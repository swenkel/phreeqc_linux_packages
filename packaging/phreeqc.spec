# Package the staging tree produced by scripts/build-inside.sh.
# Version and dist tag are passed on the rpmbuild command line so the
# upstream pin stays in distros.sh.
Name:           phreeqc
Version:        %{phreeqc_version}
Release:        1%{?dist}
Summary:        Aqueous geochemical calculations

License:        Public Domain
URL:            https://www.usgs.gov/software/phreeqc-version-3

# Databases live under /usr/share/doc/phreeqc because that is where
# upstream "make install" puts them. Do not gzip that tree, and do not
# mark it %%doc, or rpm will move or compress the files the program reads.
%global __brp_compress %{nil}
%global debug_package %{nil}
%global _build_id_links none

%description
PHREEQC Version 3 performs speciation, batch-reaction, one-dimensional
transport, and inverse geochemical calculations. This package contains
the batch executable, thermodynamic databases, examples, and the user's
guides from the USGS Linux batch distribution.

%prep
# The upstream sources are compiled before rpmbuild runs.

%build
# See scripts/build-inside.sh.

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a %{phreeqc_staging}/. %{buildroot}/

%files
/usr/bin/phreeqc
%dir /usr/share/doc/phreeqc
%dir /usr/share/doc/phreeqc/database
%dir /usr/share/doc/phreeqc/examples
/usr/share/doc/phreeqc/NOTICE
/usr/share/doc/phreeqc/Phreeqc_2_1999_manual.pdf
/usr/share/doc/phreeqc/Phreeqc_3_2013_manual.pdf
/usr/share/doc/phreeqc/phreeqc.txt
/usr/share/doc/phreeqc/phreeqc3.chm
/usr/share/doc/phreeqc/README
/usr/share/doc/phreeqc/RELEASE
/usr/share/doc/phreeqc/wrir02-4172.pdf
/usr/share/doc/phreeqc/database/Amm.dat
/usr/share/doc/phreeqc/database/ColdChem.dat
/usr/share/doc/phreeqc/database/Concrete_PHR.dat
/usr/share/doc/phreeqc/database/Concrete_PZ.dat
/usr/share/doc/phreeqc/database/core10.dat
/usr/share/doc/phreeqc/database/frezchem.dat
/usr/share/doc/phreeqc/database/iso.dat
/usr/share/doc/phreeqc/database/Kinec_v3.dat
/usr/share/doc/phreeqc/database/Kinec.v2.dat
/usr/share/doc/phreeqc/database/llnl.dat
/usr/share/doc/phreeqc/database/minteq.dat
/usr/share/doc/phreeqc/database/minteq.v4.dat
/usr/share/doc/phreeqc/database/phreeqc_rates.dat
/usr/share/doc/phreeqc/database/PHREEQC_ThermoddemV1.10_15Dec2020.dat
/usr/share/doc/phreeqc/database/phreeqc.dat
/usr/share/doc/phreeqc/database/pitzer.dat
/usr/share/doc/phreeqc/database/sit.dat
/usr/share/doc/phreeqc/database/Tipping_Hurley.dat
/usr/share/doc/phreeqc/database/wateq4f.dat
/usr/share/doc/phreeqc/examples/co2.dat
/usr/share/doc/phreeqc/examples/co2_VP.dat
/usr/share/doc/phreeqc/examples/co2.tsv
/usr/share/doc/phreeqc/examples/ex1
/usr/share/doc/phreeqc/examples/ex2
/usr/share/doc/phreeqc/examples/ex2b
/usr/share/doc/phreeqc/examples/ex2b.tsv
/usr/share/doc/phreeqc/examples/ex3
/usr/share/doc/phreeqc/examples/ex4
/usr/share/doc/phreeqc/examples/ex5
/usr/share/doc/phreeqc/examples/ex6
/usr/share/doc/phreeqc/examples/ex7
/usr/share/doc/phreeqc/examples/ex8
/usr/share/doc/phreeqc/examples/ex9
/usr/share/doc/phreeqc/examples/ex10
/usr/share/doc/phreeqc/examples/ex11
/usr/share/doc/phreeqc/examples/ex12
/usr/share/doc/phreeqc/examples/ex12a
/usr/share/doc/phreeqc/examples/ex13a
/usr/share/doc/phreeqc/examples/ex13ac
/usr/share/doc/phreeqc/examples/ex13b
/usr/share/doc/phreeqc/examples/ex13c
/usr/share/doc/phreeqc/examples/ex14
/usr/share/doc/phreeqc/examples/ex15
/usr/share/doc/phreeqc/examples/ex15a
/usr/share/doc/phreeqc/examples/ex15b
/usr/share/doc/phreeqc/examples/ex15.dat
/usr/share/doc/phreeqc/examples/ex16
/usr/share/doc/phreeqc/examples/ex17
/usr/share/doc/phreeqc/examples/ex17b
/usr/share/doc/phreeqc/examples/ex18
/usr/share/doc/phreeqc/examples/ex19
/usr/share/doc/phreeqc/examples/ex19_meas.tsv
/usr/share/doc/phreeqc/examples/ex19b
/usr/share/doc/phreeqc/examples/ex20a
/usr/share/doc/phreeqc/examples/ex20b
/usr/share/doc/phreeqc/examples/ex20-c13.tsv
/usr/share/doc/phreeqc/examples/ex20-c14.tsv
/usr/share/doc/phreeqc/examples/ex21
/usr/share/doc/phreeqc/examples/ex21_Cl_tr_rad.tsv
/usr/share/doc/phreeqc/examples/ex21_Cs_rad.tsv
/usr/share/doc/phreeqc/examples/ex21_HTO_rad.tsv
/usr/share/doc/phreeqc/examples/ex21_Na_tr_rad.tsv
/usr/share/doc/phreeqc/examples/ex22
/usr/share/doc/phreeqc/examples/Zn1e_4
/usr/share/doc/phreeqc/examples/Zn1e_7

%changelog
* Thu Oct 08 2026 PHREEQC Linux Packages <phreeqc-linux-packages@localhost> - %{phreeqc_version}-1
- Package the USGS Linux batch release.
