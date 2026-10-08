# PHREEQC Linux packages

Build the USGS [PHREEQC](https://www.usgs.gov/software/phreeqc-version-3) batch program as a `.deb` or `.rpm`. The script downloads the Linux source tarball from the [USGS download page](https://water.usgs.gov/water-resources/software/PHREEQC/), compiles it in a Docker image of the distribution you choose, and writes the package to `output/<os>-<version>/`.

The version pin is `PHREEQC_UPSTREAM` in [`distros.sh`](distros.sh). It is `3.8.6-17100`, the Linux batch release the USGS page currently distributes (`phreeqc-3.8.6-17100.tar.gz`).

You need Docker and `curl`. The package is built for the architecture of the machine running Docker.

## Choose a target

Run the script with no arguments. It asks for an operating system, then for one of the two versions that operating system still offers:

```bash
./build.sh
```

Or name the target directly:

```bash
./build.sh ubuntu 26.04
./build.sh almalinux 10
```

Any other operating system or version is rejected. The finished package is in `output/ubuntu-26.04/` or the matching directory for the target you picked.

The build runs upstream `make check` before packaging. That suite takes several minutes. Set `PHREEQC_FULL_CHECK=0` to skip it. The package is still installed afterward and example 1 is run with `phreeqc.dat`.

## Versions

These are the two newest releases as of October 2026. Ubuntu and Debian entries are the two newest LTS or stable releases. Fedora has no LTS release, so the menu lists the two Fedora releases still in security support.

| Operating system | Versions | Package |
| --- | --- | --- |
| Ubuntu | 26.04 LTS, 24.04 LTS | deb |
| Debian | 13 (Trixie), 12 (Bookworm) | deb |
| Fedora | 44, 43 | rpm |
| openSUSE Leap | 16.0, 15.6 | rpm |
| AlmaLinux | 10, 9 | rpm |
| Rocky Linux | 10, 9 | rpm |
| Red Hat Enterprise Linux | 10, 9 | rpm |
| CentOS Stream | 10, 9 | rpm |

openSUSE Leap 16.1 is still a release candidate, so 15.6 is the previous Leap release even though it reached end of life on 30 April 2026. CentOS Linux is discontinued; the CentOS choices are CentOS Stream. Red Hat container images require a subscription, so the Red Hat builds use the freely available Universal Base Images (`redhat/ubi10` and `redhat/ubi9`) and produce an RPM for that RHEL major version.

## What the package contains

The package follows upstream `make install --prefix=/usr`:

- `/usr/bin/phreeqc`
- databases, examples, and documentation under `/usr/share/doc/phreeqc`

The default database name inside the program is `phreeqc.dat` in the working directory, or the path in `PHREEQC_DATABASE`. Example 1 can be run with the installed database explicitly:

```bash
phreeqc /usr/share/doc/phreeqc/examples/ex1 ex1.out /usr/share/doc/phreeqc/database/phreeqc.dat
```

PHREEQC is public-domain software from the U.S. Geological Survey.
