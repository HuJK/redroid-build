# redroid-build

Build and run custom redroid Docker images from AOSP source (Android 13/14), with optional:
- GApps (`gapps`, `litegapps`, `mindthegapps`)
- Root (`magisk`)
- ARM translation (`ndk`, `houdini`)
- Widevine patching

## Repository layout

- `build.sh`: Main end-to-end build pipeline.
- `build_a13.sh`: Example Android 13 build configuration.
- `build_a14.sh`: Example Android 14 build configuration.
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

## Quick start

### Build Android 14 images

```bash
chmod +x build.sh build_a14.sh
sudo ./build_a14.sh
```

### Build Android 13 images

```bash
chmod +x build.sh build_a13.sh
sudo ./build_a13.sh
```

Both example scripts run `build.sh` twice:
1. without root
2. with `magisk`

## Build outputs

`build.sh` first creates:
- `redroid/redroid:<android_version>`

Then applies optional post-processing via `redroid-script`, producing tags like:
- `redroid/redroid:14.0.0_mindthegapps_houdini`
- `redroid/redroid:14.0.0_mindthegapps_houdini_magisk`
- `redroid/redroid:13.0.0_mindthegapps_houdini_widevine`

If `PUSH_IMAGE=1`, final image is pushed as:
- `<DOCKER_USERNAME>/redroid:<final_tag>`

## Configuration (environment variables)

Common variables accepted by `build.sh`:

- `ANDROID_VAR` (default: `android-14.0.0_r75`)
- `PATCH_POLICY` (`cp`, `mv`, `overlayfs`; default: `overlayfs`)
- `AYASA520_GAPPS` (``, `gapps`, `litegapps`, `mindthegapps`)
- `AYASA520_ROOT` (``, `magisk`)
- `AYASA520_NDK_TRANSLATION` (``, `ndk`, `houdini`)
- `AYASA520_WADEVINE` (`0` or `1`)
- `REDROID_TAG` (optional manual image tag override)
- `PUSH_IMAGE` (`0` or `1`)
- `DOCKER_USERNAME` (used when pushing)

Example custom build:

```bash
export ANDROID_VAR="android-14.0.0_r75"
export AYASA520_GAPPS="mindthegapps"
export AYASA520_NDK_TRANSLATION="houdini"
export AYASA520_ROOT="magisk"
export AYASA520_WADEVINE=0
export PUSH_IMAGE=0
sudo ./build.sh
```

## Clean generated artifacts

To remove generated build artifacts, overlays, and cloned helper repos while preserving `source/`:

```bash
sudo ./build.sh --clean
```

## Run containers

Start Android 14:

```bash
chmod +x start_a14.sh
sudo ./start_a14.sh
```

Start Android 13:

```bash
chmod +x start_a13.sh
sudo ./start_a13.sh
```

The scripts:
- load binder devices
- start container exposing `adb` on `localhost:5555`
- enable `adbd`
- read Android ID from `gservices.db` for Google Play uncertified device registration

## Useful Docker commands

```bash
docker ps
docker logs -f redroid14
docker stop redroid14
docker rm redroid14
```

## Notes

- `PATCH_POLICY=overlayfs` requires successful `sudo mount -t overlay`.
- First source sync/build can take a long time and large disk space.
- If Google Play is included, register the printed Android ID at:
  `https://www.google.com/android/uncertified`
