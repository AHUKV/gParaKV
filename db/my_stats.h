//
// Created by ubuntu on 7/6/24.
//

#pragma once

#include <atomic>
#include <cstddef>
#include <cstdio>
#include <filesystem>
#include <iostream>
#include <string>

namespace leveldb {

class MyStats {
 public:
  uint64_t bytes_write;
  uint64_t bytes_flush_write;

  uint64_t compaction_bytes_write = 0;
  uint64_t compaction_bytes_read = 0;
  uint64_t compaction_time = 0;

  uint64_t gc_bytes_read_write = 0;
  uint64_t gc_time = 0;
  uint64_t gc_read_write_time = 0;

  uint64_t data_transfer_time = 0;

  /*************************/

  uint32_t original_value_size;
  uint32_t var_key_value_size;

  uint32_t clean_threshold;
  uint32_t migrate_threshold;
  uint32_t max_num_log_item;
  uint32_t max_num_log;
  uint64_t max_vlog_size;

  MyStats()
      : bytes_write(0),
        bytes_flush_write(0),
        original_value_size(0),
        var_key_value_size(0),
        clean_threshold(0),
        migrate_threshold(0),
        max_num_log_item(0),
        max_num_log(0),
        max_vlog_size(0) {}

  void PrintStats(size_t done);

  void Reset() {
    bytes_write = 0;
    bytes_flush_write = 0;
    compaction_time = 0;
  }
};

extern MyStats my_stats;

}  // namespace leveldb
