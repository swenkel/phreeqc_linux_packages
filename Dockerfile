# BASE_IMAGE is one of the distribution images named in distros.sh.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY scripts/build-inside.sh /opt/phreeqc-build/build-inside.sh
COPY packaging/phreeqc.spec /opt/phreeqc-build/phreeqc.spec
RUN chmod 755 /opt/phreeqc-build/build-inside.sh

ENTRYPOINT ["/opt/phreeqc-build/build-inside.sh"]
