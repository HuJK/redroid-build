#!/bin/bash
set -e

# Example configuration for redroid build
# Targeted version: Android 14
# Features: GApps (MindTheGapps), Root(none, magisk), Translation(houdini, ndk), Widevine(0,1)

# Environment Overrides
export ANDROID_VAR="android-16.0.0_r2"
export AYASA520_GAPPS="litegapps"
export DOCKER_USERNAME=whojk
export REDROID_LUNCH="redroid_x86_64-ap2a-userdebug"

# Enable Docker Push
export PUSH_IMAGE=1

# Ensure we are in the script's directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Build matrix
ROOT_OPTIONS=("" "magisk")
TRANSLATION_OPTIONS=("houdini" "")
WIDEVINE_OPTIONS=("0")

for WIDEVINE in "${WIDEVINE_OPTIONS[@]}"; do
  export AYASA520_WADEVINE="$WIDEVINE"

  for ROOT in "${ROOT_OPTIONS[@]}"; do
    export AYASA520_ROOT="$ROOT"

    for TRANS in "${TRANSLATION_OPTIONS[@]}"; do
      export AYASA520_NDK_TRANSLATION="$TRANS"

      echo "--------------------------------------"
      echo "Starting build with configuration..."
      echo "Version: $ANDROID_VAR"
      echo "GApps: $AYASA520_GAPPS"
      echo "Widevine: $AYASA520_WADEVINE"
      echo "Root: ${AYASA520_ROOT:-none}"
      echo "Translation: $AYASA520_NDK_TRANSLATION"
      echo "Lunch: $REDROID_LUNCH"
      echo "--------------------------------------"

      bash ./build.sh
    done
  done
done
