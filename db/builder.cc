// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#include "db/builder.h"

#include "db/cuda/gpu_options.cuh"
#include "db/dbformat.h"
#include "db/filename.h"
#include "db/table_cache.h"
#include "db/version_edit.h"

#include "leveldb/db.h"
#include "leveldb/env.h"
#include "leveldb/iterator.h"

namespace leveldb {

Status BuildTable(const std::string& dbname, Env* env, const Options& options,
                  TableCache* table_cache, Iterator* iter, FileMetaData* meta) {
  Status s;
  meta->file_size = 0;
  iter->SeekToFirst();

  std::string fname = TableFileName(dbname, meta->number);
  if (iter->Valid()) {
    WritableFile* file;
    s = env->NewWritableFile(fname, &file);
    if (!s.ok()) {
      return s;
    }

    auto* builder = new TableBuilder(options, file);
    meta->smallest.DecodeFrom(iter->key());
    Slice key;
    for (; iter->Valid(); iter->Next()) {
      key = iter->key();
      builder->Add(key, iter->value());
      ++meta->num_entries;
    }
    if (!key.empty()) {
      meta->largest.DecodeFrom(key);
    }

    // Finish and check for builder errors
    s = builder->Finish();
    if (s.ok()) {
      meta->file_size = builder->FileSize();
      assert(meta->file_size > 0);
    }
    delete builder;

    // Finish and check for file errors
    if (s.ok()) {
      s = file->Sync();
    }
    if (s.ok()) {
      s = file->Close();
    }
    delete file;
    file = nullptr;

    meta->num_data_blocks = meta->num_entries / num_kv_data_block;
    if (meta->num_entries % num_kv_data_block > 0) {
      ++meta->num_data_blocks;
    }

    if (s.ok()) {
      // Verify that the table is usable
      Iterator* it = table_cache->NewIterator(ReadOptions(), meta->number,
                                              meta->file_size);
      s = it->status();
      delete it;
    }
  }

  // Check for input iterator errors
  if (!iter->status().ok()) {
    s = iter->status();
  }

  if (s.ok() && meta->file_size > 0) {
    // Keep it
  } else {
    env->RemoveFile(fname);
  }
  return s;
}

Status BuildTable(const std::string& dbname, Env* env, const Options& options,
                  TableCache* table_cache, char* all_files_buffer,
                  std::vector<FileMetaData>& metas, size_t estimate_file_size,
                  size_t data_size, size_t index_size,
                  size_t data_size_last_file, size_t index_size_last_file,
                  uint32_t num_restarts,
                  uint32_t num_restarts_last_data_block) {
  assert(all_files_buffer != nullptr);

  size_t num_files = metas.size();

  Status s;

  for (size_t i = 0; i < num_files; ++i) {
    metas[i].file_size = 0;
    std::string fname = TableFileName(dbname, metas[i].number);
    WritableFile* file;
    env->NewWritableFile(fname, &file);
    auto* builder = new TableBuilder(options, file);

    char* current_file_buffer = all_files_buffer + estimate_file_size * i;
    if (i < num_files - 1) {
      metas[i].smallest.DecodeFrom(
          Slice(current_file_buffer + 3, keySize_ + 8));
      metas[i].largest.DecodeFrom(Slice(current_file_buffer + data_size - 5 -
                                            (num_restarts + 1) * 4 -
                                            valueSize_ - keySize_ - 8,
                                        keySize_ + 8));

      file->Append(Slice(current_file_buffer, data_size + index_size));
      s = builder->MyFinish(data_size, index_size);
    } else {
      metas[i].smallest.DecodeFrom(
          Slice(current_file_buffer + 3, keySize_ + 8));
      metas[i].largest.DecodeFrom(
          Slice(current_file_buffer + data_size_last_file - 5 -
                    (num_restarts_last_data_block + 1) * 4 - valueSize_ -
                    keySize_ - 8,
                keySize_ + 8));

      file->Append(Slice(current_file_buffer,
                         data_size_last_file + index_size_last_file));
      s = builder->MyFinish(data_size_last_file, index_size_last_file);
    }
    if (s.ok()) {
      metas[i].file_size = builder->FileSize();
      assert(metas[i].file_size > 0);
    }
    delete builder;

    // Finish and check for file errors
    if (s.ok()) {
      s = file->Sync();
    }
    if (s.ok()) {
      s = file->Close();
    }
    delete file;
    file = nullptr;

    if (s.ok()) {
      // Verify that the table is usable
      Iterator* it = table_cache->NewIterator(ReadOptions(), metas[i].number,
                                              metas[i].file_size);
      s = it->status();
      delete it;
    } else {
      break;
    }

    if (s.ok() && metas[i].file_size > 0) {
      // Keep it
    } else {
      env->DeleteFile(fname);
      break;
    }
  }

  return s;
}

Status BuildTableForCompaction(const std::string& dbname, Env* env,
                               const Options& options, TableCache* table_cache,
                               char* all_files_buffer,
                               std::vector<FileMetaData>& metas,
                               size_t estimate_file_size, size_t data_size,
                               size_t index_size, size_t data_size_last_file,
                               size_t index_size_last_file,
                               uint32_t num_restarts,
                               uint32_t num_restarts_last_data_block) {
  assert(all_files_buffer != nullptr);

  size_t num_files = metas.size();

  Status s;

  for (size_t i = 0; i < num_files; ++i) {
    metas[i].file_size = 0;
    std::string fname = TableFileName(dbname, metas[i].number);
    WritableFile* file;
    env->NewWritableFile(fname, &file);
    auto* builder = new TableBuilder(options, file);

    char* current_file_buffer = all_files_buffer + estimate_file_size * i;
    if (i < num_files - 1) {
      metas[i].smallest.DecodeFrom(
          Slice(current_file_buffer + 3, keySize_ + 8));
      metas[i].largest.DecodeFrom(Slice(current_file_buffer + data_size - 5 -
                                            (num_restarts + 1) * 4 -
                                            valueSize_ - keySize_ - 8,
                                        keySize_ + 8));

      auto start_time = std::chrono::high_resolution_clock::now();
      file->Append(Slice(current_file_buffer, data_size + index_size));
      s = builder->MyFinish(data_size, index_size);
      auto end_time = std::chrono::high_resolution_clock::now();
      auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
          end_time - start_time);
      my_stats.data_transfer_time += duration.count();

    } else {
      if (num_restarts_last_data_block == 0) {
        num_restarts_last_data_block = num_restarts;
      }
      metas[i].smallest.DecodeFrom(
          Slice(current_file_buffer + 3, keySize_ + 8));
      metas[i].largest.DecodeFrom(
          Slice(current_file_buffer + data_size_last_file - 5 -
                    (num_restarts_last_data_block + 1) * 4 - valueSize_ -
                    keySize_ - 8,
                keySize_ + 8));
      auto start_time = std::chrono::high_resolution_clock::now();
      file->Append(Slice(current_file_buffer,
                         data_size_last_file + index_size_last_file));
      s = builder->MyFinish(data_size_last_file, index_size_last_file);
      auto end_time = std::chrono::high_resolution_clock::now();
      auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
          end_time - start_time);
      my_stats.data_transfer_time += duration.count();
    }
    if (s.ok()) {
      metas[i].file_size = builder->FileSize();
      assert(metas[i].file_size > 0);
    }
    delete builder;

