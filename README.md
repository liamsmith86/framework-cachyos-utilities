# Framework Laptop 16 CachyOS Utilities

Custom scripts and plasmoids for the Framework Laptop 16 (AMD Ryzen AI 9 HX 370) running CachyOS with KDE Plasma 6 on Wayland. Designed for dual-GPU setups with an NVIDIA RTX 5070 Mobile (dGPU) and AMD Radeon 890M (iGPU). Vibe coded with Claude Opus 4.6 1M.

## Scripts

### power-profile-hook.sh

Adjusts system settings when KDE's power profile changes (performance/balanced/power-saver). Controls display refresh rate, WiFi power save, PCIe ASPM policy, AMD panel power savings, fan curves (via fw-fanctrl), and CPU power limits + undervolt (via ryzenadj).

**Install:** Symlink to `~/.local/bin/` — called automatically by `power-profile-monitor.sh` when the KDE power profile changes.

### power-profile-monitor.sh

Monitors `power-profiles-daemon` over D-Bus and triggers `power-profile-hook.sh` when the active profile changes.

**Install:** Symlink to `~/.local/bin/` and enable the accompanying systemd user service (`power-profile-monitor.service`) to run at login.

### power-tune

Minimal root helper for writing to sysfs. Handles ASPM policy, AMD ABM panel power savings, WiFi power save, and Bluetooth rfkill. Called via passwordless sudo from the power profile hook.

**Install:** Copy to `/usr/local/bin/` (root-owned). Requires a sudoers entry granting passwordless access, e.g. in `/etc/sudoers.d/power-hook`.

### gpu-select

Switches the KDE compositor between the iGPU and dGPU. Saves the selection to a state file and logs out to apply. Useful when docking with an external display connected to the NVIDIA GPU module.

**Install:** Symlink to `~/.local/bin/`. Works together with `gpu-dock-env.sh` which reads the saved state at session start.

### plasmalogin-gpu-env

Detects if an external display is connected to the NVIDIA GPU at boot and writes `KWIN_DRM_DEVICES` to an env file for the plasma-login-manager greeter. Prevents greeter flickering on multi-GPU systems.

**Install:** Copy to `/usr/local/bin/` (root-owned). Called via the `plasmalogin-gpu.conf` systemd drop-in as an `ExecStartPre` hook on `plasmalogin.service`.

### sddm-kwin-wrapper

Similar to `plasmalogin-gpu-env` but wraps SDDM's kwin_wayland compositor directly. Sets `KWIN_DRM_DEVICES` based on connected displays before exec-ing kwin.

**Install:** Copy to `/usr/local/bin/` (root-owned). Only needed if using SDDM instead of plasma-login-manager.

## Environment Scripts

### gpu-dock-env.sh

Runs at Plasma session start. Reads the saved GPU mode (from `gpu-select`) and exports `KWIN_DRM_DEVICES` so KWin composites on the correct GPU. Resolves `by-path` symlinks to `/dev/dri/cardN` to avoid colon conflicts in the env var.

**Install:** Symlink to `~/.config/plasma-workspace/env/` — KDE sources all scripts in this directory at session start.

## Systemd Units

### power-profile-monitor.service

User service that runs `power-profile-monitor.sh` at login. Watches D-Bus for power profile changes and triggers the hook script.

**Install:** Symlink to `~/.config/systemd/user/` and enable with `systemctl --user enable --now power-profile-monitor.service`.

### plasmalogin-gpu.conf

Systemd drop-in for `plasmalogin.service` that runs `plasmalogin-gpu-env` as `ExecStartPre` and passes the resulting env file via `EnvironmentFile`.

**Install:** Copy to `/etc/systemd/system/plasmalogin.service.d/gpu.conf` (requires root). Run `systemctl daemon-reload` after installing.

## Plasmoids

### org.kde.batterywatts

System tray plasmoid showing real-time battery discharge wattage, CPU temperature, and dGPU temperature (when awake).

### org.kde.fwfanctrl

System tray plasmoid for Framework's fw-fanctrl. Shows current fan percentage, lets you switch between fan curve profiles, and includes a GPU compositor tab for switching between iGPU/dGPU. Fork of [augiedoggie/FrameworkFanPlasmoid](https://github.com/augiedoggie/FrameworkFanPlasmoid) by Chris Roberts, licensed under MIT.

## Installation

```sh
git clone https://github.com/liamsmith86/framework-cachyos-utilities.git ~/Documents/Projects/framework-cachyos-utilities

# User scripts
ln -sf ~/Documents/Projects/framework-cachyos-utilities/scripts/power-profile-hook.sh ~/.local/bin/
ln -sf ~/Documents/Projects/framework-cachyos-utilities/scripts/power-profile-monitor.sh ~/.local/bin/
ln -sf ~/Documents/Projects/framework-cachyos-utilities/scripts/gpu-select ~/.local/bin/

# Plasmoids
ln -sf ~/Documents/Projects/framework-cachyos-utilities/plasmoids/org.kde.batterywatts ~/.local/share/plasma/plasmoids/
ln -sf ~/Documents/Projects/framework-cachyos-utilities/plasmoids/org.kde.fwfanctrl ~/.local/share/plasma/plasmoids/

# Environment
ln -sf ~/Documents/Projects/framework-cachyos-utilities/env/gpu-dock-env.sh ~/.config/plasma-workspace/env/

# Systemd user service
ln -sf ~/Documents/Projects/framework-cachyos-utilities/systemd/power-profile-monitor.service ~/.config/systemd/user/
systemctl --user enable --now power-profile-monitor.service

# System scripts (requires root)
sudo cp scripts/power-tune /usr/local/bin/
sudo cp scripts/plasmalogin-gpu-env /usr/local/bin/
sudo cp scripts/sddm-kwin-wrapper /usr/local/bin/
sudo mkdir -p /etc/systemd/system/plasmalogin.service.d
sudo cp systemd/plasmalogin-gpu.conf /etc/systemd/system/plasmalogin.service.d/gpu.conf
```
