#!/usr/bin/env bash
# Omarchy setup orchestrator.
#
# Layout:
#   lib/common.bash   shared helpers (errors, retries, backups)
#   steps/NN-*.bash   one file per setup step, run in filename order
#   config/           mirrors ~/.config; every file here is installed (with backup)
#   wallpapers/       copied into ~/.config/omarchy/backgrounds/catppuccin/
#   packages.toml     pacman / AUR package manifest
#
# Adding a config file = drop it under config/ (e.g. config/foo/bar.conf -> ~/.config/foo/bar.conf).
# Adding a step      = add steps/NN-name.bash; it is picked up automatically.
set -Eeuo pipefail

INSTALLER_NAME=omarchy-setup
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-setup/backups"

# Dry-run mode: set DRY_RUN=1 to preview changes without making them.
# Example: DRY_RUN=1 ./setup.bash
DRY_RUN=${DRY_RUN:-0}

# Filename from wallpapers/ to use as the desktop background after setup.
# Defaults to 139396752_p0.jpg; override it to use a different image.
# Example: WALLPAPER_IMAGE=tree.jpg ./setup.bash
WALLPAPER_IMAGE=${WALLPAPER_IMAGE:-139396752_p0.jpg}

fatal() { printf 'Error: %s\n' "$*" >&2; exit 1; }
[[ -f ${BASH_SOURCE[0]} ]] || fatal 'Could not locate installer files. Download and extract the repository first.'
REPO_DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
[[ -r $REPO_DIR/lib/common.bash ]] || fatal "Missing $REPO_DIR/lib/common.bash; the repository looks incomplete."

# shellcheck source=lib/common.bash
source "$REPO_DIR/lib/common.bash"

shopt -s nullglob
STEP_FILES=("$REPO_DIR"/steps/*.bash)
shopt -u nullglob
((${#STEP_FILES[@]})) || die "No step files found in $REPO_DIR/steps"

for step_file in "${STEP_FILES[@]}"; do
  CURRENT_STEP=${step_file##*/}
  # shellcheck source=/dev/null
  source "$step_file"
done
