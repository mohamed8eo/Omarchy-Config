# shellcheck shell=bash
# PHASE: Configuration and wallpapers
# ABOUT: Sets the Catppuccin theme, installs every file under config/ into ~/.config (existing files are backed up first), and sets the desktop background.
#
# Everything under config/ mirrors ~/.config:
#   config/ghostty/config  ->  ~/.config/ghostty/config
#   config/hypr/*          ->  ~/.config/hypr/*
# Existing files are backed up under $BACKUP_DIR first. Files listed in
# SIBLING_BACKUP_FILES (lib/common.bash) also get a "<file>-bak" copy on the first run.

info 'Applying the Catppuccin theme...'
omarchy theme set catppuccin </dev/tty
ok 'Theme set to catppuccin'

info 'Installing configuration files...'
while IFS= read -r -d '' src_file; do
  relative=${src_file#"$REPO_DIR/config/"}
  target="$HOME/.config/$relative"
  use_sibling=0
  for sibling_file in "${SIBLING_BACKUP_FILES[@]}"; do
    if [[ $sibling_file == "$relative" ]]; then use_sibling=1; fi
  done
  if ((use_sibling)); then
    copy_file_with_sibling_backup "$src_file" "$target" "$relative"
  else
    copy_file "$src_file" "$target" "$relative"
  fi
done < <(find "$REPO_DIR/config" -type f -print0 | sort -z)

info 'Copying wallpapers...'
WALLPAPER_DIR="$HOME/.config/omarchy/backgrounds/catppuccin"
while IFS= read -r -d '' src_file; do
  name=$(basename -- "$src_file")
  copy_file "$src_file" "$WALLPAPER_DIR/$name" "wallpapers/$name"
done < <(find "$REPO_DIR/wallpapers" -maxdepth 1 -type f -print0 | sort -z)

WALLPAPER_PATH="$WALLPAPER_DIR/$WALLPAPER_IMAGE"
info "Setting the desktop background to $WALLPAPER_IMAGE..."
if omarchy theme bg set "$WALLPAPER_PATH" </dev/tty; then
  ok "Desktop background set to $WALLPAPER_PATH"
else
  warn "could not set the desktop background to $WALLPAPER_PATH; continuing."
fi
