# Adoção Spec Kit + Codex no repositório existente

> Status: scaffold de governança e specs publicável no Git; **os arquivos oficiais das skills do Spec Kit ainda precisam ser gerados com a CLI**. Não marcar como “Spec Kit instalado” até executar e versionar o diff gerado.

## Preparar o ambiente e preservar o trabalho existente

No PowerShell 7 **no computador de desenvolvimento**, com `git`, `uv` e `codex` presentes:

```powershell
git clone https://github.com/ds1david/ds1dev-setup-utility.git
Set-Location ds1dev-setup-utility
git status --short
# Após revisão/merge da PR de adoção, criar branch própria para inicialização oficial.
git switch -c chore/spec-kit-official-init
uv tool install specify-cli
specify version
specify init --here --force --integration codex --script ps --non-interactive
git status --short
git diff -- .specify .agents AGENTS.md
```

`--force` é usado porque o projeto já possui arquivos; **não** significa autorizar substituição sem revisar. Caso a CLI atual não aceite `--non-interactive`, consulte `specify init --help`. Use uma versão fixada em um commit de setup posterior para reproduzir as mesmas templates. Evitar `--script sh` neste host, pois a execução principal é PowerShell. Não sobrescrever a constituição ou instruções de `AGENTS.md` sem comparar conteúdo.

Os artefatos oficiais (`.agents/skills/speckit-*/SKILL.md`, `.specify/scripts`, `.specify/templates`) **devem ser criados pela CLI** e incluídos em um PR separado; não serão simulados manualmente nesta adoção. O Codex atual invoca skills com `$speckit-specify`, `$speckit-plan`, `$speckit-tasks` etc.; após init, confira nomes pelo ambiente.

## Iteração por fase
1. Ler `AGENTS.md`, constituição, `docs/phase-gates.md` e a spec da fase.
2. `$speckit-clarify` para questões em aberto; registrar decisões.
3. `$speckit-plan` reconciliando o plano inicial com o código existente.
4. `$speckit-checklist`, `$speckit-tasks`, `$speckit-analyze`.
5. `$speckit-implement` **somente na branch daquela fase**, um PR por fatia.
6. `$speckit-converge`, executar os testes e documentar evidências.
7. Concluir gate antes de iniciar fase dependente.

As specs em `specs/` são **sementes editoriais**: são intencionais, com critérios de aceite e tarefas iniciais, mas ainda não resultam de uma sessão formal do gerador. A CLI deverá reaproveitar/reconciliar esses documentos, sem recriar o repositório ou apagar dados.

## Primeiro prompt sugerido no Codex
```text
Leia AGENTS.md, .specify/memory/constitution.md, docs/phase-gates.md
e specs/001-safe-bootstrap-handoff/{spec,plan,tasks,quickstart}.md.
Analise o código e os testes atuais antes de editar. Seu escopo é APENAS a
fase 001. Execute clarify/plan/tasks/analyze, mostre os desvios e
implemente incrementalmente, preservando interface e sem elevar nem
instalar nada na máquina atual. Gere evidências dos gates em Windows 5.1
e PowerShell 7, incluindo cancelamento UAC e processo filho travado.
```

## Fontes e riscos
- Guia oficial: https://github.github.io/spec-kit/guides/existing-projects.html
- Referência oficial: https://github.github.io/spec-kit/reference/core.html
- Integrações: https://github.com/github/spec-kit/blob/main/docs/reference/integrations.md
- Não executar `irm ... | iex` em PowerShell elevado. Preferir checkout/release fixados e execução por arquivo.
- Nesta adoção, o source of truth das implementações é o Git; links Notion trazem requisitos históricos e navegação.

## Status Report

Para acompanhar progresso do backlog, instale a extensao comunitaria status-report 1.4.2 com o [guia de instalacao](speckit-status-report.md) depois de executar specify init e revisar o diff. Ela escreve specs/spec-status.md, arquivo gerado e ignorado pelo Git. O status documental nao equivale a aceitacao das tarefas.
