# Project: pm-chief-of-staff
> Analyzed: 2026-07-30
> Stack: Claude Code plugin, 100% conteúdo (9 markdown + 2 manifests JSON), zero código executável e zero dependências
> Type: plugin de distribuição de skills e sementes (o repo é o próprio marketplace)
> Suggested budget: ≤ 4 files per task

## Structure
Repo é marketplace e plugin ao mesmo tempo (`marketplace.json` com `source: "./"`). Skills do plugin em `skills/` viram comandos `/pm-chief-of-staff:*`; sementes em `seeds/` ficam fora do registro e só existem pro usuário depois de plantadas na pasta dele (`.claude/skills/`). README é a landing de instalação; PROMPT.md é o plano B colável sem plugin.

## Structural Units
- `.claude-plugin/` , manifests: plugin.json (semver, dispara auto-update) e marketplace.json
- `skills/setup/` , o produto principal: discovery em 7 blocos que gera o sistema da pessoa (CLAUDE.md, CRITICAL_FACTS, hubs, pastas) e planta as 4 sementes
- `skills/plantar/` , plantio avulso de semente do catálogo, com checagem de colisão
- `seeds/` , 4 skills starter que viram arquivos do usuário: abrir-dia, fechar-dia (par que fecha o loop diário), preparar-conversa, processar-reuniao (par pré/pós conversa)
- `README.md` , landing: instalação em 3 comandos, modelo de sementes, memória em 4 camadas, privacidade
- `PROMPT.md` , versão colável do setup pra quem não tem o plugin

## Pattern Registry

<!-- vibeflow:patterns:start -->
patterns:
  - file: patterns/skill-authoring.md
    tags: [skills, frontmatter, triggers, claude-code, authoring]
    modules: [skills/, seeds/]
  - file: patterns/seed-model.md
    tags: [seeds, lifecycle, ownership, updates, distribution]
    modules: [seeds/, skills/setup/, skills/plantar/]
  - file: patterns/writing-canon.md
    tags: [writing, style, canon, anti-tells, pt-br, tone]
    modules: [skills/, seeds/, ./]
  - file: patterns/system-contracts.md
    tags: [contracts, memory, labels, integration, folders]
    modules: [seeds/, skills/setup/]
<!-- vibeflow:patterns:end -->

## Pattern Docs Available
- [patterns/skill-authoring.md](patterns/skill-authoring.md) , anatomia de um SKILL.md: frontmatter com gatilhos literais, fluxo numerado, "Quando NÃO usar"
- [patterns/seed-model.md](patterns/seed-model.md) , ciclo de vida da semente: catálogo → plantio por cópia → arquivo do usuário, nunca sobrescrito
- [patterns/writing-canon.md](patterns/writing-canon.md) , cânone de escrita que o repo segue e propaga (sem travessão, factual, anti-tells)
- [patterns/system-contracts.md](patterns/system-contracts.md) , rótulos e paths que ligam as skills via arquivos do usuário; quebrar um lado quebra o loop

## Key Files
- `skills/setup/SKILL.md` , 166 linhas, o coração: discovery, princípios, anti-padrões, arquitetura de memória, plantio
- `skills/plantar/SKILL.md` , catálogo e plantio avulso
- `seeds/abrir-dia/SKILL.md` , abre o dia: agenda + backlog + 3 do dia calibradas contra horas livres
- `seeds/fechar-dia/SKILL.md` , fecha o dia: avalia as 3, classifica motivo, semeia `**→ amanhã:**`
- `seeds/preparar-conversa/SKILL.md` , pauta por tipo (liderado, líder, par/stakeholder)
- `seeds/processar-reuniao/SKILL.md` , nota estruturada + propagação (tasks, sinais, hubs, log)
- `README.md` , landing e contrato com o usuário (privacidade, updates)
- `PROMPT.md` , setup colável (plano B)
- `.claude-plugin/plugin.json` , versão que dispara auto-update
- `.claude-plugin/marketplace.json` , o repo como marketplace

## Dependencies (critical only)
Nenhuma. Zero dependência é decisão de produto declarada no README ("Mais nada. Não precisa saber programar").

## Known Issues / Tech Debt
- `plantar` lista o catálogo pela "primeira linha após o título", mas as 4 sementes têm banner idêntico nessa posição: a listagem mostraria a mesma frase 4 vezes (fix: ler description do frontmatter).
- `abrir-dia` usa `grep "^- \[ \]"` ancorado em início de linha: perde subtask indentada.
- Discovery do setup não persiste resposta até o fim (proposta só depois dos 7 blocos): sessão que cai no bloco 6 perde a conversa.
- "Fechar dias e semanas" prometido em PROMPT.md e setup; semente de semana não existe.
- Blocos 3, 5 e 6 do discovery (ferramentas, rituais, dores) sem destino declarado nos artefatos gerados.
