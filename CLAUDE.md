# Elfin Robot ROS2 - 项目技术规范

## 项目概述

**名称**: elfin_robot_ros2  
**类型**: 工业机器人ROS2控制系统  
**版本**: ROS2 Jazzy (Ubuntu 24.04)  
**硬件**: Elfin系列协作机器人 (3/5/10/15kg负载)  
**主分支**: `jazzy` (默认开发分支)  

## 核心架构

### 数据流
```
用户API -> MoveIt2 -> Hardware Interface -> EtherCAT Driver -> Robot Hardware
         -> Gazebo Simulation (仿真模式)
```

### 关键组件

#### 1. EtherCAT驱动层 (`elfin_ethercat_driver`)
- **职责**: 实时硬件通信
- **协议**: EtherCAT工业以太网
- **依赖**: SOEM (Simple Open EtherCAT Master)
- **实时性**: 需要PREEMPT_RT内核

#### 2. 硬件接口层 (`elfin_ros_control`)
- **职责**: ROS2 Control硬件抽象
- **接口**: position/velocity/effort控制
- **特性**: 支持仅位置控制模式

#### 3. 运动规划层 (`elfin_basic_api`)
- **职责**: 高级运动API
- **依赖**: MoveIt2运动规划框架
- **功能**: 笛卡尔/关节空间运动、碰撞检测

#### 4. 机器人描述 (`elfin_description`)
- **内容**: URDF模型、网格文件、运动学参数
- **型号**: elfin3/5/10/15及长臂版本(_l)

## 开发原则

### 1. 最小化修改原则
"这是个真问题吗？" - 只修改必要的部分
- ✅ ROS版本兼容性修改
- ❌ 代码风格优化
- ❌ 架构重构

### 2. 向后兼容原则
"Never break userspace" - 保持API稳定
- 所有话题名称不变
- 所有服务接口不变
- 所有参数名称不变

### 3. 实用主义原则
"Theory loses every time" - 解决实际问题
- 硬件通信优先级最高
- 实时性能大于代码优雅
- 稳定性大于新功能

## 工作流程

### 编译
```bash
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install
source install/setup.bash
```

### 仿真测试
```bash
# 设置Gazebo环境（重要！）
source scripts/setup_gazebo_env.sh

# 启动Gazebo仿真
ros2 launch elfin10_ros2_gazebo elfin10_gazebo.launch.py

# 或启动仿真 + MoveIt2
ros2 launch elfin5_ros2_moveit2 elfin5.launch.py

# 启动基础API
ros2 launch elfin5_ros2_moveit2 elfin5_basic_api.launch.py

# 启动控制面板
ros2 launch elfin_basic_api fake_elfin_gui.launch.py
```

### 硬件运行
```bash
# 配置网络接口（首次连接）
sudo ./scripts/setup_network.sh

# 需要实时内核和root权限
sudo chrt 10 bash
ros2 launch elfin5_ros2_moveit2 elfin5_moveit.launch.py

# 启动可视化
sudo ros2 launch elfin5_ros2_moveit2 elfin5_moveit_rviz.launch.py
```

## 关键文件

### 配置文件
- `elfin_robot_bringup/config/elfin_arm_control.yaml` - 硬件配置
- `elfin_robot_bringup/config/elfin_drivers.yaml` - 驱动参数(供应商提供)

### 脚本文件
- `scripts/setup_network.sh` - 网络接口配置脚本（连接机械臂）
- `scripts/setup_gazebo_env.sh` - Gazebo环境变量设置
- `scripts/install_jazzy.sh` - 依赖安装脚本

### 启动文件
- `*_moveit.launch.py` - 硬件控制启动
- `*_gazebo.launch.py` - 仿真环境启动
- `*_basic_api.launch.py` - API服务启动

## 注意事项

### 硬件安全
1. **上电顺序**: 先启动驱动，再使能伺服
2. **急停处理**: 保留硬件急停按钮可用
3. **关机流程**: 必须先"Servo Off"再断电

### 实时性要求
- EtherCAT通信周期: 1ms
- 控制器更新频率: 1000Hz
- 网络接口: 专用以太网口(默认eth0)

### 调试建议
1. 仿真环境验证轨迹规划
2. 检查EtherCAT连接状态
3. 监控实时性能(延迟/抖动)

## 常见问题

### Q: 编译失败
A: 运行 `./scripts/install_jazzy.sh` 安装依赖

### Q: 硬件连接失败
A: 检查网络接口名称，修改 `elfin_ethernet_name` 参数

### Q: 轨迹执行抖动
A: 确认使用PREEMPT_RT内核，提高进程优先级

### Q: Gazebo仿真中机器人倒塌
A: 确保运行 `source scripts/setup_gazebo_env.sh` 设置环境变量，gz_ros2_control插件需要正确的库路径

## 迁移记录

### Foxy -> Jazzy (2025-08-18)

#### 主要变更
1. **核心包迁移**
   - C++标准升级到C++17
   - rclcpp API更新（spin_until_future_complete添加超时参数）
   - hardware_interface API变化（read/write函数签名）
   - 修复编译错误和链接问题

2. **Gazebo迁移**
   - 从Gazebo Classic迁移到新Gazebo（Ignition）
   - 更新所有launch文件使用ros_gz_sim
   - 替换spawn_entity为create节点
   - 修复world文件的model URI

3. **gz_ros2_control集成**
   - 解决插件加载失败问题（属性顺序bug）
   - 更新控制器类型（joint_state_broadcaster）
   - 添加环境配置脚本setup_gazebo_env.sh
   - 修复机器人仿真倒塌问题

#### 统计
- 修改文件数: 57个
- 代码改动: 497 insertions(+), 235 deletions(-)
- API兼容性: 100%保持
- 测试状态: 仿真✅ 硬件待验证

## 维护者

- 原始开发: Han's Robot Co., Ltd.
- ROS2迁移: elfin_robot_ros2团队
- 当前维护: Howard

---
*"Bad programmers worry about the code. Good programmers worry about data structures."* - Linus Torvalds

本项目专注于数据流的稳定性和实时性，而非代码的优雅性。
- 各种不同类型的文件应该放在正确的文件夹, 比如文档类放在docs, 日志类放在log, 脚本类放在scripts, launch类放在launch