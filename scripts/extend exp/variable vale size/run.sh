ulimit -n 999999


/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=1000000 --value_size=16384 --db=/media/test &> 1.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=2000000 --value_size=16384 --db=/media/test &> 2.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=5000000 --value_size=16384 --db=/media/test &> 3.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=10000000 --value_size=16384 --db=/media/test &> 4.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=20000000 --value_size=16384 --db=/media/test  &> 5.txt

