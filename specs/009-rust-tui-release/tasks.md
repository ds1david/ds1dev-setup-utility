# Tasks: 009 — TUI Rust/Ratatui e distribuição confiável

> Tarefas propostas, ainda **não executadas**. Gerar/reconciliar lista detalhada com `$speckit-tasks`.

## Preparar e testar
- [ ] T001 Inventariar implementações existentes, casos de uso e gaps para FR-009.
- [ ] T002 [P] Desenhar contratos e regras de segurança, com teste primeiro; incluir eventos `command.started/finished/waiting`, correlação por `commandId` e transições que impedem spinners órfãos.
- [ ] T003 [P] Implementar fixtures e testes negativos sem efeitos colaterais; incluir processos silenciosos, concorrência, erro de spawn, timeout, cancelamento, redirecionamento de saída e terminal sem Unicode.

## Entregar incremento utilizável
- [ ] T004 Implementar UI navegável e pacote verificável com plano/consentimento; indicador inline por comando/tarefa com 10 frames Braille, tick de 80–100 ms, spinner ciano `#00A3FF` quando suportado, descrição, timer esmaecido, `?` antes de confirmar, `◌` ao verificar, `✔/✖` após resultado, fallback ASCII/estático/`NO_COLOR`/`DS1_NO_SPINNER` e título da aba restaurável.
- [ ] T005 Repetir Apply×2 em ambiente descartável e validar invariantes de compatibilidade.

## Comprovar conclusão
- [ ] T006 Executar AC-009-01 até AC-009-10, incluindo precisão nominal do tick (80–100 ms), estilos de cor, descrição/timer, mesma linha, espera por permissão, pós-verificação, erro, fallback acessível e logs sem frames; registrar evidências redigidas.
- [ ] T007 Atualizar documentação de runbooks e trilha Notion ↔ Git ↔ testes.
- [ ] T008 Revisar segurança, logs, rollback, CI e PR da fase antes de avançar.

## Evidências obrigatórias
- [ ] EV009-A: CI/contratos compatíveis.
- [ ] EV009-B: logs redigidos de sucesso e erro; gravação/captura visual que comprova animação somente enquanto o comando está ativo, com quadro final correto.
- [ ] EV009-C: ensaio controlado em VM com estado anterior/posterior.
- [ ] EV009-D: documentação atualizada e aceite do mantenedor.
