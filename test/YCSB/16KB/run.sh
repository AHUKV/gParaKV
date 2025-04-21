#!/bin/bash

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloada.spec &> ./a.txt

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloadb.spec &> ./b.txt

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloadc.spec &> ./c.txt

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloadd.spec &> ./d.txt

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloade.spec &> ./e.txt

/home/ubuntu/My/ParaKV/cmake-build-debug/bin/ycsbc -filename /mnt/pmem -vlog /media/test/test1 -db leveldb -configpath 0 -P /home/ubuntu/My/ParaKV/workloads/100/16KB/workloadf.spec &> ./f.txt

