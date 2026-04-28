#!/bin/bash

# Proper clone to Windows using the correct approach
TARGET_DIR="/mnt/c/Users/HosiTech/lms-monorepo"
SOURCE_DIR="/home/tk/lms-prod"

echo "Warning: /mnt/c/ appears to be a Linux filesystem, not actual Windows NTFS"
echo "Files copied here may not be visible to Windows applications like VSCode"
echo ""
echo "For proper Windows visibility, you should:"
echo "1. Use WSL's built-in file access: \\wsl$\\Ubuntu\\home\\tk\\lms-prod"
echo "2. Or use git to push/pull between repositories"
echo "3. Or use Windows File Explorer to copy files directly"
echo ""
echo "Current approach (copying to /mnt/c/):"

# Remove existing directory
echo "Removing existing directory..."
sudo rm -rf "$TARGET_DIR"

# Copy files
echo "Copying files..."
sudo cp -r "$SOURCE_DIR/" "$TARGET_DIR/"

# Fix ownership
echo "Fixing ownership..."
sudo chown -R tk:tk "$TARGET_DIR"

echo ""
echo "Files copied to: $TARGET_DIR"
echo "Windows path: C:\\Users\\HosiTech\\lms-monorepo"
echo "Note: These files may not be visible in Windows applications due to filesystem differences"