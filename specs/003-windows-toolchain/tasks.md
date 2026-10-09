# Tasks: 003 — Instalação Windows básica, Java/Maven/Gradle

> **Backlog inicial**, não executado. Ajustar com `$speckit-tasks` após `$speckit-plan`. Cada checkbox exige evidência concreta no PR.

## Gate A — Contrato e testes de segurança
- [ ] T001 [P] Inspecionar baseline nos arquivos Git envolvidos: runbooks/02/runbook.ps1, runbooks/02.1/runbook.ps1, runbooks/02/runbook.psd1; registrar lacunas contra AC-003.
- [ ] T002 [P] Criar ou ajustar mocks para caminhos negativos e para Test/Plan sem efeitos.
- [ ] T003 Definir contrato de entrada/saída, estado observável, pré-condições, privilégio e mecanismo de falha da fase.

## Gate B — Fatia funcional
- [ ] T004 Implementar o menor percurso feliz que entregue: Usuário instala e valida ferramentas de desenvolvimento Windows sob demanda, inclusive quando WinGet ou PATH faltam.
- [ ] T005 Testar idempotência (Apply×2 quando aplicável), conflito de estado preexistente e falha parcial.

## Gate C — Verificação e entrega
- [ ] T006 Validar cenários específicos AC-003-01 a AC-003-05 e anexar evidências de ambiente real/CI.
- [ ] T007 Atualizar documentação local e rastreabilidade com o que está de fato implementado, sem marcar itens pendentes como prontos.
- [ ] T008 Rodar suíte de regressão do projeto e revisar diffs, logs e exposição de segredos antes do PR.

## Evidência mínima
- [ ] EV003-A: screenshot/log redigido dos fluxos previstos e falhas.
- [ ] EV003-B: relatório das suites de teste e comandos exatos.
- [ ] EV003-C: resultados de duas execuções ou justificativa técnica quando não aplicável.
- [ ] EV003-D: diferença Git revisada + notas de compatibilidade/rollback.

**Não executado** até implementação e testes; `- [ ]` intencional em todos os itens.
