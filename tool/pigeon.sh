#!/bin/bash

# Build script for Pigeon code generation
# Run this script to generate the necessary code files

echo "Generating Pigeon code..."

# Generate Dart and Swift code from Pigeon definitions
dart run pigeon --input pigeons/messages.dart

echo "Pigeon code generation complete!"

cp ./ios/Classes/Shared/Messages.g.swift ./macos/Classes/Shared/Messages.g.swift