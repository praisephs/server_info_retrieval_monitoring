#!/bin/bash

LOG_FILE="/home/praisephs/server_monitoring/devopsfetch_logs/devopsfetch.log"
DATE_FORMAT=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$DATE_FORMAT] Monitoring started" >> $LOG_FILE

while true; do
    DATE_FORMAT=$(date +"%Y-%m-%d %H:%M:%S")
    {
        echo "------------------------------"
        echo "[$DATE_FORMAT] Collecting system information..."
        echo "------------------------------"

        # System Information
        echo "System Information:"
        uname -a

        # CPU and Memory Usage
        echo -e "\nCPU and Memory Usage:"
        top -b -n1 | head -n 10

        # Disk Usage
        echo -e "\nDisk Usage:"
        df -h

        # Memory Status
        echo -e "\nMemory Status:"
        free -h

        # Active Users
        echo -e "\nActive Users:"
        who

        # Recent User Logins
        echo -e "\nRecent User Logins:"
        last -n 5

        # Open Ports
        echo -e "\nOpen Ports:"
        ss -tuln

        # Nginx Domain Information
        echo -e "\nNginx Domain Information:"
        grep "server_name" /etc/nginx/sites-available/* | awk '{print $3}'

        echo "------------------------------"
        echo "[$DATE_FORMAT] Collection complete"
        echo "------------------------------"
    } >> "$LOG_FILE"

    # Implement a delay before the next iteration
    sleep 3600 # Log every hour
done

