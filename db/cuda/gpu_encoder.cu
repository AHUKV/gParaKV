//
// Created by ubuntu on 7/6/24.
//

#include "gpu_encoder.cuh"

__host__ __device__ uint32_t GPUComputeBuiltinChecksumWithLastByte(
    const char* data, size_t data_size, char last_type) {
  uint32_t crc = GPUValue(data, data_size);
  crc = GPUExtend(crc, &last_type, 1);
  return GPUMask(crc);
}

__device__ void BeginBuildDataBlock(
    uint32_t file_idx, uint32_t block_idx, char* current_block_buffer,
    GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_kv_current_data_block, uint32_t num_current_restarts,
    uint32_t* current_restarts, size_t size_current_data_block) {
  size_t shared = 0;
  size_t non_shared = keySize_ + 8;
  size_t encoded_size;

  for (size_t i = 0; i < num_kv_current_data_block; ++i) {
    GPUPutVarint32Varint32Varint32(
        current_block_buffer + key_value_size * i,
        static_cast<uint32_t>(shared), static_cast<uint32_t>(non_shared),
        static_cast<uint32_t>(valueSize_), encoded_size);

    memcpy(
        current_block_buffer + key_value_size * i + encoded_size,
        key_values_d[file_idx * num_kv_d + num_kv_data_block_d * block_idx + i]
            .key,
        non_shared);

    char* value =
        key_values_d[file_idx * num_kv_d + num_kv_data_block_d * block_idx + i]
            .value;

    memcpy(
        current_block_buffer + key_value_size * i + encoded_size + non_shared,
        value, valueSize_);
  }

  // 每个索引项中的key
  // num_data_block_d 指的是前面的文件的数据块数量
  memcpy(
      index_keys_d + (file_idx * num_data_block_d + block_idx) * (keySize_ + 8),
      key_values_d[file_idx * num_kv_d + num_kv_data_block_d * block_idx +
                   (num_kv_current_data_block - 1)]
          .key,
      keySize_ + 8);

  for (uint32_t i = 0; i < num_current_restarts; ++i) {
    GPUPutFixed32(current_block_buffer +
                      num_kv_current_data_block * key_value_size +
                      i * sizeof(uint32_t),
                  current_restarts[i]);
  }

  GPUPutFixed32(current_block_buffer +
                    num_kv_current_data_block * key_value_size +
                    num_current_restarts * sizeof(uint32_t),
                num_current_restarts);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_block_buffer, size_current_data_block - 5, type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_block_buffer + size_current_data_block - 5, trailer, 5);
}

__global__ void BuildDataBlocksKernel(char* buffer_d, GPUKeyValue* key_values_d,
                                      char* index_keys_d,
                                      uint32_t* restarts_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  char* current_block_buffer = buffer_d + file_idx * size_file_d +
                               block_idx * size_complete_data_block_d;

  BeginBuildDataBlock(file_idx, block_idx, current_block_buffer, key_values_d,
                      index_keys_d, num_kv_data_block_d, num_restarts_d,
                      restarts_d, size_complete_data_block_d);
}

__global__ void BuildDataBlocksLastFileKernel(char* buffer_d,
                                              GPUKeyValue* key_values_d,
                                              char* index_keys_d,
                                              uint32_t* restarts_d) {
  uint32_t file_idx = num_outputs_d - 1;
  uint32_t block_idx = blockIdx.x;

  char* current_block_buffer = buffer_d + file_idx * size_file_d +
                               block_idx * size_complete_data_block_d;

  BeginBuildDataBlock(file_idx, block_idx, current_block_buffer, key_values_d,
                      index_keys_d, num_kv_data_block_d, num_restarts_d,
                      restarts_d, size_complete_data_block_d);
}

__global__ void BuildLastDataBlockLastFileKernel(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_data_block_last_file, size_t num_kv_last_data_block_last_file,
    uint32_t num_restarts_last_data_block_last_file,
    uint32_t* restarts_last_data_block_last_file_d,
    size_t size_incomplete_data_block) {
  uint32_t file_idx = num_outputs_d - 1;
  uint32_t block_idx = num_data_block_last_file - 1;

  char* current_block_buffer = buffer_d + file_idx * size_file_d +
                               block_idx * size_complete_data_block_d;

  BeginBuildDataBlock(
      file_idx, block_idx, current_block_buffer, key_values_d, index_keys_d,
      num_kv_last_data_block_last_file, num_restarts_last_data_block_last_file,
      restarts_last_data_block_last_file_d, size_incomplete_data_block);
}

