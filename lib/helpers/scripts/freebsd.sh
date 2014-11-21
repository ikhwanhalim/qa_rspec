#!/bin/sh

set memory=`dmesg | awk '/real memory/ {print $4/1024/1024}'`

set cpu=`dmesg | grep -oE 'cpu[0-9]*' | awk 'END{printf "%.0f\n", (NR+0.1)/2}'`

set primary_disk=`df -hm | awk '{if($6=="/") print $2}'`


set swap=`swapinfo -hm | awk '/dev/ {print $2}'`

set mounted_tmp=`df -hm | awk -v sq="'" '/mnt/ {print sq$6sq sq$2sq}'`

set mounted=`echo $mounted_tmp | sed "s/''/','/g"`

set system="'system':{'memory':'$memory','cpu':'$cpu'}"
set disks="'disks':{'primary':'$primary_disk', 'swap':'$swap', 'mounted':{$mounted}}"

echo "{$system,$disks}"