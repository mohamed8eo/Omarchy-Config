# shellcheck shell=bash
# PHASE: Cliamp (Quran player)
# ABOUT: Optionally downloads the Quran audio (about 2GB, asks first), creates the Quran playlist, and makes cliamp start it from the launcher and from a Fish function.
#
# The cliamp config itself lives in config/cliamp/config.toml and is installed by the
# configuration phase; this step only fills in the audio paths and wires up the launcher.

# cliamp is installed from packages.toml in the packages phase.
if ! command -v cliamp >/dev/null 2>&1; then
  warn 'cliamp is not installed; skipped the cliamp Quran setup.'
  return 0
fi

QURAN_DIR="$HOME/.Quran"
CONFIG_DIR="$HOME/.config/cliamp"
PLAYLIST_DIR="$CONFIG_DIR/playlists"
CONFIG_FILE="$CONFIG_DIR/config.toml"
APP_DIR="$HOME/.local/share/applications"
APP_NAME="cliamp.desktop"
APP_OVERRIDE="$APP_DIR/$APP_NAME"
FISH_CONFIG="$HOME/.config/fish/config.fish"
FISH_MARKER="# >>> cliamp-quran launcher >>>"
CLIAMP_BIN=$(command -v cliamp)

mkdir -p "$QURAN_DIR" "$CONFIG_DIR" "$PLAYLIST_DIR" "$APP_DIR"

# --- Optional: download the Quran audio files ---
# Not asked again when ~/.Quran already contains audio files (so re-running is quick).
if [[ -n $(find "$QURAN_DIR" -maxdepth 1 -type f \( -name '*.mp3' -o -name '*.m4a' -o -name '*.opus' \) -print -quit) ]]; then
  skip "Quran audio already present in $QURAN_DIR; not downloading again"
else
  printf '\n    Download the Quran audio files from Dropbox?\n'
  printf '    This downloads about 2GB to %s\n\n' "$QURAN_DIR"
  read -r -p 'Download now? [y/N] ' quran_answer </dev/tty || quran_answer=''
  if [[ $quran_answer == [yY] || $quran_answer == [yY][eE][sS] ]]; then
    DROPBOX_URL='https://www.dropbox.com/scl/fo/plksmdojj7nyqlxh35lwq/AJCzj2g6sP8oZmqLrce7SAE?rlkey=qm5i27dsy0wgodp5ujwdxeapu&st=98m1qak2&dl=1'
    ZIP_FILE="$QURAN_DIR/dropbox-folder.zip"
    # Only a partial download is removed on exit; a complete zip is kept if extraction fails.
    TMP_PATHS+=("$ZIP_FILE.part")

    # Needs room for the zip (about 2GB) plus the extracted audio (about 2GB).
    free_kb=$(df --output=avail -k "$QURAN_DIR" 2>/dev/null | tail -n 1 | tr -d ' ' || true)
    if ! command -v unzip >/dev/null 2>&1; then
      warn 'unzip is not installed; skipped the Quran audio download.'
    elif [[ ${free_kb:-} =~ ^[0-9]+$ ]] && ((free_kb < 5 * 1024 * 1024)); then
      warn "not enough free disk space for the Quran audio (about 5GB needed, $((free_kb / 1024 / 1024))GB free); skipped the download."
    else
      info 'Downloading the Quran audio files (about 2GB, this can take a while)...'
      if retry 3 curl -L --fail --show-error -o "$ZIP_FILE.part" "$DROPBOX_URL"; then
        mv -- "$ZIP_FILE.part" "$ZIP_FILE"
        info 'Download complete. Extracting the audio files...'
        # -j: ignore folders, -n: never overwrite, -C: case-insensitive names, -q: quiet.
        # unzip exits 1 for harmless warnings (unusual file names) and 11 when one of the patterns
        # matches nothing (for example no .opus files), so success is judged by the audio that arrived.
        unzip_status=0
        unzip_output=$(unzip -j -n -C -q "$ZIP_FILE" '*.mp3' '*.m4a' '*.opus' -d "$QURAN_DIR" 2>&1) || unzip_status=$?
        if ((unzip_status <= 1 || unzip_status == 11)) \
          && [[ -n $(find "$QURAN_DIR" -maxdepth 1 -type f \( -name '*.mp3' -o -name '*.m4a' -o -name '*.opus' \) -print -quit) ]]; then
          rm -f -- "$ZIP_FILE"
          ok "Quran audio files ready in $QURAN_DIR"
        else
          printf '%s\n' "$unzip_output" | tail -n 5 >&2
          warn "could not extract any Quran audio (unzip exit $unzip_status); the download was kept at $ZIP_FILE (it may be an error page instead of a zip)."
        fi
      else
        rm -f -- "$ZIP_FILE.part"
        warn 'failed to download the Quran audio files after 3 attempts; continuing without them.'
      fi
    fi
  else
    skip 'Quran audio download skipped'
  fi
