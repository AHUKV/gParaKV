#!/bin/bash

ulimit -n 999999

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloada.spec &> ./a.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloadb.spec &> ./b.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloadc.spec &> ./c.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloadd.spec &> ./d.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloade.spec &> ./e.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/4KB/workloadf.spec &> ./f.txt