void BuildDataBlocks(char* buffer_d, GPUKeyValue* key_values_d,
                     char* index_keys_d, uint32_t* restarts_d,
                     size_t num_data_block, size_t num_outputs,
                     size_t num_kv_last_data_block,
                     size_t num_data_block_last_file,
                     uint32_t* restarts_last_data_block_d,
                     uint32_t num_restarts_last_data_block,
                     size_t size_incomplete_data_block, cudaStream_t* stream) {
  if (num_outputs > 1) {
    dim3 block(num_outputs - 1);
    dim3 grid(num_data_block);

    BuildDataBlocksKernel<<<grid, block, 0, stream[0]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);
  }

  if (num_kv_last_data_block == 0) {
    dim3 block(1);
    dim3 grid(num_data_block_last_file);

    BuildDataBlocksLastFileKernel<<<grid, block, 0, stream[1]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);
  } else {
    dim3 block(1);
    dim3 grid(num_data_block_last_file - 1);

    BuildDataBlocksLastFileKernel<<<grid, block, 0, stream[1]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);

    BuildLastDataBlockLastFileKernel<<<1, 1, 0, stream[2]>>>(
        buffer_d, key_values_d, index_keys_d, num_data_block_last_file,
        num_kv_last_data_block, num_restarts_last_data_block,
        restarts_last_data_block_d, size_incomplete_data_block);
  }
}

__device__ void BeginBuildDataBlockForCompaction(
    uint32_t file_idx, uint32_t block_idx, char* current_block_buffer,
    GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_kv_current_data_block, uint32_t num_current_restarts,
    uint32_t* current_restarts, size_t size_current_data_block) {
  size_t shared = 0;
  size_t non_shared = keySize_ + 8;
  size_t encoded_size;

  for (size_t i = 0; i < num_kv_current_data_block; ++i) {
    GPUPutVarint32Varint32Varint32(
        current_block_buffer + key_value_size * i,
        static_cast<uint32_t>(shared), static_cast<uint32_t>(non_shared),
        static_cast<uint32_t>(valueSize_), encoded_size);

    memcpy(current_block_buffer + key_value_size * i + encoded_size,
           key_values_d[file_idx * num_kv_compaction_d +
                        num_kv_data_block_compaction_d * block_idx + i]
               .key,
           non_shared);

    char* value = key_values_d[file_idx * num_kv_compaction_d +
                               num_kv_data_block_compaction_d * block_idx + i]
                      .value;
    memcpy(
        current_block_buffer + key_value_size * i + encoded_size + non_shared,
        value, valueSize_);
  }

  // 每个索引项中的key
  // num_data_block_d 指的是前面的文件的数据块数量
  memcpy(index_keys_d + (file_idx * num_data_block_compaction_d + block_idx) *
                            (keySize_ + 8),
         key_values_d[file_idx * num_kv_compaction_d +
                      num_kv_data_block_compaction_d * block_idx +
                      (num_kv_current_data_block - 1)]
             .key,
         keySize_ + 8);

  for (uint32_t i = 0; i < num_current_restarts; ++i) {
    GPUPutFixed32(current_block_buffer +
                      num_kv_current_data_block * key_value_size +
                      i * sizeof(uint32_t),
                  current_restarts[i]);
  }

  GPUPutFixed32(current_block_buffer +
                    num_kv_current_data_block * key_value_size +
                    num_current_restarts * sizeof(uint32_t),
                num_current_restarts);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_block_buffer, size_current_data_block - 5, type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_block_buffer + size_current_data_block - 5, trailer, 5);
}

__global__ void BuildDataBlocksKernelForCompaction(char* buffer_d,
                                                   GPUKeyValue* key_values_d,
                                                   char* index_keys_d,
                                                   uint32_t* restarts_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  char* current_block_buffer =
      buffer_d + file_idx * size_file_compaction_d +
      block_idx * size_complete_data_block_compaction_d;

  BeginBuildDataBlockForCompaction(
      file_idx, block_idx, current_block_buffer, key_values_d, index_keys_d,
      num_kv_data_block_compaction_d, num_restarts_compaction_d, restarts_d,
      size_complete_data_block_compaction_d);
}

__global__ void BuildDataBlocksLastFileKernelForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    uint32_t* restarts_d) {
  uint32_t file_idx = num_outputs_compaction_d - 1;
  uint32_t block_idx = blockIdx.x;

  char* current_block_buffer =
      buffer_d + file_idx * size_file_compaction_d +
      block_idx * size_complete_data_block_compaction_d;

  BeginBuildDataBlockForCompaction(
      file_idx, block_idx, current_block_buffer, key_values_d, index_keys_d,
      num_kv_data_block_compaction_d, num_restarts_compaction_d, restarts_d,
      size_complete_data_block_compaction_d);
}

__global__ void BuildLastDataBlockLastFileKernelForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    size_t num_data_block_last_file, size_t num_kv_last_data_block_last_file,
    uint32_t num_restarts_last_data_block_last_file,
    uint32_t* restarts_last_data_block_last_file_d,
    size_t size_incomplete_data_block) {
  uint32_t file_idx = num_outputs_compaction_d - 1;
  uint32_t block_idx = num_data_block_last_file - 1;

  char* current_block_buffer =
      buffer_d + file_idx * size_file_compaction_d +
      block_idx * size_complete_data_block_compaction_d;

  BeginBuildDataBlockForCompaction(
      file_idx, block_idx, current_block_buffer, key_values_d, index_keys_d,
      num_kv_last_data_block_last_file, num_restarts_last_data_block_last_file,
      restarts_last_data_block_last_file_d, size_incomplete_data_block);
}

