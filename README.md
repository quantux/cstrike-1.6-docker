# Servidor Docker de CS 1.6
Para rodar o projeto:
1. Clonar com:
  - git clone https://github.com/quantux/cstrike-1.6-docker
2. Rodar com:
  - docker compose up -d

### Ao iniciar o jogo, coloque a senha e entre no server:
password ggwp
connect <ip>

### Para gerenciar o servidor:
  - rcon_password admin123

### Para gerenciar os bots:
  - rcon yb fill team
  - rcon yb add t
  - rcon yb add ct
  - rcon yb kickall
  - rcon yb_difficulty # para ver a dificuldade atual
  - rcon yb_difficulty <0-4> # para setar a dificuldade

### Para mudar de mapa:
  - rcon changelevel de_dust2_fundo
