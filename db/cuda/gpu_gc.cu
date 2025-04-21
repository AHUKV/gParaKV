//
// Created by ubuntu on 7/22/24.
//

#include "db/my_stats.h"

/*
void GPUGC::MallocMemory() {
  cudaMalloc(&gpu_flags, max_num_log * max_num_log_item);
}

__global__ void GPUInvalidMark(const uint32_t* invalid_pos_d,
                               size_t invalid_size, uint32_t* pos_d,
                               size_t var_key_value_size) {
  uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
  if (tid >= invalid_size) return;
  pos_d[(invalid_pos_d[tid] - 12) / var_key_value_size] = 0;
}

void GPUGCPrepare(uint32_t* invalid_pos, size_t invalid_size,
                  uint32_t** pos_d) {
  uint32_t* invalid_pos_d;
  cudaMalloc(&invalid_pos_d, invalid_size * sizeof(uint32_t));
  cudaMemcpy(invalid_pos_d, invalid_pos, invalid_size * sizeof(uint32_t),
             cudaMemcpyHostToDevice);

  cudaMalloc(pos_d, leveldb::my_stats.max_num_log_item * sizeof(uint32_t));
  cudaMemset(*pos_d, 1, leveldb::my_stats.max_num_log_item * sizeof(uint32_t));

  // 计算块和线程数
  size_t threadsPerBlock = 256;
  size_t blocksPerGrid = (invalid_size + threadsPerBlock - 1) / threadsPerBlock;

  // 调用 GPU 核函数
  GPUInvalidMark<<<blocksPerGrid, threadsPerBlock>>>(
      invalid_pos_d, invalid_size, *pos_d,
      leveldb::my_stats.var_key_value_size + 12);

  // 等待 GPU 完成
  cudaDeviceSynchronize();

  // 释放 GPU 内存
  cudaFree(invalid_pos_d);
}

*/
/*__global__ GPUGCKernel(char* output, uint32_t* pos_d, uint32_t* global_count,
                       size_t num_log_item) {
  uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
  if (tid >= num_log_item) return;

  uint32_t index = atomicAdd(global_count, 1);

}*//*


void GPUGC(const char* vlog_file, size_t file_size, char** output,
           size_t output_size, uint32_t* pos_d, size_t num_log_item,
           size_t num_valid) {
  char* vlog_file_d;
  cudaMalloc(&vlog_file_d, file_size);
  cudaMemcpy(vlog_file_d, vlog_file, file_size, cudaMemcpyHostToDevice);

  cudaMalloc(output, output_size);

  uint32_t* global_count;
  cudaMalloc(&global_count, num_valid * sizeof(uint32_t));
  cudaMemset(global_count, 0, num_valid * sizeof(uint32_t));

  cudaFree(vlog_file_d);
}
*/
