# shellcheck shell=bash
# PHASE: Browser
# ABOUT: Applies the Helium hardware video acceleration fix (launcher wrapper, flags, desktop entry) and sets Helium as the default browser.
# Adapted from docs/omarchy-chromium-hardware-acceleration-fix.md (that note targets Brave).
# The wrapper forces Mesa EGL and the right VA-API driver; the desktop-entry override makes
# launchers use it. Skipped if Helium is not installed.

if command -v helium-browser >/dev/null 2>&1; then
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
  ok "Installed $HELIUM_WRAPPER"

  backup_if_present "$HELIUM_FLAGS" helium-browser-flags.conf
  mkdir -p "$(dirname -- "$HELIUM_FLAGS")"
  cat > "$HELIUM_FLAGS" <<'FLAGS'
--ozone-platform=wayland
--ozone-platform-hint=wayland
--password-store=gnome-libsecret
--enable-features=TouchpadOverscrollHistoryNavigation
FLAGS
  ok "Installed $HELIUM_FLAGS"

  if [[ -r $HELIUM_DESKTOP_SRC ]]; then
    backup_if_present "$HELIUM_DESKTOP" applications/helium-browser.desktop
    mkdir -p "$(dirname -- "$HELIUM_DESKTOP")"
    sed -E "s#^Exec=(/usr/bin/)?(helium-browser|chromium)#Exec=$HELIUM_WRAPPER#" "$HELIUM_DESKTOP_SRC" > "$HELIUM_DESKTOP"
    if grep -qF "Exec=$HELIUM_WRAPPER" "$HELIUM_DESKTOP"; then
      ok "Installed $HELIUM_DESKTOP"
    else
      warn "no Exec line was rewritten in $HELIUM_DESKTOP; launchers may skip the wrapper."
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$(dirname -- "$HELIUM_DESKTOP")" || true
    fi
  else
    warn "$HELIUM_DESKTOP_SRC not found; skipped the desktop entry override."
  fi

  # Set Helium as the default browser.
  if command -v xdg-settings >/dev/null 2>&1; then
    if xdg-settings set default-web-browser helium-browser.desktop; then
      ok 'Default browser set to Helium (helium-browser.desktop)'
    else
      warn 'could not set Helium as the default browser.'
    fi
  else
    warn 'xdg-settings not found; could not set Helium as the default browser.'
  fi
else
  skip 'Helium is not installed; skipping the hardware acceleration fix and default browser setup'
fi
