#! /usr/bin/env python
#coding=utf-8
#version 2.7

import sys
if sys.version_info > (3, 0):
  raise RuntimeError('we use Python 2.x to run this python script')
import os
import time
import zipfile
import base64
import re
import xml.etree.ElementTree as ET
import hashlib
import shutil
reload(sys)
sys.setdefaultencoding('utf-8')

def main():
  print '============开始制作upc文件============'
  diffpackpath=sys.argv[1]
  PROJECT_NAME=sys.argv[2]
  description=sys.argv[3]
  priority=sys.argv[4]
  hw_version=sys.argv[5]
  old_ver=sys.argv[6]
  new_ver=sys.argv[7]

  bindata=[]
  base64file = open(os.path.dirname(diffpackpath) + '/base64.txt', 'wb')
  base64.encode(open(diffpackpath, 'rb'),  base64file)  # 先将升级包的base64编码保存到base64.txt
  base64file.close()
  with open(os.path.dirname(diffpackpath) + '/base64.txt', 'r') as f:
    for line in f.readlines():
      bindata.append(line.strip('\n')) # base64.txt中所有行连到一起

  diffpack=zipfile.ZipFile(diffpackpath)
  scriptpath=diffpack.extract('META-INF/com/google/android/updater-script', os.path.dirname(sys.argv[1]))
  diffpack.close
  with open(scriptpath, "r") as f:
    # 先从updater-script中过滤出含有"ro.build.fingerprint"的前两行
    line = [x for x in f if x.find('ro.build.fingerprint') > 0][0:2]
    # 再从这两行中提取出升级前后的完整版本号
    old_version = re.split("[:/]", line[0])[5]
    new_version = re.split("[:/]", line[1])[5]
    print '==========debug updater-script中old_version,new_version=============='
    print(old_version)
    print(new_version)
    assert(len(old_version) > 28)
    assert(len(new_version) > 28)

  root              = ET.Element("update-package")
  creationdate      = ET.SubElement(root, "creation-date")
  creationdate.text = time.strftime('%Y/%m/%d %H:%M:%S',time.localtime(os.path.getctime(diffpackpath))) # 用getctime得到升级包的创建时间
  hw                = ET.SubElement(root, "hw")
  hw.text           = PROJECT_NAME
  hwv               = ET.SubElement(root, "hwv")
  hwv.text          = hw_version
  src_swv           = ET.SubElement(root, "src_swv")
  src_swv.text      = old_version
  dst_swv           = ET.SubElement(root, "dst_swv")
  dst_swv.text      = new_version
  des               = ET.SubElement(root, "description")
  des.text          = description
  size              = ET.SubElement(root, "size")
  size.text         = str(os.path.getsize(diffpackpath))
  prio              = ET.SubElement(root, "priority")
  prio.text         = priority
  md5               = ET.SubElement(root, "md5")
  md5.text          = hashlib.md5(open(diffpackpath, 'r').read()).hexdigest() # 得到升级包的md5
  binary            = ET.SubElement(root, "binary")
  binary.text       = "".join(bindata)
  tree              = ET.ElementTree(root)
  # 为了在保存xml文件时声明xml文件头,将xml_declaration设为true
  tree.write(os.path.dirname(diffpackpath) + '/UPC_' + PROJECT_NAME + '_' + hw_version + '_' + old_ver + '-' + new_ver + '.xml', encoding="UTF-8", xml_declaration=True)
  if os.path.exists(os.path.dirname(diffpackpath)):
    os.remove(os.path.dirname(diffpackpath) + '/base64.txt');shutil.rmtree(os.path.dirname(diffpackpath) + '/META-INF/')

  tree = ET.parse(os.path.dirname(diffpackpath) + '/UPC_' + PROJECT_NAME + '_' + hw_version + '_' + old_ver + '-' + new_ver + '.xml')
  print '============upc文件参数============'
  print(tree.getroot().find('creation-date').text)
  print(tree.getroot().find('hw').text)
  print(tree.getroot().find('hwv').text)
  print(tree.getroot().find('src_swv').text)
  print(tree.getroot().find('dst_swv').text)
  print(tree.getroot().find('description').text)
  print(tree.getroot().find('size').text)
  print(tree.getroot().find('priority').text)
  print(tree.getroot().find('md5').text)
  print '==================================='

  
if __name__ == '__main__':
  main()

