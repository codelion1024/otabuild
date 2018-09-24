#!/bin/dash

get_targetfiles_dir() {
  netpath_full=$(grep $1 $ota_param_file | awk -F \= '{print $2}' | sed 's/\\/\//g')
  while read line
  do
    netpath_prefix=$(echo $line | awk '{print $1}')
    mountpath=$(echo $line | awk '{print $2}')
    if [ "$(echo $netpath_full | grep $netpath_prefix)" != "" ]; then
      behind=$(echo "$netpath_full" | awk -F "$netpath_prefix" '{printf "%s",$2}')
      echo $mountpath$behind
      break
    fi
  done < /etc/fstab
}

join_description() {
  DES_TEXT_FILE=$otabuild/input/description.txt
  DES_LINE_RANGE=`awk '/TEXT/ {print NR}' $1`  # get the line number of "[TEXT]" and "[/TEXT]"
  DES_LINENU_BEGIN=`echo $DES_LINE_RANGE | awk -F " " '{print $1}'`
  DES_LINENU_END=`echo $DES_LINE_RANGE | awk -F " " '{print $2}'`
  if [ $DES_LINENU_END -le `expr $DES_LINENU_BEGIN + 1` ]; then printf '%b' "\033[31;1m DES_LINENU_END $DES_LINENU_END must > DES_LINENU_BEGIN $DES_LINENU_BEGIN + 1 \033[0m\n"; clean_and_quit; fi

  awk -F '\t' 'NR=='$DES_LINENU_BEGIN+1',NR=='$DES_LINENU_END-1' {print $1 " " $2}' $1 > $DES_TEXT_FILE
  while read line
  do
    des_joined=${des_joined}\\\n${line}
  done < $DES_TEXT_FILE
  echo "<![CDATA[${des_joined#*n}]]>"
}

printf '%b' "\033[32;1m $BUILD_TAG--步骤$((STEP=STEP+1))--初始化并打印所有参数 \033[0m\n"

ota_param_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $ota_param_dir
ota_param_file=$ota_param_dir/ota_parameter.txt
mv -v $WORKSPACE/ota_parameter.txt $ota_param_file
dos2unix $ota_param_file
enca -L zh_CN -x UTF-8 $ota_param_file

target_old_windir=$(get_targetfiles_dir source_version)
target_new_windir=$(get_targetfiles_dir dest_version)

outputdir=$otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME;mkdir -p $outputdir
otatools_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/linux-x86;mkdir -p $otatools_dir
target_old_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/oldtarget;mkdir -p $target_old_dir
target_new_dir=$otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME/newtarget;mkdir -p $target_new_dir
if [ ! -d $window_out_path_two ]; then printf '%b' "\033[31;1m $window_out_path_two didn't exist, ask CIE to create it on ubuntu compile server \033[0m\n";clean_and_quit; fi
if [ ! -d $window_out_path_one ]; then printf '%b' "\033[31;1m $window_out_path_one didn't exist, ask CIE to create it on ubuntu compile server \033[0m\n";clean_and_quit; fi

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
OTA_TYPE=stable
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
if [ $BIGVERSION -ge 8 ]; then
  # we make block-based OTA for new project since android O
  IS_BLOCK="--block"
elif [ $BIGVERSION -lt 8 ]; then
  IS_BLOCK=""
fi
if [ $WIPE_DATA = "true" ]; then
  IS_WIPE_USER_DATA="--wipe_user_data"
elif [ $WIPE_DATA = "false" ]; then
  IS_WIPE_USER_DATA=""
fi

printf '%b' "\033[32;1m =========================所有信息BEGIN================================== \033[0m\n"
printf "BIGVERSION                  %s\n" $BIGVERSION
printf "check_integrity             %s\n" $check_integrity
printf "BUILDTYPE                   %s\n" $BUILDTYPE
printf "autosync                    %s\n" $autosync
printf "WIPE_DATA                   %s\n" $WIPE_DATA
printf "market                      %s\n" $market
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
printf "otatools_dir                %s\n" $otatools_dir
printf "target_old_dir              %s\n" $target_old_dir
printf "target_new_dir              %s\n" $target_new_dir
printf "OTA_TYPE                    %s\n" $OTA_TYPE
printf "PLATFORM                    %s\n" $PLATFORM
printf "window_out_path_two         %s\n" $window_out_path_two
printf "window_out_path_one         %s\n" $window_out_path_one
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
printf '%b' "\033[32;1m =========================所有信息END================================== \033[0m\n"

