FROM debian:bookworm-slim

# Dependências essenciais (i386)
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libc6:i386 libstdc++6:i386 libgcc-s1:i386 \
        unzip tar curl xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Variáveis de ambiente (SteamAPI FIX)
ENV LD_LIBRARY_PATH=/opt/steam/linux32

# Criar usuário e grupos
RUN groupadd -r steam && useradd -r -u 1000 -g steam -m -d /opt/steam steam

# Criar diretórios e garantir permissões
RUN mkdir -p /opt/steam/hlds \
             /opt/dependencies && \
    chown -R steam:steam /opt/steam /opt/dependencies

# Definir usuário e diretório de trabalho
USER steam
WORKDIR /opt/steam

# Copiar dependências locais
COPY --chown=steam:steam dependencies /opt/dependencies
RUN mv /opt/dependencies/lib/hlds.install /opt/steam

# 1. SteamCMD + HLDS (motor base)
RUN tar xzf /opt/dependencies/steamcmd_linux.tar.gz && \
    ./steamcmd.sh +runscript hlds.install && \
    rm steamcmd.sh

# 2. ReHLDS (binários do servidor)
#    Nota: usa a versão 3.13.0.788. A 3.14.x é incompatível com o caminho
#    ARM64 (Box86): retorna "Can not retrive filesystem interface version
#    'VFileSystem009'." (ver rehlds/ReHLDS#1130). Padroniza as duas imagens.
RUN unzip -o /opt/dependencies/rehlds-bin-3.13.0.788.zip -d /opt/steam/hlds && \
    unzip -o -j /opt/dependencies/rehlds-bin-3.13.0.788.zip "bin/linux32/*" -d /opt/steam/hlds && \
    unzip -o -j /opt/dependencies/rehlds-bin-3.13.0.788.zip "bin/linux32/valve/*" -d /opt/steam/hlds/valve/dlls && \
    rm /opt/dependencies/rehlds-bin-3.13.0.788.zip

# 3. Steam SDK fix
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# 4. Metamod-R
RUN mkdir -p /opt/steam/hlds/cstrike/addons/metamod && \
    unzip -o -j /opt/dependencies/metamod-bin-1.3.0.149.zip \
        "addons/metamod/metamod*" \
        -d /opt/steam/hlds/cstrike/addons/metamod && \
    rm /opt/dependencies/metamod-bin-1.3.0.149.zip

# Configurações finais
WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

ENTRYPOINT ["./hlds_run", "-game", "cstrike"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
