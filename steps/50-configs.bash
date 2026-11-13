# shellcheck shell=bash
# Step 50: theme, config files, and wallpapers.
#
# Everything under config/ mirrors ~/.config:
#   config/ghostty/config  ->  ~/.config/ghostty/config
#   config/hypr/*          ->  ~/.config/hypr/*
# Existing files are backed up under $BACKUP_DIR first. Files listed in
# SIBLING_BACKUP_FILES (lib/common.bash) also get a "<file>-bak" copy on the first run.

omarchy theme set catppuccin </dev/tty

printf '\nApplying configuration files...\n'
while IFS= read -r -d '' source; do
  relative=${source#"$REPO_DIR/config/"}
  target="$HOME/.config/$relative"
  use_sibling=0
  for sibling_file in "${SIBLING_BACKUP_FILES[@]}"; do
    if [[ $sibling_file == "$relative" ]]; then use_sibling=1; fi
  done
  if ((use_sibling)); then
    copy_file_with_sibling_backup "$source" "$target" "$relative"
  else
    copy_file "$source" "$target" "$relative"
  fi
done < <(find "$REPO_DIR/config" -type f -print0 | sort -z)

printf '\nCopying wallpapers...\n'
WALLPAPER_DIR="$HOME/.config/omarchy/backgrounds/catppuccin"
while IFS= read -r -d '' source; do
  name=$(basename -- "$source")
  copy_file "$source" "$WALLPAPER_DIR/$name" "wallpapers/$name"
done < <(find "$REPO_DIR/wallpapers" -maxdepth 1 -type f -print0 | sort -z)

WALLPAPER_PATH="$WALLPAPER_DIR/$WALLPAPER_IMAGE"
printf '\nSetting desktop background to %s...\n' "$WALLPAPER_IMAGE"
if omarchy theme bg set "$WALLPAPER_PATH" </dev/tty; then
  printf 'Desktop background set to %s.\n' "$WALLPAPER_PATH"
else
  warn "could not set the desktop background to $WALLPAPER_PATH; continuing."
fi
