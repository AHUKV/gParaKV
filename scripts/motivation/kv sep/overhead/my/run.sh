ulimit -n 999999

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=100000000 --value_size=1024 --db=/media/test &> 1.txt
