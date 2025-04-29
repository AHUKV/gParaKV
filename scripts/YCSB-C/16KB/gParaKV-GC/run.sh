#!/bin/bash

ulimit -n 999999

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloada.spec &> ./a.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloadb.spec &> ./b.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloadc.spec &> ./c.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloadd.spec &> ./d.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloade.spec &> ./e.txt

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/bin/ycsbc -filename /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/16KB/workloadf.spec &> ./f.txt

