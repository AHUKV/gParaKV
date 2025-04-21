#!/bin/bash

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloada.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/a.txt

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadb.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/b.txt

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadc.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/c.txt

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadd.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/d.txt

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloade.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/e.txt

/home/ubuntu/My/AHKV/AHKV-1024/ycsbc/ycsbc -filename /mnt/pmem -vlog /media/test -db leveldb -configpath 0 -P /home/ubuntu/My/GPURocksDB-V3/workloads/100/workloadf.spec &> /home/ubuntu/GDH/ycsbc/AHKV/1KB/100/f.txt

