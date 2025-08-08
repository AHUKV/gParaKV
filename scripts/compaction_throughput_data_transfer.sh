#!/usr/bin/env bash
###############################################################################
# gParaKV COMPACTION-THROUGHPUT BENCHMARK
#
# This script measures **compaction throughput** for either
#   • gParaKV          (no GC)  or
#   • gParaKV-GC       (GC enabled, --gc=1)
#
# The workload is `fillrandom` only; read throughput is irrelevant here.
#
# ─────────────────────────────────────────────────────────────────────────────
#  Result of interest (saved in OUT_FILE) looks like:
#
#   compaction throughput = (read + write) / time = (61346.070989 + 60028.295607) / 302.472028 = 401.27 MB/s
#
#  The script does **not** parse this line—simply open OUT_FILE and look for
#  the “compaction throughput = … MB/s” summary printed by `db_bench`.
#
# ─────────────────────────────────────────────────────────────────────────────
#  USAGE EXAMPLES
#
#   # 100 GiB workload, no GC
#   ./compaction_throughput_data_transfer.sh
#
#   # 50 GiB workload, GC enabled, custom paths
#   VALUE_SIZE=4096 NUM_KV=12500000 ENABLE_GC=1 \
#   DB_PATH=/data/kv OUT_FILE=comp_gc.txt ./bench_compaction.sh
###############################################################################

#############################
# Tunable parameters
#############################
VALUE_SIZE=${VALUE_SIZE:-1024}        # value size in bytes
KEY_SIZE=16                           # fixed key size (bytes)
NUM_KV=${NUM_KV:-100000000}           # number of KV pairs
DB_PATH=${DB_PATH:-/tmp/test}         # SSTable directory
OUT_FILE=${OUT_FILE:-1.txt}           # db_bench output file
ENABLE_GC=${ENABLE_GC:-0}             # 0 = gParaKV, 1 = gParaKV-GC (with GC)

#############################
# Binary selection & flags
#############################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  DB_BENCH_BIN="/home/gParaKV-GC/build/db_bench"
  GC_FLAG="--gc=1"
else
  DB_BENCH_BIN="/home/gParaKV/build/db_bench"
  GC_FLAG="--gc=0"                    # explicit, though default
fi

#############################
# Informational banner
#############################
TOTAL_GIB=$(( (VALUE_SIZE + KEY_SIZE) * NUM_KV >> 30 ))
echo "─────────────────────────────────────────────────────────────"
echo "gParaKV Compaction Benchmark"
echo "Binary      : $DB_BENCH_BIN"
echo "GC enabled? : $ENABLE_GC  ($GC_FLAG)"
echo "Value size  : $VALUE_SIZE B"
echo "Key size    : $KEY_SIZE B (fixed)"
echo "KV pairs    : $NUM_KV"
echo "≈Data size  : ${TOTAL_GIB} GiB"
echo "DB path     : $DB_PATH"
echo "Output file : $OUT_FILE"
echo "─────────────────────────────────────────────────────────────"

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

echo "Benchmark finished.  Open '$OUT_FILE' and search for:"
echo "  \"compaction throughput = … MB/s\""
echo "This line reports the combined read+write bandwidth during compaction."

