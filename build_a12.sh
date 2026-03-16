#!/bin/bash

# Example configuration for redroid build
# Targeted version: Android 12
# Features: GApps (MindTheGapps), Root(none, magisk), Libhoudini / NDK translation

# Environment Overrides
export ANDROID_VAR="android-12.0.0_r34"
export AYASA520_GAPPS="mindthegapps"
export AYASA520_WADEVINE=1
export DOCKER_USERNAME=whojk
export REDROID_LUNCH="redroid_x86_64-userdebug"

# Disable Docker Push for this example
export PUSH_IMAGE=0

# Ensure we are in the script's directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Build matrix
ROOT_OPTIONS=("" "magisk")
TRANSLATION_OPTIONS=("houdini" "ndk")

for ROOT in "${ROOT_OPTIONS[@]}"; do
  for TRANS in "${TRANSLATION_OPTIONS[@]}"; do

    export AYASA520_ROOT="$ROOT"
    export AYASA520_NDK_TRANSLATION="$TRANS"

    echo "--------------------------------------"
    echo "Starting build with configuration..."
    echo "Version: $ANDROID_VAR"
    echo "GApps: $AYASA520_GAPPS"
    echo "Root: ${AYASA520_ROOT:-none}"
    echo "Translation: $AYASA520_NDK_TRANSLATION"
    echo "--------------------------------------"

    bash ./build.sh

  done
done
