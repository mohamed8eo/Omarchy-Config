# shellcheck shell=bash
# Step 45: Helium hardware video decode fix and default browser.
# Adapted from docs/omarchy-chromium-hardware-acceleration-fix.md (that note targets Brave).
# The wrapper forces Mesa EGL and the right VA-API driver; the desktop-entry override makes
# launchers use it. Skipped if Helium is not installed.

if command -v helium-browser >/dev/null 2>&1; then
  printf '\nApplying Helium hardware acceleration fix...\n'
  HELIUM_WRAPPER="$HOME/.local/bin/omarchy-launch-helium"
  HELIUM_FLAGS="$HOME/.config/helium-browser-flags.conf"
  HELIUM_DESKTOP_SRC=${HELIUM_DESKTOP_SRC:-/usr/share/applications/helium-browser.desktop}
  HELIUM_DESKTOP="$HOME/.local/share/applications/helium-browser.desktop"

  backup_if_present "$HELIUM_WRAPPER" local-bin/omarchy-launch-helium
  mkdir -p "$(dirname -- "$HELIUM_WRAPPER")"
  cat > "$HELIUM_WRAPPER" <<'WRAPPER'
#!/bin/bash
MESA_EGL=/usr/share/glvnd/egl_vendor.d/50_mesa.json
[[ -f $MESA_EGL ]] && export __EGL_VENDOR_LIBRARY_FILENAMES="$MESA_EGL"

IGPU="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -iv 'nvidia' | grep -iE 'intel|amd|advanced micro devices|radeon|ati ')"
if echo "$IGPU" | grep -qi 'intel'; then
  export LIBVA_DRIVER_NAME=iHD
elif [[ -n $IGPU ]]; then
  export LIBVA_DRIVER_NAME=radeonsi
fi

exec /usr/bin/helium-browser "$@"
WRAPPER
  chmod +x "$HELIUM_WRAPPER"
  printf 'Installed %s\n' "$HELIUM_WRAPPER"

  backup_if_present "$HELIUM_FLAGS" helium-browser-flags.conf
  mkdir -p "$(dirname -- "$HELIUM_FLAGS")"
  cat > "$HELIUM_FLAGS" <<'FLAGS'
--ozone-platform=wayland
--ozone-platform-hint=wayland
--password-store=gnome-libsecret
--enable-features=TouchpadOverscrollHistoryNavigation
FLAGS
  printf 'Installed %s\n' "$HELIUM_FLAGS"

  if [[ -r $HELIUM_DESKTOP_SRC ]]; then
    backup_if_present "$HELIUM_DESKTOP" applications/helium-browser.desktop
    mkdir -p "$(dirname -- "$HELIUM_DESKTOP")"
    sed -E "s#^Exec=(/usr/bin/)?(helium-browser|chromium)#Exec=$HELIUM_WRAPPER#" "$HELIUM_DESKTOP_SRC" > "$HELIUM_DESKTOP"
    if grep -qF "Exec=$HELIUM_WRAPPER" "$HELIUM_DESKTOP"; then
      printf 'Installed %s\n' "$HELIUM_DESKTOP"
    else
      warn "no Exec line was rewritten in $HELIUM_DESKTOP; launchers may skip the wrapper."
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$(dirname -- "$HELIUM_DESKTOP")" || true
    fi
  else
    warn "$HELIUM_DESKTOP_SRC not found; skipped the desktop entry override."
  fi

  # Set Helium as the default browser (multiple methods for compatibility).
  printf 'Setting Helium as default browser...\n'
  local browser="helium-browser.desktop"
  local success=0

  # Method 1: xdg-settings (standard)
  if command -v xdg-settings >/dev/null 2>&1; then
    if xdg-settings set default-web-browser "$browser"; then
      printf '  xdg-settings: OK\n'
      success=1
    else
      printf '  xdg-settings: failed\n'
    fi
  fi

  # Method 2: gio mime (GNOME/GTK apps)
  if command -v gio >/dev/null 2>&1; then
    gio mime x-scheme-handler/http "$browser" 2>/dev/null && printf '  gio http: OK\n' || printf '  gio http: failed\n'
    gio mime x-scheme-handler/https "$browser" 2>/dev/null && printf '  gio https: OK\n' || printf '  gio https: failed\n'
    gio mime text/html "$browser" 2>/dev/null && printf '  gio html: OK\n' || printf '  gio html: failed\n'
    success=1
  fi

  # Method 3: xdg-mime (freedesktop standard)
  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "$browser" x-scheme-handler/http 2>/dev/null && printf '  xdg-mime http: OK\n' || printf '  xdg-mime http: failed\n'
    xdg-mime default "$browser" x-scheme-handler/https 2>/dev/null && printf '  xdg-mime https: OK\n' || printf '  xdg-mime https: failed\n'
    xdg-mime default "$browser" text/html 2>/dev/null && printf '  xdg-mime html: OK\n' || printf '  xdg-mime html: failed\n'
    xdg-mime default "$browser" application/xhtml+xml 2>/dev/null && printf '  xdg-mime xhtml: OK\n' || printf '  xdg-mime xhtml: failed\n'
    success=1
  fi

  # Refresh desktop database
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    printf '  desktop database: refreshed\n'
  fi

  if ((success)); then
    printf 'Default browser set to Helium.\n'
  else
    warn 'could not set Helium as default browser (no suitable tool found).'
  fi
else
  printf '\nHelium is not installed; skipping the hardware acceleration fix and default browser setup.\n'
fi
