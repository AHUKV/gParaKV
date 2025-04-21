//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include <string>

#include "gpu_sort.cuh"
#include "gpu_struct.cuh"

void MallocInputFiles(InputFile** input_files_d, size_t num_file);

__global__ void SetInputFile(InputFile* inputFile_d, size_t level, char* file_d,
                             size_t file_size, uint64_t file_number,
                             uint64_t num_data_blocks, uint64_t num_entries);

void AddInputFile(size_t level, const std::string& file, uint64_t file_number,
                  uint64_t num_data_blocks, uint64_t num_entries,
                  InputFile* input_file_d);

__global__ void PrepareDecode(InputFile* inputFiles_d, size_t num_file,
                              uint64_t* all_num_kv_d);

__host__ __device__ void GPUDecodeFrom(char** input, size_t* size,
                                       uint64_t* offset_, uint32_t* size_);

__host__ __device__ void GPUParseInternalKey(const char* internal_key,
                                             size_t internal_key_size,
                                             uint64_t& sequence,
                                             unsigned char& type);

__global__ void DecodeFootersKernel(InputFile* inputFiles,
                                    GPUBlockHandle* footers);

__global__ void DecodeIndexBlocksKernel(InputFile* inputFiles,
                                        GPUBlockHandle* footer,
                                        GPUBlockHandle* index_block,
                                        uint64_t max_num_data_block_d);

__global__ void DecodeDataBlocksKernel(InputFile* inputFiles,
                                       uint32_t* global_count,
                                       GPUBlockHandle* index_block,
                                       GPUKeyValue* keyValuePtr,
                                       uint64_t max_num_data_block_d);

GPUKeyValue* DecodeSSTables(size_t num_file, InputFile* inputFiles_d,
                           size_t& all_num_kvz);
