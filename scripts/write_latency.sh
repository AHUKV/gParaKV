#!/usr/bin/env bash
###############################################################################
# gParaKV WRITE-LATENCY BENCHMARK
#
# This script measures the write latency of **gParaKV** (no GC) or **gParaKV-GC**
# (GC enabled).  It runs the `fillrandom` workload only—`readrandom` is omitted
# because throughput is not under test here.
#
# ─────────────────────────────────────────────────────────────────────────────
#  Output of interest (saved in OUT_FILE) looks like this:
#
#   Count: 100000000  Average: 11.2638  StdDev: 14.00
#   Min: 1.0000  Median: 6.2979  Max: 6149.0000
#   Percentiles: P50: 6.30  P75: 20.62  P90: 26.60  P99: 50.45  P99.9: 86.03
#                P99.99: 199.75
#
#   • All values are **latencies in microseconds**.
#   • Use P50 / P90 / P99 to judge tail latency.
#
# ─────────────────────────────────────────────────────────────────────────────
#  HOW TO USE
#
#   chmod +x bench_latency.sh
#   ./bench_latency.sh                       # default: 1024-B values, 100 M KV
#
#   # Customize via environment variables:
#   VALUE_SIZE=4096 NUM_KV=50000000 \
#   ENABLE_GC=1 DB_PATH=/data/kv OUT_FILE=lat_gc.txt ./bench_latency.sh
###############################################################################

#############################
# Tunable parameters
#############################
VALUE_SIZE=${VALUE_SIZE:-1024}        # size of each value (bytes)
KEY_SIZE=16                           # size of each key (fixed)  (bytes)
NUM_KV=${NUM_KV:-100000000}           # number of key/value pairs
DB_PATH=${DB_PATH:-/tmp/test}         # target directory for SSTables
OUT_FILE=${OUT_FILE:-1.txt}           # file to capture db_bench output
ENABLE_GC=${ENABLE_GC:-0}             # 0 = gParaKV   |  1 = gParaKV-GC (GC)

#############################
# Select binary and GC flag
#############################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  DB_BENCH_BIN="$HOME/gParaKV-GC/build/db_bench"
  GC_FLAG="--gc=1"                    # enable GC
else
  DB_BENCH_BIN="$HOME/gParaKV/build/db_bench"
  GC_FLAG="--gc=0"                    # explicit, but default
fi

#############################
# Derived metrics (for log)
#############################
TOTAL_GIB=$(( (VALUE_SIZE + KEY_SIZE) * NUM_KV >> 30 ))
echo "≈${TOTAL_GIB} GiB will be written (VALUE=${VALUE_SIZE} B, KEY=${KEY_SIZE} B, NUM=${NUM_KV})." | tee /dev/tty
echo "(Binary: $DB_BENCH_BIN  |  GC: $GC_FLAG)" | tee /dev/tty
echo "Results will be stored in $OUT_FILE" | tee /dev/tty
echo "──────────────────────────────────────" | tee /dev/tty

#############################
# Run benchmark
#############################
"$DB_BENCH_BIN" \
  --benchmarks=fillrandom \
  --value_size="$VALUE_SIZE" \
  --num="$NUM_KV" \
  --db="$DB_PATH" \
  $GC_FLAG \
  &> "$OUT_FILE"

echo "Benchmark finished."
echo "Inspect $OUT_FILE for latency statistics (see header of this script for format)."
