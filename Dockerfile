FROM ubuntu:18.04

ENV LANG en_US.UTF-8

COPY Libs-blds libs-blds
RUN chmod +x libs-blds && ./libs-blds
