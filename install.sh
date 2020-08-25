#!/bin/bash
clear
set -u
echo 请输入开机密码因为需要读写权限
# First check if the OS is Linux.
if [[ "$(uname)" = "Linux" ]]; then
  HOMEBREW_ON_LINUX=1
fi

# On macOS, this script installs to /usr/local only.
# On Linux, it installs to /home/linuxbrew/.linuxbrew if you have sudo access
# and ~/.linuxbrew otherwise.
# To install elsewhere (which is unsupported)
# you can untar https://github.com/Homebrew/brew/tarball/master
# anywhere you like.
if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
  HOMEBREW_PREFIX="/usr/local"
  HOMEBREW_REPOSITORY="/usr/local/Homebrew"
  HOMEBREW_CACHE="${HOME}/Library/Caches/Homebrew"

  STAT="stat -f"
  CHOWN="/usr/sbin/chown"
  CHGRP="/usr/bin/chgrp"
  GROUP="admin"
  TOUCH="/usr/bin/touch"
else
  HOMEBREW_PREFIX_DEFAULT="/home/linuxbrew/.linuxbrew"
  HOMEBREW_CACHE="${HOME}/.cache/Homebrew"

  STAT="stat --printf"
  CHOWN="/bin/chown"
  CHGRP="/bin/chgrp"
  GROUP="$(id -gn)"
  TOUCH="/bin/touch"
fi
BREW_REPO="https://gitee.com/todungubulahe_bilibili/brew"

# TODO: bump version when new macOS is released
MACOS_LATEST_SUPPORTED="10.15"
# TODO: bump version when new macOS is released
MACOS_OLDEST_SUPPORTED="10.13"

# For Homebrew on Linux
REQUIRED_RUBY_VERSION=2.6  # https://github.com/Homebrew/brew/pull/6556
REQUIRED_GLIBC_VERSION=2.13  # https://docs.brew.sh/Homebrew-on-Linux#requirements

# no analytics during installation
export HOMEBREW_NO_ANALYTICS_THIS_RUN=1
export HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT=1

# string formatters
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

have_sudo_access() {
  local -a args
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${args[*]-}" ]]; then
      /usr/bin/sudo "${args[@]}" -l mkdir &>/dev/null
    else
      /usr/bin/sudo -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -z "${HOMEBREW_ON_LINUX-}" ]] && [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    abort "在 macOS 上需要root（sudo）权限 (比如 将用户权限 $USER 提升为管理员权限)!"
  fi

  return "$HAVE_SUDO_ACCESS"
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

abort() {
  printf "%s\n" "$1"
  exit 1
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute_sudo() {
  local -a args=("$@")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A" "${args[@]}")
  fi
  if have_sudo_access; then
    ohai "/usr/bin/sudo" "${args[@]}"
    execute "/usr/bin/sudo" "${args[@]}"
  else
    ohai "${args[@]}"
    execute "${args[@]}"
  fi
}

getc() {
  local save_state
  save_state=$(/bin/stty -g)
  /bin/stty raw -echo
  IFS= read -r -n 1 -d '' "$@"
  /bin/stty "$save_state"
}

wait_for_user() {
  local c
  echo
  echo "请通过按“ENTER”键进入下一个安装部分"
  getc c
  # we test for \r and \n because some stuff does \r instead
  if ! [[ "$c" == $'\r' || "$c" == $'\n' ]]; then
    exit 1
  fi
}

major_minor() {
  echo "${1%%.*}.$(x="${1#*.}"; echo "${x%%.*}")"
}

if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
  macos_version="$(major_minor "$(/usr/bin/sw_vers -productVersion)")"
fi

version_gt() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -gt "${2#*.}" ]]
}
version_ge() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -ge "${2#*.}" ]]
}
version_lt() {
  [[ "${1%.*}" -lt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -lt "${2#*.}" ]]
}

should_install_git() {
  if [[ $(command -v git) ]]; then
    return 1
  fi
}

should_install_curl() {
  if [[ $(command -v curl) ]]; then
    return 1
  fi
}

should_install_command_line_tools() {
  if [[ -n "${HOMEBREW_ON_LINUX-}" ]]; then
    return 1
  fi

  if version_gt "$macos_version" "10.13"; then
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
  else
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]] ||
      ! [[ -e "/usr/include/iconv.h" ]]
  fi
}

get_permission() {
  $STAT "%A" "$1"
}

user_only_chmod() {
  [[ -d "$1" ]] && [[ "$(get_permission "$1")" != "755" ]]
}