printf '%b' "\033[32;1m =================检查ota_param_file中的source_version和dest_version下是否确实存在target-files====================== \033[0m\n"
if [ "$target_old_win" = "" ] || [ "$target_new_win" = "" ]; then
  if [ $ota_style = "fullpkg" ] && [ "$target_new_win" != "" ]; then
    printf '%b' "\033[32;1m new target-files exist, still can proceed if we only build a full OTA package \033[0m\n"
  else
    # on any other situations, we can't proceed if lack one of target-files
    printf '%b' "\033[31;1m Lack target-files!!! We can't proceed, Check if target_old_win and target_new_win is null value \033[0m\n"
    clean_and_quit
  fi
fi
printf '%b' "\033[32;1m =================将target-files从/mnt/hgfs拷贝到%s/input下====================== \033[0m\n" $otabuild
cp -vf $target_old_win $target_old_dir
if [ $check_integrity = "true" ]; then
    zip -T $target_old_file
    if [ $? != 0 ]; then
      printf '%b' "\033[31;1m $target_new_file integrity check failed after copy to compile server, stop building, disk may has bad block(s)!!! \033[0m\n"
      clean_and_quit
    else
      printf '%b' "\033[32;1m $target_new_file integrity check succeed, go on \033[0m\n"
    fi
fi

cp -vf $target_new_win $target_new_dir
if [ $check_integrity = "true" ]; then
    zip -T $target_new_file
    if [ $? != 0 ]; then
      printf '%b' "\033[31;1m $target_new_file integrity check failed after copy to compile server, stop building, disk may has bad block(s)!!! \033[0m\n"
      clean_and_quit
    else
      printf '%b' "\033[32;1m $target_new_file integrity check succeed, go on \033[0m\n"
    fi
fi

printf '%b' "\033[32;1m =================将host端工具从out拷贝到%s/linux-x86下====================== \033[0m\n" $otabuild
if [ -e $ANDROID/out/target/product/${PROJECT_NAME}/otatools.zip ]; then
  # if otatools.zip exits, always extract it to get all of host building tools firstly. otatools.zip is used for this purpose.
  unzip -o $ANDROID/out/target/product/${PROJECT_NAME}/otatools.zip "bin/*" "framework/*" "lib64/*" -d $otatools_dir
else
  # if otatools.zip didn't exit, copy essential file manually.
  if [ ! -d $otatools_dir/bin ]; then mkdir $otatools_dir/bin; fi
  if [ ! -d $otatools_dir/framework ]; then mkdir $otatools_dir/framework; fi
  if [ ! -d $otatools_dir/lib64 ]; then mkdir $otatools_dir/lib64; fi
  cp -vu $ANDROID/out/host/linux-x86/bin/bsdiff                                                                    $otatools_dir/bin/
  cp -vu $ANDROID/out/host/linux-x86/bin/imgdiff                                                                   $otatools_dir/bin/
  cp -vu $ANDROID/out/host/linux-x86/framework/signapk.jar                                                         $otatools_dir/framework/
  cp -vu $ANDROID/out/host/linux-x86/lib64/libc++.so                                                               $otatools_dir/lib64/
  cp -vu $ANDROID/out/host/linux-x86/lib64/libconscrypt_openjdk_jni.so                                             $otatools_dir/lib64/
  if [ $BIGVERSION -lt 8 ]; then
    cp -vu $ANDROID/out/host/linux-x86/lib64/libdivsufsort.so $ANDROID/out/host/linux-x86/lib64/libdivsufsort64.so $otatools_dir/lib64/
  elif [ $BIGVERSION -ge 8 ]; then
    cp -vu $ANDROID/out/host/linux-x86/bin/bro                                                                     $otatools_dir/bin/
    cp -vu $ANDROID/out/host/linux-x86/lib64/libbrotli.so                                                          $otatools_dir/lib64/
  fi
fi

