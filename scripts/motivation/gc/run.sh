
/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=40000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=false &> 1.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=80000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=false &> 2.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=160000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=false &> 3.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=400000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=false &> 4.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=800000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=false &> 5.txt


/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=40000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=true &> 6.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=80000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=true &> 7.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=160000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=true &> 8.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=400000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=true &> 9.txt

/home/ubuntu/CLionProjects/rocksdb-9.8.4/cmake-build-debug/db_bench --compression_type=none --benchmarks=fillrandom --num=800000000 --value_size=128 --histogram=1 --db=/media/test --enable_blob_garbage_collection=true &> 10.txt

