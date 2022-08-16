#!/bin/bash
set -e
clear
    #创建用于存储相应文件（夹）的空白目录
dir1=./ddbdocker
dir2=./ddbdocker/ddb_related

if [ ! -e "$dir1" ]; 
then
    mkdir $dir1
fi

if [ ! -e "$dir2" ]; 
then
    mkdir $dir2
fi


    #输入所要下载的dolphindb版本号
read -p "Please enter your dolphindb version, the default value will be 2.00.5:" version

if [ -z "$version" ]; 
then
    version="2.00.5"
fi
    #下载压缩包
wget "https://www.dolphindb.cn/downloads/DolphinDB_Linux64_V${version}.zip"

if [ -e ./DolphinDB_Linux64_V${version}.zip ];
then
    echo -e "上传软件升级安装包成功" "\033[32m UpLoadSuccess\033[0m"
else
    echo -e "无法找到升级版本安装包，请上传至该目录" "\033[31m UpLoadFailure\033[0m"
    echo ""
    sleep 1
    exit
fi
    #解压安装包
unzip "DolphinDB_Linux64_V${version}.zip" -d "v${version}" 
if [ -d ./v${version} ];then
    echo -e "解压软件安装包成功" "\033[32m UnzipSuccess\033[0m"
else
    echo -e "解压安装包失败，请检查升级安装包是否下载完整" "\033[31m UnzipFailure\033[0m"
    echo ""
    sleep 1
    exit
fi

    #获取相应路径下的源和目标文件（夹）
source_f1=./v${version}/server/dolphindb.cfg
source_f2=./v${version}/server/dolphindb.lic
source_dir4=./v${version}/server/plugins

f1=./ddbdocker/ddb_related/dolphindb.cfg
f2=./ddbdocker/ddb_related/dolphindb.lic
dir3=./ddbdocker/data
dir4=./ddbdocker/plugins


    #编写函数对各目标路径进行遍历并通过设置条件语句来判断是否要对已有的文件进行覆盖
function isCovered() {  

for i in $*;
do
    if [ -e $i ];
    then
        #echo $i
        read -p "The $i has already existed, would you want to recover or clean it and other similar ones?(y/n)" answer
        if [ $answer=="y" ];
        then
            break
        else
            echo ""
            sleep 1
            exit
        fi
    fi
done
}

isCovered $f1 $f2 $dir3 $dir4

    #进行相应文件（夹）的拷贝
cp -rpf $source_f1 $f1
cp -rpf $source_f2 $f2

if [ -e "$dir3" ]; 
then
    rm -rf $dir3
fi

mkdir $dir3
cp -rpf $source_dir4 $dir4

    #删除下载、解压的安装包
rm -rf ./v${version}
rm -rf ./DolphinDB_Linux64_V${version}.zip