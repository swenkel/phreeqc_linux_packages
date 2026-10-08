# Allow-list of package targets. Source this file; do not execute it.
#
# PHREEQC_UPSTREAM is the single version pin. It matches the Linux batch
# tarball published on https://www.usgs.gov/software/phreeqc-version-3
# (phreeqc-3.8.6-17100.tar.gz). Package versions replace the hyphen so
# deb and rpm version fields stay valid.

PHREEQC_UPSTREAM=3.8.6-17100
PHREEQC_VERSION=${PHREEQC_UPSTREAM//-/.}
PHREEQC_TARBALL=phreeqc-${PHREEQC_UPSTREAM}.tar.gz
PHREEQC_URL=https://water.usgs.gov/water-resources/software/PHREEQC/${PHREEQC_TARBALL}
PHREEQC_DEB_REVISION=1

# id|version|label|image|format|manager|dist_tag
# dist_tag is the RPM %{dist} suffix without the leading dot. Deb rows leave it empty.
phreeqc_rows() {
  cat <<'EOF'
ubuntu|26.04|Ubuntu 26.04 LTS|ubuntu:26.04|deb|apt|
ubuntu|24.04|Ubuntu 24.04 LTS|ubuntu:24.04|deb|apt|
debian|13|Debian 13 (Trixie)|debian:13|deb|apt|
debian|12|Debian 12 (Bookworm)|debian:12|deb|apt|
fedora|44|Fedora 44|fedora:44|rpm|dnf|fc44
fedora|43|Fedora 43|fedora:43|rpm|dnf|fc43
opensuse|16.0|openSUSE Leap 16.0|opensuse/leap:16.0|rpm|zypper|lp160
opensuse|15.6|openSUSE Leap 15.6|opensuse/leap:15.6|rpm|zypper|lp156
almalinux|10|AlmaLinux 10|almalinux:10|rpm|dnf|el10
almalinux|9|AlmaLinux 9|almalinux:9|rpm|dnf|el9
rockylinux|10|Rocky Linux 10|rockylinux:10|rpm|dnf|el10
rockylinux|9|Rocky Linux 9|rockylinux:9|rpm|dnf|el9
rhel|10|Red Hat Enterprise Linux 10|redhat/ubi10|rpm|dnf|el10
rhel|9|Red Hat Enterprise Linux 9|redhat/ubi9|rpm|dnf|el9
centos|10|CentOS Stream 10|quay.io/centos/centos:stream10|rpm|dnf|el10
centos|9|CentOS Stream 9|quay.io/centos/centos:stream9|rpm|dnf|el9
EOF
}

# id|menu label, in menu order. Each id has exactly two rows in phreeqc_rows.
phreeqc_operating_systems() {
  cat <<'EOF'
ubuntu|Ubuntu
debian|Debian
fedora|Fedora
opensuse|openSUSE Leap
almalinux|AlmaLinux
rockylinux|Rocky Linux
rhel|Red Hat Enterprise Linux
centos|CentOS Stream
EOF
}

phreeqc_lookup() {
  local want_id=$1 want_ver=$2
  local id ver label image format manager dist
  TARGET_ID=
  TARGET_VERSION=
  TARGET_LABEL=
  TARGET_IMAGE=
  TARGET_FORMAT=
  TARGET_MANAGER=
  TARGET_DIST_TAG=
  while IFS='|' read -r id ver label image format manager dist; do
    [[ -z "$id" || "$id" == \#* ]] && continue
    if [[ "$id" == "$want_id" && "$ver" == "$want_ver" ]]; then
      TARGET_ID=$id
      TARGET_VERSION=$ver
      TARGET_LABEL=$label
      TARGET_IMAGE=$image
      TARGET_FORMAT=$format
      TARGET_MANAGER=$manager
      TARGET_DIST_TAG=$dist
      return 0
    fi
  done < <(phreeqc_rows)
  return 1
}
