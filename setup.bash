#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_NAME=omarchy-setup
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-setup/backups"

# Filename from images/ to use as the desktop background after setup.
# Defaults to 139396752_p0.jpg; override it to use a different image.
# Example: WALLPAPER_IMAGE=tree.jpg ./setup.bash
WALLPAPER_IMAGE=${WALLPAPER_IMAGE:-139396752_p0.jpg}
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
on_error() {
  local status=$?
  printf '\n%s failed at line %s (exit %s). No later steps were run.\n' "$INSTALLER_NAME" "$1" "$status" >&2
  printf 'Any file backups are under: %s\n' "$BACKUP_ROOT" >&2
  exit "$status"
}
trap 'on_error "$LINENO"' ERR

[[ $EUID -ne 0 ]] || die 'Run as your normal user, not with sudo.'
command -v omarchy >/dev/null || die 'Omarchy was not found; this installer requires Omarchy.'
command -v python3 >/dev/null || die 'python3 is required to read packages.toml.'
[[ -r /dev/tty ]] || die 'An interactive terminal is required for the preview, update, and shell change.'
[[ -f ${BASH_SOURCE[0]} ]] || die 'Could not locate installer files. Download and extract the repository first.'
REPO_DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
for required in hypr images starship.toml tmux.conf packages.toml; do
  [[ -e $REPO_DIR/$required ]] || die "Required repo entry is missing: $required"
