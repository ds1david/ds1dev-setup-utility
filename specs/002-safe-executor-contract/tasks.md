# Tasks: 002 — Executor seguro, catálogo e diagnóstico sem admin

> **Backlog inicial**, não executado. Ajustar com `$speckit-tasks` após `$speckit-plan`. Cada checkbox exige evidência concreta no PR.

## Gate A — Contrato e testes de segurança
- [ ] T001 [P] Inspecionar baseline nos arquivos Git envolvidos: src/ds1-setup.ps1, src/Runbooks.psm1, src/Preflight.psm1; registrar lacunas contra AC-002.
- [ ] T002 [P] Criar ou ajustar mocks para caminhos negativos e para Test/Plan sem efeitos; cobrir ação silenciosa de longa duração, falha, espera e cancelamento do indicador `running`.
- [ ] T003 Definir contrato de entrada/saída, estado observável, pré-condições, privilégio e mecanismo de falha da fase; incluir identidade de comando e eventos de início/fim confiáveis.
- [ ] T003A Garantir read-model seguro para runbook PSD1 monolítico sem inventar steps internos; expor elegibilidade/bloqueios do motor para futura seleção na UI, mantendo Test/Plan somente-leitura.

## Gate B — Fatia funcional
- [ ] T004 Implementar o menor percurso feliz que entregue: Executar -List, -Task X -Plan e -Validate em contexto sem administrador e com resultado consistente, preservando runbooks PSD1; instrumentar ação existente e renderizar spinner inline na TUI PowerShell, sem contaminar logs nem mudar semântica do handler.
- [ ] T005 Testar idempotência (Apply×2 quando aplicável), conflito de estado preexistente e falha parcial.

## Gate C — Verificação e entrega
- [ ] T006 Validar cenários específicos AC-002-01 a AC-002-09, incluindo spinner Braille ciano a cada 80–100 ms, texto/timer, permissão `[s/N]`, estado verificando, falha com motivo real e fallback acessível, e anexar evidências de ambiente real/CI.
- [ ] T007 Atualizar documentação local e rastreabilidade com o que está de fato implementado, sem marcar itens pendentes como prontos.
- [ ] T008 Rodar suíte de regressão do projeto e revisar diffs, logs e exposição de segredos antes do PR.

## Evidência mínima
- [ ] EV002-A: screenshot/log redigido dos fluxos previstos e falhas.
- [ ] EV002-B: relatório das suites de teste e comandos exatos.
- [ ] EV002-C: resultados de duas execuções ou justificativa técnica quando não aplicável.
- [ ] EV002-D: diferença Git revisada + notas de compatibilidade/rollback.

**Não executado** até implementação e testes; `- [ ]` intencional em todos os itens.
