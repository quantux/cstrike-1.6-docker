FROM --platform=linux/386 debian:bookworm-slim

# ===============================
# Dependências mínimas
# ===============================
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    xz-utils \
    tar \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/steam

# ===============================
# Dependências locais
# ===============================
COPY dependencies /opt/dependencies
COPY lib/hlds.install .

# ===============================
# SteamCMD + HLDS
# ===============================
RUN tar xzf /opt/dependencies/steamcmd_linux.tar.gz \
 && ./steamcmd.sh +runscript hlds.install \
 && rm steamcmd.sh

# ===============================
# ReHLDS
# ===============================
RUN unzip -o /opt/dependencies/rehlds-bin-3.14.0.857.zip \
 && unzip -o -j /opt/dependencies/rehlds-bin-3.14.0.857.zip "bin/linux32/*" -d hlds \
 && unzip -o -j /opt/dependencies/rehlds-bin-3.14.0.857.zip "bin/linux32/valve/*" -d hlds \
 && rm /opt/dependencies/rehlds-bin-3.14.0.857.zip

# ===============================
# Metamod
# ===============================
RUN mkdir -p hlds/cstrike/addons/metamod \
 && unzip -j /opt/dependencies/metamod-bin-1.3.0.149.zip \
    "addons/metamod/metamod*" \
    -d hlds/cstrike/addons/metamod \
 && rm /opt/dependencies/metamod-bin-1.3.0.149.zip

# ===============================
# Run
# ===============================
WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux

ENTRYPOINT ["./hlds_run", "-game", "cstrike"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
