---
name: guia-pm-chief-of-staff
description: Orienta desenvolvimento e verificação do plugin pm-chief-of-staff. Use antes de alterar skills, sementes, manifests, adapters ou hooks deste repositório.
---

# Guia do repositório

Este repositório é o plugin e seu marketplace. O produto é feito de instruções Markdown e scripts POSIX sh, sem dependências externas instaladas pelo plugin.

## Mapa

* `skills/`: cinco workflows do plugin, registrados pelos manifests.
* `seeds/`: seis workflows copiados para a pasta da pessoa, fora do registro do plugin.
* `modulos/`: templates compartilhados e ponte de descoberta do Codex.
* `agents/ai-tells-reviewer.md`: fonte do protocolo do revisor independente.
* `.claude-plugin/`: identidade e marketplace Claude; `.codex-plugin/`: identidade e hooks do Codex.
* `hooks/`: boot de memória e sua suíte. O script roda na pasta da pessoa, não na raiz do plugin.
* `testes/`: provas determinísticas da ponte e da descoberta local.
* `.vibeflow/`: contexto e relatórios locais, ignorados pelo git.

## Verificação

Rode `sh hooks/boot-memoria-teste.sh` e `sh testes/ponte-codex-teste.sh`. A descoberta real exige `codex` no PATH; os casos sem ele não provam essa parte. Rode também `git diff --check` e `claude plugin validate .`.

Alteração em skill ou agente exige E2E em pasta temporária: `claude -p "<gatilho>" --plugin-dir <raiz-do-plugin> --permission-mode acceptEdits --output-format stream-json --verbose`. O evento `init` comprova skills e agentes registrados. Uma chamada com `--agent pm-chief-of-staff:ai-tells-reviewer` comprova as ferramentas do revisor. Use conta já autenticada, dados fictícios e registre o resultado real. Grep/Glob da sessão principal e do agente podem diferir, então confira o `init` em vez de assumir.

No Codex, `codex debug prompt-input` prova descoberta de skills sem chamar modelo. Ele não prova execução, instalação do pacote ou boot confiado. E2E de setup e retomada exige sessões novas com modelo. Instalação de plugin altera configuração persistente; confiança de hooks é revista pelo mecanismo normal do runtime, sem bypass nos testes.

## Contratos

Arquivos personalizados têm uma fonte em `.claude/skills/`; `.agents/skills` é descoberta derivada. Preserve arquivos e links preexistentes. Só altere wrappers comprovadamente gerados pela ponte. Casos de sobrescrita, links, falha de escrita e caminhos com espaços exigem prova de comportamento.

`AGENTS.md` é o manual gerado; `CLAUDE.md` é sua ponte de uma linha. Regras situacionais continuam em `.claude/rules/` e precisam de índice no `AGENTS.md` para runtimes sem carga nativa de `paths:`. Alteração nos dois manifests mantém a mesma versão. Mudanças no setup que também existam no `PROMPT.md` precisam chegar ao colável antes da release.
