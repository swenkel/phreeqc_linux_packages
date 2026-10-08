#!/bin/bash
# Compile PHREEQC, pack a deb or rpm, install it, and run example 1.
# build.sh passes the environment and mounts /cache and /output.

set -euo pipefail

: "${PHREEQC_VERSION:?PHREEQC_VERSION is required}"
: "${PHREEQC_UPSTREAM:?PHREEQC_UPSTREAM is required}"
: "${PHREEQC_TARBALL:?PHREEQC_TARBALL is required}"
: "${PHREEQC_DEB_REVISION:?PHREEQC_DEB_REVISION is required}"
: "${PKG_FORMAT:?PKG_FORMAT is required}"
: "${PKG_MANAGER:?PKG_MANAGER is required}"
: "${PHREEQC_FULL_CHECK:=1}"

SPEC=/opt/phreeqc-build/phreeqc.spec
CACHE_TARBALL=/cache/${PHREEQC_TARBALL}
DOC_ROOT=/usr/share/doc/phreeqc
SHARE_ROOT=/usr/share/phreeqc

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

install_deps() {
  case "$PKG_MANAGER" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y build-essential dpkg-dev
      ;;
    dnf)
      dnf install -y gcc-c++ make rpm-build gzip tar findutils
      ;;
    zypper)
      zypper --non-interactive refresh
      zypper --non-interactive install --no-recommends \
        gcc-c++ make rpm-build gzip tar findutils
      ;;
    *)
      die "unknown package manager: ${PKG_MANAGER}"
      ;;
  esac
}

relocate_runtime_files() {
  local staging=$1
  mkdir -p "${staging}${SHARE_ROOT}"
  mv "${staging}${DOC_ROOT}/database" "${staging}${SHARE_ROOT}/database"
  mv "${staging}${DOC_ROOT}/examples" "${staging}${SHARE_ROOT}/examples"
}

