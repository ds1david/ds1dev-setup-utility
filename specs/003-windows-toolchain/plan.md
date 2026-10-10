# Implementation Plan: 003 — Instalação Windows básica, Java/Maven/Gradle

**Estado:** planejamento inicial para Codex/Spec Kit; reconciliar com `$speckit-plan` e inspeção do código antes de implementação.
**Feature:** [spec.md](spec.md) · **Constituição:** [constitution.md](../../.specify/memory/constitution.md)

## Resumo técnico
Usuário instala e valida ferramentas de desenvolvimento Windows sob demanda, inclusive quando WinGet ou PATH faltam.

## Contexto tecnológico
- Host principal: Windows 11; bootstrap compatível PowerShell 5.1 e runtime principal PowerShell 7.4+.
- Contrato atual: manifests PSD1 `SchemaVersion=1`, scripts PowerShell e testes sem instalações reais em CI.
- Ferramentas existentes a preservar: `bootstrap.ps1`, `src/*.psm1`, `runbooks/**`, testes PowerShell.
- Interfaces externas: comandos nativos/instaladores oficiais dependentes do escopo; mocks em CI.
- Não fazer upgrade implícito para YAML v2 ou Rust, salvo fase dedicada.

## Verificação da constituição
**Aceito sob condição**: privilégio mínimo, Test/Plan não-mutáveis, confirmação Apply, SHA e URLs oficiais, isolamento dos três ambientes e compatibilidade. Qualquer exceção precisa de ADR e aprovação humana antes do merge.

## Investigação antes de editar
1. Criar provider de instalação e detector de versões por ferramenta com testes de unidade isolados.
2. Baixar pacotes apenas de endpoints oficiais, verificar SHA e preservar arquivo antes de mutação.
3. Tratar novo terminal versus sessão atual e conflitos com PATH máquina/usuário explicitamente.
4. Manter IDs legados 02 e 02.1, refinar subpassos no mesmo contrato até decisão de migração.

## Caminhos existentes afetados
- `runbooks/02/runbook.ps1`
- `runbooks/02.1/runbook.ps1`
- `runbooks/02/runbook.psd1`
- `runbooks/02.1/runbook.psd1`
- `docs/02-windows.md`
- `docs/02.1-toolchain-windows.md`

## Design e compatibilidade
- Reaproveitar funções existentes em vez de duplicar lógica na TUI.
- Registrar contrato de entrada, saída, estados, logs e rollback ao modificar código.
- Não renomear IDs antigos sem procedimento e testes de migração.
- Plano concreto deve incluir o inventário dos arquivos modificados, riscos de máquina limpa e cenários de negativa/erro.

## Plano de verificação
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- `java -version; javac -version; mvn -version; gradle --version`
- `python tools/check_specs.py` verifica somente a estrutura documental.
- Testes unitários em CI; testes reais em VM Windows/WSL/MSYS2 apropriada, com registro de estado anterior e posterior.

## Recuperação/rollback
Backup de PATH e variáveis e instruções de remoção reversível; não remover instalação previamente existente.

## Gate de saída
Checklist [tasks.md](tasks.md), cenários [quickstart.md](quickstart.md), resultados AC-003 e links de evidência no PR. Sem evidência, a fase permanece planejada.