exists_but_not_writable() {
  [[ -e "$1" ]] && ! [[ -r "$1" && -w "$1" && -x "$1" ]]
}

get_owner() {
  $STAT "%u" "$1"
}

file_not_owned() {
  [[ "$(get_owner "$1")" != "$(id -u)" ]]
}

get_group() {
  $STAT "%g" "$1"
}

file_not_grpowned() {
  [[ " $(id -G "$USER") " != *" $(get_group "$1") "*  ]]
}

# Please sync with 'test_ruby()' in 'Library/Homebrew/utils/ruby.sh' from Homebrew/brew repository.
test_ruby () {
  if [[ ! -x $1 ]]
  then
    return 1
  fi

  "$1" --enable-frozen-string-literal --disable=gems,did_you_mean,rubyopt -rrubygems -e \
    "abort if Gem::Version.new(RUBY_VERSION.to_s.dup).to_s.split('.').first(2) != \
              Gem::Version.new('$REQUIRED_RUBY_VERSION').to_s.split('.').first(2)" 2>/dev/null
}

no_usable_ruby() {
  local ruby_exec
  IFS=$'\n' # Do word splitting on new lines only
  for ruby_exec in $(which -a ruby); do
    if test_ruby "$ruby_exec"; then
      return 1
    fi
  done
  IFS=$' \t\n' # Restore IFS to its default value
  return 0
}

outdated_glibc() {
  local glibc_version
  glibc_version=$(ldd --version | head -n1 | grep -o '[0-9.]*$' | grep -o '^[0-9]\+\.[0-9]\+')
  version_lt "$glibc_version" "$REQUIRED_GLIBC_VERSION"
}

if [[ -n "${HOMEBREW_ON_LINUX-}" ]] && no_usable_ruby && outdated_glibc
then
    abort "$(cat <<-EOFABORT
	Homebrew 需要有 Ruby $REQUIRED_RUBY_VERSION 语言但在你的系统中找不到.
	Homebrew 的便携版 Ruby 需要 Glibc $REQUIRED_GLIBC_VERSION 或其更新版.
	请看 ${tty_underline}https://docs.brew.sh/Homebrew-on-Linux 的requirements（要求）部分${tty_reset}
	安装 Ruby $REQUIRED_RUBY_VERSION 然后添加你的PATH路径.
    EOFABORT
    )"
fi

# USER isn't always set so provide a fall back for the installer and subprocesses.
if [[ -z "${USER-}" ]]; then
  USER="$(chomp "$(id -un)")"
  export USER
fi

# Invalidate sudo timestamp before exiting (if it wasn't active before).
if ! /usr/bin/sudo -n -v 2>/dev/null; then
  trap '/usr/bin/sudo -k' EXIT
fi

# Things can fail later if `pwd` doesn't exist.
# Also sudo prints a warning message for no good reason
cd "/usr" || exit 1

####################################################################### script
if should_install_git; then
    abort "$(cat <<EOABORT
你必须在安装Homebrew前安装Git Homebrew. 详情请看:
  ${tty_underline}https://docs.brew.sh/Installation${tty_reset}
EOABORT
)"
fi

if should_install_curl; then
    abort "$(cat <<EOABORT
你必须在安装Homebrew前安装cURL. 详情请看:
  ${tty_underline}https://docs.brew.sh/Installation${tty_reset}
EOABORT
)"
fi

if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
 have_sudo_access
else
  if [[ -n "${CI-}" ]] || [[ -w "$HOMEBREW_PREFIX_DEFAULT" ]] || [[ -w "/home/linuxbrew" ]] || [[ -w "/home" ]]; then
    HOMEBREW_PREFIX="$HOMEBREW_PREFIX_DEFAULT"
  else
    trap exit SIGINT
    if [[ $(/usr/bin/sudo -n -l mkdir 2>&1) != *"mkdir"* ]]; then
      ohai "选定Homebrew安装目录"
      echo "- ${tty_bold}输入密码并回车${tty_reset} 去安装 去 ${tty_underline}${HOMEBREW_PREFIX_DEFAULT}${tty_reset} (${tty_bold}推荐${tty_reset})"
      echo "- ${tty_bold}同时按Control和D${tty_reset} 去安装 到 ${tty_underline}$HOME/.linuxbrew${tty_reset}"
      echo "- ${tty_bold}同时按 Control和C${tty_reset} 来停止安装"
    fi
    if have_sudo_access; then
      HOMEBREW_PREFIX="$HOMEBREW_PREFIX_DEFAULT"
    else
      HOMEBREW_PREFIX="$HOME/.linuxbrew"
    fi
    trap - SIGINT
  fi
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
fi

