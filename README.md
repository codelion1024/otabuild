1 编译环境要求:  
1.1 enca,用于对ota_parameter.txt进行编码转换  
sudo apt-get install enca  
1.2 python2.x



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

cd $ANDROID/../otabuild  
git pull --rebase origin otabuild_Int  
bash ./main.sh $ANDROID  


