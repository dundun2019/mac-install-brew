#!/bin/bash
clear
echo "你是mac用户吗请输入y/n"
read MY_DOWN_NUM
case $MY_DOWN_NUM in
yes)
	cd ~
	git clone https://gitee.com/yao2019ss/install-brew.git
	if [ ! -d "install-brew.git" ];then
		mv install-brew.git install-brew
		cd install-brew
	fi
chmod +x install.sh
./install.sh
;;
y)
	cd ~
	git clone https://gitee.com/yao2019ss/install-brew.git
	if [ ! -d "install-brew.git" ];then
		mv install-brew.git install-brew
		cd install-brew
	fi
chmod +x install.sh
./install.sh
;;
*)
	echo 抱歉此脚本只支持mac用户Linux版正在开发
	read -p "请按任意退出"
;;
esac
exit 0
