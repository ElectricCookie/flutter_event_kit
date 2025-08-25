#!/bin/bash

# Script to sync shared Swift code to iOS and macOS directories
# This ensures both platforms use the same implementation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Syncing Swift code from shared directory..."

# Create directories if they don't exist
mkdir -p "$PROJECT_ROOT/ios/Classes/Shared"
mkdir -p "$PROJECT_ROOT/macos/Classes/Shared"

# Copy main plugin file
echo "Copying FlutterEventKitPlugin.swift..."
cp "$PROJECT_ROOT/shared/Classes/FlutterEventKitPlugin.swift" "$PROJECT_ROOT/ios/Classes/"
cp "$PROJECT_ROOT/shared/Classes/FlutterEventKitPlugin.swift" "$PROJECT_ROOT/macos/Classes/"

# Copy shared files
echo "Copying shared files..."
cp "$PROJECT_ROOT/shared/Classes/Shared/"* "$PROJECT_ROOT/ios/Classes/Shared/"
cp "$PROJECT_ROOT/shared/Classes/Shared/"* "$PROJECT_ROOT/macos/Classes/Shared/"

echo "Swift code sync completed successfully!"
