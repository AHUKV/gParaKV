#include "pmem_hashmap.h"

#include <cstring>
#include <stdexcept>

#include "my_stats.h"

HashMap::HashMap(const std::string& path) {
  if ((pop = pmemobj_create(path.c_str(), LAYOUT_NAME, PMEMOBJ_POOL_SIZE,
                            0666)) == nullptr) {
    if ((pop = pmemobj_open(path.c_str(), LAYOUT_NAME)) == nullptr) {
      throw std::runtime_error("Failed to create or open the pool");
    }
  }
  root_oid = pmemobj_root(pop, sizeof(hashmap));
  if (OID_IS_NULL(root_oid)) {
    throw std::runtime_error("Failed to allocate root object");
  }
}

HashMap::~HashMap() { pmemobj_close(pop); }

void HashMap::put(const std::string& key, const std::string& value) {
  PMEMoid oid;
  auto it = map.find(key);
  if (it != map.end()) {
    oid = it->second;
  } else {
    size_t value_size = value.size() + 1;
    if (pmemobj_alloc(pop, &oid, value_size, 0, nullptr, nullptr) != 0) {
      throw std::runtime_error("Failed to allocate memory for value");
    }
    map[key] = oid;
  }
  char* dest = (char*)pmemobj_direct(oid);
  strcpy(dest, value.c_str());
  pmemobj_persist(pop, dest, value.size() + 1);
}

std::string HashMap::get(const std::string& key) {
  auto it = map.find(key);
  if (it == map.end()) {
    return "";
  }
  PMEMoid oid = it->second;
  char* value = (char*)pmemobj_direct(oid);
  return {value, leveldb::my_stats.original_value_size};
}

bool HashMap::exists(const std::string& key) {
  return map.find(key) != map.end();
}
