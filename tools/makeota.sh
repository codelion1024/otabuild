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

    cp -vf $otabuild/extra_script/${PROJECT_NAME}/$market/extra_${style}.sh $otabuild/input/extra.sh
}

makefull()
{
  packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}
  mkdir -p $outputdir/$packfolder
  fullpack_signed=$outputdir/$packfolder/ota_full_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "\e[32m %s \e[0m\n" "制作整包----$fullpack_signed"
  prepare_extra
  $ANDROID/build/tools/releasetools/ota_from_target_files \
  $IS_WIPE_USER_DATA \
  $IS_BLOCK \
  --verbose \
  --no_prereq \
  --package_key $KEY \
  --path $otatools_dir \
  --device_specific $ANDROID/device/qcom/common \
  $target_new_file $fullpack_signed

  if [ $check_integrity = "true" ]; then
    zip -T $fullpack_signed
    if [ $? != 0 ]; then
      echo -e "\e[31m $fullpack_signed integrity check failed before copy to windows server, stop building, disk may has bad block(s)!!! \e[0m"
      clean_and_quit
    else
      echo -e "\e[32m $fullpack_signed integrity check succeed, go on \e[0m"
    fi
  fi
}

makediff()
{
  if [ $full_bsp_modem = "true" ]; then
    printf "\e[32m %s \e[0m\n" "-------------对target_old_file去除BSPMODEM文件----------------"
    target_old_file_noradio=$target_old_dir/$(basename -s '.zip' $target_old_file)_noradio.zip
    cp -vu $target_old_file $target_old_file_noradio
    zip --verbose $target_old_file_noradio --delete "RADIO/*.*"
  fi

  if [ $style = "up" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}; fi
  if [ $style = "down" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${curtime}_${OTA_TYPE}_F; fi
  mkdir -p $outputdir/$packfolder
  diffpack_signed=$outputdir/$packfolder/ota_diff_${old_ver}_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "\e[32m %s \e[0m\n" "制作差分包----$diffpack_signed"
  prepare_extra
  if [ $full_bsp_modem = "true" ]; then
    $ANDROID/build/tools/releasetools/ota_from_target_files \
    $IS_WIPE_USER_DATA \
    $IS_BLOCK \
    --verbose \
    --worker_threads 8 \
    --package_key $KEY \
    --path $otatools_dir \
    --device_specific $ANDROID/device/qcom/common \
    --incremental_from $target_old_file_noradio $target_new_file $diffpack_signed
  else
    $ANDROID/build/tools/releasetools/ota_from_target_files \
    $IS_WIPE_USER_DATA \
    $IS_BLOCK \
    --verbose \
    --worker_threads 8 \
    --package_key $KEY \
    --path $otatools_dir \
    --device_specific $ANDROID/device/qcom/common \
    --incremental_from $target_old_file $target_new_file $diffpack_signed
  fi

  if [ $check_integrity = "true" ]; then
    zip -T $diffpack_signed
    if [ $? != 0 ]; then
      echo -e "\e[31m $diffpack_signed integrity check failed before copy to windows server, stop building, disk may has bad block(s)!!! \e[0m"
      clean_and_quit
    else
      echo -e "\e[32m $diffpack_signed integrity check succeed, go on \e[0m"
    fi
  fi
}


style=$1
if [ $style = "full" ]; then makefull; fi
if [ $style = "up" ] || [ $style = "down" ]; then makediff; fi

