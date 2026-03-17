#!/bin/bash
set -e

# Example configuration for redroid build
# Targeted version: Android 12
# Features: GApps (MindTheGapps), Root(none, magisk), Libhoudini / NDK translation

# Environment Overrides
export ANDROID_VAR="android-12.0.0_r34"
export AYASA520_GAPPS="mindthegapps"
export DOCKER_USERNAME=whojk
export REDROID_LUNCH="redroid_x86_64-userdebug"

# Disable Docker Push for this example
export PUSH_IMAGE=1

# Ensure we are in the script's directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Build matrix
ROOT_OPTIONS=("" "magisk")
TRANSLATION_OPTIONS=("houdini" "ndk" "")
WIDEVINE_OPTIONS=("0" "1")
REMOVE_UI_ODEX_OPTIONS=("0" "1")

for WIDEVINE in "${WIDEVINE_OPTIONS[@]}"; do
  export AYASA520_WADEVINE="$WIDEVINE"

  for ROOT in "${ROOT_OPTIONS[@]}"; do
    export AYASA520_ROOT="$ROOT"

    for TRANS in "${TRANSLATION_OPTIONS[@]}"; do
      export AYASA520_NDK_TRANSLATION="$TRANS"

      for REMOVE_ODEX in "${REMOVE_UI_ODEX_OPTIONS[@]}"; do
        export AYASA520_REMOVE_UI_ODEX="$TRANS"
      
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
done