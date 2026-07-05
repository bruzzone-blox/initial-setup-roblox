# Spec: Scaffold de projeto Roblox com Rojo (para rodar no Claude Code)

> Documento de especificação. Cole no Claude Code na raiz de uma pasta vazia
> e peça para ele executar. Ele deve seguir esta spec à risca, respeitar os
> **não-objetivos** e parar nos pontos marcados como **AÇÃO MANUAL**.

---

## 1. Objetivo

Criar, do zero, a estrutura de um projeto de jogo Roblox tratado como software
profissional: código Luau versionado em git, com toolchain fixado, lint,
formatter e sync ao vivo para o Roblox Studio via Rojo.

O alvo desta etapa é **provar o pipeline ponta a ponta** (código no disco →
Studio ao vivo). Gameplay real vem depois, em cima deste scaffold.

## 2. Contexto e divisão de trabalho (leia antes de agir)

- **Claude Code cuida do código.** Toda lógica em Luau: server scripts,
  client scripts, ModuleScripts, configs do toolchain, git.
- **Roblox Studio cuida do visual e dos assets.** Mapa, Parts, modelagem 3D,
  UI no editor, física, e principalmente **testar/jogar** (Play). Isso NÃO é
  responsabilidade do Claude Code e não deve ser simulado nem "gerado".
- **Rojo é a ponte.** Sincroniza os arquivos `.luau` do disco para dentro da
  árvore de Instances do Studio em tempo real.

Se em algum momento a tarefa parecer pedir manipulação direta da cena 3D ou do
Studio, isso está fora do escopo — pare e sinalize, não invente.

## 3. Ambiente alvo

- SO: Windows, com Roblox Studio instalado na mesma máquina.
- Ponto de partida: repositório novo, do zero.
- Gerenciador de toolchain: **Rokit**.
- Sync: **Rojo**.
- Sem package manager (Wally) nesta etapa — ver não-objetivos.

## 4. Não-objetivos (restrições explícitas)

- NÃO adicionar Wally nem nenhuma dependência externa agora. O repo ainda não
  tem lib externa; adicionar package manager só agrega config sem benefício.
- NÃO gerar código de gameplay (inventário, combate, economia, etc.) nesta
  etapa. Só o "hello world" de validação.
- NÃO tentar instalar o plugin do Rojo no Studio nem abrir o Studio — isso é
  ação manual do usuário.
- NÃO criar assets, modelos ou UI.

## 5. Pré-requisitos que são AÇÃO MANUAL do usuário

Estas duas etapas o Claude Code NÃO executa. Ele deve apenas documentá-las no
README e lembrar o usuário ao final:

1. **Instalar o Rokit** no Windows (script oficial de instalação do repositório
   `rojo-rbx/rokit`). Depois disso, `rokit` fica disponível no PATH.
2. **Instalar o plugin do Rojo dentro do Studio** (via Creator Store ou o
   binário do release do `rojo-rbx/rojo`). Sem esse plugin, o sync não funciona.

## 6. Estrutura a criar

```
<raiz>/
├── rokit.toml              # versões fixadas de rojo, selene, stylua
├── default.project.json    # mapeia pastas do disco -> Instances do Studio
├── selene.toml             # config do linter
├── stylua.toml             # config do formatter
├── .gitignore
├── README.md               # setup + como rodar o sync
└── src/
    ├── server/
    │   └── Main.server.luau      # -> ServerScriptService.Main (Script)
    ├── client/
    │   └── Main.client.luau      # -> StarterPlayerScripts.Main (LocalScript)
    └── shared/
        └── Greeting.luau         # ModuleScript -> ReplicatedStorage.Greeting
```

> **Nota (Rojo):** os scripts de entrada usam nomes explícitos
> (`Main.server.luau` / `Main.client.luau`), **não** `init.server.luau` /
> `init.client.luau`. Um `init.*.luau` na raiz de uma pasta mapeada diretamente
> para um serviço faz o Rojo reclassificar o próprio serviço em Script/LocalScript
> (serviços não podem ser reclassificados), o que quebra o sync. Arquivos
> nomeados viram Instances-filhas dentro do serviço, que é o comportamento
> desejado.

## 7. Requisitos por arquivo

