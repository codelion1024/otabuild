#####1 编译服务器软件环境要求
1.1 enca,用于转换ota_parameter.txt文件(spm启动任务时上传的文件)的编码
sudo apt-get install enca
1.2 dos2unix, 用于转换ota_parameter.txt文件的换行符
sudo apt-get install dos2unix
1.3 python命令默认链接到的是python2.x
1.4 Jenkins上需要安装AnsiColor插件,用于让Jenkins任务的Console Output支持解释ANSI转义字符,输出彩色日志
https://wiki.jenkins.io/display/JENKINS/AnsiColor+Plugin

#####2 适配新项目前的准备工作
2.1 将以下活动cherry-pick到当前项目的分支上并merge
http://10.100.13.23:8080/#/c/47213/ 全包升级时根据版本编译时间决定是否清data分区
http://10.100.13.23:8080/#/c/48082/ 支持通过全量包降级升级
http://10.100.13.23:8080/#/c/48086/ 支持直接生成逆向差分升级包

http://10.100.13.23:8080/#/c/49688/ 解决system.img差异导致的OTA失败
http://10.100.13.23:8080/#/c/49717/ 解决system.img差异导致的OTA失败
http://10.100.13.23:8080/#/c/49879/ 优化out/dist下对编译结果的判断逻辑

http://10.100.13.23:8080/#/c/48050/ extra_script框架更新build下的辅助改动
http://10.100.13.23:8080/#/c/50611/ extra_script框架:recovery集成busybox工具集,更新update-script逻辑
http://10.100.13.23:8080/#/c/51335/ extra_script框架:recovery中集成toybox,并创建子命令链接
http://10.100.13.23:8080/#/c/51368/ extra_script框架:修复注释格式错误

2.2 在编译服务器上该项目的安卓源码路径 android/qiku, 在android/qiku的上一级目录clone好otabuild仓库, 即 android/otabuild,然后切到otabuild_Int分支:
git checkout -t origin/otabuild_Int

2.3  在otabuild仓库的extra_script下, 建立对应机型名的文件夹,将otabuild/extra_script/template下对应的extra脚本模板拷到此机型文件夹下.
对于android 8.0及以后的项目,基于block方式做包,因此拷贝extra_script\template\block-based\下的模板.
对于android 8.0之前的项目,基于file方式做包,因此拷贝extra_script\template\file-based\下的模板.
国内版拷贝到机型名\normal路径下,海外版拷贝到机型名\oversea路径下.
以后按软件代表的特殊需求持续更新对应的脚本即可.

#####3 hudson任务配置
######3.1 选择任务类型
创建当前项目的Jenkins任务时,首先选择任务类型为`构建一个自由风格的软件项目`

######3.2 设置 `参数化构建过程`
勾选任务配置中的`参数化构建过程`

参数 | 类型 | 取值 | 含义 |
---|---|---|
SIGNTYPE | Choice | Rel(默认), Int | ota包的签名类型,选Rel用qiku签名,选Int用google签名 |
ota_parameter.txt | File Parameter | 使用者上传 | spm启动任务时上传的文件 
check_integrity | Choice | true, false(默认) | 是否对拷贝到编译服务器的target-file.zip和刚编译生成的ota包做数据完整性检测, 服务器上检测一个target-file大概耗时1分钟 |
BIGVERSION | Choice | 7, 8(默认)  |  项目android源码的大版本号, O及之后都选8, O之前都选7 |
BUILDTYPE | Choice | RELEASE(默认), DEBUG | RELEASE用于软件代表正式做ota包,DEBUG用于调试otabuild脚本 |
autosync | Choice | true, false | 是否自动同步编译输出到17服务器 |

各参数的Description的html描述信息:
`autosync`
```http
<font size="3">
是否自动同步编译输出到17服务器<br/>
如果手动拷贝到17服务器比较快, 在需要紧急发布的情况下,可以在编译时选择不同步,编译完成后手动拷贝到17
<font>
```

######3.3 设置 `绑定服务器节点`
勾选`Restrict where this project can be run`,`Label Expression`设置为项目android源码所在服务器,eg:Ubu_10.99.12.11

######3.4 设置 `构建环境`
在`构建环境`下勾选`Color ANSI Console Output`, 之后在`ANSI color map`下选择4种颜色风格xterm,vga,css,gnome-terminal中的一种.个人推荐gnome-terminal或vga风格.
各颜色风格示例:
1 xterm
![xterm](md_pic\xterm.PNG "xterm example")
2 vga
![vga](md_pic\vga.PNG "vga example")
3 css
![css](md_pic\css.PNG "css example")
4 gnome-terminal
![gnome-terminal](md_pic\gnome-terminal.PNG "gnome-terminal example")

######3.5 设置 `构建`
选择`Execute shell`,`Command`为:
```bash
export ANDROID=项目android源码路径          # $ANDROID为编译服务器上当前项目android源码路径
export PROJECT_NAME=机型名                  # $PROJECT_NAME为机型名
export PLATFORM=芯片平台名                  # $PLATFORM为平台名
export market=国内版或海外版                # 国内版取normal, 海外版取oversea
echo "build type is $BUILDTYPE"
cd $ANDROID/../otabuild
if [ "$BUILDTYPE" == "RELEASE" ]; then
  git checkout otabuild_Int
  git checkout .
  git pull --rebase origin otabuild_Int
  export window_out_path_20=编译输出路径    # $window_out_path_20为20服务器编译生成的ota包输出路径
  export window_out_path_17=编译输出路径    # $window_out_path_17为17服务器编译生成的ota包输出路径
elif [ "$BUILDTYPE" == "DEBUG" ]; then
  git checkout otabuild_Dev
  # when debug, no need copy to 17 server,just need copy to a signle path for we debug.
  export window_out_path_20=编译输出路径
fi

bash ./main.sh
```

#####4 其他注意事项
1 西安编译服务器上的挂载点配置文件为~/bin/mount.sh,深圳编译服务器上的挂载点配置文件为 /etc/fstab
otabuild是从服务器上的挂载点配置文件中, 自动解析来得到target-files文件的挂载路径. 因此对于这两个文件,有以下要求:
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





