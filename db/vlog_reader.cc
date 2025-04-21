// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#include "db/vlog_reader.h"

#include <stdio.h>

#include "leveldb/env.h"

#include "util/coding.h"
#include "util/crc32c.h"
#include "util/mutexlock.h"

#include "my_stats.h"

namespace leveldb {
namespace log {

VReader::Reporter::~Reporter() {}

VReader::VReader(SequentialFile* file, bool checksum, uint64_t initial_offset)
    : file_(file),
      reporter_(nullptr),
      checksum_(checksum),
      // 一次从磁盘读kblocksize，多余的做缓存以便下次读
      backing_store_(new char[kBlockSize]),
      buffer_(),
      eof_(false) {
  if (initial_offset > 0) SkipToPos(initial_offset);
}

VReader::VReader(SequentialFile* file, Reporter* reporter, bool checksum,
                 uint64_t initial_offset)
    : file_(file),
      reporter_(reporter),
      checksum_(checksum),
      // 一次从磁盘读kblocksize，多余的做缓存以便下次读
      backing_store_(new char[kBlockSize]),
      buffer_(),
      eof_(false) {
  if (initial_offset > 0) SkipToPos(initial_offset);
}

VReader::~VReader() {
  delete[] backing_store_;
  delete file_;
}

bool VReader::SkipToPos(size_t pos) {
  if (pos > 0) {  // 跳到距file文件头偏移pos的地方
    Status skip_status = file_->SkipFromHead(pos);
    if (!skip_status.ok()) {
      ReportDrop(pos, skip_status);
      return false;
    }
  }
  return true;
}

// 日志回放的时候是单线程
bool VReader::ReadRecord(Slice* record, std::string* scratch, int& head_size) {
  scratch->clear();
  record->clear();

  if (buffer_.size() < kVHeaderMaxSize) {  // 遇到buffer_剩的空间不够解析头部时
    if (!eof_) {
      size_t left_head_size = buffer_.size();
      if (left_head_size > 0)  // 如果读缓冲还剩内容，拷贝到读缓冲区头
        memcpy(backing_store_, buffer_.data(), left_head_size);
      buffer_.clear();
      Status status = file_->Read(kBlockSize - left_head_size, &buffer_,
                                  backing_store_ + left_head_size);

      if (left_head_size > 0) buffer_.go_back(left_head_size);

      if (!status.ok()) {
        buffer_.clear();
        ReportDrop(kBlockSize, status);
        eof_ = true;
        return false;
      } else if (buffer_.size() < kBlockSize) {
        // 因为前面回退了，所以这里是kblocksize
        eof_ = true;
        // 最少的一条记录也需要6个字节，一个字节的数据
        if (buffer_.size() < 4 + 1 + 1) return false;
      }
    } else {
      if (buffer_.size() < 4 + 1 + 1) {
        buffer_.clear();
        return false;
      }
    }
  }

  // 解析头部
  uint32_t length = 12 + my_stats.var_key_value_size;
  if (length <= buffer_.size()) {
    *record = Slice(buffer_.data(), length);
    buffer_.remove_prefix(length);
    return true;
  } else {
    if (eof_) {  // 日志最后一条记录不完整的情况，直接忽略
      return false;
    }
    // 逻辑记录不能在buffer中全部容纳，需要将读取结果写入到scratch
    scratch->reserve(length);
    size_t buffer_size = buffer_.size();
    scratch->assign(buffer_.data(), buffer_size);
    buffer_.clear();
    const uint64_t left_length = length - buffer_size;
    if (left_length > kBlockSize / 2) {
      // 如果剩余待读的记录超过block块的一半大小，则直接读到scratch中
      Slice buffer;
      scratch->resize(length);
      Status status =
          file_->Read(left_length, &buffer,
                      const_cast<char*>(scratch->data()) + buffer_size);

      if (!status.ok()) {
        ReportDrop(left_length, status);
        return false;
      }
      if (buffer.size() < left_length) {
        eof_ = true;
        scratch->clear();

        return false;
      }
    } else {  // 否则读一整块到buffer中
      Status status = file_->Read(kBlockSize, &buffer_, backing_store_);

      if (!status.ok()) {
        ReportDrop(kBlockSize, status);
        return false;
      } else if (buffer_.size() < kBlockSize) {
        if (buffer_.size() < left_length) {
          eof_ = true;
          scratch->clear();
          ReportCorruption(left_length, "last record not full");
          return false;  ////////////////////////////////
        }
        // 这个判断不要也可以，加的话算是优化，提早知道到头了，省的read一次才知道
        eof_ = true;
      }
      scratch->append(buffer_.data(), left_length);
      buffer_.remove_prefix(left_length);
    }
    *record = Slice(*scratch);
    return true;
  }
}

// get查询中根据索引从vlog文件中读value值
bool VReader::Read(char* val, size_t size, size_t pos) {
  MutexLock l(&mutex_);
  if (!SkipToPos(pos)) {
    return false;
  }
  Slice buffer;
  Status status = file_->Read(size, &buffer, val);
  if (!status.ok() || buffer.size() != size) {
    ReportDrop(size, status);
    return false;
  }
  return true;
}

void VReader::ReportCorruption(uint64_t bytes, const char* reason) {
  ReportDrop(bytes, Status::Corruption(reason));
}

void VReader::ReportDrop(uint64_t bytes, const Status& reason) {
  if (reporter_ != nullptr) {
    reporter_->Corruption(static_cast<size_t>(bytes), reason);
  }
}

bool VReader::DeallocateDiskSpace(uint64_t offset, size_t len) {
  return file_->DeallocateDiskSpace(offset, len).ok();
}

}  // namespace log
}  // namespace leveldb
