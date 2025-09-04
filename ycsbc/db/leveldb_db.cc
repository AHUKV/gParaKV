#include "leveldb_db.h"

#include <leveldb/cache.h>

using namespace std;
uint64_t get_count_ok = 0;

namespace ycsbc {

LevelDB::LevelDB(const char* dbfilename, const char* vlog,
                 const char* configPath)
    : db_(nullptr) {
  leveldb::Options options;
  options.create_if_missing = true;
  options.compression = leveldb::CompressionType::kNoCompression;

  leveldb::Status status = leveldb::DB::Open(options, dbfilename, vlog, &db_);

  if (!status.ok()) {
    fprintf(stderr, "can't open leveldb\n");
    cerr << status.ToString() << endl;
    exit(0);
  }
}

int LevelDB::Read(const string& table, const string& key,
                  const vector<string>* fields, vector<DB::KVPair>& result) {
  std::string value;
  leveldb::Status s = db_->Get(leveldb::ReadOptions(), key, &value);
  if (s.IsNotFound()) {
    ++not_found_;
    return DB::kOK;
  }

  if (!s.ok()) {
    ++not_found_;
//    cerr << s.ToString() << endl;
//    fprintf(stderr, "read error\n");
  }
  get_count_ok++;

  return DB::kOK;
}

int LevelDB::Insert(const string& table, const string& key,
                    vector<DB::KVPair>& values) {
  leveldb::Status s;
  int count = 0;
  for (KVPair& p : values) {
    s = db_->Put(leveldb::WriteOptions(), key, p.second);
    count++;
    if (!s.ok()) {
//      fprintf(stderr, "insert error!\n");
//      cout << s.ToString() << endl;
//      exit(0);
    }
  }

  return DB::kOK;
}

int LevelDB::Delete(const string& table, const string& key) {
  vector<DB::KVPair> values;
  return Insert(table, key, values);
}

int LevelDB::Scan(const std::string& table, const std::string& key, int len,
                  const std::vector<std::string>* fields,
                  std::vector<std::vector<KVPair>>& result) {
  auto it = db_->NewIterator(leveldb::ReadOptions());
  it->Seek(key);

  std::vector<KVPair> pairs;
  pairs.reserve(len);
  leveldb::Slice k, v;
  for (int i = 0; i < len && it->Valid(); i++) {
    k = it->key();
    v = it->value();
    KVPair pair(k.ToString(), v.ToString());
    pairs.push_back(pair);
    it->Next();
  }

  result.push_back(pairs);

  delete it;

  return DB::kOK;
}

int LevelDB::Update(const string& table, const string& key,
                    vector<DB::KVPair>& values) {
  return Insert(table, key, values);
}

void LevelDB::PrintMyStats() {
}

LevelDB::~LevelDB() { delete db_; }

}  // namespace ycsbc
