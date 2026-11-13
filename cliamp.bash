
#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/cliamp"
PLAYLIST_DIR="$CONFIG_DIR/playlists"
CONFIG_FILE="$CONFIG_DIR/config.toml"
QURAN_DIR="$HOME/.Quran"

APP_DIR="$HOME/.local/share/applications"
APP_NAME="cliamp.desktop"
APP_OVERRIDE="$APP_DIR/$APP_NAME"

FISH_CONFIG="$HOME/.config/fish/config.fish"
FISH_MARKER="# >>> cliamp-quran launcher >>>"

echo "Setting up Cliamp Quran startup..."

# 1. Check Cliamp executable
CLIAMP_BIN="$(command -v cliamp || true)"

if [[ -z "$CLIAMP_BIN" ]]; then
    echo "Error: cliamp executable not found."
    exit 1
fi

# 2. Check Quran directory
if [[ ! -d "$QURAN_DIR" ]]; then
    echo "Error: Quran directory does not exist: $QURAN_DIR"
    exit 1
fi

# 3. Create required directories
mkdir -p "$CONFIG_DIR" "$PLAYLIST_DIR" "$APP_DIR"

# 4. Back up and update Cliamp configuration
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
fi

cat > "$CONFIG_FILE" <<EOF
playlist = "Quran"
initial_directory = "$QURAN_DIR"

visualizer = "BarsDot"
theme = ""
eq_preset = "Flat"
eq = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

repeat = "All"

[ytmusic]
enabled = true
cookies_from = ""

[downloads]
directory = "$QURAN_DIR"
EOF

echo "Cliamp configuration updated."

# 5. Create Quran playlist if it doesn't exist
if ! cliamp playlist list | grep -qE '^[[:space:]]*Quran[[:space:]]'; then
    echo "Creating Quran playlist..."
    cliamp playlist create "Quran" --dir "$QURAN_DIR"
else
    echo "Quran playlist already exists."
fi

# 6. Find original desktop entry
SOURCE_APP=""

for directory in \
    "$HOME/.local/share/applications" \
    /usr/local/share/applications \
    /usr/share/applications
do
    candidate="$directory/$APP_NAME"

    if [[ -f "$candidate" && "$candidate" != "$APP_OVERRIDE" ]]; then
        SOURCE_APP="$candidate"
        break
    fi
done

if [[ ! -f "$APP_OVERRIDE" ]]; then
    if [[ -z "$SOURCE_APP" ]]; then
        SOURCE_APP="$(find /usr/share/applications \
            /usr/local/share/applications \
            -iname '*cliamp*.desktop' \
            -print -quit 2>/dev/null || true)"
    fi

    if [[ -z "$SOURCE_APP" || ! -f "$SOURCE_APP" ]]; then
        echo "Error: Could not find Cliamp desktop entry."
        exit 1
    fi

    cp "$SOURCE_APP" "$APP_OVERRIDE"
else
    cp "$APP_OVERRIDE" "$APP_OVERRIDE.bak"
fi

# 7. Update desktop launcher
if grep -q '^Exec=' "$APP_OVERRIDE"; then
    sed -i 's|^Exec=.*|Exec=cliamp --playlist Quran|' "$APP_OVERRIDE"
else
    echo "Error: No Exec entry found."
    exit 1
fi

if grep -q '^DBusActivatable=' "$APP_OVERRIDE"; then
    sed -i 's/^DBusActivatable=.*/DBusActivatable=false/' "$APP_OVERRIDE"
else
    echo 'DBusActivatable=false' >> "$APP_OVERRIDE"
fi

chmod 644 "$APP_OVERRIDE"

echo "Desktop launcher updated."

# 8. Add Fish function
mkdir -p "$(dirname "$FISH_CONFIG")"
touch "$FISH_CONFIG"

if ! grep -Fq "$FISH_MARKER" "$FISH_CONFIG"; then
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

    echo "Fish function installed."
else
    echo "Fish function already installed."
fi

echo
echo "===================================="
echo "Cliamp Quran setup completed!"
echo "===================================="
echo "Executable: $CLIAMP_BIN"
echo "Config:     $CONFIG_FILE"
echo "Playlist:   Quran"
echo "Audio:      $QURAN_DIR"
echo "Desktop:    $APP_OVERRIDE"
echo "Fish:       $FISH_CONFIG"
echo
echo "Reload Fish with: source ~/.config/fish/config.fish"
echo "Then run: cliamp"

