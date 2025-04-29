#!/bin/bash

ulimit -n 999999

# 启动 db_bench 并将其放入后台执行
/home/ubuntu/CLionProjects/AHKV-222/out-static/db_bench --benchmarks=fillrandom --value_size=256 --num=400000000 --db=/media/test --vlog=/media/test --gc=1 &> 1.txt &
DB_BENCH_PID=$!

# 使用 watch 命令监控 GPU 状态，重定向输出到 gpu.log 文件
watch -n 1 '(nvidia-smi --format=csv,noheader --query-gpu=timestamp,power.draw,utilization.gpu,memory.used,memory.total) >> gpu.log' &
WATCH_PID=$!

# 等待 db_bench 完成
wait $DB_BENCH_PID

# db_bench 完成后，杀死 watch 命令
kill $WATCH_PID

echo "db_bench and GPU monitoring have completed."
