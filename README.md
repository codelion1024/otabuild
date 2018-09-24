###1 编译服务器软件环境要求:  
1.1 enca,用于对ota_parameter.txt进行编码转换  
sudo apt-get install enca  
1.2 python默认链接到的是python2.x


###2 适配新项目前的准备工作  

2.1 在tools/config下新增新项目的配置文件  
2.2 将以下活动cherry-pick到当前项目的分支上  
http://10.100.13.23:8080/#/c/47213/  
http://10.100.13.23:8080/#/c/46178/  

###3 hudson任务配置  
####3.1 设置  参数化构建过程   
参数 | 类型 | 取值
---|---|---
SIGNTYPE | Choice | Rel或Int
ota_parameter.txt | File Parameter | 使用者上传
check_integrity | Choice | 选true会增加target-file zip包数据完整性检测, 服务器上检测一个target-file大概耗时1分钟

####3.2 设置  绑定服务器节点    
勾选Restrict where this project can be run,Label Expression设置为项目android源码所在服务器,eg:Ubu_10.99.12.11

####3.3 设置  构建  
选择Execute shell,Command为:  
```bash
export ANDROID=项目android源码路径       # $ANDROID为编译服务器上当前项目android源码路径  
export PROJECT_NAME=机型名	                  # $PROJECT_NAME为机型名  
export PLATFORM=芯片平台名				# $PLATFORM为平台名  
export window_out_path=编译输出路径	# $window_out_path为编译生成的ota包输出路径  

cd $ANDROID/../otabuild  
git pull --rebase origin otabuild_Int  
bash ./main.sh $ANDROID $PROJECT_NAME $PLATFORM $window_out_path  
```








###4 编译系统中所有文件说明  
main.sh--主控脚本,由Jenkin任务直接启动  
tools/init.sh--main.sh调用,初始化脚本,解析出所有编译所需信息  
tools/makeota.sh--main.sh调用,实现编译ota包  
tools/makeupc.py--main.sh调用,实现生成upc文件  
tools/config--所有支持机型的配置文件,里面保存一些必要的常量  
tools/linux-x86--host端生成ota包时需要用到的库和binary.  
tools/signapk.jar--用于签名ota包.  





