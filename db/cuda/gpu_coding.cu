//
// Created by ubuntu on 7/6/24.
//

#include "gpu_coding.cuh"
#include "gpu_options.cuh"

__host__ __device__ char* GPUEncodeVarint32(char* dst, uint32_t v) {
  auto* ptr = reinterpret_cast<unsigned char*>(dst);
  static const int B = 128;
  if (v <
      (1 << 7)) {  // 编码为一个字节, 最高位（第 7 位）为 0, 其余 7 位表示数值
    *(ptr++) = v;
  } else if (v < (1 << 14)) {
    // 编码为两个字节，第一个字节的最高位（第 7 位）为 1，其余 7 位表示 v 的低 7
    // 位； 第二个字节的最高位（第 7 位）为 0，其余 7 位表示 v 的高 7 位；
    *(ptr++) = v | B;
    *(ptr++) = v >> 7;
  } else if (v < (1 << 21)) {
    *(ptr++) = v | B;
    *(ptr++) = (v >> 7) | B;
    *(ptr++) = v >> 14;
  } else if (v < (1 << 28)) {
    *(ptr++) = v | B;
    *(ptr++) = (v >> 7) | B;
    *(ptr++) = (v >> 14) | B;
    *(ptr++) = v >> 21;
  } else {
    *(ptr++) = v | B;
    *(ptr++) = (v >> 7) | B;
    *(ptr++) = (v >> 14) | B;
    *(ptr++) = (v >> 21) | B;
    *(ptr++) = v >> 28;
  }
  return reinterpret_cast<char*>(ptr);
}

__host__ __device__ void GPUPutVarint32Varint32Varint32(char* dst, uint32_t v1,
                                                        uint32_t v2,
                                                        uint32_t v3,
                                                        size_t& encoded_size) {
  char buf[15];
  char* ptr = GPUEncodeVarint32(buf, v1);
  ptr = GPUEncodeVarint32(ptr, v2);
  ptr = GPUEncodeVarint32(ptr, v3);
  encoded_size = static_cast<size_t>(ptr - buf);
  memcpy(dst, buf, encoded_size);
}

__host__ __device__ uint64_t GPUDecodeFixed8(const char* ptr) {
  uint8_t result;
  memcpy(&result, ptr, sizeof(uint8_t));
  return result;
}

__host__ __device__ void GPUParseHotValue(const char* len_pos_hot,
                                          unsigned char* c) {
  *c = GPUDecodeFixed8(len_pos_hot + 12);
}

__host__ __device__ void GPUPutFixed32(char* dst, uint32_t value) {
  memcpy(dst, const_cast<const char*>(reinterpret_cast<char*>(&value)),
         sizeof(uint32_t));
}

__host__ __device__ uint32_t GPUDecodeFixed32(const char* ptr) {
  uint32_t result;
  memcpy(&result, ptr, sizeof(uint32_t));
  return result;
}

__host__ __device__ void GPUEncodeFixed8(char* buf, uint8_t value) {
  memcpy(buf, &value, sizeof(value));
}

__host__ __device__ void GPUEncodeFixed16(char* buf, uint16_t value) {
  memcpy(buf, &value, sizeof(value));
}

__host__ __device__ void GPUEncodeFixed32(char* buf, uint32_t value) {
  memcpy(buf, &value, sizeof(value));
}

__host__ __device__ void GPUEncodeFixed64(char* buf, uint64_t value) {
  memcpy(buf, &value, sizeof(value));
}

__host__ __device__ char* GPUEncodeVarint64(char* dst, uint32_t v) {
  static const unsigned int B = 128;
  auto* ptr = reinterpret_cast<unsigned char*>(dst);
  while (v >= B) {
    *(ptr++) = (v & (B - 1)) | B;
    v >>= 7;
  }
  *(ptr++) = static_cast<unsigned char>(v);
  return reinterpret_cast<char*>(ptr);
}

__host__ __device__ void GPUPutFixed64Fixed32(char* dst, uint64_t v1,
                                              uint32_t v2) {
  GPUEncodeFixed64(dst, v1);
  GPUEncodeFixed32(dst + sizeof(uint64_t), v2);
}

__host__ __device__ void GPUPutFixed64Varint64(char* dst, uint64_t v1,
                                               uint64_t v2) {
  char buf[20];
  GPUEncodeFixed64(buf, v1);
  char* ptr = GPUEncodeVarint64(buf + sizeof(uint64_t), v2);

  memcpy(dst, buf, static_cast<size_t>(ptr - buf));
}

__host__ __device__ bool GPUGetFixed32(char** input, size_t* size,
                                       uint32_t* value) {
  if (*size < sizeof(uint32_t)) {
    return false;
  }

  *value = GPUDecodeFixed32(*input);
  *input += sizeof(uint32_t);
  *size -= sizeof(uint32_t);

  return true;
}

__host__ __device__ uint64_t GPUDecodeFixed64(const char* ptr) {
  uint64_t result;
  memcpy(&result, ptr, sizeof(uint64_t));
  return result;
}

__host__ __device__ bool GPUGetFixed64(char** input, size_t* size,
                                       uint64_t* value) {
  if (*size < sizeof(uint64_t)) {
    return false;
  }

  *value = GPUDecodeFixed64(*input);
  *input += sizeof(uint64_t);
  *size -= sizeof(uint64_t);

  return true;
}

__host__ __device__ char* GPUGetVarint64Ptr(char* p, const char* limit,
                                            uint64_t* value) {
  uint64_t result = 0;
  for (uint32_t shift = 0; shift <= 63 && p < limit; shift += 7) {
    uint64_t byte = *(reinterpret_cast<const unsigned char*>(p));
    p++;
    if (byte & 128) {
      // More bytes are present
      result |= ((byte & 127) << shift);
    } else {
      result |= (byte << shift);
      *value = result;
      return reinterpret_cast<char*>(p);
    }
  }
  return nullptr;
}

__host__ __device__ bool GPUGetVarint64(char** input, size_t& size,
                                        uint64_t* value) {
  char* p = *input;
  const char* limit = p + size;
  char* q = GPUGetVarint64Ptr(p, limit, value);
  if (q == nullptr) {
    return false;
  } else {
    *input = q;
    size = limit - q;
    return true;
  }
}

__host__ __device__ const char* GPUGetVarint32PtrFallback(const char* p,
                                                          const char* limit,
                                                          uint32_t* value) {
  uint32_t result = 0;
  for (uint32_t shift = 0; shift <= 28 && p < limit; shift += 7) {
    uint32_t byte = *(reinterpret_cast<const unsigned char*>(p));
    p++;
    if (byte & 128) {
      // More bytes are present
      result |= ((byte & 127) << shift);
    } else {
      result |= (byte << shift);
      *value = result;
      return reinterpret_cast<const char*>(p);
    }
  }
  return nullptr;
}

__host__ __device__ const char* GPUGetVarint32Ptr(const char* p,
                                                  const char* limit,
                                                  uint32_t* value) {
  if (p < limit) {
    uint32_t result = *(reinterpret_cast<const unsigned char*>(p));
    if ((result & 128) == 0) {
      *value = result;
      return p + 1;
    }
  }
  return GPUGetVarint32PtrFallback(p, limit, value);
}
