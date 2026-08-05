# Servidor Docker de CS 1.6 (ReHLDS)

Imagem multi-plataforma para CS 1.6:

- **linux/amd64** — roda nativamente (binários x86-32).
- **linux/arm64** — roda os mesmos binários x86 sob o emulador **Box86** (x86 -> ARM), compilado durante o build.

## Estrutura / fluxo de dados

| Componente | Onde vive | Detalhe |
|---|---|---|
| Engine (ReHLDS), steamcmd, Metamod | **Na imagem** | Imagem enxuta, sem conteúdo pesado |
| Conteúdo do jogo (mapas, addons, configs) | **Bind-mount `./cstrike`** | Editável sem rebuild |
| Base mínima de fallback | `cstrike-base` na imagem | Semear o `./cstrike` se vier vazio |

O `./cstrike/` é montado como volume: para adicionar/remover **mapas**, basta
editar a pasta e reiniciar o container — **sem rebuild da imagem**.

## Pré-requisitos

- Docker (a imagem já está publicada no Docker Hub, não precisa de Buildx).
- Para execução **arm64**: uma máquina ARM64 real (Raspberry Pi, NAS, nuvem ARM).

## Uso rápido

```bash
git clone https://github.com/quantux/cstrike-1.6-docker
cd cstrike-1.6-docker

# amd64 (padrao)
docker compose up -d

# arm64
PLATFORM=linux/arm64 TAG=arm64 docker compose up -d
```

A imagem `quantux1/cstrike-1.6-docker:latest` (e `:arm64`) é puxada do
**Docker Hub**, sem build local.

## Senhas (RCON / entrada)

As senhas ficam hardcoded no `docker-compose.yaml` (variáveis `RCON_PASSWORD`
e `SV_PASSWORD`), com valores de exemplo `admin123`/`ggwp`. O entrypoint as
injeta no `server.cfg` a cada start.

Para usar as reais: edite o compose localmente e aplique — **sem rebuild**:

```bash
docker compose up -d
```

> Aviso: `docker-compose.yaml` é versionado no git. Troque os valores
> localmente e **não commite** as senhas reais — commit apenas os exemplos.

## Conectar

1. No jogo: **password `$SV_PASSWORD`**
2. **connect `[ip]`**

## Gerenciamento (via rcon)

`rcon_password $RCON_PASSWORD`

## Build manual da imagem (para contribuir/manter)

Para quem quiser buildar e publicar a imagem multiarquitetura:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quantux1/cstrike-1.6-docker:latest --push .
```

Para o build de arm64, são necessários Docker com Buildx e uma máquina ARM64
real (ou `docker buildx build --push --platform linux/arm64` em um host com
QEMU/emulação arm64).

| Ação | Comando |
|---|---|
| Preencher bots | `rcon yb fill team` |
| Adicionar bot (T) | `rcon yb add t` |
| Adicionar bot (CT) | `rcon yb add ct` |
| Remover todos os bots | `rcon yb kickall` |
| Ver dificuldade | `rcon yb_difficulty` |
| Definir dificuldade (0-4) | `rcon yb_difficulty <0-4>` |
| Mudar de mapa | `rcon changelevel de_dust2_fundo` |

## Adicionar / remover mapas (sem rebuild)

Os mapas vivem em `./cstrike/maps` (montado por volume):

1. Copie o `.bsp` para `./cstrike/maps/` (ou remova o que não quer).
2. (Opcional) edite `./cstrike/mapcycle.txt`.
3. `docker compose restart cs-server`

Não é preciso rebuildar a imagem.

## Healthcheck

O compose define um `healthcheck` que verifica o processo do servidor e o
socket UDP em `27015`. Com `restart: unless-stopped`, o container é reiniciado
automaticamente se ficar inacessível.

## Versões fixadas (reproduitibilidade)

| Dependência | Versão |
|---|---|
| Imagem base | `debian:bookworm-slim` (por digest) |
| Box86 | `0.3.8` (checksum sha256 verificado) |
| ReHLDS | `3.13.0.788` |
| Metamod-R | `1.3.0.149` |

> **ReHLDS 3.13.0.788 é obrigatório** no caminho ARM64: a 3.14.x não sobe sob
> Box86 (`Can not retrive filesystem interface version 'VFileSystem009'.`).

## Como a base é obtida

`dependencies/lib/hlds.install` usa o **steamcmd** para baixar o HLDS base
(app 90, branch `steam_legacy`). No amd64 o wrapper `steamcmd.sh` cuida do
auto-restart (código 42); no arm64 o binário roda sob Box86 e o retry é feito
no próprio `Dockerfile`. Os binários do engine/plugins vêm de `dependencies/`.