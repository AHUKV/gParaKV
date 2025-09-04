#include "db/vlog_manager.h"

namespace leveldb {

VlogManager::VlogManager(uint64_t clean_threshold)
    : clean_threshold_(clean_threshold),
      now_vlog_(0) {}

VlogManager::~VlogManager() {
  auto iter = manager_.begin();
  for (; iter != manager_.end(); ++iter) {
    delete iter->second.vlog_;
  }
}

void VlogManager::AddVlog(uint64_t vlog_numb, log::VReader* vlog) {
  VlogInfo v{};
  v.vlog_ = vlog;

  KeyValueInfo keyValueInfo{};

  manager_.insert(std::make_pair(vlog_numb, v));

  now_vlog_ = vlog_numb;
}

log::VReader* VlogManager::GetVlog(uint64_t vlog_numb) {
  auto iter = manager_.find(vlog_numb);
  if (iter == manager_.end())
    return nullptr;
  else
    return iter->second.vlog_;
}

}  // namespace leveldb
