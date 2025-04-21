#include "db/garbage_collector.h"

#include "db/db_impl.h"
#include "db/filename.h"
#include "db/version_edit.h"
#include "db/write_batch_internal.h"

#include "my_stats.h"

namespace leveldb {

void GarbageCollector::SetVlog(uint64_t vlog_number, uint64_t garbage_beg_pos) {
  SequentialFile* vlr_file;
  db_->options_.env->NewSequentialFile(
      VLogFileName(db_->vlog_name_, vlog_number), &vlr_file);
  vlog_reader_ = new log::VReader(vlr_file, true, 0);
  vlog_number_ = vlog_number;
  garbage_pos_ = garbage_beg_pos;
}

/*void GarbageCollector::BeginGarbageCollect(
    const Slice& file, const std::vector<uint32_t>& invalid_pos) {
  uint64_t position = 0;
  uint32_t count = 0;

  WriteBatch batch, clean_valid_batch;
  Slice key, value;

  while (position < file.size()) {
    if (position + 18 == invalid_pos[count]) {
      position += my_stats.var_key_value_size + 18;
      count++;
      continue;
    }

    WriteBatchInternal::SetContents(
        &batch, {file.data() + position + 6, my_stats.var_key_value_size + 12});
    position += + my_stats.var_key_value_size + 18;

    uint64_t pos = 0;
    bool isDel = false;
    WriteBatchInternal::ParseRecord(&batch, pos, key, value, isDel);

    clean_valid_batch.Put(key, value);

    if (clean_valid_batch.ApproximateSize() >=
        my_stats.clean_write_buffer_size) {
      Status s = db_->Write(WriteOptions(), &clean_valid_batch);
      assert(s.ok());
      clean_valid_batch.Clear();
    }
  }

  if (WriteBatchInternal::Count(&clean_valid_batch) > 0) {
    Status s = db_->Write(WriteOptions(), &clean_valid_batch);
    assert(s.ok());
    clean_valid_batch.Clear();
  }
}*/

void GarbageCollector::BeginMigration(
    const Slice& file, HashMap& hashMap,
    const std::vector<uint32_t>& keyValuesPos) {
  WriteBatch batch;
  Slice key, value;
  for (const auto& key_value_pos : keyValuesPos) {
    WriteBatchInternal::SetContents(&batch, {file.data() + key_value_pos - 12,
                                             my_stats.var_key_value_size + 12});

    uint64_t pos = 0;
    bool isDel = false;
    WriteBatchInternal::ParseRecord(&batch, pos, key, value, isDel);

    hashMap.put({key.data(), key.size()}, {value.data(), value.size()});
  }
}

}  // namespace leveldb
