# Tasks: 004 — WSL2 Ubuntu e toolchain Linux

> **Backlog inicial**, não executado. Ajustar com `$speckit-tasks` após `$speckit-plan`. Cada checkbox exige evidência concreta no PR.

## Gate A — Contrato e testes de segurança
- [ ] T001 [P] Inspecionar baseline nos arquivos Git envolvidos: runbooks/03/runbook.ps1, runbooks/03.1/runbook.ps1, docs/03-wsl.md; registrar lacunas contra AC-004.
- [ ] T002 [P] Criar ou ajustar mocks para caminhos negativos e para Test/Plan sem efeitos.
- [ ] T003 Definir contrato de entrada/saída, estado observável, pré-condições, privilégio e mecanismo de falha da fase.

## Gate B — Fatia funcional
- [ ] T004 Implementar o menor percurso feliz que entregue: Ubuntu WSL2 configurado, sem cruzamento acidental para binários Windows.
- [ ] T005 Testar idempotência (Apply×2 quando aplicável), conflito de estado preexistente e falha parcial.

## Gate C — Verificação e entrega
- [ ] T006 Validar cenários específicos AC-004-01 a AC-004-05 e anexar evidências de ambiente real/CI.
- [ ] T007 Atualizar documentação local e rastreabilidade com o que está de fato implementado, sem marcar itens pendentes como prontos.
- [ ] T008 Rodar suíte de regressão do projeto e revisar diffs, logs e exposição de segredos antes do PR.

## Evidência mínima
- [ ] EV004-A: screenshot/log redigido dos fluxos previstos e falhas.
- [ ] EV004-B: relatório das suites de teste e comandos exatos.
- [ ] EV004-C: resultados de duas execuções ou justificativa técnica quando não aplicável.
- [ ] EV004-D: diferença Git revisada + notas de compatibilidade/rollback.

**Não executado** até implementação e testes; `- [ ]` intencional em todos os itens.
