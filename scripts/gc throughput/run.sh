ulimit -n 999999


/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=100000000 --value_size=1024 --db=/media/test --vlog=/media/test &> 1024.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=800000000 --value_size=128 --db=/media/test --vlog=/media/test --vlog_size=33554432 &> 128.txt

