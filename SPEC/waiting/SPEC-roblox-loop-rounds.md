# Spec: Loop de rounds com lava subindo (para rodar no Claude Code)

> Documento de especificação. Cole no Claude Code na raiz do projeto
> `initial-setup-roblox` (que já tem o pipeline Rojo validado) e peça para ele
> implementar. O Claude Code deve seguir esta spec à risca, respeitar os
> **não-objetivos** e os **requisitos de design obrigatórios**, e parar para
> pedir confirmação em qualquer decisão estrutural não coberta aqui.

---

## 1. Objetivo

Implementar o primeiro jogo funcional sobre o scaffold já existente: um **loop
de rounds** com uma mecânica de sobrevivência (lava subindo, último de pé
vence). O foco é validar arquitetura — máquina de estados, servidor
autoritativo, comunicação cliente-servidor e ciclo de vida do jogador. Não é
sobre acabamento visual.

## 2. Contexto e divisão de trabalho (leia antes de agir)

- **Claude Code cuida do código.** Toda a lógica em Luau, incluindo a geração
  da geometria da arena por código.
- **Roblox Studio cuida de testar** (Play) e, no futuro, de assets importados.
- **Rojo** já está configurado e sincroniza `src/` → Studio ao vivo. O pipeline
  da fase 1 já foi validado (os `print` de hello-world já apareceram no Output).

Princípio que guia todas as decisões abaixo: **o servidor é a única fonte de
verdade.** Ele decide estado da partida, quem está vivo e quem venceu. O cliente
só exibe o que o servidor manda. Isso é o que impede trapaça.

## 3. Estado atual do projeto

- Scaffold pronto: `rokit.toml`, `default.project.json`, `selene.toml`,
  `stylua.toml`, `.gitignore`, `README.md` e a árvore `src/` com hello-world.
- Ferramentas instaladas via Rokit: rojo, selene, StyLua.
- Os arquivos hello-world (`Main.server.luau`, `Main.client.luau` e
  `src/shared/Greeting.luau`) devem ser **substituídos/removidos** por esta
  implementação. `Greeting.luau` deixa de existir.

## 4. Decisões travadas (não reabrir)

Estas já foram decididas. Implementar exatamente assim, sem propor alternativas:

1. **Evento único** `GameStateUpdate` (servidor → clientes), com payload
   `{ state, timeRemaining, aliveCount, winnerName? }`. Não criar múltiplos
   RemoteEvents.
2. **Eliminação por altura no servidor** (checagem por Heartbeat), não pelo
   evento `Touched` da lava.
3. **Toda a geometria é gerada por código** (plataforma, pilares, lobby, lava).
   Nada é construído manualmente no Studio.

## 5. Requisitos de design obrigatórios

Dois pontos que NÃO são óbvios e cuja ausência quebra o jogo. São requisitos,
não sugestões:

1. **Gradiente de altura para a lava.** Uma plataforma plana com lava subindo
   elimina todos os jogadores no mesmo instante — não produz "último de pé".
   Portanto, o gerador de arena DEVE criar, além da plataforma, um conjunto de
   **pilares de alturas variadas**. Assim quem fica no chão morre primeiro, quem
   sobe nos pilares mais altos sobrevive mais, e sobra um vencedor.

2. **Modo de desenvolvimento para teste solo.** A regra "sobrou 1 jogador, o
   round acaba" encerraria a partida instantaneamente quando há só 1 jogador
   (útil para testar sozinho no Studio). Portanto:
   - `Config` tem `DEV_MODE`; quando ligado, o mínimo de jogadores efetivo é 1.
   - A condição de fim do round DEVE considerar quantos jogadores começaram:
     com 2+ participantes, o round acaba quando sobra 1 ou 0; com 1 participante
     (solo), o round só acaba quando esse jogador morre ou o tempo esgota.

## 6. Não-objetivos (restrições explícitas)

- NÃO implementar combate, dano entre jogadores, habilidades ou projéteis.
- NÃO adicionar persistência (DataStore) nesta fase. Fica para depois.
- NÃO adicionar Wally nem dependências externas.
- NÃO usar assets da Toolbox/Creator Store. Só formas primitivas e material
  built-in.
- NÃO construir nada manualmente no Studio.

## 7. Estrutura de arquivos a implementar

