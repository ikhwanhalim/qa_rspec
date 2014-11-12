#!/bin/bash

memory=`free -m |awk '{print $2}'| sed -n 2p`

cpu=`cat /proc/cpuinfo |grep processor |tail -1 |awk '{print $3+1}'`

disk=`df -hm | awk {'print $1" "$2'} | grep /dev/ | awk {'print $2-G-B-H'}`

swap=`free -m | grep wap: | awk {'print $2-G-B-H'}`



echo "{\"system\":{\"memory\":\"$memory\",\"cpu\":\"$cpu\"}, \"disks\":{\"primary\":\"$disk\", \"swap\":\"$swap\"}}"
