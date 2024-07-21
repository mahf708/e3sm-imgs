# Build stage with Spack pre-installed and ready to be used
FROM spack/ubuntu-jammy:0.22.0 AS builder

# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir -p /opt/spack-environment \
&&  (echo "spack:" \
&&   echo "  definitions:" \
&&   echo "    - compilers: [gcc@11]" \
&&   echo "    - mpis: [mpich]" \
&&   echo "    - mpipkgs: [hdf5, netcdf-c, netcdf-cxx, netcdf-fortran, parallel-netcdf]" \
&&   echo "    - othpkgs: [cmake, perl, python, libxml2, perl-xml-libxml, py-setuptools]" \
&&   echo " " \
&&   echo "  specs:" \
&&   echo "    - szip" \
&&   echo "    - matrix:" \
&&   echo "      - [\$mpis]" \
&&   echo "      - [\$%compilers]" \
&&   echo "    - matrix:" \
&&   echo "      - [\$othpkgs]" \
&&   echo "      - [\$%compilers]" \
&&   echo "    - matrix:" \
&&   echo "      - [\$mpipkgs]" \
&&   echo "      - [\$^mpis]" \
&&   echo "      - [\$%compilers]" \
&&   echo "  concretizer:" \
&&   echo "    unify: true" \
&&   echo "  config:" \
&&   echo "    install_tree: /opt/software" \
&&   echo "  view: /usr/local/packages") > /opt/spack-environment/spack.yaml

# This command will add the build cache to your Spack configuration, allowing you to access pre-built packages for faster installation.
# https://cache.spack.io/tag/v0.22.1/?stack=e4s
RUN spack mirror add v0.22.1-e4s https://binaries.spack.io/v0.22.1/e4s
RUN spack buildcache keys --install --trust
# https://cache.spack.io/tag/v0.22.1/?stack=root#
RUN spack mirror add v0.22.1-root https://binaries.spack.io/v0.22.1/root
RUN spack buildcache keys --install --trust

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# # Strip all the binaries
# RUN find -L /usr/local/packages/* -type f -exec readlink -f '{}' \; | \
#     xargs file -i | \
#     grep 'charset=binary' | \
#     grep 'x-executable\|x-archive\|x-sharedlib' | \
#     awk -F: '{print $1}' | xargs strip -s

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

# Bare OS image to run the installed executables
FROM spack/ubuntu-jammy:0.22.0

RUN mkdir -p $HOME/projects/e3sm/cesm-inputdata

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

ENV LANGUAGE=en_US:en \
    LANG=en_US.UTF-8

# ARG SZIP_VERSION
# ARG HDF5_VERSION
# ARG NETCDFC_VERSION
# ARG NETCDFCXX_VERSION
# ARG NETCDFFORTRAN_VERSION
# ARG PNETCDF_VERSION

# ENV SZIP_VERSION ${SZIP_VERSION}
# ENV HDF5_VERSION ${HDF5_VERSION}
# ENV NETCDFC_VERSION ${NETCDFC_VERSION}
# ENV NETCDFCXX_VERSION ${NETCDFCXX_VERSION}
# ENV NETCDFFORTRAN_VERSION ${NETCDFFORTRAN_VERSION}
# ENV PNETCDF_VERSION ${PNETCDF_VERSION}

# COPY Libs-blds libs-blds
# RUN chmod +x libs-blds && ./libs-blds && rm libs-blds

COPY E3sm-test e3sm-test
RUN chmod +x e3sm-test

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /usr/local/packages /usr/local/packages
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l"]
