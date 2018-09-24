#!/bin/bash


echo $BUILD_TAG--步骤$(expr $STEP + 1)--初始化并打印所有参数

ota_param_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $ota_param_dir
ota_param_file=$ota_param_dir/ota_parameter.txt
mv -v $WORKSPACE/ota_parameter.txt $ota_param_file
enca -L zh_CN -x UTF-8 $ota_param_file

outputdir=$otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $outputdir
target_old_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/oldtarget;mkdir -p $target_old_dir
target_new_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/newtarget;mkdir -p $target_new_dir

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
SIGNAPK=$otabuild/tools/sign/signapk.jar
Int_KEY=$otabuild/tools/sign/int/testkey
Rel_KEY=$otabuild/tools/sign/rel/testkey
OTA_TYPE=stable

if [ $SIGNTYPE = "Int" ]; then KEY=$Int_KEY; fi
if [ $SIGNTYPE = "Rel" ]; then KEY=$Rel_KEY; fi
if [ $PROJECT_NAME = "QK1607" ]; then
  PLATFORM=QC8976;window_out_path=/mnt/hgfs/ota/QC8976_Test_Version/${PROJECT_NAME};mkdir -p $window_out_path; 
fi
if [ $PROJECT_NAME = "QK1713" ]; then
  PLATFORM=SDM630;window_out_path=/mnt/hgfs/ota/QCOM_SDM630/${PROJECT_NAME};mkdir -p $window_out_path;
fi
if [ $PROJECT_NAME = "QK1711" ]; then
  PLATFORM=QC8940;window_out_path=/mnt/hgfs/ota/QC8940_Test_Version/QK1711_OS3.0;mkdir -p $window_out_path;
fi

PLAT_CFG_FILE=$otabuild/tools/config/${PLATFORM}_ota_parameter.txt
int_server_name=`grep '^int_server_name' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
int_server_ip=`grep '^int_server_ip' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
int_platform=`grep '^int_platform' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
int_server=/mnt/hgfs/$int_server_name/${PROJECT_NAME}/${PROJECT_NAME}_Int
rel_server_name=`grep '^rel_server_name' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
rel_server_ip=`grep '^rel_server_ip' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
rel_version=`grep '^rel_version=' $PLAT_CFG_FILE | awk -F = '{print $2}' | tr -d " "| tr -d "\r"`
rel_platform=`grep '^rel_platform' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
rel_server=/mnt/hgfs/$rel_server_name/${PROJECT_NAME}

source_version=$(grep source_version $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}' | sed 's/\\/\//g' | sed 's/\/\/'$rel_server_ip'\/'$rel_version'\/'$rel_platform'/\/mnt\/hgfs\/'$rel_server_name'/g' | sed 's/\/\/'$int_server_ip'\/'$int_platform'/\/mnt\/hgfs\/'$int_server_name'/g')
dest_version=$(grep dest_version $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}' | sed 's/\\/\//g' | sed 's/\/\/'$rel_server_ip'\/'$rel_version'\/'$rel_platform'/\/mnt\/hgfs\/'$rel_server_name'/g' | sed 's/\/\/'$int_server_ip'\/'$int_platform'/\/mnt\/hgfs\/'$int_server_name'/g')
priority=$(grep priority $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
description=$(grep description $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
ota_style=$(grep ota_style $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
full_bsp_modem=$(grep full_bsp_modem $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
target_old_win=$(ls $source_version/*cota*.zip)
target_new_win=$(ls $dest_version/*cota*.zip)
target_old_file=$target_old_dir/$(basename $target_old_win)
target_new_file=$target_new_dir/$(basename $target_new_win)
old_ver=$(basename --suffix=.zip $target_old_win | awk -F \- '{print $4}')
new_ver=$(basename --suffix=.zip $target_new_win | awk -F \- '{print $4}')
hw_version=$(echo $target_old_win | awk -F \/ '{print $7}' | awk -F \. '{print $2}')
if [ $priority = "" ]; then priority=Optional; fi


echo =========================所有信息BEGIN==================================
echo "ANDROID           $ANDROID"
echo "otabuild          $otabuild"
echo "PROJECT_NAME      $PROJECT_NAME"
echo "SIGNTYPE          $SIGNTYPE"
echo "TIME              $TIME"
echo "ota_param_dir     $ota_param_dir"
echo "ota_param_file    $ota_param_file"
cat -n $ota_param_file
echo "outputdir         $outputdir"
echo "target_old_dir    $target_old_dir"
echo "target_new_dir    $target_new_dir"
echo "OTA_TYPE          $OTA_TYPE"
echo "PLATFORM          $PLATFORM"
echo "window_out_path   $window_out_path"
echo "DEV_SRC           $DEV_SRC"
echo "DEV_DST           $DEV_DST"
echo "PLAT_CFG_FILE     $PLAT_CFG_FILE"
echo --------------------------------------------------------------
echo "int_server_name   $int_server_name"
echo "int_server_ip     $int_server_ip"
echo "int_platform      $int_platform"
echo "int_server        $int_server"
echo "rel_server_name   $rel_server_name"
echo "rel_server_ip     $rel_server_ip"
echo "rel_version       $rel_version"
echo "rel_platform      $rel_platform"
echo "rel_server        $rel_server"
echo --------------------------------------------------------------
echo "source_version    $source_version"
echo "dest_version      $dest_version"
echo "priority          $priority"
echo "description       $description"
echo "ota_style         $ota_style"
echo "full_bsp_modem    $full_bsp_modem"
echo "target_old_win    $target_old_win"
echo "target_new_win    $target_new_win"
echo "target_old_file   $target_old_file"
echo "target_new_file   $target_new_file"
echo "old_ver           $old_ver"
echo "new_ver           $new_ver"
echo "hw_version        $hw_version"
echo =========================所有信息END==================================



echo =================将target-files从/mnt/hgfs拷贝到$otabuild/input下======================
cp -vf $target_old_win $target_old_dir
cp -vf $target_new_win $target_new_dir

mkdir -p $otabuild/linux-x86;mkdir $otabuild/linux-x86/bin;mkdir $otabuild/linux-x86/framework;mkdir $otabuild/linux-x86/lib64;
cp -vu $ANDROID/out/host/linux-x86/bin/bsdiff $ANDROID/out/host/linux-x86/bin/imgdiff $otabuild/linux-x86/bin/
cp -vu $ANDROID/out/host/linux-x86/framework/signapk.jar $otabuild/linux-x86/framework/
cp -vu $ANDROID/out/host/linux-x86/lib64/libc++.so $ANDROID/out/host/linux-x86/lib64/libconscrypt_openjdk_jni.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort64.so $otabuild/linux-x86/lib64/

