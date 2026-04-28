#!/bin/bash

# Proper clone for Windows compatibility
TARGET_DIR="/mnt/c/Users/HosiTech/lms-monorepo"
SOURCE_DIR="/home/tk/lms-prod"

# Remove existing directory
echo "Removing existing directory..."
sudo rm -rf "$TARGET_DIR"

# Create target directory with proper Windows permissions
echo "Creating target directory..."
sudo mkdir -p "$TARGET_DIR"
sudo chown -R tk:tk "$TARGET_DIR"

# Use rsync for better file handling (preserves Windows compatibility)
echo "Copying files with rsync..."
sudo rsync -av --progress --no-perms --no-owner --no-group "$SOURCE_DIR/" "$TARGET_DIR/" --exclude='.git' --exclude='node_modules' --exclude='.venv'

# Final ownership fix
echo "Setting final ownership..."
sudo chown -R tk:tk "$TARGET_DIR"

echo "Windows-compatible clone completed!"
echo "Open in VSCode: C:\\Users\\HosiTech\\lms-monorepo"