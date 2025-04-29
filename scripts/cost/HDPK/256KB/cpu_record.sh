#!/bin/bash

# 上次能耗读数的初始值
CPU0_ENERGY=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
CPU1_ENERGY=$(cat /sys/class/powercap/intel-rapl:1/energy_uj)
LAST_ENERGY_VALUE=$((CPU0_ENERGY + CPU1_ENERGY))

while true; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $(pgrep -d',' db_bench) -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    CPU_USAGE=$(pidstat -p $(pgrep -d',' db_bench) 1 1 | tail -n 1 | awk '{print $8 " %"}')


    CPU0_ENERGY=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
    CPU1_ENERGY=$(cat /sys/class/powercap/intel-rapl:1/energy_uj)
    # 获取当前能耗读数
    CURRENT_ENERGY_VALUE=$((CPU0_ENERGY + CPU1_ENERGY))
    # 计算能耗差，即本次和上次读数之差
    ENERGY_DIFF=$(($CURRENT_ENERGY_VALUE - $LAST_ENERGY_VALUE))
    # 更新上次能耗读数
    LAST_ENERGY_VALUE=$CURRENT_ENERGY_VALUE
    # 计算功率，假定时间间隔大约为1秒
    POWER_USAGE=$(echo "$ENERGY_DIFF / 1000000" | bc -l) # 转换为瓦特(W)

    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE, Power Usage: ${POWER_USAGE} W" >> cpu.log
    sleep 1
done
