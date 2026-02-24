#!/bin/bash

# Configuration - Prioritize Environment Variables
ANDROID_VAR="${ANDROID_VAR:-android-14.0.0_r75}"
PROJROOT="${PROJROOT:-$(cd "$(dirname "$0")" && pwd)}"
PATCH_PATH="${PATCH_PATH:-$PROJROOT/redroid-patches}"
DOC_PATH="${DOC_PATH:-$PROJROOT/redroid-doc}"
SOURCE_PATH="${SOURCE_PATH:-$PROJROOT/source/$ANDROID_VAR}"
BUILD_PATH="${BUILD_PATH:-$PROJROOT/build/$ANDROID_VAR}"

# Patching Policy: "cp", "mv", or "overlayfs"
PATCH_POLICY="${PATCH_POLICY:-overlayfs}"
BUILD_DIFF_PATH="${BUILD_DIFF_PATH:-$PROJROOT/build_diff/$ANDROID_VAR}"
BUILD_WORK_PATH="${BUILD_WORK_PATH:-$PROJROOT/build_work/$ANDROID_VAR}"

# redroid-script (ayasa520) configuration
AYASA520_PATH="${AYASA520_PATH:-$PROJROOT/redroid-script}"
AYASA520_GAPPS="${AYASA520_GAPPS:-}"              # Options: "", "gapps", "litegapps", "mindthegapps"
AYASA520_ROOT="${AYASA520_ROOT:-}"                # Options: "", "magisk"
AYASA520_NDK_TRANSLATION="${AYASA520_NDK_TRANSLATION:-}"    # Options: "", "ndk", "houdini"
AYASA520_WADEVINE="${AYASA520_WADEVINE:-0}"       # Options: 0, 1

# Docker Registry configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-dockeruser}"
PUSH_IMAGE="${PUSH_IMAGE:-0}"                   # Set to 1 to push the image to registry
REDROID_LUNCH="${REDROID_LUNCH:-}"              # Required lunch combo (e.g. redroid_x86_64-userdebug)

# Intelligent Dependency Detection (fallback to parent if local not found)
[ ! -d "$PATCH_PATH" ] && [ -d "$PROJROOT/redroid-patches" ] && PATCH_PATH="$PROJROOT/redroid-patches"
[ ! -d "$AYASA520_PATH" ] && [ -d "$PROJROOT/redroid-script" ] && AYASA520_PATH="$PROJROOT/redroid-script"
[ ! -d "$DOC_PATH" ] && [ -d "$PROJROOT/redroid-doc" ] && DOC_PATH="$PROJROOT/redroid-doc"

# Minimum available disk space in GB for source sync
MIN_DISK_GB=150

# ============================================================
# --clean handler: cleanup everything except the source folder
# ============================================================
if [ "$1" == "--clean" ]; then
    echo "=== Clean mode: removing all generated files (keeping source) ==="

    # Unmount overlayfs if mounted
    if mountpoint -q "$BUILD_PATH" 2>/dev/null; then
        echo "Unmounting OverlayFS at $BUILD_PATH..."
        sudo umount -l "$BUILD_PATH"
    fi

    # Remove build artifacts
    [ -d "$BUILD_PATH" ] && echo "Removing $BUILD_PATH..." && rm -rf "$BUILD_PATH"
    [ -d "$BUILD_DIFF_PATH" ] && echo "Removing $BUILD_DIFF_PATH..." && rm -rf "$BUILD_DIFF_PATH"
    [ -d "$BUILD_WORK_PATH" ] && echo "Removing $BUILD_WORK_PATH..." && rm -rf "$BUILD_WORK_PATH"

    # Remove cloned repos
    [ -d "$PATCH_PATH" ] && echo "Removing $PATCH_PATH..." && rm -rf "$PATCH_PATH"
    [ -d "$DOC_PATH" ] && echo "Removing $DOC_PATH..." && rm -rf "$DOC_PATH"
    [ -d "$AYASA520_PATH" ] && echo "Removing $AYASA520_PATH..." && rm -rf "$AYASA520_PATH"

    echo "Clean complete. Source folder preserved at: $PROJROOT/source/"
    exit 0
fi

# ============================================================
# Prerequisite checks
# ============================================================

# 0. Required configuration
if [ -z "$REDROID_LUNCH" ]; then
    echo "Error: REDROID_LUNCH is empty."
    echo "Set REDROID_LUNCH in your wrapper script (e.g., build_a13.sh/build_a14.sh)."
    exit 1
fi

# 1. Required commands
REQUIRED_CMDS=(git git-lfs curl unzip python3 docker)
MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    echo "Error: The following required commands are missing:"
    printf '  - %s\n' "${MISSING_CMDS[@]}"
    echo ""
    echo "Install them before running this script. For example on Ubuntu/Debian:"
    echo "  sudo apt-get install git git-lfs curl unzip python3 docker.io"
    exit 1
