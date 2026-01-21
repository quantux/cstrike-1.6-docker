SERVIDOR DOCKER DE CS 1.6

Este projeto permite rodar um servidor de Counter-Strike 1.6 usando Docker,
com suporte a bots via YAPB e configuração de senha.

=============================================================
PARA RODAR O PROJETO

1. Clonar o repositório:
   git clone https://github.com/quantux/cstrike-1.6-docker

2. Subir o servidor:
   docker compose up -d

=============================================================
ENTRANDO NO SERVIDOR

Ao iniciar o jogo, use os seguintes comandos no console do CS 1.6:

- Inserir a senha do servidor:
  password ggwp

- Conectar ao servidor:
  connect [IP_DO_SERVIDOR]

Dica: se você entrar pelo navegador de servidores, a tela de senha aparecerá automaticamente.

=============================================================
GERENCIANDO O SERVIDOR

Senha RCON para executar comandos administrativos:
  rcon_password admin123

=============================================================
GERENCIANDO OS BOTS (YAPB)

- Preencher times automaticamente:
  rcon yb fill team

- Adicionar bot Terrorista:
  rcon yb add t

- Adicionar bot Counter-Terrorista:
  rcon yb add ct

- Remover todos os bots:
  rcon yb kickall

- Ver dificuldade atual dos bots:
  rcon yb_difficulty

- Ajustar dificuldade dos bots (0-4):
  rcon yb_difficulty <0-4>

Valores de dificuldade:
  0 - Easy
  1 - Normal
  2 - Hard
  3 - Expert
  4 - Custom/Variante

=============================================================
MUDANDO DE MAPA

- Trocar o mapa atual:
  rcon changelevel de_dust2_fundo

Você pode usar qualquer mapa disponível no diretório cstrike/maps.
