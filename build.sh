#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Usage ---
# ./build.sh debug: Runs the app in debug mode.
# ./build.sh release [apk|appbundle|ios]: Builds the app for release.
# -----------------

MODE=$1
TYPE=$2

if [ "$MODE" == "debug" ]; then
  echo "Running app in Debug mode with config/debug.json..."
  flutter run --dart-define-from-file=config/debug.json

elif [ "$MODE" == "release" ]; then
  if [ -z "$TYPE" ]; then
    echo "Error: Release build type not specified. Use 'apk', 'appbundle', or 'ios'."
    exit 1
  fi
  echo "Building app for Release mode (type: $TYPE) with config/release.json..."
  flutter build $TYPE --dart-define-from-file=config/release.json

else
  echo "Usage: $0 [debug|release]"
  echo "  debug: Runs the app in debug mode."
  echo "  release [apk|appbundle|ios]: Builds the app for release."
  exit 1
fi

echo "Script finished successfully."
