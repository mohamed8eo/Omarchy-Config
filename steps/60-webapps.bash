# shellcheck shell=bash
# Step 60: remove web app launchers you don't want. Only launchers that exist are removed.

WEBAPPS_TO_REMOVE=("Google Contacts" "Google Maps" "Google Messages" "Google Photos" "HEY" "X" "Zoom" "Basecamp")
WEBAPP_DIR="$HOME/.local/share/applications"
printf '\nRemoving unwanted web apps...\n'
for webapp in "${WEBAPPS_TO_REMOVE[@]}"; do
  if [[ -f $WEBAPP_DIR/$webapp.desktop ]]; then
    if omarchy webapp remove "$webapp"; then
      printf 'Removed web app: %s\n' "$webapp"
    else
      warn "could not remove web app \"$webapp\"; continuing."
    fi
  else
    printf 'Web app not installed, skipping: %s\n' "$webapp"
  fi
done
