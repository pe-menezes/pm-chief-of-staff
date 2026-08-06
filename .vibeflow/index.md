# Project: pm-chief-of-staff
> Analyzed: 2026-08-06 (incremental sobre a análise de 2026-07-30; repo em v0.3.0)
> Stack: Claude Code plugin. 15 markdown de produto (fora de `.vibeflow/`), 3 manifests JSON e 1 hook em POSIX sh; zero dependência externa
> Type: plugin de distribuição de skills e sementes (o repo é o próprio marketplace)
> Suggested budget: ≤ 4 files per task

## Structure
Repo é marketplace e plugin ao mesmo tempo (`marketplace.json` com `source: "./"`). Quatro skills em `skills/` viram comandos `/pm-chief-of-staff:*`; seis sementes em `seeds/` ficam fora do registro e só existem pro usuário depois de plantadas na pasta dele (`.claude/skills/`). `modulos/` guarda template de módulo compartilhado, que também é plantado. `hooks/hooks.json` registra o único executável do repo (`boot-memoria.sh`, SessionStart nos matchers `startup` e `clear`). README é a landing de instalação; PROMPT.md é o plano B colável sem plugin, e espelha a régua do setup.

## Structural Units
- `.claude-plugin/` , manifests: plugin.json (semver, dispara auto-update) e marketplace.json
- `skills/setup/` , o produto principal: discovery em 7 blocos que gera o sistema da pessoa (CLAUDE.md, CRITICAL_FACTS, hubs, pastas, `.claude/rules/`, `.claude/skills/_shared/`) e planta 5 sementes
- `skills/plantar/` , plantio avulso de semente do catálogo, com checagem de colisão
- `skills/conectar/` , mapeia capacidade → provider no módulo `_shared/capacidades.md` da pessoa e confere os consumidores; roda no Bloco 3 do setup e de novo quando a caixa de ferramentas muda
- `skills/criar-skill/` , triagem (a régua de 4 destinos) + autoria + teste de disparo + plantio de skill sob medida
- `seeds/` , 6 skills starter que viram arquivos do usuário: abrir-dia e fechar-dia (par do loop diário), fechar-semana (loop semanal em cima dos diários), preparar-conversa e processar-reuniao (par pré/pós conversa), absorver (intake de material)
- `modulos/` , template do módulo compartilhado (`capacidades.md`), copiado pra `.claude/skills/_shared/` da pessoa
- `hooks/` , `hooks.json` (SessionStart) e `boot-memoria.sh`, que injeta CRITICAL_FACTS + navegacao + log mais recente na abertura da sessão
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
    modules: [seeds/, modulos/, skills/setup/, skills/plantar/, skills/conectar/]
  - file: patterns/instruction-routing.md
    tags: [routing, load-trigger, rules, shared-module, self-modulation]
    modules: [skills/setup/, skills/criar-skill/, seeds/absorver/, ./]
  - file: patterns/writing-canon.md
    tags: [writing, style, canon, anti-tells, pt-br, tone]
    modules: [skills/, seeds/, hooks/, ./]
  - file: patterns/system-contracts.md
    tags: [contracts, memory, labels, integration, folders, capabilities]
    modules: [seeds/, modulos/, skills/setup/, skills/conectar/]
<!-- vibeflow:patterns:end -->

## Pattern Docs Available
- [patterns/skill-authoring.md](patterns/skill-authoring.md) , anatomia de um SKILL.md: frontmatter com gatilhos literais, fluxo numerado, "Quando NÃO usar", e as regras de autoria que o `criar-skill` ensina (progressive disclosure, alvo em número, sem exemplo engessado)
- [patterns/seed-model.md](patterns/seed-model.md) , ciclo de vida da semente e do módulo: catálogo → plantio por cópia → arquivo do usuário, nunca sobrescrito; e a consequência de que melhoria no catálogo não alcança quem já plantou
- [patterns/instruction-routing.md](patterns/instruction-routing.md) , a régua de 4 destinos (CLAUDE.md, regra com `paths:`, módulo `_shared`, skill dona) e o eixo que separa os quatro: o gatilho de carga
- [patterns/writing-canon.md](patterns/writing-canon.md) , cânone de escrita que o repo segue e propaga (sem travessão, factual, anti-tells)
- [patterns/system-contracts.md](patterns/system-contracts.md) , rótulos e paths que ligam as skills via arquivos do usuário, incluindo o contrato skill ↔ conector (capacidade, `provider`, `como chamar`); quebrar um lado quebra o loop

