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
            "${PATCHELF}" --add-needed libshim_sensorndkbridge.so "${2}"
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

# Utils patch
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/vendor/lib64/libexynosdisplay.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/vendor/lib/libexynosdisplay.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib64/hw/hwcomposer.exynos9611.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib/hw/hwcomposer.exynos9611.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib/sensors.sensorhub.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib64/sensors.sensorhub.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib/sensors.grip.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib64/sensors.grip.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib/sensors.inputvirtual.so
"${PATCHELF}" --replace-needed libutils.so libutils-v32.so $BLOB_ROOT/proprietary/vendor/lib64/sensors.inputvirtual.so

"${MY_DIR}/setup-makefiles.sh"

