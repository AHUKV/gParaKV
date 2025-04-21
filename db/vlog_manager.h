#ifndef STORAGE_LEVELDB_DB_VLOG_MANAGER_H_
#define STORAGE_LEVELDB_DB_VLOG_MANAGER_H_

#include "db/cuda/gpu_sort.cuh"
#include "db/vlog_reader.h"
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "my_stats.h"

namespace leveldb {

class VlogManager {
 public:
  struct VlogInfo {
    log::VReader* vlog_{};
  };

  struct KeyValueInfo {
    std::vector<uint32_t> keyValuesPos_;

    [[nodiscard]] uint32_t count() const { return keyValuesPos_.size(); }

    KeyValueInfo() { keyValuesPos_.reserve(my_stats.max_num_log_item); }
  };

  VlogManager(uint64_t clean_threshold, uint32_t migrate_threshold);
  ~VlogManager();

  // vlog一定要是new出来的，vlog_manager的析构函数会delete它
  void AddVlog(uint64_t vlog_numb, log::VReader* vlog);

  log::VReader* GetVlog(uint64_t vlog_numb);

  void AddHotKeyValue(const GPUKeyValue& key_value);
  bool IsMigration();
  std::pair<uint64_t, std::vector<uint32_t>*> GetVlogToMigrate();
  void RemoveMigration(uint64_t vlog_numb);

 private:
  std::unordered_map<uint32_t, VlogInfo> manager_;

  std::unordered_map<uint32_t, KeyValueInfo> hot_manager_;
  std::unordered_map<uint32_t, std::vector<uint32_t>*> hot_key_values_;

  uint32_t clean_threshold_;
  uint32_t now_vlog_;

  uint32_t migrate_threshold_;
};

}  // namespace leveldb

#endif
