# Servidor Docker de CS 1.6
### Para rodar o projeto:
- Clonar com: <br>
  git clone https://github.com/quantux/cstrike-1.6-docker
- Rodar com: <br>
  docker compose up -d

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
