# redroid-build

My custom redroid image build script. 
Build from [redroid](https://github.com/remote-android/redroid-doc) from AOSP source (Android 12/13/14/15/16)
And then apply patch [redroid-script-openwrt](https://github.com/rote66/redroid-script-openwrt/) from [rote66](https://github.com/rote66) for every combination

- GApps (`litegapps`, `mindthegapps`)
- Root ( ` `, `magisk`)
- ARM translation (` `, `ndk`, `houdini`)
- Widevine patching

## Pre-built Images:

https://hub.docker.com/r/whojk/redroid/tags

Android 16:

- `docker pull whojk/redroid:16.0.0_litegapps`
- `docker pull whojk/redroid:16.0.0_litegapps_magisk`
- `docker pull whojk/redroid:16.0.0_litegapps_houdini`
- `docker pull whojk/redroid:16.0.0_litegapps_houdini_magisk`

Android 15:

- `docker pull whojk/redroid:15.0.0_litegapps`
- `docker pull whojk/redroid:15.0.0_litegapps_magisk`
- `docker pull whojk/redroid:15.0.0_litegapps_houdini`
- `docker pull whojk/redroid:15.0.0_litegapps_houdini_magisk`

Android 14:

- `docker pull whojk/redroid:14.0.0_mindthegapps`
- `docker pull whojk/redroid:14.0.0_mindthegapps_magisk`
- `docker pull whojk/redroid:14.0.0_mindthegapps_ndk`
- `docker pull whojk/redroid:14.0.0_mindthegapps_ndk_magisk`
- `docker pull whojk/redroid:14.0.0_mindthegapps_houdini`
- `docker pull whojk/redroid:14.0.0_mindthegapps_houdini_magisk`

Android 13:

- `docker pull whojk/redroid:13.0.0_mindthegapps`
- `docker pull whojk/redroid:13.0.0_mindthegapps_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_magisk`
- `docker pull whojk/redroid:13.0.0_mindthegapps_magisk_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_ndk`
- `docker pull whojk/redroid:13.0.0_mindthegapps_ndk_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_ndk_magisk`
- `docker pull whojk/redroid:13.0.0_mindthegapps_ndk_magisk_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini_magisk`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini_magisk_widevine`

Android 12:
- `docker pull whojk/redroid:12.0.0_mindthegapps`
- `docker pull whojk/redroid:12.0.0_mindthegapps_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_widevine_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_magisk`
- `docker pull whojk/redroid:12.0.0_mindthegapps_magisk_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_magisk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_magisk_widevine_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_widevine_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_magisk`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_magisk_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_magisk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_magisk_widevine_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_widevine_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_magisk`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_magisk_systemui`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_magisk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_magisk_widevine_systemui`

## Repository layout

Build script

- `build.sh`: Main end-to-end build pipeline (expects `REDROID_LUNCH` to be set).
- `build_a*.sh`: Android build configuration wrapper.

Run script

- `r13.sh`: Run an Android 13 (houdini) container image and print Google uncertified registration ID.
- `r13a.sh`: Run an Android 13 (ndk) container image and print Google uncertified registration ID.

## Credits & dependencies

Repository dependency tree (traced from `build.sh`, `local_manifests`, and the currently cloned post-process repository):

* `https://android.googlesource.com/platform/manifest`
* `https://github.com/remote-android/local_manifests`
  * `https://github.com/remote-android/device_redroid`
  * `https://github.com/remote-android/device_redroid-prebuilts`
  * `https://github.com/remote-android/redroid-c2`
  * `https://github.com/remote-android/redroid-gatekeeper`
  * `https://github.com/remote-android/redroid-omx`
  * `https://github.com/remote-android/vendor_redroid`
  * `https://github.com/remote-android/chromium-webview-stub`
  * `https://github.com/LineageOS/android_external_chromium-webview_prebuilt_arm`
  * `https://github.com/LineageOS/android_external_chromium-webview_prebuilt_arm64`
  * `https://github.com/LineageOS/android_external_chromium-webview_prebuilt_x86`
  * `https://github.com/LineageOS/android_external_chromium-webview_prebuilt_x86_64`
* `https://github.com/remote-android/redroid-doc`
* `https://github.com/remote-android/redroid-patches`
* `https://github.com/rote66/redroid-script-openwrt`
  * forked from `https://github.com/ayasa520/redroid-script`
  * credits/docs reference:
    * `https://github.com/waydroid/waydroid_script`
    * `https://huskydg.github.io/magisk-files/`
    * `https://github.com/rote66/vendor_intel_proprietary_houdini`
  * feature payload repositories still used by this build flow:
    * `https://github.com/s1204IT/MindTheGappsBuilder`
    * `https://github.com/ayasa520/Magisk`
    * `https://github.com/supremegamers/vendor_google_proprietary_ndk_translation-prebuilt`
    * `https://github.com/rote66/vendor_intel_proprietary_houdini`
    * `https://github.com/rote66/redroid_libhoudini_hack`
    * `https://github.com/supremegamers/vendor_google_proprietary_widevine-prebuilt`

Notes:
- Includes direct repositories from `build.sh` and transitive repositories referenced by `local_manifests` and `rote66/redroid-script-openwrt`.
- The tree prioritizes repos that affect this build flow directly; the `credits/docs reference` branch under `rote66/redroid-script-openwrt` is included only for upstream provenance.

## Prerequisites

Build host requirements used by `build.sh`:
- Linux host with Docker and `sudo` access
- Recommended: `>=64 GB RAM`, `>=16 CPU cores`, `>=150 GB` free disk
- Installed commands: `git`, `git-lfs`, `curl`, `unzip`, `python3`, `docker`
- Python modules: `requests`, `tqdm`

Runtime requirements used by `r13.sh` / `r13a.sh`:
- `adb`, `sqlite3`
- Kernel binder module support (`binder_linux`)

## Notes

- `PATCH_POLICY=overlayfs` requires successful `sudo mount -t overlay`.
- First source sync/build can take a long time and large disk space.
- If Google Play is included, register the printed Android ID at:
  `https://www.google.com/android/uncertified`
