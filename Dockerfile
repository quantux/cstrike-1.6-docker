# syntax=docker/dockerfile:1
#
# Dockerfile unico para CS 1.6 (ReHLDS) multi-plataforma.
#
#   - linux/amd64 (x86_64):  roda nativamente (libs i386).
#   - linux/arm64 (aarch64): roda os binarios x86 sob o emulador Box86
#     (x86 -> ARM), compilado para aarch64 durante o build.
#
# Build:
#   docker buildx build --platform linux/amd64,linux/arm64 \
#     -t quantux1/cstrike-1.6-docker:latest .
#
# Para build/run padrao na arquitetura do host:
#   docker compose up -d --build

# Base pinada por digest (manifest list multiarch, compartilhado amd64/arm64).
ARG BASE_DIGEST=abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241
FROM debian:bookworm-slim@sha256:${BASE_DIGEST}

# TARGETARCH e fornecido automaticamente pelo buildx (amd64/arm64/arm/v7...).
ARG TARGETARCH

# Versoes pinned das dependencias.
ARG BOX86_VERSION=0.3.8
# sha256 do tarball do Box86 v0.3.8
# (https://github.com/ptitSeb/box86/archive/refs/tags/v0.3.8.tar.gz).
ARG BOX86_SHA256=454e5f7c57f7c7c4530d4f453bf6afd07b00bd93c92fe16a4305bacae0b6a93d

# 0. Sistema base: dependencias por arquitetura.
#    amd64: apenas libs i386 para rodar o ReHLDS nativamente.
#    arm64: armhf (libs ARM32 nativas p/ Box86) + i386 (libs x86 emuladas)
#           + toolchain p/ cruzar o Box86.
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        dpkg --add-architecture armhf && dpkg --add-architecture i386 && \
        apt-get update && apt-get install -y --no-install-recommends \
            libc6:armhf libstdc++6:armhf libgcc-s1:armhf \
            libc6:i386 libstdc++6:i386 libgcc-s1:i386 zlib1g:i386 \
            libcurl4:i386 libssl3:i386 libtinfo6:i386 \
            unzip tar curl xz-utils ca-certificates procps \
            git cmake make python3 crossbuild-essential-armhf qemu-user-static; \
    else \
        dpkg --add-architecture i386 && \
        apt-get update && apt-get install -y --no-install-recommends \
            libc6:i386 libstdc++6:i386 libgcc-s1:i386 \
            unzip tar curl xz-utils ca-certificates procps python3; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# 1. Box86: emulador userland x86 -> ARM (somente arm64).
#    -DARM64=1 usa o cross-compilador arm-linux-gnueabihf-gcc (32-bit ARM).
#    CMAKE_CROSSCOMPILING_EMULATOR roda os testes do CMake via qemu-arm,
#    tornando o build portavel para kernels arm64 (inclusive 16K pages, ex.: Pi 5).
#    Download verificado por checksum (pinado).
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        curl -fsSL -o /tmp/box86.tar.gz \
            https://github.com/ptitSeb/box86/archive/refs/tags/v${BOX86_VERSION}.tar.gz && \
        echo "${BOX86_SHA256}  /tmp/box86.tar.gz" | sha256sum -c - && \
        mkdir -p /opt/box86/src && \
        tar xzf /tmp/box86.tar.gz -C /opt/box86/src --strip-components=1 && \
        mkdir -p /opt/box86/src/build && cd /opt/box86/src/build && \
        cmake .. -DARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DNOGIT=1 \
            -DCMAKE_CROSSCOMPILING_EMULATOR=/usr/bin/qemu-arm-static && \
        make -j"$(nproc)" && make install && \
        rm -rf /opt/box86/src /tmp/box86.tar.gz; \
    fi

# 2. Variaveis de ambiente
#    LD_LIBRARY_PATH: loader nativo (SteamAPI fix).
#    BOX86_LD_LIBRARY_PATH: onde o Box86 procura libs x86 (i386 + steamcmd/HLDS).
ENV LD_LIBRARY_PATH=/opt/steam/linux32
ENV BOX86_LD_LIBRARY_PATH=/usr/lib/i386-linux-gnu:/opt/steam/linux32

