#!/sbin/sh

srcver=`busybox cat /tmp/info.txt | busybox grep srcver | busybox cut -d '=' -f 2`
tgtver=`busybox cat /tmp/info.txt | busybox grep tgtver | busybox cut -d '=' -f 2`
device=`busybox cat /tmp/info.txt | busybox grep device | busybox cut -d '=' -f 2`
style=`busybox cat /tmp/info.txt | busybox grep style | busybox cut -d '=' -f 2`
SIGNTYPE=`busybox cat /tmp/info.txt | busybox grep SIGNTYPE | busybox cut -d '=' -f 2`
priority=`busybox cat /tmp/info.txt | busybox grep priority | busybox cut -d '=' -f 2`
full_bsp_modem=`busybox cat /tmp/info.txt | busybox grep full_bsp_modem | busybox cut -d '=' -f 2`
PLATFORM=`busybox cat /tmp/info.txt | busybox grep PLATFORM | busybox cut -d '=' -f 2`
hw_version=`busybox cat /tmp/info.txt | busybox grep hw_version | busybox cut -d '=' -f 2`
# use -v '^#' to filter out comment lines
ver_local=`busybox grep -v '^#' /default.prop | busybox grep ro.build.version.incremental | busybox cut -d '=' -f 2`
dev_local=`busybox grep -v '^#' /default.prop | busybox grep ro.product.device | busybox cut -d '=' -f 2`


if [ $device != $dev_local ]; then
    echo "this package is build for $device, can't apply for $dev_local"
    exit
fi
if [ $srcver != $ver_local ]; then
    echo "this package is backward incremental, build form $srcver, can't apply from $ver_local"
    exit
fi
echo "we use this script to record and handle all of the ARTIFICIAL PROCESS for ${device}'s $style ota update"
echo "ARTIFICIAL PROCESS begin"




echo "ARTIFICIAL PROCESS end"
