## Objetivo da mudança
Indique a fase `specs/NNN-*` e o resultado verificável para o usuário.

## Rastreabilidade
- Feature spec:
- Fontes Notion relevantes:
- Código/runbooks:
- Documentação atualizada:

## Evidências e testes
- [ ] `python tools/check_specs.py`
- [ ] Testes PowerShell preexistentes pertinentes
- [ ] Test/Plan sem side effects
- [ ] Aplicação em VM/snapshot autorizado
- [ ] Apply×2 sem mudança redundante (ou justificativa)
- [ ] Erro, timeout, confirmação recusada e reboot conforme escopo
- [ ] Log sanitizado e pós-condição observada
- [ ] Fase não avançou além do gate

## Compatibilidade e segurança
- [ ] IDs de runbooks legados preservados
- [ ] Contrato PSD1 preservado ou migração explicitamente testada
- [ ] Privilégio mínimo, identidade correta e consentimento
- [ ] Não executa script remoto elevado nem expõe credenciais
- [ ] Plano de rollback documentado
- [ ] `Implemented` só alterado após comprovação

## Limitações conhecidas / próximos passos
Documentar divergências de Notion, ambientes não testados e bloqueios; nunca marcar como concluído sem prova.
