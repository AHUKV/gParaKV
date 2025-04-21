//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include "gpu_crc.cuh"
#include "gpu_sort.cuh"
#include "gpu_struct.cuh"

// 一个文件的数据块数量
inline __constant__ size_t num_data_block_d;
// 数据块中键值对数量
inline __constant__ size_t num_kv_data_block_d;
// 重启点的数量
inline __constant__ uint32_t num_restarts_d;
// 完整数据块的总大小
inline __constant__ size_t size_complete_data_block_d;

// GPU编码多SSTable专用
// 前面的文件中一个文件的KV对总数量
inline __constant__ size_t num_kv_d;
// 前面的文件中一个文件的预估大小
inline __constant__ size_t size_file_d;
// 输出文件的数量
inline __constant__ size_t num_outputs_d;
// 非最后一个文件的数据块的大小
inline __constant__ size_t data_size_d;
// 非最后一个文件索引块的大小
inline __constant__ size_t index_size_d;

/******************/

// 一个文件的数据块数量
inline __constant__ size_t num_data_block_compaction_d;
// 数据块中键值对数量
inline __constant__ size_t num_kv_data_block_compaction_d;
// 重启点的数量
inline __constant__ uint32_t num_restarts_compaction_d;
// 完整数据块的总大小
inline __constant__ size_t size_complete_data_block_compaction_d;

// GPU编码多SSTable专用
// 前面的文件中一个文件的KV对总数量
inline __constant__ size_t num_kv_compaction_d;
// 前面的文件中一个文件的预估大小
inline __constant__ size_t size_file_compaction_d;
// 输出文件的数量
inline __constant__ size_t num_outputs_compaction_d;
// 非最后一个文件的数据块的大小
inline __constant__ size_t data_size_compaction_d;
// 非最后一个文件索引块的大小
inline __constant__ size_t index_size_compaction_d;

/******************/

__host__ __device__ uint32_t GPUComputeBuiltinChecksumWithLastByte(
    const char* data, size_t data_size, char last_type);

__device__ void BeginBuildDataBlock(
    uint32_t file_idx, uint32_t block_idx, char* current_block_buffer,
    GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_kv_current_data_block, uint32_t num_current_restarts,
    uint32_t* current_restarts, size_t size_current_data_block);

__device__ void BeginBuildDataBlockForCompaction(
    uint32_t file_idx, uint32_t block_idx, char* current_block_buffer,
    GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_kv_current_data_block, uint32_t num_current_restarts,
    uint32_t* current_restarts, size_t size_current_data_block);

__global__ void BuildDataBlocksKernel(char* buffer_d, GPUKeyValue* key_values_d,
                                      char* index_keys_d, uint32_t* restarts_d);

__global__ void BuildDataBlocksKernelForCompaction(char* buffer_d,
                                                   GPUKeyValue* key_values_d,
                                                   char* index_keys_d,
                                                   uint32_t* restarts_d);

__global__ void BuildDataBlocksLastFileKernel(char* buffer_d,
                                              GPUKeyValue* key_values_d,
                                              char* index_keys_d,
                                              uint32_t* restarts_d);

__global__ void BuildDataBlocksLastFileKernelForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    uint32_t* restarts_d);

__global__ void BuildLastDataBlockLastFileKernel(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_data_block_last_file, size_t num_kv_last_data_block_last_file,
    uint32_t num_restarts_last_data_block_last_file,
    uint32_t* restarts_last_data_block_last_file_d,
    size_t size_incomplete_data_block);

__global__ void BuildLastDataBlockLastFileKernelForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_data_block_last_file, size_t num_kv_last_data_block_last_file,
    uint32_t num_restarts_last_data_block_last_file,
    uint32_t* restarts_last_data_block_last_file_d,
    size_t size_incomplete_data_block);

void BuildDataBlocks(char* buffer_d, GPUKeyValue* key_values_d,
                     char* index_keys_d, uint32_t* restarts_d,
                     size_t num_data_block, size_t num_outputs,
                     size_t num_kv_last_data_block,
                     size_t num_data_block_last_file,
                     uint32_t* restarts_last_data_block_d,
                     uint32_t num_restarts_last_data_block,
                     size_t size_incomplete_data_block, cudaStream_t* stream);

void BuildDataBlocksForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    uint32_t* restarts_d, size_t num_data_block, size_t num_outputs,
    size_t num_kv_last_data_block, size_t num_data_block_last_file,
    uint32_t* restarts_last_data_block_d, uint32_t num_restarts_last_data_block,
    size_t size_incomplete_data_block, cudaStream_t* stream);

__global__ void ComputeDataBlockHandleKernel(GPUBlockHandle* block_handles_d,
                                             uint32_t* restarts_for_index_d);

__global__ void ComputeDataBlockHandleLastFileKernel(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t num_data_block_last_file);

__device__ void BeginBuildIndexBlock(uint32_t file_idx, uint32_t block_idx,
                                     char* current_index_buffer,
                                     char* index_keys_d,
                                     GPUBlockHandle* block_handles_d,
                                     uint32_t* current_restarts,
                                     size_t current_num_data_block);

__global__ void BuildIndexBlockKernel(char* buffer_d, char* index_keys_d,
                                      GPUBlockHandle* block_handles_d,
                                      uint32_t* restarts_for_index_d);

__global__ void BuildIndexBlockLastFileKernel(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_last_file_d, size_t num_data_block_last_file,
    size_t data_size_last_file);

__global__ void ComputeChecksumKernel(char* buffer_d);

__global__ void ComputeChecksumLastFileKernel(char* buffer_d,
                                              size_t num_data_block_last_file,
                                              size_t data_size_last_file,
                                              size_t index_size_last_file);

void BuildIndexBlocks(char* buffer_d, char* index_keys_d,
                      GPUBlockHandle* block_handles_d, size_t num_outputs,
                      size_t num_data_block, uint32_t* restarts_for_index_d,
                      size_t num_data_block_last_file,
                      uint32_t* restarts_for_index_last_file_d,
                      size_t size_incomplete_data_block,
                      size_t data_size_last_file, size_t index_size_last_file,
                      cudaStream_t* stream);

__global__ void ComputeDataBlockHandleKernelForCompaction(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_d);

__global__ void ComputeDataBlockHandleLastFileKernelForCompaction(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t num_data_block_last_file);

__device__ void BeginBuildIndexBlockForCompaction(
    uint32_t file_idx, uint32_t block_idx, char* current_index_buffer,
    char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* current_restarts, size_t current_num_data_block);

__global__ void BuildIndexBlockKernelForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_d);

__global__ void BuildIndexBlockLastFileKernelForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_last_file_d, size_t num_data_block_last_file,
    size_t data_size_last_file);

__global__ void ComputeChecksumKernelForCompaction(char* buffer_d);

__global__ void ComputeChecksumLastFileKernelForCompaction(
    char* buffer_d, size_t num_data_block_last_file, size_t data_size_last_file,
    size_t index_size_last_file);

void BuildIndexBlocksForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    size_t num_outputs, size_t num_data_block, uint32_t* restarts_for_index_d,
    size_t num_data_block_last_file, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t data_size_last_file,
    size_t index_size_last_file, cudaStream_t* stream);

void BuildSSTables(GPUKeyValue* key_value_d, std::vector<SSTableInfo>& infos,
                   char** all_files_buffer, size_t& estimate_file_size,
                   size_t& data_size, size_t& index_size,
                   size_t& data_size_last_file, size_t& index_size_last_file,
                   uint32_t& num_restarts,
                   uint32_t& num_restarts_last_data_block);

void BuildSSTablesForCompaction(GPUKeyValue* key_value_d,
                                std::vector<SSTableInfo>& infos,
                                char** all_files_buffer,
                                size_t& estimate_file_size, size_t& data_size,
                                size_t& index_size, size_t& data_size_last_file,
                                size_t& index_size_last_file,
                                uint32_t& num_restarts,
                                uint32_t& num_restarts_last_data_block);
