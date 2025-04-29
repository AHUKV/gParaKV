ulimit -n 999999

rm -rf /media/test/*

/home/ubuntu/CLionProjects/diffkv/build/titandb_bench --benchmarks=fillrandom --value_size=4096 --num=25000000 --db=/media/test &> 1.txt

