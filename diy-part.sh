#!/bin/bash
# 1. 添加自定义软件源
cd package
git clone https://github.com/cdny123/openwrt-package1.git

# 2. 添加自定义软件包
git clone https://github.com/sirpdboy/luci-app-lucky.git
git clone https://github.com/lq-wq/luci-app-autoupdate.git
git clone https://github.com/Jason6111/luci-app-dockerman.git

# 添加自定义主题
git clone https://github.com/sirpdboy/luci-theme-kucat.git
git clone https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom.git
git clone https://github.com/jerrykuku/luci-theme-argon.git

# 更换固件内核为6.6
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile

# 添加个性签名, 默认增加年月日
mkdir -p package/base-files/files/etc
echo "DISTRIB_DESCRIPTION='OpenWrt $(date +%Y-%m-%d)'" > package/base-files/files/etc/openwrt_release

# 添加默认主题为argon
mkdir -p feeds/luci/modules/luci-base/root/etc/config
echo "config luci 'main'
        option mediaurlbase '/luci-static/argon'" > feeds/luci/modules/luci-base/root/etc/config/luci

# 下载 OpenClash 和 adguardhome 的内核文件
mkdir -p files/etc/openclash/core
curl -L -o files/etc/openclash/core/clash https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-amd64.tar.gz

mkdir -p files/usr/bin
curl -L -o files/usr/bin/AdGuardHome https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz

# 修改 openwrt 后台地址为 192.168.6.1，默认子网掩码：255.255.255.0，修改主机名称为OP-NIT
mkdir -p package/base-files/files/bin
echo "config_generate content" > package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
sed -i 's/255.255.255.0/255.255.255.0/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/OP-NIT/g' package/base-files/files/bin/config_generate

# 设置免密码登录
mkdir -p package/base-files/files/etc
sed -i 's/root::0:0:99999:7:::/root::0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 系统和网络优化
mkdir -p package/base-files/files/etc
echo "net.core.default_qdisc=fq" > package/base-files/files/etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> package/base-files/files/etc/sysctl.conf
echo "vm.swappiness=10" >> package/base-files/files/etc/sysctl.conf
echo "vm.min_free_kbytes=65536" >> package/base-files/files/etc/sysctl.conf

# 优化IRQ和CPU调度
echo "kernel.sched_migration_cost_ns=5000000" >> package/base-files/files/etc/sysctl.conf
echo "kernel.sched_autogroup_enabled=1" >> package/base-files/files/etc/sysctl.conf

# 更新和安装feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 运行 OpenWrt 编译
make image PROFILE="generic" PACKAGES="luci luci-ssl htop iw iwinfo openssh-sftp-server openvpn-openssl wpad-openssl irqbalance schedtool usbutils lm-sensors luci-app-adguardhome luci-app-alist luci-app-ddns luci-app-diskman luci-app-ksmbd luci-app-openclash luci-app-poweroff luci-app-store luci-app-upnp luci-app-dockerman luci-app-autoupdate" FILES="files/"

# 将生成的固件文件复制到 /build/output
mkdir -p /build/output
cp bin/targets/x86/64/* /build/output/
