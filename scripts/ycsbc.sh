#!/usr/bin/env bash
###############################################################################
# ycsb_run.sh ─ YCSB-C Benchmark Harness for ParaKV
#
# Purpose
# -------
# • Executes a YCSB-C workload (e.g., Workload-A, B, …) against either
#   - **ParaKV**      (no GC)  or
#   - **ParaKV-GC**   (with GC enabled)
# • Captures both **load** and **transaction** throughput in a log file.
#
# ─────────────────────────────────────────────────────────────────────────────
# ❶ Variables you can change
#    ENABLE_GC        : 0 = ParaKV  |  1 = ParaKV-GC
#    FILENAME         : Directory where SSTables are written
#    WORKLOAD_SPEC    : Path to a workload file inside the project’s “workloads”
#                       folder, e.g., workloads/100/workloada.spec
#                       (The “100” sub-folder means ≈100 GiB of data.)
#    OUT_FILE         : Where all console output is saved.
#
# ❷ Fixed parameters (rarely changed)
#    -db              : Storage engine (always “leveldb” for ParaKV)
#    -configpath      : 0 → use default config embedded in workload file
#
# ❸ Output of interest (KTPS = K Txn/s)
#    Loading throughput      : 217.142 KTPS
#    Transaction throughput  :  58.487 KTPS
#
# ❹ Example usage
#    chmod +x ycsb_run.sh
#    ./ycsb_run.sh                            # default: no GC, Workload-A (100 GiB)
#
#    # Run Workload-F (10 GiB) with GC enabled
#    ENABLE_GC=1 WORKLOAD_SPEC=workloads/10/workloadf.spec \
#    OUT_FILE=f_gc.txt ./ycsb_run.sh
###############################################################################

##########################
# User-tunable variables #
##########################
ENABLE_GC=${ENABLE_GC:-0}                           # 0 = ParaKV, 1 = ParaKV-GC
FILENAME=${FILENAME:-/media/test}                   # SSTable directory
WORKLOAD_SPEC=${WORKLOAD_SPEC:-workloads/100/workloada.spec}
OUT_FILE=${OUT_FILE:-a.txt}

##########################
# Binary selection
##########################
if [[ "$ENABLE_GC" -eq 1 ]]; then
  YCSB_BIN="$HOME/ParaKV-GC/cmake-build-debug/bin/ycsbc"
else
  YCSB_BIN="$HOME/ParaKV/cmake-build-debug/bin/ycsbc"
fi

##########################
# Informational banner
##########################
echo "─────────────────────────────────────────────────────────────"
echo "YCSB-C benchmark"
echo "Binary          : $YCSB_BIN"
echo "GC enabled?     : $ENABLE_GC"
echo "Data directory  : $FILENAME"
echo "Workload file   : $WORKLOAD_SPEC"
echo "Log file        : $OUT_FILE"
echo "─────────────────────────────────────────────────────────────"

##########################
# Run YCSB
##########################
"$YCSB_BIN" \
  -filename "$FILENAME" \
  -db leveldb \
  -configpath 0 \
  -P "$WORKLOAD_SPEC" \
  &> "$OUT_FILE"

echo "Benchmark complete. Inspect '$OUT_FILE' for:"
echo "  • Loading throughput (KTPS)"
echo "  • Transaction throughput (KTPS)"
