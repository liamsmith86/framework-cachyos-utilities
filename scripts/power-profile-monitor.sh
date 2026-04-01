#!/bin/bash
# Monitors power-profiles-daemon for profile changes via D-Bus
# and runs power-profile-hook.sh when the active profile changes.

HOOK="$HOME/.local/bin/power-profile-hook.sh"

stdbuf -oL gdbus monitor --system \
    --dest net.hadess.PowerProfiles \
    --object-path /net/hadess/PowerProfiles |
while IFS= read -r line; do
    if [[ "$line" == *"ActiveProfile"* ]]; then
        profile=$(echo "$line" | grep -oP "ActiveProfile': <'\\K[^']+")
        if [[ -n "$profile" ]]; then
            "$HOOK" "$profile" &
        fi
    fi
done