void BuildDataBlocksForCompaction(
    char* buffer_d, GPUKeyValue* key_values_d, char* index_keys_d,
    uint32_t* restarts_d, size_t num_data_block, size_t num_outputs,
    size_t num_kv_last_data_block, size_t num_data_block_last_file,
    uint32_t* restarts_last_data_block_d, uint32_t num_restarts_last_data_block,
    size_t size_incomplete_data_block, cudaStream_t* stream) {
  if (num_outputs > 1) {
    dim3 block(num_outputs - 1);
    dim3 grid(num_data_block);

    BuildDataBlocksKernelForCompaction<<<grid, block, 0, stream[0]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);
  }

  if (num_kv_last_data_block == 0) {
    dim3 block(1);
    dim3 grid(num_data_block_last_file);

    BuildDataBlocksLastFileKernelForCompaction<<<grid, block, 0, stream[1]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);
  } else {
    dim3 block(1);
    dim3 grid(num_data_block_last_file - 1);

    BuildDataBlocksLastFileKernelForCompaction<<<grid, block, 0, stream[1]>>>(
        buffer_d, key_values_d, index_keys_d, restarts_d);

    BuildLastDataBlockLastFileKernelForCompaction<<<1, 1, 0, stream[2]>>>(
        buffer_d, key_values_d, index_keys_d, num_data_block_last_file,
        num_kv_last_data_block, num_restarts_last_data_block,
        restarts_last_data_block_d, size_incomplete_data_block);
  }
}

__global__ void ComputeDataBlockHandleKernel(GPUBlockHandle* block_handles_d,
                                             uint32_t* restarts_for_index_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  block_handles_d[file_idx * num_data_block_d + block_idx].set_offset(
      block_idx * size_complete_data_block_d);
  block_handles_d[file_idx * num_data_block_d + block_idx].set_size(
      size_complete_data_block_d - 5);

  if (file_idx == 0)
    restarts_for_index_d[block_idx] = size_index_entry * block_idx;
}

__global__ void ComputeDataBlockHandleLastFileKernel(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t num_data_block_last_file) {
  uint32_t file_idx = num_outputs_d - 1;
  uint32_t block_idx = blockIdx.x;

  block_handles_d[file_idx * num_data_block_d + block_idx].set_offset(
      block_idx * size_complete_data_block_d);
  block_handles_d[file_idx * num_data_block_d + block_idx].set_size(
      size_complete_data_block_d - 5);

  restarts_for_index_last_file_d[block_idx] = size_index_entry * block_idx;

  if (block_idx == num_data_block_last_file - 1) {
    block_handles_d[file_idx * num_data_block_d + block_idx].set_size(
        size_incomplete_data_block - 5);
  }
}

__device__ void BeginBuildIndexBlock(uint32_t file_idx, uint32_t block_idx,
                                     char* current_index_buffer,
                                     char* index_keys_d,
                                     GPUBlockHandle* block_handles_d,
                                     uint32_t* current_restarts,
                                     size_t current_num_data_block) {
  size_t shared = 0;
  size_t non_shared = keySize_ + 8;
  size_t encoded_size;

  GPUPutVarint32Varint32Varint32(
      current_index_buffer + size_index_entry * block_idx,
      static_cast<uint32_t>(shared), static_cast<uint32_t>(non_shared),
      encoded_index_entry, encoded_size);

  memcpy(
      current_index_buffer + size_index_entry * block_idx + encoded_size,
      index_keys_d + (file_idx * num_data_block_d + block_idx) * (keySize_ + 8),
      keySize_ + 8);

  GPUPutFixed64Fixed32(
      current_index_buffer + size_index_entry * block_idx + encoded_size +
          keySize_ + 8,
      block_handles_d[file_idx * num_data_block_d + block_idx].offset(),
      block_handles_d[file_idx * num_data_block_d + block_idx].size());

  char* restarts_buffer = current_index_buffer +
                          size_index_entry * current_num_data_block +
                          block_idx * sizeof(uint32_t);

  GPUPutFixed32(restarts_buffer, current_restarts[block_idx]);
}

__global__ void BuildIndexBlockKernel(char* buffer_d, char* index_keys_d,
                                      GPUBlockHandle* block_handles_d,
                                      uint32_t* restarts_for_index_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  char* current_index_buffer = buffer_d + file_idx * size_file_d + data_size_d;

  BeginBuildIndexBlock(file_idx, block_idx, current_index_buffer, index_keys_d,
                       block_handles_d, restarts_for_index_d, num_data_block_d);
}

__global__ void BuildIndexBlockLastFileKernel(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_last_file_d, size_t num_data_block_last_file,
    size_t data_size_last_file) {
  uint32_t file_idx = num_outputs_d - 1;
  uint32_t block_idx = blockIdx.x;

  char* current_index_buffer =
      buffer_d + file_idx * size_file_d + data_size_last_file;

  BeginBuildIndexBlock(file_idx, block_idx, current_index_buffer, index_keys_d,
                       block_handles_d, restarts_for_index_last_file_d,
                       num_data_block_last_file);
}

__global__ void ComputeChecksumKernel(char* buffer_d) {
  uint32_t file_idx = threadIdx.x;

  char* current_buffer =
      buffer_d + file_idx * size_file_d + data_size_d + index_size_d;

  GPUPutFixed32(current_buffer - 9, num_data_block_d);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_buffer - index_size_d, index_size_d - 5, type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_buffer - 5, trailer, 5);
}

