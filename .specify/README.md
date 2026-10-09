# Spec Kit — estado desta adoção

Este repositório contém **constituição local, instruções para Codex e specs de fases**, mas a integração oficial do Spec Kit ainda precisa ser gerada.

- `memory/constitution.md`: guardrails do projeto; preservar ao executar init.
- `../AGENTS.md`: instruções do agente.
- `../.agents/skills/ds1-runbook-delivery/SKILL.md`: skill local do projeto (não substitui skills oficiais).
- `../tools/install-spec-kit.ps1`: plano/inicializador explícito que exige autorização para Apply.
- `../docs/codex-speckit.md`: sequência de instalação e execução por fase.
- `../specs/`: specs editoriais já versionadas, a reconciliar com CLI.

**Quando a CLI for executada:**
`specify init --here --force --non-interactive --integration codex --script ps`

A CLI gera/atualiza `.specify/scripts`, `.specify/templates` e `.agents/skills/speckit-*` de sua própria distribuição. Por serem arquivos gerados a partir da versão local, **não** criar equivalentes falsos manualmente. Versionar o diff revisado em uma branch separada, mantendo os documentos já escritos. A geração não implica implementação de runbooks.
