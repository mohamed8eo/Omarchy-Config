# shellcheck shell=bash
# Shared helpers for setup.bash and steps/*.bash. This file is sourced, never executed.
# Expects INSTALLER_NAME, BACKUP_ROOT, BACKUP_DIR, LOG_FILE and REPO_DIR from setup.bash,
# and lib/ui.bash to be loaded first.

# ---- Shared state ---------------------------------------------------------
CURRENT_STEP=init          # step file being run (shown if something fails)
FAILED_PLUGINS=()          # plugin steps that failed and were skipped
LOGIN_SHELL_OK=0           # set to 1 once Fish is the login shell
TMP_PATHS=()               # temp files/dirs removed on exit
SUDO_KEEPALIVE_PID=''
SUDO_PRIMED_BY_US=0

# Files under config/ (path relative to config/) that keep a "<file>-bak" copy of the
# user's original next to them on the first run, in addition to the timestamped backup.
SIBLING_BACKUP_FILES=("ghostty/config")

# ---- sudo -----------------------------------------------------------------
# The password is asked for once (sudo -v) and sudo's own timestamp cache is kept alive in the
# background, so every later sudo call (omarchy, pacman, chsh...) runs without a prompt.
# The password itself is never read, stored or logged by this script.
start_sudo_keepalive() {
  ( while sudo -n true 2>/dev/null; do
      sleep 50
      kill -0 "$$" 2>/dev/null || exit 0
    done ) >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
  if [[ -n $SUDO_KEEPALIVE_PID ]]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=''
  fi
  # Forget the credential again, but only if this script was the one that asked for it.
  if ((SUDO_PRIMED_BY_US)); then
    sudo -k 2>/dev/null || true
    SUDO_PRIMED_BY_US=0
  fi
}

sudo_authenticate() {
  command -v sudo >/dev/null 2>&1 || die 'sudo is required but was not found.'
  if sudo -n true 2>/dev/null; then
    ok 'Administrator access is already available.'
  else
    info 'Enter your password once. It is cached for this setup only and never stored.'
    sudo -v </dev/tty || die 'Could not obtain administrator access (sudo authentication failed).'
    SUDO_PRIMED_BY_US=1
  fi
  start_sudo_keepalive
  ok 'Administrator access granted; it stays active until the setup ends.'
}

# ---- Error handling -------------------------------------------------------
# retry <attempts> <command...>: rerun a flaky (network) command before giving up.
retry() {
  local attempts=$1 n
  shift
  for ((n = 1; n <= attempts; n++)); do
    if "$@"; then return 0; fi
    if ((n < attempts)); then
      note "Attempt $n of $attempts failed; retrying in 3 seconds..."
      sleep 3
    fi
  done
  return 1
}

# Runs on every exit (success, error, Ctrl+C): stop sudo keep-alive, remove temp files.
cleanup() {
  local path
  stop_sudo_keepalive
  for path in "${TMP_PATHS[@]:-}"; do
    [[ -z $path ]] || rm -rf -- "$path"
  done
}

on_error() {
  local status=$? line=$1 failed_cmd=$2 source_file=${3:-setup.bash}
  printf '\n' >&2
  err 'Setup stopped because a command failed.'
  err_detail Phase "[$PHASE_INDEX/$PHASE_TOTAL] $PHASE_TITLE"
  err_detail Where "${source_file##*/}:$line"
  err_detail Command "$failed_cmd"
  err_detail Exit "$status"
  err_detail Backups "$BACKUP_ROOT"
  err_detail Log "$LOG_FILE"
  err_detail Next 'Fix the problem above, then re-run ./setup.bash.'
  exit "$status"
}

trap cleanup EXIT
trap 'printf "\n" >&2; note "$INSTALLER_NAME was interrupted."; exit 130' INT TERM
trap 'on_error "$LINENO" "$BASH_COMMAND" "${BASH_SOURCE[0]:-}"' ERR

# ---- File helpers ---------------------------------------------------------
# backup_if_present <target> <relative-path-inside-backup-dir>
backup_if_present() {
  local target=$1 relative=$2
  if [[ -d $target ]]; then
    die "Destination is a directory, expected a file: $target"
  fi
  if [[ -e $target || -L $target ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
    cp -a -- "$target" "$BACKUP_DIR/$relative"
    info "Backed up $target"
  fi
}

# copy_file <source> <target> <relative-path-inside-backup-dir>
copy_file() {
  local source=$1 target=$2 relative=$3
  backup_if_present "$target" "$relative"
  mkdir -p "$(dirname -- "$target")"
  cp --remove-destination -f -- "$source" "$target"
  ok "Installed $target"
}

# Like copy_file, but the first run moves the original to "<target>-bak".
# If "<target>-bak" already exists it is kept (so re-running never loses your original)
# and the current file goes to the timestamped backup dir instead.
copy_file_with_sibling_backup() {
  local source=$1 target=$2 relative=$3
  local bak="$target-bak"
  [[ ! -d $target ]] || die "Destination is a directory, expected a file: $target"
  mkdir -p "$(dirname -- "$target")"
  if [[ -e $target || -L $target ]]; then
    if [[ -e $bak || -L $bak ]]; then
      backup_if_present "$target" "$relative"
    else
      mv -- "$target" "$bak"
      info "Backed up $target to $bak"
    fi
  fi
  cp --remove-destination -f -- "$source" "$target"
  ok "Installed $target"
}

# ---- Optional steps -------------------------------------------------------
# run_optional <label> <command...>: a failure is reported and skipped, never fatal.
run_optional() {
  local label=$1
  shift
  info "$label..."
  if "$@" </dev/tty; then
    ok "$label: done"
  else
    warn "\"$label\" failed; continuing."
    FAILED_PLUGINS+=("$label")
    return 1
  fi
}
