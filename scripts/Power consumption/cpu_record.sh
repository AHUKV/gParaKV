#!/bin/bash
CPU0_ENERGY=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
CPU1_ENERGY=$(cat /sys/class/powercap/intel-rapl:1/energy_uj)
LAST_ENERGY_VALUE=$((CPU0_ENERGY + CPU1_ENERGY))

while true; do
    MEM_USAGE=$(ps -p $(pgrep -d',' db_bench) -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')
    CPU_USAGE=$(pidstat -p $(pgrep -d',' db_bench) 1 1 | tail -n 1 | awk '{print $8 " %"}')


    CPU0_ENERGY=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
    CPU1_ENERGY=$(cat /sys/class/powercap/intel-rapl:1/energy_uj)
    CURRENT_ENERGY_VALUE=$((CPU0_ENERGY + CPU1_ENERGY))
    ENERGY_DIFF=$(($CURRENT_ENERGY_VALUE - $LAST_ENERGY_VALUE))
    LAST_ENERGY_VALUE=$CURRENT_ENERGY_VALUE
    POWER_USAGE=$(echo "$ENERGY_DIFF / 1000000" | bc -l) 
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE, Power Usage: ${POWER_USAGE} W" >> cpu.log
    sleep 1
done
