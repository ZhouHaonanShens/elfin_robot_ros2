#!/bin/bash
# Environment setup for gz_ros2_control plugin loading

# Set Gazebo plugin paths
export IGN_GAZEBO_SYSTEM_PLUGIN_PATH=/opt/ros/jazzy/lib:$IGN_GAZEBO_SYSTEM_PLUGIN_PATH
export GZ_SIM_SYSTEM_PLUGIN_PATH=/opt/ros/jazzy/lib:$GZ_SIM_SYSTEM_PLUGIN_PATH

# Set plugin loader path for gz_ros2_control
export GZ_PLUGIN_PATH=/opt/ros/jazzy/lib:$GZ_PLUGIN_PATH

# Ensure the library is accessible
export LD_LIBRARY_PATH=/opt/ros/jazzy/lib:$LD_LIBRARY_PATH

echo "Gazebo environment configured for gz_ros2_control"