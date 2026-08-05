# Servidor Docker de CS 1.6
### Para rodar o projeto:
Clonar com: <br>
git clone https://github.com/quantux/cstrike-1.6-docker
<br><br>
Rodar com: <br>
docker compose up -d

### Suporte a ARM64 (aarch64):
O projeto original usa binários x86 (32 bits) para o engine (ReHLDS) e todos os
plugins (Metamod-R, AMX Mod X, YaPB etc.), que **não rodam nativamente** em
processadores ARM64. Para isso, a imagem `linux/arm64` reutiliza esses mesmos
binários e os executa sob o emulador **Box86** (x86 -> ARM), dentro de um
container nativo aarch64. Os bots (YaPB) e todo o restante continuam funcionando
idênticos ao x86, pois rodam no mesmo processo emulado.

- Base: `debian:bookworm-slim` (aarch64), com multiarch `armhf` (libs ARM32 que
  o Box86 embrulha) e `i386` (libs x86 que o Box86 carrega emuladas).
- O Box86 é compilado para aarch64 a partir do código-fonte durante o build.
- O steamcmd é executado sob Box86 para baixar a base HLDS (mesmo fluxo do x86).
- **ReHLDS 3.13.0.788 obrigatório** no caminho ARM64: a 3.14.x não sobe sob Box86
  (erro `Can not retrive filesystem interface version 'VFileSystem009'.`).

> **Use uma máquina ARM64 real** (Raspberry Pi, NAS com arm64, nuvem ARM etc.)
> para build e execução. A compilação do Box86 roda de forma nativa e confiável
> nessas máquinas.

```
docker compose -f docker-compose.arm64.yaml up -d --build
```

Ou, com build manual:

```
docker buildx build --platform linux/arm64 -t cstrike-1.6-docker:arm64 .
docker run -d --name cstrike-1.6-docker-arm64 \
  -p 27015:27015 -p 27015:27015/udp \
  -v "$(pwd)/cstrike:/opt/steam/hlds/cstrike" \
  cstrike-1.6-docker:arm64 +map de_dust2 +maxplayers 16
```

### Ao iniciar o jogo, coloque a senha e entre no server:
password ggwp<br>
connect [ip]

### Para gerenciar o servidor:
rcon_password admin123

### Para gerenciar os bots:
rcon yb fill team<br>
rcon yb add t<br>
rcon yb add ct<br>
rcon yb kickall<br>
rcon yb_difficulty # para ver a dificuldade atual<br>
rcon yb_difficulty <0-4> # para setar a dificuldade<br>

### Para mudar de mapa:
rcon changelevel de_dust2_fundo
