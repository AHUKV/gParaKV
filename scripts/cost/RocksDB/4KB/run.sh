ulimit -n 999999

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --benchmarks=fillrandom --value_size=4096 --num=25000000 --db=/media/test --enable_blob_files=false --enable_blob_garbage_collection=false &> 1.txt

