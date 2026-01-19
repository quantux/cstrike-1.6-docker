FROM debian:bookworm-slim

# ===============================
# Dependências essenciais (Adicionado suporte i386)
# ===============================
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    libgcc-s1:i386 \
    libstdc++6:i386 \
    libc6:i386 \
    unzip \
    tar \
    curl \
    xz-utils \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ===============================
# Criar usuário steam
# ===============================
RUN groupadd -r steam && useradd -r -g steam -m -d /opt/steam steam

USER steam
WORKDIR /opt/steam
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ===============================
# Copiar dependências locais
# ===============================
COPY --chown=steam:steam dependencies /opt/dependencies

# ===============================
# Script de instalação do HLDS
# ===============================
COPY --chown=steam:steam ./lib/hlds.install /opt/steam

# ===============================
# 1. SteamCMD + HLDS (motor base)
# ===============================
RUN tar xzf /opt/dependencies/steamcmd_linux.tar.gz \
 && ./steamcmd.sh +runscript hlds.install \
 && rm steamcmd.sh

# ===============================
# 2. ReHLDS (binários do servidor)
# ===============================
RUN unzip -o /opt/dependencies/rehlds-bin-3.14.0.857.zip \
 && unzip -o -j /opt/dependencies/rehlds-bin-3.14.0.857.zip "bin/linux32/*" -d hlds \
 && unzip -o -j /opt/dependencies/rehlds-bin-3.14.0.857.zip "bin/linux32/valve/*" -d hlds \
 && rm /opt/dependencies/rehlds-bin-3.14.0.857.zip

# ===============================
# 3. Steam SDK fix
# ===============================
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# ===============================
# 4. Metamod-R
# ===============================
RUN mkdir -p hlds/cstrike/addons/metamod \
 && unzip -j /opt/dependencies/metamod-bin-1.3.0.149.zip \
    "addons/metamod/metamod*" \
    -d hlds/cstrike/addons/metamod \
 && rm /opt/dependencies/metamod-bin-1.3.0.149.zip

WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

ENTRYPOINT ["./hlds_run", "-game", "cstrike"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
