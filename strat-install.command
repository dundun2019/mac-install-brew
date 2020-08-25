#!/bin/bash
#yao2019xm@163.com
clear
echo "尊敬的用户使用此脚本请遵守 GNU General Public License v3.0开源许可证[y/n]"
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
n)
	read -p "抱歉由于您无法遵守GNU-General-Public-License-v3.0请按任意退出"
;;
no)
	read -p "抱歉由于您无法遵守GNU-General-Public-License-v3.0请按任意退出"
;;
*)
	read -p "输入无效请重新打开此脚本"
;;
esac
exit 0
