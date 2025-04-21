

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=100000000 --value_size=1024 --db=/mnt/pmem --vlog=/media/test &> 1024.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=25000000 --value_size=4096 --db=/mnt/pmem --vlog=/media/test &> 4096.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=1562500 --value_size=65536 --db=/mnt/pmem --vlog=/media/test &> 65536.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=390625 --value_size=262144 --db=/mnt/pmem --vlog=/media/test &> 262144.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=400000000 --value_size=256 --db=/mnt/pmem --vlog=/media/test &> 256.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom,readrandom --num=650000000 --value_size=128 --db=/mnt/pmem --vlog=/media/test &> 128.txt

