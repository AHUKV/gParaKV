#!/usr/bin/env bash
###############################################################################
# gpu_record.sh ─ GPU-side power-profiling harness for gParaKV
#
# 1. Runs db_bench (`fillrandom`) with or without garbage collection.
# 2. Samples NVIDIA-GPU power every second via nvidia-smi.
# 3. Stops sampling automatically when db_bench exits.
#
# ─────────────────────────────────────────────────────────────────────────────
#  OUTPUT
#    · db_bench console output        → 1.txt
#    · GPU telemetry (CSV)            → gpu.log
#
#  RUN ORDER
#    ①  Start this script.
#    ②  In another terminal, start cpu_record.sh (logs CPU/RAPL power).
###############################################################################

##########################
# User-tunable variables #
##########################
# Select implementation: 0 = no GC  |  1 = with GC
ENABLE_GC=${ENABLE_GC:-0}

# Common db_bench parameters
NUM_KV=${NUM_KV:-100000000}          # number of key/value pairs
VALUE_SIZE=${VALUE_SIZE:-1024}       # value size in bytes
DB_PATH=${DB_PATH:-/tmp/test}        # SSTable directory

##########################
# Binary & flag selection
##########################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  DB_BENCH_BIN="/home/gParaKV-GC/build/db_bench"
  GC_FLAG="--gc=1"
else
  DB_BENCH_BIN="/home/gParaKV/build/db_bench"
  GC_FLAG="--gc=0"                   # explicit, though default
fi

echo "─────────────────────────────────────────────────────────────"
echo "gpu_record.sh starting"
echo "Binary       : $DB_BENCH_BIN"
echo "GC enabled?  : $ENABLE_GC  ($GC_FLAG)"
echo "NUM_KV       : $NUM_KV"
echo "VALUE_SIZE   : $VALUE_SIZE B"
echo "DB_PATH      : $DB_PATH"
echo "─────────────────────────────────────────────────────────────"

# Avoid “too many open files” (RocksDB opens many FDs)
ulimit -n 999999

##########################
# 1. Launch db_bench
##########################
"$DB_BENCH_BIN" \
  --benchmarks=fillrandom \
  --num="$NUM_KV" \
  --value_size="$VALUE_SIZE" \
  --db="$DB_PATH" \
  $GC_FLAG \
  &> 1.txt &
DB_BENCH_PID=$!

##########################
# 2. Start GPU telemetry
##########################
watch -n 1 \
  '(nvidia-smi --format=csv,noheader --query-gpu=timestamp,power.draw,utilization.gpu,memory.used,memory.total) >> gpu.log' &
WATCH_PID=$!

##########################
# 3. Wait & clean up
##########################
wait "$DB_BENCH_PID"
kill "$WATCH_PID"

echo "gpu_record.sh complete: db_bench → 1.txt, GPU stats → gpu.log"
