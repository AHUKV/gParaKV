//
// Created by ubuntu on 7/6/24.
//

#include <cstring>
#include <cuda_runtime.h>
#include <thrust/copy.h>
#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/reduce.h>
#include <thrust/sort.h>
#include <thrust/unique.h>
#include <vector>

#include "gpu_sort.cuh"

struct is_count_greater_than_one {
  __host__ __device__ bool operator()(const int x) const { return x > 1; }
};

struct SetValueAtPosition {
  __host__ __device__ GPUKeyValue operator()(GPUKeyValue kv) const {
    kv.value[8] = 0xA;
    return kv;
  }
};

void GPUSort(GPUKeyValue* key_value_d, size_t num_element,
             size_t& sorted_size) {
  thrust::sort(thrust::device, key_value_d, key_value_d + num_element);

  sorted_size =
      thrust::unique(thrust::device, key_value_d, key_value_d + num_element) -
      key_value_d;
}

size_t GPUUnique(GPUKeyValue* key_value_d, size_t num_element) {
  return thrust::unique(thrust::device, key_value_d,
                        key_value_d + num_element) -
         key_value_d;
}

void GPUSortMark(GPUKeyValue* key_value_d, size_t num_element,
                 size_t& sorted_size, GPUKeyValue** old_start,
                 size_t& num_old) {
  // 排序
  thrust::sort(thrust::device, key_value_d, key_value_d + num_element);

  // 创建计数值数组，每个键的初始计数值为 1
  thrust::device_vector<int> d_counts(num_element, 1);

  // 创建输出键和值数组
  thrust::device_vector<GPUKeyValue> d_keys_output(num_element);
  thrust::device_vector<int> d_values_output(num_element);

  // 调用 thrust::reduce_by_key 进行计数
  auto new_end = thrust::reduce_by_key(
      thrust::device, key_value_d, key_value_d + num_element,  // 输入键
      d_counts.begin(),        // 输入值（计数）
      d_keys_output.begin(),   // 输出键
      d_values_output.begin()  // 输出值（计数）
  );

  // 计算结果的大小
  int num_elements = new_end.first - d_keys_output.begin();

  cudaMalloc((void**)old_start, num_elements * sizeof(GPUKeyValue));

  // 使用 thrust::copy_if 过滤 count > 1 的键值对
  auto end_it = thrust::copy_if(
      d_keys_output.begin(), d_keys_output.begin() + num_elements,
      d_values_output.begin(), thrust::device_pointer_cast(*old_start),
      is_count_greater_than_one());

  // 计算过滤后的元素数量
  num_old = end_it - thrust::device_pointer_cast(*old_start);

  // 去重
  sorted_size =
      thrust::unique(thrust::device, key_value_d, key_value_d + num_element) -
      key_value_d;
}

void GPUMark(GPUKeyValue* key_value_d, size_t num_element,
             std::vector<GPUKeyValue>& new_start) {
  // 排序
  thrust::sort(thrust::device, key_value_d, key_value_d + num_element,
               GPUKeyValueSortAscending());

  // 创建计数值数组，每个键的初始计数值为 1
  thrust::device_vector<int> d_counts(num_element, 1);

  // 创建输出键和值数组
  thrust::device_vector<GPUKeyValue> d_keys_output(num_element);
  thrust::device_vector<int> d_values_output(num_element);

  // 调用 thrust::reduce_by_key 进行计数
  auto new_end = thrust::reduce_by_key(
      thrust::device, key_value_d, key_value_d + num_element,  // 输入键
      d_counts.begin(),        // 输入值（计数）
      d_keys_output.begin(),   // 输出键
      d_values_output.begin()  // 输出值（计数）
  );

  // 计算结果的大小
  int num_elements = new_end.first - d_keys_output.begin();

  // 创建一个新的容器，用于存储 count > 1 的键值对
  thrust::device_vector<GPUKeyValue> keys_with_count_greater_than_one(
      num_elements);

  // 使用 thrust::copy_if 过滤 count > 1 的键值对
  auto end_it = thrust::copy_if(
      d_keys_output.begin(), d_keys_output.begin() + num_elements,
      d_values_output.begin(), keys_with_count_greater_than_one.begin(),
      is_count_greater_than_one());

  // 计算过滤后的元素数量
  size_t num_old = end_it - keys_with_count_greater_than_one.begin();

  // 将结果从设备端复制到主机端
  new_start.reserve(num_old);
  new_start.resize(num_old);
  thrust::copy(keys_with_count_greater_than_one.begin(), end_it,
               new_start.begin());
}

void GPUSortMemtable(GPUKeyValue* key_values,
                     std::unordered_map<std::string, std::string>& kvs,
                     size_t total_num_kv, size_t& sorted_size) {
  kvs.reserve(total_num_kv);
  for (size_t i = 0; i < total_num_kv; ++i) {
    std::string key(key_values[i].key, keySize_);
    std::string value(key_values[i].value, valueSize_);
    kvs.emplace(std::move(key), std::move(value));
  }

  sorted_size = kvs.size();
}

void GPUPositionSort(uint32_t* position, size_t& size) {
  uint32_t* position_d;
  cudaMalloc(&position_d, sizeof(uint32_t) * size);
  cudaMemcpy(position_d, position, sizeof(uint32_t) * size,
             cudaMemcpyHostToDevice);

  thrust::sort(thrust::device, position_d, position_d + size);
  size = thrust::unique(thrust::device, position_d, position_d + size) -
         position_d;

  cudaMemcpy(position, position_d, sizeof(uint32_t) * size,
             cudaMemcpyDeviceToHost);

  cudaFree(position_d);
}

void test_test() {}