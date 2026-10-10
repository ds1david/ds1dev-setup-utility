# Tasks: 009 — TUI Rust/Ratatui e distribuição confiável

> Tarefas propostas, ainda **não executadas**. Gerar/reconciliar lista detalhada com `$speckit-tasks`.

## Preparar e testar
- [ ] T001 Inventariar implementações existentes, casos de uso e gaps para FR-009, distinguindo catálogo PowerShell já existente, futura TUI Rust e runner, sem declarar protótipo como homologado.
- [ ] T002 [P] Desenhar contratos e regras de segurança, com teste primeiro; incluir eventos `command.started/finished/waiting`, correlação por `commandId` e transições que impedem spinners órfãos.
- [ ] T003 [P] Implementar fixtures e testes negativos sem efeitos colaterais; incluir processos silenciosos, concorrência, erro de spawn, timeout, cancelamento, redirecionamento de saída, terminais Unicode/ASCII e runbook de 5 passos com bloqueios e logs.

## Entregar incremento utilizável
- [ ] T004 Implementar catálogo 23/77 e detalhe de runbook 40/60 + barra inferior, tema DS1 Modern Terminal (bordas rounded, foco violeta, seleção ciano, logs), indicador inline com 10 frames Braille/tick 80–100ms (`#61AFEF` padrão; `#00A3FF` variante), timer, confirmação `?`, pós-verificação `◌`, resultados `✔/✖`, fallbacks ASCII/`NO_COLOR`/`DS1_NO_SPINNER` e título opcional restaurável.
- [ ] T004A Implementar navegação por foco: setas/`j/k`, Espaço, `a` em elegíveis do filtro, Tab, `/`, `p`, `L`, PageUp/PageDown/End e atalhos desativados em prompts/modais. `Enter` abre detalhes/revisão; aplicar somente após confirmação contextual explícita.
- [ ] T004B Implementar estado UI desacoplado do runner: `focusedStepId`, `selectedStepIds`, `observedStatuses`, resumo de dependências, buffer de logs e seleção congelada durante plano aprovado/Apply. Não inferir estado de step pelo checkbox ou posição na lista.
- [ ] T005 Repetir Apply×2 em ambiente descartável e validar invariantes de compatibilidade.

## Comprovar conclusão
- [ ] T006 Executar AC-009-01 até AC-009-16: layout 23/77 + 40/60, estados/foco/seleção, teclado e filtro, estilo e contraste, prompt/segurança, logs/scroll e spinner/tempo; validar recusa, NoOp, dependência, falha parcial e regressões com evidências redigidas.
- [ ] T007 Atualizar documentação de runbooks e trilha Notion ↔ Git ↔ testes.
- [ ] T008 Revisar segurança, logs, rollback, CI e PR da fase antes de avançar.

## Evidências obrigatórias
- [ ] EV009-A: CI/contratos compatíveis.
- [ ] EV009-B: logs redigidos de sucesso e erro; screenshots de catálogo e runbook em 120×32/80×24 com tema e fallback, fluxo de seleção/foco distintos e captura que comprova spinner apenas quando comando ativo.
- [ ] EV009-C: ensaio controlado em VM com estado anterior/posterior.
- [ ] EV009-D: documentação atualizada e aceite do mantenedor.
