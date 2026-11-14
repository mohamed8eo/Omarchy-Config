# shellcheck shell=bash
# PHASE: Web apps cleanup
# ABOUT: Removes web app launchers you don't want (Google Contacts, Maps, Messages, Photos, HEY, X, Zoom, Basecamp). Only launchers that exist are removed.

WEBAPPS_TO_REMOVE=("Google Contacts" "Google Maps" "Google Messages" "Google Photos" "HEY" "X" "Zoom" "Basecamp")
WEBAPP_DIR="$HOME/.local/share/applications"
for webapp in "${WEBAPPS_TO_REMOVE[@]}"; do
  if [[ -f $WEBAPP_DIR/$webapp.desktop ]]; then
    if omarchy webapp remove "$webapp"; then
      ok "Removed web app: $webapp"
    else
      warn "could not remove web app \"$webapp\"; continuing."
    fi
  else
    skip "Web app not installed: $webapp"
  fi
done
