#ifndef STORAGE_LEVELDB_DB_VLOG_MANAGER_H_
#define STORAGE_LEVELDB_DB_VLOG_MANAGER_H_

#include "db/vlog_reader.h"
#include <unordered_map>
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

  VlogManager(uint64_t clean_threshold);
  ~VlogManager();

  // vlog一定要是new出来的，vlog_manager的析构函数会delete它
  void AddVlog(uint64_t vlog_numb, log::VReader* vlog);

  log::VReader* GetVlog(uint64_t vlog_numb);

 private:
  std::unordered_map<uint32_t, VlogInfo> manager_;

  uint32_t clean_threshold_;
  uint32_t now_vlog_;
};

}  // namespace leveldb

#endif
