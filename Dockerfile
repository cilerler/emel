FROM mcr.microsoft.com/mssql-tools:latest

RUN apt-get -qqy update \
     && apt-get -qqy install wget software-properties-common \
     && wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb \
     && dpkg -i packages-microsoft-prod.deb \
     && apt-get -qqy update \
     && apt-get -qqy install powershell
