//
// Created by ubuntu on 12/26/24.
//

#pragma once

#include <condition_variable>
#include <mutex>

namespace leveldb {

// 基于令牌桶算法 (Token Bucket)
class RateLimiter {
 public:
  RateLimiter(int rate_per_second)
      : tokens_(rate_per_second), max_tokens_(rate_per_second) {
    last_refill_time_ = std::chrono::steady_clock::now();
  }

  void Acquire() {
    std::unique_lock<std::mutex> lock(mu_);
    RefillTokens();

    while (tokens_ <= 0) {
      cv_.wait(lock);
      RefillTokens();
    }
    --tokens_;
  }

 private:
  void RefillTokens() {
    auto now = std::chrono::steady_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                       now - last_refill_time_)
                       .count();
    int new_tokens = elapsed * max_tokens_ / 1000;
    if (new_tokens > 0) {
      tokens_ = std::min(max_tokens_, tokens_ + new_tokens);
      last_refill_time_ = now;
      cv_.notify_all();
    }
  }

  std::mutex mu_;
  std::condition_variable cv_;
  int tokens_;
  const int max_tokens_;
  std::chrono::steady_clock::time_point last_refill_time_;
};

}  // namespace leveldb
