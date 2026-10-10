# Implementation Plan: 004 — WSL2 Ubuntu e toolchain Linux

**Estado:** planejamento inicial para Codex/Spec Kit; reconciliar com `$speckit-plan` e inspeção do código antes de implementação.
**Feature:** [spec.md](spec.md) · **Constituição:** [constitution.md](../../.specify/memory/constitution.md)

## Resumo técnico
Ubuntu WSL2 configurado, sem cruzamento acidental para binários Windows.

## Contexto tecnológico
- Host principal: Windows 11; bootstrap compatível PowerShell 5.1 e runtime principal PowerShell 7.4+.
- Contrato atual: manifests PSD1 `SchemaVersion=1`, scripts PowerShell e testes sem instalações reais em CI.
- Ferramentas existentes a preservar: `bootstrap.ps1`, `src/*.psm1`, `runbooks/**`, testes PowerShell.
- Interfaces externas: comandos nativos/instaladores oficiais dependentes do escopo; mocks em CI.
- Não fazer upgrade implícito para YAML v2 ou Rust, salvo fase dedicada.

## Verificação da constituição
**Aceito sob condição**: privilégio mínimo, Test/Plan não-mutáveis, confirmação Apply, SHA e URLs oficiais, isolamento dos três ambientes e compatibilidade. Qualquer exceção precisa de ADR e aprovação humana antes do merge.

## Investigação antes de editar
1. Adicionar discovery robusto de distros, features e identidade Linux; tratar setup de usuário como fase separada.
2. Chamar wsl.exe com argumentos e scripts locais verificados, validando exit code e outputs.
3. Persistir checkpoint de reboot não-autoritativo, revalidar estado real ao retomar.
4. Evidenciar ausência de binários Windows nos comandos de desenvolvimento Linux.

## Caminhos existentes afetados
- `runbooks/03/runbook.ps1`
- `runbooks/03.1/runbook.ps1`
- `docs/03-wsl.md`
- `docs/03.1-toolchain-ubuntu.md`

## Design e compatibilidade
- Reaproveitar funções existentes em vez de duplicar lógica na TUI.
- Registrar contrato de entrada, saída, estados, logs e rollback ao modificar código.
- Não renomear IDs antigos sem procedimento e testes de migração.
- Plano concreto deve incluir o inventário dos arquivos modificados, riscos de máquina limpa e cenários de negativa/erro.

## Plano de verificação
- `wsl --status; wsl --list --verbose`
- `wsl -d <DISTRO> -- bash -lc 'command -v java; java -version; command -v mvn; mvn -version; command -v gradle; gradle --version'`
- `python tools/check_specs.py` verifica somente a estrutura documental.
- Testes unitários em CI; testes reais em VM Windows/WSL/MSYS2 apropriada, com registro de estado anterior e posterior.

## Recuperação/rollback
Desabilitar passos de integração por opt-in, não executar wsl --unregister e nunca apagar distro/dados.

## Gate de saída
Checklist [tasks.md](tasks.md), cenários [quickstart.md](quickstart.md), resultados AC-004 e links de evidência no PR. Sem evidência, a fase permanece planejada.
