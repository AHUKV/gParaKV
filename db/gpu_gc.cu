//
// Created by ubuntu on 7/22/24.
//

#include <thrust/iterator/counting_iterator.h>

#include "gpu_gc.h"

void GPUGC::MallocMemory() {
  cudaMalloc(&gpu_flags, max_num_log * max_num_log_item);
  cudaMemset(gpu_flags, 1, max_num_log * max_num_log_item);

  cudaMalloc(&invalid_count, max_num_log * sizeof(uint32_t));
  cudaMemset(invalid_count, 0, max_num_log * sizeof(uint32_t));

  cudaStreamCreate(&stream);
}

GPUGC::~GPUGC() {
  cudaFree(gpu_flags);
  cudaFree(invalid_count);
  cudaStreamDestroy(stream);
}

__device__ bool CompareKey(const GPUKeyValue& key_value1,
                           const GPUKeyValue& key_value2) {
  for (int i = 0; i < keySize_; ++i) {
    if (key_value1.key[i] != key_value2.key[i]) {
      return false;
    }
  }
  return true;
}

__global__ void MarkInvalidKeysKernel(GPUKeyValue* key_values_d,
                                      uint8_t* gpu_flags,
                                      uint32_t max_num_log_item,
                                      uint32_t max_num_log,
                                      uint32_t var_key_value_size,
                                      uint32_t* invalid_count, size_t n) {
  uint32_t tid = threadIdx.x + blockIdx.x * blockDim.x;
  if (tid > 0 && tid < n) {
    if (CompareKey(key_values_d[tid], key_values_d[tid - 1])) {
      uint32_t vlog_num = GPUDecodeFixed32(key_values_d[tid].value);
      uint32_t invalid_pos = GPUDecodeFixed32(key_values_d[tid].value + 4);
      uint32_t idx = (vlog_num - 1) * max_num_log_item +
                     (invalid_pos - 12) / var_key_value_size;
      if (idx < max_num_log_item * max_num_log)
        gpu_flags[idx] = 0;  // 索引从0开始
      // 该vlog的无效KV对数量+1，必须原子操作
      if (vlog_num <= max_num_log) atomicAdd(&invalid_count[vlog_num - 1], 1);
    }
  }
}

void GPUGC::Mark(GPUKeyValue* key_values_d, size_t n) {
  // 计算块和线程数
  size_t threadsPerBlock = 1024;
  size_t blocksPerGrid = (n + threadsPerBlock - 1) / threadsPerBlock;

  MarkInvalidKeysKernel<<<blocksPerGrid, threadsPerBlock, 0, stream>>>(
      key_values_d, gpu_flags, max_num_log_item, max_num_log,
      leveldb::my_stats.var_key_value_size + 12, invalid_count, n);
  CHECK(cudaStreamSynchronize(stream));
}

__global__ void TriggerGCKernel(const uint32_t* invalid_count,
                                uint32_t* vlog_num_d,
                                uint32_t* curr_invalid_count,
                                uint32_t max_num_log,
                                uint32_t clean_threshold) {
  uint32_t tid = threadIdx.x + blockIdx.x * blockDim.x;
  if (tid >= max_num_log) return;

  // 使用 atomicCAS 确保只有第一个线程进入
  if (invalid_count[tid] >= clean_threshold) {
    if (atomicCAS(vlog_num_d, 0, tid + 1) == 0) {  // vlog_num_d 初始值应为 0
      // 只有第一个线程成功更新 vlog_num_d，才能进入这里
      *curr_invalid_count = invalid_count[tid];
    }
    return;
  }
}

__global__ void Adjustment(const uint8_t* flags, uint32_t max_num_log_item,
                           uint32_t* count) {
  uint32_t tid = threadIdx.x + blockIdx.x * blockDim.x;
  if (tid >= max_num_log_item) return;
  if (flags[tid] == 0) atomicAdd(count, 1);
}

bool GPUGC::TriggerGC() {
  uint32_t* vlog_num_d;
  uint32_t* curr_invalid_count;
  cudaMalloc(&vlog_num_d, sizeof(uint32_t));
  cudaMemset(vlog_num_d, 0, sizeof(uint32_t));
  cudaMalloc(&curr_invalid_count, sizeof(uint32_t));
  cudaMemset(curr_invalid_count, 0, sizeof(uint32_t));

  size_t threadsPerBlock = 256;
  size_t blocksPerGrid = (max_num_log + threadsPerBlock - 1) / threadsPerBlock;
  TriggerGCKernel<<<blocksPerGrid, threadsPerBlock, 0, stream>>>(
      invalid_count, vlog_num_d, curr_invalid_count, max_num_log,
      leveldb::my_stats.clean_threshold);
  CHECK(cudaStreamSynchronize(stream));

  cudaMemcpy(&triggered_vlog_num, vlog_num_d, sizeof(uint32_t),
             cudaMemcpyDeviceToHost);

  if (triggered_vlog_num > 0) {
    cudaMemcpy(&triggered_invalid_count, curr_invalid_count, sizeof(uint32_t),
               cudaMemcpyDeviceToHost);

    //    printf("GC is triggered, vlog num: %d, count: %d\n",
    //    triggered_vlog_num,
    //           triggered_invalid_count);
    return true;
  }
  return false;
}

