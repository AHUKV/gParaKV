#!/bin/bash

ulimit -n 999999

# 启动 db_bench 并将其放入后台执行
/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=100000000 --value_size=1024 --db=/media/test &> 1.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=5000000 --value_size=1024 --db=/media/test &> 2.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=10000000 --value_size=1024 --db=/media/test &> 3.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=200000000 --value_size=1024 --db=/media/test &> 4.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=500000000 --value_size=1024 --db=/media/test &> 5.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=200000000 --value_size=1024 --db=/media/test &> 6.txt
