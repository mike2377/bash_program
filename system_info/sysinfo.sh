#!/bin/bash

#1. System Identity, current user
current_user=$(whoami)

#hostname
host_name=$(hostname)

#current date
current_datetime=$(date +"%a %b %d %T")

echo "======================================="
echo "             SYSTEM INFO               "
echo "======================================="
echo -e "\033[0;32m User: $current_user \033[0m"
echo -e "\033[0;32m Hostname: $host_name \033[0m"
echo -e "\033[0;32m Date: $current_datetime \033[0m\033[0m"
echo "---------------------------------------"

#2. Uptime
uptime_string=$(uptime -p)

echo "-----------------Uptime-----------------"
echo -e "\033[0;32m $uptime_string \033[0m"
echo ""

#3. Memory Usage
total_memory=$(free -h | awk '/^Mem:/{print $2}')
used_memory=$(free -m | awk '/^Mem:/{print $3}')
free_memory=$(free -m | awk '/^Mem:/{print $4}')

echo "----------------Memory (MB)--------------"
echo -e "\033[0;32m Total: $total_memory MB | Used: $used_memory MB | Free: $free_memory MB \033[0m"
echo ""

#4. Disk Usage
total_disk=$(df -h / | awk 'NR==2 {print $2}')
used_disk=$(df -h / | awk 'NR==2 {print $3}')
free_disk=$(df -h / | awk 'NR==2 {print $4}')

echo "-----------------Disk Usage---------------"
echo -e "\033[0;32m Total: $total_disk | Used: $used_disk | Free: $free_disk \033[0m"
echo ""

#5. Running Processes, total processes
total_processes=$(ps aux | wc -l)
total_processes=$((total_processes - 1))

echo "------------------Processes---------------"
echo -e "\033[0;32m Running: $total_processes \033[0m"

#Display the top 5 memory-consuming processes
echo "Top 5 Memory-Consuming Processes:"
echo "------------------------------------------"
top_fivemem=$(ps aux --sort=-%mem | head -6 | awk '{printf "PID: %-6s | MEM: %-6s | CMD: %s\n", $2, $4, $11}')
echo -e "\033[0;32m$top_fivemem \033[0m"
echo ""

# Warning if free memory is low
if [ "$free_memory" -lt 500 ]; then
    echo -e "\033[0;31m WARNING: Low memory! Only ${free_memory}MB free. \033[0m"
else
    echo -e "\033[0;32m High Memory Only ${free_memory}MB \033[0m"
fi

# Warning if free disk space is low
free_disk_num="${free_disk//G/}"
if [ "$free_disk_num" -lt 10 ]; then
    echo -e "\033[0;31m WARNING: Low disk space! Only ${free_disk} free. \033[0m"
else
    echo -e "\033[0;32m High disk space ${free_disk}MB \033[0m"
fi
echo ""

#CPU usage
echo "CPU Usage"
echo "------------------------------------------"
cpu_usage=$(top -bn2 -d 0.1 | grep '^%Cpu' | tail -n 1 | awk '{print $2 + $4}')
echo -e "\033[0;32mCurrent CPU Usage: $cpu_usage%\033[0m"
echo ""

echo "============================================="
echo "                   Dashboard Ok         "
echo "============================================="