# 3. Usuario e grupos (uid 1000, comum nas duas plataformas)
RUN groupadd -r steam && useradd -r -u 1000 -g steam -m -d /opt/steam steam

# 4. Diretorios e permissoes
RUN mkdir -p /opt/steam/hlds /opt/dependencies && \
    chown -R steam:steam /opt/steam /opt/dependencies

# 4b. Cliente RCON de terminal (UDP, GoldSrc): exposto como comando global
#     `rcon` dentro do container para trocar de mapa / controlar bots etc.
#     Instalado aqui (ainda como root) para poder escrever em /usr/local/bin.
COPY rcon.py /usr/local/bin/rcon.py
RUN chmod +x /usr/local/bin/rcon.py && ln -sf /usr/local/bin/rcon.py /usr/local/bin/rcon

USER steam
WORKDIR /opt/steam

# 5. Dependencias locais (binarios do server + script de instalacao do steamcmd)
COPY --chown=steam:steam dependencies /opt/dependencies
RUN mv /opt/dependencies/lib/hlds.install /opt/steam

# 6. SteamCMD + base HLDS
#    amd64: o wrapper steamcmd.sh cuida do auto-restart (codigo 42).
#    arm64: o .sh nao roda sob emulacao; executamos o binario direto sob Box86
#           e tratamos o 42 reiniciando a execucao.
RUN tar xzf /opt/dependencies/steamcmd_linux.tar.gz && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        while :; do \
            box86 ./linux32/steamcmd +runscript hlds.install; \
            rc=$?; \
            [ "$rc" -eq 42 ] && continue; \
            [ "$rc" -eq 0 ] && break; \
            echo "steamcmd falhou com codigo $rc"; \
            exit "$rc"; \
        done; \
        rm steamcmd.sh; \
    else \
        ./steamcmd.sh +runscript hlds.install && rm steamcmd.sh; \
    fi

# 7. ReHLDS (binarios do servidor).
#    ATENCAO: usa a versao 3.13.0.788, pois a 3.14.x retorna
#    "Can not retrive filesystem interface version 'VFileSystem009'." sob Box86
#    (ver rehlds/ReHLDS#1130 e ptitSeb/box86#1027). Padroniza as duas arquiteturas.
RUN unzip -o /opt/dependencies/rehlds-bin-3.13.0.788.zip -d /opt/steam/hlds && \
    unzip -o -j /opt/dependencies/rehlds-bin-3.13.0.788.zip "bin/linux32/*" -d /opt/steam/hlds && \
    unzip -o -j /opt/dependencies/rehlds-bin-3.13.0.788.zip "bin/linux32/valve/*" -d /opt/steam/hlds/valve/dlls && \
    rm /opt/dependencies/rehlds-bin-3.13.0.788.zip

# 8. Steam SDK fix
RUN mkdir -p ~/.steam && ln -s /opt/steam/linux32 ~/.steam/sdk32

# 9. Metamod-R
RUN mkdir -p /opt/steam/hlds/cstrike/addons/metamod && \
    unzip -o -j /opt/dependencies/metamod-bin-1.3.0.149.zip \
        "addons/metamod/metamod*" \
        -d /opt/steam/hlds/cstrike/addons/metamod && \
    rm /opt/dependencies/metamod-bin-1.3.0.149.zip

# 10. Copia-base para seed: usada pelo entrypoint quando o volume de conteudo
#     (cstrike) vier vazio ou ausente. Mantem a imagem enxuta (sem os 4GB de
#     mapas/config do repositrio, que ficam no bind ./cstrike).
RUN cp -a /opt/steam/hlds/cstrike /opt/steam/cstrike-base

# 11. Entrypoint unico (native x86_64 usa hlds_run; arm64 usa box86 + hlds_linux)
COPY --chown=steam:steam entrypoint.sh /opt/steam/entrypoint.sh
RUN chmod +x /opt/steam/entrypoint.sh

WORKDIR /opt/steam/hlds
RUN chmod +x hlds_run hlds_linux && echo 10 > steam_appid.txt

ENTRYPOINT ["/opt/steam/entrypoint.sh"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
