#!/bin/bash

# Generate Pigeon bindings, then sync Swift from shared/ to ios/ and macos/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Generating Pigeon code..."
dart run pigeon --input pigeons/messages.dart
echo "Pigeon code generation complete!"

echo "Syncing generated Swift from shared/ to ios/ and macos/..."
"$SCRIPT_DIR/sync_swift_code.sh"
