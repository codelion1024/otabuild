#####1 编译服务器软件环境要求  
1.1 enca,用于转换ota_parameter.txt文件(spm启动任务时上传的文件)的编码  
`sudo apt-get install enca`   
1.2 dos2unix, 用于转换ota_parameter.txt文件的换行符  
`sudo apt-get install dos2unix`  
1.3 python命令默认链接到的是python2.x  
1.4 Jenkins上需要安装AnsiColor插件,用于让Jenkins任务的Console  Output支持解释ANSI转义字符,输出彩色日志  
`https://wiki.jenkins.io/display/JENKINS/AnsiColor+Plugin`

#####2 适配新项目前的准备工作  
2.1 将以下活动cherry-pick到当前项目的分支上并merge  
/#/c/47213/ 全包升级时根据版本编译时间决定是否清data分区  
/#/c/48082/ 支持通过全量包降级升级   
/#/c/48086/ 支持直接生成逆向差分升级包  

/#/c/49688/ 解决system.img差异导致的OTA失败  
/#/c/49717/ 解决system.img差异导致的OTA失败  
/#/c/49879/ 优化out/dist下对编译结果的判断逻辑  

/#/c/48050/ extra_script框架更新build下的辅助改动  
/#/c/50611/ extra_script框架:recovery集成busybox工具集,更新update-script逻辑  
/#/c/51335/ extra_script框架:recovery中集成toybox,并创建子命令链接  
/#/c/51368/ extra_script框架:修复注释格式错误  

2.2 在编译服务器上该项目的安卓源码路径 android/qiku, 用以下命令在android/qiku的上一级目录clone好otabuild仓库, 同时切到otabuild_Int分支:  
```bash
android$ git clone --branch otabuild_Int ssh://{username}@10.100.13.23:29418/android/otabuild
```
其中{username}部分替换为当前服务器在gerrit上配置的用户名,西安项目通常为system1.   

2.3  在otabuild仓库的extra_script下, 建立存放对应机型国内版和海外版extra脚本路径,如extra_script\QK1807\normal和\extra_script\QK1807\oversea.  
对于android 8.0及以后的项目,基于block方式做包,因此拷贝extra_script\template\block-based\下的模板脚本文件到normal和oversea下.  
对于android 8.0之前的项目,基于file方式做包,因此拷贝extra_script\template\file-based\下的模板脚本文件到normal和oversea下.  
然后在otabuild下将刚新增的extra脚本提交到otabuild_Int和otabuild_Dev,并合入.  
以后按软件代表的特殊需求持续更新对应的脚本即可.  

#####3 hudson任务配置  
######3.1 选择任务类型
创建当前项目的Jenkins任务时,首先选择任务类型为`构建一个自由风格的软件项目`  

######3.2 设置 `参数化构建过程`
勾选任务配置中的`参数化构建过程`    

| 参数   |      类型      |  取值 | 含义 |
|----------|:-------------:|------:|:-----:|
| SIGNTYPE | Choice | Rel(默认), Int | ota包的签名类型,选Rel用qiku签名,选Int用google签名 |
| ota_parameter.txt | File Parameter |   使用者上传 | spm启动任务时上传的文件 |
| check_integrity | Choice |  true, false(默认) | 是否对拷贝到编译服务器的target-file.zip和刚编译生成的ota包做数据完整性检测, 服务器上检测一个target-file大概耗时1分钟 |
| BIGVERSION | Choice |  7, 8(默认) | 项目android源码的大版本号, O及之后都选8, O之前都选7 |
| BUILDTYPE | Choice | RELEASE(默认), DEBUG | RELEASE用于软件代表正式做ota包,DEBUG用于调试otabuild脚本 |
| autosync | Choice | true, false | 是否自动同步编译输出到17服务器 |
| WIPE_DATA | Choice | true, false | 所整包差分包都强制清除数据 |

