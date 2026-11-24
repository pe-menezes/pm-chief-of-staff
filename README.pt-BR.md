# pm-chief-of-staff

[Read in English](README.md)

**Um Chief of Staff pessoal para quem trabalha com produto, dentro do Claude Code ou do Codex.** Você abre o agente numa pasta vazia, ele te entrevista por uns 20 a 30 minutos, e das respostas nasce um sistema seu: as pastas, o manual que ele segue e as rotinas de trabalho. A memória dele são arquivos markdown nessa pasta. Sem banco de dados e sem servidor.

## Como fica no dia a dia

Antes de uma 1:1, você pede a pauta e ele monta a partir do que está escrito na pasta: o que você prometeu na última conversa e não fez, e o assunto que vem sendo empurrado há semanas. Depois da reunião, você cola a transcrição, e ele grava a nota e atualiza o que mudou.

Nada vem de template. O setup pergunta quem você é, o que você toca, quem trabalha contigo e onde dói, e monta a pasta a partir disso. Você revisa tudo antes de qualquer arquivo ser criado.

## Instalar

Abra o seu agente de código e peça:

```
instala pra mim, por favor: github.com/pe-menezes/pm-chief-of-staff
```

Depois abra o agente numa pasta vazia, numa sessão nova, e peça: `monta meu chief of staff`.

Precisa do Claude Code (assinatura Claude Pro ou superior) ou do Codex. Não precisa saber programar.

<details>
<summary>Instalar à mão</summary>

No Claude Code, aberto na pasta vazia:

```
/plugin marketplace add pe-menezes/pm-chief-of-staff
/plugin install pm-chief-of-staff@pm-chief-of-staff
/reload-plugins
/pm-chief-of-staff:setup em português
```

No Codex, pelo terminal:

```
codex plugin marketplace add pe-menezes/pm-chief-of-staff
codex plugin add pm-chief-of-staff@pm-chief-of-staff
```

Depois abra uma sessão nova do Codex na pasta vazia e peça "monta meu chief of staff". O Codex pede a sua aprovação para os hooks do plugin.

</details>

## O que vem

| Skill | O que faz |
|---|---|
| `prep-conversation` | monta a pauta de 1:1, de conversa com par ou com stakeholder, a partir do que está na pasta |
| `process-meeting` | transforma a transcrição em nota e leva o que mudou para os lugares certos |
| `absorb` | guarda um documento ou artigo, com resumo e de onde veio |
| `start-day`, `close-day`, `close-week` | rotinas opcionais do dia e da semana; o setup pergunta quais você quer |

Depois de instaladas na sua pasta, as skills são arquivos seus: peça uma mudança e ele edita a skill.

## Seus dados

A pasta fica no seu computador. O plugin não instala servidor nem conector, e atualização nunca mexe nos seus arquivos. A conversa segue as regras da conta do agente que você usa. Antes de colar transcrição da empresa, confira a política de IA dela.

## Mais

* [Guia completo](docs/guia-completo.pt-BR.md): a memória, as atualizações, a mesma pasta no Claude e no Codex, e os problemas comuns.
* [Setup sem o plugin](PROMPT.pt-BR.md): o prompt para colar em qualquer agente que mexa em arquivo.
* Bug ou semente que falta: abra uma [issue](https://github.com/pe-menezes/pm-chief-of-staff/issues).

Licença MIT.
