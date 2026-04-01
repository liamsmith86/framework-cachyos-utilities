#!/bin/sh
# gpu-dock-env.sh — Set KWIN_DRM_DEVICES at Plasma session start
#
# Reads saved GPU mode from state file. If set to dgpu, composites on
# the NVIDIA GPU for full external display refresh rate.
#
# IMPORTANT: by-path symlinks contain colons (pci-0000:c1:00.0) which
# conflict with KWIN_DRM_DEVICES's colon separator. We must resolve
# to /dev/dri/cardN paths.

STATE_FILE="$HOME/.config/gpu-dock-mode"

mode=$(cat "$STATE_FILE" 2>/dev/null || echo "igpu")

if [ "$mode" = "dgpu" ]; then
    NVIDIA_DRI=$(readlink -f "/dev/dri/by-path/pci-0000:c1:00.0-card" 2>/dev/null)
    AMD_DRI=$(readlink -f "/dev/dri/by-path/pci-0000:c2:00.0-card" 2>/dev/null)

    if [ -c "$NVIDIA_DRI" ] && [ -c "$AMD_DRI" ]; then
        export KWIN_DRM_DEVICES="${NVIDIA_DRI}:${AMD_DRI}"
    else
        # NVIDIA device not available (D3cold / not loaded) — fall back to iGPU
        # to avoid a login loop
        echo "igpu" > "$STATE_FILE"
        unset KWIN_DRM_DEVICES 2>/dev/null || true
    fi
else
    unset KWIN_DRM_DEVICES 2>/dev/null || true
fi