    // Finish and check for file errors
    if (s.ok()) {
      s = file->Sync();
    }
    if (s.ok()) {
      s = file->Close();
    }
    delete file;
    file = nullptr;

    if (s.ok()) {
      // Verify that the table is usable
      Iterator* it = table_cache->NewIterator(ReadOptions(), metas[i].number,
                                              metas[i].file_size);
      s = it->status();
      delete it;
    } else {
      break;
    }

    if (s.ok() && metas[i].file_size > 0) {
      // Keep it
    } else {
      env->DeleteFile(fname);
      break;
    }
  }

  return s;
}

Status BuildHotTable(const std::string& dbname, Env* env,
                     const Options& options, TableCache* table_cache,
                     std::vector<GPUKeyValue>& iter, FileMetaData* meta) {
  Status s;
  meta->file_size = 0;

  std::sort(iter.begin(), iter.end());

  std::string fname = TableFileName(dbname, meta->number);
  if (!iter.empty()) {
    WritableFile* file;
    s = env->NewWritableFile(fname, &file);
    if (!s.ok()) {
      return s;
    }

    auto* builder = new TableBuilder(options, file);

    meta->smallest.DecodeFrom({iter[0].key, keySize_});
    Slice key;

    for (const auto& item : iter) {
      key = {item.key, keySize_};
      builder->Add(key, {item.value, valueSize_});
      ++meta->num_entries;
    }

    if (!key.empty()) {
      meta->largest.DecodeFrom(key);
    }

    // Finish and check for builder errors
    s = builder->Finish();
    if (s.ok()) {
      meta->file_size = builder->FileSize();
      assert(meta->file_size > 0);
    }
    delete builder;

    // Finish and check for file errors
    if (s.ok()) {
      s = file->Sync();
    }
    if (s.ok()) {
      s = file->Close();
    }
    delete file;
    file = nullptr;

    meta->num_data_blocks = meta->num_entries / num_kv_data_block;
    if (meta->num_entries % num_kv_data_block > 0) {
      meta->num_data_blocks++;
    }

    if (s.ok()) {
      // Verify that the table is usable
      Iterator* it = table_cache->NewIterator(ReadOptions(), meta->number,
                                              meta->file_size);
      s = it->status();
      delete it;
    }
  }

  if (s.ok() && meta->file_size > 0) {
    // Keep it
  } else {
    env->RemoveFile(fname);
  }
  return s;
}

}  // namespace leveldb
