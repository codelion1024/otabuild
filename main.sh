#!/bin/bash

TIME=`date +%y%m%d_%H%M%S`
STEP=0
echo $BUILD_TAG--步骤$(expr $STEP + 1)--编译开始

ANDROID=$1
otabuild=$ANDROID/../otabuild

source $otabuild/tools/init.sh


echo =====================开始制作整包==================
curtime=$(date +%y%m%d_%H%M)
source $otabuild/tools/makeota.sh full
echo =====================开始制作正向差分升级包==================
source $otabuild/tools/makeota.sh up
mv -v $ota_param_file $outputdir/$packfolder
python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver


tmpdir=$target_old_dir;target_old_dir=$target_new_dir;target_new_dir=$tmpdir
tmpfile=$target_old_file;target_old_file=$target_new_file;target_new_file=$tmpfile
tmpver=$old_ver;old_ver=$new_ver;new_ver=$tmpver
echo ======================开始制作逆向差分升级包=================
curtime=$(date +%y%m%d_%H%M)
source $otabuild/tools/makeota.sh down
python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver


cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path
if [ -d $otabuild ]; then rm -vr $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
if [ -d $otabuild ]; then rm -vr $otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME; fi