__global__ void ComputeChecksumLastFileKernel(char* buffer_d,
                                              size_t num_data_block_last_file,
                                              size_t data_size_last_file,
                                              size_t index_size_last_file) {
  uint32_t file_idx = num_outputs_d - 1;

  char* current_buffer = buffer_d + file_idx * size_file_d +
                         data_size_last_file + index_size_last_file;

  GPUPutFixed32(current_buffer - 9, num_data_block_last_file);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_buffer - index_size_last_file, index_size_last_file - 5, type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_buffer - 5, trailer, 5);
}

void BuildIndexBlocks(char* buffer_d, char* index_keys_d,
                      GPUBlockHandle* block_handles_d, size_t num_outputs,
                      size_t num_data_block, uint32_t* restarts_for_index_d,
                      size_t num_data_block_last_file,
                      uint32_t* restarts_for_index_last_file_d,
                      size_t size_incomplete_data_block,
                      size_t data_size_last_file, size_t index_size_last_file,
                      cudaStream_t* stream) {
  if (num_outputs > 1) {
    dim3 block(num_outputs - 1);
    dim3 grid(num_data_block);

    ComputeDataBlockHandleKernel<<<grid, block, 0, stream[1]>>>(
        block_handles_d, restarts_for_index_d);

    // 第二个核函数需要第一个核函数的结果，它们使用同一个流，所以不需要进行同步
    BuildIndexBlockKernel<<<grid, block, 0, stream[1]>>>(
        buffer_d, index_keys_d, block_handles_d, restarts_for_index_d);

    ComputeChecksumKernel<<<1, block, 0, stream[1]>>>(buffer_d);
  }

  dim3 block(1);
  dim3 grid(num_data_block_last_file);

  ComputeDataBlockHandleLastFileKernel<<<grid, block, 0, stream[2]>>>(
      block_handles_d, restarts_for_index_last_file_d,
      size_incomplete_data_block, num_data_block_last_file);

  BuildIndexBlockLastFileKernel<<<grid, block, 0, stream[2]>>>(
      buffer_d, index_keys_d, block_handles_d, restarts_for_index_last_file_d,
      num_data_block_last_file, data_size_last_file);

  ComputeChecksumLastFileKernel<<<1, 1, 0, stream[2]>>>(
      buffer_d, num_data_block_last_file, data_size_last_file,
      index_size_last_file);
}

__global__ void ComputeDataBlockHandleKernelForCompaction(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  block_handles_d[file_idx * num_data_block_compaction_d + block_idx]
      .set_offset(block_idx * size_complete_data_block_compaction_d);
  block_handles_d[file_idx * num_data_block_compaction_d + block_idx].set_size(
      size_complete_data_block_compaction_d - 5);

  if (file_idx == 0)
    restarts_for_index_d[block_idx] = size_index_entry * block_idx;
}

__global__ void ComputeDataBlockHandleLastFileKernelForCompaction(
    GPUBlockHandle* block_handles_d, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t num_data_block_last_file) {
  uint32_t file_idx = num_outputs_compaction_d - 1;
  uint32_t block_idx = blockIdx.x;

  block_handles_d[file_idx * num_data_block_compaction_d + block_idx]
      .set_offset(block_idx * size_complete_data_block_compaction_d);
  block_handles_d[file_idx * num_data_block_compaction_d + block_idx].set_size(
      size_complete_data_block_compaction_d - 5);

  restarts_for_index_last_file_d[block_idx] = size_index_entry * block_idx;

  if (block_idx == num_data_block_last_file - 1) {
    block_handles_d[file_idx * num_data_block_compaction_d + block_idx]
        .set_size(size_incomplete_data_block - 5);
  }
}

__device__ void BeginBuildIndexBlockForCompaction(
    uint32_t file_idx, uint32_t block_idx, char* current_index_buffer,
    char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* current_restarts, size_t current_num_data_block) {
  size_t shared = 0;
  size_t non_shared = keySize_ + 8;
  size_t encoded_size;

  GPUPutVarint32Varint32Varint32(
      current_index_buffer + size_index_entry * block_idx,
      static_cast<uint32_t>(shared), static_cast<uint32_t>(non_shared),
      encoded_index_entry, encoded_size);

  memcpy(current_index_buffer + size_index_entry * block_idx + encoded_size,
         index_keys_d + (file_idx * num_data_block_compaction_d + block_idx) *
                            (keySize_ + 8),
         keySize_ + 8);

  GPUPutFixed64Fixed32(
      current_index_buffer + size_index_entry * block_idx + encoded_size +
          keySize_ + 8,
      block_handles_d[file_idx * num_data_block_compaction_d + block_idx]
          .offset(),
      block_handles_d[file_idx * num_data_block_compaction_d + block_idx]
          .size());

  char* restarts_buffer = current_index_buffer +
                          size_index_entry * current_num_data_block +
                          block_idx * sizeof(uint32_t);

  GPUPutFixed32(restarts_buffer, current_restarts[block_idx]);
}

__global__ void BuildIndexBlockKernelForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_d) {
  uint32_t file_idx = threadIdx.x;
  uint32_t block_idx = blockIdx.x;

  char* current_index_buffer =
      buffer_d + file_idx * size_file_compaction_d + data_size_compaction_d;

  BeginBuildIndexBlockForCompaction(
      file_idx, block_idx, current_index_buffer, index_keys_d, block_handles_d,
      restarts_for_index_d, num_data_block_compaction_d);
}

__global__ void BuildIndexBlockLastFileKernelForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    uint32_t* restarts_for_index_last_file_d, size_t num_data_block_last_file,
    size_t data_size_last_file) {
  uint32_t file_idx = num_outputs_compaction_d - 1;
  uint32_t block_idx = blockIdx.x;

  char* current_index_buffer =
      buffer_d + file_idx * size_file_compaction_d + data_size_last_file;

  BeginBuildIndexBlockForCompaction(
      file_idx, block_idx, current_index_buffer, index_keys_d, block_handles_d,
      restarts_for_index_last_file_d, num_data_block_last_file);
}

__global__ void ComputeChecksumKernelForCompaction(char* buffer_d) {
  uint32_t file_idx = threadIdx.x;

  char* current_buffer = buffer_d + file_idx * size_file_compaction_d +
                         data_size_compaction_d + index_size_compaction_d;

  GPUPutFixed32(current_buffer - 9, num_data_block_compaction_d);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_buffer - index_size_compaction_d, index_size_compaction_d - 5,
      type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_buffer - 5, trailer, 5);
}

__global__ void ComputeChecksumLastFileKernelForCompaction(
    char* buffer_d, size_t num_data_block_last_file, size_t data_size_last_file,
    size_t index_size_last_file) {
  uint32_t file_idx = num_outputs_compaction_d - 1;

  char* current_buffer = buffer_d + file_idx * size_file_compaction_d +
                         data_size_last_file + index_size_last_file;

  GPUPutFixed32(current_buffer - 9, num_data_block_last_file);

  char trailer[5];
  char type = 0x0;
  trailer[0] = type;
  uint32_t checksum = GPUComputeBuiltinChecksumWithLastByte(
      current_buffer - index_size_last_file, index_size_last_file - 5, type);
  GPUEncodeFixed32(trailer + 1, checksum);

  memcpy(current_buffer - 5, trailer, 5);
}

void BuildIndexBlocksForCompaction(
    char* buffer_d, char* index_keys_d, GPUBlockHandle* block_handles_d,
    size_t num_outputs, size_t num_data_block, uint32_t* restarts_for_index_d,
    size_t num_data_block_last_file, uint32_t* restarts_for_index_last_file_d,
    size_t size_incomplete_data_block, size_t data_size_last_file,
    size_t index_size_last_file, cudaStream_t* stream) {
  if (num_outputs > 1) {
    dim3 block(num_outputs - 1);
    dim3 grid(num_data_block);

    ComputeDataBlockHandleKernelForCompaction<<<grid, block, 0, stream[1]>>>(
        block_handles_d, restarts_for_index_d);

    // 第二个核函数需要第一个核函数的结果，它们使用同一个流，所以不需要进行同步
    BuildIndexBlockKernelForCompaction<<<grid, block, 0, stream[1]>>>(
        buffer_d, index_keys_d, block_handles_d, restarts_for_index_d);

    ComputeChecksumKernelForCompaction<<<1, block, 0, stream[1]>>>(buffer_d);
  }

  dim3 block(1);
  dim3 grid(num_data_block_last_file);

  ComputeDataBlockHandleLastFileKernelForCompaction<<<grid, block, 0,
                                                      stream[2]>>>(
      block_handles_d, restarts_for_index_last_file_d,
      size_incomplete_data_block, num_data_block_last_file);

  BuildIndexBlockLastFileKernelForCompaction<<<grid, block, 0, stream[2]>>>(
      buffer_d, index_keys_d, block_handles_d, restarts_for_index_last_file_d,
      num_data_block_last_file, data_size_last_file);

  ComputeChecksumLastFileKernelForCompaction<<<1, 1, 0, stream[2]>>>(
      buffer_d, num_data_block_last_file, data_size_last_file,
      index_size_last_file);

  CHECK(cudaStreamSynchronize(stream[2]));
}