fi

# --- Point the installed cliamp config at ~/.Quran ---
# TOML does not expand $HOME, so the paths are filled in here.
if [[ -f $CONFIG_FILE ]]; then
  sed -i -e "s|^initial_directory = .*|initial_directory = \"$QURAN_DIR\"|" \
         -e "s|^directory = .*|directory = \"$QURAN_DIR\"|" "$CONFIG_FILE"
  ok "cliamp config points at $QURAN_DIR"
else
  warn "$CONFIG_FILE not found; cliamp paths were not set."
fi

# --- Create the Quran playlist ---
if cliamp playlist list 2>/dev/null | grep -qE '^[[:space:]]*Quran[[:space:]]'; then
  skip 'Quran playlist already exists'
elif cliamp playlist create "Quran" --dir "$QURAN_DIR" 2>/dev/null; then
  ok 'Quran playlist created'
else
  warn 'failed to create the Quran playlist (cliamp may need a first run).'
fi

# --- Desktop entry override ---
SOURCE_APP=""
for dir in \
  "$HOME/.local/share/applications" \
  /usr/local/share/applications \
  /usr/share/applications
do
  candidate="$dir/$APP_NAME"
  if [[ -f $candidate && $candidate != "$APP_OVERRIDE" ]]; then
    SOURCE_APP=$candidate
    break
  fi
done
if [[ -z $SOURCE_APP ]]; then
  SOURCE_APP=$(find /usr/share/applications /usr/local/share/applications -iname '*cliamp*.desktop' -print -quit 2>/dev/null || true)
fi

if [[ -n $SOURCE_APP && -f $SOURCE_APP ]]; then
  backup_if_present "$APP_OVERRIDE" "applications/$APP_NAME"
  cp -- "$SOURCE_APP" "$APP_OVERRIDE"
  sed -i 's|^Exec=.*|Exec=cliamp --playlist Quran|' "$APP_OVERRIDE"
  if grep -q '^DBusActivatable=' "$APP_OVERRIDE"; then
    sed -i 's/^DBusActivatable=.*/DBusActivatable=false/' "$APP_OVERRIDE"
  else
    printf 'DBusActivatable=false\n' >> "$APP_OVERRIDE"
  fi
  chmod 644 "$APP_OVERRIDE"
  ok "Desktop entry updated: $APP_OVERRIDE"
else
  warn 'could not find the cliamp desktop entry; skipped the desktop override.'
fi

# --- Fish function: plain `cliamp` starts the Quran playlist ---
mkdir -p "$(dirname -- "$FISH_CONFIG")"
touch "$FISH_CONFIG"
if grep -Fq "$FISH_MARKER" "$FISH_CONFIG"; then
  skip 'Fish cliamp function already present'
else
  cat >> "$FISH_CONFIG" <<EOF

$FISH_MARKER
function cliamp
    if test (count \$argv) -eq 0
        command "$CLIAMP_BIN" --playlist Quran
    else
        command "$CLIAMP_BIN" \$argv
    end
end
# <<< cliamp-quran launcher <<<
EOF
  ok "Fish function added to $FISH_CONFIG (run: source ~/.config/fish/config.fish)"
fi
