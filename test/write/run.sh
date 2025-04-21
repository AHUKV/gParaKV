/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=400000000 --value_size=256 --db=/mnt/pmem --vlog=/media/test &> 256.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 256.log

    # 睡眠1秒
    sleep 1
done

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=700000000 --value_size=128 --db=/mnt/pmem --vlog=/media/test &> 128.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 128.log

    # 睡眠1秒
    sleep 1
done


exit 0

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=25000000 --value_size=4096 --db=/mnt/pmem --vlog=/media/test &> 4096.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 4096.log

    # 睡眠1秒
    sleep 1
done

/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=1562500 --value_size=65536 --db=/mnt/pmem --vlog=/media/test &> 65536.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 65536.log

    # 睡眠1秒
    sleep 1
done


/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=100000000 --value_size=1024 --db=/mnt/pmem --vlog=/media/test &> 1024.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 1024.log

    # 睡眠1秒
    sleep 1
done



/home/ubuntu/My/ParaKV-GC/cmake-build-debug/db_bench --benchmarks=fillrandom --num=390625 --value_size=262144 --db=/mnt/pmem --vlog=/media/test &> 262144.txt &

# 得到 db_bench 命令的进程ID
DB_BENCH_PID=$!

# 无限循环，直到 db_bench 命令结束
while ps -p $DB_BENCH_PID > /dev/null; do
    # 获取内存使用情况
    MEM_USAGE=$(ps -p $DB_BENCH_PID -o rss= | awk '{sum+=$1} END {print sum/1024 " MB"}')

    # 获取CPU使用情况
    # 使用pidstat时确保间隔时间足够获取数据，这里使用了 2 秒来确保有数据输出
    CPU_USAGE=$(pidstat -p $DB_BENCH_PID 2 1 | tail -n 1 | awk '{print $8 " %"}')

    # 输出到日志文件
    echo "Memory Usage: $MEM_USAGE, CPU Usage: $CPU_USAGE" >> 262144.log

    # 睡眠1秒
    sleep 1
done
