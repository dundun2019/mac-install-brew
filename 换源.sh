cd /usr/local/Homebrew/Library/Taps/homebrew/
#克隆到本地并修改名称linux不需要
if [ ! -d "brew" ];then
git clone --mirror https://gitee.com/yao2019ss/brew.git
cd /usr/local/Homebrew/Library/Taps/homebrew/brew.git
git pull 
cd /usr/local/Homebrew/Library/Taps/homebrew
mv brew.git brew
fi
##########################################################
cd /usr/local/Homebrew/Library/Taps/homebrew
if [ ! -d "homebrew-core" ];then
git clone --mirror https://gitee.com/yao2019ss/homebrew-core.git
cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core.git
git pull
cd /usr/local/Homebrew/Library/Taps/homebrew
mv homebrew-core.git homebrew-core
fi
##########################################################
cd /usr/local/Homebrew/Library/Taps/homebrew/
if [ ! -d "homebrew-cask" ];then
git clone --mirror https://gitee.com/yao2019ss/homebrew-cask.git
cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask.git/
git pull
cd /usr/local/Homebrew/Library/Taps/homebrew
mv homebrew-cask.git homebrew-cask
fi
#修改源
echo "输入你想使用源的序号：1.中科大 2.清华大学 3.本地(git 仓库比较慢) "
read MY_DOWN_NUM
case $MY_DOWN_NUM in
1)
	echo "正在配置中科大源..."
	sleep 1
	cd "$(brew --repo)"
	sudo git remote set-url origin https://mirrors.ustc.edu.cn/brew.git
	cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
	sudo git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
	cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
	git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
	brew update
;;
*)
	echo "未输入有效选项将按照不进行设置"
	exit 0
esac