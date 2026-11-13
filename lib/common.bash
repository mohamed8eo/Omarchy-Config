# shellcheck shell=bash
# Shared helpers for setup.bash and steps/*.bash. This file is sourced, never executed.
# Expects INSTALLER_NAME, BACKUP_ROOT, REPO_DIR and DRY_RUN to be set by setup.bash first.

# ---- Shared state ---------------------------------------------------------
CURRENT_STEP=init          # name of the step file being run (shown if something fails)
WARNINGS=()                # non-fatal problems, listed in the final summary
FAILED_PLUGINS=()          # plugin steps that failed and were skipped
LOGIN_SHELL_OK=0           # set to 1 once Fish is the login shell
TMP_PATHS=()               # temp files/dirs removed on exit

# Files under config/ (path relative to config/) that keep a "<file>-bak" copy of the
# user's original next to them on the first run, in addition to the timestamped backup.
SIBLING_BACKUP_FILES=("ghostty/config")

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# ---- Dry-run helpers -------------------------------------------------------
# In dry-run mode, print what would happen without making changes.
_dry_run() { ((DRY_RUN)); }

_dry() {
  _dry_run || return 0
  local fmt=$1
  shift
  printf '[DRY-RUN] '"$fmt"'\n' "$@" >&2
}

# ---- Messages -------------------------------------------------------------
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'Warning: %s\n' "$*" >&2; WARNINGS+=("$*"); }

# ---- Error handling -------------------------------------------------------
# retry <attempts> <command...>: rerun a flaky (network) command before giving up.
retry() {
  local attempts=$1 n
  shift
  for ((n = 1; n <= attempts; n++)); do
    if "$@"; then return 0; fi
    if ((n < attempts)); then
      printf 'Attempt %d/%d failed; retrying in 3s...\n' "$n" "$attempts" >&2
      sleep 3
    fi
  done
  return 1
}

# Temp files/dirs added to TMP_PATHS are removed on any exit (success, error, Ctrl+C).
cleanup() {
  local path
  for path in "${TMP_PATHS[@]:-}"; do
    [[ -z $path ]] || rm -rf -- "$path"
  done
}

on_error() {
  local status=$? line=$1 failed_cmd=$2 source_file=${3:-setup.bash}
  printf '\n%s failed (exit %s).\n' "$INSTALLER_NAME" "$status" >&2
  printf '  Step:           %s\n' "$CURRENT_STEP" >&2
  printf '  Location:       %s:%s\n' "${source_file##*/}" "$line" >&2
  printf '  Failed command: %s\n' "$failed_cmd" >&2
  printf 'No later steps were run. Fix the problem above and re-run ./setup.bash.\n' >&2
  printf 'Any file backups are under: %s\n' "$BACKUP_ROOT" >&2
  exit "$status"
}

trap cleanup EXIT
trap 'printf "\n%s interrupted.\n" "$INSTALLER_NAME" >&2; exit 130' INT TERM
trap 'on_error "$LINENO" "$BASH_COMMAND" "${BASH_SOURCE[0]:-}"' ERR

# ---- File helpers ---------------------------------------------------------
# backup_if_present <target> <relative-path-inside-backup-dir>
backup_if_present() {
  local target=$1 relative=$2
  _dry_run && { _dry "Would backup %s to %s/%s" "$target" "$BACKUP_DIR" "$relative"; return; }
  if [[ -d $target ]]; then
    die "Destination is a directory, expected a file: $target"
  fi
  if [[ -e $target || -L $target ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
    cp -a -- "$target" "$BACKUP_DIR/$relative"
    printf 'Backed up %s\n' "$target"
  fi
}

# copy_file <source> <target> <relative-path-inside-backup-dir>
copy_file() {
  local source=$1 target=$2 relative=$3
  _dry_run && { _dry "Would copy %s -> %s (backup: %s)" "$source" "$target" "$relative"; return; }
  backup_if_present "$target" "$relative"
  mkdir -p "$(dirname -- "$target")"
  cp --remove-destination -f -- "$source" "$target"
  printf 'Installed %s\n' "$target"
}

# Like copy_file, but the first run moves the original to "<target>-bak".
# If "<target>-bak" already exists it is kept (so re-running never loses your original)
# and the current file goes to the timestamped backup dir instead.
copy_file_with_sibling_backup() {
  local source=$1 target=$2 relative=$3
  local bak="$target-bak"
  _dry_run && { _dry "Would copy %s -> %s with sibling backup (bak: %s)" "$source" "$target" "$bak"; return; }
  [[ ! -d $target ]] || die "Destination is a directory, expected a file: $target"
  mkdir -p "$(dirname -- "$target")"
  if [[ -e $target || -L $target ]]; then
    if [[ -e $bak || -L $bak ]]; then
      backup_if_present "$target" "$relative"
    else
      mv -- "$target" "$bak"
      printf 'Backed up %s to %s\n' "$target" "$bak"
    fi
  fi
  cp --remove-destination -f -- "$source" "$target"
  printf 'Installed %s\n' "$target"
}

# run_cmd <description> <command...>
# In dry-run: prints what would run. In normal: executes.
run_cmd() {
  local desc=$1
  shift
  _dry_run && { _dry "%s: %s" "$desc" "$*"; return; }
  printf '%s...\n' "$desc"
  "$@"
}

# ---- Optional steps -------------------------------------------------------
# run_optional <label> <command...>: a failure is reported and skipped, never fatal.
run_optional() {
  local label=$1
  shift
  if _dry_run; then
    _dry 'Optional step: %s (command: %s)' "$label" "$*"
    return 0
  fi
  printf '\n%s...\n' "$label"
  if ! "$@" </dev/tty; then
    printf 'Warning: "%s" failed; continuing.\n' "$label" >&2
    FAILED_PLUGINS+=("$label")
    return 1
  fi
}
