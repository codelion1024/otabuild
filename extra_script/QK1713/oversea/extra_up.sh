#!/system/bin/sh

srcver=`cat /tmp/info.txt | grep srcver | busybox cut -d '=' -f 2`
tgtver=`cat /tmp/info.txt | grep tgtver | busybox cut -d '=' -f 2`
device=`cat /tmp/info.txt | grep device | busybox cut -d '=' -f 2`
style=`cat /tmp/info.txt | grep style  | busybox cut -d '=' -f 2`
SIGNTYPE=`cat /tmp/info.txt | grep SIGNTYPE  | busybox cut -d '=' -f 2`
priority=`cat /tmp/info.txt | grep priority  | busybox cut -d '=' -f 2`
full_bsp_modem=`cat /tmp/info.txt | grep full_bsp_modem  | busybox cut -d '=' -f 2`
PLATFORM=`cat /tmp/info.txt | grep PLATFORM  | busybox cut -d '=' -f 2`
hw_version=`cat /tmp/info.txt | grep hw_version  | busybox cut -d '=' -f 2`
ver_local=$(getprop ro.build.version.incremental)
dev_local=$(getprop ro.product.device)


if [ $device != $dev_local ]; then
    echo "this package is build for $device, can't apply for $dev_local"
    exit
fi
if [ $srcver != $ver_local ]; then
    echo "this package is forward incremental, build form $srcver, can't apply from $ver_local"
    exit
fi
echo "we use this script to record and handle all of the ARTIFICIAL PROCESS for ${device}'s $style ota update"
echo "ARTIFICIAL PROCESS begin"




echo "ARTIFICIAL PROCESS end"