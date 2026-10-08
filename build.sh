#!/bin/bash
# Build a PHREEQC batch package for one supported distribution.
# With no arguments, ask for the operating system and then the version.
# With two arguments, skip the menus: ./build.sh ubuntu 26.04

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=distros.sh
source "$ROOT/distros.sh"

usage() {
  cat <<EOF
Usage: ./build.sh [<os> <version>]

Build the USGS PHREEQC ${PHREEQC_UPSTREAM} Linux batch source inside a
Docker image of the selected distribution and write a .deb or .rpm to
output/<os>-<version>/.

With no arguments, the script asks which operating system and which of
its two supported versions to build. Anything outside the list is rejected.

Supported targets:
EOF
  local id ver label image format manager dist
  while IFS='|' read -r id ver label image format manager dist; do
    [[ -z "$id" || "$id" == \#* ]] && continue
    printf '  %-14s %-6s  %s\n' "$id" "$ver" "$label"
  done < <(phreeqc_rows)
  cat <<EOF

Examples:
  ./build.sh
  ./build.sh ubuntu 26.04
  ./build.sh almalinux 10

The build runs upstream "make check" before packaging. That suite takes
several minutes. Set PHREEQC_FULL_CHECK=0 to skip it. The package is
still installed and example 1 is run either way.
EOF
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

prompt_index() {
  local prompt=$1
  shift
  local options=("$@")
  local choice i
  while true; do
    printf '%s\n' "$prompt" >&2
    for i in "${!options[@]}"; do
      printf '  %d) %s\n' "$((i + 1))" "${options[$i]}" >&2
    done
    printf 'Choice: ' >&2
    if ! read -r choice; then
      die "selection cancelled"
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf '%s\n' "$((choice - 1))"
      return 0
    fi
    printf 'Enter a number from 1 to %d.\n\n' "${#options[@]}" >&2
  done
}

select_target_interactive() {
  local -a os_ids=() os_labels=()
  local id label
  while IFS='|' read -r id label; do
    [[ -z "$id" || "$id" == \#* ]] && continue
    os_ids+=("$id")
    os_labels+=("$label")
  done < <(phreeqc_operating_systems)

  local os_index
  os_index=$(prompt_index "Select an operating system:" "${os_labels[@]}")
  local os_id=${os_ids[$os_index]}

  local -a ver_ids=() ver_labels=()
  local ver row_id row_ver row_label
  while IFS='|' read -r row_id row_ver row_label _; do
    [[ -z "$row_id" || "$row_id" == \#* ]] && continue
    if [[ "$row_id" == "$os_id" ]]; then
      ver_ids+=("$row_ver")
      ver_labels+=("$row_label")
    fi
  done < <(phreeqc_rows)

  printf '\n'
  local ver_index
  ver_index=$(prompt_index "Select a version:" "${ver_labels[@]}")
  phreeqc_lookup "$os_id" "${ver_ids[$ver_index]}"
}

fetch_tarball() {
  mkdir -p "$ROOT/cache"
  local dest="$ROOT/cache/$PHREEQC_TARBALL"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  command -v curl >/dev/null 2>&1 || die "curl is required to download ${PHREEQC_TARBALL}"
  printf 'Downloading %s\n' "$PHREEQC_URL"
  curl -fL --retry 3 -o "${dest}.partial" "$PHREEQC_URL"
  mv "${dest}.partial" "$dest"
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  if [[ $# -eq 0 ]]; then
    if [[ ! -t 0 ]]; then
      usage >&2
      die "no operating system given and stdin is not a terminal"
    fi
    select_target_interactive
  elif [[ $# -eq 2 ]]; then
    local os_id=${1,,}
    local version=$2
    if ! phreeqc_lookup "$os_id" "$version"; then
      usage >&2
      die "unsupported target: ${1} ${2}"
    fi
  else
    usage >&2
    die "pass both an operating system and a version, or neither to choose interactively"
  fi

  command -v docker >/dev/null 2>&1 || die "docker is required"
  docker info >/dev/null 2>&1 || die "docker is installed but the daemon is not reachable"

  fetch_tarball

  local image_tag="phreeqc-build:${TARGET_ID}-${TARGET_VERSION}"
  local out_dir="$ROOT/output/${TARGET_ID}-${TARGET_VERSION}"
  mkdir -p "$out_dir"

  printf 'Building PHREEQC %s for %s (%s)\n' \
    "$PHREEQC_UPSTREAM" "$TARGET_LABEL" "$TARGET_FORMAT"

  docker build \
    --build-arg "BASE_IMAGE=${TARGET_IMAGE}" \
    -t "$image_tag" \
    "$ROOT"

  docker run --rm \
    -e "PHREEQC_VERSION=${PHREEQC_VERSION}" \
    -e "PHREEQC_UPSTREAM=${PHREEQC_UPSTREAM}" \
    -e "PHREEQC_TARBALL=${PHREEQC_TARBALL}" \
    -e "PHREEQC_DEB_REVISION=${PHREEQC_DEB_REVISION}" \
    -e "PKG_FORMAT=${TARGET_FORMAT}" \
    -e "PKG_MANAGER=${TARGET_MANAGER}" \
    -e "DIST_TAG=${TARGET_DIST_TAG}" \
    -e "PHREEQC_FULL_CHECK=${PHREEQC_FULL_CHECK:-1}" \
    -e "HOST_UID=$(id -u)" \
    -e "HOST_GID=$(id -g)" \
    -v "$ROOT/cache:/cache:ro" \
    -v "$out_dir:/output" \
    "$image_tag"

  printf 'Package written to %s\n' "$out_dir"
  find "$out_dir" -maxdepth 1 -type f -printf '  %f\n'
}

main "$@"
