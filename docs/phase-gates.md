# Roadmap por fatias de valor e gates de aceite

> 2026-10-09. **Todas as fases abaixo estão planejadas, NÃO implementadas por estas specs**. O código parcial preexistente não deve ser confundido com a cobertura indicada.

| Fase | Entrega utilizável | Gate de saída |
|---|---|---|
| [001](../specs/001-safe-bootstrap-handoff/spec.md) | Bootstrap não trava nem perde diagnóstico após UAC/PS7 | Fluxo PS5.1→UAC→PS7 com falhas simuladas, timeout e log; sem instalação automática |
| [002](../specs/002-safe-executor-contract/spec.md) | Listar/testar/planejar runbooks sem admin e com erros confiáveis | Test/Plan imutáveis; dependências, estados, saída e logs testados em Windows/Linux |
| [003](../specs/003-windows-toolchain/spec.md) | Windows com Git/Python/JDK21/Maven/Gradle funcional | VM limpa + máquina parcial; Apply×2 sem duplicações; checks das versões |
| [004](../specs/004-ubuntu-wsl-toolchain/spec.md) | Ubuntu WSL2 operacional com SDKMAN/toolchain Linux | reboot/retomada, WSL e Java/Maven/Gradle sem binários Windows |
| [005](../specs/005-msys2-ucrt64/spec.md) | MSYS2 UCRT64 com GCC/CMake/Ninja/Terminal | Atualização pacman segura; compile de teste; paths e platform corretos |
| [006](../specs/006-isolated-workspaces-shells-ides/spec.md) | Workspaces separados, perfis e IDEs interligadas | Três raízes distintas; PATH idempotente; nenhum vínculo involuntário |
| [007](../specs/007-docker-backup-validation/spec.md) | Docker central, diagnóstico e backup/restore guiados | Conflito de engine bloqueado; restore de amostra; relatórios de validação |
| [008](../specs/008-yaml-v2-runner/spec.md) | Contrato v2 opt-in com interpretes Windows/WSL/MSYS2 | Testes de schema, segurança, compatibilidade PSD1 e streams/exit codes |
| [009](../specs/009-rust-tui-release/spec.md) | TUI Rust/Ratatui e pacote verificado para usuário final | Paridade CLI/TUI; release checksum; instalação Windows limpa ensaiada |

## Gates comuns a todas as fases
- Sem alterações não autorizadas em `Test`, `Plan`, `-WhatIf` e execução de teste.
- Testar caminhos de erro (403/download, timeout, UAC cancelado, reboot pendente, execução duplicada) aplicáveis ao escopo.
- Revalidar imediatamente após Apply; relatórios não equivalem a estado detectado.
- Não assumir recursos ausentes no Windows limpo; simular e ensaiar em máquina descartável antes de aprovar.
- `Implemented=true` só depois da suíte, integração manual controlada e documentação com evidência.
- PR separada por fase, sem reescrever o bootstrap, catálogo ou wiki fora do escopo.
- Responsabilidade pelo aceite é do mantenedor humano; documentação não é aprovação técnica.

## Dependências
```text
001 -> 002 -> 003 -> 004 -> 005 -> 006 -> 007
               \__________________________-> 008 -> 009
```
A fase 008 pode iniciar após 002 com testes isolados, mas a descontinuação do runtime anterior exige evidência de 003–007. A TUI 009 depende de motor e contrato aprovados, não do modo legacy em desenvolvimento.

## Verificações locais
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
pwsh -NoProfile -File tests/preflight.tests.ps1
pwsh -NoProfile -File tests/task-phases.tests.ps1
pwsh -NoProfile -File tests/bootstrap.tests.ps1
pwsh -NoProfile -File tests/bootstrap-handoff.tests.ps1
pwsh -NoProfile -File tests/bootstrap-discovery.tests.ps1
```
Os testes existentes são a **linha de base**, não provam por si sós a fase concluída.
