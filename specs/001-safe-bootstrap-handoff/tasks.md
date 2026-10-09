# Tasks: 001 — Handoff seguro PS5.1 → UAC → PS7

> **Backlog inicial**, não executado. Ajustar com `$speckit-tasks` após `$speckit-plan`. Cada checkbox exige evidência concreta no PR.

## Gate A — Contrato e testes de segurança
- [ ] T001 [P] Inspecionar baseline nos arquivos Git envolvidos: bootstrap.ps1, tests/bootstrap.tests.ps1, tests/bootstrap-handoff.tests.ps1; registrar lacunas contra AC-001.
- [ ] T002 [P] Criar ou ajustar mocks para caminhos negativos e para Test/Plan sem efeitos.
- [ ] T003 Definir contrato de entrada/saída, estado observável, pré-condições, privilégio e mecanismo de falha da fase.

## Gate B — Fatia funcional
- [ ] T004 Implementar o menor percurso feliz que entregue: Bootstrap retomável, sem travamento silencioso nem instalação inesperada; diagnostica a sessão elevada e respeita cancelamento.
- [ ] T005 Testar idempotência (Apply×2 quando aplicável), conflito de estado preexistente e falha parcial.

## Gate C — Verificação e entrega
- [ ] T006 Validar cenários específicos AC-001-01 a AC-001-05 e anexar evidências de ambiente real/CI.
- [ ] T007 Atualizar documentação local e rastreabilidade com o que está de fato implementado, sem marcar itens pendentes como prontos.
- [ ] T008 Rodar suíte de regressão do projeto e revisar diffs, logs e exposição de segredos antes do PR.

## Evidência mínima
- [ ] EV001-A: screenshot/log redigido dos fluxos previstos e falhas.
- [ ] EV001-B: relatório das suites de teste e comandos exatos.
- [ ] EV001-C: resultados de duas execuções ou justificativa técnica quando não aplicável.
- [ ] EV001-D: diferença Git revisada + notas de compatibilidade/rollback.

**Não executado** até implementação e testes; `- [ ]` intencional em todos os itens.
