#!/bin/bash
# Build script for elfin_robot_ros2 with ROS2 Jazzy

set -e

echo "=== Building elfin_robot_ros2 for ROS2 Jazzy ==="

# Check if ROS2 Jazzy is installed
if [ ! -f /opt/ros/jazzy/setup.bash ]; then
    echo "ERROR: ROS2 Jazzy not found!"
    echo "Please run ./install_jazzy.sh first to install ROS2 Jazzy"
    exit 1
fi

# Source ROS2 Jazzy
source /opt/ros/jazzy/setup.bash

# Clean previous builds if they exist
if [ -d "build" ]; then
    echo "Cleaning previous build directory..."
    rm -rf build
fi
if [ -d "install" ]; then
    echo "Cleaning previous install directory..."
    rm -rf install
fi
if [ -d "log" ]; then
    echo "Cleaning previous log directory..."
    rm -rf log
fi

# Build the workspace
echo "Building workspace..."
colcon build --symlink-install

# Check build status
if [ $? -eq 0 ]; then
    echo "=== Build Successful! ==="
    echo "To use the packages, run:"
    echo "source install/setup.bash"
else
    echo "=== Build Failed! ==="
    echo "Please check the error messages above"
    exit 1
fi