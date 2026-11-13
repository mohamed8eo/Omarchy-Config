# shellcheck shell=bash
# Step 60: remove web app launchers you don't want. Only launchers that exist are removed.

WEBAPPS_TO_REMOVE=("Google Contacts" "Google Maps" "Google Messages" "Google Photos" "HEY" "X" "Zoom" "Basecamp")
WEBAPP_DIR="$HOME/.local/share/applications"
run_cmd 'Removing unwanted web apps' true
for webapp in "${WEBAPPS_TO_REMOVE[@]}"; do
  if [[ -f $WEBAPP_DIR/$webapp.desktop ]]; then
    run_cmd "Removing web app: $webapp" omarchy webapp remove "$webapp" || warn "could not remove web app \"$webapp\"; continuing."
  else
    printf 'Web app not installed, skipping: %s\n' "$webapp"
  fi
done