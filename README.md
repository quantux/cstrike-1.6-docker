# Servidor Docker de CS 1.6
Para rodar o projeto, não precisa clonar esse repositório inteiro do github.
Apenas faça o download do server.cfg desse repositório, e monte o arquivo como volume para dentro do container no docker-compose.yaml:
  - ./server.cfg:/opt/steam/hlds/cstrike/server.cfg

Depois, rodar o docker compose up -d

---
Para gerenciar:
Primeiro, logar com:
  - rcon_password senha

Comandos mais usados para bots:
  - rcon yb fill team
  - rcon yb add t
  - rcon yb add ct
  - rcon yb kickall
  - rcon yb_difficulty 0-4

---
Esse reposisótio contém um pack extenso de mapas na pasta cstrike.
Portanto, ele é bem pesado.