void BuildSSTables(GPUKeyValue* key_value_d, std::vector<SSTableInfo>& infos,
                   char** all_files_buffer, size_t& estimate_file_size,
                   size_t& data_size, size_t& index_size,
                   size_t& data_size_last_file, size_t& index_size_last_file,
                   uint32_t& num_restarts,
                   uint32_t& num_restarts_last_data_block) {
  size_t num_outputs = infos.size();

  cudaStream_t stream[4];
  for (auto& s : stream) {
    cudaStreamCreate(&s);
  }

  num_restarts = infos[0].num_restarts;  // 完整数据块的restarts数量

  // 最后一个数据块的restarts数量
  num_restarts_last_data_block = infos[num_outputs - 1].num_restarts;
  // 最后一个文件的数据块数量
  size_t num_data_block_last_file = infos[num_outputs - 1].num_data_block;
  // 最后一个数据块的KV对数量
  size_t num_kv_last_data_block = infos[num_outputs - 1].num_kv_last_data_block;

  // 完整数据块大小
  size_t size_complete_data_block = key_value_size * num_kv_data_block +
                                    (num_restarts + 1) * sizeof(uint32_t) + 5;

  // 非完整数据块大小
  size_t size_incomplete_data_block;
  if (num_kv_last_data_block == 0) {
    size_incomplete_data_block = size_complete_data_block;
  } else {
    size_incomplete_data_block =
        key_value_size * num_kv_last_data_block +
        (num_restarts_last_data_block + 1) * sizeof(uint32_t) + 5;
  }

  // 数据块大小
  // 数据总数量 * size_complete_data_block + size_incomplete_data_block

  // 索引块大小
  // 数据块数量 * (size_index_entry + sizeof(uint32_t)) + sizeof(uint32_t) + 5

  // 一个SSTable大小的估计值
  // data_size + index_size + 2048 - (data_size + index_size) % 2048

  size_t num_kv, num_data_block = 0;
  if (num_outputs > 1) {
    num_kv = infos[0].total_num_kv;
    num_data_block = infos[0].num_data_block;
    data_size = num_data_block * size_complete_data_block;
    index_size = num_data_block * (size_index_entry + sizeof(uint32_t)) +
                 sizeof(uint32_t) + 5;

    estimate_file_size =
        data_size + index_size + 1024 - (data_size + index_size) % 1024;
  }

  data_size_last_file =
      (num_data_block_last_file - 1) * size_complete_data_block +
      size_incomplete_data_block;
  index_size_last_file =
      num_data_block_last_file * (size_index_entry + sizeof(uint32_t)) +
      sizeof(uint32_t) + 5;

  size_t estimate_last_file_size =
      data_size_last_file + index_size_last_file + 1024 -
      (data_size_last_file + index_size_last_file) % 1024;

  // 编码后所有SSTable的大小的估计值
  size_t total_estimate_file_size =
      (num_outputs - 1) * estimate_file_size + estimate_last_file_size;
  // index_keys 用
  size_t total_num_all_data_blocks =
      (num_outputs - 1) * num_data_block + num_data_block_last_file;

  // 申请主机内存
  // 数据块的restarts
  auto* restarts = new uint32_t[num_restarts];
  for (uint32_t i = 0; i < num_restarts; ++i) {
    restarts[i] = BlockRestartInterval * key_value_size * i;
  }

  // 最后一个文件的最后一个数据块的restarts信息
  auto* restarts_last_data_block = new uint32_t[num_restarts_last_data_block];
  for (uint32_t i = 0; i < num_restarts_last_data_block; ++i) {
    restarts_last_data_block[i] = BlockRestartInterval * key_value_size * i;
  }

  *all_files_buffer = new char[total_estimate_file_size];

  // 申请设备内存
  // 数据块
  char* all_files_buffer_d;
  char* index_keys_d;

  // 索引块
  GPUBlockHandle* block_handles_d;
  uint32_t* restarts_for_index_d;
  uint32_t* restarts_for_index_last_file_d;

  // 数据块的重启点
  uint32_t* restarts_d;
  uint32_t* restarts_last_data_block_d;

  cudaMallocAsync(&all_files_buffer_d, total_estimate_file_size, stream[0]);
  cudaMallocAsync(&index_keys_d, total_num_all_data_blocks * (keySize_ + 8),
                  stream[1]);
  cudaMallocAsync(&block_handles_d,
                  total_num_all_data_blocks * sizeof(GPUBlockHandle),
                  stream[2]);
  cudaMallocAsync(&restarts_for_index_d, num_data_block * sizeof(uint32_t),
                  stream[3]);
  cudaMallocAsync(&restarts_d, num_restarts * sizeof(uint32_t), stream[0]);
  cudaMallocAsync(&restarts_last_data_block_d,
                  num_restarts_last_data_block * sizeof(uint32_t), stream[1]);
  cudaMallocAsync(&restarts_for_index_last_file_d,
                  num_data_block_last_file * sizeof(uint32_t), stream[2]);

  // 数据传输
  // 常量内存
  cudaMemcpyToSymbolAsync(num_data_block_d, &num_data_block, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[1]);
  cudaMemcpyToSymbolAsync(num_restarts_d, &num_restarts, sizeof(uint32_t), 0,
                          cudaMemcpyHostToDevice, stream[2]);
  cudaMemcpyToSymbolAsync(size_complete_data_block_d, &size_complete_data_block,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[3]);
  cudaMemcpyToSymbolAsync(num_kv_d, &num_kv, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[0]);
  cudaMemcpyToSymbolAsync(size_file_d, &estimate_file_size, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[1]);
  cudaMemcpyToSymbolAsync(num_outputs_d, &num_outputs, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[2]);
  cudaMemcpyToSymbolAsync(data_size_d, &data_size, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[3]);
  cudaMemcpyToSymbolAsync(index_size_d, &index_size, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[0]);
  cudaMemcpyToSymbolAsync(num_kv_data_block_d, &num_kv_data_block,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[1]);

  // 全局内存
  auto start_time = std::chrono::high_resolution_clock::now();
  cudaMemcpyAsync(restarts_d, restarts, num_restarts * sizeof(uint32_t),
                  cudaMemcpyHostToDevice, stream[2]);
  cudaMemcpyAsync(restarts_last_data_block_d, restarts_last_data_block,
                  num_restarts_last_data_block * sizeof(uint32_t),
                  cudaMemcpyHostToDevice, stream[3]);
  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
      end_time - start_time);
  leveldb::my_stats.data_transfer_time += duration.count();

  for (auto& s : stream) {
    CHECK(cudaStreamSynchronize(s));
  }

  BuildDataBlocks(all_files_buffer_d, key_value_d, index_keys_d, restarts_d,
                  num_data_block, num_outputs, num_kv_last_data_block,
                  num_data_block_last_file, restarts_last_data_block_d,
                  num_restarts_last_data_block, size_incomplete_data_block,
                  stream);

  BuildIndexBlocks(all_files_buffer_d, index_keys_d, block_handles_d,
                   num_outputs, num_data_block, restarts_for_index_d,
                   num_data_block_last_file, restarts_for_index_last_file_d,
                   size_incomplete_data_block, data_size_last_file,
                   index_size_last_file, stream);

  for (auto& s : stream) {
    CHECK(cudaStreamSynchronize(s));
  }

  start_time = std::chrono::high_resolution_clock::now();
  cudaMemcpy(*all_files_buffer, all_files_buffer_d, total_estimate_file_size,
             cudaMemcpyDeviceToHost);
  end_time = std::chrono::high_resolution_clock::now();
  duration = std::chrono::duration_cast<std::chrono::microseconds>(
      end_time - start_time);
  leveldb::my_stats.data_transfer_time += duration.count();

  // 释放资源
  cudaFree(all_files_buffer_d);
  cudaFree(index_keys_d);
  cudaFree(restarts_last_data_block_d);
  cudaFree(block_handles_d);
  cudaFree(restarts_for_index_d);
  cudaFree(restarts_for_index_last_file_d);
  cudaFree(restarts_d);

  for (auto& s : stream) {
    cudaStreamDestroy(s);
  }

  delete[] restarts;
  delete[] restarts_last_data_block;
}

