# shellcheck shell=bash
# Terminal output helpers: banner, phases, status lines, key/value rows.
# Sourced, never executed. Colors are used only on a terminal; set NO_COLOR=1 to disable them.
# Expects LOG_FILE to be set by setup.bash (falls back to /dev/null).

if [[ -t 1 && -t 2 && -z ${NO_COLOR:-} && ${TERM:-dumb} != dumb ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_CYAN=$'\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''
fi

LOG_FILE=${LOG_FILE:-/dev/null}
WARNINGS=()                # non-fatal problems, listed in the final summary
PHASE_INDEX=0
PHASE_TOTAL=0
PHASE_TITLE=init

# log_line <LEVEL> <message>: append a plain-text line to the log file (never fails).
log_line() {
  printf '%s %-5s %s\n' "$(date '+%F %T')" "$1" "$2" >> "$LOG_FILE" 2>/dev/null || true
}

# ---- Layout ---------------------------------------------------------------
ui_banner() {
  printf '\n%s%s%s\n' "$C_BOLD" "$1" "$C_RESET"
  printf '%s%s%s\n' "$C_DIM" "$2" "$C_RESET"
  log_line START "$1"
}

# phase <title> [description lines...]: announce the phase that is about to run.
phase() {
  local title=$1 line
  shift
  PHASE_INDEX=$((PHASE_INDEX + 1))
  PHASE_TITLE=$title
  printf '\n%s==>%s %s[%d/%d] %s%s\n' "$C_CYAN$C_BOLD" "$C_RESET" "$C_BOLD" "$PHASE_INDEX" "$PHASE_TOTAL" "$title" "$C_RESET"
  for line in "$@"; do
    printf '    %s%s%s\n' "$C_DIM" "$line" "$C_RESET"
  done
  log_line PHASE "[$PHASE_INDEX/$PHASE_TOTAL] $title"
}

# kv <label> <value>: aligned detail row (used in the summary).
kv() { printf '    %s%-16s%s %s\n' "$C_DIM" "$1" "$C_RESET" "$2"; }

# ---- Status lines ---------------------------------------------------------
info() { printf ' %s[ INFO ]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; log_line INFO "$*"; }
ok()   { printf ' %s[  OK  ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; log_line OK "$*"; }
skip() { printf ' %s[ SKIP ]%s %s\n' "$C_DIM" "$C_RESET" "$*"; log_line SKIP "$*"; }
# note: a visible but unrecorded heads-up (e.g. a retry); warn: recorded for the final summary.
note() { printf ' %s[ NOTE ]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; log_line NOTE "$*"; }
warn() { printf ' %s[ WARN ]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; WARNINGS+=("$*"); log_line WARN "$*"; }
err()  { printf ' %s[ERROR ]%s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; log_line ERROR "$*"; }
# err_detail <label> <value>: aligned row under an error message.
err_detail() { printf '          %s%-9s%s %s\n' "$C_DIM" "$1" "$C_RESET" "$2" >&2; log_line ERROR "  $1 $2"; }
die() { err "$*"; exit 1; }

format_duration() {
  local total=$1
  if ((total >= 3600)); then
    printf '%dh %dm %ds' $((total / 3600)) $((total % 3600 / 60)) $((total % 60))
  elif ((total >= 60)); then
    printf '%dm %ds' $((total / 60)) $((total % 60))
  else
    printf '%ds' "$total"
  fi
}