各参数的Description的html描述信息:  
`SIGNTYPE`
```html
<font size="3">
默认Rel为正式QIKU签名，Int为google原生签名。
<font>
```
`ota_parameter.txt`
```html
<font size="3">
请上传ota_parameter.txt,内容格式如下：<br/>
source_version=\\10.99.11.20\QC8976_Test_Version\QK1607\Rel_Version\088.PX.170825.QK1607_2017.08.25-09.29\Configurations<br/>
dest_version=\\10.99.11.20\QC8976_Test_Version\QK1607\Rel_Version\090.PX.170828.QK1607_2017.08.28-16.08\Configurations<br/>
priority=Optional<br/>
ota_style=all<br/>
full_bsp_modem=false<br/>
description=1.改善XX;\n2增加XX;\n3.优化。<br/>

<br/>
各参数说明:<br/>
source_version:源版本，对前向升级包而言即低版本而言，需填入*-cota-target_files-*.zip的全路径<br/>
dest_version:目标版本，对前向升级包而言即高版本而言，需填入*-cota-target_files-*.zip的全路径<br/>
priority:差分包升级类型，Optional为普通升级包，Super为强制升级包。没填写，默认使用Optional<br/>
  
ota_style: 此次的OTA包类型，取值有all,full,diff和fullpkg,forward,backward.<br/>
all表示同时制作整包,正向差分升级包以及逆向差分升级包，full表示只制作正向差分升级包和整包，diff表示只制作逆向差分升级包<br/>
fullpkg,forward,backward为调试选项,仅用于调试脚本时填写.分别代表只制作整包,只制作正向差分升级包,只制作逆向差分升级包<br/>
不填写则默认使用all<br/>
  
full_bsp_modem:取值为true或false,含义为做差分包时是否对bsp散件做全量更新.默认为false<br/>
description:该差分包的更新说明<br/>
<font>
```
`check_integrity`
```html
<font size="3">
是否对拷贝到编译服务器的target-files.zip和刚编译生成的ota包做数据完整性检测.<br/>
服务器上检测一个target-files.zip大概耗时1分钟,检测一个整包耗时30s左右,检测一个差分包耗时几秒.<br/>
此项为true会略微增加编译时间,但可避免由于服务器磁盘坏道导致的升级包数据损坏问题.
<font>
```
`BIGVERSION`
```html
<font size="3">
项目当前所在分支源码Android大版本号
<font>
```
`BUILDTYPE`
```html
<font size="3">
release用于软件代表正式做ota包,debug用于调试otabuild脚本
<font>
```
`WIPE_DATA`
```html
<font size="3">
所有整包差分包都强制清除数据
<font>
```
`autosync`
```http
<font size="3">
是否自动同步编译输出到17服务器<br/>
如果手动拷贝到17服务器比较快, 在需要紧急发布的情况下,可以在编译时选择不同步,编译完成后手动拷贝到17
<font>
```

######3.3 设置 `绑定服务器节点`  
勾选`Restrict where this project can be run`,`Label Expression`  设置为项目android源码所在服务器,eg:Ubu_10.99.12.11  

######3.4 设置 `构建环境`  
在`构建环境`下勾选`Color ANSI Console Output`, 之后在`ANSI color map`下选择4种颜色风格xterm,vga,css,gnome-terminal中的一种.个人推荐gnome-terminal或vga风格.  
各颜色风格示例:  
1 xterm  
![xterm](.\md_pic\xterm.PNG "xterm example")  
2 vga  
![vga](.\md_pic\vga.PNG "vga example")  
3 css  
![css](.\md_pic\css.PNG "css example")  
4 gnome-terminal  
![gnome-terminal](.\md_pic\gnome-terminal.PNG "gnome-terminal example")  

######3.5 设置 `构建`  
选择`Execute shell`,`Command`为:
```bash
SHELL=script parser type    # now supported 'bash' and 'dash'. With reference https://wiki.ubuntu.com/DashAsBinSh, dash is a lite edition of bash, it launchs faster and is posix compatible.
export ANDROID=/path/to/android/source     #  eg:'/home/system1/src/1807_lc/android/qiku'
export PROJECT_NAME=project name                  # eg:'QK1807'
export PLATFORM=chipset name                  # eg:'SDM660'
export market=market place                # set 'normal' if domestic, set 'oversea' if oversea
echo "build type is $BUILDTYPE"
cd $ANDROID/../otabuild
if [ $BUILDTYPE = "RELEASE" ]; then
  git checkout otabuild_Int
  git checkout .
  git pull --rebase origin otabuild_Int
  # $window_out_path_20 stands for the upgrade package path in 20 server
  export window_out_path_20=/path/to/release/in/20server
  # $window_out_path_17 stands for the upgrade package path in 17 server
  export window_out_path_17=/path/to/release/in/17server
elif [ $BUILDTYPE = "DEBUG" ]; then
  git checkout otabuild_Dev
  # when debug, no need copy to 17 server,just need copy to a signle path for we debug.
  export window_out_path_20=/path/to/store/debug-purposed-packages
fi

if [ $SHELL = "bash" ]; then
  $SHELL ./main.sh
elif [ $SHELL = "dash" ]; then
  $SHELL ./portable/main.sh
fi
```

#####4 其他注意事项  
1 西安编译服务器上的挂载点配置文件为~/bin/mount.sh,深圳编译服务器上的挂载点配置文件为 /etc/fstab  
otabuild是从服务器上的挂载点配置文件中, 自动解析来得到target-files文件的挂载路径.   因此对于这两个文件,有以下要求:  
1.  换行符为unix风格  
2. 最好不要有无任何内容的空白行  

#####5 编译系统中所有文件说明  
main.sh--主控脚本,由Jenkin任务直接启动  
tools/init.sh--main.sh调用,初始化脚本,解析出所有编译所需信息  
tools/makeota.sh--main.sh调用,实现编译ota包  
tools/makeupc.py--main.sh调用,实现生成upc文件  
tools/config--所有支持机型的配置文件,里面保存一些必要的常量  
tools/linux-x86--host端生成ota包时需要用到的库和binary.  
tools/signapk.jar--用于签名ota包.  