### 7.1 `rokit.toml`
- Inicializar com `rokit init` e adicionar as ferramentas com `rokit add`, de
  forma que as **versões estáveis mais recentes** sejam resolvidas
  automaticamente (não chutar números de versão à mão).
- Ferramentas obrigatórias: `rojo-rbx/rojo`, `Kampfkarren/selene`,
  `JohnnyMorganz/StyLua`.
- Ao final, `rokit.toml` deve conter as três ferramentas na seção `[tools]`.

### 7.2 `default.project.json`
Este é o arquivo mais crítico. Deve mapear:
- `src/server`  → `ServerScriptService`
- `src/client`  → `StarterPlayer` → `StarterPlayerScripts`
- `src/shared`  → `ReplicatedStorage`

Definir `name` do projeto e garantir que o `tree` reflita exatamente esse
mapeamento. Qualquer erro aqui quebra o sync inteiro, então validar a sintaxe.

### 7.3 `selene.toml`
- Configurar com o `std` apropriado para Roblox (biblioteca padrão `roblox`).
- Manter regras default; sem customização agressiva nesta etapa.

### 7.4 `stylua.toml`
- Configuração padrão sensata para Luau (largura de linha, indentação).
- Objetivo é só ter formatter determinístico no repo.

### 7.5 `.gitignore`
- Ignorar artefatos de build (`*.rbxl`, `*.rbxlx`, lock/backups do Studio),
  pastas de ferramentas locais e sujeira de SO.

### 7.6 Scripts de validação (hello world)
- `src/server/Main.server.luau`: ao rodar, dá `print` confirmando que o servidor
  subiu e consome o ModuleScript de `shared`.
- `src/shared/Greeting.luau`: ModuleScript que exporta uma função simples
  (ex.: retorna uma saudação) — serve para provar o `require` cross-context.
- `src/client/Main.client.luau`: `print` mínimo confirmando execução no cliente.

> Ver a nota da seção 6 sobre por que os arquivos são `Main.*.luau` e não
> `init.*.luau`.

Nada além disso. O propósito é único: verificar que o pipeline funciona.

### 7.7 `README.md`
Deve conter, em português:
- As duas AÇÕES MANUAIS da seção 5.
- A sequência de sync da seção 8.
- Um lembrete claro da divisão de trabalho (código no Claude Code, visual/Play
  no Studio).

## 8. Sequência de sync (documentar no README, não executar)

1. `rokit install` — baixa as ferramentas nas versões fixadas.
2. `rojo serve` — sobe o servidor de sync local.
3. No Studio: abrir um place em branco e clicar em **Connect** no plugin do Rojo.
4. A partir daí, edições em `src/` aparecem no Studio ao vivo; usar **Play**
   para testar.

## 9. Critérios de aceitação

- [ ] Todos os arquivos da seção 6 existem com conteúdo coerente.
- [ ] `rokit.toml` lista rojo, selene e StyLua com versões resolvidas.
- [ ] `default.project.json` tem sintaxe JSON válida e o mapeamento da 7.2.
- [ ] `git init` feito e um commit inicial criado.
- [ ] `selene src` e `stylua --check src` rodam sem erro nos arquivos gerados
      (rodar como verificação; se `rokit install` foi executado).
- [ ] README cobre as ações manuais e a sequência de sync.
- [ ] Nenhum arquivo de Wally, nenhuma dependência externa, nenhum código de
      gameplay.

## 10. Ordem de execução sugerida para o Claude Code

1. `git init` na raiz.
2. `rokit init` e `rokit add` das três ferramentas.
3. `rokit install`.
4. Criar `default.project.json`, `selene.toml`, `stylua.toml`, `.gitignore`.
5. Criar a árvore `src/` com os três scripts de validação.
6. Rodar `stylua src` e `selene src` para validar.
7. Escrever o `README.md`.
8. Commit inicial.
9. Encerrar imprimindo as duas AÇÕES MANUAIS pendentes para o usuário.

## 11. Regras de conduta para esta tarefa

- Se algo na spec parecer ambíguo ou tecnicamente equivocado, **discordar e
  apontar** antes de prosseguir — não seguir cegamente.
- Não expandir o escopo por conta própria (nada de Wally, gameplay ou assets).
- Parar e pedir confirmação se precisar tomar uma decisão estrutural não coberta
  aqui.
