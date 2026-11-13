# shellcheck shell=bash
# Step 00: preflight checks and package manifest parsing. Nothing is changed here.

[[ $EUID -ne 0 ]] || die 'Run as your normal user, not with sudo.'
command -v omarchy >/dev/null || die 'Omarchy was not found; this installer requires Omarchy.'
command -v python3 >/dev/null || die 'python3 is required to read packages.toml.'
[[ -r /dev/tty ]] || die 'An interactive terminal is required for the preview, update, and shell change.'

for required in config wallpapers packages.toml; do
  [[ -e $REPO_DIR/$required ]] || die "Required repo entry is missing: $required"
done
[[ $WALLPAPER_IMAGE != */* ]] || die 'WALLPAPER_IMAGE must be a filename from wallpapers/, not a path.'
[[ -f $REPO_DIR/wallpapers/$WALLPAPER_IMAGE ]] || die "WALLPAPER_IMAGE not found in wallpapers/: $WALLPAPER_IMAGE"

# Fail early when offline: nearly every step below downloads something.
if command -v curl >/dev/null 2>&1 && [[ ${SKIP_NET_CHECK:-0} != 1 ]]; then
  curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1 \
    || die 'No internet connection (could not reach github.com). Connect and rerun, or set SKIP_NET_CHECK=1 to skip this check.'
fi

PACKAGE_DATA=$(python3 - "$REPO_DIR/packages.toml" <<'PY'
import sys, tomllib
with open(sys.argv[1], 'rb') as f:
    manifest = tomllib.load(f)
for section in ('pacman', 'aur'):
    packages = manifest.get(section, [])
    if not isinstance(packages, list) or any(not isinstance(p, str) or not p.strip() for p in packages):
        raise SystemExit(f'packages.toml: {section} must be an array of non-empty package names')
    for package in packages:
        if any(c.isspace() for c in package) or package.startswith('-'):
            raise SystemExit(f'packages.toml: invalid package name {package!r}')
        print(f'{section}\t{package}')
PY
) || die 'Could not parse packages.toml.'
PACMAN_PACKAGES=()
AUR_PACKAGES=()
while IFS=$'\t' read -r kind package; do
  [[ -n ${kind:-} ]] || continue
  case $kind in
    pacman) PACMAN_PACKAGES+=("$package") ;;
    aur) AUR_PACKAGES+=("$package") ;;
    *) die "Unknown package category: $kind" ;;
  esac
done <<< "$PACKAGE_DATA"
