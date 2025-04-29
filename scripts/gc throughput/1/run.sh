ulimit -n 999999


#/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=100000000 --value_size=1024 --db=/media/test --vlog=/media/test &> 1024.txt 


/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=400000000 --value_size=256 --db=/media/test --vlog_size=33554432 &> 256.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=800000000 --value_size=128 --db=/media/test --vlog_size=33554432 &> 128.txt

exit 0

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=1562500 --value_size=65536 --db=/media/test --vlog=/media/test &> 65536.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=390625 --value_size=262144 --db=/media/test --vlog=/media/test &> 262144.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=25000000 --value_size=4096 --db=/media/test --vlog=/media/test &> 4096.txt 
