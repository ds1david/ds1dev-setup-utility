# Implementation Plan: 002 — Executor seguro, catálogo e diagnóstico sem admin

**Estado:** planejamento inicial para Codex/Spec Kit; reconciliar com `$speckit-plan` e inspeção do código antes de implementação.
**Feature:** [spec.md](spec.md) · **Constituição:** [constitution.md](../../.specify/memory/constitution.md)

## Resumo técnico
Executar -List, -Task X -Plan e -Validate em contexto sem administrador e com resultado consistente, preservando runbooks PSD1.

## Contexto tecnológico
- Host principal: Windows 11; bootstrap compatível PowerShell 5.1 e runtime principal PowerShell 7.4+.
- Contrato atual: manifests PSD1 `SchemaVersion=1`, scripts PowerShell e testes sem instalações reais em CI.
- Ferramentas existentes a preservar: `bootstrap.ps1`, `src/*.psm1`, `runbooks/**`, testes PowerShell.
- Interfaces externas: comandos nativos/instaladores oficiais dependentes do escopo; mocks em CI.
- Não fazer upgrade implícito para YAML v2 ou Rust, salvo fase dedicada.

## Verificação da constituição
**Aceito sob condição**: privilégio mínimo, Test/Plan não-mutáveis, confirmação Apply, SHA e URLs oficiais, isolamento dos três ambientes e compatibilidade. Qualquer exceção precisa de ADR e aprovação humana antes do merge.

## Investigação antes de editar
1. Separar comandos read-only da inicialização de transcript/arquivos protegidos hoje feita no startup.
2. Manter parser Import-PowerShellDataFile v1; criar abstrações para capabilities, privilégio, protocolo de resultado e logs.
3. Introduzir testes de contrato e mocks para side effects, caminhos, código de saída e dependências.
4. Unificar documentação com runbooks PSD1 existentes; o modelo YAML v2 permanece proposta.

## Caminhos existentes afetados
- `src/ds1-setup.ps1`
- `src/Runbooks.psm1`
- `src/Preflight.psm1`
- `src/TaskPhases.psm1`
- `src/Tui.psm1`
- `runbooks/**/runbook.psd1`
- `tests/runbooks.tests.ps1`
- `tests/task-phases.tests.ps1`

## Design e compatibilidade
- Reaproveitar funções existentes em vez de duplicar lógica na TUI.
- Registrar contrato de entrada, saída, estados, logs e rollback ao modificar código.
- Não renomear IDs antigos sem procedimento e testes de migração.
- Plano concreto deve incluir o inventário dos arquivos modificados, riscos de máquina limpa e cenários de negativa/erro.

## Plano de verificação
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- `pwsh -NoProfile -File tests/preflight.tests.ps1`
- `pwsh -NoProfile -File tests/task-phases.tests.ps1`
- `python tools/check_specs.py` verifica somente a estrutura documental.
- Testes unitários em CI; testes reais em VM Windows/WSL/MSYS2 apropriada, com registro de estado anterior e posterior.

## Recuperação/rollback
Backout de novo dispatcher mantendo contrato v1; logs antigos continuam legíveis.

## Gate de saída
Checklist [tasks.md](tasks.md), cenários [quickstart.md](quickstart.md), resultados AC-002 e links de evidência no PR. Sem evidência, a fase permanece planejada.
