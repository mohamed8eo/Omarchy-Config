#!/usr/bin/env bash
# Omarchy setup orchestrator.
#
# Layout:
#   lib/ui.bash       terminal output (banner, phases, status lines)
#   lib/common.bash   shared helpers (sudo, errors, retries, backups)
#   steps/NN-*.bash   one file per setup phase, run in filename order
#   config/           mirrors ~/.config; every file here is installed (with backup)
#   wallpapers/       copied into ~/.config/omarchy/backgrounds/catppuccin/
#   packages.toml     pacman / AUR package manifest
#
# Adding a config file = drop it under config/ (e.g. config/foo/bar.conf -> ~/.config/foo/bar.conf).
# Adding a phase     = add steps/NN-name.bash with a metadata header (see below); it is picked up
#                      automatically, announced when it starts, and listed in the plan.
#
# Step metadata (comment lines at the top of each steps/*.bash file):
#   # PHASE: Short title shown in the progress header and the plan
#   # ABOUT: One line describing what the phase does (repeat the line for more text)
#   # PLAN: hide        (optional) leave the phase out of the plan list
set -Eeuo pipefail

INSTALLER_NAME=omarchy-setup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-setup"
BACKUP_ROOT="$STATE_DIR/backups"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
LOG_FILE="$STATE_DIR/logs/setup-$TIMESTAMP.log"
mkdir -p "$STATE_DIR/logs" 2>/dev/null || LOG_FILE=/dev/null

# Filename from wallpapers/ to use as the desktop background after setup.
# Defaults to 139396752_p0.jpg; override it to use a different image.
# Example: WALLPAPER_IMAGE=tree.jpg ./setup.bash
WALLPAPER_IMAGE=${WALLPAPER_IMAGE:-139396752_p0.jpg}

fatal() { printf ' [ERROR ] %s\n' "$*" >&2; exit 1; }
[[ -f ${BASH_SOURCE[0]} ]] || fatal 'Could not locate installer files. Download and extract the repository first.'
REPO_DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
for lib_file in ui common; do
  [[ -r $REPO_DIR/lib/$lib_file.bash ]] || fatal "Missing $REPO_DIR/lib/$lib_file.bash; the repository looks incomplete."
done

# shellcheck source=lib/ui.bash
source "$REPO_DIR/lib/ui.bash"
# shellcheck source=lib/common.bash
source "$REPO_DIR/lib/common.bash"

shopt -s nullglob
STEP_FILES=("$REPO_DIR"/steps/*.bash)
shopt -u nullglob
((${#STEP_FILES[@]})) || die "No step files found in $REPO_DIR/steps"

# step_meta <file> <KEY>: print the value of every "# KEY: value" header line.
step_meta() { sed -n "s/^# $2: *//p" "$1"; }

# Read the metadata of every step up front so the plan and the progress counter agree.
PHASE_TITLES=()
PHASE_ABOUTS=()
PHASE_HIDDEN=()
for step_file in "${STEP_FILES[@]}"; do
  title=$(step_meta "$step_file" PHASE)
  PHASE_TITLES+=("${title:-$(basename -- "$step_file" .bash)}")
  PHASE_ABOUTS+=("$(step_meta "$step_file" ABOUT | paste -sd' ' -)")
  PHASE_HIDDEN+=("$(step_meta "$step_file" PLAN)")
done
PHASE_TOTAL=${#STEP_FILES[@]}

ui_banner 'Omarchy Setup' "Automated post-install configuration  |  log: $LOG_FILE"

for index in "${!STEP_FILES[@]}"; do
  step_file=${STEP_FILES[$index]}
  CURRENT_STEP=${step_file##*/}
  mapfile -t about_lines < <(step_meta "$step_file" ABOUT)
  phase "${PHASE_TITLES[$index]}" "${about_lines[@]}"
  # shellcheck source=/dev/null
  source "$step_file"
done