done
[[ $WALLPAPER_IMAGE != */* ]] || die 'WALLPAPER_IMAGE must be a filename from images/, not a path.'
[[ -f $REPO_DIR/images/$WALLPAPER_IMAGE ]] || die "WALLPAPER_IMAGE not found in images/: $WALLPAPER_IMAGE"

PACKAGE_DATA=$(python3 - "$REPO_DIR/packages.toml" <<'PY'
import sys, tomllib
with open(sys.argv[1], 'rb') as f:
    manifest = tomllib.load(f)
for section in ('pacman', 'aur'):
    packages = manifest.get(section, [])
    if not isinstance(packages, list) or any(not isinstance(p, str) or not p.strip() for p in packages):
        raise SystemExit(f'packages.toml: {section} must be an array of non-empty package names')
    for package in packages:
        if any(c.isspace() for c in package) or package.startswith('-'):
            raise SystemExit(f'packages.toml: invalid package name {package!r}')
        print(f'{section}\t{package}')
PY
) || die 'Could not parse packages.toml.'
PACMAN_PACKAGES=()
AUR_PACKAGES=()
while IFS=$'\t' read -r kind package; do
  [[ -n ${kind:-} ]] || continue
  case $kind in
    pacman) PACMAN_PACKAGES+=("$package") ;;
    aur) AUR_PACKAGES+=("$package") ;;
    *) die "Unknown package category: $kind" ;;
  esac
done <<< "$PACKAGE_DATA"

printf 'Plan:\n'
printf '  Run omarchy update first (skipped with a warning if it fails)\n'
printf '  Install dev environments: Node.js, Go, Python, Rust (omarchy install dev-env)\n'
printf '  Install Codex (omarchy install ai chatgpt)\n'
printf '  Install Ghostty (omarchy install terminal ghostty) and make it the default terminal\n'
printf '  Apply the Helium hardware video acceleration fix (launcher wrapper, flags, desktop entry) and set Helium as the default browser\n'
printf '  Install packages listed in packages.toml and omarchy-fish\n'
printf '  Set Fish as this user’s login shell\n'
printf '  Set the Catppuccin theme and copy repo images\n'
printf '  Set the desktop background to images/%s\n' "$WALLPAPER_IMAGE"
printf '  Install Neovim config from mohamed8eo/nvim_config (backs up ~/.config/nvim to ~/.config/nvim-bak)\n'
printf '  Create ~/personal and clone ThePrimeagen/harpoon and ThePrimeagen/99 into it\n'
printf '  Remove these web app launchers if present: Google Contacts, Google Maps, Google Messages, Google Photos, HEY, X, Zoom, Basecamp\n'
printf '  Install Omarchy plugins at the end: lock-designs, omarchy-spotlight, VoxType OSD, island (and switch the bar to island)\n'
printf '  Replace these files (existing targets will be backed up first):\n'
find "$REPO_DIR/hypr" -maxdepth 1 -type f -printf '    ~/.config/hypr/%f\n' | sort
printf '    ~/.config/starship.toml\n    ~/.config/tmux/tmux.conf\n'
find "$REPO_DIR/images" -maxdepth 1 -type f -printf '    ~/.config/omarchy/backgrounds/catppuccin/%f\n' | sort
printf '  Pacman: %s\n' "${PACMAN_PACKAGES[*]:-(none listed)}"
printf '  AUR:    %s\n' "${AUR_PACKAGES[*]:-(none listed)}"
read -r -p 'Continue? [y/N] ' answer </dev/tty
[[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { printf 'Cancelled.\n'; exit 0; }

printf '\nRunning omarchy update...\n'
if ! omarchy update </dev/tty; then
  printf '\nWarning: omarchy update failed; skipping it and continuing.\n' >&2
fi

# Node goes first: the Codex launcher needs the mise-managed Node.
install_dev_env() {
  local name=$1 tool=$2
  if mise where "$tool" >/dev/null 2>&1; then
    printf 'Skipping %s (already installed via mise).\n' "$name"
  else
    printf '\nInstalling %s...\n' "$name"
    omarchy install dev-env "$name" </dev/tty
  fi
}
install_dev_env node node
install_dev_env go go
install_dev_env python python
if command -v rustc >/dev/null || mise where rust >/dev/null 2>&1; then
  printf 'Skipping rust (already installed).\n'
else
  printf '\nInstalling rust...\n'
  omarchy install dev-env rust </dev/tty
fi

printf '\nInstalling Codex...\n'
omarchy install ai chatgpt </dev/tty

if ((${#PACMAN_PACKAGES[@]})); then omarchy pkg add "${PACMAN_PACKAGES[@]}" </dev/tty; fi
if [[ " ${AUR_PACKAGES[*]:-} " == *" helium-browser-bin "* ]]; then
  # The AUR package verifies Helium's PGP signature, so its signing key must be known.
  printf '\nImporting Helium signing key...\n'
  if ! gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys BE677C1989D35EAB2C5F26C9351601AD01D6378E </dev/tty; then
    printf 'Warning: could not import the Helium signing key; the Helium install may fail.\n' >&2
  fi
fi
if ((${#AUR_PACKAGES[@]})); then omarchy pkg aur add "${AUR_PACKAGES[@]}" </dev/tty; fi
omarchy pkg add omarchy-fish </dev/tty

FISH_PATH=$(command -v fish) || die 'Fish was not found after installing omarchy-fish.'
FISH_PATH=$(realpath -- "$FISH_PATH")
grep -Fxq "$FISH_PATH" /etc/shells || die "$FISH_PATH is not in /etc/shells; add it, then rerun the installer."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ $CURRENT_SHELL != "$FISH_PATH" ]]; then chsh -s "$FISH_PATH" "$USER" </dev/tty; fi

omarchy theme set catppuccin </dev/tty

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
backup_if_present() {
  local target=$1 relative=$2
  if [[ -d $target ]]; then
    die "Destination is a directory, expected a file: $target"
  fi
  if [[ -e $target || -L $target ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
    cp -a -- "$target" "$BACKUP_DIR/$relative"
    printf 'Backed up %s\n' "$target"
  fi
}
copy_file() {
  local source=$1 target=$2 relative=$3
  backup_if_present "$target" "$relative"
  mkdir -p "$(dirname -- "$target")"
  cp --remove-destination -f -- "$source" "$target"
  printf 'Installed %s\n' "$target"
}

printf 'Applying configuration files...\n'
while IFS= read -r -d '' source; do
  name=$(basename -- "$source")
  copy_file "$source" "$HOME/.config/hypr/$name" "hypr/$name"
done < <(find "$REPO_DIR/hypr" -maxdepth 1 -type f -print0)

copy_file "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml" starship.toml
copy_file "$REPO_DIR/tmux.conf" "$HOME/.config/tmux/tmux.conf" tmux.conf
while IFS= read -r -d '' source; do
  name=$(basename -- "$source")
  copy_file "$source" "$HOME/.config/omarchy/backgrounds/catppuccin/$name" "images/$name"
done < <(find "$REPO_DIR/images" -maxdepth 1 -type f -print0)

WALLPAPER_PATH="$HOME/.config/omarchy/backgrounds/catppuccin/$WALLPAPER_IMAGE"
printf '\nSetting desktop background to %s...\n' "$WALLPAPER_IMAGE"
if omarchy theme bg set "$WALLPAPER_PATH" </dev/tty; then
  printf 'Desktop background set to %s.\n' "$WALLPAPER_PATH"
else
  printf 'Warning: could not set the desktop background to %s; continuing.\n' "$WALLPAPER_PATH" >&2
fi

# Neovim config from mohamed8eo/nvim_config.
# Backs up the current ~/.config/nvim to ~/.config/nvim-bak, clones the repo, and installs it.
printf '\nInstalling Neovim config...\n'
if command -v git >/dev/null 2>&1; then
  NVIM_CONFIG_DIR="$HOME/.config/nvim"
  NVIM_BACKUP_DIR="$HOME/.config/nvim-bak"
  NVIM_TMP_DIR=$(mktemp -d)
  if git clone --depth 1 https://github.com/mohamed8eo/nvim_config.git "$NVIM_TMP_DIR/nvim" </dev/tty; then
    if [[ -e $NVIM_CONFIG_DIR || -L $NVIM_CONFIG_DIR ]]; then
      rm -rf -- "$NVIM_BACKUP_DIR"
      mv -- "$NVIM_CONFIG_DIR" "$NVIM_BACKUP_DIR"
      printf 'Backed up %s to %s\n' "$NVIM_CONFIG_DIR" "$NVIM_BACKUP_DIR"
    fi
    mkdir -p "$(dirname -- "$NVIM_CONFIG_DIR")"
    cp -a -- "$NVIM_TMP_DIR/nvim" "$NVIM_CONFIG_DIR"
    rm -rf -- "$NVIM_CONFIG_DIR/.git"
    printf 'Installed Neovim config at %s\n' "$NVIM_CONFIG_DIR"
  else
    printf 'Warning: failed to clone mohamed8eo/nvim_config; skipping Neovim config install.\n' >&2
  fi
  rm -rf -- "$NVIM_TMP_DIR"
else
  printf 'Warning: git not found; skipping Neovim config install.\n' >&2
fi

# Personal repos.
printf '\nSetting up ~/personal repos...\n'
if command -v git >/dev/null 2>&1; then
  PERSONAL_DIR="$HOME/personal"
  mkdir -p "$PERSONAL_DIR"
  for repo in harpoon 99; do
    target="$PERSONAL_DIR/$repo"
    if [[ -e $target ]]; then
      printf 'Personal repo already present, skipping: %s\n' "$target"
    elif git clone --depth 1 "https://github.com/ThePrimeagen/$repo.git" "$target" </dev/tty; then
      printf 'Cloned %s\n' "$target"
    else
      printf 'Warning: failed to clone ThePrimeagen/%s; continuing.\n' "$repo" >&2
    fi
  done
else
  printf 'Warning: git not found; skipping ~/personal repos.\n' >&2
fi


# Helium hardware video decode fix, adapted from omarchy-chromium-hardware-acceleration-fix.md
# (that note targets Brave). The wrapper forces Mesa EGL and the right VA-API driver; the
# desktop-entry override makes launchers use it. Skipped if Helium is not installed.
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
      printf 'Warning: no Exec line was rewritten in %s; launchers may skip the wrapper.\n' "$HELIUM_DESKTOP" >&2
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$(dirname -- "$HELIUM_DESKTOP")" || true
    fi
  else
    printf 'Warning: %s not found; skipped the desktop entry override.\n' "$HELIUM_DESKTOP_SRC" >&2
  fi

  # Set Helium as the default browser.
  if command -v xdg-settings >/dev/null 2>&1; then
    if xdg-settings set default-web-browser helium-browser.desktop; then
      printf 'Default browser set to Helium (helium-browser.desktop).\n'
    else
      printf 'Warning: could not set Helium as the default browser.\n' >&2
    fi
  else
    printf 'Warning: xdg-settings not found; could not set Helium as the default browser.\n' >&2
  fi
else
  printf '\nHelium is not installed; skipping the hardware acceleration fix and default browser setup.\n'
fi

# Ghostty as the default terminal. Omarchy launches terminals through xdg-terminal-exec,
# which uses the first entry of ~/.config/xdg-terminals.list.
printf '\nInstalling Ghostty...\n'
if ! omarchy install terminal ghostty </dev/tty; then
  printf 'Warning: "omarchy install terminal ghostty" failed; continuing.\n' >&2
fi
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
GHOSTTY_DESKTOP=com.mitchellh.ghostty.desktop
if [[ $(head -n 1 "$XDG_TERMINALS" 2>/dev/null || true) != "$GHOSTTY_DESKTOP" ]]; then
  backup_if_present "$XDG_TERMINALS" xdg-terminals.list
  mkdir -p "$(dirname -- "$XDG_TERMINALS")"
  XDG_TMP=$(mktemp)
  { printf '%s\n' "$GHOSTTY_DESKTOP"; grep -vFx -- "$GHOSTTY_DESKTOP" "$XDG_TERMINALS" 2>/dev/null || true; } > "$XDG_TMP"
  mv -- "$XDG_TMP" "$XDG_TERMINALS"
fi
printf 'Default terminal: Ghostty (%s)\n' "$XDG_TERMINALS"

# Remove web app launchers you don't want. Only launchers that exist are removed.
WEBAPPS_TO_REMOVE=("Google Contacts" "Google Maps" "Google Messages" "Google Photos" "HEY" "X" "Zoom" "Basecamp")
WEBAPP_DIR="$HOME/.local/share/applications"
printf '\nRemoving unwanted web apps...\n'
for webapp in "${WEBAPPS_TO_REMOVE[@]}"; do
  if [[ -f $WEBAPP_DIR/$webapp.desktop ]]; then
    if omarchy webapp remove "$webapp"; then
      printf 'Removed web app: %s\n' "$webapp"
    else
      printf 'Warning: could not remove web app "%s"; continuing.\n' "$webapp" >&2
    fi
  else
    printf 'Web app not installed, skipping: %s\n' "$webapp"
  fi
done

# Omarchy plugins. A failing plugin is reported and skipped; it never stops the setup.
FAILED_PLUGINS=()
run_optional() {
  local label=$1; shift
  printf '\n%s...\n' "$label"
  if ! "$@" </dev/tty; then
    printf 'Warning: "%s" failed; continuing.\n' "$label" >&2
    FAILED_PLUGINS+=("$label")
    return 1
  fi
}


printf '\nInstalling Omarchy plugins...\n'

# QyLock - Themed lock screen and live backgrounds
if run_optional 'qylock-oma' omarchy plugin add https://github.com/mjtiempo/qylock-oma.git --enable --yes; then
  run_optional 'QyLock sync' omarchy-shell mark.lock-themes sync || true
fi

run_optional 'omarchy-spotlight' omarchy plugin add https://github.com/maajix/omarchy-spotlight.git --enable || true

if run_optional 'island plugin' omarchy plugin add https://github.com/mohamed8eo/island.git; then
  run_optional 'island bar' omarchy bar use guilhermerisu.island || true
fi

# Restart Omarchy shell to load QyLock and other plugins
omarchy restart shell

printf '\nSetup complete. Backups: %s\nFish is now the configured login shell; open a new login session to use it.\n' "$BACKUP_DIR"
if ((${#FAILED_PLUGINS[@]})); then printf 'These plugin steps failed and were skipped: %s\n' "${FAILED_PLUGINS[*]}" >&2; fi