if [[ "$UID" == "0" ]]; then
  abort "Don't run this as root!"
elif [[ -d "$HOMEBREW_PREFIX" && ! -x "$HOMEBREW_PREFIX" ]]; then
  abort "$(cat <<EOABORT
Homebrew的前缀, ${HOMEBREW_PREFIX}, 存在但没有找到. 如果这个不是
 intentional, 请恢复为默认设置然后重新尝试运行安装程序并更改文件权限:
    sudo chmod 775 ${HOMEBREW_PREFIX}
EOABORT
)"
fi

if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
  if version_lt "$macos_version" "10.7"; then
    abort "$(cat <<EOABORT
你的Mac OS X版本太老了. 详见:
  ${tty_underline}https://gitee.com/todungubulahe_bilibili/tigerbrews${tty_reset}
EOABORT
)"
  elif version_lt "$macos_version" "10.10"; then
    abort "你的OS X版本太老了"
  elif version_gt "$macos_version" "$MACOS_LATEST_SUPPORTED" || \
    version_lt "$macos_version" "$MACOS_OLDEST_SUPPORTED"; then
    who="We"
    what=""
    if version_gt "$macos_version" "$MACOS_LATEST_SUPPORTED"; then
      what="pre-release version"
    else
      who+=" (and Apple)"
      what="太老了"
    fi
    ohai "你在使用macOS ${macos_version}."
    ohai "${who} 对这个没有提供支持 ${what}."

    echo "$(cat <<EOS
这次安装应该没有成功！之后你有可能安装软件失败.
请在github或gitee或Discourse或TwitterTwitter或IRC创建一个可靠的PR(pull requests)或去询问帮助(issues)
并附上你的安装过程 ${what}.
EOS
)
"
  fi
fi

ohai "这个脚本将会安装到这些目录:"
echo "${HOMEBREW_PREFIX}/bin/brew"
echo "${HOMEBREW_PREFIX}/share/doc/homebrew"
echo "${HOMEBREW_PREFIX}/share/man/man1/brew.1"
echo "${HOMEBREW_PREFIX}/share/zsh/site-functions/_brew"
echo "${HOMEBREW_PREFIX}/etc/bash_completion.d/brew"
echo "${HOMEBREW_REPOSITORY}"

# Keep relatively in sync with
# https://gitee.com/todungubulahe_bilibili/brew/blob/master/Library/Homebrew/keg.rb
directories=(bin etc include lib sbin share opt var
             Frameworks
             etc/bash_completion.d lib/pkgconfig
             share/aclocal share/doc share/info share/locale share/man
             share/man/man1 share/man/man2 share/man/man3 share/man/man4
             share/man/man5 share/man/man6 share/man/man7 share/man/man8
             var/log var/homebrew var/homebrew/linked
             bin/brew)
group_chmods=()
for dir in "${directories[@]}"; do
  if exists_but_not_writable "${HOMEBREW_PREFIX}/${dir}"; then
    group_chmods+=("${HOMEBREW_PREFIX}/${dir}")
  fi
done

# zsh refuses to read from these directories if group writable
directories=(share/zsh share/zsh/site-functions)
zsh_dirs=()
for dir in "${directories[@]}"; do
  zsh_dirs+=("${HOMEBREW_PREFIX}/${dir}")
done

directories=(bin etc include lib sbin share var opt
             share/zsh share/zsh/site-functions
             var/homebrew var/homebrew/linked
             Cellar Caskroom Homebrew Frameworks)
mkdirs=()
for dir in "${directories[@]}"; do
  if ! [[ -d "${HOMEBREW_PREFIX}/${dir}" ]]; then
    mkdirs+=("${HOMEBREW_PREFIX}/${dir}")
  fi
done

user_chmods=()
if [[ "${#zsh_dirs[@]}" -gt 0 ]]; then
  for dir in "${zsh_dirs[@]}"; do
    if user_only_chmod "${dir}"; then
      user_chmods+=("${dir}")
    fi
  done
fi

chmods=()
if [[ "${#group_chmods[@]}" -gt 0 ]]; then
  chmods+=("${group_chmods[@]}")
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]; then
  chmods+=("${user_chmods[@]}")
fi

chowns=()
chgrps=()
if [[ "${#chmods[@]}" -gt 0 ]]; then
  for dir in "${chmods[@]}"; do
    if file_not_owned "${dir}"; then
      chowns+=("${dir}")
    fi
    if file_not_grpowned "${dir}"; then
      chgrps+=("${dir}")
    fi
  done
fi

