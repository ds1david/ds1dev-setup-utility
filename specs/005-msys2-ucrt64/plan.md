# Implementation Plan: 005 — MSYS2 UCRT64 funcional e isolado

**Estado:** planejamento inicial para Codex/Spec Kit; reconciliar com `$speckit-plan` e inspeção do código antes de implementação.
**Feature:** [spec.md](spec.md) · **Constituição:** [constitution.md](../../.specify/memory/constitution.md)

## Resumo técnico
MSYS2 UCRT64 instalado com gerenciador pacman, GCC/CMake/Ninja e perfil de Terminal verificável.

## Contexto tecnológico
- Host principal: Windows 11; bootstrap compatível PowerShell 5.1 e runtime principal PowerShell 7.4+.
- Contrato atual: manifests PSD1 `SchemaVersion=1`, scripts PowerShell e testes sem instalações reais em CI.
- Ferramentas existentes a preservar: `bootstrap.ps1`, `src/*.psm1`, `runbooks/**`, testes PowerShell.
- Interfaces externas: comandos nativos/instaladores oficiais dependentes do escopo; mocks em CI.
- Não fazer upgrade implícito para YAML v2 ou Rust, salvo fase dedicada.

## Verificação da constituição
**Aceito sob condição**: privilégio mínimo, Test/Plan não-mutáveis, confirmação Apply, SHA e URLs oficiais, isolamento dos três ambientes e compatibilidade. Qualquer exceção precisa de ADR e aprovação humana antes do merge.

## Investigação antes de editar
1. Discovery de instalação e chamadas via msys2_shell.cmd/burst script local, tratando quoting seguro.
2. Modelar atualização pacman em estágios; verificar exit codes e retorno de processo ao encerrar shell.
3. Gerar perfil Terminal validando JSON e preservar outras configurações.
4. Testar instalação não padrão e fluxo de atualização com pacman locked em VM.

## Caminhos existentes afetados
- `runbooks/04/runbook.ps1`
- `runbooks/04.1/runbook.ps1`
- `docs/04-msys2.md`
- `docs/04.1-toolchain-msys2.md`

## Design e compatibilidade
- Reaproveitar funções existentes em vez de duplicar lógica na TUI.
- Registrar contrato de entrada, saída, estados, logs e rollback ao modificar código.
- Não renomear IDs antigos sem procedimento e testes de migração.
- Plano concreto deve incluir o inventário dos arquivos modificados, riscos de máquina limpa e cenários de negativa/erro.

## Plano de verificação
- `pacman --version`
- `gcc -dumpmachine; cmake --version; ninja --version`
- `python tools/check_specs.py` verifica somente a estrutura documental.
- Testes unitários em CI; testes reais em VM Windows/WSL/MSYS2 apropriada, com registro de estado anterior e posterior.

## Recuperação/rollback
Nunca remover pacotes de usuário ou MSYS2 preexistente; reverter somente entradas de PATH/profile geradas com backup.

## Gate de saída
Checklist [tasks.md](tasks.md), cenários [quickstart.md](quickstart.md), resultados AC-005 e links de evidência no PR. Sem evidência, a fase permanece planejada.