fi

# Check required Python modules
MISSING_PYMOD=()
python3 -c "import requests" 2>/dev/null || MISSING_PYMOD+=("python3-requests")
python3 -c "import tqdm" 2>/dev/null || MISSING_PYMOD+=("python3-tqdm")

if [ ${#MISSING_PYMOD[@]} -ne 0 ]; then
    echo "Error: The following required Python modules are missing:"
    printf '  - %s\n' "${MISSING_PYMOD[@]}"
    echo ""
    echo "Install them before running this script. For example on Ubuntu/Debian:"
    echo "  sudo apt-get install ${MISSING_PYMOD[*]}"
    exit 1
fi

# Verify git-lfs is initialized
if ! git lfs env >/dev/null 2>&1; then
    echo "Warning: git-lfs is installed but not initialized. Running 'git lfs install'..."
    git lfs install
fi

# 2. Disk space check (on the filesystem that will hold SOURCE_PATH)
mkdir -p "$SOURCE_PATH"
AVAIL_KB=$(df --output=avail "$SOURCE_PATH" 2>/dev/null | tail -1 | tr -d ' ')

if [ -z "$AVAIL_KB" ]; then
    echo "Warning: Could not determine available disk space for $SOURCE_PARENT. Continuing anyway..."
else
    AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
    # Only enforce the check if source hasn't been downloaded yet
    if [ ! -d "$SOURCE_PATH" ] && [ ! -d "$BUILD_PATH" ]; then
        if [ "$AVAIL_GB" -lt "$MIN_DISK_GB" ]; then
            echo "Error: Insufficient disk space."
            echo "  Required : >= ${MIN_DISK_GB} GB"
            echo "  Available: ${AVAIL_GB} GB (on $(df --output=target "$SOURCE_PATH" | tail -1))"
            echo ""
            echo "Free up space or change SOURCE_PATH to a filesystem with enough room."
            exit 1
        fi
        echo "Disk space check passed: ${AVAIL_GB} GB available (need ${MIN_DISK_GB} GB)."
    fi
fi

# 3. RAM and CPU core warnings
HAS_WARNINGS=0

TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
if [ -n "$TOTAL_RAM_KB" ]; then
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    if [ "$TOTAL_RAM_GB" -lt 64 ]; then
        echo "Warning: System has ${TOTAL_RAM_GB} GB RAM. 64 GB or more is recommended for AOSP builds."
        echo "         Build may be slow or fail due to insufficient memory."
        HAS_WARNINGS=1
    fi
else
    echo "Warning: Could not determine system RAM."
    HAS_WARNINGS=1
fi

CPU_CORES=$(nproc 2>/dev/null)
if [ -n "$CPU_CORES" ]; then
    if [ "$CPU_CORES" -lt 16 ]; then
        echo "Warning: System has ${CPU_CORES} CPU cores. 16 or more is recommended for AOSP builds."
        echo "         Build may be significantly slower with fewer cores."
        HAS_WARNINGS=1
    fi
else
    echo "Warning: Could not determine CPU core count."
    HAS_WARNINGS=1
fi

if [ "$HAS_WARNINGS" -eq 1 ]; then
    echo ""
    read -s -n 1 -p "Warnings detected. Press any key to continue or Ctrl+C to abort . . ."
    echo ""
fi

# ============================================================
# Main build script
# ============================================================

set -x

# Ensure repo is available
if ! command -v repo >/dev/null 2>&1; then
    echo "repo not found, downloading..."
    mkdir -p "$HOME/.local/bin"
    curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/.local/bin/repo"
    chmod a+x "$HOME/.local/bin/repo"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Clone redroid-doc if not exist
if [ ! -d "$DOC_PATH" ]; then
    echo "Cloning redroid-doc to $DOC_PATH..."
    git clone https://github.com/remote-android/redroid-doc.git "$DOC_PATH"
fi

# Patch Dockerfile to handle root user (e.g., if host user is root)
if [ -f "$DOC_PATH/android-builder-docker/Dockerfile" ] && ! grep -q "getent group" "$DOC_PATH/android-builder-docker/Dockerfile"; then
    echo "Patching redroid-doc Dockerfile for root user support..."
    sed -i 's/^RUN groupadd -g $groupid $username/RUN (getent group $groupid || groupadd -g $groupid $username)/' "$DOC_PATH/android-builder-docker/Dockerfile"
    sed -i 's/useradd -m -u $userid -g $groupid $username/(getent passwd $userid || &)/' "$DOC_PATH/android-builder-docker/Dockerfile"
    sed -i 's/echo $username >\/root\/username/mkdir -p \/home\/$username \&\& &/' "$DOC_PATH/android-builder-docker/Dockerfile"
    sed -i 's/adduser $username sudo/(& || true)/' "$DOC_PATH/android-builder-docker/Dockerfile"
fi

# Clone patches if not exist
if [ ! -d "$PATCH_PATH" ]; then
    echo "Cloning redroid-patches to $PATCH_PATH..."
    git clone https://github.com/remote-android/redroid-patches.git "$PATCH_PATH"
fi

# Clone redroid-script if not exist
if [ ! -d "$AYASA520_PATH" ]; then
    echo "Cloning redroid-script to $AYASA520_PATH..."
    git clone https://github.com/ayasa520/redroid-script.git "$AYASA520_PATH"
fi

# 1. Download Source Phase (Independent)
dir_has_content() {
    [ -d "$1" ] && [ "$(ls -A "$1" 2>/dev/null)" ]
}

if ! dir_has_content "$SOURCE_PATH" && ! dir_has_content "$BUILD_PATH"; then
    echo "Downloading redroid source to $SOURCE_PATH..."
    mkdir -p "$SOURCE_PATH"
    cd "$SOURCE_PATH" || exit 1
    repo init -u https://android.googlesource.com/platform/manifest --git-lfs --depth=1 -b "$ANDROID_VAR"
    VERSION_MAJOR=$(echo "$ANDROID_VAR" | cut -d'-' -f2 | cut -d'.' -f1)
    echo "Adding local manifests for version $VERSION_MAJOR..."
    git clone https://github.com/remote-android/local_manifests.git .repo/local_manifests -b "${VERSION_MAJOR}.0.0"
    echo "Syncing redroid source in $SOURCE_PATH... Make sure 200GB available disk size."
    repo sync -c -j8
else
    echo "Source already exists (either in $SOURCE_PATH or $BUILD_PATH). Skipping download phase."
fi

# 2. Patch Policy Phase (Prepare build environment)
# Skip if BUILD_PATH already exists and is non-empty (e.g., from a previous run)
if [ -d "$BUILD_PATH" ] && [ "$(ls -A "$BUILD_PATH" 2>/dev/null)" ]; then
    echo "Build directory $BUILD_PATH already exists and is non-empty. Skipping patch policy, apply patch, and linkerconfig patch."
else
    echo "Preparing build environment using PATCH_POLICY: $PATCH_POLICY"

    case "$PATCH_POLICY" in
        "cp")
            echo "Clearing build path: $BUILD_PATH"
            rm -rf "$BUILD_PATH"
            mkdir -p "$BUILD_PATH"
            echo "Copying source from $SOURCE_PATH to $BUILD_PATH..."
            cp -a "$SOURCE_PATH/." "$BUILD_PATH/"
            ;;
        "mv")
            if [ -d "$SOURCE_PATH" ]; then
                echo "Clearing build path: $BUILD_PATH"
                rm -rf "$BUILD_PATH"
                echo "Moving source from $SOURCE_PATH to $BUILD_PATH..."
                mv "$SOURCE_PATH" "$BUILD_PATH"
            else
                echo "Source already in $BUILD_PATH. Skipping move."
            fi
            ;;
        "overlayfs")
            echo "Preparing OverlayFS..."
            rm -rf "$BUILD_PATH" "$BUILD_DIFF_PATH" "$BUILD_WORK_PATH"
            mkdir -p "$BUILD_PATH" "$BUILD_DIFF_PATH" "$BUILD_WORK_PATH"
            echo "Mounting OverlayFS: source($SOURCE_PATH) -> build($BUILD_PATH)"
            sudo mount -t overlay overlay -o lowerdir="$SOURCE_PATH",upperdir="$BUILD_DIFF_PATH",workdir="$BUILD_WORK_PATH" "$BUILD_PATH"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to mount OverlayFS."
                exit 1
            fi
            ;;
        *)
            echo "Error: Invalid PATCH_POLICY '$PATCH_POLICY'. Use 'cp', 'mv', or 'overlayfs'."
            exit 1
            ;;
    esac

    cd "$BUILD_PATH" || exit 1

    # Apply patches
    echo "Applying redroid patches from $PATCH_PATH to $BUILD_PATH..."
    "$PATCH_PATH/apply-patch.sh" "$BUILD_PATH" "$ANDROID_VAR"

    # Apply houdini linkerconfig patch if houdini NDK translation is selected
    if [ "$AYASA520_NDK_TRANSLATION" == "houdini" ]; then
        LINKERCONFIG_FILE="$BUILD_PATH/system/linkerconfig/contents/namespace/systemdefault.cc"
        if [ -f "$LINKERCONFIG_FILE" ]; then
            echo "Applying houdini linkerconfig patch to $LINKERCONFIG_FILE..."
            sed -i '/ns\.AddSearchPath(system_ext + "\/${LIB}");/a\  // for houdini\n  ns.AddSearchPath("/system/lib/arm");\n  ns.AddSearchPath("/system/lib64/arm64");' "$LINKERCONFIG_FILE"
        else
            echo "Warning: $LINKERCONFIG_FILE not found. Skipping houdini linkerconfig patch."
        fi
    fi
