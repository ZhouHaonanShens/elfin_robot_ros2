#!/bin/bash

# Elfin Robot Network Configuration Script
# 用于配置网络接口连接Elfin机械臂

set -e

# 配置参数
INTERFACE="enp2s0"
ROBOT_IP="192.168.2.1"
HOST_IP="192.168.2.100"
NETMASK="255.255.255.0"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}请使用sudo权限运行此脚本${NC}"
        echo "用法: sudo $0"
        exit 1
    fi
}

# 打印信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 清理旧配置
cleanup_old_config() {
    print_info "清理网络接口 $INTERFACE 的旧配置..."
    
    # 关闭接口
    ip link set $INTERFACE down 2>/dev/null || true
    
    # 清除所有IP地址
    ip addr flush dev $INTERFACE 2>/dev/null || true
    
    # 清除相关路由
    ip route flush dev $INTERFACE 2>/dev/null || true
    
    # 清理ARP缓存
    ip neigh flush dev $INTERFACE 2>/dev/null || true
    
    print_info "旧配置已清理"
}

# 配置网络接口
configure_network() {
    print_info "配置网络接口 $INTERFACE..."
    
    # 启用接口
    ip link set $INTERFACE up
    
    # 设置IP地址
    ip addr add ${HOST_IP}/24 dev $INTERFACE
    
    # 设置混杂模式（EtherCAT需要）
    ip link set $INTERFACE promisc on
    
    # 添加到机械臂的直连路由
    ip route add $ROBOT_IP dev $INTERFACE 2>/dev/null || true
    
    print_info "网络配置完成："
    echo "  接口: $INTERFACE"
    echo "  主机IP: $HOST_IP"
    echo "  机械臂IP: $ROBOT_IP"
}

# 测试连接
test_connection() {
    print_info "测试与机械臂的连接..."
    
    # 等待接口稳定
    sleep 2
    
    # ARP探测
    arping -c 2 -I $INTERFACE $ROBOT_IP 2>/dev/null || true
    
    # Ping测试
    if ping -c 2 -W 2 -I $INTERFACE $ROBOT_IP > /dev/null 2>&1; then
        print_info "✓ Ping测试成功"
    else
        print_warning "Ping测试失败（某些机械臂不响应ICMP）"
    fi
    
    # 检查ARP表
    if ip neigh show | grep -q "$ROBOT_IP.*$INTERFACE"; then
        print_info "✓ 机械臂MAC地址已发现"
        ip neigh show | grep "$ROBOT_IP.*$INTERFACE"
    else
        print_warning "未在ARP表中发现机械臂"
    fi
}

# 检查EtherCAT连接（如果有工具）
check_ethercat() {
    SLAVEINFO="/home/howard/HowardProjects/elfin_robot_ros2/build/soem_ros2/SOEM/test/linux/slaveinfo/slaveinfo"
    
    if [ -f "$SLAVEINFO" ]; then
        print_info "扫描EtherCAT从站..."
        $SLAVEINFO $INTERFACE || true
    fi
}

# 显示最终配置
show_config() {
    print_info "当前网络配置："
    echo ""
    echo "接口信息："
    ip addr show $INTERFACE
    echo ""
    echo "路由表："
    ip route | grep $INTERFACE || echo "  无相关路由"
    echo ""
    echo "ARP表："
    ip neigh show | grep $INTERFACE || echo "  无ARP记录"
}

# 创建持久化配置（可选）
create_persistent_config() {
    print_info "是否创建持久化配置？(y/n)"
    read -r response
    
    if [[ "$response" == "y" ]]; then
        # 创建NetworkManager连接配置
        nmcli con delete "elfin-robot" 2>/dev/null || true
        nmcli con add type ethernet con-name "elfin-robot" ifname $INTERFACE \
            ipv4.method manual \
            ipv4.addresses ${HOST_IP}/24 \
            ipv4.gateway "" \
            ipv4.dns "" \
            ipv6.method ignore \
            connection.autoconnect no
        
        print_info "持久化配置已创建（名称：elfin-robot）"
        echo "启用: nmcli con up elfin-robot"
        echo "禁用: nmcli con down elfin-robot"
    fi
}

# 主函数
main() {
    echo "========================================="
    echo "    Elfin Robot 网络配置工具"
    echo "========================================="
    echo ""
    
    check_root
    cleanup_old_config
    configure_network
    test_connection
    check_ethercat
    echo ""
    show_config
    echo ""
    create_persistent_config
    
    echo ""
    print_info "配置完成！"
    echo ""
    echo "下一步："
    echo "1. 确保机械臂已上电并使能"
    echo "2. 运行ROS2启动命令："
    echo "   source /opt/ros/jazzy/setup.bash"
    echo "   source install/setup.bash"
    echo "   ros2 launch elfin10_ros2_moveit2 elfin10_moveit.launch.py"
}

# 运行主函数
main