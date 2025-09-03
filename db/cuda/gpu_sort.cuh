//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include "db/gpu_gc.h"
#include <cstdint>
#include <cstring>
#include <string>
#include <unordered_map>
#include <vector>

#include "gpu_options.cuh"

class GPUKeyValue {
 public:
  __host__ __device__ GPUKeyValue() : key{}, value{}, sequence(0) {}

  __host__ __device__ GPUKeyValue(const GPUKeyValue& other)
      : key{}, value{}, sequence(other.sequence) {
    memcpy(key, other.key, keySize_ + 8);
    memcpy(value, other.value, valueSize_);
  }

  char key[keySize_ + 8 + 1];
  char value[valueSize_ + 1];
  uint64_t sequence;  // 序列号

  // new
  __host__ __device__ bool operator<(const GPUKeyValue& other) const {
    const auto* p1 = (const unsigned char*)key;
    const auto* p2 = (const unsigned char*)other.key;

    for (size_t i = 0; i < keySize_; ++i) {
      if (static_cast<int>(p1[i]) != static_cast<int>(p2[i])) {
        return static_cast<int>(p1[i]) < static_cast<int>(p2[i]);
      }
    }

    return sequence > other.sequence;
  }

  __host__ __device__ bool operator==(const GPUKeyValue& other) const {
    const auto* p1 = (const unsigned char*)key;
    const auto* p2 = (const unsigned char*)other.key;

    for (size_t i = 0; i < keySize_; ++i) {
      if (static_cast<int>(p1[i]) != static_cast<int>(p2[i])) {
        return false;
      }
    }

    return true;
  }
};

// old
struct GPUKeyValueSortAscending {
  __host__ __device__ bool operator()(const GPUKeyValue& a,
                                      const GPUKeyValue& b) const {
    const auto* p1 = (const unsigned char*)a.key;
    const auto* p2 = (const unsigned char*)b.key;

    for (size_t i = 0; i < keySize_; ++i) {
      if (static_cast<int>(p1[i]) != static_cast<int>(p2[i])) {
        return static_cast<int>(p1[i]) < static_cast<int>(p2[i]);
      }
    }

    return a.sequence < b.sequence;
  }
};

void GPUSort(GPUKeyValue* key_value_d, size_t num_element, size_t& sorted_size);

size_t GPUUnique(GPUKeyValue* key_value_d, size_t num_element);

void GPUSortMark(GPUKeyValue* key_value_d, size_t num_element,
                 size_t& sorted_size, GPUKeyValue** old_start, size_t& num_new);

void GPUMark(GPUKeyValue* key_value_d, size_t num_element,
             std::vector<GPUKeyValue>& new_start);

void GPUSortMemtable(GPUKeyValue* key_values,
                     std::unordered_map<std::string, std::string>& kvs,
                     size_t total_num_kv, size_t& sorted_size);

void GPUPositionSort(uint32_t* position, size_t& size);
