#!/bin/bash
# Entrypoint para ARM64 (aarch64).
# O engine HLDS/ReHLDS é um binário x86 (32 bits). Numa máquina ARM64 ele é
# executado sob o emulador Box86, que traduz as chamadas x86 para as
# bibliotecas ARM32 nativas (armhf) já instaladas na imagem.
set -e

HLDS_DIR=/opt/steam/hlds
cd "$HLDS_DIR"

# Diretórios onde o Box86 busca bibliotecas x86 (i386 do sistema + steamcmd/HLDS)
export BOX86_LD_LIBRARY_PATH="${BOX86_LD_LIBRARY_PATH:-/usr/lib/i386-linux-gnu:/opt/steam/linux32}"

# Steam SDK fix (mesmo comportamento do projeto x86)
mkdir -p ~/.steam && ln -sf /opt/steam/linux32 ~/.steam/sdk32

# Executa o binário do servidor (x86) sob o Box86, com o modo de jogo cstrike
exec box86 ./hlds_linux -game cstrike "$@"