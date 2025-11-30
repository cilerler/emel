FROM mcr.microsoft.com/mssql-tools:latest

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && wget -q "https://packages.microsoft.com/config/$(. /etc/os-release && echo $ID/$VERSION_ID)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/opt/mssql-tools/bin:/opt/mssql-tools18/bin"
