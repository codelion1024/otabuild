#!/system/bin/sh

# I am sure $srcver variable is useless for full ota
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
    echo "ota package is build for $device, can't apply for $dev_local"
    exit
fi
echo "we use this script to record and handle all of the ARTIFICIAL PROCESS for ${device}'s $style ota update"
echo "ARTIFICIAL PROCESS begin"

# 解决 Bug 188158: 【1713-A01_049】【智能聚合页】48-49OTA后负一屏未删除
# 解决 Bug 188600: 【1713-A01--052】【OS3.0】一路OTA升级成功后快视频仍然存在
# 由于1713 55版本的OTA包部署之后，周六有用户反馈连接5G wifi时蓝牙断连问题，所以紧急撤掉55版本，重新发布了58版本
# 所以，还得麻烦你帮忙制作40<->58  43<->58的OTA包
if ([ $ver_local == "040" ] || [ $ver_local == "043" ]) && [ $tgtver == "058" ]; then
  mount -v -t ext4 -o max_batch_time=0,commit=1,data=ordered,barrier=1,errors=panic,nodelalloc /dev/block/bootdevice/by-name/userdata /data
  rm -rf /data/app/com.qiku.cardmanager*
  rm -rf /data/app/com.lightsky.video*
  umount /data
fi


echo "ARTIFICIAL PROCESS end"