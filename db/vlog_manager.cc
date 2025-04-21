#include "db/vlog_manager.h"

#include "util/coding.h"

namespace leveldb {

VlogManager::VlogManager(uint64_t clean_threshold, uint32_t migrate_threshold)
    : clean_threshold_(clean_threshold),
      now_vlog_(0),
      migrate_threshold_(migrate_threshold) {}

VlogManager::~VlogManager() {
  auto iter = manager_.begin();
  for (; iter != manager_.end(); iter++) {
    delete iter->second.vlog_;
  }
}

void VlogManager::AddVlog(uint64_t vlog_numb, log::VReader* vlog) {
  VlogInfo v{};
  v.vlog_ = vlog;

  KeyValueInfo keyValueInfo{};

  manager_.insert(std::make_pair(vlog_numb, v));
  hot_manager_.insert(std::make_pair(vlog_numb, keyValueInfo));

  now_vlog_ = vlog_numb;
}

log::VReader* VlogManager::GetVlog(uint64_t vlog_numb) {
  auto iter = manager_.find(vlog_numb);
  if (iter == manager_.end())
    return nullptr;
  else
    return iter->second.vlog_;
}

void VlogManager::AddHotKeyValue(const GPUKeyValue& key_value) {
  uint32_t vlog_num = DecodeFixed32(key_value.value);
  uint32_t pos = DecodeFixed32(key_value.value + 4);

  auto iter = hot_manager_.find(vlog_num);
  if (iter != hot_manager_.end()) {
    iter->second.keyValuesPos_.emplace_back(pos);
    if (iter->second.count() >= migrate_threshold_ && vlog_num != now_vlog_) {
      hot_key_values_[vlog_num] = &iter->second.keyValuesPos_;
    }
  }
}

bool VlogManager::IsMigration() { return !hot_key_values_.empty(); }

std::pair<uint64_t, std::vector<uint32_t>*> VlogManager::GetVlogToMigrate() {
  auto iter = hot_key_values_.begin();
  assert(iter != hot_key_values_.end());
  return *iter;
}

void VlogManager::RemoveMigration(uint64_t vlog_numb) {
  auto iter = hot_manager_.find(vlog_numb);
  iter->second.keyValuesPos_.clear();
  hot_manager_.erase(iter);
  hot_key_values_.erase(vlog_numb);
}

}  // namespace leveldb
