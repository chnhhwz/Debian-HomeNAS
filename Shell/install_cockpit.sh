#!/bin/bash

# 配置45Drives Repo安装脚本（用于安装Navigator、File Sharing、Identities组件）
curl -sSL https://repo.45drives.com/setup | bash
apt update

# 获取系统版本代号
os_codename=$(awk -F= '/VERSION_CODENAME/{print $2}' /etc/os-release)

# 安装Cockpit及其附属组件（Navigator、File Sharing、Identities组件）
apt install -y -t "$os_codename-backports" cockpit cockpit-pcp
apt install -y cockpit-navigator cockpit-file-sharing cockpit-identities

# 询问是否安装cockpit-machines
read -p "是否安装虚拟机组件？(y/n): " install_machines

if [[ $install_machines == "y" ]]; then
    # 安装 cockpit-machines 组件
    apt install -y -t "$os_codename-backports" cockpit-machines

    # 开启IP包转发功能
    echo "开启IP包转发功能..."
    sysctl_conf="/etc/sysctl.conf"
    if grep -qE "^#?net.ipv4.ip_forward=1" "$sysctl_conf"; then
        sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' "$sysctl_conf"
    else
        echo "net.ipv4.ip_forward=1" >> "$sysctl_conf"
    fi
    sysctl -p
    echo "已安装虚拟机组件。"
else
    echo "已跳过虚拟机组件安装。"
fi

# 配置首页展示信息
cat <<EOF > /etc/motd
我们信任您已经从系统管理员那里了解了日常注意事项。总结起来无外乎这三点：
1、尊重别人的隐私。
2、输入前要先考虑(后果和风险)。
3、权力越大，责任越大。
EOF

# 安装Tuned系统调优工具
apt install -y tuned

# Cockpit调优，设置自动注销闲置及Nginx反向代理Cockpit操作
cockpit_conf="/etc/cockpit/cockpit.conf"
if [[ ! -f "$cockpit_conf" ]]; then
    mkdir -p /etc/cockpit
    cat <<EOF > "$cockpit_conf"
[Session]
IdleTimeout=15
Banner=/etc/cockpit/issue.cockpit

[WebService]
ProtocolHeader = X-Forwarded-Proto
ForwardedForHeader = X-Forwarded-For
LoginTo = false
LoginTitle = HomeNAS
EOF
fi

# 检查 /etc/cockpit/issue.cockpit 配置文件是否存在，不存在则创建
issue_file="/etc/cockpit/issue.cockpit"
[[ ! -f "$issue_file" ]] && echo "基于Debian搭建HomeNAS！" > "$issue_file"

# 检查是否需要设置Cockpit外网访问
read -p "是否设置Cockpit外网访问？(y/n): " response
config_file="/etc/cockpit/cockpit.conf"
if [[ -z "$response" || "$response" == "n" ]]; then
    # 用户不做回应或者回答n
    if [[ -f "$config_file" ]]; then
        if grep -q "Origins" "$config_file"; then
            # 删除Origins参数行
            sed -i '/Origins/d' "$config_file"
            echo "已跳过Cockpit外网访问配置，并删除对应外网访问参数。"
        else
            echo "已跳过Cockpit外网访问配置，且检查没有配置外网访问参数。"
        fi
    else
        echo "已跳过Cockpit外网访问配置。"
    fi
else
    # 提示用户输入外网访问域名
    read -p "请输入Cockpit外网访问地址（如有端口号需一并输入）： " domain

    # 移除输入中的协议部分
    domain=$(echo "$domain" | sed -E 's#^https?://##')

    # 提取当前主机内网IP地址
    internal_ip=$(hostname -I | awk '{print $1}')
    # 配置Cockpit的Origins参数
    if [[ -f "$config_file" ]]; then
        if grep -q "Origins" "$config_file"; then
            sed -i "s#^Origins = .*#Origins = https://$domain wss://$domain https://$internal_ip:9090#" "$config_file"
        else
            sed -i "/\[WebService\]/a Origins = https://$domain wss://$domain https://$internal_ip:9090" "$config_file"
        fi
    else
        echo "[WebService]" > "$config_file"
        echo "Origins = https://$domain wss://$domain https://$internal_ip:9090" >> "$config_file"
    fi
    echo "已设置Cockpit外网访问域名：https://$domain"
fi

echo "Cockpit调优配置完成。"

# 设置Cockpit接管网络配置（网络管理工具由network改为NetworkManager）
interfaces_file="/etc/network/interfaces"
if [[ -f "$interfaces_file" ]]; then
    sed -i '/^[^#]/ s/^/#/' "$interfaces_file"
else
    echo "文件 '$interfaces_file' 不存在，跳过操作。"
fi

# 重启Network Manager服务
systemctl restart NetworkManager && echo "已重启 Network Manager 服务。"

# 重启cockpit服务
systemctl try-restart cockpit
