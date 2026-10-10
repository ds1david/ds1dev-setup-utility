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

## Requisitos
- **FR-002-01:** Test/Plan/-List/-Validate não geram mutações observáveis nem elevam processos; instalações somente por Apply e confirmação explícita.
- **FR-002-02:** Continuar a descobrir runbooks em runbooks/**/runbook.psd1 sem lista de IDs codificada na interface.
- **FR-002-03:** Rejeitar ID duplicado, dependência ausente/cíclica, path traversal, schema errado e retorno diferente de hashtable único.
- **FR-002-04:** Reportar status NotInstalled/Ready/Installed/NeedsReboot/Failed/Blocked ou documentar tradução dos nomes já implementados sem declarar planejado como instalado.
- **FR-002-05:** Encaminhar stdout/stderr/exit code de processos de forma determinística, redigir segredos e distinguir observação atual do histórico.
- **FR-002-06:** Blocked para dependência faltante não instala essa dependência automaticamente; Apply revalida e verifica pós-condição.

## Critérios de aceite
- **AC-002-01:** Com usuário padrão e runbooks não implementados, -List/-Plan/-Validate terminam sem UAC, escrita em ProgramData protegido ou outras mutações.
- **AC-002-02:** PSD1 v1 continua carregando todos os IDs existentes e bloqueando Apply com Implemented=false.
- **AC-002-03:** Manifesto malicioso ou inválido é rejeitado antes de executar qualquer script.
- **AC-002-04:** Apply com confirmação recusada não executa ação; Apply permitido verifica estado final e trata falhas de comando nativo.
- **AC-002-05:** Testes de contrato e de logs demonstram ausência de segredos e distinção de sucesso, parcial, bloqueado e erro.

## Não escopo
Migração YAML v2, instaladores de ferramentas ou substituição da TUI por Rust.

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
