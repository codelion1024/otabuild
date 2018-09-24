1 编译服务器软件环境要求:  
1.1 enca,用于对ota_parameter.txt进行编码转换  
sudo apt-get install enca  
1.2 python默认链接到的是python2.x
1.3 将活动http://10.100.13.23:8080/#/c/44843/ cherry-pick到当前项目的分支上  

  
2 hudson任务配置  
2.1 参数化构建过程  
参数 | 类型 | 取值
---|---|---
PROJECT_NAME | Choice | 机型名,eg:QK1711
SIGNTYPE | Choice | Rel或Int
ota_parameter.txt | File Parameter | 使用者上传

2.2 绑定服务器节点  
勾选Restrict where this project can be run,Label Expression设置为项目android源码所在服务器,eg:Ubu_10.99.12.11

2.3 构建  
选择Execute shell,Command为:  
ANDROID=项目android源码路径  
PROJECT_NAME=机型名  
PLATFORM=芯片平台名  
window_out_path=编译输出路径  

cd $ANDROID/../otabuild  
git pull --rebase origin otabuild_Int  
bash ./main.sh $ANDROID $PROJECT_NAME $PLATFORM $window_out_path  


3 otabuild适配新项目  
3.1 在tools/config下新增新项目的配置文件  


4 编译系统中所有文件说明  
main.sh--主控脚本,由Jenkin任务直接启动  
tools/init.sh--main.sh调用,初始化脚本,解析出所有编译所需信息  
tools/makeota.sh--main.sh调用,实现编译ota包  
tools/makeupc.py--main.sh调用,实现生成upc文件  
tools/config--所有支持机型的配置文件,里面保存一些必要的常量  
tools/linux-x86--host端生成ota包时需要用到的库和binary.  
tools/signapk.jar--用于签名ota包.  