__global__ void GPUGCKernel(char* vlog_d, char* output_d, uint8_t* flags,
                            uint32_t max_num_log_item,
                            uint32_t triggered_vlog_num, uint32_t* global_count,
                            uint32_t var_key_value_size) {
  uint32_t tid = blockDim.x * blockIdx.x + threadIdx.x;
  if (tid >= max_num_log_item) return;

  flags = flags + (triggered_vlog_num - 1) * max_num_log_item;
  if (flags[tid] == 0) return;

  uint32_t index = atomicAdd(global_count, 1);
  memcpy(output_d + index * var_key_value_size,
         vlog_d + tid * var_key_value_size, var_key_value_size);
}

void GPUGC::BeginGPUGC(const char* vlog, size_t vlog_size, char** output,
                       size_t& output_size) {
  char* vlog_d;
  cudaMalloc(&vlog_d, vlog_size);
  cudaMemcpy(vlog_d, vlog, vlog_size, cudaMemcpyHostToDevice);

  uint32_t* global_count;
  cudaMalloc(&global_count, max_num_log_item * sizeof(uint32_t));
  cudaMemset(global_count, 0, max_num_log_item * sizeof(uint32_t));

  output_size = vlog_size - triggered_invalid_count *
                                (leveldb::my_stats.var_key_value_size + 12);
  char* output_d;
  cudaMalloc(&output_d, output_size);

  // 计算块和线程数
  size_t threadsPerBlock = 1024;
  size_t blocksPerGrid =
      (max_num_log_item + threadsPerBlock - 1) / threadsPerBlock;

  GPUGCKernel<<<blocksPerGrid, threadsPerBlock, 0, stream>>>(
      vlog_d, output_d, gpu_flags, max_num_log_item, triggered_vlog_num,
      global_count, leveldb::my_stats.var_key_value_size + 12);

  CHECK(cudaStreamSynchronize(stream));

  *output = new char[output_size];
  cudaMemcpy(*output, output_d, output_size, cudaMemcpyDeviceToHost);

  cudaFree(output_d);
  cudaFree(global_count);
  cudaFree(vlog_d);
}

__global__ void GPUGCOptimizedKernel(char* vlog_d, char* output_d,
                                     const uint8_t* flags,
                                     uint32_t var_key_value_size,
                                     uint32_t total_thread_num,
                                     uint32_t process_num_per_thread,
                                     uint32_t* global_count) {
  uint32_t tid = blockDim.x * blockIdx.x + threadIdx.x;
  if (tid >= total_thread_num) return;

  uint32_t count;
  for (uint32_t idx = tid * process_num_per_thread;
       idx < (tid + 1) * process_num_per_thread; ++idx) {
    if (flags[idx] == 1) {
      count = atomicAdd(global_count, 1);
      memcpy(output_d + count * var_key_value_size,
             vlog_d + idx * var_key_value_size, var_key_value_size);
    }
  }
}

void GPUGC::BeginGPUGCOptimized(const char* vlog, size_t vlog_size,
                                char** output) {
  auto start_time = std::chrono::high_resolution_clock::now();
  char* vlog_d;
  cudaMalloc((void**)&vlog_d, vlog_size);
  cudaMemcpy(vlog_d, vlog, vlog_size, cudaMemcpyHostToDevice);
  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
      end_time - start_time);
  leveldb::my_stats.data_transfer_time += duration.count();

  uint32_t process_num_per_thread = 100;
  uint32_t total_thread_num =
      leveldb::my_stats.max_num_log_item / process_num_per_thread;

  uint32_t* global_count;
  cudaMalloc(&global_count, sizeof(uint32_t));
  cudaMemset(global_count, 0, sizeof(uint32_t));

  uint32_t* flag_count_d;
  cudaMalloc(&flag_count_d, sizeof(uint32_t));
  cudaMemset(flag_count_d, 0, sizeof(uint32_t));
  size_t block = 256;
  size_t grid = (max_num_log_item + block - 1) / block;
  Adjustment<<<grid, block, 0, stream>>>(
      gpu_flags + (triggered_vlog_num - 1) * max_num_log_item, max_num_log_item,
      flag_count_d);
  CHECK(cudaStreamSynchronize(stream));
  uint32_t flag_count;
  cudaMemcpy(&flag_count, flag_count_d, sizeof(uint32_t),
             cudaMemcpyDeviceToHost);
  //  printf("flag count: %u\n", flag_count);

  triggered_invalid_count = flag_count;

  size_t output_size =
      vlog_size - flag_count * (leveldb::my_stats.var_key_value_size + 12);

  char* output_d;
  cudaMalloc(&output_d, output_size);

  // 计算块和线程数
  size_t threadsPerBlock = 1024;
  size_t blocksPerGrid =
      (total_thread_num + threadsPerBlock - 1) / threadsPerBlock;
  GPUGCOptimizedKernel<<<blocksPerGrid, threadsPerBlock, 0, stream>>>(
      vlog_d, output_d, gpu_flags + (triggered_vlog_num - 1) * max_num_log_item,
      leveldb::my_stats.var_key_value_size + 12, total_thread_num,
      process_num_per_thread, global_count);
  CHECK(cudaStreamSynchronize(stream));

  *output = new char[output_size];
  cudaMemcpy(*output, output_d, output_size, cudaMemcpyDeviceToHost);

  cudaFree(output_d);
  cudaFree(vlog_d);
  cudaFree(global_count);
}

void GPUGC::CleanGC() {
  cudaMemset(&invalid_count[triggered_vlog_num - 1], 0, sizeof(uint32_t));
  cudaMemset(gpu_flags + (triggered_vlog_num - 1) * max_num_log_item, 1,
             max_num_log_item);
  triggered_vlog_num = 0;
  triggered_invalid_count = 0;
}
