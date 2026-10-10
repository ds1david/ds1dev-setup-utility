# Feature Specification: 002 — Executor seguro, catálogo e diagnóstico sem admin

**Status:** Proposta para execução futura; não certifica código pronto.
**Feature branch recomendada:** `feat/002-safe-executor-contract`
**Fonte:** Git atual + wiki Notion (consulta 2026-10-09). **Dependências:** 001 aprovado; execução real depende apenas das dependências declaradas da tarefa.

## Contexto
Executar -List, -Task X -Plan e -Validate em contexto sem administrador e com resultado consistente, preservando runbooks PSD1.

O repositório já contém implementação parcial e testes. A entrega desta fase deve ser um delta pequeno, verificável e isolado da infraestrutura existente. Não recriar o projeto do zero e não assumir que exemplos de documentação já funcionem.

## Histórias de usuário
- **US1 (P1):** Como usuário padrão quero inspecionar o estado e o plano de instalação sem UAC.
- **US2 (P2):** Como administrador responsável quero autorizar somente as ações que exigem privilégios.
- **US3 (P3):** Como criador de runbook quero schema estável, isolamento de caminhos, logs adequados e falhas rastreáveis.
- **US4 (P2):** Como operador quero identificar visualmente quais comandos estão realmente em execução no runbook, mesmo enquanto não imprimem saída.

## Requisitos
- **FR-002-01:** Test/Plan/-List/-Validate não geram mutações observáveis nem elevam processos; instalações somente por Apply e confirmação explícita.
- **FR-002-02:** Continuar a descobrir runbooks em runbooks/**/runbook.psd1 sem lista de IDs codificada na interface.
- **FR-002-03:** Rejeitar ID duplicado, dependência ausente/cíclica, path traversal, schema errado e retorno diferente de hashtable único.
- **FR-002-04:** Reportar status NotInstalled/Ready/Installed/NeedsReboot/Failed/Blocked ou documentar tradução dos nomes já implementados sem declarar planejado como instalado.
- **FR-002-05:** Encaminhar stdout/stderr/exit code de processos de forma determinística, redigir segredos e distinguir observação atual do histórico.
- **FR-002-06:** Blocked para dependência faltante não instala essa dependência automaticamente; Apply revalida e verifica pós-condição.
- **FR-002-07:** O motor informa início e término efetivos de cada ação instrumentada (incluindo runbook PSD1), com identificadores estáveis `runId/taskId/stepId/commandId`, comando sanitizado, timestamps, duração e resultado. O renderizador provisório PowerShell pode animar um ícone `running` na linha do comando **somente entre início real e término**, sem usar stdout como sinal de atividade. Um bloco opaco sem checkpoints conta como uma única ação, não como comandos internos inventados.
- **FR-002-08:** A interface atual PowerShell deve exibir por ação instrumentada uma única linha dinâmica no formato `⠋ Executando <descrição>... (4s)` enquanto ativa: spinner Braille ciano preferencial `#00A3FF` a cada 80–100 ms, texto principal legível e timer esmaecido; final `✔ <resultado> (5.2s)` verde ou `✖ <erro real> (1.1s)` vermelho. Aguardando autorização/input usa `?` sem spinner, e a pós-verificação usa `Verificando resultado...` antes de anunciar sucesso. Fallback ASCII/textual, `NO_COLOR`, `DS1_NO_SPINNER=1`, terminais incompatíveis, saída redirecionada e logs/transcrições não contêm frames de animação. Parar o spinner em sucesso, erro, cancelamento, timeout e exceção. Não exigir Rust nem YAML v2 para implementar o indicador nas ações PSD1 já instrumentadas.

- **FR-002-09:** Publicar para interfaces uma representação **somente leitura** das unidades realmente conhecidas por runbook PSD1: identidade estável do runbook/etapa, descrição, estado observado, dependências, capacidade de Apply, bloqueios, target e resultado de Test/Plan. Se o handler for monolítico, expor **uma única unidade** em vez de inventar cinco passos internos para preencher a TUI. Seleção visual e cursor não autorizam ações. O contrato de catálogo PSD1 e a descoberta dinâmica permanecem inalterados.

## Critérios de aceite
- **AC-002-01:** Com usuário padrão e runbooks não implementados, -List/-Plan/-Validate terminam sem UAC, escrita em ProgramData protegido ou outras mutações.
- **AC-002-02:** PSD1 v1 continua carregando todos os IDs existentes e bloqueando Apply com Implemented=false.
- **AC-002-03:** Manifesto malicioso ou inválido é rejeitado antes de executar qualquer script.
- **AC-002-04:** Apply com confirmação recusada não executa ação; Apply permitido verifica estado final e trata falhas de comando nativo.
- **AC-002-05:** Testes de contrato e de logs demonstram ausência de segredos e distinção de sucesso, parcial, bloqueado e erro.
- **AC-002-06:** Ação instrumentada em fixture que dura 5 segundos sem stdout mantém `running` e contador na tela; a animação para na conclusão e o ícone final corresponde ao resultado real. Início negado, exceção anterior ao spawn e falta de confirmação nunca exibem execução fictícia.
- **AC-002-07:** Execução redirecionada, `Start-Transcript`, pipeline e terminal limitado não acumulam frames/escapes no log; sem suporte visual o estado `Em execução` permanece legível. Testar Ctrl+C e timeout sem spinner órfão.
- **AC-002-08:** No host compatível, fixture silenciosa por ≥5 s mostra ao menos dois quadros Braille distintos e timer crescente sem emitir linhas novas; a pausa para permissão mantém `?` e opção negativa padrão. Saída 0 com pós-checagem negativa não exibe `✔`, e `✖` apresenta causa e duração. Testar troca de cor sem depender exclusivamente dela, e fallback sem cor/animação.
- **AC-002-09:** Para um runbook PSD1 opaco, a TUI recebe uma unidade identificável e não relata passos internos inexistentes; estado/bloqueio do motor não pode ser sobrescrito pelo `[x]` do frontend. Test/Plan e navegação não elevam nem executam instalação.

## Não escopo
Migração YAML v2, instaladores de ferramentas ou substituição da TUI por Rust. O indicador inline desta fase se aplica apenas a ações que o motor atual instrumenta; captura de subprocessos opacos e paralelismo completo são contratos da fase 008.

## Condições não funcionais e segurança
- Ações mutáveis somente via confirmação; testes e planos sem efeitos colaterais.
- Falha deve ser explícita, não transformar erro em `Installed` nem mascarar `exit code`.
- Registrar evidência e versão, redigindo segredo e preservando identidade.
- Regressão dos comandos/IDs atuais proibida salvo migração deliberada e testada.

## Fontes e rastreabilidade
- Wiki Notion: https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f678117b4b3ffe0ccd4b228
- Git: `src/ds1-setup.ps1`
- Git: `src/Runbooks.psm1`
- Git: `src/Preflight.psm1`
- Git: `src/TaskPhases.psm1`
- Git: `src/Tui.psm1`
- Git: `runbooks/**/runbook.psd1`
- Git: `tests/runbooks.tests.ps1`
- Git: `tests/task-phases.tests.ps1`
- Constituição: `../../.specify/memory/constitution.md`
- Rastreabilidade: `../../docs/notion-runbook-traceability.md`

## Métricas e evidência de saída
- 100% dos critérios AC desta fase demonstrados em testes e/ou ensaio manual controlado.
- Dois Apply consecutivos quando aplicável, com ausência de mutação redundante.
- Caminhos negativos testados e reportados no PR, junto de limitações de plataforma.
- Nenhum `Implemented=true` sem prova real de pós-condição.
