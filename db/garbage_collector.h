
#pragma

#include "db/cuda/gpu_sort.cuh"
#include "db/vlog_reader.h"
#include <cstdint>

#include "pmem_hashmap.h"
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

  void BeginGarbageCollect(const Slice& file,
                           const std::vector<uint32_t>& invalid_pos);

  static void BeginMigration(const Slice& file, HashMap& hashMap,
                             const std::vector<uint32_t>& keyValuesPos);

 private:
  uint64_t vlog_number_;
  uint64_t garbage_pos_;  // vlog文件起始垃圾回收的地方
  log::VReader* vlog_reader_;
  DBImpl* db_;
};

}  // namespace leveldb
