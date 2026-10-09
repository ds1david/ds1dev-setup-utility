# Feature Specification: 001 — Handoff seguro PS5.1 → UAC → PS7

**Status:** Proposta para execução futura; não certifica código pronto.
**Feature branch recomendada:** `feat/001-safe-bootstrap-handoff`
**Fonte:** Git atual + wiki Notion (consulta 2026-10-09). **Dependências:** Nenhuma; aproveita implementação parcial do bootstrap.

## Contexto
Bootstrap retomável, sem travamento silencioso nem instalação inesperada; diagnostica a sessão elevada e respeita cancelamento.

O repositório já contém implementação parcial e testes. A entrega desta fase deve ser um delta pequeno, verificável e isolado da infraestrutura existente. Não recriar o projeto do zero e não assumir que exemplos de documentação já funcionem.

## Histórias de usuário
- **US1 (P1):** Como usuário em PS5.1 sem privilégio, quero saber exatamente por que o processo elevado falhou ou foi cancelado sem perder a sessão original.
- **US2 (P2):** Como usuário com pwsh compatível, quero reutilizar minha instalação em vez de baixar outra.
- **US3 (P3):** Como mantenedor, quero reproduzir falha de processo filho, cancelamento UAC e identidade divergente sem instalar software na máquina de teste.

## Requisitos
- **FR-001-01:** Preservar invocação por arquivo e parâmetros públicos atuais, em PowerShell 5.1 e PowerShell 7.4+.
- **FR-001-02:** Uma tentativa de elevação deve exibir a decisão, aguardar de modo limitado, encerrar/diagnosticar corretamente o processo filho e não deixar estado de sucesso falso.
- **FR-001-03:** Se UAC for negado, a conta elevada for diferente, a sessão abortada ou houver timeout, emitir erro com código, correlação e caminho completo para diagnóstico acessível ao usuário original.
- **FR-001-04:** Produzir registro seguro mesmo quando a janela elevada se fecha; nunca expor senha, token, linha de comando sensível ou depender de nome curto de pasta.
- **FR-001-05:** Fixar e verificar instalador PS7 oficial quando estritamente necessário, sem instalar WinGet para bootstrap e sem executar URL como código elevado.

## Critérios de aceite
- **AC-001-01:** Execução PS5.1 não elevada com UAC recusado retorna status diferente de zero e mensagem compreensível, sem nova instalação.
- **AC-001-02:** Elevação com mesmo usuário e pwsh já instalado inicia uma única instância do executor; janela original não fica presa após abortar.
- **AC-001-03:** Processo elevado encerrado inesperadamente e timeout simulado produzem diagnóstico com RunId e caminho de log existente; nenhum processo órfão.
- **AC-001-04:** Conta UAC diferente é rejeitada antes de alterar o profile do usuário original.
- **AC-001-05:** Testes de bootstrap e handoff existentes passam nos dois shells no Windows; testes negativos documentam evidência.

## Não escopo
Alterar arquitetura do motor de runbooks, instalar toolchains ou tornar todas as operações não elevadas (fase 002).

## Condições não funcionais e segurança
- Ações mutáveis somente via confirmação; testes e planos sem efeitos colaterais.
- Falha deve ser explícita, não transformar erro em `Installed` nem mascarar `exit code`.
- Registrar evidência e versão, redigindo segredo e preservando identidade.
- Regressão dos comandos/IDs atuais proibida salvo migração deliberada e testada.

## Fontes e rastreabilidade
- Wiki Notion: https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f67812e828ad07f279c20a7
- Git: `bootstrap.ps1`
- Git: `tests/bootstrap.tests.ps1`
- Git: `tests/bootstrap-handoff.tests.ps1`
- Git: `tests/bootstrap-discovery.tests.ps1`
- Git: `docs/tui-windows.md`
- Constituição: `../../.specify/memory/constitution.md`
- Rastreabilidade: `../../docs/notion-runbook-traceability.md`

## Métricas e evidência de saída
- 100% dos critérios AC desta fase demonstrados em testes e/ou ensaio manual controlado.
- Dois Apply consecutivos quando aplicável, com ausência de mutação redundante.
- Caminhos negativos testados e reportados no PR, junto de limitações de plataforma.
- Nenhum `Implemented=true` sem prova real de pós-condição.
