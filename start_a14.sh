#!/bin/bash

REDROID_NAME="redroid14"
REDROID_DATA="$HOME/${REDROID_NAME}-data"

# 1. Check dependencies
for cmd in adb sqlite3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "$cmd not found, installing..."
        sudo apt install -y $([ "$cmd" = "adb" ] && echo "adb" || echo "sqlite3")
    fi
done

modprobe binder_linux devices="binder,hwbinder,vndbinder"
adb start-server

mkdir -p "$REDROID_DATA"

docker run -it -d \
    --name "$REDROID_NAME" \
    -p 5555:5555 \
    --privileged \
    -v "$REDROID_DATA/data":/data \
    whojk/redroid:14.0.0_mindthegapps_houdini \
    androidboot.redroid_width=1920 \
    androidboot.redroid_height=1080 \
    androidboot.redroid_dpi=240 \
    androidboot.redroid_fps=60 \
    androidboot.use_redroid_overlayfs=1 \
    androidboot.use_memfd=1 \
    androidboot.redroid_gpu_mode=host \
    ro.secure=1 \
    ro.debuggable=0 \
    ro.setupwizard.mode=DISABLED \
    ro.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi \
    ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi \
    ro.product.cpu.abilist64=x86_64,arm64-v8a \
    ro.vendor.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi \
    ro.vendor.product.cpu.abilist32=x86,armeabi-v7a,armeabi \
    ro.vendor.product.cpu.abilist64=x86_64,arm64-v8a \
    ro.odm.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi \
    ro.odm.product.cpu.abilist32=x86,armeabi-v7a,armeabi \
    ro.odm.product.cpu.abilist64=x86_64,arm64-v8a \
    ro.dalvik.vm.native.bridge=libhoudini.so \
    ro.enable.native.bridge.exec=1 \
    ro.enable.native.bridge.exec64=1 \
    ro.dalvik.vm.isa.arm=x86 \
    ro.dalvik.vm.isa.arm64=x86_64

sleep 5

# Enable adbd

if [ -f ~/.android/adbkey.pub ]; then
    pubkey=$(cat ~/.android/adbkey.pub)
    if ! grep -qF "$pubkey" "$REDROID_DATA/data/misc/adb/adb_keys"; then
        echo "$pubkey" >> "$REDROID_DATA/data/misc/adb/adb_keys"
    fi
fi

docker exec -it "$REDROID_NAME" setprop ctl.start adbd

# Extract and show android ID (retry up to 50 times)
echo -n "Waiting for play service init: "
for i in $(seq 1 50); do
    printf "\rWaiting for play service init: [%-50s] (%d/50)" "$(printf '#%.0s' $(seq 1 $i))" "$i"
    docker exec -i "$REDROID_NAME" cat /data/data/com.google.android.gsf/databases/gservices.db > "$REDROID_DATA/gservices.db" 2>/dev/null
    ANDROID_ID=$(sqlite3 "$REDROID_DATA/gservices.db" "select * from main where name = 'android_id';" 2>/dev/null | grep -oP '\d+')
    [ -n "$ANDROID_ID" ] && break
    sleep 1
done
echo
rm -f "$REDROID_DATA/gservices.db"

if [ -n "$ANDROID_ID" ]; then
    echo "Please register the android ID at https://www.google.com/android/uncertified with following ID to use Google Play:"
    echo "$ANDROID_ID"
else
    echo "Failed to retrieve android ID after 50 attempts."
fi