fi

cd "$BUILD_PATH" || exit 1

# Build builder
echo "Building redroid-builder docker image from $DOC_PATH..."
cd "$DOC_PATH/android-builder-docker" || exit 1
docker build --build-arg userid=$(id -u) --build-arg groupid=$(id -g) --build-arg username=$(id -un) -t redroid-builder .
# Build redroid
echo "Starting redroid build within builder container..."
docker run -it --rm --hostname redroid-builder --name redroid-builder -v "$BUILD_PATH":/src -e REDROID_LUNCH="$REDROID_LUNCH" --entrypoint /bin/bash redroid-builder -lc "
    cd /src
    . build/envsetup.sh
    echo \"Using lunch combo: \$REDROID_LUNCH\"
    lunch \"\$REDROID_LUNCH\"
    m
"

# Create final image
echo "Creating final redroid docker image from build artifacts..."
cd "$BUILD_PATH/out/target/product/redroid_x86_64" || exit 0

DEFAULT_TAG=$(echo "$ANDROID_VAR" | cut -d'-' -f2 | cut -d'_' -f1)
REDROID_TAG="${REDROID_TAG:-$DEFAULT_TAG}"

if [ -f system.img ] && [ -f vendor.img ]; then
    mkdir -p system vendor
    sudo mount system.img system -o ro
    sudo mount vendor.img vendor -o ro
    sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | docker import -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' - redroid:latest
    docker tag redroid:latest "redroid/redroid:$REDROID_TAG"
    sudo umount system vendor
    rmdir system vendor
    echo "Redroid base image created: redroid/redroid:$REDROID_TAG"

    FINAL_IMAGE="redroid/redroid:$REDROID_TAG"
    FINAL_TAG="$REDROID_TAG"

    # Post-processing with redroid-script (ayasa520)
    if [ -n "$AYASA520_GAPPS" ] || [ -n "$AYASA520_ROOT" ] || [ -n "$AYASA520_NDK_TRANSLATION" ] || [ "$AYASA520_WADEVINE" -eq 1 ]; then
        echo "Applying redroid-script patches from $AYASA520_PATH..."
        SCRIPT_FLAGS="-a $REDROID_TAG"

        # Order follows redroid.py tags.append order:
        #   -g gapps, -lg litegapps, -mtg mindthegapps, -n ndk, -i houdini, -m magisk, -w widevine

        if [ "$AYASA520_GAPPS" == "gapps" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -g"
            FINAL_TAG="${FINAL_TAG}_gapps"
        fi

        if [ "$AYASA520_GAPPS" == "litegapps" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -lg"
            FINAL_TAG="${FINAL_TAG}_litegapps"
        fi

        if [ "$AYASA520_GAPPS" == "mindthegapps" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -mtg"
            FINAL_TAG="${FINAL_TAG}_mindthegapps"
        fi

        if [ "$AYASA520_NDK_TRANSLATION" == "ndk" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -n"
            FINAL_TAG="${FINAL_TAG}_ndk"
        fi

        if [ "$AYASA520_NDK_TRANSLATION" == "houdini" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -i"
            FINAL_TAG="${FINAL_TAG}_houdini"
        fi

        if [ "$AYASA520_ROOT" == "magisk" ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -m"
            FINAL_TAG="${FINAL_TAG}_magisk"
        fi

        if [ "$AYASA520_WADEVINE" -eq 1 ]; then
            SCRIPT_FLAGS="$SCRIPT_FLAGS -w"
            FINAL_TAG="${FINAL_TAG}_widevine"
        fi

        cd "$AYASA520_PATH" || exit 1
        python3 redroid.py $SCRIPT_FLAGS

        FINAL_IMAGE="redroid/redroid:$FINAL_TAG"
    fi

    # Push to registry if requested
    if [ "$PUSH_IMAGE" -eq 1 ]; then
        REMOTE_IMAGE="$DOCKER_USERNAME/redroid:$FINAL_TAG"
        echo "Pushing image to registry: $REMOTE_IMAGE..."
        docker tag "$FINAL_IMAGE" "$REMOTE_IMAGE"
        docker push "$REMOTE_IMAGE"
    fi
else
    echo "Build artifacts not found. Please check the build log."
fi
