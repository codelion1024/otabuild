#!/bin/bash

function clean_and_quit()
{
    echo "clean input, output, and then quit"
    if [ -d $otabuild ]; then rm -vr $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    if [ -d $otabuild ]; then rm -vr $otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    exit
}

# 检测enca是否安装, 后面要用enca转换文件编码
type enca >/dev/null 2>&1 || { echo >&2 "we need enca to convert ota_param_file's encoding,using sudo apt-get install enca to install it.  Aborting."; exit 1; }

TIME=`date +%y%m%d_%H%M%S`
STEP=0
printf "%s\n" "$BUILD_TAG--步骤$((STEP++))--编译开始"

otabuild=$ANDROID/../otabuild
source $otabuild/tools/init.sh

curtime=$(date +%y%m%d_%H%M)
if [ $ota_style = "all" ] || [ $ota_style = "full" ]; then
  printf "=====================开始制作整包==================\n"
  source $otabuild/tools/makeota.sh full
fi
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "forward" ]; then
  printf "=====================开始制作正向差分升级包==================\n"
  source $otabuild/tools/makeota.sh up
  mv -v $ota_param_file $outputdir/$packfolder
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

curtime=$(date +%y%m%d_%H%M)
if [ $ota_style = "all" ] || [ $ota_style = "diff" ] || [ $ota_style = "backward" ]; then
  printf "======================开始制作逆向差分升级包=================\n"
  # 对于逆向差分升级包, 需要交换新旧target-files
  tmpdir=$target_old_dir;target_old_dir=$target_new_dir;target_new_dir=$tmpdir
  tmpfile=$target_old_file;target_old_file=$target_new_file;target_new_file=$tmpfile
  tmpver=$old_ver;old_ver=$new_ver;new_ver=$tmpver
  source $otabuild/tools/makeota.sh down
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path
clean_and_quit



