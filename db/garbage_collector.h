
#pragma once

#include "db/vlog_reader.h"
#include <cstdint>

#include "vlog_writer.h"

namespace leveldb {

class VReader;
class DBImpl;
class VersionEdit;

class GarbageCollector {
 public:
  GarbageCollector(DBImpl* db)
      : vlog_number_(0), garbage_pos_(0), vlog_reader_(nullptr), db_(db) {}

  ~GarbageCollector() { delete vlog_reader_; }

  void SetVlog(uint64_t vlog_number, uint64_t garbage_beg_pos = 0);

 private:
  uint64_t vlog_number_;
  uint64_t garbage_pos_;  // vlog文件起始垃圾回收的地方
  log::VReader* vlog_reader_;
  DBImpl* db_;
};

}  // namespace leveldb