if [[ "${#group_chmods[@]}" -gt 0 ]]; then
  ohai "在现的有（安装）目录中（修改群组）使其可以读写:"
  printf "%s\n" "${group_chmods[@]}"
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]; then
  ohai "在现的有（安装）目录中（修改用户和群组）使其可以读写:"
  printf "%s\n" "${user_chmods[@]}"
fi
if [[ "${#chowns[@]}" -gt 0 ]]; then
  ohai "在现的有（安装）目录中（修改用户和群组）使其可以让您设置成 ${tty_underline}${USER}${tty_reset}:"
  printf "%s\n" "${chowns[@]}"
fi
if [[ "${#chgrps[@]}" -gt 0 ]]; then
  ohai "在现的有（安装）目录中（修改用户和群组）使其可以让群组设置成 ${tty_underline}${GROUP}${tty_reset}:"
  printf "%s\n" "${chgrps[@]}"
fi
if [[ "${#mkdirs[@]}" -gt 0 ]]; then
  ohai "将创建以下新目录:"
  printf "%s\n" "${mkdirs[@]}"
fi

if should_install_command_line_tools; then
  ohai "The Xcode Command Line Tools will be installed."
fi

if [[ -t 0 && -z "${CI-}" ]]; then
  wait_for_user
fi

if [[ -d "${HOMEBREW_PREFIX}" ]]; then
  if [[ "${#chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "u+rwx" "${chmods[@]}"
  fi
  if [[ "${#group_chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "g+rwx" "${group_chmods[@]}"
  fi
  if [[ "${#user_chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "755" "${user_chmods[@]}"
  fi
  if [[ "${#chowns[@]}" -gt 0 ]]; then
    execute_sudo "$CHOWN" "$USER" "${chowns[@]}"
  fi
  if [[ "${#chgrps[@]}" -gt 0 ]]; then
    execute_sudo "$CHGRP" "$GROUP" "${chgrps[@]}"
  fi
else
  execute_sudo "/bin/mkdir" "-p" "${HOMEBREW_PREFIX}"
  if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
    execute_sudo "$CHOWN" "root:wheel" "${HOMEBREW_PREFIX}"
  else
    execute_sudo "$CHOWN" "$USER:$GROUP" "${HOMEBREW_PREFIX}"
  fi
fi

if [[ "${#mkdirs[@]}" -gt 0 ]]; then
  execute_sudo "/bin/mkdir" "-p" "${mkdirs[@]}"
  execute_sudo "/bin/chmod" "g+rwx" "${mkdirs[@]}"
  execute_sudo "$CHOWN" "$USER" "${mkdirs[@]}"
  execute_sudo "$CHGRP" "$GROUP" "${mkdirs[@]}"
fi

if ! [[ -d "${HOMEBREW_CACHE}" ]]; then
  if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
    execute_sudo "/bin/mkdir" "-p" "${HOMEBREW_CACHE}"
  else
    execute "/bin/mkdir" "-p" "${HOMEBREW_CACHE}"
  fi
fi
if exists_but_not_writable "${HOMEBREW_CACHE}"; then
  execute_sudo "/bin/chmod" "g+rwx" "${HOMEBREW_CACHE}"
fi
if file_not_owned "${HOMEBREW_CACHE}"; then
  execute_sudo "$CHOWN" "$USER" "${HOMEBREW_CACHE}"
fi
if file_not_grpowned "${HOMEBREW_CACHE}"; then
  execute_sudo "$CHGRP" "$GROUP" "${HOMEBREW_CACHE}"
fi
if [[ -d "${HOMEBREW_CACHE}" ]]; then
  execute "$TOUCH" "${HOMEBREW_CACHE}/.cleaned"
fi

if should_install_command_line_tools && version_ge "$macos_version" "10.13"; then
  ohai "正在在线寻找Line Tools命令"
  # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
  clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  execute_sudo "$TOUCH" "$clt_placeholder"

  clt_label_command="/usr/sbin/softwareupdate -l |
                      grep -B 1 -E 'Command Line Tools' |
                      awk -F'*' '/^ *\\*/ {print \$2}' |
                      sed -e 's/^ *Label: //' -e 's/^ *//' |
                      sort -V |
                      tail -n1"
  clt_label="$(chomp "$(/bin/bash -c "$clt_label_command")")"

  if [[ -n "$clt_label" ]]; then
    ohai "Installing $clt_label"
    execute_sudo "/usr/sbin/softwareupdate" "-i" "$clt_label"
    execute_sudo "/bin/rm" "-f" "$clt_placeholder"
    execute_sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
  fi
fi

# Headless install may have failed, so fallback to original 'xcode-select' method
if should_install_command_line_tools && test -t 0; then
  ohai "正在安装Line Tools命令(一个GUI界面):"
  execute_sudo "/usr/bin/xcode-select" "--install"
  echo "请在安装安装完成后按任意键退出."
  getc
  execute_sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
fi

if [[ -z "${HOMEBREW_ON_LINUX-}" ]] && ! output="$(/usr/bin/xcrun clang 2>&1)" && [[ "$output" == *"license"* ]]; then
  abort "$(cat <<EOABORT
你没有同意Xcode的许可.
请在安装开始前运行
    sudo xcodebuild -license
阅读并同意许可
EOABORT
)"
fi

ohai "正在下载安装Homebrew..."
(
  cd "${HOMEBREW_REPOSITORY}" >/dev/null || return

  # we do it in four steps to avoid merge errors when reinstalling
  execute "git" "init" "-q"

  # "git remote add" will fail if the remote is defined in the global config
  execute "git" "config" "remote.origin.url" "${BREW_REPO}"
  execute "git" "config" "remote.origin.fetch" "+refs/heads/*:refs/remotes/origin/*"

  # ensure we don't munge line endings on checkout
  execute "git" "config" "core.autocrlf" "false"

  execute "git" "fetch" "origin" "--force"
  execute "git" "fetch" "origin" "--tags" "--force"

  execute "git" "reset" "--hard" "origin/master"

  execute "ln" "-sf" "${HOMEBREW_REPOSITORY}/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"

  execute "${HOMEBREW_PREFIX}/bin/brew" "update" "--force"
) || exit 1

if [[ ":${PATH}:" != *":${HOMEBREW_PREFIX}/bin:"* ]]; then
  warn "${HOMEBREW_PREFIX}/bin is not in your PATH."
fi

ohai "安装完成!"
echo

# Use the shell's audible bell.
if [[ -t 1 ]]; then
  printf "\a"
fi

# Use an extra newline and bold to avoid this being missed.
ohai "Homebrew是一个匿名者聚集一起分析的组织."
echo "$(cat <<EOS
${tty_bold}在这里可以阅读分析代码也可以退出:
  ${tty_underline}https://docs.brew.sh/Analytics${tty_reset}
没有分析已经发出的日志 (或当这些时 \`install\` run).
EOS
)
"

ohai "Homebrew完全是非盈利的. 也可以考虑捐款:"
echo "$(cat <<EOS
  ${tty_underline}https://gitee.com/todungubulahe_bilibili/brew#donations${tty_reset}
EOS
)
"

(
  cd "${HOMEBREW_REPOSITORY}" >/dev/null || return
  execute "git" "config" "--replace-all" "homebrew.analyticsmessage" "true"
  execute "git" "config" "--replace-all" "homebrew.caskanalyticsmessage" "true"
) || exit 1

ohai "下一部分:"
echo "- 执行 \`brew help\` "
echo "- 进一步获取帮助: "
echo "    ${tty_underline}https://docs.brew.sh${tty_reset}"

if [[ -n "${HOMEBREW_ON_LINUX-}" ]]; then
  case "$SHELL" in
    */bash*)
      if [[ -r "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
      else
        shell_profile="$HOME/.profile"
      fi
      ;;
    */zsh*)
      shell_profile="$HOME/.zprofile"
      ;;
    *)
      shell_profile="$HOME/.profile"
      ;;
  esac

  echo "- 安装Homebrew需要root(sudo)权限:"

  if [[ $(command -v apt-get) ]]; then
    echo "    sudo apt-get install build-essential"
  elif [[ $(command -v yum) ]]; then
    echo "    sudo yum groupinstall 'Development Tools'"
  elif [[ $(command -v pacman) ]]; then
    echo "    sudo pacman -S base-devel"
  elif [[ $(command -v apk) ]]; then
    echo "    sudo apk add build-base"
  fi

  cat <<EOS
    See ${tty_underline}https://docs.brew.sh/linux${tty_reset} for more information
- Add Homebrew to your ${tty_bold}PATH${tty_reset} in ${tty_underline}${shell_profile}${tty_reset}:
    echo 'eval \$(${HOMEBREW_PREFIX}/bin/brew shellenv)' >> ${shell_profile}
    eval \$(${HOMEBREW_PREFIX}/bin/brew shellenv)
- We recommend that you install GCC:
    brew install gcc

EOS
fi
cd ~/install-brew
chmod +x 换源.sh
sleep 2
./换源.sh
exit 0