void BuildSSTablesForCompaction(GPUKeyValue* key_value_d,
                                std::vector<SSTableInfo>& infos,
                                char** all_files_buffer,
                                size_t& estimate_file_size, size_t& data_size,
                                size_t& index_size, size_t& data_size_last_file,
                                size_t& index_size_last_file,
                                uint32_t& num_restarts,
                                uint32_t& num_restarts_last_data_block) {
  size_t num_outputs = infos.size();

  cudaStream_t stream[4];
  for (auto& s : stream) {
    cudaStreamCreate(&s);
  }

  num_restarts = infos[0].num_restarts;  // 完整数据块的restarts数量

  // 最后一个数据块的restarts数量
  num_restarts_last_data_block = infos[num_outputs - 1].num_restarts;
  // 最后一个文件的数据块数量
  size_t num_data_block_last_file = infos[num_outputs - 1].num_data_block;
  // 最后一个数据块的KV对数量
  size_t num_kv_last_data_block = infos[num_outputs - 1].num_kv_last_data_block;

  // 完整数据块大小
  size_t size_complete_data_block = key_value_size * num_kv_data_block +
                                    (num_restarts + 1) * sizeof(uint32_t) + 5;

  // 非完整数据块大小
  size_t size_incomplete_data_block;
  if (num_kv_last_data_block == 0) {
    size_incomplete_data_block = size_complete_data_block;
  } else {
    size_incomplete_data_block =
        key_value_size * num_kv_last_data_block +
        (num_restarts_last_data_block + 1) * sizeof(uint32_t) + 5;
  }

  // 数据块大小
  // 数据总数量 * size_complete_data_block + size_incomplete_data_block

  // 索引块大小
  // 数据块数量 * (size_index_entry + sizeof(uint32_t)) + sizeof(uint32_t) + 5

  // 一个SSTable大小的估计值
  // data_size + index_size + 2048 - (data_size + index_size) % 2048

  size_t num_kv = 0, num_data_block = 0;
  if (num_outputs > 1) {
    num_kv = infos[0].total_num_kv;
    num_data_block = infos[0].num_data_block;
    data_size = num_data_block * size_complete_data_block;
    index_size = num_data_block * (size_index_entry + sizeof(uint32_t)) +
                 sizeof(uint32_t) + 5;

    estimate_file_size =
        data_size + index_size + 1024 - (data_size + index_size) % 1024;
  }

  data_size_last_file =
      (num_data_block_last_file - 1) * size_complete_data_block +
      size_incomplete_data_block;
  index_size_last_file =
      num_data_block_last_file * (size_index_entry + sizeof(uint32_t)) +
      sizeof(uint32_t) + 5;

  size_t estimate_last_file_size =
      data_size_last_file + index_size_last_file + 1024 -
      (data_size_last_file + index_size_last_file) % 1024;

  // 编码后所有SSTable的大小的估计值
  size_t total_estimate_file_size =
      (num_outputs - 1) * estimate_file_size + estimate_last_file_size;
  // index_keys 用
  size_t total_num_all_data_blocks =
      (num_outputs - 1) * num_data_block + num_data_block_last_file;

  // 申请主机内存
  // 数据块的restarts
  auto* restarts = new uint32_t[num_restarts];
  for (uint32_t i = 0; i < num_restarts; ++i) {
    restarts[i] = BlockRestartInterval * key_value_size * i;
  }

  // 最后一个文件的最后一个数据块的restarts信息
  auto* restarts_last_data_block = new uint32_t[num_restarts_last_data_block];
  for (uint32_t i = 0; i < num_restarts_last_data_block; ++i) {
    restarts_last_data_block[i] = BlockRestartInterval * key_value_size * i;
  }

  *all_files_buffer = new char[total_estimate_file_size];

  // 申请设备内存
  // 数据块
  char* all_files_buffer_d;
  char* index_keys_d;

  // 索引块
  GPUBlockHandle* block_handles_d;
  uint32_t* restarts_for_index_d;
  uint32_t* restarts_for_index_last_file_d;

  // 数据块的重启点
  uint32_t* restarts_d;
  uint32_t* restarts_last_data_block_d;

  cudaMallocAsync(&all_files_buffer_d, total_estimate_file_size, stream[0]);
  cudaMallocAsync(&index_keys_d, total_num_all_data_blocks * (keySize_ + 8),
                  stream[1]);
  cudaMallocAsync(&block_handles_d,
                  total_num_all_data_blocks * sizeof(GPUBlockHandle),
                  stream[2]);
  cudaMallocAsync(&restarts_for_index_d, num_data_block * sizeof(uint32_t),
                  stream[3]);
  cudaMallocAsync(&restarts_d, num_restarts * sizeof(uint32_t), stream[0]);
  cudaMallocAsync(&restarts_last_data_block_d,
                  num_restarts_last_data_block * sizeof(uint32_t), stream[1]);
  cudaMallocAsync(&restarts_for_index_last_file_d,
                  num_data_block_last_file * sizeof(uint32_t), stream[2]);

  // 数据传输
  // 常量内存
  cudaMemcpyToSymbolAsync(num_data_block_compaction_d, &num_data_block,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[1]);
  cudaMemcpyToSymbolAsync(num_restarts_compaction_d, &num_restarts,
                          sizeof(uint32_t), 0, cudaMemcpyHostToDevice,
                          stream[2]);
  cudaMemcpyToSymbolAsync(size_complete_data_block_compaction_d,
                          &size_complete_data_block, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[3]);
  cudaMemcpyToSymbolAsync(num_kv_compaction_d, &num_kv, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[0]);
  cudaMemcpyToSymbolAsync(size_file_compaction_d, &estimate_file_size,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[1]);
  cudaMemcpyToSymbolAsync(num_outputs_compaction_d, &num_outputs,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[2]);
  cudaMemcpyToSymbolAsync(data_size_compaction_d, &data_size, sizeof(size_t), 0,
                          cudaMemcpyHostToDevice, stream[3]);
  cudaMemcpyToSymbolAsync(index_size_compaction_d, &index_size, sizeof(size_t),
                          0, cudaMemcpyHostToDevice, stream[0]);
  cudaMemcpyToSymbolAsync(num_kv_data_block_compaction_d, &num_kv_data_block,
                          sizeof(size_t), 0, cudaMemcpyHostToDevice, stream[1]);

  // 全局内存
  cudaMemcpyAsync(restarts_d, restarts, num_restarts * sizeof(uint32_t),
                  cudaMemcpyHostToDevice, stream[2]);
  cudaMemcpyAsync(restarts_last_data_block_d, restarts_last_data_block,
                  num_restarts_last_data_block * sizeof(uint32_t),
                  cudaMemcpyHostToDevice, stream[3]);

  for (auto& s : stream) {
    CHECK(cudaStreamSynchronize(s));
  }

  BuildDataBlocksForCompaction(
      all_files_buffer_d, key_value_d, index_keys_d, restarts_d, num_data_block,
      num_outputs, num_kv_last_data_block, num_data_block_last_file,
      restarts_last_data_block_d, num_restarts_last_data_block,
      size_incomplete_data_block, stream);

  BuildIndexBlocksForCompaction(
      all_files_buffer_d, index_keys_d, block_handles_d, num_outputs,
      num_data_block, restarts_for_index_d, num_data_block_last_file,
      restarts_for_index_last_file_d, size_incomplete_data_block,
      data_size_last_file, index_size_last_file, stream);

  for (auto& s : stream) {
    cudaStreamDestroy(s);
  }

  cudaMemcpy(*all_files_buffer, all_files_buffer_d, total_estimate_file_size,
             cudaMemcpyDeviceToHost);

  // 释放资源
  cudaFree(all_files_buffer_d);
  cudaFree(index_keys_d);
  cudaFree(restarts_last_data_block_d);
  cudaFree(block_handles_d);
  cudaFree(restarts_for_index_d);
  cudaFree(restarts_for_index_last_file_d);
  cudaFree(restarts_d);

  for (auto& s : stream) {
    cudaStreamDestroy(s);
  }

  delete[] restarts;
  delete[] restarts_last_data_block;
}
