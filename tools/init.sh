#!/bin/bash

function get_targetfiles_dir_XIAN()
{
  netpath_full=$(grep $1 $ota_param_file | awk -F \= '{print $2}' | sed 's/\\/\//g')
  while read line
  do
    netpath_prefix=$(echo $line | awk '{print $5}')
    mountpath=$(echo $line | awk '{print $6}')
    if [[ $netpath_full == *$netpath_prefix* ]]; then
      behind=$(echo "$netpath_full" | awk -F "$netpath_prefix" '{printf "%s",$2}')
      echo $mountpath$behind
      break
    fi
  done < ~/bin/mount.sh # build server in xian use ~/bin/mount.sh to manage mountpoint
}

function get_targetfiles_dir_SHENZHEN()
{
  netpath_full=$(grep $1 $ota_param_file | awk -F \= '{print $2}' | sed 's/\\/\//g')
  while read line
  do
    netpath_prefix=$(echo $line | awk '{print $1}')
    mountpath=$(echo $line | awk '{print $2}')
    if [[ $netpath_full == *$netpath_prefix* ]]; then
      behind=$(echo "$netpath_full" | awk -F "$netpath_prefix" '{printf "%s",$2}')
      echo $mountpath$behind
      break
    fi
  done < /etc/fstab # build server in shenzhen use /etc/fstab to manage mountpoint
}

function join_description()
{
  DES_TEXT_FILE=$otabuild/input/description.txt
  DES_LINE_RANGE=`awk '/TEXT/ {print NR}' $1`  # get the line number of "[TEXT]" and "[/TEXT]"
  DES_LINENU_BEGIN=`echo $DES_LINE_RANGE | awk -F " " '{print $1}'`
  DES_LINENU_END=`echo $DES_LINE_RANGE | awk -F " " '{print $2}'`
  if [ $DES_LINENU_END -le `expr $DES_LINENU_BEGIN + 1` ]; then echo "DES_LINENU_END $DES_LINENU_END must > DES_LINENU_BEGIN $DES_LINENU_BEGIN + 1"; clean_and_quit; fi

  awk -F '\t' 'NR=='$DES_LINENU_BEGIN+1',NR=='$DES_LINENU_END-1' {print $1 " " $2}' $1 > $DES_TEXT_FILE
  while read line
  do
    des_joined=${des_joined}\\\n${line}
  done < $DES_TEXT_FILE
  echo "<![CDATA[${des_joined#*n}]]>"
}

printf "%s\n" "$BUILD_TAG--步骤$((STEP++))--初始化并打印所有参数"

ota_param_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $ota_param_dir
ota_param_file=$ota_param_dir/ota_parameter.txt
mv -v $WORKSPACE/ota_parameter.txt $ota_param_file
dos2unix $ota_param_file
enca -L zh_CN -x UTF-8 $ota_param_file

if [ $LOCATION == "XIAN" ]; then
  target_old_windir=$(get_targetfiles_dir_XIAN source_version)
  target_new_windir=$(get_targetfiles_dir_XIAN dest_version)
elif [ $LOCATION == "SHENZHEN" ]; then
  target_old_windir=$(get_targetfiles_dir_SHENZHEN source_version)
  target_new_windir=$(get_targetfiles_dir_SHENZHEN dest_version)
fi

outputdir=$otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $outputdir
target_old_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/oldtarget;mkdir -p $target_old_dir
target_new_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/newtarget;mkdir -p $target_new_dir
if [ ! -d $window_out_path_17 ]; then echo "$window_out_path_17 didn't exist, ask CIE to create it on ubuntu compile server";clean_and_quit; fi
if [ ! -d $window_out_path_20 ]; then echo "$window_out_path_20 didn't exist, ask CIE to create it on ubuntu compile server";clean_and_quit; fi

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
OTA_TYPE=stable
SIGNAPK=$otabuild/tools/signapk.jar
Int_KEY=$ANDROID/build/target/product/security/testkey
Rel_KEY=/mnt/hgfs/security/testkey

priority=$(grep priority $ota_param_file | tr -s "[\r]" "[\n]" | awk -F \= '{print $2}')
description=$(join_description $ota_param_file)
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
printf "LOCATION                    %s\n" $LOCATION
printf "ANDROID                     %s\n" $ANDROID
printf "otabuild                    %s\n" $otabuild
printf "PROJECT_NAME                %s\n" $PROJECT_NAME
printf "SIGNTYPE                    %s\n" $SIGNTYPE
printf "TIME                        %s\n" $TIME
printf "ota_param_dir               %s\n" $ota_param_dir
printf "ota_param_file              %s\n" $ota_param_file
cat -n $ota_param_file
printf "\n"
printf "outputdir                   %s\n" $outputdir
printf "target_old_dir              %s\n" $target_old_dir
printf "target_new_dir              %s\n" $target_new_dir
printf "OTA_TYPE                    %s\n" $OTA_TYPE
printf "PLATFORM                    %s\n" $PLATFORM
printf "window_out_path_17          %s\n" $window_out_path_17
printf "window_out_path_20          %s\n" $window_out_path_20
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
if [ -e $ANDROID/out/dist/otatools.zip ]; then
  # if otatools.zip exits, always extract it to get all of host building tools firstly. otatools.zip is used for this purpose.
  unzip -o $ANDROID/out/dist/otatools.zip "bin/*" "framework/*" "lib64/*" -d $otabuild/linux-x86/
else
  # if otatools.zip didn't exit, copy essential file manually.
  if [ ! -d $otabuild/linux-x86 ]; then mkdir -p $otabuild/linux-x86; fi
  if [ ! -d $otabuild/linux-x86/bin ]; then mkdir $otabuild/linux-x86/bin; fi
  if [ ! -d $otabuild/linux-x86/framework ]; then mkdir $otabuild/linux-x86/framework; fi
  if [ ! -d $otabuild/linux-x86/lib64 ]; then mkdir $otabuild/linux-x86/lib64; fi
  cp -vu $ANDROID/out/host/linux-x86/bin/bsdiff                                                                    $otabuild/linux-x86/bin/
  cp -vu $ANDROID/out/host/linux-x86/bin/imgdiff                                                                   $otabuild/linux-x86/bin/
  cp -vu $ANDROID/out/host/linux-x86/framework/signapk.jar                                                         $otabuild/linux-x86/framework/
  cp -vu $ANDROID/out/host/linux-x86/lib64/libc++.so                                                               $otabuild/linux-x86/lib64/
  cp -vu $ANDROID/out/host/linux-x86/lib64/libconscrypt_openjdk_jni.so                                             $otabuild/linux-x86/lib64/
  if [ $BIGVERSION -lt 8 ]; then
    cp -vu $ANDROID/out/host/linux-x86/lib64/libdivsufsort.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort64.so $otabuild/linux-x86/lib64/
  elif [ $BIGVERSION -ge 8 ]; then
    cp -vu $ANDROID/out/host/linux-x86/bin/bro                                                                     $otabuild/linux-x86/bin/
    cp -vu $ANDROID/out/host/linux-x86/lib64/libbrotli.so                                                          $otabuild/linux-x86/lib64/
  fi
fi

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