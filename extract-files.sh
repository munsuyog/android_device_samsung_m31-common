#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE=m31
DEVICE_COMMON=m31-common
VENDOR=samsung

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib*/libsensorlistener.so)
            patchelf --add-needed libshim_sensorndkbridge.so "${2}"
            ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

BLOB_ROOT="$ANDROID_ROOT"/vendor/"$VENDOR"/"$DEVICE_COMMON"/proprietary

# Remove libhidltransport dependencie
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/bin/hw/android.hardware.drm@1.4-service.widevine
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/lib/libstagefright_bufferqueue_helper_vendor.so
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/lib/libstagefright_omx_vendor.so
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/lib/libwvhidl.so
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/lib/sensors.sensorhub.so
patchelf --remove-needed libhidltransport.so $BLOB_ROOT/vendor/lib64/sensors.sensorhub.so
# Remove libhwbinder dependencie
patchelf --remove-needed libhwbinder.so $BLOB_ROOT/vendor/bin/hw/android.hardware.drm@1.4-service.widevine
patchelf --remove-needed libhwbinder.so $BLOB_ROOT/vendor/lib/libwvhidl.so

# Protobuf
patchelf --replace-needed libprotobuf-cpp-lite.so libprotobuf-cpp-lite-v29.so $BLOB_ROOT/vendor/lib/libwvhidl.so
patchelf --replace-needed libprotobuf-cpp-lite.so libprotobuf-cpp-lite-v29.so $BLOB_ROOT/vendor/lib/mediadrm/libwvdrmengine.so

# Replace libvndsecril-client with libsecril-client
#${PATCHELF}" --replace-needed libvndsecril-client.so libsecril-client.so $BLOB_ROOT/vendor/lib/libwrappergps.so
#${PATCHELF}" --replace-needed libvndsecril-client.so libsecril-client.so $BLOB_ROOT/vendor/lib64/libwrappergps.so
#${PATCHELF}" --replace-needed libvndsecril-client.so libsecril-client.so $BLOB_ROOT/lib/libaudio-ril.so
#${PATCHELF}" --replace-needed libvndsecril-client.so libsecril-client.so $BLOB_ROOT/lib/hw/audio.primary.exynos8895.so


"${MY_DIR}/setup-makefiles.sh"
