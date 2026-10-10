# Codex — DS1 Dev Setup Utility

## Missão
Evoluir **o repositório existente**, não reescrevê-lo, por especificações incrementais em `specs/NNN-slug/`. A primeira entrega prioritária é a correção do handoff PowerShell 5.1 → UAC → PowerShell 7. A ordem está em `docs/phase-gates.md`.

## Leitura obrigatória antes de qualquer mudança
1. `.specify/memory/constitution.md`, `docs/phase-gates.md`, `docs/codex-speckit.md`.
2. `README.md`, `docs/plano-de-execucao.md`, `docs/arquitetura-executor.md`, `docs/runbooks.md`.
3. Documentação vinculada em `docs/notion-runbook-traceability.md`, e documentação local do runbook afetado.
4. `spec.md`, `plan.md`, `tasks.md`, `quickstart.md` da fase em andamento.

## Regras inegociáveis
- Nunca interpretar documentação e exemplos como prova de código implementado. Estado inicial é o observado no Git, com `Implemented=$false` respeitado.
- Preservar IDs de catálogo e o contrato PSD1 v1 até migração aprovada. A numeração de páginas no Notion diverge da numeração atual dos runbooks; **não renumerar IDs** sem migração/testes.
- Operações `Test` e `Plan` jamais modificam o host; `Apply` exige consentimento, verifica pós-condições e deve ser idempotente.
- Não solicitar UAC ao executar `-List`, `-Plan`, `-Validate` ou diagnósticos somente-leitura; quando o código atual contrariar isso, tratar como dívida da fase 002.
- Elevação somente para ação específica que necessite privilégio; evitar que uma sessão de outra conta altere perfil, credenciais ou WSL do usuário original.
- Nunca executar scripts arbitrários baixados de Notion/GitHub nem `irm | iex` em execução administrativa. Pacotes são verificados e revisados antes da execução.
- Não coletar logs com tokens, senhas, segredos, PII ou conteúdo de rede/corporativo. Sanitizar dados e manter logs mínimos.
- Três workspaces são físicos e independentes: `C:\workspace` (Windows), `/workspace` ext4 (Ubuntu) e `/workspace` sob instalação UCRT64 (MSYS2); não compartilhar `local/bin`, `local/env` ou `local/config`.
- Docker Desktop e IDEs gráficas residem no Windows; não assumir Ubuntu, MSYS2, WinGet, pwsh, JDK ou Docker preexistentes.
- Preferir alterações pequenas, reversíveis e testadas. Nunca automatizar reboot, formatação, exclusão, troca de engine ou instalação sem confirmação.

## Fluxo Spec Kit / Codex
O gerador **oficial** de skills do Spec Kit é `specify init --here --force --integration codex --script ps`, após branch/backup e revisão do diff. Consulte `docs/codex-speckit.md`. Não inventar arquivos `$speckit-*` manuais: deixá-los sob responsabilidade da CLI do projeto `github/spec-kit`.
Na sessão Codex, para **uma fase por vez**: `$speckit-clarify` → `$speckit-plan` → `$speckit-checklist` → `$speckit-tasks` → `$speckit-analyze` → `$speckit-implement` → `$speckit-converge`. Os documentos iniciais desta adoção são propostas; o Codex deve reconciliá-los antes de executar.
Usar branch/PR próprios **por fase**. Não avançar se o gate da fase falhar. Uma spec não equivale à implementação.

## Verificação antes de PR
- `python tools/check_specs.py`
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`, `tests/preflight.tests.ps1`, `tests/task-phases.tests.ps1`
- `pwsh -NoProfile -File tests/bootstrap.tests.ps1`, `tests/bootstrap-handoff.tests.ps1`, `tests/bootstrap-discovery.tests.ps1`
- Em Windows, executar também testes de bootstrap via `powershell.exe` 5.1.
- Testes de integração reais somente em VM descartável e com consentimento explícito.
Documentar evidência, versão, plataforma, número de execuções e pendências no PR.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
