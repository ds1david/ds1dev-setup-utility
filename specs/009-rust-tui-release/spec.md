# Feature Specification: 009 — TUI Rust/Ratatui e distribuição confiável

**Status:** Backlog; proposta ainda não implementada.
**Branch de feature:** `feat/009-rust-tui-release`
**Dependências:** 002, 008 aprovados; cobertura 003–007 representada sem prometer instalações ausentes.

## Contexto
UI navegável e pacote de release verificável com seleção consciente, plano e execução via motor estável.

O código preexistente e a wiki são materiais distintos. A fase 009 não valida a execução de scripts pelo simples fato de documentá-los.

## Histórias de usuário
- **US1 / P1:** Quero uma TUI rápida para buscar por categoria e selecionar tarefas sem instalar nada ao abrir o menu.
- **US2 / P2:** Quero comparar Test, Plan, Apply, dependências, estado e logs antes de confirmar uma tarefa.
- **US3 / P3:** Quero baixar release verificável sem executar script remoto mutável em admin.
- **US4 / P1:** Quero ver, ao lado de cada comando em andamento, um indicador animado semelhante ao spinner do `uv`/Codex, inclusive quando a operação não produz saída temporariamente, e reconhecer claramente quando terminou ou falhou.

## Requisitos
- **FR-009-01:** UI Rust/Ratatui atua como cliente do mesmo motor e catálogo; não duplicar lógica de detecção/Apply no frontend.
- **FR-009-02:** Navegação por teclado, seleção individual ou por lote, busca, descrição, links locais/Notion, progresso, logs e cancelamento previsível.
- **FR-009-03:** Abrir/fechar TUI não faz alterações no sistema; Apply exige confirmação por tarefa/batch e lista efeitos/precondições.
- **FR-009-04:** Mostrar estado derivado de observação atual, não estado histórico; não atribuir Installed a planejado.
- **FR-009-05:** Empacotar binário, scripts e manifests com integridade verificável, versões fixadas e SBOM ou inventário equivalente.
- **FR-009-06:** Validar release em Windows 11 limpo com PS5.1 e PS7; rollback preserva dados do usuário e não apaga ferramentas instaladas.
- **FR-009-07:** Cada comando/step realmente ativo aparece em **uma linha dinâmica** como `⠋ Executando <descrição amigável>... (4s)`, com spinner imediatamente à esquerda do texto, contador crescente e comando real redigido acessível nos detalhes. No catálogo/runbook, a tarefa-pai agrega os estados das ações filhas sem simular trabalho em comandos não iniciados. A UI anima exclusivamente a partir do ciclo de vida do motor, inclusive durante silêncio de stdout/stderr; espera por consentimento usa `?` com opção negativa padrão; após encerrar, `Verificando resultado...` antecede `✔` verde (sucesso observado) ou `✖` vermelho (falha real). Não considerar `exitCode=0` uma pós-condição satisfeita.
- **FR-009-08:** Usar os dez quadros Braille (`⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`) com atualização nominal **a cada 80–100 ms** (limite 10–12,5 fps), sem fontes externas. Spinner ciano preferencial `#00A3FF` (fallback ANSI ciano), texto principal na cor do tema e timer `(4s)`, `(5.2s)`, `(1m12s)` cinza/esmaecido; `✔` verde e `✖` vermelho acompanhados de texto claro. Respeitar acessibilidade/contraste e `NO_COLOR`; usar ASCII (`| / - \`) ou estado textual estático em terminais incompatíveis, redirecionados ou com `DS1_NO_SPINNER=1`. Não registrar frames, ANSI ou oscilações de timer nos logs persistidos. A renderização não interfere no fluxo do subprocesso.
- **FR-009-09:** No Windows Terminal/Console Host que permitir alteração segura do título, **opcionalmente** refletir o estado ativo na aba/janela com título prefixado por spinner/`DS1 em execução`, sem assumir que todo terminal suporta sequências OSC; preservar/restaurar título anterior em término, exceção ou cancelamento. O indicador inline é obrigatório mesmo quando o título for indisponível. Não alterar títulos de sessões ou processos que a aplicação não controla.
- **FR-009-10:** Em execução concorrente, cada comando mantém indicador e temporização próprios, ligados a `runId/taskId/stepId/commandId`; quando houver operação aguardando autenticação, UAC, entrada do usuário ou aprovação, exibir estado explícito `Aguardando ação` em vez de atividade fictícia.

## Critérios de aceite
- **AC-009-01:** TUI lista todos os runbooks que CLI lista, com dependências e estados equivalentes.
- **AC-009-02:** Abertura/fechamento, navegação, busca, Test e Plan não provocam instalação nem alteração de PATH.
- **AC-009-03:** Confirmação recusada cancela seleção inteira ou ação indicada sem Apply oculto.
- **AC-009-04:** Erros de subprocesso, pending reboot e logs continuam visíveis na interface e exportáveis de forma redigida.
- **AC-009-05:** Pacote release inclui checksums e processo de verificação documentado; teste de instalação a partir de Windows limpo registra evidências.
- **AC-009-06:** Em comando fixture sem saída por pelo menos 5 segundos, o indicador inline segue animado e o tempo decorrido avança; no evento terminal, cessa em até um refresh e mostra status e código corretos. Verificar sucesso com e sem pós-condição satisfeita, erro, timeout, Ctrl+C, spawn inválido e cancelamento.
- **AC-009-07:** Windows Terminal e Console Host com suporte exibem spinner em 80×24 e 120×32; fallback sem TTY, Unicode desabilitado e `DS1_NO_SPINNER=1` não emite frames repetidos, caracteres de controle em log nem degrada execução. Título da janela é restaurado quando a alteração for habilitada e suportada.
- **AC-009-08:** Vários steps em paralelo mantêm spinners isolados; evento atrasado/duplicado ou erro de renderização não transforma `failed` em sucesso nem deixa indicadores órfãos. Pausa para interação aparece como espera, não como atividade.
- **AC-009-09:** Capturar na TUI interativa ao menos dois frames distintos em intervalos nominais 80–100 ms, spinner ciano (`#00A3FF` quando truecolor estiver disponível), timer cinza, mesmo número de linhas renderizadas e descrição do comando legível; verificar resultado visual `✔ ... (5.2s)`/`✖ ... (1.1s)`, com textos sem dependência exclusiva das cores.
- **AC-009-10:** Fluxo de consentimento `[s/N]` não anima até aprovação; processo concluído enquanto pós-condição está pendente apresenta `Verificando resultado...` sem ícone de sucesso prematuro. Validar título durante execução e restauração quando o host suportar, além de fallback acessível/sem animação.

## Não escopo
Backend web, execução unattended, rate limiter, orquestração central ou cópia de senhas.

## Requisitos globais e restrições
- Nenhum comando Test/Plan deve produzir efeito colateral; Apply explícito, confirmado, idempotente e verificável.
- Estado observado e evidência acima de histórico; cenários de falha nunca declarados concluídos.
- Operações administrativas granulares, logs redigidos e nenhum acesso automático a recursos corporativos.
- Preservar interfaces legadas até migração compatível e testada.
- Não renumerar os IDs PSD1 atuais para acomodar os números históricos da wiki Notion.

## Fontes consultadas e código de referência
- Notion: https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc
- Git: `src/Tui.psm1`
- Git: `src/ds1-setup.ps1`
- Git: `docs/tui-windows.md` (contrato visual de spinner e título de terminal)
- Git: `docs/script-runner-v2.md` (eventos estruturados de ciclo de vida)
- Git: `docs/guia-de-testes.md`
- Git: `README.md`
- [Rastreabilidade](../../docs/notion-runbook-traceability.md)
- [Constituição](../../.specify/memory/constitution.md)

## Evidências de conclusão
- Cada AC-009 possui ambiente, comando e evidência redigida documentados no PR.
- Testes negativos, conflito de estado preexistente e idempotência demonstrados.
- Só marcar um runbook `Implemented=true` após validação observável.
