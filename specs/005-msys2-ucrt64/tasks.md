# Tasks: 005 — MSYS2 UCRT64 funcional e isolado

> **Backlog inicial**, não executado. Ajustar com `$speckit-tasks` após `$speckit-plan`. Cada checkbox exige evidência concreta no PR.

## Gate A — Contrato e testes de segurança
- [ ] T001 [P] Inspecionar baseline nos arquivos Git envolvidos: runbooks/04/runbook.ps1, runbooks/04.1/runbook.ps1, docs/04-msys2.md; registrar lacunas contra AC-005.
- [ ] T002 [P] Criar ou ajustar mocks para caminhos negativos e para Test/Plan sem efeitos.
- [ ] T003 Definir contrato de entrada/saída, estado observável, pré-condições, privilégio e mecanismo de falha da fase.

## Gate B — Fatia funcional
- [ ] T004 Implementar o menor percurso feliz que entregue: MSYS2 UCRT64 instalado com gerenciador pacman, GCC/CMake/Ninja e perfil de Terminal verificável.
- [ ] T005 Testar idempotência (Apply×2 quando aplicável), conflito de estado preexistente e falha parcial.

## Gate C — Verificação e entrega
- [ ] T006 Validar cenários específicos AC-005-01 a AC-005-05 e anexar evidências de ambiente real/CI.
- [ ] T007 Atualizar documentação local e rastreabilidade com o que está de fato implementado, sem marcar itens pendentes como prontos.
- [ ] T008 Rodar suíte de regressão do projeto e revisar diffs, logs e exposição de segredos antes do PR.

## Evidência mínima
- [ ] EV005-A: screenshot/log redigido dos fluxos previstos e falhas.
- [ ] EV005-B: relatório das suites de teste e comandos exatos.
- [ ] EV005-C: resultados de duas execuções ou justificativa técnica quando não aplicável.
- [ ] EV005-D: diferença Git revisada + notas de compatibilidade/rollback.

**Não executado** até implementação e testes; `- [ ]` intencional em todos os itens.
