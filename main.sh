#!/bin/bash

function clean_and_quit()
{
    echo -e "\e[32m clean input, output, and then quit \e[0m"
    if [ -d $otabuild ]; then rm -vr $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    if [ -d $otabuild ]; then rm -vr $otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    exit
}

# 检测dos2unix,enca是否安装, 后面要用dos2unix转换文件换行符,用enca转换文件编码
type dos2unix >/dev/null 2>&1 || { echo -e >&2 "\e[31m we need dos2unix to convert dos style line break,using sudo apt-get install dos2unix to install it. Aborting. \e[0m"; exit 1; }
type enca >/dev/null 2>&1 || { echo -e >&2 "\e[31m we need enca to convert ota_param_file's encoding,using sudo apt-get install enca to install it. Aborting. \e[0m"; exit 1; }

TIME=`date +%y%m%d_%H%M%S`
STEP=0
# set jenkins server's ip address
JENKINS_IP_XIAN=10.100.11.206
JENKINS_IP_SHENZHEN=10.100.11.23
printf "%s\n" "$BUILD_TAG--步骤$((STEP++))--编译开始"

otabuild=$ANDROID/../otabuild
source $otabuild/tools/init.sh

curtime=$(date +%y%m%d_%H%M)
# fullpkg,forward,backward均为调试选项,供内部开发使用,分别用于单独制作全包,单独制作前向差分包,后向差分包
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "fullpkg" ]; then
  printf "\e[32m =====================开始制作整包================== \e[0m\n"
  source $otabuild/tools/makeota.sh full
fi
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "forward" ]; then
  printf "\e[32m =====================开始制作正向差分升级包================== \e[0m\n"
  source $otabuild/tools/makeota.sh up
  mv -v $ota_param_file $outputdir/$packfolder
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

curtime=$(date +%y%m%d_%H%M)
if [ $ota_style = "all" ] || [ $ota_style = "diff" ] || [ $ota_style = "backward" ]; then
  printf "\e[32m ======================开始制作逆向差分升级包================= \e[0m\n"
  # 对于逆向差分升级包, 需要交换新旧target-files
  tmpdir=$target_old_dir;target_old_dir=$target_new_dir;target_new_dir=$tmpdir
  tmpfile=$target_old_file;target_old_file=$target_new_file;target_new_file=$tmpfile
  tmpver=$old_ver;old_ver=$new_ver;new_ver=$tmpver
  source $otabuild/tools/makeota.sh down
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

if [ "$window_out_path_20" != "" ]; then
  cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_20
fi
if [ "$window_out_path_17" != "" ]; then
  if [ $autosync == "true" ]; then
    echo -e "\e[32m all of ota packgages had copied to 20 server, we can get them from 20, now begin copy to 17 server \e[0m"
    cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_17
  elif [ $autosync == "false" ]; then
    echo -e "\e[32m you had selected don't sync building result to $window_out_path_17, you should copy them manually. \e[0m"
  fi
fi
clean_and_quit