assert_install_layout() {
  local staging=$1
  [[ -f "${staging}/usr/bin/phreeqc" ]] || die "make install did not produce /usr/bin/phreeqc"
  [[ -f "${staging}${SHARE_ROOT}/database/phreeqc.dat" ]] || die "make install did not produce phreeqc.dat"
  [[ -f "${staging}${SHARE_ROOT}/examples/ex1" ]] || die "make install did not produce examples/ex1"

  local unexpected
  unexpected=$(find "$staging" -type f -o -type l | sed "s|^${staging}||" | while read -r path; do
    case "$path" in
      /usr/bin/phreeqc|"${DOC_ROOT}"|"${DOC_ROOT}"/*|"${SHARE_ROOT}"|"${SHARE_ROOT}"/*) ;;
      *) printf '%s\n' "$path" ;;
    esac
  done)
  if [[ -n "$unexpected" ]]; then
    printf 'unexpected installed files:\n%s\n' "$unexpected" >&2
    exit 1
  fi
}

package_deb() {
  local staging=$1 work=$2
  local arch depends size deb_root
  arch=$(dpkg --print-architecture)
  # dpkg-shlibdeps maps a binary to a package only when it lives under debian/<package>/.
  mkdir -p "${work}/debian/phreeqc"
  ln -s "${staging}/usr" "${work}/debian/phreeqc/usr"
  cat > "${work}/debian/control" <<'EOF'
Source: phreeqc

Package: phreeqc
Architecture: any
Description: aqueous geochemical calculations
 placeholder
EOF
  depends=$(
    cd "$work"
    dpkg-shlibdeps -O debian/phreeqc/usr/bin/phreeqc | sed -n 's/^shlibs:Depends=//p'
  )
  [[ -n "$depends" ]] || die "dpkg-shlibdeps produced no shared-library dependencies"
  size=$(du -sk "$staging" | cut -f1)

  deb_root="${work}/deb"
  mkdir -p "${deb_root}/DEBIAN"
  cp -a "${staging}/." "$deb_root/"
  cat > "${deb_root}/DEBIAN/control" <<EOF
Package: phreeqc
Version: ${PHREEQC_VERSION}-${PHREEQC_DEB_REVISION}
Section: science
Priority: optional
Architecture: ${arch}
Depends: ${depends}
Installed-Size: ${size}
Maintainer: PHREEQC Linux Packages <phreeqc-linux-packages@localhost>
Homepage: https://www.usgs.gov/software/phreeqc-version-3
Description: aqueous geochemical calculations
 PHREEQC Version 3 performs speciation, batch-reaction, one-dimensional
 transport, and inverse geochemical calculations. This package contains
 the batch executable, thermodynamic databases, examples, and the user's
 guides from the USGS Linux batch distribution.
EOF
  dpkg-deb --root-owner-group --build "$deb_root" \
    "/output/phreeqc_${PHREEQC_VERSION}-${PHREEQC_DEB_REVISION}_${arch}.deb"
}

package_rpm() {
  local staging=$1 work=$2
  [[ -n "${DIST_TAG:-}" ]] || die "DIST_TAG is required for an rpm build"
  local top=${work}/rpm
  mkdir -p "${top}/BUILD" "${top}/RPMS" "${top}/SOURCES" "${top}/SPECS" "${top}/SRPMS"
  rpmbuild -bb \
    --define "_topdir ${top}" \
    --define "dist .${DIST_TAG}" \
    --define "phreeqc_version ${PHREEQC_VERSION}" \
    --define "phreeqc_staging ${staging}" \
    "$SPEC"
  find "${top}/RPMS" -type f -name '*.rpm' -exec cp -a {} /output/ \;
  local count
  count=$(find /output -maxdepth 1 -type f -name '*.rpm' | wc -l)
  [[ "$count" -eq 1 ]] || die "expected one rpm in /output, found ${count}"
}

install_package() {
  local package
  local -a packages=()
  mapfile -t packages < <(find /output -maxdepth 1 -type f \( -name '*.deb' -o -name '*.rpm' \))
  [[ ${#packages[@]} -eq 1 ]] || die "expected one package in /output, found ${#packages[@]}"
  package=${packages[0]}
  case "$PKG_FORMAT" in
    deb)
      dpkg -i "$package"
      ;;
    rpm)
      rpm -Uvh --nosignature "$package"
      ;;
    *)
      die "unknown package format: ${PKG_FORMAT}"
      ;;
  esac
}

smoke_test() {
  local smoke db
  smoke=$(mktemp -d)
  db=${SHARE_ROOT}/database/phreeqc.dat
  command -v phreeqc >/dev/null 2>&1 || die "phreeqc is not on PATH after install"
  [[ -s "$db" ]] || die "installed database is missing: ${db}"
  cp "${SHARE_ROOT}/examples/ex1" "${smoke}/ex1"
  phreeqc "${smoke}/ex1" "${smoke}/ex1.out" "$db"
  [[ -s "${smoke}/ex1.out" ]] || die "example 1 produced no output"
  printf 'Smoke test passed (example 1).\n'
}

give_output_to_host_user() {
  if [[ -n "${HOST_UID:-}" && -n "${HOST_GID:-}" ]]; then
    chown "${HOST_UID}:${HOST_GID}" /output/*
  fi
}

main() {
  [[ -f "$CACHE_TARBALL" ]] || die "missing source tarball at ${CACHE_TARBALL}"
  case "$PKG_FORMAT" in
    deb|rpm) ;;
    *) die "PKG_FORMAT must be deb or rpm" ;;
  esac

  install_deps

  local work srcdir builddir staging
  work=$(mktemp -d)
  tar -xzf "$CACHE_TARBALL" -C "$work"
  srcdir="${work}/phreeqc-${PHREEQC_UPSTREAM}"
  [[ -d "$srcdir" ]] || die "tarball did not contain ${srcdir}"
  builddir="${work}/build"
  mkdir "$builddir"
  (
    cd "$builddir"
    "${srcdir}/configure" --prefix=/usr --without-gmp
    make -j"$(nproc)"
    if [[ "$PHREEQC_FULL_CHECK" == "1" ]]; then
      make check
    fi
    staging="${work}/staging"
    mkdir "$staging"
    make install "DESTDIR=${staging}"
  )
  staging="${work}/staging"
  relocate_runtime_files "$staging"
  assert_install_layout "$staging"

  find /output -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  case "$PKG_FORMAT" in
    deb) package_deb "$staging" "$work" ;;
    rpm) package_rpm "$staging" "$work" ;;
  esac

  install_package
  smoke_test
  give_output_to_host_user
}

main "$@"
