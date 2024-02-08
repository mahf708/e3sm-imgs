FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

ENV LANGUAGE=en_US:en \
    LANG=en_US.UTF-8

ARG SZIP_VERSION
ARG HDF5_VERSION
ARG NETCDFC_VERSION
ARG NETCDFCXX_VERSION
ARG NETCDFFORTRAN_VERSION
ARG PNETCDF_VERSION

ENV SZIP_VERSION ${SZIP_VERSION}
ENV HDF5_VERSION ${HDF5_VERSION}
ENV NETCDFC_VERSION ${NETCDFC_VERSION}
ENV NETCDFCXX_VERSION ${NETCDFCXX_VERSION}
ENV NETCDFFORTRAN_VERSION ${NETCDFFORTRAN_VERSION}
ENV PNETCDF_VERSION ${PNETCDF_VERSION}

COPY Libs-blds libs-blds
RUN chmod +x libs-blds && ./libs-blds && rm libs-blds

COPY E3sm-test e3sm-test
RUN chmod +x e3sm-test
