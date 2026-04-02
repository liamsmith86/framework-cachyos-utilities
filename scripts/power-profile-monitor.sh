#!/bin/bash
# Monitors power-profiles-daemon for profile changes via D-Bus
# and runs power-profile-hook.sh when the active profile changes.
#
# Power-saver transitions are delayed 60s so that briefly unplugging
# (e.g. moving the laptop) doesn't needlessly drop to 60Hz.

HOOK="$HOME/.local/bin/power-profile-hook.sh"
HOOK_PID=""

# Kill previous hook and its entire process tree (sudo, ryzenadj, etc.)
cancel_hook() {
    if [[ -n "$HOOK_PID" ]] && kill -0 "$HOOK_PID" 2>/dev/null; then
        kill -- -"$HOOK_PID" 2>/dev/null
        wait "$HOOK_PID" 2>/dev/null
    fi
    HOOK_PID=""
}

stdbuf -oL gdbus monitor --system \
    --dest net.hadess.PowerProfiles \
    --object-path /net/hadess/PowerProfiles |
while IFS= read -r line; do
    if [[ "$line" == *"ActiveProfile"* ]]; then
        profile=$(echo "$line" | grep -oP "ActiveProfile': <'\\K[^']+")
        if [[ -n "$profile" ]]; then
            cancel_hook
            if [[ "$profile" == "power-saver" ]]; then
                setsid --wait bash -c "sleep 60 && \"$HOOK\" \"$profile\"" &
            else
                setsid --wait "$HOOK" "$profile" &
            fi
            HOOK_PID=$!
        fi
    fi
done
