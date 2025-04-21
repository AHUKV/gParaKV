#!/bin/bash

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadf.spec &> ./f.txt

exit 0

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloada.spec &> ./a.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadb.spec &> ./b.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadc.spec &> ./c.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadd.spec &> ./d.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloade.spec &> ./e.txt

