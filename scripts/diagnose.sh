#!/usr/bin/env bash
# Intel Arc ReBAR Diagnostic v0.2
# READ-ONLY: no PCIe writes, unbinds, rescans or reboots

set -u

TARGET_ID="8086:e212"

echo "=== Intel Arc ReBAR Diagnostic v0.2 ==="
echo "Date: $(date -Is)"
echo "Kernel: $(uname -r)"
echo

if ! command -v lspci >/dev/null 2>&1; then
    echo "ERROR: lspci is not installed"
    exit 1
fi

echo "=== PCIe topology ==="
lspci -tv
echo

echo "=== GPU identification ==="
found=0

for device in /sys/bus/pci/devices/*; do
    [[ -r "$device/vendor" && -r "$device/device" ]] || continue

    vendor=$(cat "$device/vendor")
    product=$(cat "$device/device")

    if [[ "$vendor" != "0x8086" || "$product" != "0xe212" ]]; then
        continue
    fi

    found=1
    bdf=${device##*/}

    echo "GPU: $bdf"
    echo "PCI ID: $TARGET_ID"

    echo
    echo "=== BAR configuration ==="
    lspci -s "$bdf" -vv |
        grep -E 'Region 2:|Resizable BAR|BAR 2:' || true

    echo
    echo "=== Driver ==="
    if [[ -L "$device/driver" ]]; then
        driver=$(basename "$(readlink -f "$device/driver")")
        echo "Driver: $driver"
    else
        echo "Driver: NOT BOUND"
    fi

    echo
    echo "=== DRM render nodes ==="
    matched=0

    for render in /sys/class/drm/renderD*; do
        [[ -e "$render/device" ]] || continue

        resolved=$(readlink -f "$render/device")

        if [[ "$resolved" == "$(readlink -f "$device")" ]]; then
            echo "/dev/dri/${render##*/} -> $bdf"
            matched=1
        fi
    done

    if [[ "$matched" == 0 ]]; then
        echo "No matching DRM render node found"
    fi

    echo
    echo "=== Validation ==="

    bar_line=$(lspci -s "$bdf" -vv |
        grep 'Region 2:' | head -n 1)

    if [[ "$bar_line" == *"[size=16G]"* ]]; then
        echo "BAR2_16G: PASS"
    else
        echo "BAR2_16G: NOT VERIFIED"
    fi

    if [[ -L "$device/driver" ]] &&
       [[ "$(basename "$(readlink -f "$device/driver")")" == "xe" ]]; then
        echo "XE_DRIVER: PASS"
    else
        echo "XE_DRIVER: NOT VERIFIED"
    fi

    if [[ "$matched" == 1 ]]; then
        echo "DRM_NODE: PASS"
    else
        echo "DRM_NODE: NOT VERIFIED"
    fi
done

if [[ "$found" == 0 ]]; then
    echo "Intel Arc B50 (8086:e212): NOT FOUND"
    exit 1
fi

echo
echo "READ-ONLY DIAGNOSTIC COMPLETE"
