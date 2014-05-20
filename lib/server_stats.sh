#!/bin/bash

# install necessary files:
# sudo apt-get install bc

# make this file executable:
# chmod +x server_stats.sh

# add to crontab (command: crontab -e)
# * * * * * /path/to/server_stats.sh

# thingspeak api key for channel that data will be logged to
api_key='XXXXXXXXXXXXXXXX'

# get cpu usage as a percent
used_cpu_percent=`top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 \
| tr -s ' ' | cut -f2 -d' ' | cut -f1 -d'%'`
echo $used_cpu_percent

# get memory
used_mem=`free -m | tr -s ' ' | grep buffers/cache | cut -f3 -d' '`
total_mem=`free -m | tr -s ' ' | grep Mem | cut -f2 -d' '`
used_mem_percent=`echo "scale=2;100*$used_mem/$total_mem" | bc`
echo $used_mem_percent

# get disk use as a percent
used_disk_percent=`df -lh | awk '{if ($6 == "/") { print $5 }}' \
| head -1 | cut -d'%' -f1`
echo $used_disk_percent

# post the data to thingspeak
curl -k --data \
"api_key=$api_key&field1=$used_cpu_percent&field2=$used_mem_\
percent&field3=$used_disk_percent" https://api.thingspeak.com/update

