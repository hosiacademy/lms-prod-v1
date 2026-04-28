#!/bin/bash

# Clone current project to Windows location
TARGET_DIR="/mnt/c/Users/HosiTech/lms-monorepo"
SOURCE_DIR="/home/tk/lms-prod"

# Remove existing directory if it exists
echo "Removing existing directory at $TARGET_DIR..."
sudo rm -rf "$TARGET_DIR"

# Copy the entire project
echo "Cloning $SOURCE_DIR to $TARGET_DIR..."
sudo cp -r "$SOURCE_DIR/" "$TARGET_DIR/"

# Fix ownership to match Windows user
echo "Fixing file ownership..."
sudo chown -R tk:tk "$TARGET_DIR"

echo "Clone completed successfully!"
echo "Windows path: C:\\Users\\HosiTech\\lms-monorepo"
echo "WSL path: $TARGET_DIR"