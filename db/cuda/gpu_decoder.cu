//
// Created by ubuntu on 7/6/24.
//

#include <chrono>
#include <thrust/sort.h>

#include "gpu_coding.cuh"
#include "gpu_decoder.cuh"

void MallocInputFiles(InputFile** input_files_d, size_t num_file) {
  cudaMalloc(input_files_d, num_file * sizeof(InputFile));
}

__global__ void SetInputFile(InputFile* inputFile_d, size_t level, char* file_d,
                             size_t file_size, uint64_t file_number,
                             uint64_t num_data_blocks, uint64_t num_entries) {
  inputFile_d->level = level;
  inputFile_d->file = file_d;
  inputFile_d->file_size = file_size;
  inputFile_d->file_number = file_number;
  inputFile_d->num_data_blocks = num_data_blocks;
  inputFile_d->num_entries = num_entries;
}

void AddInputFile(size_t level, const std::string& file, uint64_t file_number,
                  uint64_t num_data_blocks, uint64_t num_entries,
                  InputFile* input_file_d) {
  size_t file_size = file.size();

  char* file_d;
  cudaMalloc((void**)&file_d, file_size);
  cudaMemcpy(file_d, file.c_str(), file_size, cudaMemcpyHostToDevice);

  SetInputFile<<<1, 1>>>(input_file_d, level, file_d, file_size, file_number,
                         num_data_blocks, num_entries);
}

__global__ void PrepareDecode(InputFile* inputFiles_d, size_t num_file,
                              uint64_t* all_num_kv_d) {
  for (size_t i = 0; i < num_file; ++i) {
    uint64_t num_kv = inputFiles_d[i].num_entries;
    *all_num_kv_d += num_kv;
  }
}

__host__ __device__ void GPUDecodeFrom(char** input, size_t* size,
                                       uint64_t* offset_, uint32_t* size_) {
  if (GPUGetFixed64(input, size, offset_) &&
      GPUGetFixed32(input, size, size_)) {
  } else {
    printf("bad block handle\n");
  }
}

__host__ __device__ void GPUParseInternalKey(const char* internal_key,
                                             size_t internal_key_size,
                                             uint64_t& sequence,
                                             unsigned char& type) {
  uint64_t num = GPUDecodeFixed64(internal_key + internal_key_size - 8);
  unsigned char c = num & 0xff;
  sequence = num >> 8;
  type = c;
}

__global__ void DecodeFootersKernel(InputFile* inputFiles,
                                    GPUBlockHandle* footers) {
  unsigned int tid = threadIdx.x;

  char* footer = inputFiles[tid].file + inputFiles[tid].file_size - 56;
  size_t footer_size = 56;

  uint64_t offset;
  uint32_t size;
  GPUDecodeFrom(&footer, &footer_size, &offset, &size);
  GPUDecodeFrom(&footer, &footer_size, &offset, &size);

  footers[tid].set_offset(offset);
  footers[tid].set_size(size);
}

__global__ void DecodeIndexBlocksKernel(InputFile* inputFiles,
                                        GPUBlockHandle* footer,
                                        GPUBlockHandle* index_block,
                                        uint64_t max_num_data_block_d) {
  unsigned int file_idx = threadIdx.x;
  unsigned int block_idx = blockIdx.x;

  if (block_idx >= inputFiles[file_idx].num_data_blocks) return;

  char* data = inputFiles[file_idx].file + footer[file_idx].offset();
  char* p = data + size_index_entry * block_idx + 3 + (keySize_ + 8);

  size_t handle_size = encoded_index_entry;

  uint64_t offset;
  uint32_t size;
  GPUDecodeFrom(&p, &handle_size, &offset, &size);

  index_block[file_idx * max_num_data_block_d + block_idx].set_offset(offset);
  index_block[file_idx * max_num_data_block_d + block_idx].set_size(size);
}

__global__ void DecodeDataBlocksKernel(InputFile* inputFiles,
                                       uint32_t* global_count,
                                       GPUBlockHandle* index_block,
                                       GPUKeyValue* keyValuePtr,
                                       uint64_t max_num_data_block_d) {
  unsigned int file_idx = threadIdx.x;
  unsigned int block_idx = blockIdx.x;
  //  unsigned int kv_idx = threadIdx.y;

  if (block_idx >= inputFiles[file_idx].num_data_blocks) return;

  size_t num_kv;
  if (block_idx < inputFiles[file_idx].num_data_blocks - 1) {
    num_kv = num_kv_data_block;
  } else {  // 最后一个数据块
    num_kv = inputFiles[file_idx].num_entries -
             num_kv_data_block * (inputFiles[file_idx].num_data_blocks - 1);
  }

  const char* current_data_block =
      inputFiles[file_idx].file +
      index_block[file_idx * max_num_data_block_d + block_idx].offset();

  for (size_t i = 0; i < num_kv; ++i) {
    const char* p = current_data_block + key_value_size * i;

    uint32_t index = atomicAdd(global_count, 1);

    const char* key = p + 3;
    memcpy(keyValuePtr[index].key, key, keySize_ + 8);

    const char* value = key + keySize_ + 8;
    memcpy(keyValuePtr[index].value, value, valueSize_);

    unsigned char type = 0;
    GPUParseInternalKey(key, keySize_ + 8, keyValuePtr[index].sequence, type);
  }
}

GPUKeyValue* DecodeSSTables(size_t num_file, InputFile* inputFiles_d,
                            size_t& all_num_kv) {
  // 准备输入数据
  // footer、索引块和数据块共有输入数据
  uint64_t* all_num_kv_d;
  cudaMalloc(&all_num_kv_d, sizeof(uint64_t));
  cudaMemsetAsync(all_num_kv_d, 0, sizeof(uint64_t));

  PrepareDecode<<<1, 1>>>(inputFiles_d, num_file, all_num_kv_d);

  cudaMemcpyAsync(&all_num_kv, all_num_kv_d, sizeof(uint64_t),
                  cudaMemcpyDeviceToHost);

  GPUBlockHandle* index_blocks_d;  // 索引块
  cudaMalloc(&index_blocks_d,
             num_file * max_num_data_block * sizeof(GPUBlockHandle));

  GPUBlockHandle* footers_d;
  cudaMalloc(&footers_d, sizeof(GPUBlockHandle) * num_file);

  GPUKeyValue* key_value_d;
  cudaMalloc((void**)&key_value_d, all_num_kv * sizeof(GPUKeyValue));

  uint32_t* global_count;
  cudaMalloc(&global_count, sizeof(uint32_t));
  cudaMemset(global_count, 0, sizeof(uint32_t));

  // 准备执行核函数
  dim3 block(num_file);
  dim3 grid(max_num_data_block);

  cudaStream_t stream;
  cudaStreamCreate(&stream);

  DecodeFootersKernel<<<1, block, 0, stream>>>(inputFiles_d, footers_d);

  DecodeIndexBlocksKernel<<<grid, block, 0, stream>>>(
      inputFiles_d, footers_d, index_blocks_d, max_num_data_block);

  DecodeDataBlocksKernel<<<grid, block, 0, stream>>>(
      inputFiles_d, global_count, index_blocks_d, key_value_d,
      max_num_data_block);
  CHECK(cudaStreamSynchronize(stream));

  thrust::sort(thrust::device, key_value_d, key_value_d + all_num_kv);

  // 释放资源
  cudaStreamDestroy(stream);
  cudaFree(index_blocks_d);
  cudaFree(footers_d);
  cudaFree(global_count);
  cudaFree(all_num_kv_d);

  return key_value_d;
}
