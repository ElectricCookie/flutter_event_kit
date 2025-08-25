# Shared Swift Code

This directory contains the shared Swift implementation for the Flutter EventKit plugin.

## Structure

- `Classes/FlutterEventKitPlugin.swift` - Main plugin implementation
- `Classes/Shared/` - Shared utility files
  - `Error.swift` - Error handling utilities
  - `EventKitService.swift` - EventKit service implementation
  - `Messages.g.swift` - Generated Pigeon messages

## Usage

To sync the shared code to both iOS and macOS platforms, run:

```bash
./scripts/sync_swift_code.sh
```

This script will:

1. Copy `FlutterEventKitPlugin.swift` to both `ios/Classes/` and `macos/Classes/`
2. Copy all files from `Classes/Shared/` to both `ios/Classes/Shared/` and `macos/Classes/Shared/`

## Workflow

1. Make changes to the Swift files in this `shared/` directory
2. Run the sync script to update both platforms
3. Build and test your changes

This approach ensures both iOS and macOS use identical implementations while avoiding symlink issues in build environments.
