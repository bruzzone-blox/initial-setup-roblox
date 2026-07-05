# initial-setup-roblox

Scaffold de um projeto de jogo Roblox tratado como software profissional: código
Luau versionado em git, toolchain fixado com **Rokit**, lint (**selene**),
formatter (**StyLua**) e sync ao vivo para o Roblox Studio via **Rojo**.

O objetivo desta etapa é **provar o pipeline ponta a ponta** — código no disco →
Studio ao vivo. Não há gameplay aqui, apenas os scripts "hello world" de
validação.

## Divisão de trabalho

- **Código (Claude Code / este repo):** toda a lógica em Luau — server scripts,
  client scripts, ModuleScripts, config do toolchain e git.
- **Visual e assets (Roblox Studio):** mapa, Parts, modelagem 3D, UI no editor,
  física e, principalmente, **testar/jogar** (botão **Play**). Isso é feito no
  Studio, não neste repositório.
- **Rojo é a ponte:** sincroniza os arquivos `.luau` do disco para dentro da
  árvore de Instances do Studio em tempo real.

## Estrutura

```
.
├── rokit.toml              # versões fixadas de rojo, selene, StyLua
├── default.project.json    # mapeia pastas do disco -> Instances do Studio
├── selene.toml             # config do linter (std roblox)
├── stylua.toml             # config do formatter
├── .gitignore
└── src/
    ├── server/Main.server.luau   # -> ServerScriptService.Main (Script)
    ├── client/Main.client.luau   # -> StarterPlayerScripts.Main (LocalScript)
    └── shared/Greeting.luau       # -> ReplicatedStorage.Greeting (ModuleScript)
```

> **Nota técnica sobre os nomes dos scripts.** A spec sugeria
> `init.server.luau` / `init.client.luau` na raiz das pastas. No Rojo, um
> `init.*.luau` na raiz de uma pasta mapeada **diretamente para um serviço**
> transforma o próprio serviço num Script/LocalScript (serviços não podem ser
> reclassificados), o que quebra o sync. Por isso os scripts de entrada são
> arquivos **nomeados** (`Main.*.luau`), que viram *filhos* Script/LocalScript
> dentro do serviço correto — o mapeamento pasta→serviço da spec foi mantido.

## Pré-requisitos — AÇÃO MANUAL do usuário

Estas duas etapas **não** são feitas por este repositório. Faça-as você mesmo:

1. **Instalar o Rokit** (Windows), seguindo o script oficial de instalação do
   repositório [`rojo-rbx/rokit`](https://github.com/rojo-rbx/rokit). Depois
   disso, `rokit` fica disponível no PATH.
2. **Instalar o plugin do Rojo dentro do Studio**, via Creator Store ou o
   binário do release de [`rojo-rbx/rojo`](https://github.com/rojo-rbx/rojo).
   **Sem esse plugin o sync não funciona.**

## Sequência de sync

Na raiz do repositório:

1. `rokit install` — baixa as ferramentas nas versões fixadas em `rokit.toml`.
2. `rojo serve` — sobe o servidor de sync local.
3. No **Studio**: abra um place em branco e clique em **Connect** no plugin do
   Rojo.
4. A partir daí, edições em `src/` aparecem no Studio ao vivo. Use **Play** para
   testar.

Ao dar Play com o sync ativo, o Output do Studio deve mostrar:

```
[server] ServerScriptService subiu com sucesso.
[server] Hello, Servidor! O pipeline Rojo esta funcionando.
[client] StarterPlayerScripts executou no cliente.
```

Isso confirma o pipeline: server rodando, `require` cross-context do
ModuleScript em `ReplicatedStorage`, e client rodando.

## Comandos úteis (opcionais)

- `stylua src` — formata os scripts.
- `stylua --check src` — verifica formatação sem alterar.
- `selene src` — roda o linter.
