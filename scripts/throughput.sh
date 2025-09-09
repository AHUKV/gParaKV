#!/usr/bin/env bash
###############################################################################
# gParaKV throughput benchmark (write: fillrandom, read: readrandom)
#
# This script is **location–agnostic**: you can launch it from any directory.
# Simply edit the tunable parameters below—or export them as environment
# variables—before running.
#
# ────────────────────────────────────────────────────────────────────────────
# ❶ Two binaries
#    • gParaKV (no GC)      : /home/gParaKV/build/db_bench
#    • gParaKV-GC (with GC) : /home/gParaKV-GC/build/db_bench  +  --gc=1
#
# ❷ Key facts
#    • KEY_SIZE is fixed at 16 bytes in gParaKV.
#    • Total data written ≈ ((VALUE_SIZE + KEY_SIZE) * NUM_KV) >> 30 GiB.
#      Example: (1024 + 16) B × 100 000 000 ≈ 100 GiB.
#
# ❸ Throughput output (MB/s) appears in `fillrandom` and `readrandom` lines:
#      fillrandom : … 200 MB/s
#      readrandom : …  100 MB/s
###############################################################################

#############################
# Tunable parameters
#############################
VALUE_SIZE=${VALUE_SIZE:-1024}       # Size of each value (bytes)
KEY_SIZE=16                          # Fixed by gParaKV (bytes)
NUM_KV=${NUM_KV:-100000000}          # Number of key/value pairs
DB_PATH=${DB_PATH:-/tmp/test}        # SSTable directory
OUT_FILE=${OUT_FILE:-1.txt}          # Where to save db_bench output
ENABLE_GC=${ENABLE_GC:-0}            # 0 = no GC, 1 = trigger GC

#############################
# Select binary and GC flag
#############################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  DB_BENCH_BIN="$HOME/gParaKV-GC/build/db_bench"
else
  DB_BENCH_BIN="$HOME/gParaKV/build/db_bench"
fi

#############################
# Derived metric (for your log)
#############################
TOTAL_GIB=$(( (VALUE_SIZE + KEY_SIZE) * NUM_KV >> 30 ))
echo "≈${TOTAL_GIB} GiB of data will be written." | tee /dev/tty

#############################
# Run benchmark
#############################
"$DB_BENCH_BIN" \
  --benchmarks=fillrandom,readrandom \
  --value_size="$VALUE_SIZE" \
  --num="$NUM_KV" \
  --db="$DB_PATH" \
  &> "$OUT_FILE"

echo "Benchmark finished. Results saved to $OUT_FILE"
