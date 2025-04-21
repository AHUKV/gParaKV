//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include <cstdint>
#include <cstdio>
#include <driver_types.h>

#ifndef __host__
#define __host__
#endif

#ifndef __device__
#define __device__
#endif

#ifndef __global__
#define __global__
#endif

#ifndef __constant__
#define __constant__
#endif

#define CHECK(call)                                           \
  do {                                                        \
    cudaError_t error = call;                                 \
    if (error != cudaSuccess) {                               \
      printf("CUDA error at %s:%d: %s\n", __FILE__, __LINE__, \
             cudaGetErrorString(error));                      \
      exit(1);                                                \
    }                                                         \
  } while (0)

struct SSTableInfo {
  __host__ __device__ SSTableInfo() = default;

  __host__ __device__ SSTableInfo(size_t _num_data_block, size_t _num_restarts,
                                  size_t _total_num_kv,
                                  size_t _num_kv_last_data_block)
      : num_data_block(_num_data_block),
        num_restarts(_num_restarts),
        total_num_kv(_total_num_kv),
        num_kv_last_data_block(_num_kv_last_data_block) {}

  size_t num_data_block = 0;  // 该文件数据块数量
  size_t num_restarts = 0;    // 该文件数据块的restarts大小
  size_t total_num_kv = 0;    // 该文件总 KV对数量
  size_t num_kv_last_data_block = 0;  // 最后一个文件最后一个数据块KV的数量
};

class GPUBlockHandle {
 public:
  __host__ __device__ GPUBlockHandle() : offset_(0), size_(0) {}
  __host__ __device__ GPUBlockHandle(uint64_t offset, uint32_t size)
      : offset_(offset), size_(size) {}

  __host__ __device__ uint64_t offset() const { return offset_; }
  __host__ __device__ void set_offset(uint64_t _offset) { offset_ = _offset; }

  __host__ __device__ uint32_t size() const { return size_; }
  __host__ __device__ void set_size(uint32_t _size) { size_ = _size; }

 private:
  uint64_t offset_;  // 指向文件的偏移量
  uint32_t size_;    // 表示Block的大小
};

struct InputFile {
  __host__ __device__ InputFile()
      : level(0),
        file{},
        file_size(0),
        file_number(0),
        num_data_blocks(0),
        num_entries(0) {}

  size_t level;
  char* file;
  size_t file_size;
  uint64_t file_number;
  uint64_t num_data_blocks;
  uint64_t num_entries;
};
