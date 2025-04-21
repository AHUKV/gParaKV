// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#ifndef STORAGE_LEVELDB_DB_BUILDER_H_
#define STORAGE_LEVELDB_DB_BUILDER_H_

#include "db/cuda/gpu_sort.cuh"
#include <vector>

#include "leveldb/status.h"

namespace leveldb {

struct Options;
struct FileMetaData;

class Env;
class Iterator;
class TableCache;
class VersionEdit;

// Build a Table file from the contents of *iter.  The generated file
// will be named according to meta->number.  On success, the rest of
// *meta will be filled with metadata about the generated table.
// If no data is present in *iter, meta->file_size will be set to
// zero, and no Table file will be produced.
Status BuildTable(const std::string& dbname, Env* env, const Options& options,
                  TableCache* table_cache, Iterator* iter, FileMetaData* meta);

Status BuildTable(const std::string& dbname, Env* env, const Options& options,
                  TableCache* table_cache, char* all_files_buffer,
                  std::vector<FileMetaData>& metas, size_t estimate_file_size,
                  size_t data_size, size_t index_size,
                  size_t data_size_last_file, size_t index_size_last_file,
                  uint32_t num_restarts, uint32_t num_restarts_last_data_block);

Status BuildTableForCompaction(const std::string& dbname, Env* env,
                               const Options& options, TableCache* table_cache,
                               char* all_files_buffer,
                               std::vector<FileMetaData>& metas,
                               size_t estimate_file_size, size_t data_size,
                               size_t index_size, size_t data_size_last_file,
                               size_t index_size_last_file,
                               uint32_t num_restarts,
                               uint32_t num_restarts_last_data_block);

Status BuildHotTable(const std::string& dbname, Env* env, const Options& options,
                    TableCache* table_cache, std::vector<GPUKeyValue>& iter,
                    FileMetaData* meta);

}  // namespace leveldb

#endif  // STORAGE_LEVELDB_DB_BUILDER_H_
