#!/bin/bash

# Script to sync shared Swift code to iOS and macOS directories
# This ensures both platforms use the same implementation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Syncing Swift code from shared directory..."

# Swift Package Manager source directories. CocoaPods reads the same files.
IOS_DEST="$PROJECT_ROOT/ios/flutter_event_kit/Sources/flutter_event_kit"
MACOS_DEST="$PROJECT_ROOT/macos/flutter_event_kit/Sources/flutter_event_kit"

mkdir -p "$IOS_DEST/Shared"
mkdir -p "$MACOS_DEST/Shared"

# Copy main plugin file
echo "Copying FlutterEventKitPlugin.swift..."
cp "$PROJECT_ROOT/shared/Classes/FlutterEventKitPlugin.swift" "$IOS_DEST/"
cp "$PROJECT_ROOT/shared/Classes/FlutterEventKitPlugin.swift" "$MACOS_DEST/"

# Copy shared files
echo "Copying shared files..."
cp "$PROJECT_ROOT/shared/Classes/Shared/"* "$IOS_DEST/Shared/"
cp "$PROJECT_ROOT/shared/Classes/Shared/"* "$MACOS_DEST/Shared/"

echo "Swift code sync completed successfully!"
