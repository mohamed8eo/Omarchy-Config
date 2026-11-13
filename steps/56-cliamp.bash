# shellcheck shell=bash
# Step 56: Cliamp Quran setup (optional)
#
# Optionally downloads Quran audio from Dropbox into ~/.Quran, fixes the paths in the
# installed cliamp config, creates the "Quran" playlist, overrides the desktop launcher so it
# starts that playlist, and adds a Fish `cliamp` function.
# (The cliamp config itself lives in config/cliamp/config.toml and is installed by step 50.)

# cliamp is installed from packages.toml in step 20.
if ! command -v cliamp >/dev/null 2>&1; then
  warn 'cliamp is not installed; skipped the cliamp Quran setup.'
  return 0
fi

run_cmd 'Cliamp Quran Setup' true

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

run_cmd "Creating directories" mkdir -p "$QURAN_DIR" "$CONFIG_DIR" "$PLAYLIST_DIR" "$APP_DIR"

# --- Optional: download the Quran audio files ---
# Not asked again when ~/.Quran already contains audio files (so re-running is quick).
if [[ -n $(find "$QURAN_DIR" -maxdepth 1 -type f \( -name '*.mp3' -o -name '*.m4a' -o -name '*.opus' \) -print -quit) ]]; then
  printf 'Quran audio already present in %s; skipping the download.\n' "$QURAN_DIR"
else
  quran_answer=''
  if _dry_run; then
    printf '[DRY-RUN] Would prompt: Download Quran audio files from Dropbox? (y/N)\n'
    quran_answer='n'
  else
    printf '\nDownload Quran audio files from Dropbox?\n'
    printf 'This downloads about 2GB of audio to %s\n' "$QURAN_DIR"
    read -r -p 'Download now? [y/N] ' quran_answer </dev/tty || quran_answer=''
  fi
  if [[ $quran_answer == [yY] || $quran_answer == [yY][eE][sS] ]]; then
    DROPBOX_URL='https://www.dropbox.com/scl/fo/plksmdojj7nyqlxh35lwq/AJCzj2g6sP8oZmqLrce7SAE?rlkey=qm5i27dsy0wgodp5ujwdxeapu&st=98m1qak2&dl=1'
    ZIP_FILE="$QURAN_DIR/dropbox-folder.zip"
    EXTRACT_DIR="$QURAN_DIR/dropbox-files"
    TMP_PATHS+=("$ZIP_FILE" "$EXTRACT_DIR")

    if ! command -v unzip >/dev/null 2>&1; then
      warn 'unzip is not installed; skipped the Quran audio download.'
    else
      run_cmd 'Downloading Quran audio files' retry 3 curl -L --fail "$DROPBOX_URL" -o "$ZIP_FILE"
      if [[ -f $ZIP_FILE ]]; then
        run_cmd 'Extracting Quran audio files' unzip -o -q "$ZIP_FILE" -d "$EXTRACT_DIR"
        # Move the audio files up into ~/.Quran (existing files are not overwritten).
        run_cmd 'Moving audio files to ~/.Quran' find "$EXTRACT_DIR" -type f \( -name '*.mp3' -o -name '*.m4a' -o -name '*.opus' \) -exec mv -n -- {} "$QURAN_DIR/" \;
        printf 'Quran audio files ready in %s\n' "$QURAN_DIR"
        rm -rf -- "$EXTRACT_DIR" "$ZIP_FILE"
      else
        warn 'failed to download the Quran audio files after 3 attempts; continuing without them.'
      fi
    fi
  else
    printf 'Skipping Quran audio download.\n'
  fi
fi

# --- Point the installed cliamp config at ~/.Quran ---
# TOML does not expand $HOME, so the paths are filled in here.
if [[ -f $CONFIG_FILE ]]; then
  run_cmd "Updating cliamp config paths to $QURAN_DIR" sed -i -e "s|^initial_directory = .*|initial_directory = \"$QURAN_DIR\"|" -e "s|^directory = .*|directory = \"$QURAN_DIR\"|" "$CONFIG_FILE"
else
  warn "$CONFIG_FILE not found; cliamp paths were not set."
fi

# --- Create the Quran playlist ---
run_cmd 'Creating Quran playlist' cliamp playlist list 2>/dev/null | grep -qE '^[[:space:]]*Quran[[:space:]]' && printf 'Quran playlist already exists.\n' || cliamp playlist create "Quran" --dir "$QURAN_DIR" 2>/dev/null || warn 'failed to create the Quran playlist (cliamp may need a first run).'

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
  run_cmd "Creating desktop override $APP_OVERRIDE" cp -- "$SOURCE_APP" "$APP_OVERRIDE"
  if ! _dry_run; then
    sed -i 's|^Exec=.*|Exec=cliamp --playlist Quran|' "$APP_OVERRIDE"
    if grep -q '^DBusActivatable=' "$APP_OVERRIDE"; then
      sed -i 's/^DBusActivatable=.*/DBusActivatable=false/' "$APP_OVERRIDE"
    else
      printf 'DBusActivatable=false\n' >> "$APP_OVERRIDE"
    fi
    chmod 644 "$APP_OVERRIDE"
    printf 'Desktop entry updated: %s\n' "$APP_OVERRIDE"
  fi
else
  warn 'could not find the cliamp desktop entry; skipped the desktop override.'
fi

# --- Fish function: plain `cliamp` starts the Quran playlist ---
run_cmd "Ensuring Fish config directory exists" mkdir -p "$(dirname -- "$FISH_CONFIG")"
run_cmd "Touching Fish config" touch "$FISH_CONFIG"
if grep -Fq "$FISH_MARKER" "$FISH_CONFIG"; then
  printf 'Fish function already present.\n'
else
  run_cmd "Adding Fish function to $FISH_CONFIG" cat >> "$FISH_CONFIG" <<EOF

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
  printf 'Fish function added to %s\n' "$FISH_CONFIG"
fi

printf '\nCliamp Quran setup complete.\n'
printf '  Config:    %s\n' "$CONFIG_FILE"
printf '  Audio dir: %s\n' "$QURAN_DIR"
printf '  Desktop:   %s\n' "$APP_OVERRIDE"
printf '  Fish:      %s (run: source ~/.config/fish/config.fish)\n' "$FISH_CONFIG"