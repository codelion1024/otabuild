#!/system/bin/sh


srcver=         `cat /tmp/info.txt | grep srcver | busybox cut -d '=' -f 2`
tgtver=         `cat /tmp/info.txt | grep tgtver | busybox cut -d '=' -f 2`
device=         `cat /tmp/info.txt | grep device | busybox cut -d '=' -f 2`
style=          `cat /tmp/info.txt | grep style  | busybox cut -d '=' -f 2`
SIGNTYPE=       `cat /tmp/info.txt | grep SIGNTYPE  | busybox cut -d '=' -f 2`
priority=       `cat /tmp/info.txt | grep priority  | busybox cut -d '=' -f 2`
full_bsp_modem= `cat /tmp/info.txt | grep full_bsp_modem  | busybox cut -d '=' -f 2`
PLATFORM=       `cat /tmp/info.txt | grep PLATFORM  | busybox cut -d '=' -f 2`
hw_version=     `cat /tmp/info.txt | grep hw_version  | busybox cut -d '=' -f 2`
if [ $device != $(getprop ro.product.device) ]; then
    echo "ota package is build for $device, can apply for $(getprop ro.product.device)"
fi


