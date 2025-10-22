FROM mcr.microsoft.com/mssql-tools:latest

RUN apt-get update && apt-get install -y \
    wget \
    software-properties-common \
    ca-certificates \
    && wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm packages-microsoft-prod.deb
