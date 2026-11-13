# shellcheck shell=bash
# Step 45: Helium hardware video decode fix and default browser.
# Adapted from docs/omarchy-chromium-hardware-acceleration-fix.md (that note targets Brave).
# The wrapper forces Mesa EGL and the right VA-API driver; the desktop-entry override makes
# launchers use it. Skipped if Helium is not installed.

if command -v helium-browser >/dev/null 2>&1; then
  run_cmd 'Applying Helium hardware acceleration fix' true
  HELIUM_WRAPPER="$HOME/.local/bin/omarchy-launch-helium"
  HELIUM_FLAGS="$HOME/.config/helium-browser-flags.conf"
  HELIUM_DESKTOP_SRC=${HELIUM_DESKTOP_SRC:-/usr/share/applications/helium-browser.desktop}
  HELIUM_DESKTOP="$HOME/.local/share/applications/helium-browser.desktop"

  backup_if_present "$HELIUM_WRAPPER" local-bin/omarchy-launch-helium
  run_cmd "Creating wrapper $HELIUM_WRAPPER" mkdir -p "$(dirname -- "$HELIUM_WRAPPER")"
  if ! _dry_run; then
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
  fi

  backup_if_present "$HELIUM_FLAGS" helium-browser-flags.conf
  run_cmd "Creating flags file $HELIUM_FLAGS" mkdir -p "$(dirname -- "$HELIUM_FLAGS")"
  if ! _dry_run; then
    cat > "$HELIUM_FLAGS" <<'FLAGS'
--ozone-platform=wayland
--ozone-platform-hint=wayland
--password-store=gnome-libsecret
--enable-features=TouchpadOverscrollHistoryNavigation
FLAGS
    printf 'Installed %s\n' "$HELIUM_FLAGS"
  fi

  if [[ -r $HELIUM_DESKTOP_SRC ]]; then
    backup_if_present "$HELIUM_DESKTOP" applications/helium-browser.desktop
    run_cmd "Creating desktop override $HELIUM_DESKTOP" mkdir -p "$(dirname -- "$HELIUM_DESKTOP")"
    if ! _dry_run; then
      sed -E "s#^Exec=(/usr/bin/)?(helium-browser|chromium)#Exec=$HELIUM_WRAPPER#" "$HELIUM_DESKTOP_SRC" > "$HELIUM_DESKTOP"
      if grep -qF "Exec=$HELIUM_WRAPPER" "$HELIUM_DESKTOP"; then
        printf 'Installed %s\n' "$HELIUM_DESKTOP"
      else
        warn "no Exec line was rewritten in $HELIUM_DESKTOP; launchers may skip the wrapper."
      fi
      if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$(dirname -- "$HELIUM_DESKTOP")" || true
      fi
    fi
  else
    warn "$HELIUM_DESKTOP_SRC not found; skipped the desktop entry override."
  fi

  # Set Helium as the default browser (multiple methods for compatibility).
  run_cmd 'Setting Helium as default browser' true
  browser="helium-browser.desktop"
  success=0

  # Method 1: xdg-settings (standard)
  if command -v xdg-settings >/dev/null 2>&1; then
    run_cmd "xdg-settings set default-web-browser $browser" xdg-settings set default-web-browser "$browser" && success=1 || true
  fi

  # Method 2: gio mime (GNOME/GTK apps)
  if command -v gio >/dev/null 2>&1; then
    run_cmd "gio mime x-scheme-handler/http $browser" gio mime x-scheme-handler/http "$browser" 2>/dev/null && success=1 || true
    run_cmd "gio mime x-scheme-handler/https $browser" gio mime x-scheme-handler/https "$browser" 2>/dev/null && success=1 || true
    run_cmd "gio mime text/html $browser" gio mime text/html "$browser" 2>/dev/null && success=1 || true
  fi

  # Method 3: xdg-mime (freedesktop standard)
  if command -v xdg-mime >/dev/null 2>&1; then
    run_cmd "xdg-mime default $browser x-scheme-handler/http" xdg-mime default "$browser" x-scheme-handler/http 2>/dev/null && success=1 || true
    run_cmd "xdg-mime default $browser x-scheme-handler/https" xdg-mime default "$browser" x-scheme-handler/https 2>/dev/null && success=1 || true
    run_cmd "xdg-mime default $browser text/html" xdg-mime default "$browser" text/html 2>/dev/null && success=1 || true
    run_cmd "xdg-mime default $browser application/xhtml+xml" xdg-mime default "$browser" application/xhtml+xml 2>/dev/null && success=1 || true
  fi

  # Refresh desktop database
  if command -v update-desktop-database >/dev/null 2>&1; then
    run_cmd "Refreshing desktop database" update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  fi

  if ((success)); then
    printf 'Default browser set to Helium.\n'
  else
    warn 'could not set Helium as default browser (no suitable tool found).'
  fi
else
  printf '\nHelium is not installed; skipping the hardware acceleration fix and default browser setup.\n'
fi