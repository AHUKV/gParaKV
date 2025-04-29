ulimit -n 999999
rm -rf /media/test/*
/home/ubuntu/CLionProjects/hpdk-main/cmake-build/db_bench --benchmarks=fillrandom --value_size=1024 --num=20000000 --db=/mnt/pmem &> 1.txt

