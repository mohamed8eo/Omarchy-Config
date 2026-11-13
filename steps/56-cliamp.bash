# shellcheck shell=bash
# Step 56: Cliamp Quran setup (optional)
#
# Configures cliamp with Quran playlist, downloads audio files from Dropbox (optional),
# creates desktop entry override, and adds Fish function.

# Only run if cliamp is in the package list (installed via 20-packages.bash)
if ! command -v cliamp >/dev/null 2>&1; then
  printf 'cliamp not installed; skipping cliamp setup.\n'
  return 0
fi

printf '\n=== Cliamp Quran Setup ===\n'

QURAN_DIR="$HOME/.Quran"
CONFIG_DIR="$HOME/.config/cliamp"
PLAYLIST_DIR="$CONFIG_DIR/playlists"
CONFIG_FILE="$CONFIG_DIR/config.toml"
APP_DIR="$HOME/.local/share/applications"
APP_NAME="cliamp.desktop"
APP_OVERRIDE="$APP_DIR/$APP_NAME"
FISH_CONFIG="$HOME/.config/fish/config.fish"
FISH_MARKER="# >>> cliamp-quran launcher >>>"

# --- Optional: Download Quran audio files ---
printf '\nDownload Quran audio files from Dropbox?\n'
printf 'This will download ~2GB of audio files to %s\n' "$QURAN_DIR"
printf '[y/N] '
read -r REPLY </dev/tty
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf 'Downloading Quran audio files...\n'
  mkdir -p "$QURAN_DIR"
  cd "$QURAN_DIR"

  DROPBOX_URL='https://www.dropbox.com/scl/fo/plksmdojj7nyqlxh35lwq/AJCzj2g6sP8oZmqLrce7SAE?rlkey=qm5i27dsy0wgodp5ujwdxeapu&st=98m1qak2&dl=1'
  ZIP_FILE="dropbox-folder.zip"
  EXTRACT_DIR="dropbox-files"

  if retry 3 curl -L --fail "$DROPBOX_URL" -o "$ZIP_FILE"; then
    printf 'Download complete. Extracting...\n'
    if command -v unzip >/dev/null 2>&1; then
      unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR"
      # Move extracted files to .Quran root if they're in a subfolder
      if [[ -d "$EXTRACT_DIR" ]]; then
        find "$EXTRACT_DIR" -type f -name '*.mp3' -o -name '*.m4a' -o -name '*.opus' | while IFS= read -r file; do
          mv -n "$file" "$QURAN_DIR/" 2>/dev/null || true
        done
        rm -rf "$EXTRACT_DIR"
      fi
      rm -f "$ZIP_FILE"
      printf 'Quran audio files ready in %s\n' "$QURAN_DIR"
    else
      warn 'unzip not installed; zip file saved to %s/%s' "$QURAN_DIR" "$ZIP_FILE"
    fi
  else
    warn 'Failed to download Quran audio files after 3 attempts; continuing without them.'
  fi
else
  printf 'Skipping Quran audio download.\n'
  mkdir -p "$QURAN_DIR"
fi

# --- Create/Update cliamp config ---
mkdir -p "$CONFIG_DIR" "$PLAYLIST_DIR"

# The config file from config/cliamp/config.toml will be installed by 50-configs.bash
# but we need to ensure the initial_directory uses $HOME (already done in config.toml)
# Verify the installed config has the right path
if [[ -f "$CONFIG_FILE" ]]; then
  sed -i "s|initial_directory = \".*\"|initial_directory = \"$QURAN_DIR\"|" "$CONFIG_FILE"
  sed -i "s|directory = \".*\"|directory = \"$QURAN_DIR\"|" "$CONFIG_FILE"
fi

# --- Create Quran playlist ---
printf 'Creating Quran playlist...\n'
if ! cliamp playlist list 2>/dev/null | grep -qE '^[[:space:]]*Quran[[:space:]]'; then
  cliamp playlist create "Quran" --dir "$QURAN_DIR" 2>/dev/null || warn 'Failed to create Quran playlist (cliamp may need first run)'
else
  printf 'Quran playlist already exists.\n'
fi

# --- Create/Update desktop entry override ---
mkdir -p "$APP_DIR"

# Find source desktop entry
SOURCE_APP=""
for dir in \
  "$HOME/.local/share/applications" \
  /usr/local/share/applications \
  /usr/share/applications
do
  candidate="$dir/$APP_NAME"
  if [[ -f "$candidate" && "$candidate" != "$APP_OVERRIDE" ]]; then
    SOURCE_APP="$candidate"
    break
  fi
done

if [[ -z "$SOURCE_APP" ]]; then
  SOURCE_APP=$(find /usr/share/applications /usr/local/share/applications -iname '*cliamp*.desktop' -print -quit 2>/dev/null || true)
fi

if [[ -n "$SOURCE_APP" && -f "$SOURCE_APP" ]]; then
  if [[ -f "$APP_OVERRIDE" ]]; then
    backup_if_present "$APP_OVERRIDE" "applications/$APP_NAME"
  fi
  cp "$SOURCE_APP" "$APP_OVERRIDE"

  # Update Exec line
  sed -i 's|^Exec=.*|Exec=cliamp --playlist Quran|' "$APP_OVERRIDE"

  # Ensure DBusActivatable=false
  if grep -q '^DBusActivatable=' "$APP_OVERRIDE"; then
    sed -i 's/^DBusActivatable=.*/DBusActivatable=false/' "$APP_OVERRIDE"
  else
    echo 'DBusActivatable=false' >> "$APP_OVERRIDE"
  fi

  chmod 644 "$APP_OVERRIDE"
  printf 'Desktop entry updated: %s\n' "$APP_OVERRIDE"
else
  warn 'Could not find cliamp desktop entry; skipping desktop override.'
fi

# --- Add Fish function ---
mkdir -p "$(dirname "$FISH_CONFIG")"
touch "$FISH_CONFIG"

if ! grep -Fq "$FISH_MARKER" "$FISH_CONFIG"; then
  CLIAMP_BIN=$(command -v cliamp)
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
  printf 'Fish function added to %s\n' "$FISH_CONFIG"
else
  printf 'Fish function already present.\n'
fi

printf '\nCliamp Quran setup complete.\n'
printf '  Config:     %s\n' "$CONFIG_FILE"
printf '  Audio dir:  %s\n' "$QURAN_DIR"
printf '  Desktop:    %s\n' "$APP_OVERRIDE"
printf '  Fish func:  %s\n' "$FISH_CONFIG"
printf 'Reload Fish with: source ~/.config/fish/config.fish\n'