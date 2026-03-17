# redroid-build

Build and run custom redroid Docker images from AOSP source (Android 13/14), with optional:
- GApps (`gapps`, `litegapps`, `mindthegapps`)
- Root (`magisk`)
- ARM translation (`ndk`, `houdini`)
- Widevine patching

## Pre-built Images:

https://hub.docker.com/r/whojk/redroid/tags

- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_ndk_magisk_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_widevine`
- `docker pull whojk/redroid:12.0.0_mindthegapps_houdini_magisk_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini_widevine`
- `docker pull whojk/redroid:13.0.0_mindthegapps_houdini_magisk_widevine`
- `docker pull whojk/redroid:14.0.0_mindthegapps_houdini`
- `docker pull whojk/redroid:14.0.0_mindthegapps_houdini_magisk`

## Repository layout

Build script

- `build.sh`: Main end-to-end build pipeline (expects `REDROID_LUNCH` to be set).
- `build_a12.sh`: Android 12 build configuration wrapper.
- `build_a13.sh`: Android 13 build configuration wrapper.
- `build_a14.sh`: Android 14 build configuration wrapper.

Run script

- `start_a12.sh`: Run an Android 12 container image and print Google uncertified registration ID.
- `start_a12a.sh`: Run an Android 12(ndk) container image and print Google uncertified registration ID.
- `start_a13.sh`: Run an Android 13 container image and print Google uncertified registration ID.
- `start_a14.sh`: Run an Android 14 container image and print Google uncertified registration ID.

## Credits & dependencies

Repository dependency tree (traced from `build.sh`, `local_manifests`, and patch/post-process scripts):

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
* `https://github.com/ayasa520/redroid-script`
  * `https://github.com/s1204IT/MindTheGappsBuilder`
  * `https://github.com/ayasa520/Magisk`
  * `https://github.com/supremegamers/vendor_google_proprietary_ndk_translation-prebuilt`
  * `https://github.com/rote66/vendor_intel_proprietary_houdini`
  * `https://github.com/rote66/redroid_libhoudini_hack`
  * `https://github.com/supremegamers/vendor_google_proprietary_widevine-prebuilt`

Notes:
- Includes direct repositories from `build.sh` and transitive repositories referenced by `local_manifests` and `redroid-script`.
- The above tree reflects executable script paths, not README/reference links from dependency repos.

## Prerequisites

Build host requirements used by `build.sh`:
- Linux host with Docker and `sudo` access
- Recommended: `>=64 GB RAM`, `>=16 CPU cores`, `>=150 GB` free disk
- Installed commands: `git`, `git-lfs`, `curl`, `unzip`, `python3`, `docker`
- Python modules: `requests`, `tqdm`

Runtime requirements used by `start_a13.sh` / `start_a14.sh`:
- `adb`, `sqlite3`
- Kernel binder module support (`binder_linux`)

## Notes

- `PATCH_POLICY=overlayfs` requires successful `sudo mount -t overlay`.
- First source sync/build can take a long time and large disk space.
- If Google Play is included, register the printed Android ID at:
  `https://www.google.com/android/uncertified`
