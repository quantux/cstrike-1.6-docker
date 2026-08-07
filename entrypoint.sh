#!/bin/bash
# Entrypoint unico (amd64 + arm64).
#   - amd64: executa o hlds_run (wrapper nativo).
#   - arm64: executa o hlds_linux (x86) sob o emulador Box86.
# Se o volume de conteudo (cstrike) vier vazio/ausente, semeia a partir da
# copia-base da imagem (/opt/steam/cstrike-base), mantendo a imagem enxuta.
set -e

HLDS_DIR=/opt/steam/hlds
cd "$HLDS_DIR"

# Diretorios onde o Box86 busca bibliotecas x86 (i386 do sistema + steamcmd/HLDS)
export BOX86_LD_LIBRARY_PATH="${BOX86_LD_LIBRARY_PATH:-/usr/lib/i386-linux-gnu:/opt/steam/linux32}"

# Steam SDK fix
mkdir -p ~/.steam && ln -sf /opt/steam/linux32 ~/.steam/sdk32

# Seed: se nao houver conteudo do jogo, copia a base minima da imagem
if [ ! -d "$HLDS_DIR/cstrike" ] || [ -z "$(ls -A "$HLDS_DIR/cstrike" 2>/dev/null)" ]; then
    if [ -d /opt/steam/cstrike-base ]; then
        echo "cstrike vazio; semeando base da imagem em /opt/steam/hlds/cstrike"
        mkdir -p "$HLDS_DIR/cstrike"
        cp -a /opt/steam/cstrike-base/. "$HLDS_DIR/cstrike/"
    fi
fi

# Senhas (RCON / entrada) definidas em .env e passadas via compose.
# Sao aplicadas no server.cfg em runtime — editar o .env nao exige rebuild.
CONFIG="$HLDS_DIR/cstrike/server.cfg"

apply_cvar() {
    local key="$1" value="$2"
    if [ -n "$value" ]; then
        local value_escaped
        value_escaped=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
        if grep -qE "^${key} " "$CONFIG"; then
            sed -i "s|^${key} .*|${key} \"${value_escaped}\"|" "$CONFIG" \
                || echo "aviso: nao foi possivel atualizar ${key} em ${CONFIG}"
        else
            printf '%s "%s"\n' "$key" "$value" >> "$CONFIG" \
                || echo "aviso: nao foi possivel adicionar ${key} em ${CONFIG}"
        fi
    else
        # Valor vazio: remove qualquer senha existente para abrir o servidor.
        sed -i "/^${key} .*/d" "$CONFIG" \
            || echo "aviso: nao foi possivel remover ${key} em ${CONFIG}"
    fi
    return 0
}

apply_cvar rcon_password "$RCON_PASSWORD"
apply_cvar sv_password "$SV_PASSWORD"

# Regras de jogo / rotacao de mapas configuraveis via env (compose).
# Default: mapa dura para sempre (sem tempo/rounds/vitorias). Para ciclo
# automatico, defina um limite > 0 e o MAPCYCLE desejado.
apply_cvar mp_timelimit "$MP_TIMELIMIT"
apply_cvar mp_maxrounds "$MP_MAXROUNDS"
apply_cvar mp_winlimit "$MP_WINLIMIT"

# Rotacao de mapas: se MAPCYCLE for fornecido, semeia o mapcycle.txt.
# Ex.: "de_dust2 de_aztec de_dust" (mapas espacados por espaco)
if [ -n "${MAP_CYCLE:-}" ]; then
    printf '%s\n' $MAP_CYCLE > "$HLDS_DIR/cstrike/mapcycle.txt"
fi

# Executa o servidor: Box86 (arm64) ou nativo (amd64)
if command -v box86 >/dev/null 2>&1; then
    exec box86 ./hlds_linux -game cstrike "$@"
fi

exec ./hlds_run -game cstrike "$@"
