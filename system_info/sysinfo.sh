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
echo "User: $current_user"
echo "Hostname: $host_name"
echo "Date: $current_datetime"
echo "---------------------------------------"

#2. Uptime
uptime_string=$(uptime -p)

echo "-----------------Uptime-----------------"
echo "$uptime_string"
echo ""

#3. Memory Usage
total_memory=$(free -h | awk '/^Mem:/{print $2}')
used_memory=$(free -m | awk '/^Mem:/{print $3}')
free_memory=$(free -m | awk '/^Mem:/{print $4}')

echo "----------------Memory (MB)--------------"
echo "Total: $total_memory MB | Used: $used_memory MB | Free: $free_memory MB"
echo ""

#4. Disk Usage
total_disk=$(df -h / | awk 'NR==2 {print $2}')
used_disk=$(df -h / | awk 'NR==2 {print $3}')
free_disk=$(df -h / | awk 'NR==2 {print $4}')

echo "-----------------Disk Usage---------------"
echo "Total: $total_disk | Used: $used_disk | Free: $free_disk"
echo ""

#5. Running Processes, total processes
total_processes=$(ps aux | wc -l)
total_processes=$((total_processes - 1))

echo "------------------Processes---------------"
echo "Running: $total_processes"

#Display the top 5 memory-consuming processes
echo "Top 5 Memory-Consuming Processes:"
echo "------------------------------------------"
ps aux --sort=-%mem | head -6 | awk '{printf "PID: %-6s | MEM: %-6s | CMD: %s\n", $2, $4, $11}'
echo ""

# Warning if free memory is low
if [ "$free_memory" -lt 500 ]; then
    echo "WARNING: Low memory! Only ${free_memory}MB free."
fi

# Warning if free disk space is low
free_disk_num="${free_disk//G/}"
if [ "$free_disk_num" -lt 10 ]; then
    echo "WARNING: Low disk space! Only ${free_disk} free."
fi

echo "============================================="
echo "                   Dashboard Ok         "
echo "============================================="