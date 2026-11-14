# shellcheck shell=bash
# PHASE: Review plan
# ABOUT: Shows everything this setup will do and asks for confirmation before changing anything.
# PLAN: hide

printf '\n  %sThe following phases will run:%s\n' "$C_BOLD" "$C_RESET"
plan_number=0
for idx in "${!PHASE_TITLES[@]}"; do
  if [[ ${PHASE_HIDDEN[$idx]} == hide ]]; then continue; fi
  plan_number=$((plan_number + 1))
  printf '   %2d. %s\n' "$plan_number" "${PHASE_TITLES[$idx]}"
  if [[ -n ${PHASE_ABOUTS[$idx]} ]]; then
    printf '       %s%s%s\n' "$C_DIM" "${PHASE_ABOUTS[$idx]}" "$C_RESET"
  fi
done

printf '\n  %sFiles that will be replaced%s (existing ones are backed up first; Ghostty'\''s config is also kept as config-bak):\n' "$C_BOLD" "$C_RESET"
find "$REPO_DIR/config" -type f -printf '    ~/.config/%P\n' | sort
find "$REPO_DIR/wallpapers" -maxdepth 1 -type f -printf '    ~/.config/omarchy/backgrounds/catppuccin/%f\n' | sort

printf '\n  %sPackages%s\n' "$C_BOLD" "$C_RESET"
printf '    Pacman: %s\n' "${PACMAN_PACKAGES[*]:-(none listed)}"
printf '    AUR:    %s\n' "${AUR_PACKAGES[*]:-(none listed)}"

printf '\n  Your sudo password is requested once, right after you confirm.\n\n'
read -r -p 'Proceed with setup? [y/N] ' answer </dev/tty
[[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { info 'Cancelled; nothing was changed.'; exit 0; }
