//
// Created by ubuntu on 7/6/24.
//

#include "my_stats.h"

namespace leveldb {

MyStats my_stats;

void MyStats::PrintStats(size_t done_) {
  std::string directory = "/media/test";
  uintmax_t total_size = 0;

  try {
    for (const auto& entry :
         std::filesystem::recursive_directory_iterator(directory)) {
      if (entry.is_regular_file()) {
        total_size += std::filesystem::file_size(entry.path());
      }
    }
  } catch (const std::filesystem::filesystem_error& e) {
  }

  fprintf(stdout,
          "flush到磁盘: %.0fMB,\t\t 写入磁盘: %.0fMB,\t\t 写放大: %.2f \n",
          (bytes_flush_write / 1048576.0), (bytes_write / 1048576.0),
          static_cast<double>(bytes_write) /
              static_cast<double>(bytes_flush_write));

  fprintf(
      stdout,
      "原始写入磁盘: %.0fMB,\t\t 新写入磁盘量： %.0fMB,\t\t 空间放大： %.2f \n",
      (static_cast<double>((original_value_size + 16) * done_) / 1048576.0),
      static_cast<double>(total_size) / 1048576.0,
      static_cast<double>(total_size) /
          static_cast<double>((original_value_size + 16) * done_));

  printf("compaction time: %lu\n", compaction_time);

  printf(
      "compaction throughput = (read + write) / time = (%f + %f) / %f =  "
      "%.2f MB/s\n",
      static_cast<double>(compaction_bytes_read) / (1024 * 1024),
      static_cast<double>(compaction_bytes_write) / (1024 * 1024),
      static_cast<double>(compaction_time) / 1000000,
      (static_cast<double>(compaction_bytes_read) / (1024 * 1024) +
       static_cast<double>(compaction_bytes_write) / (1024 * 1024)) /
          (static_cast<double>(compaction_time) / 1000000));

  printf("gc bytes read and write: %lu\n", gc_bytes_read_write);
  printf("gc time: %lu\n", gc_time);
  printf("gc throughput: %.2f\n",
         (static_cast<double>(gc_bytes_read_write) / (1024 * 1024)) /
             (static_cast<double>(gc_time) / 1000000));

  printf("gc read and write time: %lu us\n", gc_read_write_time);
  printf("gc computation time: %lu us\n", gc_time - gc_read_write_time);

  printf("data transfer time: %lu us\n", data_transfer_time);
}

}  // namespace leveldb
