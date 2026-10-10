# Tasks: 008 — Schema YAML v2 e script runner multiprocessos

> Tarefas propostas, ainda **não executadas**. Gerar/reconciliar lista detalhada com `$speckit-tasks`.

## Preparar e testar
- [ ] T001 Inventariar implementações existentes, casos de uso e gaps para FR-008.
- [ ] T002 [P] Desenhar contratos e regras de segurança, com teste primeiro; definir correlação, ordenação e transições dos eventos `command.*`.
- [ ] T003 [P] Implementar fixtures e testes negativos sem efeitos colaterais; incluir subprocesso silencioso, saída intercalada, concorrência, timeout, crash e erro de spawn.
- [ ] T003A Especificar read-model tipado de steps YAML v2 com IDs/ordem/status/bloqueios, sem transferir permissão de Apply à seleção ou ao foco da TUI.

## Entregar incremento utilizável
- [ ] T004 Implementar fluxo mínimo para entregar: Oferece v2 opt-in validado para steps Windows/Ubuntu/MSYS2 com execução por interpretador, deixando PSD1 v1 funcionando; publicar eventos de vida de comando sem misturá-los a stdout/stderr e sem renderizar spinner pelo runner.
- [ ] T005 Repetir Apply×2 em ambiente descartável e validar invariantes de compatibilidade.

## Comprovar conclusão
- [ ] T006 Executar AC-008-01 até AC-008-08 e registrar resultados redigidos, incluindo distinção entre autorização, execução, verificação, erro, timeout e interrupção; garantir ausência de eventos `running` órfãos durante silêncio de stdout.
- [ ] T007 Atualizar documentação de runbooks e trilha Notion ↔ Git ↔ testes.
- [ ] T008 Revisar segurança, logs, rollback, CI e PR da fase antes de avançar.

## Evidências obrigatórias
- [ ] EV008-A: CI/contratos compatíveis.
- [ ] EV008-B: logs redigidos de sucesso e erro.
- [ ] EV008-C: ensaio controlado em VM com estado anterior/posterior.
- [ ] EV008-D: documentação atualizada e aceite do mantenedor.
