// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#include "db/vlog_writer.h"

#include <stdint.h>

#include "leveldb/env.h"

#include "util/coding.h"
#include "util/crc32c.h"

#include "my_stats.h"

namespace leveldb::log {

VWriter::VWriter(WritableFile* dest) : dest_(dest) {}

VWriter::~VWriter() {}

Status VWriter::AddRecord(const Slice& slice) {
  Status s;
  if (slice.size() <= my_stats.var_key_value_size + 12) {
    s = dest_->Append(slice);
  } else {
    const char* start = slice.data() + 12;
    int count = slice.size() / (my_stats.var_key_value_size + 12) + 1;
    for (int i = 0; i < count; ++i) {
      std::string tmp;
      tmp.resize(12);
      EncodeFixed32(&tmp[8], 1);
      tmp.append({start + i * my_stats.var_key_value_size,
                  my_stats.var_key_value_size});
      s = dest_->Append(tmp);
    }
  }
  if (s.ok()) {
    s = dest_->Flush();
  }
  return s;
}

}  // namespace leveldb::log
