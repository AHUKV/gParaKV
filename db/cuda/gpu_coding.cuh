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

__host__ __device__ char* GPUEncodeVarint32(char* dst, uint32_t v);

__host__ __device__ void GPUPutVarint32Varint32Varint32(char* dst, uint32_t v1,
                                                        uint32_t v2,
                                                        uint32_t v3,
                                                        size_t& encoded_size);

__host__ __device__ uint64_t GPUDecodeFixed8(const char* ptr);

__host__ __device__ void GPUParseHotValue(const char* len_pos_hot,
                                          unsigned char* c);

__host__ __device__ void GPUPutFixed32(char* dst, uint32_t value);

__host__ __device__ uint32_t GPUDecodeFixed32(const char* ptr);

__host__ __device__ void GPUEncodeFixed8(char* buf, uint8_t value);

__host__ __device__ void GPUEncodeFixed16(char* buf, uint16_t value);

__host__ __device__ void GPUEncodeFixed32(char* buf, uint32_t value);

__host__ __device__ void GPUEncodeFixed64(char* buf, uint64_t value);

__host__ __device__ char* GPUEncodeVarint64(char* dst, uint32_t v);

__host__ __device__ void GPUPutFixed64Fixed32(char* dst, uint64_t v1,
                                              uint32_t v2);

__host__ __device__ void GPUPutFixed64Varint64(char* dst, uint64_t v1,
                                               uint64_t v2);

__host__ __device__ bool GPUGetFixed32(char** input, size_t* size,
                                       uint32_t* value);

__host__ __device__ uint64_t GPUDecodeFixed64(const char* ptr);

__host__ __device__ bool GPUGetFixed64(char** input, size_t* size,
                                       uint64_t* value);

__host__ __device__ char* GPUGetVarint64Ptr(char* p, const char* limit,
                                            uint64_t* value);

__host__ __device__ bool GPUGetVarint64(char** input, size_t& size,
                                        uint64_t* value);

__host__ __device__ const char* GPUGetVarint32PtrFallback(const char* p,
                                                          const char* limit,
                                                          uint32_t* value);

__host__ __device__ const char* GPUGetVarint32Ptr(const char* p,
                                                  const char* limit,
                                                  uint32_t* value);
