#!/bin/bash
# Power profile hook for KDE
# Usage: power-profile-hook.sh [performance|balanced|power-saver]
#
# Configure in KDE System Settings > Power Management for each profile.
# Uses /usr/local/bin/power-tune helper via sudoers.

PROFILE="${1:-balanced}"

# Ensure kscreen-doctor uses Wayland backend (not set in systemd user env)
export QT_QPA_PLATFORM=wayland

# Only change laptop panel refresh if it's enabled and no external monitor
KSCREEN=$(kscreen-doctor -o 2>/dev/null | cat -v)
EXTERNAL_CONNECTED=$(echo "$KSCREEN" | grep -c "DP-1" || true)
LAPTOP_ENABLED=$(echo "$KSCREEN" | grep -A1 "eDP-2" | grep -c "enabled" || true)

set_laptop_hz() {
    if [ "$LAPTOP_ENABLED" -ge 1 ] && [ "$EXTERNAL_CONNECTED" -eq 0 ]; then
        kscreen-doctor output.eDP-2.mode.2560x1600@"$1" 2>/dev/null
    fi
}

case "$PROFILE" in
    performance)
        set_laptop_hz 165
        sudo power-tune wifi off
        sudo power-tune aspm performance
        sudo power-tune abm 0
        fw-fanctrl use performance
        sudo ryzenadj --tctl-temp=100 --set-coall=0xFFFE7 2>/dev/null
        ;;

    balanced)
        set_laptop_hz 165
        sudo power-tune wifi off
        sudo power-tune aspm performance
        sudo power-tune abm 0
        fw-fanctrl use balanced
        sudo ryzenadj --stapm-limit=35000 --fast-limit=45000 --slow-limit=35000 --tctl-temp=85 --set-coall=0xFFFE2 2>/dev/null
        ;;

    power-saver)
        set_laptop_hz 60
        sudo power-tune wifi on
        sudo power-tune aspm powersave
        sudo power-tune abm 1
        fw-fanctrl use power-saver
        sudo ryzenadj --stapm-limit=15000 --fast-limit=20000 --slow-limit=15000 --tctl-temp=75 --set-coall=0xFFFDD 2>/dev/null
        ;;
esac
