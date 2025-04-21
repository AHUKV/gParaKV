//
// Created by ubuntu on 7/6/24.
//

#include "gpu_flush_compaction.cuh"
#include "gpu_struct.cuh"

void CUDAFree(GPUKeyValue* key_values_d) { cudaFree(key_values_d); }

void ReleaseSource(InputFile* inputFiles_d, GPUKeyValue* key_value_d,
                   size_t num_inputs) {
  cudaFree(key_value_d);

  InputFile inputFiles_h;

  for (size_t i = 0; i < num_inputs; ++i) {
    cudaMemcpy(&inputFiles_h, inputFiles_d + i, sizeof(InputFile),
               cudaMemcpyDeviceToHost);
    cudaFree(inputFiles_h.file);
  }

  cudaFree(inputFiles_d);
}

void EncodePrepare(size_t total_num_kv, std::vector<SSTableInfo>& infos) {
  uint32_t num_restarts = num_kv_data_block / BlockRestartInterval + 1;

  size_t max_num_kv = max_num_data_block * num_kv_data_block;

  size_t remaining_num_kv = total_num_kv;
  while (remaining_num_kv >= max_num_kv) {
    infos.emplace_back(max_num_data_block, num_restarts, max_num_kv, 0);
    remaining_num_kv -= max_num_kv;
  }

  if (remaining_num_kv > 0) {
    size_t num_data_block = remaining_num_kv / num_kv_data_block;
    size_t num_kv_last_data_block = remaining_num_kv % num_kv_data_block;
    uint32_t num_restarts_last_data_block = num_restarts;
    if (num_kv_last_data_block > 0) {
      num_data_block++;
      num_restarts_last_data_block =
          num_kv_last_data_block / BlockRestartInterval + 1;
    }
    infos.emplace_back(num_data_block, num_restarts_last_data_block,
                       remaining_num_kv, num_kv_last_data_block);
  }
}

void GPUFlush(GPUKeyValue* key_values, GPUKeyValue** key_values_d,
              char** all_files_buffer, size_t total_num_kv, size_t& sorted_size,
              size_t& num_files, size_t& estimate_file_size, size_t& data_size,
              size_t& index_size, size_t& data_size_last_file,
              size_t& index_size_last_file, uint32_t& num_restarts,
              uint32_t& num_restarts_last_data_block,
              uint64_t& num_data_blocks) {
  cudaMalloc((void**)key_values_d, total_num_kv * sizeof(GPUKeyValue));
  cudaMemcpy(*key_values_d, key_values, total_num_kv * sizeof(GPUKeyValue),
             cudaMemcpyHostToDevice);

  GPUSort(*key_values_d, total_num_kv, sorted_size);

  std::vector<SSTableInfo> infos;
  EncodePrepare(sorted_size, infos);
  num_data_blocks = infos[0].num_data_block;

  num_files = infos.size();

  BuildSSTables(*key_values_d, infos, all_files_buffer, estimate_file_size,
                data_size, index_size, data_size_last_file,
                index_size_last_file, num_restarts,
                num_restarts_last_data_block);
}
