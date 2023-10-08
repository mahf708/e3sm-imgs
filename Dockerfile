FROM ubuntu:20.04

ENV LANG en_US.UTF-8

COPY Libs-blds libs-blds
RUN chmod +x libs-blds && ./libs-blds

USER E3SM_USER
