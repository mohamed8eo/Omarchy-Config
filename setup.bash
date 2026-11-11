#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_NAME=omarchy-setup
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-setup/backups"
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
printf '  Install packages listed in packages.toml and omarchy-fish\n'
printf '  Set Fish as this user’s login shell\n'
printf '  Set the Catppuccin theme and copy repo images\n'
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
run_optional 'lock-designs' omarchy plugin add https://github.com/SmoothPixels/lock-designs.git --enable || true
run_optional 'omarchy-spotlight' omarchy plugin add https://github.com/maajix/omarchy-spotlight.git --enable || true
if run_optional 'VoxType OSD' omarchy plugin add https://github.com/Blizl/Omarchy-VoxType-OSD.git --enable; then
  run_optional 'VoxType OSD setup' "$HOME/.config/omarchy/plugins/blizl.voxtype-osd/bin/setup" || true
fi
if run_optional 'island plugin' omarchy plugin add https://github.com/Guilhermerisu/island.git; then
  run_optional 'island bar' omarchy bar use guilhermerisu.island || true
fi

printf '\nSetup complete. Backups: %s\nFish is now the configured login shell; open a new login session to use it.\n' "$BACKUP_DIR"
if ((${#FAILED_PLUGINS[@]})); then printf 'These plugin steps failed and were skipped: %s\n' "${FAILED_PLUGINS[*]}" >&2; fi
