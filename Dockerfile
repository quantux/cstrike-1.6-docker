FROM debian:bullseye-slim

# Argumentos de Versão
ARG rehlds_build=3.13.0.788
ARG metamod_version=1.3.0.138
ARG amxmod_version=1.8.2
ARG regamedll_version=5.26.0.668
ARG reapi_version=5.24.0.300
ARG yapb_version=4.4.957

# URLs
ARG yapb_url=https://github.com/yapb/yapb/releases/download/${yapb_version}/yapb-${yapb_version}-linux.tar.xz
ARG steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

# Configurações de Ambiente
ENV CPU_MHZ=2300
ENV LANG=en_US.UTF-8

# Dependências essenciais (removido pacotes de compilação desnecessários)
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

# 1. SteamCMD + HLDS
RUN curl -sL "$steamcmd_url" | tar xz \
 && ./steamcmd.sh +runscript hlds.install \
 && rm steamcmd.sh

# 2. ReHLDS (Baixa, extrai e remove o zip)
RUN curl -sLJO https://github.com/dreamstalker/rehlds/releases/download/${rehlds_build}/rehlds-bin-${rehlds_build}.zip \
 && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/*" -d hlds \
 && unzip -o -j rehlds-bin-${rehlds_build}.zip "bin/linux32/valve/*" -d hlds \
 && rm rehlds-bin-${rehlds_build}.zip

# 3. Steam SDK fix
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# 4. Metamod-R
RUN mkdir -p hlds/cstrike/addons/metamod \
 && curl -sLJO https://github.com/theAsmodai/metamod-r/releases/download/${metamod_version}/metamod-bin-${metamod_version}.zip \
 && unzip -j metamod-bin-${metamod_version}.zip "addons/metamod/metamod*" -d hlds/cstrike/addons/metamod \
 && rm metamod-bin-${metamod_version}.zip \
 && sed -i 's|dlls/cs.so|addons/metamod/metamod_i386.so|' hlds/cstrike/liblist.gam

# 5. AMX Mod X
RUN curl -sL http://www.amxmodx.org/release/amxmodx-${amxmod_version}-base-linux.tar.gz | tar -xz -C hlds/cstrike \
 && echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' >> hlds/cstrike/addons/metamod/plugins.ini \
 && cat hlds/cstrike/mapcycle.txt >> hlds/cstrike/addons/amxmodx/configs/maps.ini

# 6. ReGameDLL
RUN curl -sLJO https://github.com/s1lentq/ReGameDLL_CS/releases/download/${regamedll_version}/regamedll-bin-${regamedll_version}.zip \
 && unzip -o -j regamedll-bin-${regamedll_version}.zip "bin/linux32/cstrike/*" -d hlds/cstrike \
 && unzip -o -j regamedll-bin-${regamedll_version}.zip "bin/linux32/cstrike/dlls/*" -d hlds/cstrike/dlls \
 && rm regamedll-bin-${regamedll_version}.zip

# 7. ReAPI
RUN curl -sLJO https://github.com/s1lentq/reapi/releases/download/${reapi_version}/reapi-bin-${reapi_version}.zip \
 && unzip -o reapi-bin-${reapi_version}.zip -d hlds/cstrike \
 && rm reapi-bin-${reapi_version}.zip \
 && echo 'reapi' >> hlds/cstrike/addons/amxmodx/configs/modules.ini

# 8. YaPB (BOTS)
RUN curl -sL "$yapb_url" | tar -xJ -C hlds/cstrike \
 && echo 'linux addons/yapb/bin/yapb.so' >> hlds/cstrike/addons/metamod/plugins.ini

# 9. GARANTIR PERMISSÕES (Executar por último antes do WORKDIR final)
USER root
RUN mkdir -p /opt/steam/hlds/cstrike/addons/yapb/data/train && \
    chown -R steam:steam /opt/steam/hlds/cstrike/addons/yapb/data/ && \
    chmod -R 775 /opt/steam/hlds/cstrike/addons/yapb/data/
USER steam

WORKDIR /opt/steam/hlds

# Finalização
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

ENTRYPOINT ["./hlds_run", "-game", "cstrike"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
