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
ARG yapb_url=https://github.com/yapb/yapb/releases/download/${yapb_version}/yapb-${yapb_version}-linux.tar.xz
ARG steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
ARG reunion_url=https://github.com/rehlds/ReUnion/releases/download/${reunion_version}/reunion-${reunion_version}.zip

# Configurações de Ambiente
ENV CPU_MHZ=2300
ENV LANG=en_US.UTF-8

# Dependências essenciais
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    lib32gcc-s1 \
    unzip \
    xz-utils \
    zip \
 && rm -rf /var/lib/apt/lists/*

# Criar usuário steam
RUN groupadd -r steam && useradd -r -g steam -m -d /opt/steam steam

USER steam
WORKDIR /opt/steam
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Script de instalação do HLDS
COPY --chown=steam:steam ./lib/hlds.install /opt/steam

# 1. SteamCMD + HLDS (Motor Base)
RUN curl -sL "$steamcmd_url" | tar xz \
 && ./steamcmd.sh +runscript hlds.install \
 && rm steamcmd.sh

# 2. ReHLDS (Binários do Servidor)
RUN curl -sLJO https://github.com/dreamstalker/rehlds/releases/download/${rehlds_build}/rehlds-bin-${rehlds_build}.zip \
 && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/*" -d hlds \
 && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/valve/*" -d hlds \
 && rm rehlds-bin-${rehlds_build}.zip

# 3. Steam SDK fix
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# 4. Metamod-R (Core para Plugins)
RUN mkdir -p hlds/cstrike/addons/metamod \
 && curl -sLJO https://github.com/theAsmodai/metamod-r/releases/download/${metamod_version}/metamod-bin-${metamod_version}.zip \
 && unzip -j metamod-bin-${metamod_version}.zip "addons/metamod/metamod*" -d hlds/cstrike/addons/metamod \
 && rm metamod-bin-${metamod_version}.zip

# Nota: AMX Mod X, ReAPI e YaPB agora vivem na sua pasta 'cstrike' no host.
# Mantemos o ambiente limpo para o volume assumir o controle.

USER root
# Garantir que a pasta de destino exista para o mapeamento
RUN mkdir -p /opt/steam/hlds/cstrike
USER steam

WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

ENTRYPOINT ["./hlds_run", "-game", "cstrike"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
