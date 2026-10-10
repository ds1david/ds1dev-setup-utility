# Implementation Plan: 001 — Handoff seguro PS5.1 → UAC → PS7

**Estado:** planejamento inicial para Codex/Spec Kit; reconciliar com `$speckit-plan` e inspeção do código antes de implementação.
**Feature:** [spec.md](spec.md) · **Constituição:** [constitution.md](../../.specify/memory/constitution.md)

## Resumo técnico
Bootstrap retomável, sem travamento silencioso nem instalação inesperada; diagnostica a sessão elevada e respeita cancelamento.

## Contexto tecnológico
- Host principal: Windows 11; bootstrap compatível PowerShell 5.1 e runtime principal PowerShell 7.4+.
- Contrato atual: manifests PSD1 `SchemaVersion=1`, scripts PowerShell e testes sem instalações reais em CI.
- Ferramentas existentes a preservar: `bootstrap.ps1`, `src/*.psm1`, `runbooks/**`, testes PowerShell.
- Interfaces externas: comandos nativos/instaladores oficiais dependentes do escopo; mocks em CI.
- Não fazer upgrade implícito para YAML v2 ou Rust, salvo fase dedicada.

## Verificação da constituição
**Aceito sob condição**: privilégio mínimo, Test/Plan não-mutáveis, confirmação Apply, SHA e URLs oficiais, isolamento dos três ambientes e compatibilidade. Qualquer exceção precisa de ADR e aprovação humana antes do merge.

## Investigação antes de editar
1. Isolar criação de processo, troca de identidade, confirmação e coleta de retorno do executável elevado.
2. Definir protocolo explícito de handoff: RunId, status, código de saída, saída redigida, arquivo de diagnóstico, prazo de espera e cleanup em finally.
3. Simular processos/UAC com doubles em testes unitários; realizar ensaio controlado em VM Windows 11 com PS5.1 e PS7.
4. Documentar estados de erro antes de qualquer tentativa de auto-restart ou novo download.

## Caminhos existentes afetados
- `bootstrap.ps1`
- `tests/bootstrap.tests.ps1`
- `tests/bootstrap-handoff.tests.ps1`
- `tests/bootstrap-discovery.tests.ps1`
- `docs/tui-windows.md`

## Design e compatibilidade
- Reaproveitar funções existentes em vez de duplicar lógica na TUI.
- Registrar contrato de entrada, saída, estados, logs e rollback ao modificar código.
- Não renomear IDs antigos sem procedimento e testes de migração.
- Plano concreto deve incluir o inventário dos arquivos modificados, riscos de máquina limpa e cenários de negativa/erro.

## Plano de verificação
- `powershell.exe -NoProfile -File tests/bootstrap.tests.ps1`
- `powershell.exe -NoProfile -File tests/bootstrap-handoff.tests.ps1`
- `pwsh -NoProfile -File tests/bootstrap-discovery.tests.ps1`
- `python tools/check_specs.py` verifica somente a estrutura documental.
- Testes unitários em CI; testes reais em VM Windows/WSL/MSYS2 apropriada, com registro de estado anterior e posterior.

## Recuperação/rollback
Manter o bootstrap anterior disponível por tag/commit; alteração só em branch; falha operacional encerra sem mutação irreversível.

## Gate de saída
Checklist [tasks.md](tasks.md), cenários [quickstart.md](quickstart.md), resultados AC-001 e links de evidência no PR. Sem evidência, a fase permanece planejada.
