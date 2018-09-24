#!/bin/bash

printf "%s\n" "$BUILD_TAG--步骤$((STEP++))--初始化并打印所有参数"

ota_param_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $ota_param_dir
ota_param_file=$ota_param_dir/ota_parameter.txt
mv -v $WORKSPACE/ota_parameter.txt $ota_param_file
enca -L zh_CN -x UTF-8 $ota_param_file

outputdir=$otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $outputdir
target_old_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/oldtarget;mkdir -p $target_old_dir
target_new_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/newtarget;mkdir -p $target_new_dir
mkdir -p $window_out_path;

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
OTA_TYPE=stable

PLAT_CFG_FILE=$otabuild/tools/config/${PLATFORM}_ota_parameter.txt
SIGNAPK=$otabuild/tools/signapk.jar
Int_KEY=$ANDROID/build/target/product/security/testkey
Rel_KEY=/mnt/hgfs/security/testkey
targetfiles_server_ip=`grep '^targetfiles_server_ip' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
targetfiles_subroot_win=`grep '^targetfiles_subroot_win' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`
targetfiles_subroot_linux=`grep '^targetfiles_subroot_linux' $PLAT_CFG_FILE | awk -F =  '{print $2}' | tr -d " "| tr -d "\r"`

target_old_windir=$(grep source_version $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}' | sed 's/\\/\//g' | sed 's/\/\/'$targetfiles_server_ip'\/'$targetfiles_subroot_win'/\/mnt\/hgfs\/'$targetfiles_subroot_linux'/g')
target_new_windir=$(grep dest_version $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}' | sed 's/\\/\//g' | sed 's/\/\/'$targetfiles_server_ip'\/'$targetfiles_subroot_win'/\/mnt\/hgfs\/'$targetfiles_subroot_linux'/g')
priority=$(grep priority $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
description=$(grep description $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
ota_style=$(grep ota_style $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
full_bsp_modem=$(grep full_bsp_modem $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
target_old_win=$(ls $target_old_windir/*cota*.zip)
target_new_win=$(ls $target_new_windir/*cota*.zip)
target_old_file=$target_old_dir/$(basename $target_old_win)
target_new_file=$target_new_dir/$(basename $target_new_win)
old_ver=$(basename --suffix=.zip $target_old_win | awk -F \- '{print $4}')
new_ver=$(basename --suffix=.zip $target_new_win | awk -F \- '{print $4}')
hw_version=$(echo $target_old_win | awk -F \/ '{print $7}' | awk -F \. '{print $2}')
if [ $priority = "" ]; then priority=Optional; fi
if [ $ota_style = "" ]; then ota_style=all; fi
if [ $SIGNTYPE = "Int" ]; then KEY=$Int_KEY; fi
if [ $SIGNTYPE = "Rel" ]; then KEY=$Rel_KEY; fi

printf "%s\n" "=========================所有信息BEGIN=================================="
printf "BIGVERSION                  %s\n" $BIGVERSION
printf "market                      %s\n" $market
printf "ANDROID                     %s\n" $ANDROID
printf "otabuild                    %s\n" $otabuild
printf "PROJECT_NAME                %s\n" $PROJECT_NAME
printf "SIGNTYPE                    %s\n" $SIGNTYPE
printf "TIME                        %s\n" $TIME
printf "ota_param_dir               %s\n" $ota_param_dir
printf "ota_param_file              %s\n" $ota_param_file
cat -n $ota_param_file
printf "outputdir                   %s\n" $outputdir
printf "target_old_dir              %s\n" $target_old_dir
printf "target_new_dir              %s\n" $target_new_dir
printf "OTA_TYPE                    %s\n" $OTA_TYPE
printf "PLATFORM                    %s\n" $PLATFORM
printf "window_out_path             %s\n" $window_out_path
printf "PLAT_CFG_FILE               %s\n" $PLAT_CFG_FILE
printf "%s\n" "--------------------------------------------------------------"
printf "targetfiles_server_ip       %s\n" $targetfiles_server_ip
printf "targetfiles_server_ip       %s\n" $targetfiles_server_ip
printf "targetfiles_subroot_linux   %s\n" $targetfiles_subroot_linux
printf "%s\n" "--------------------------------------------------------------"
printf "target_old_windir           %s\n" $target_old_windir
printf "target_new_windir           %s\n" $target_new_windir
printf "priority                    %s\n" $priority
printf "description                 %s\n" $description
printf "ota_style                   %s\n" $ota_style
printf "full_bsp_modem              %s\n" $full_bsp_modem
printf "target_old_win              %s\n" $target_old_win
printf "target_new_win              %s\n" $target_new_win
printf "target_old_file             %s\n" $target_old_file
printf "target_new_file             %s\n" $target_new_file
printf "old_ver                     %s\n" $old_ver
printf "new_ver                     %s\n" $new_ver
printf "hw_version                  %s\n" $hw_version
printf "%s\n" "=========================所有信息END=================================="


printf "=================将host端工具从out拷贝到%s/linux-x86下======================\n" $otabuild
if [ ! -d $otabuild/linux-x86 ]; then mkdir -p $otabuild/linux-x86; fi
if [ ! -d $otabuild/linux-x86/bin ]; then mkdir $otabuild/linux-x86/bin; fi
if [ ! -d $otabuild/linux-x86/framework ]; then mkdir $otabuild/linux-x86/framework; fi
if [ ! -d $otabuild/linux-x86/lib64 ]; then mkdir $otabuild/linux-x86/lib64; fi
cp -vu $ANDROID/out/host/linux-x86/bin/bsdiff $ANDROID/out/host/linux-x86/bin/imgdiff $otabuild/linux-x86/bin/
cp -vu $ANDROID/out/host/linux-x86/framework/signapk.jar $otabuild/linux-x86/framework/
cp -vu $ANDROID/out/host/linux-x86/lib64/libc++.so $ANDROID/out/host/linux-x86/lib64/libconscrypt_openjdk_jni.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort64.so $otabuild/linux-x86/lib64/

printf "=================将target-files从/mnt/hgfs拷贝到%s/input下======================\n" $otabuild
cp -vf $target_old_win $target_old_dir
if [ $check_integrity = "true" ]; then
    zip -T $target_old_file
    if [ $? != 0 ]; then echo "$target_old_file is missing or data corrupt!";clean_and_quit; fi
fi

cp -vf $target_new_win $target_new_dir
if [ $check_integrity = "true" ]; then
    zip -T $target_new_file
    if [ $? != 0 ]; then echo "$target_new_file is missing or data corrupt!";clean_and_quit; fi
fi