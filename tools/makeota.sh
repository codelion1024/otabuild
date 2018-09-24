#! /bin/bash

function prepare_extra()
{
    cat /dev/null >                             $otabuild/input/info.txt
    echo "srcver=$old_ver" >>                   $otabuild/input/info.txt
    echo "tgtver=$new_ver" >>                   $otabuild/input/info.txt
    echo "device=$PROJECT_NAME" >>              $otabuild/input/info.txt
    echo "style=$style" >>                      $otabuild/input/info.txt
    echo "SIGNTYPE=$SIGNTYPE" >>                $otabuild/input/info.txt
    echo "priority=$priority" >>                $otabuild/input/info.txt
    echo "full_bsp_modem=$full_bsp_modem" >>    $otabuild/input/info.txt
    echo "PLATFORM=$PLATFORM" >>                $otabuild/input/info.txt
    echo "hw_version=$hw_version" >>            $otabuild/input/info.txt

    cp -vf $otabuild/extra_script/${PROJECT_NAME}/extra_${style}.sh $otabuild/input/extra.sh
}

makefull()
{
  packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}
  mkdir -p $outputdir/$packfolder
  fullpack=$outputdir/$packfolder/ota_full_${new_ver}_${hw_version}_${OTA_TYPE}.zip
  fullpack_signed=$outputdir/$packfolder/ota_full_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "%s\n" "制作整包----$fullpack_signed"
  prepare_extra
  $ANDROID/build/tools/releasetools/ota_from_target_files --verbose --block --no_prereq --wipe_user_data -x pagesize=2048 --package_key $KEY -p $otabuild/linux-x86 -s $ANDROID/device/qcom/common $target_new_file $fullpack
  java -Xmx8192m -jar $SIGNAPK -w $KEY.x509.pem $KEY.pk8 $fullpack $fullpack_signed
  if [ -f $fullpack ]; then rm -v $fullpack; fi
}

makediff()
{
  if [ $full_bsp_modem = "true" ]; then
    printf "%s\n" "-------------对target_old_file去除BSPMODEM文件----------------"
    target_old_file_noradio=$target_old_dir/$(basename -s '.zip' $target_old_file)_noradio.zip
    # --copy代表复制zip文件所有内容, 用-x排除RADIO下所有bsp散件
    # 这一步默认输出的log很多,用--quiet参数消除
    zip --quiet $target_old_file --copy "*.*" --out $target_old_file_noradio -x "RADIO/*.*"
  fi

  if [ $style = "up" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}; fi
  if [ $style = "down" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}_F; fi
  mkdir -p $outputdir/$packfolder
  diffpack=$outputdir/$packfolder/ota_diff_${old_ver}_${new_ver}_${hw_version}_${OTA_TYPE}.zip
  diffpack_signed=$outputdir/$packfolder/ota_diff_${old_ver}_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "%s\n" "制作差分包----$diffpack_signed"
  prepare_extra
  if [ $full_bsp_modem = "true" ]; then
    $ANDROID/build/tools/releasetools/ota_from_target_files --verbose --block --worker_threads 8 -x pagesize=2048 --package_key $KEY -p $otabuild/linux-x86 -s $ANDROID/device/qcom/common -i $target_old_file_noradio $target_new_file $diffpack
  else
    $ANDROID/build/tools/releasetools/ota_from_target_files --verbose --block --worker_threads 8 -x pagesize=2048 --package_key $KEY -p $otabuild/linux-x86 -s $ANDROID/device/qcom/common -i $target_old_file $target_new_file $diffpack
  fi
  java -Xmx4096m -jar $SIGNAPK -w $KEY.x509.pem $KEY.pk8 $diffpack $diffpack_signed
  if [ -f $diffpack ]; then rm -v $diffpack; fi
}


style=$1
if [ $style = "full" ]; then makefull; fi
if [ $style = "up" ] || [ $style = "down" ]; then makediff; fi

