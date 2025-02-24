#!/bin/bash

# Stop execution on the first error
set -e

# Function to check the exit status of commands
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        exit 1
    fi
}

# Variables
KERNEL_VERSION="6.6"
OPENCLASH_URL="https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-amd64.tar.gz"
ADGUARDHOME_URL="https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz"

# 1. 添加自定义软件源
echo "Step 1: Adding custom software sources..."
mkdir -p package
cd package || exit
git clone https://github.com/cdny123/openwrt-package1.git
check_command "Cloning openwrt-package1"

# 2. 添加自定义软件包
echo "Step 2: Adding custom software packages..."
git clone https://github.com/sirpdboy/luci-app-lucky.git
check_command "Cloning luci-app-lucky"

git clone https://github.com/Jason6111/luci-app-dockerman.git
check_command "Cloning luci-app-dockerman"

# 添加自定义主题
echo "Step 3: Adding custom themes..."
git clone https://github.com/sirpdboy/luci-theme-kucat.git
check_command "Cloning luci-theme-kucat"

git clone https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom.git
check_command "Cloning luci-theme-infinityfreedom"

git clone https://github.com/jerrykuku/luci-theme-argon.git
check_command "Cloning luci-theme-argon"

# 更换固件内核为指定版本
echo "Step 4: Changing firmware kernel version..."
if [ -f "target/linux/x86/Makefile" ]; then
    sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=${KERNEL_VERSION}/g" target/linux/x86/Makefile
    check_command "Changing kernel version"
else
    echo "Error: target/linux/x86/Makefile not found."
    exit 1
fi

# 添加个性签名, 默认增加年月日
echo "Step 5: Adding custom signature..."
mkdir -p package/base-files/files/etc
echo "DISTRIB_DESCRIPTION='OpenWrt $(date +%Y-%m-%d)'" > package/base-files/files/etc/openwrt_release

# 添加默认主题为argon
echo "Step 6: Setting default theme to argon..."
mkdir -p feeds/luci/modules/luci-base/root/etc/config
echo "config luci 'main'
        option mediaurlbase '/luci-static/argon'" > feeds/luci/modules/luci-base/root/etc/config/luci

# 下载 OpenClash 和 adguardhome 的内核文件
echo "Step 7: Downloading OpenClash and AdGuardHome core files..."
mkdir -p files/etc/openclash/core
curl -L -o files/etc/openclash/core/clash ${OPENCLASH_URL}
check_command "Downloading OpenClash core"

mkdir -p files/usr/bin
curl -L -o files/usr/bin/AdGuardHome ${ADGUARDHOME_URL}
check_command "Downloading AdGuardHome"

# 修改 openwrt 后台地址为 192.168.6.1，默认子网掩码：255.255.255.0，修改主机名称为OP-NIT
echo "Step 8: Modifying OpenWrt settings..."
mkdir -p package/base-files/files/bin
echo "config_generate content" > package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
sed -i 's/255.255.255.0/255.255.255.0/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/OP-NIT/g' package/base-files/files/bin/config_generate

# 设置免密码登录
echo "Step 9: Setting passwordless login..."
mkdir -p package/base-files/files/etc
sed -i 's/root::0:0:99999:7:::/root::0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 系统和网络优化
echo "Step 10: System and network optimization..."
mkdir -p package/base-files/files/etc
echo "net.core.default_qdisc=fq" > package/base-files/files/etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> package/base-files/files/etc/sysctl.conf
echo "vm.swappiness=10" >> package/base-files/files/etc/sysctl.conf
echo "vm.min_free_kbytes=65536" >> package/base-files/files/etc/sysctl.conf

# 优化IRQ和CPU调度
echo "Step 11: Optimizing IRQ and CPU scheduling..."
echo "kernel.sched_migration_cost_ns=5000000" >> package/base-files/files/etc/sysctl.conf
echo "kernel.sched_autogroup_enabled=1" >> package/base-files/files/etc/sysctl.conf

# 更新和安装feeds
echo "Step 12: Updating and installing feeds..."
./scripts/feeds update -a
check_command "Updating feeds"

./scripts/feeds install -a
check_command "Installing feeds"

# 运行 OpenWrt 编译
echo "Step 13: Building OpenWrt image..."
make image PROFILE="generic" PACKAGES="luci luci-ssl htop iw iwinfo openssh-sftp-server openvpn-openssl wpad-openssl irqbalance schedtool usbutils lm-sensors luci-app-adguardhome luci-app-alist luci-theme-argon luci-theme-bootstrap"
check_command "Building OpenWrt image"

# 将生成的固件文件复制到 /build/output
echo "Step 14: Copying firmware files to /build/output..."
mkdir -p /build/output
cp bin/targets/x86/64/* /build/output/
check_command "Copying firmware files to /build/output"
