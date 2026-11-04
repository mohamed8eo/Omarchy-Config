#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL='https://github.com/mohamed8eo/omarchy-setup.git'
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-setup.XXXXXX")
cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT

command -v git >/dev/null || { printf 'Error: git is required to fetch omarchy-setup.\n' >&2; exit 1; }
git clone --depth 1 --branch main "$REPO_URL" "$WORK_DIR/repo"
bash "$WORK_DIR/repo/setup.bash"
