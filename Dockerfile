FROM spack/ubuntu-jammy:0.22.0

ARG GCC_VERSION
ARG MPICH_VERSION
ARG SZIP_VERSION
ARG HDF5_VERSION
ARG NETCDFC_VERSION
ARG NETCDFCXX_VERSION
ARG NETCDFFORTRAN_VERSION
ARG PNETCDF_VERSION

ENV GCC_VERSION=${GCC_VERSION}
ENV MPICH_VERSION=${MPICH_VERSION}
ENV SZIP_VERSION=${SZIP_VERSION}
ENV HDF5_VERSION=${HDF5_VERSION}
ENV NETCDFC_VERSION=${NETCDFC_VERSION}
ENV NETCDFCXX_VERSION=${NETCDFCXX_VERSION}
ENV NETCDFFORTRAN_VERSION=${NETCDFFORTRAN_VERSION}
ENV PNETCDF_VERSION=${PNETCDF_VERSION}

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y remove cmake
RUN apt-get -y install software-properties-common
RUN add-apt-repository universe
RUN apt-get update && apt-get -y install \
    locales csh m4 libcurl4-openssl-dev \
    libz-dev gcc g++ gfortran liblapack-dev make git \
    git wget subversion libxml2-dev libxml2-utils libxml-libxml-perl \
    libswitch-perl build-essential checkinstall zlib1g-dev libssl-dev python3-distutils

# TODO: move to env file (spack.yaml)?
RUN mkdir -p /opt/spack-environment \
&&  (echo "spack:" \
&&   echo "  definitions:" \
&&   echo "    - compilers: [gcc@${GCC_VERSION}]" \
&&   echo "    - mpis: [mpich@${MPICH_VERSION}]" \
&&   echo "    - mpipkgs: [hdf5@${HDF5_VERSION}, netcdf-c@${NETCDFC_VERSION}, netcdf-cxx@${NETCDFCXX_VERSION}, netcdf-fortran@${NETCDFFORTRAN_VERSION}, parallel-netcdf@${PNETCDF_VERSION}]" \
&&   echo "    - othpkgs: [cmake, cprnc]" \
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

# TODO: do these intervene with each other?
# https://cache.spack.io/tag/v0.22.1/?stack=e4s
RUN spack mirror add v0.22.0-e4s https://binaries.spack.io/v0.22.0/e4s
RUN spack buildcache keys --install --trust
# https://cache.spack.io/tag/v0.22.1/?stack=root#
RUN spack mirror add v0.22.0-root https://binaries.spack.io/v0.22.0/root
RUN spack buildcache keys --install --trust
# https://oaciss.uoregon.edu/e4s/inventory.html
RUN spack mirror add E4S https://cache.e4s.io
RUN spack buildcache keys -it

RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

RUN mkdir -p $HOME/projects/e3sm/cesm-inputdata

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

ENV LANGUAGE=en_US:en \
    LANG=en_US.UTF-8

RUN mkdir -p /app/test
COPY E3sm-test /app/test/e3sm-test
RUN chmod +x /app/test/e3sm-test

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l"]
