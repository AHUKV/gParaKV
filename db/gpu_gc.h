//
// Created by ubuntu on 7/22/24.
//

#pragma once

#include "db/cuda/gpu_coding.cuh"
#include "db/cuda/gpu_sort.cuh"
#include "db/cuda/gpu_struct.cuh"
#include <cstddef>
#include <cstdint>
#include <unordered_map>

#include "my_stats.h"

class GPUKeyValue;

class GPUGC {
 public:
  GPUGC(uint32_t _max_num_log, uint32_t _max_num_log_item)
      : max_num_log(_max_num_log + 1000),
        max_num_log_item(_max_num_log_item),
        triggered_vlog_num(0),
        triggered_invalid_count(0),
        gpu_flags{},
        invalid_count{} {}

  ~GPUGC();

  void MallocMemory();

  void Mark(GPUKeyValue* key_values_d, size_t n);

  bool TriggerGC();

  void BeginGPUGC(const char* vlog, size_t vlog_size, char** output, size_t& output_size);

  void BeginGPUGCOptimized(const char* vlog_name, size_t vlog_size, char** output);

  void CleanGC();

  cudaStream_t stream;

  uint32_t max_num_log;
  uint32_t max_num_log_item;

  uint32_t triggered_vlog_num;
  uint32_t triggered_invalid_count;

  uint8_t* gpu_flags;   // GPU位图
  uint32_t* invalid_count;  // 每个vlog的无效KV对数量
};
