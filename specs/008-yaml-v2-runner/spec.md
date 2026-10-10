# Feature Specification: 008 — Schema YAML v2 e script runner multiprocessos

**Status:** Backlog; proposta ainda não implementada.
**Branch de feature:** `feat/008-yaml-v2-runner`
**Dependências:** Fase 002 consolidada; não requer TUI Rust e não autoriza migração em massa antecipada.

## Contexto
Oferece v2 opt-in validado para steps Windows/Ubuntu/MSYS2 com execução por interpretador, deixando PSD1 v1 funcionando.

O código preexistente e a wiki são materiais distintos. A fase 008 não valida a execução de scripts pelo simples fato de documentá-los.

## Histórias de usuário
- **US1 / P1:** Quero definir novas tarefas com múltiplos checks e steps sem duplicar script orquestrador.
- **US2 / P2:** Quero selecionar interpreter/target/version sem executar Windows Bash acidentalmente em WSL ou vice-versa.
- **US3 / P3:** Quero logs stdout/stderr, exit code e estado por step com rastreabilidade sem vazamento de segredos.

## Requisitos
- **FR-008-01:** Definir schema YAML v2 com versionamento, IDs imutáveis, dependências, checks, exec actions, alvo, interpretador, timeout, verificação, rollback opcional e atributos de privilégio.
- **FR-008-02:** Resolver YAML por parser distribuído/pinado e confiável; não exigir Python previamente instalado em Windows limpo, não usar eval de string como comando.
- **FR-008-03:** Executar PowerShell Windows, Bash WSL distro indicada e Bash MSYS2 UCRT64 por adaptadores separados, com argumento explícito sem interpolação de shell e env permitidas.
- **FR-008-04:** Receber streams stdout/stderr separados, código de saída, duração, cancelamento, timeout, pending reboot e log JSONL com redaction.
- **FR-008-05:** Rejeitar traversal, cwd fora do permitido, binário não confiável, shell injection, dependência circular e segredo em config/log.
- **FR-008-06:** Manter compatibilidade PSD1 v1, desabilitar YAML novo por default durante piloto e fornecer migração incremental com fixture real.

## Critérios de aceite
- **AC-008-01:** Fixtures v2 válidas/invalidas cobrem schema, target, interpretação de versões, AST e dependências.
- **AC-008-02:** PSD1 v1 continua com mesma execução/IDs/semântica enquanto v2 está habilitado separadamente.
- **AC-008-03:** Teste adversarial tenta shell injection, path traversal e interpolação de token: todos rejeitados sem side effects.
- **AC-008-04:** Timeout e falha em passo N interrompem dependentes e preservam stdout/stderr redigidos e códigos.
- **AC-008-05:** Uma tarefa de exemplo executa Test→Plan→Apply→Verify com adaptador real em VM para Windows, Ubuntu e MSYS2.

## Não escopo
Rust TUI, download de catálogo pela internet, execução remota e descontinuação imediata do PSD1.

## Requisitos globais e restrições
- Nenhum comando Test/Plan deve produzir efeito colateral; Apply explícito, confirmado, idempotente e verificável.
- Estado observado e evidência acima de histórico; cenários de falha nunca declarados concluídos.
- Operações administrativas granulares, logs redigidos e nenhum acesso automático a recursos corporativos.
- Preservar interfaces legadas até migração compatível e testada.
- Não renumerar os IDs PSD1 atuais para acomodar os números históricos da wiki Notion.

## Fontes consultadas e código de referência
- Notion: https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc
- Git: `docs/modelo-runbooks-v2.md`
- Git: `docs/perfis-ambientes-versoes-v2.md`
- Git: `docs/script-runner-v2.md`
- Git: `src/Runbooks.psm1`
- Git: `runbooks/**/runbook.psd1`
- [Rastreabilidade](../../docs/notion-runbook-traceability.md)
- [Constituição](../../.specify/memory/constitution.md)

## Evidências de conclusão
- Cada AC-008 possui ambiente, comando e evidência redigida documentados no PR.
- Testes negativos, conflito de estado preexistente e idempotência demonstrados.
- Só marcar um runbook `Implemented=true` após validação observável.
