# Spec: README de lançamento (problemas comuns + dado sensível + canal de feedback)

## Objective
O README responde as 3 perguntas previsíveis do lançamento (deu erro e agora, posso colar dado da empresa, como peço uma skill) sem virar manual.

## Context
O repo lançou hoje mirando a comunidade de produto (Product Tank). Os 3 atritos previsíveis do primeiro contato não têm resposta escrita: comando que não aparece (o README só cobre no passo de instalação), discovery interrompido, skill plantada que não registra na sessão. A seção de dados responde "nada é enviado pra mim", que está certo, e não responde a pergunta que GPM e head vão fazer na sala: posso colar transcrição de 1:1 da minha empresa? Issues está habilitado no repo e o README não convida; pedido de semente é a única medição de demanda disponível.

## Definition of Done
1. [ ] Seção "Problemas comuns" com os 3 casos (Unknown command, discovery interrompido, comando de skill plantada ausente), 1-2 linhas cada.
2. [ ] "Onde ficam meus dados?" ganha: o plugin não roda código (conversa e markdown), e transcrição de 1:1 é dado sensível de terceiro com aponte pra política de IA da empresa.
3. [ ] Convite a issues no README com os 2 caminhos (bug, pedido de semente) e templates correspondentes em `.github/ISSUE_TEMPLATE/`.
4. [ ] Craftsmanship: cânone de escrita em tudo (sem travessão, factual); as adições no README somam no máximo 20 linhas.

## Scope
`README.md`, `.github/ISSUE_TEMPLATE/bug.md`, `.github/ISSUE_TEMPLATE/pedir-semente.md` (3 arquivos, budget ≤4 ok).

## Anti-scope
- Sem GIF, screenshot ou link de exemplo (a pasta EXEMPLO é outra spec; o link entra lá).
- Sem mudança nos passos de instalação.
- Sem CHANGELOG (entra com o bump de versão pós-série).
- Sem quote de prova social: depende de material do dono, fora do alcance deste PR.

## Technical Decisions
- Templates no formato markdown clássico de ISSUE_TEMPLATE (frontmatter name/about/labels): zero configuração extra, funciona no repo como está.
- O caso "discovery interrompido" assume a retomada por `setup-notas.md` da spec `setup-robusto`: dependência declarada abaixo.
- Pedido de semente pergunta gatilho, leituras e escritas: o mesmo contrato que uma semente real precisa declarar (patterns/system-contracts), o que torna o pedido implementável.

## Applicable Patterns
- `writing-canon` (README é a vitrine do cânone)
- `system-contracts` (estrutura do template de pedido de semente)

## Risks
- README crescer e diluir a landing → cap de 20 linhas no DoD.
- Template longo espanta quem só quer registrar 1 frase → campos com hint curto, nenhum obrigatório.

## Dependencies
- `.vibeflow/specs/setup-robusto.md` (mergear #2 antes: o troubleshoot de discovery interrompido cita a retomada por setup-notas.md)
