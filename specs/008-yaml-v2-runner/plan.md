# Implementation Plan: 008 — Schema YAML v2 e script runner multiprocessos

> Documento técnico inicial; executar `$speckit-plan` e atualizar decisões em branch própria antes da codificação.

## Resumo
Oferece v2 opt-in validado para steps Windows/Ubuntu/MSYS2 com execução por interpretador, deixando PSD1 v1 funcionando.

## Contexto técnico
- Host: Windows 11; PowerShell 5.1 para bootstrap e PS7 como runtime principal.
- Preservar contratos atuais PSD1 v1 e runbooks existentes; YAML v2 e Rust não estão prontos na baseline.
- Executar testes sem instalar ou modificar computador do desenvolvedor.
- Dependências: Fase 002 consolidada; não requer TUI Rust e não autoriza migração em massa antecipada.

## Constituição e avaliação de risco
Confirmar privilégio mínimo, confirmação, observabilidade, idempotência, fontes verificadas, independência de ambientes e rollback. Não tomar o código atual como automaticamente aderente: registrar dívida técnica e criar testes de regressão.

## Estratégia de implementação
1. Definir schema formal JSON Schema para YAML v2, com mapeamento explícito para plano de execução tipado.
2. Separar parsing, binding de variáveis, policy engine e executor por interpretador.
3. Testar com fixtures cross-platform e comandos inofensivos; promover feature flag por runbook.
4. Criar migração piloto mantendo ID e mesmo resultado antes de habilitar restante do catálogo.
5. Contratar eventos estruturados `command.started`, `command.waiting`, `command.resumed`, `command.finished` e `command.interrupted` com correlação por `runId/taskId/stepId/commandId`, idempotência de sequência, redaction de comando e reconciliador para interrupções. Frames e título do terminal permanecem responsabilidade das interfaces PowerShell/Rust.

## Artefatos existentes a avaliar
- `docs/modelo-runbooks-v2.md`
- `docs/perfis-ambientes-versoes-v2.md`
- `docs/script-runner-v2.md`
- `src/Runbooks.psm1`
- `runbooks/**/runbook.psd1`

## Contratos e estrutura a produzir
- Fluxo de entrada, estados, erro e pós-condições explícitos por runbook/adaptador.
- Teste de contrato para comando silencioso ≥5 s com emissão de início/fim sem chunks, múltiplos processos concorrentes, fechamento ordenado e detecção de spawn inválido sem `started` fictício.
- Testes unitários do contrato, testes de integração em VM e documentação com fontes Notion.
- Gate com evidência dos AC-008; sem alterações de IDs existentes e sem confundir feature flag com implementação.

## Validação recomendada
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- `pwsh -NoProfile -File tests/task-phases.tests.ps1`
- `python tools/check_specs.py`
- Ensaiar dois Apply na VM quando houver ação mutável; comparar diffs.
- Testar confirmação negada, dependência indisponível, falha parcial e logs sem segredo.
- Verificar que os eventos estruturados são suficientes para o spinner da UI funcionar sem stdout, não persistem quadros de animação e não deixam execuções incompletas como `running` após reinício.

## Rollback e implantação
Feature flag v2 reversível, PSD1 mantém execução como fallback; não migrar catálogos em massa antes da paridade.

## Checklist de saída
Implementação limitada à fase, testes/CI green, pós-condições verificadas, evidências anexadas e PR revisada.
