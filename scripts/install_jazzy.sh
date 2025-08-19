#!/bin/bash
# ROS2 Jazzy installation script for Ubuntu 24.04
# Minimal installation for elfin_robot_ros2 migration

set -e  # Exit on error

echo "=== Installing ROS2 Jazzy on Ubuntu 24.04 ==="

# Setup locale
echo "Setting up locale..."
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# Setup sources
echo "Adding ROS2 apt repository..."
sudo apt install -y software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS2 Jazzy
echo "Installing ROS2 Jazzy Desktop..."
sudo apt update
sudo apt install -y ros-jazzy-desktop
sudo apt install -y ros-dev-tools

# Install elfin robot dependencies (mapped from Foxy to Jazzy)
echo "Installing elfin robot dependencies..."
# Note: Package names changed in Jazzy (gazebo -> gz, some controllers renamed)
sudo apt install -y \
  ros-jazzy-joint-trajectory-controller \
  ros-jazzy-controller-manager \
  ros-jazzy-trajectory-msgs \
  ros-jazzy-gz-ros2-control \
  ros-jazzy-gz-ros2-control-demos \
  ros-jazzy-joint-state-broadcaster \
  ros-jazzy-position-controllers \
  ros-jazzy-moveit \
  build-essential \
  libgtk-3-dev \
  python3-pip

# Install Python dependencies (using system packages for Ubuntu 24.04)
echo "Installing Python dependencies..."
sudo apt install -y python3-wxgtk4.0 python3-transforms3d

# Setup environment
echo "Setting up ROS2 environment..."
if ! grep -q "/opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

echo "=== Installation Complete ==="
echo "Please run: source ~/.bashrc"
echo "Or: source /opt/ros/jazzy/setup.bash"
echo "Then you can build the workspace with: colcon build"

# Install missing dependencies if first run failed
echo ""
echo "If you see package not found errors above, run this to install the corrected packages:"
echo "sudo apt install -y ros-jazzy-joint-trajectory-controller ros-jazzy-controller-manager ros-jazzy-trajectory-msgs ros-jazzy-gz-ros2-control ros-jazzy-gz-ros2-control-demos ros-jazzy-joint-state-broadcaster ros-jazzy-position-controllers ros-jazzy-moveit build-essential libgtk-3-dev python3-pip"