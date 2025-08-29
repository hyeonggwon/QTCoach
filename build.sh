#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Usage ---
# ./build.sh debug [ios|android]: Runs the app on an available device for the specified platform.
# ./build.sh release [ios|android|web]: Builds the app for release.
# -----------------

MODE=$1
PLATFORM=$2

if [ "$MODE" == "debug" ]; then
  if [ -z "$PLATFORM" ]; then
    echo "Error: Platform not specified for debug mode. Use 'ios' or 'android'."
    echo "Usage: $0 debug [ios|android]"
    exit 1
  fi

  # --- 자동 기기 감지 로직 ---
  echo "Finding an available $PLATFORM device..."
  # 'flutter devices' 목록에서 해당 플랫폼의 첫 번째 기기 ID를 찾아 변수에 저장합니다.
  DEVICE_ID=$(flutter devices | grep $PLATFORM | head -n 1 | awk -F '•' '{print $2}' | xargs)

  # 기기를 찾지 못했으면 에러 메시지를 출력하고 종료합니다.
  if [ -z "$DEVICE_ID" ]; then
    echo "Error: No available $PLATFORM device found. Please connect a device or start an emulator/simulator."
    exit 1
  fi

  echo "Found device: $DEVICE_ID. Running app in Debug mode for $PLATFORM..."
  
  # 찾은 DEVICE_ID를 -d 옵션에 전달하여 앱을 실행합니다.
  flutter run -d "$DEVICE_ID" --dart-define-from-file=config/debug.json

elif [ "$MODE" == "release" ]; then
  if [ -z "$PLATFORM" ]; then
    echo "Error: Platform not specified for release mode. Use 'ios', 'android', or 'web'."
    echo "Usage: $0 release [ios|android|web]"
    exit 1
  fi
  
  echo "Building app for Release mode for $PLATFORM with config/release.json..."
  
  case $PLATFORM in
    "ios")
      echo "Building iOS release..."
      flutter build ipa --dart-define-from-file=config/release.json
      ;;
    "android")
      echo "Building Android App Bundle..."
      flutter build appbundle --dart-define-from-file=config/release.json
      ;;
    "web")
      echo "Building Web release..."
      flutter build web --dart-define-from-file=config/release.json
      ;;
    *)
      echo "Error: Invalid platform '$PLATFORM'. Use 'ios', 'android', or 'web'."
      exit 1
      ;;
  esac

else
  echo "Usage: $0 [debug|release] [ios|android|web]"
  exit 1
fi

echo "Script finished successfully."

```

### **어떻게 동작하나요?**

새로 추가된 이 한 줄의 코드가 핵심입니다.

```bash
DEVICE_ID=$(flutter devices | grep $PLATFORM | head -n 1 | awk -F '•' '{print $2}' | xargs)
