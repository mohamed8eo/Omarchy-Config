# Fixing Hardware-Accelerated Video Decode for Chromium-based Browsers on Hybrid NVIDIA + iGPU Omarchy Systems

This guide documents the complete, tested solution to fix hardware-accelerated video decoding on hybrid NVIDIA + Intel/AMD laptops running Omarchy (Hyprland), resolving `EGL_BAD_MATCH`, black screens, and software decoding fallbacks.

---

## Step 1: Create the Wrapper Script

Create a launcher wrapper script in `~/.local/bin/omarchy-launch-chromium` that forces Mesa EGL (matching the Hyprland compositor) and the correct VA-API driver.

```bash
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/omarchy-launch-chromium
#!/bin/bash
MESA_EGL=/usr/share/glvnd/egl_vendor.d/50_mesa.json
[[ -f $MESA_EGL ]] && export __EGL_VENDOR_LIBRARY_FILENAMES="$MESA_EGL"

IGPU="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -iv 'nvidia' | grep -iE 'intel|amd|advanced micro devices|radeon|ati ')"
if echo "$IGPU" | grep -qi 'intel'; then
  export LIBVA_DRIVER_NAME=iHD
elif [[ -n $IGPU ]]; then
  export LIBVA_DRIVER_NAME=radeonsi
fi

exec /usr/bin/brave "$@"
EOF
```

Make the wrapper executable:
```bash
chmod +x ~/.local/bin/omarchy-launch-chromium
```

---

## Step 2: Configure Browser Flags

Ensure your browser flags (e.g., for Brave in `~/.config/brave-flags.conf`) enable Wayland ozone platform and required features while removing any conflicting disable flags:

```text
--ozone-platform=wayland
--ozone-platform-hint=wayland
--password-store=gnome-libsecret
--enable-features=TouchpadOverscrollHistoryNavigation
```

---

## Step 3: Override the Desktop Entry

To ensure your application launcher and shortcuts invoke the wrapper script (and avoid duplicate app entries), create or override the desktop entry in `~/.local/share/applications/brave-browser.desktop`:

```ini
[Desktop Entry]
Version=1.0
Name=Brave
GenericName=Web Browser
Comment=Access the Internet
Exec=/home/mohamed/.local/bin/omarchy-launch-chromium %U
StartupNotify=true
Terminal=false
Icon=brave-desktop
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ipfs;x-scheme-handler/ipns;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=/home/mohamed/.local/bin/omarchy-launch-chromium

[Desktop Action new-private-window]
Name=New Incognito Window
Exec=/home/mohamed/.local/bin/omarchy-launch-chromium --incognito
```

---

## Step 4: Refresh Desktop Database

Update the local desktop database so your system registers the override:

```bash
update-desktop-database ~/.local/share/applications
```

---

## Verification

1. Launch your browser.
2. Navigate to `brave://gpu` (or `chrome://gpu`).
3. Check **Video Decode**—it should now display **Hardware accelerated**.
