#!/sbin/sh

# I am sure $srcver variable is useless for full ota
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
sdk_ver=`busybox grep -v '^#' /default.prop | busybox grep ro.build.version.sdk | busybox cut -d '=' -f 2`

# in project with 7.1.1(sdk 25), ro.build.version.incremental is like '023'
# in project with 8.1.0(sdk 27), ro.build.version.incremental is like '8.1.077.PX.180518.360OS_360OS_QK1807_CN'
# if we try to let ver_local stands for a pure digital build number, we should parse againg in 8.1.0
if [ $sdk_ver -eq 27 ]; then
  ver_local=`echo $ver_local | cut -d '.' -f 3`
fi

if [ $device != $dev_local ]; then
    echo "ota package is build for $device, can't apply for $dev_local"
    exit
fi
echo "we use this script to record and handle all of the ARTIFICIAL PROCESS for ${device}'s $style ota update"
echo "ARTIFICIAL PROCESS begin"

# TFS_208071:1803正向升级到063版本后清除指纹数据
if [ $ver_local -lt 063 ] && [ $tgtver -eq 063 ]; then
  mount -v -t ext4 -o max_batch_time=0,commit=1,data=ordered,barrier=1,errors=panic,nodelalloc /dev/block/bootdevice/by-name/userdata /data
  echo "handle TFS_208071 begin"
  rm -f /data/system/locksettings.db
  echo "handle TFS_208071 end"
  umount /data
fi

echo "ARTIFICIAL PROCESS end"
