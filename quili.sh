#!/bin/bash

VERSION="240605-2104"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/quili.sh"

# 节点安装功能
function install_node() {
  # 增加swap空间
  sudo mkdir /swap
  sudo fallocate -l 24G /swap/swapfile
  sudo chmod 600 /swap/swapfile
  sudo mkswap /swap/swapfile
  sudo swapon /swap/swapfile
  echo '/swap/swapfile swap swap defaults 0 0' >> /etc/fstab
  
  # 向/etc/sysctl.conf文件追加内容
  echo -e "\n# 自定义最大接收和发送缓冲区大小" >> /etc/sysctl.conf
  echo "net.core.rmem_max=600000000" >> /etc/sysctl.conf
  echo "net.core.wmem_max=600000000" >> /etc/sysctl.conf
  
  echo "配置已添加到/etc/sysctl.conf"
  
  # 重新加载sysctl配置以应用更改
  sysctl -p
  echo "sysctl配置已重新加载"
  
  # 更新并升级Ubuntu软件包
  sudo apt update && sudo apt -y upgrade 
  
  # 安装wget、screen和git等组件
  sudo apt install git ufw bison screen binutils gcc make bsdmainutils cpulimit gawk -y
  
  # 下载并安装gvm
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  source /root/.gvm/scripts/gvm
  
  # 安装并使用go1.4作为bootstrap
  gvm install go1.4 -B
  gvm use go1.4
  export GOROOT_BOOTSTRAP=$GOROOT
  gvm install go1.17.13 -B
  gvm use go1.17.13
  export GOROOT_BOOTSTRAP=$GOROOT
  gvm install go1.20.2 -B
  gvm use go1.20.2
  
  git clone https://github.com/a3165458/ceremonyclient.git
  cd ceremonyclient/node
  git switch release
  
  # 赋予执行权限
  chmod +x release_autorun.sh
  
  # 创建一个screen会话并运行命令
  screen -dmS Quili bash -c './release_autorun.sh'
  echo "====节点安装完成===="
  
}

# 查看常规版本节点日志
function check_service_status() {
    screen -r Quili
}

# 独立启动
function run_node() {
    screen -ls | grep Detached | grep quil | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    screen -dmS Quili bash -c "source /root/.gvm/scripts/gvm && gvm use go1.20.2 && cd ~/ceremonyclient/node && ./release_autorun.sh"
    echo "====已重启节点===="
}

# 备份核心数据
function backup_set() {
mkdir -p /home/administrator/backup
cat ~/ceremonyclient/node/.config/config.yml > /home/administrator/backup/config.yml
cat ~/ceremonyclient/node/.config/keys.yml > /home/administrator/backup/keys.yml

echo "====备份完成，请执行cd ~/backup 查看备份文件===="

}

# 查询余额
function check_balance() {
cd ~/ceremonyclient/node 
GOEXPERIMENT=arenas go build -o qclient main.go
sudo cp $HOME/ceremonyclient/client/qclient /usr/local/bin
qclient token balance
echo "====余额查询完成===="
}

# 解锁性能
function unlock_performance() {
cd ~/ceremonyclient/node 
git switch release-non-datacenter
chmod +x release_autorun.sh
screen -ls | grep Detached | grep quil | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
screen -dmS Quili bash -c './release_autorun.sh'
echo "====已解锁CPU性能限制并重启===="
}

# 更新脚本
function update_script() {
    rm -rf quili.sh
    wget -O quili.sh https://raw.githubusercontent.com/at200216/quili/main/quili.sh && chmod +x quili.sh
    echo "====脚本已更新，原版本号为：${VERSION}"
}

# 主菜单
function main_menu() {
    clear
    echo "NShaw自用，简化自大赌哥脚本。"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看日志"
    echo "3. 重启节点"
    echo "4. 备份文件"
    echo "5. 查询余额"
    echo "6. 性能解锁"
    echo "7. 更新脚本"
    read -p "请输入选项（1-7）: " OPTION
    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;  
    3) run_node ;;
    4) backup_set ;;
    5) check_balance ;;
    6) unlock_performance ;;
    7) update_script ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
