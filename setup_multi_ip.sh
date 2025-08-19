#!/bin/bash

# 多IP地址配置脚本
# 在同一网卡上同时配置DHCP（外网）和静态IP（机器人）

set -e

# 配置参数
INTERFACE="enp2s0"
ROBOT_IP="192.168.2.100/24"  # 用于连接机器人的静态IP
CONNECTION_NAME="elfin-multi-ip"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查root权限
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用sudo运行"
    echo "用法: sudo $0"
    exit 1
fi

print_info "配置多IP地址（DHCP + 静态IP）"

# 方法1：直接添加第二个IP（临时）
add_temporary_ip() {
    print_info "添加临时静态IP到现有接口..."
    
    # 添加第二个IP地址（不影响现有的DHCP地址）
    ip addr add $ROBOT_IP dev $INTERFACE 2>/dev/null || {
        print_info "IP地址可能已存在，尝试删除后重新添加..."
        ip addr del $ROBOT_IP dev $INTERFACE 2>/dev/null || true
        ip addr add $ROBOT_IP dev $INTERFACE
    }
    
    print_info "临时配置完成（重启后失效）"
}

# 方法2：创建永久配置
add_permanent_config() {
    print_info "创建永久多IP配置..."
    
    # 删除旧配置
    nmcli connection delete "$CONNECTION_NAME" 2>/dev/null || true
    
    # 创建新配置：DHCP为主，额外添加静态IP
    nmcli connection add \
        type ethernet \
        con-name "$CONNECTION_NAME" \
        ifname "$INTERFACE" \
        ipv4.method auto \
        ipv4.addresses "$ROBOT_IP" \
        ipv6.method auto \
        connection.autoconnect yes \
        connection.autoconnect-priority 100
    
    # 说明：
    # ipv4.method auto - 使用DHCP获取主IP
    # ipv4.addresses - 额外添加静态IP
    # 这样会同时拥有DHCP分配的IP和静态IP
    
    print_info "激活永久配置..."
    nmcli connection up "$CONNECTION_NAME"
    
    print_info "永久配置完成（重启后自动生效）"
}

# 显示当前状态
show_status() {
    print_info "当前网络状态："
    echo ""
    echo "=== 所有IP地址 ==="
    ip addr show $INTERFACE | grep "inet " | while read line; do
        echo "  $line"
    done
    echo ""
    
    # 测试连通性
    print_info "测试连通性："
    
    # 测试外网
    echo -n "  外网(8.8.8.8): "
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    # 测试机器人
    echo -n "  机器人(192.168.2.1): "
    if ping -c 1 -W 2 192.168.2.1 > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ 无响应（可能未开机或不响应ping）${NC}"
    fi
    
    # 测试本地路由器
    GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)
    if [ -n "$GATEWAY" ]; then
        echo -n "  网关($GATEWAY): "
        if ping -c 1 -W 2 $GATEWAY > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    fi
}

# 主菜单
main() {
    echo "========================================="
    echo "    多IP地址配置工具"
    echo "========================================="
    echo ""
    echo "选择配置方式："
    echo "  1) 临时配置（立即生效，重启失效）"
    echo "  2) 永久配置（重启后自动生效）"
    echo "  3) 两者都配置"
    echo ""
    read -p "请选择 (1/2/3): " choice
    
    case $choice in
        1)
            add_temporary_ip
            ;;
        2)
            add_permanent_config
            ;;
        3)
            add_temporary_ip
            echo ""
            add_permanent_config
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac
    
    echo ""
    show_status
    
    echo ""
    print_info "配置完成！"
    echo ""
    echo "现在你可以："
    echo "  • 访问外网（通过DHCP获取的IP）"
    echo "  • 访问机器人（通过192.168.2.100）"
    echo ""
    echo "管理命令："
    echo "  查看所有IP: ip addr show $INTERFACE"
    echo "  查看连接: nmcli connection show"
    echo "  切换连接: nmcli connection up <connection-name>"
}

# 运行主函数
main