#!/bin/bash
clear
echo "你是mac用户吗请输入y/n"
read MY_DOWN_NUM
case $MY_DOWN_NUM in
y/yes)
	cd ~
	git clone https://gitee.com/yao2019ss/install-brew.git
	if [ ! -d "install-brew.git" ];then
		cd install-brew.git
	else
		cd install-brew
	fi
chmod +x install.sh
./install.sh
exit0