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
  packfolder=OTA_V${old_ver}_V${new_ver}_${TIME}_${OTA_TYPE}
  mkdir -p $outputdir/$packfolder
  fullpack_signed=$outputdir/$packfolder/ota_full_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "\e[32m %s \e[0m\n" "building full-package----$fullpack_signed"
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
    test_integrity $fullpack_signed
  fi
}

makediff()
{
  if [ $full_bsp_modem = "true" ]; then
    printf "\e[32m %s \e[0m\n" "-------------strip radio files from $target_old_file----------------"
    target_old_file_noradio=$target_old_dir/$(basename -s '.zip' $target_old_file)_noradio.zip
    cp -vu $target_old_file $target_old_file_noradio
    zip --verbose $target_old_file_noradio --delete "RADIO/*.*"
  fi

  if [ $style = "up" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${TIME}_${OTA_TYPE}; fi
  if [ $style = "down" ]; then packfolder=OTA_V${old_ver}_V${new_ver}_${TIME}_${OTA_TYPE}_F; fi
  mkdir -p $outputdir/$packfolder
  diffpack_signed=$outputdir/$packfolder/ota_diff_${old_ver}_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip

  printf "\e[32m %s \e[0m\n" "building diff-package----$diffpack_signed"
  prepare_extra
  if [ $full_bsp_modem = "true" ]; then
    $ANDROID/build/tools/releasetools/ota_from_target_files \
    $IS_WIPE_USER_DATA \
    $IS_BLOCK \
    --log_diff $outputdir/$packfolder/diff_${old_ver}_${new_ver}.txt \
    --verbose \
    --worker_threads $thread_nums \
    --package_key $KEY \
    --path $otatools_dir \
    --device_specific $ANDROID/device/qcom/common \
    --incremental_from $target_old_file_noradio $target_new_file $diffpack_signed
  else
    $ANDROID/build/tools/releasetools/ota_from_target_files \
    $IS_WIPE_USER_DATA \
    $IS_BLOCK \
    --log_diff $outputdir/$packfolder/diff_${old_ver}_${new_ver}.txt \
    --verbose \
    --worker_threads $thread_nums \
    --package_key $KEY \
    --path $otatools_dir \
    --device_specific $ANDROID/device/qcom/common \
    --incremental_from $target_old_file $target_new_file $diffpack_signed
  fi

  if [ $check_integrity = "true" ]; then
    test_integrity $diffpack_signed
  fi
}


style=$1
if [ $style = "full" ]; then makefull; fi
if [ $style = "up" ] || [ $style = "down" ]; then makediff; fi

