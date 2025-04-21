#ifndef YCSB_C_LEVELDB_H
#define YCSB_C_LEVELDB_H

#include <leveldb/db.h>
#include <leveldb/env.h>
#include <leveldb/filter_policy.h>
#include <leveldb/write_batch.h>

#include <iostream>
#include <string>

#include "../core/db.h"
#include "../core/properties.h"

using std::cout;
using std::endl;

namespace ycsbc {
class LevelDB : public DB {
 public:
  LevelDB(const char* dbfilename, const char* vlog, const char* configPath);

  int Read(const std::string& table, const std::string& key,
           const std::vector<std::string>* fields,
           std::vector<KVPair>& result) override;

  int Scan(const std::string& table, const std::string& key, int len,
           const std::vector<std::string>* fields,
           std::vector<std::vector<KVPair>>& result) override;

  int Update(const std::string& table, const std::string& key,
             std::vector<KVPair>& values) override;

  int Insert(const std::string& table, const std::string& key,
             std::vector<KVPair>& values) override;

  int Delete(const std::string& table, const std::string& key) override;

  void PrintMyStats() override;

  virtual ~LevelDB();

 private:
  leveldb::DB* db_;
  uint32_t not_found_;
};
}  // namespace ycsbc
#endif
