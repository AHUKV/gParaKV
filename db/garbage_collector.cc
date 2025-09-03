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

}  // namespace leveldb
