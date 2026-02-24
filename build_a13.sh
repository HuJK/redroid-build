#!/bin/bash

# Example configuration for redroid build
# Targeted version: Android 13
# Features: GApps (MindTheGapps), Root(none, magisk), Libhoudini (ARM translation)

# Environment Overrides
export ANDROID_VAR="android-13.0.0_r83"
export AYASA520_GAPPS="mindthegapps"
export AYASA520_ROOT=""
export AYASA520_NDK_TRANSLATION="houdini"
export AYASA520_WADEVINE=1
export DOCKER_USERNAME=redroid
export REDROID_LUNCH="redroid_x86_64-userdebug"

# Disable Docker Push for this example
export PUSH_IMAGE=0

# Ensure we are in the script's directory and run build.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

echo "Starting build with configuration..."
echo "Version: $ANDROID_VAR"
echo "Features: GApps($AYASA520_GAPPS), Root($AYASA520_ROOT), Translation($AYASA520_NDK_TRANSLATION)"

bash ./build.sh

export AYASA520_ROOT="magisk"

echo "Starting build with configuration..."
echo "Version: $ANDROID_VAR"
echo "Features: GApps($AYASA520_GAPPS), Root($AYASA520_ROOT), Translation($AYASA520_NDK_TRANSLATION)"
bash ./build.sh