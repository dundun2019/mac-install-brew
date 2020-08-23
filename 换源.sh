#!/bin/bash
clear
cd /usr/local/Homebrew/Library/Taps/homebrew/
echo "正在检测安装进度..."
sleep 2
#克隆到本地并修改名称linux不需要
if [ ! -d "brew" ];then
	git clone --mirror https://gitee.com/yao2019ss/brew.git
	cd /usr/local/Homebrew/Library/Taps/homebrew/brew.git
	git pull 
	cd /usr/local/Homebrew/Library/Taps/homebrew
	mv brew.git brew
	echo 已为您下载brew
	sleep 2
else
	echo 您已下载brew
	sleep 2	
fi
##########################################################
cd /usr/local/Homebrew/Library/Taps/homebrew
if [ ! -d "homebrew-core" ];then
	git clone --mirror https://gitee.com/yao2019ss/homebrew-core.git
	cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core.git
	git pull
	cd /usr/local/Homebrew/Library/Taps/homebrew
	mv homebrew-core.git homebrew-core
	echo 已为您下载homebrew-core
	sleep 2
else
	echo 您已下载homebrew-core
	sleep 2
fi

##########################################################
cd /usr/local/Homebrew/Library/Taps/homebrew/
if [ ! -d "homebrew-cask" ];then
	git clone --mirror https://gitee.com/yao2019ss/homebrew-cask.git
	cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask.git/
	git pull
	cd /usr/local/Homebrew/Library/Taps/homebrew
	mv homebrew-cask.git homebrew-cask
	echo 已为您下载homebrew-cask

	sleep 2
else
	echo 您已下载homebrew-cask
	sleep 2
fi
clear
#修改源
echo "输入你想使用源的序号：1.中科大（建议） 2.清华大学（较慢） 3.北外（比较快） "
read MY_DOWN_NUM
case $MY_DOWN_NUM in
1)
	echo "正在配置中科大源..."
	sleep 2
	cd "$(brew --repo)"
	sudo git remote set-url origin https://mirrors.ustc.edu.cn/brew.git
	cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
	sudo git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
	cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
	sudo git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
	echo "正在刷新..."
	sleep 2
	brew update
;;
2)
	echo "正在配置清华大学源..."
	sleep 2
	cd "$(brew --repo)"
	sudo git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
	cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
	sudo git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
	cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
	sudo git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git
	echo "正在刷新..."
	sleep 2
	brew update
;;
3)
	echo "正在配置北外源..."
	sleep 2
	cd "$(brew --repo)"
	sudo git remote set-url origin https://mirrors.bfsu.edu.cn/git/homebrew/brew.git
	cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
	sudo git remote set-url origin https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git
	cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
	git remote set-url origin https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-cask.git
	echo "正在刷新..."
	sleep 2
	brew update
;;
*)
	echo "未输入有效选项将不进行设置"
	sleep 2
;;
esac
echo "已换源谢谢食用"
sleep 2
clear
read -p "按任意退出"
exit 0