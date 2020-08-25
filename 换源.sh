#!/bin/bash
clear
echo 你需要换源[y/n]吗？可以使下载更快！
read MY_DOWN_NUM
case $MY_DOWN_NUM in
yes)
	#进入换源
;;
y)
	#进入换源
;;
*)
	echo 已为您跳过换源
	sleep 2
	read -p "按任意建进入清理下载的安装脚本等;不想清理请直接关闭窗口即可"
	cd ~
	rm -rf install-brew
	exit 0
;;
esac
cd /usr/local/Homebrew/Library/Taps/homebrew/
echo "正在检测安装进度..."
sleep 2
#克隆到本地并修改名称linux不需要
if [ ! -d "brew" ];then
	git clone --mirror https://gitee.com/yao2019ss/brew.git
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
	echo "已换源谢谢食用"
	sleep 2
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
	echo "已换源谢谢食用"
	sleep 2
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
	echo "已换源谢谢食用"
	sleep 2
;;
*)
	echo "未输入有效选项将不进行设置"
	sleep 2
;;
esac
echo "正在刷新..."
sleep 2
brew update
clear
sleep 2
read -p "按任意建进入清理下载的安装脚本等;不想清理请直接关闭窗口即可"
cd ~
rm -rf install-brew
read -p "清理完成按任意键退出"
exit 0
