//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include <chrono>

#include "gpu_encoder.cuh"

void CUDAFree(GPUKeyValue* key_values_d);

void ReleaseSource(InputFile* inputFiles_d, GPUKeyValue* key_value_d,
                   size_t num_inputs);

void EncodePrepare(size_t total_num_kv, std::vector<SSTableInfo>& infos);

void GPUFlush(GPUKeyValue* key_values, GPUKeyValue** key_values_d,
              char** all_files_buffer, size_t total_num_kv, size_t& sorted_size,
              size_t& num_files, size_t& estimate_file_size, size_t& data_size,
              size_t& index_size, size_t& data_size_last_file,
              size_t& index_size_last_file, uint32_t& num_restarts,
              uint32_t& num_restarts_last_data_block,
              uint64_t& num_data_blocks);
