#!/bin/dash

clean_and_quit() {
    printf '%b' "\033[32;1m clean input, output, and then quit \033[0m\n"
    if [ -d $otabuild ]; then rm -vr $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    if [ -d $otabuild ]; then rm -vr $otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
    exit
}

# 检测dos2unix,enca是否安装, 后面要用dos2unix转换文件换行符,用enca转换文件编码
type dos2unix >/dev/null 2>&1 || { printf >&2 '%b' "\033[31;1m we need dos2unix to convert dos style line break,using sudo apt-get install dos2unix to install it. Aborting. \033[0m\n"; exit 1; }
type enca >/dev/null 2>&1 || { printf >&2 '%b' "\033[31;1m we need enca to convert ota_param_file's encoding,using sudo apt-get install enca to install it. Aborting. \033[0m\n"; exit 1; }

TIME=`date +%y%m%d_%H%M%S`
STEP=0
# set jenkins server's ip address
JENKINS_IP_XIAN=10.100.11.206
JENKINS_IP_SHENZHEN=10.100.11.23
printf "%s\n" "$BUILD_TAG--步骤$((STEP=STEP+1))--编译开始"

otabuild=$ANDROID/../otabuild
. $otabuild/portable/tools/init.sh

curtime=$(date +%y%m%d_%H%M)
# fullpkg,forward,backward均为调试选项,供内部开发使用,分别用于单独制作全包,单独制作前向差分包,后向差分包
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "fullpkg" ]; then
  printf '%b' "\033[32;1m =====================开始制作整包================== \033[0m\n"
  style=full; . $otabuild/portable/tools/makeota.sh
fi
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "forward" ]; then
  printf '%b' "\033[32;1m =====================开始制作正向差分升级包================== \033[0m\n"
  style=up; . $otabuild/portable/tools/makeota.sh
  mv -v $ota_param_file $outputdir/$packfolder
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

curtime=$(date +%y%m%d_%H%M)
if [ $ota_style = "all" ] || [ $ota_style = "diff" ] || [ $ota_style = "backward" ]; then
  printf '%b' "\033[32;1m ======================开始制作逆向差分升级包================= \033[0m\n"
  # 对于逆向差分升级包, 需要交换新旧target-files
  tmpdir=$target_old_dir;target_old_dir=$target_new_dir;target_new_dir=$tmpdir
  tmpfile=$target_old_file;target_old_file=$target_new_file;target_new_file=$tmpfile
  tmpver=$old_ver;old_ver=$new_ver;new_ver=$tmpver
  style=down; . $otabuild/portable/tools/makeota.sh
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

if [ "$window_out_path_20" != "" ]; then
  cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_20
fi
if [ "$window_out_path_17" != "" ]; then
  if [ $autosync = "true" ]; then
    printf '%b' "\033[32;1m all of ota packgages had copied to 20 server, we can get them from 20, now begin copy to 17 server \033[0m\n"
    cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_17
  elif [ $autosync = "false" ]; then
    printf '%b' "\033[32;1m you had selected don't sync building result to $window_out_path_17, you should copy them manually. \033[0m\n"
  fi
fi
clean_and_quit



