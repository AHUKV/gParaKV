#!/usr/bin/env bash
###############################################################################
# gParaKV space amplification benchmark (write-only: fillrandom)
#
# This script is **location–agnostic**: run it from anywhere.
# It writes a dataset, then computes space amplification:
#     SpaceAmp = (on-disk bytes) / (logical bytes written)
#
# ────────────────────────────────────────────────────────────────────────────
# ❶ Two binaries
#    • gParaKV (no GC)      : $HOME/gParaKV/build/db_bench
#    • gParaKV-GC (with GC) : $HOME/gParaKV-GC/build/db_bench + --gc=1
#
# ❷ Key facts
#    • KEY_SIZE is fixed at 16 bytes in gParaKV.
#    • Logical bytes written = (VALUE_SIZE + KEY_SIZE) * NUM_KV
#    • On-disk bytes are measured by `du -sb ${DB_PATH}` after run.
#
# ❸ Output
#    • db_bench raw output → OUT_FILE (default: 1.txt)
#    • A final summary line with SpaceAmp is appended to OUT_FILE.
###############################################################################

#############################
# Tunable parameters
#############################
VALUE_SIZE=${VALUE_SIZE:-1024}       # Size of each value (bytes)
KEY_SIZE=16                          # Fixed by gParaKV (bytes)
NUM_KV=${NUM_KV:-100000000}          # Number of key/value pairs
DB_PATH=${DB_PATH:-/tmp/test}        # SSTable directory (will be recreated)
OUT_FILE=${OUT_FILE:-1.txt}          # Where to save db_bench output
ENABLE_GC=${ENABLE_GC:-0}            # 0 = no GC, 1 = trigger GC

#############################
# Select binary and GC flag
#############################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  DB_BENCH_BIN="$HOME/gParaKV-GC/build/db_bench"
  GC_FLAG="--gc=1"      # Explicitly enable GC
else
  DB_BENCH_BIN="$HOME/gParaKV/build/db_bench"
  GC_FLAG="--gc=0"      # Explicitly disable GC (default)
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
  $GC_FLAG \
  &> "$OUT_FILE"

echo "Benchmark finished. Results saved to $OUT_FILE"
