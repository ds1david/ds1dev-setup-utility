---
name: ds1-runbook-delivery
description: Planeje, implemente e valide uma fase isolada de DS1 Dev Setup Utility, respeitando segurança Test/Plan/Apply, compatibilidade PSD1 e rastreabilidade Notion. Use ao trabalhar em specs, bootstrap, ferramentas Windows, WSL, MSYS2 ou TUI.
---

# DS1 Runbook Delivery

Antes de modificar qualquer arquivo, leia:
- `AGENTS.md`
- `.specify/memory/constitution.md`
- `docs/phase-gates.md`
- `docs/notion-runbook-traceability.md`
- `docs/plano-de-execucao.md`

## Procedimento
1. Escolha **somente uma** pasta de `specs/NNN-*`.
2. Leia `spec.md`, `plan.md`, `tasks.md`, `quickstart.md`; compare com código preexistente e as páginas da wiki mapeadas.
3. Declare lacunas antes de implementar; não trate documentação como implementação.
4. Se o Spec Kit oficial estiver instalado, usar as skills `$speckit-clarify`, `$speckit-plan`, `$speckit-tasks`, `$speckit-analyze` e `$speckit-implement`. Não simule que foram executadas.
5. Entregar feature pequena com testes de estado observado, erro e idempotência. Preservar IDs do catálogo PSD1.
6. Fazer validação sem modificar o host normal. Apply só em VM consentida; nunca executar código remoto elevado.
7. Documentar resultado, diffs, rollback e riscos residuais, deixar `Implemented=false` até concluir o gate.

## Escopo e qualificação
A política de privilégios da fase 002 ainda não é implementada. O código existente pode exigir admin para tarefas de leitura; sinalize como dívida, não induza elevação para contornar testes.

O material `specs/` é backlog versionado; o Spec Kit oficial deverá ser instalado com `tools/install-spec-kit.ps1 -Mode Apply` ou comando indicado em `docs/codex-speckit.md`.
