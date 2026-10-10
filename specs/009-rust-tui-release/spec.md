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
- **US5 / P1:** Como operador quero entrar em um runbook e ver passos selecionáveis à esquerda, detalhes e logs vivos à direita, além de prompts/atalhos contextuais abaixo, sem perder o contexto durante a execução.
- **US6 / P1:** Como operador quero percorrer etapas com setas ou `j/k`, usar Espaço e `a` para selecionar passos elegíveis, manter filtros/scroll sem perder seleção e revisar o plano antes de autorizar mudanças.

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
- **FR-009-11:** A TUI apresenta **duas vistas coerentes**: catálogo global existente com categorias/runbooks (aprox. 23/77), e **detalhe/execução de runbook** com lista de passos à esquerda (~40%), detalhes e logs ao vivo à direita (~60%), barra inferior fixa para permissão, status e atalhos; cabeçalho contém runbook, destino, seleção e progresso. Em 80×24 a 119×31, painéis alternáveis; abaixo, modo linear. O painel de passos permanece visível durante Apply no layout amplo.
- **FR-009-12:** Fornecer tema configurável **DS1 Modern Terminal**, inspirado na proposta visual do usuário, sem atribuí-lo como tema oficial do GitHub Spec Kit: fundo `#282C34`, bordas muted/rounded `#4B5263`, cursor violeta `#C678DD` (variante âmbar `#D19A66`), checkbox selecionado ciano `#56B6C2`, sucesso verificado verde `#98C379`, spinner de execução ciano-azulado `#61AFEF` (variante prévia `#00A3FF`), autorização amarelo `#E5C07B` e dicas esmaecidas `#5C6370`. Aumentar contraste dos textos que não forem legíveis, testar `NO_COLOR`, 16/256 cores, Unicode/ASCII e terminais sem bordas arredondadas; cores não são única indicação semântica.
- **FR-009-13:** Modelo UI mantém **separados** `focusedStepId`, conjunto de IDs selecionados e estado observado por step, sem confundir `❯`, `[x]` e `✔/⠋/?/○/✖`. Seleção persiste por ID após busca, filtro, reordenação e scroll. `Space` alterna o passo elegível e `a` alterna somente elegíveis no escopo/filtro visível, explicitando alcance; bloquear selecionar via lote itens inválidos/não implementados. Uma seleção não certifica instalação nem concede aprovação; durante Apply, a seleção do plano aprovado fica congelada.
- **FR-009-14:** No foco da lista, `↑/↓` e `j/k` navegam, `Space` marca, `a` marca elegíveis, `Tab/Shift+Tab` muda foco, `/` pesquisa, `p` mostra plano, `L` abre logs, `PageUp/PageDown/End` controla scroll/autofollow. Em busca/prompt/modal, teclas são locais, sem disparar atalhos globais. `Enter` na lista abre detalhe/subgrupo; **nunca inicia Apply diretamente**, mesmo que o exemplo visual proponha `[Enter] Rodar`. Aplicar requer etapa separada de revisão + confirmação negativa por padrão e validação do motor.
- **FR-009-15:** Painel direito consome informações do motor (descrição, dependências, target, versões, pré/pós-condição, comando sanitizado, stdout/stderr redigidos, resultado/código e log persistido), com scroll virtual/buffer finito, auto-follow opcional e entrada de usuário intacta na barra inferior. Spinner/timer e logs são simultâneos; não usar `eval`, não executar scripts ou inferir estados dentro de `draw_ui`. Runbooks PSD1 opacos aparecem como uma etapa sem inventar passos internos; YAML v2/checkpoints disponibilizam granularidade apenas quando reais.
- **FR-009-16:** Marcação em lote não instala dependências automaticamente. Antes de Apply, o motor revalida Test/Plan, explicita dependências transitivas, NoOp, passos bloqueados, permissão, destino, risco e ações concretas; falha/negativa preserva seleção sem executar o lote. Execução mantém a tela aberta para consulta/exportação de logs e tratamento de cancelamento seguro. A TUI é cliente, nunca autoridade de permissões ou da pós-verificação.

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
- **AC-009-11:** Em fixture com runbook de 5 passos, a vista ampla exibe passos (40%), detalhes/logs (60%) e barra inferior sem ocultação. Na execução, passos e logs continuam visíveis; em 80×24 alternam-se por foco; modo linear funciona sem TTY.
- **AC-009-12:** Setas/`j/k`, Espaço, `a`, Tab, `/` e navegação de logs são testados com foco, campo de busca e modal. Em input, `a/j/k/Enter` não disparam ações globais. `Enter` no catálogo e nos passos abre detalhe/revisão, nunca Apply; confirmação recusada não executa nada.
- **AC-009-13:** Cursor, seleção e estado observado são visualmente e semanticamente independentes. Seleção por IDs sobrevive a busca, filtro, reorder, scroll e refresh; `a` só inclui elegíveis do escopo indicado, bloqueados são explicados e dependências aparecem no plano sem Apply oculto.
- **AC-009-14:** Snapshot tests do tema verificam bordas arredondadas e fallback, foco violeta, check ciano, spinner azul-ciano, prompt amarelo, sucesso/erro distintos, contraste ajustado, `NO_COLOR` e modo ASCII; variante `#00A3FF` não altera semântica de eventos.
- **AC-009-15:** Fluxo de saída intensa e log sem newline mantém scroll/autofollow, timer, seleção congelada, painel direito responsivo e prompt/consentimento acessível; arquivos de logs permanecem íntegros, sem segredos nem frames de spinner.
- **AC-009-16:** Teste E2E sem efeitos em VM/fixtures comprova `Test→Plan→Confirm→Apply→Verify`, recusa, NoOp, dependência bloqueante, falha parcial e cancelamento: nenhum atalho navega para instalação sem confirmação, nenhum item vira `✔` sem pós-verificação.

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
- Git: `docs/tui-windows.md` (design system DS1 Modern Terminal, catálogo 23/77, runbook 40/60, navegação e estados do spinner)
- Git: `docs/script-runner-v2.md` (eventos estruturados de ciclo de vida)
- Git: `docs/guia-de-testes.md`
- Git: `README.md`
- [Rastreabilidade](../../docs/notion-runbook-traceability.md)
- [Constituição](../../.specify/memory/constitution.md)

## Evidências de conclusão
- Cada AC-009 possui ambiente, comando e evidência redigida documentados no PR.
- Testes negativos, conflito de estado preexistente e idempotência demonstrados.
- Só marcar um runbook `Implemented=true` após validação observável.
