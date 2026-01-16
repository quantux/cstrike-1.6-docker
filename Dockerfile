FROM debian:bullseye-slim

# Argumentos de Versão
ARG rehlds_build=3.13.0.788
ARG metamod_version=1.3.0.138
ARG amxmod_version=1.8.2
ARG regamedll_version=5.26.0.668
ARG reapi_version=5.24.0.300
ARG yapb_version=4.4.957
ARG reunion_version=0.2.0.25

# URLs
ARG steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

# Configurações de Ambiente
ENV CPU_MHZ=2300
ENV LANG=en_US.UTF-8

# 1. Instalação de dependências e Suporte Multi-Arquitetura
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    xz-utils \
    zip \
    libx11-6 \
    gnupg \
    wget \
    && arch=$(dpkg --print-architecture) \
    && if [ "$arch" = "arm64" ]; then \
         echo "Configurando ambiente ARM64 (Raspberry Pi)..." \
         && dpkg --add-architecture i386 \
         && dpkg --add-architecture armhf \
         && wget https://itai-nelken.github.io/weekly-box86-debs/debian/box86.list -O /etc/apt/sources.list.d/box86.list \
         && wget -qO- https://itai-nelken.github.io/weekly-box86-debs/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-archive-keyring.gpg \
         && apt-get update \
         && apt-get install -y box86:armhf libc6:armhf libc6:i386 libstdc++6:i386 libgcc-s1:i386; \
       else \
         echo "Configurando ambiente AMD64 (PC)..." \
         && dpkg --add-architecture i386 \
         && apt-get update \
         && apt-get install -y lib32gcc-s1 lib32stdc++6; \
       fi \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário steam
RUN groupadd -r steam && useradd -r -g steam -m -d /opt/steam steam

USER steam
WORKDIR /opt/steam
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Script de instalação do HLDS
COPY --chown=steam:steam ./lib/hlds.install /opt/steam

# 2. SteamCMD + HLDS (Instalação do Jogo)
# Executamos o binário diretamente se o script .sh falhar
RUN curl -sL "$steamcmd_url" | tar xz \
    && ./steamcmd.sh +runscript hlds.install \
    || ./linux32/steamcmd +runscript hlds.install \
    && rm -rf steamcmd.sh linux32 linux64

# 3. ReHLDS (Binários do Servidor)
RUN curl -sLJO https://github.com/dreamstalker/rehlds/releases/download/${rehlds_build}/rehlds-bin-${rehlds_build}.zip \
    && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/*" -d hlds \
    && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/valve/*" -d hlds \
    && rm rehlds-bin-${rehlds_build}.zip

# 4. Steam SDK fix
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# 5. Metamod-R
RUN mkdir -p hlds/cstrike/addons/metamod \
    && curl -sLJO https://github.com/theAsmodai/metamod-r/releases/download/${metamod_version}/metamod-bin-${metamod_version}.zip \
    && unzip -j metamod-bin-${metamod_version}.zip "addons/metamod/metamod*" -d hlds/cstrike/addons/metamod \
    && rm metamod-bin-${metamod_version}.zip

# Copiar arquivos customizados (Mapas, configs, etc)
COPY --chown=steam:steam ./cstrike /opt/steam/hlds/cstrike

WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

# 6. Entrypoint Inteligente (Detecta se precisa usar Box86)
RUN echo $'#!/bin/bash\n\
arch=$(dpkg --print-architecture)\n\
if [ "$arch" = "arm64" ]; then\n\
  echo "--- INICIANDO SERVIDOR VIA BOX86 (ARM64) ---"\n\
  # Box86 traduz instruções x86 para ARM nativo\n\
  exec box86 ./hlds_run "$@"\n\
else\n\
  echo "--- INICIANDO SERVIDOR NATIVAMENTE (AMD64) ---"\n\
  exec ./hlds_run "$@"\n\
fi' > /opt/steam/entrypoint.sh && chmod +x /opt/steam/entrypoint.sh

ENTRYPOINT ["/opt/steam/entrypoint.sh"]
CMD ["-game", "cstrike", "+map", "de_dust2", "+maxplayers", "16"]