```
src/
├── shared/                       -> ReplicatedStorage
│   ├── Config.luau               # todos os valores ajustáveis
│   ├── GameEnums.luau            # nomes canônicos dos estados
│   └── Remotes.luau              # o RemoteEvent único e helpers
├── server/                       -> ServerScriptService
│   ├── Main.server.luau          # ÚNICO Script; orquestra o boot
│   └── modules/
│       ├── ArenaBuilder.luau     # gera plataforma, pilares, lobby
│       ├── PlayerManager.luau    # spawn, conjunto de vivos, entrada/saída
│       ├── HazardController.luau # lava subindo + eliminação por altura
│       └── RoundManager.luau     # a máquina de estados (coração)
└── client/                       -> StarterPlayerScripts
    ├── Main.client.luau          # ÚNICO LocalScript; inicia o HUD
    └── modules/
        └── HUDController.luau    # ouve o servidor, desenha a UI
```

Padrão obrigatório: **um único ponto de entrada por lado**. Apenas
`Main.server.luau` e `Main.client.luau` são scripts executáveis; todo o resto é
ModuleScript acessado via `require`. Isso mantém a ordem de inicialização
explícita.

## 8. Contrato por módulo

Implementar exatamente estas interfaces públicas.

### shared/Config.luau
Tabela única de constantes. Deve conter, no mínimo:
- `DEV_MODE` (bool), `MIN_PLAYERS` (number).
- `INTERMISSION_DURATION`, `ROUND_DURATION`, `ROUNDEND_DURATION` (segundos).
- Dimensões e centro da plataforma da arena.
- Parâmetros dos pilares: quantidade, tamanho na base, altura mínima e máxima.
- Dimensões e centro do lobby.
- Parâmetros da lava: velocidade de subida, Y inicial do topo, margem de
  eliminação.
- Função `Config.getMinPlayers()` que retorna 1 se `DEV_MODE`, senão
  `MIN_PLAYERS`.

Objetivo: balancear o jogo = editar só este arquivo. Não espalhar números
mágicos pelos outros módulos.

### shared/GameEnums.luau
- `State` com três valores string: `Intermission`, `InRound`, `RoundEnd`.

### shared/Remotes.luau
Um único RemoteEvent chamado `GameStateUpdate`. Interface:
- `init()` — servidor: cria o RemoteEvent em ReplicatedStorage (idempotente).
- `get()` — retorna o RemoteEvent, esperando existir (seguro no cliente).
- `broadcast(payload)` — servidor: envia o payload para todos os clientes.
- `onUpdate(callback)` — cliente: registra callback para cada atualização.

Payload sempre no formato `{ state, timeRemaining, aliveCount, winnerName? }`,
com `winnerName` preenchido só no `RoundEnd`. Comunicação de mão única: o
cliente não envia nada que decida resultado.

### server/modules/ArenaBuilder.luau
Gera toda a geometria por código. Interface:
- `build()` — cria plataforma principal, os pilares de alturas variadas e a
  plataforma de lobby, tudo agrupado num Folder no Workspace. Idempotente
  (reconstrói do zero se chamado de novo).
- `getArenaSpawn()` — retorna `Vector3` de spawn no round, sobre a plataforma,
  com leve dispersão, derivado da geometria criada (não coordenada chumbada).
- `getLobbySpawn()` — retorna `Vector3` da área de espera, derivado da geometria.

Todas as Parts ancoradas. Pilares com alturas sorteadas entre mínimo e máximo do
Config — este é o requisito de gradiente da seção 5.

### server/modules/PlayerManager.luau
Ciclo de vida do jogador. Interface:
- `init()` — trata entrada/saída de jogadores; ao (re)spawnar, manda o jogador
  para o lobby.
- `spawnAllForRound()` — teleporta todos os presentes para a arena e monta o
  conjunto de "vivos". Também deve tratar morte por qualquer causa (queda, dano)
  como eliminação.
- `getAlivePlayers()` — retorna lista dos jogadores vivos e ainda no servidor.
- `getAliveCount()` — retorna a contagem de vivos.
- `eliminate(player)` — remove do conjunto de vivos e teleporta para o lobby.
- `reset()` — limpa o conjunto para o próximo round.

