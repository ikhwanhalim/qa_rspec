#!/bin/bash

memory=`free -m |awk '{print $2}'| sed -n 2p`

cpu=`cat /proc/cpuinfo |grep processor |tail -1 |awk '{print $3+1}'`

primary_disk=`df -hm | awk '{if($6=="/") print $2}'`

swap=`free -m | grep wap: | awk {'print $2-G-B-H'}`

mounted_tmp=`df -hm | awk -v dd=':' -v dq='"' '/mnt/ {print dq$6dq dd dq$2dq}'`

mounted=`echo $mounted_tmp | sed 's/\" \"/\"\,\"/g'`

primary_network_interface=`ip route get 8.8.8.8 | awk -v dq='"' '{if($1=="8.8.8.8") print dq$5dq}'`

primary_network_ip=`ip route get 8.8.8.8 | awk -v dq='"' '{if($1=="8.8.8.8") print dq$7dq}'`

echo "{\"system\":{\"memory\":\"$memory\",\"cpu\":\"$cpu\"},
        \"networks\":{\"primary\":{\"ip\":$primary_network_ip,\"interface\":$primary_network_interface}},
        \"disks\":{\"primary\":\"$primary_disk\", \"swap\":\"$swap\", \"mounted\":{$mounted}}}"
