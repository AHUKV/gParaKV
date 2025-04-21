//
//  utils.h
//  YCSB-C
//
//  Created by Jinglei Ren on 12/5/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#ifndef YCSB_C_UTILS_H_
#define YCSB_C_UTILS_H_

#include <algorithm>
#include <cstdint>
#include <exception>
#include <iostream>
#include <random>

namespace utils {

inline std::string GenerateKey() {
  // 创建随机数生成引擎
  std::random_device random_device;
  std::mt19937 random_engine(random_device());

  // 创建一个均匀分布的随机数生成器，范围为 [2, 60]
  std::uniform_int_distribution<int> distribution(2, 60);

  // 生成随机数
  int random_number = distribution(random_engine);

  std::string all_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      "abcdefghijklmnopqrstuvwxyz"
      "0123456789"
      "!@#$%^&*()-=_+[]{}|;':\",.<>?/\\`~";

  std::string key;

  for (int i = 0; i < random_number; ++i) {
    std::uniform_int_distribution<size_t> distribution2(0, all_chars.size());
    size_t random_index = distribution2(random_engine);
    key += all_chars[random_index];
  }

  return key;
}

const uint64_t kFNVOffsetBasis64 = 0xCBF29CE484222325;
const uint64_t kFNVPrime64 = 1099511628211;

inline uint64_t FNVHash64(uint64_t val) {
  uint64_t hash = kFNVOffsetBasis64;

  for (int i = 0; i < 8; i++) {
    uint64_t octet = val & 0x00ff;
    val = val >> 8;

    hash = hash ^ octet;
    hash = hash * kFNVPrime64;
  }
  return hash;
}

inline uint64_t Hash(uint64_t val) { return FNVHash64(val); }

inline double RandomDouble(double min = 0.0, double max = 1.0) {
  static std::default_random_engine generator;
  static std::uniform_real_distribution<double> uniform(min, max);
  return uniform(generator);
}

///
/// Returns an ASCII code that can be printed to desplay
///
inline char RandomPrintChar() { return rand() % 94 + 33; }

class Exception : public std::exception {
 public:
  Exception(const std::string &message) : message_(message) {}
  const char *what() const noexcept { return message_.c_str(); }

 private:
  std::string message_;
};

inline bool StrToBool(std::string str) {
  std::transform(str.begin(), str.end(), str.begin(), ::tolower);
  if (str == "true" || str == "1") {
    return true;
  } else if (str == "false" || str == "0") {
    return false;
  } else {
    throw Exception("Invalid bool string: " + str);
  }
}

inline std::string Trim(const std::string &str) {
  auto front = std::find_if_not(str.begin(), str.end(),
                                [](int c) { return std::isspace(c); });
  return std::string(
      front,
      std::find_if_not(str.rbegin(), std::string::const_reverse_iterator(front),
                       [](int c) { return std::isspace(c); })
          .base());
}

}  // namespace utils

#endif  // YCSB_C_UTILS_H_
