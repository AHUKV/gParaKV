#pragma once

#include <cstdint>
#include <libpmemobj.h>
#include <string>
#include <unordered_map>

#define LAYOUT_NAME "hashmap_layout"
#define PMEMOBJ_POOL_SIZE (1024ULL * 1024 * 1024 * 15)

struct hashmap {
  PMEMoid root_oid;
};

class HashMap {
 public:
  explicit HashMap(const std::string& path);
  ~HashMap();
  void put(const std::string& key, const std::string& value);
  std::string get(const std::string& key);
  bool exists(const std::string& key);

 private:
  PMEMobjpool* pop;
  PMEMoid root_oid{};
  std::unordered_map<std::string, PMEMoid> map;
};