## Key Files
- `skills/setup/SKILL.md` , 216 linhas, o coração: discovery, princípios, anti-padrões, arquitetura de memória, régua de 4 destinos, plantio
- `skills/criar-skill/SKILL.md` , 46 linhas: triagem de destino, regras de autoria e a camada de implementação de cada destino
- `skills/conectar/SKILL.md` , 31 linhas: a régua "capacidade, nunca nome de ferramenta" e a conferência de consumidores
- `skills/plantar/SKILL.md` , 20 linhas: catálogo e plantio avulso
- `modulos/capacidades.md` , 22 linhas: template com 8 capacidades e as colunas `provider` / `como chamar` / `sem conector`
- `hooks/boot-memoria.sh` , 46 linhas, o único executável: gate por `CLAUDE.md` + `CRITICAL_FACTS.md`, limite de 32KB por arquivo, stdout vira contexto
- `hooks/hooks.json` , registra o SessionStart nos matchers `startup` e `clear` (compact fica de fora de propósito)
- `seeds/abrir-dia/SKILL.md` , abre o dia: agenda (via capacidades) + backlog + 3 do dia calibradas contra horas livres
- `seeds/fechar-dia/SKILL.md` , fecha o dia: avalia as 3, classifica motivo, semeia `**→ amanhã:**`
- `seeds/fechar-semana/SKILL.md` , fecha a semana: agrega balanços, força 1 a 3 calls, mede saúde da memória, monta o diário novo
- `seeds/preparar-conversa/SKILL.md` , pauta por tipo (liderado, líder, par/stakeholder)
- `seeds/processar-reuniao/SKILL.md` , nota estruturada + propagação (tasks, sinais, hubs, log)
- `seeds/absorver/SKILL.md` , intake de material: roteia, destila com proveniência, declara o consumidor
- `README.md` , landing e contrato com o usuário (privacidade, updates)
- `PROMPT.md` , setup colável (plano B), espelho da régua
- `.claude-plugin/plugin.json` , versão que dispara auto-update (v0.3.0)
- `.claude-plugin/marketplace.json` , o repo como marketplace

## Dependencies (critical only)
Nenhuma externa. Zero dependência é decisão de produto declarada no README ("Mais nada. Não precisa saber programar"). Desde v0.2.0 o repo tem 1 executável próprio (`hooks/boot-memoria.sh`, POSIX sh, só `wc`, `cat`, `ls`, `date`, `sort`, `tail`): roda local, não instala nada, não acessa rede, e sai em silêncio fora de uma pasta de Chief of Staff.

## Known Issues / Tech Debt
- README diz "o plugin não roda código nem instala nada: é conversa e arquivos markdown" (seção "Onde ficam meus dados?"), o que deixou de ser verdade em v0.2.0: o hook SessionStart executa `boot-memoria.sh` a cada abertura de sessão. A promessa de privacidade continua de pé (local, sem rede), a frase não.
- `hooks/boot-memoria.sh` , comentário do topo com fragmento duplicado de edição anterior ("injeta no contexto o estado gravado" seguido de "contexto da sessao o estado gravado em disco"). Só comentário, sem efeito no comportamento.
- PROMPT.md espelha a régua de 4 destinos no princípio 1, mas a lista de pastas propostas (item 1 do "Depois do discovery") cita só a pasta de regras situacionais e omite a pasta do módulo compartilhado. Quem segue o PROMPT recebe a régua sem o lugar do quarto destino.
- Duas réguas de tamanho pro mesmo arquivo, 10x de distância: `fechar-semana` mede `CRITICAL_FACTS.md` contra ~3KB e o hook só avisa acima de 32KB (`LIMITE=32768`). O arquivo pode estar 5x acima do alvo declarado com o hook em silêncio.
- Setup e `criar-skill` afirmam que `/doctor` "revisa e simplifica o CLAUDE.md". A validar: no Claude Code o comando é diagnóstico de instalação. Se a afirmação não confere, são 2 arquivos a corrigir no mesmo change.
- `plantar` não conhece a camada de módulo: planta semente que lê `_shared/capacidades.md` sem checar se o módulo existe nem se a linha "Carregado por" do módulo passa a citar a semente nova. A degradação é graciosa (a semente volta a perguntar), a divergência é silenciosa. O `conectar` cobre o sentido inverso (módulo escrito → conferir consumidores) e o `fechar-semana` cobre a deriva na semana.

Resolvido desde a análise de 30/07: listagem do catálogo por posição de texto no `plantar` (hoje lê o `description` do frontmatter), grep do backlog ancorado em início de linha no `abrir-dia` (hoje sem âncora, subtask conta), discovery sem persistência (hoje `setup-notas.md` por bloco), promessa "fechar dias e semanas" sem semente de semana (hoje `seeds/fechar-semana/`), e blocos 3, 5 e 6 do discovery sem destino (hoje `contexto/ferramentas-e-fontes.md`, `rituais.md`, `dores.md`).