### server/modules/HazardController.luau
A lava. Interface:
- `init()` — nada no boot; a lava é criada em `start()`.
- `start()` — cria/posiciona a lava no Y inicial e passa a subir a cada
  Heartbeat, na velocidade do Config. A cada Heartbeat, para cada jogador vivo,
  se o `HumanoidRootPart.Position.Y` estiver abaixo do topo da lava mais a
  margem de eliminação, chama `PlayerManager.eliminate`.
- `stop()` — para a subida, desconecta o Heartbeat e remove a lava.

A lava deve ser um kill-volume por altura, não por colisão física
(`CanCollide = false`), para evitar empurrar os jogadores.

### server/modules/RoundManager.luau
A máquina de estados. Interface:
- `start()` — inicia o loop de estados, que roda indefinidamente numa corrotina.
- `getState()` — retorna o estado atual.

Comportamento do loop, usando **polling** (consultar `getAliveCount()` por tick,
não arquitetura orientada a eventos):
1. Esperar jogadores suficientes (Intermission).
2. Contagem regressiva do intervalo; se cair abaixo do mínimo, volta a esperar.
3. InRound: `spawnAllForRound()`, `HazardController.start()`, e a cada segundo
   fazer `broadcast` e checar a condição de fim (ver requisito de design 5.2).
4. Ao fim: `HazardController.stop()`, determinar vencedor (o único sobrevivente,
   ou nil se ninguém/empate).
5. RoundEnd: `PlayerManager.reset()`, mostrar o resultado por alguns segundos.
6. Repetir.

A cada transição de estado e a cada tick de cronômetro, chamar
`Remotes.broadcast` com o payload completo.

### server/Main.server.luau
Único Script do servidor. Ordem de boot explícita:
`Remotes.init()` → `ArenaBuilder.build()` → `PlayerManager.init()` →
`HazardController.init()` → `RoundManager.start()`.

### client/Main.client.luau
Único LocalScript. Faz só `HUDController.init()`.

### client/modules/HUDController.luau
UI deliberadamente magra; não decide nada. Interface:
- `init()` — cria um ScreenGui com rótulos (estado, cronômetro, contagem de
  vivos e uma mensagem de resultado) e conecta em `Remotes.onUpdate`.

Ao receber cada update, redesenha os rótulos. No `RoundEnd`, mostra o vencedor
(ou "sem vencedor" quando `winnerName` for nulo).

## 9. Fluxo de estados (resumo)

`Intermission` (esperando jogadores + contagem) → `InRound` (todos na arena,
lava subindo, eliminações) → `RoundEnd` (vencedor exibido) → volta para
`Intermission`.

## 10. Critérios de aceitação

- [ ] Todos os arquivos da seção 7 existem, com as interfaces da seção 8.
- [ ] Hello-world removido (`Greeting.luau` apagado; os dois `Main` reescritos).
- [ ] `ArenaBuilder` gera plataforma, pilares de alturas variadas e lobby por
      código (requisito 5.1 cumprido).
- [ ] Fim de round trata corretamente o caso solo em `DEV_MODE` (requisito 5.2).
- [ ] Um único RemoteEvent `GameStateUpdate`; eliminação por altura no servidor.
- [ ] `stylua --check src` e `selene src` passam sem erro.
- [ ] `rojo build` gera o place sem erro de árvore.
- [ ] Nada de combate, DataStore, Wally ou assets externos.
- [ ] Commit criado ao final.

## 11. Ordem de execução sugerida

1. Remover `Greeting.luau`; preparar os dois `Main` para reescrita.
2. Implementar os três módulos `shared`.
3. Implementar `ArenaBuilder`, `PlayerManager`, `HazardController`,
   `RoundManager`.
4. Reescrever `Main.server.luau` e `Main.client.luau` e o `HUDController`.
5. Rodar `stylua src` e `selene src`; corrigir o que aparecer.
6. Rodar `rojo build` para validar a árvore.
7. Commit.
8. Imprimir para o usuário como testar em `DEV_MODE` (rojo serve, Connect, Play
   sozinho).

## 12. Regras de conduta para esta tarefa

- Se algum ponto da spec parecer tecnicamente equivocado, **discordar e apontar
  antes de implementar** — não seguir cegamente.
- Não expandir o escopo por conta própria. Respeitar os não-objetivos.
- Se precisar tomar uma decisão estrutural não coberta aqui, **parar e pedir
  confirmação** em vez de assumir.
- Não construir nada no Studio nem instruir o usuário a construir — toda a
  geometria é por código.
