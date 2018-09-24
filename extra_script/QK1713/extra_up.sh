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



# 解决 Bug 188158: 【1713-A01_049】【智能聚合页】48-49OTA后负一屏未删除
# 解决 Bug 188600: 【1713-A01--052】【OS3.0】一路OTA升级成功后快视频仍然存在
if [ tgtver == "054" ]; then
  rm -rf  /data/app/com.qiku.cardmanager*
  rm -rf  /data/app/com.lightsky.video*
fi
    
