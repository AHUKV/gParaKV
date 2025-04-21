//
// Created by ubuntu on 7/6/24.
//

#pragma once

constexpr uint32_t BlockRestartInterval = 16;
// 在数据块的大小达到这个值之前，会继续插入键值对
constexpr size_t num_kv_data_block = 118;

constexpr size_t max_num_data_block = 666;

constexpr int keySize_ = 16;
constexpr int valueSize_ = 8;

constexpr size_t encoded_value_size = 1;
constexpr size_t key_value_size =
    2 + encoded_value_size + keySize_ + 8 + valueSize_;
constexpr size_t encoded_index_entry = 12;
constexpr size_t size_index_entry = keySize_ + 8 + encoded_index_entry + 3;
