# Quickstart: 008 — Schema YAML v2 e script runner multiprocessos

> Roteiro de ensaio FUTURO em VM restaurável. Executar somente ações não mutáveis no host normal. A lista abaixo **não confirma** que os recursos já existem.

## Preparar
1. Fazer checkout da branch `feat/008-yaml-v2-runner` e registrar commit SHA, OS e versão de pwsh.
2. Revisar [spec.md](spec.md), constituição e matriz Notion; selecionar VM sem dados não recuperáveis.
3. Antes de qualquer Apply, executar Test/Plan, verificar suas saídas e observar se arquivos/PATH/registry mudaram.
4. Obter confirmação específica do usuário para cada execução mutável.

## Verificações seguras / dependentes de ambiente
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
pwsh -NoProfile -File tests/task-phases.tests.ps1
python tools/check_specs.py
```
Marcadores como distro/paths devem ser substituídos pelo valor **observado**, nunca assumir valores fixos. A ausência de `cargo`, `docker` ou `gcc` é estado `Blocked/NotInstalled`, não conclusão.

## Cenários observáveis
1. **AC-008-01:** Fixtures v2 válidas/invalidas cobrem schema, target, interpretação de versões, AST e dependências. Capturar versões, saída, código de retorno e estado após execução.
2. **AC-008-02:** PSD1 v1 continua com mesma execução/IDs/semântica enquanto v2 está habilitado separadamente. Capturar versões, saída, código de retorno e estado após execução.
3. **AC-008-03:** Teste adversarial tenta shell injection, path traversal e interpolação de token: todos rejeitados sem side effects. Capturar versões, saída, código de retorno e estado após execução.
4. **AC-008-04:** Timeout e falha em passo N interrompem dependentes e preservam stdout/stderr redigidos e códigos. Capturar versões, saída, código de retorno e estado após execução.
5. **AC-008-05:** Uma tarefa de exemplo executa Test→Plan→Apply→Verify com adaptador real em VM para Windows, Ubuntu e MSYS2. Capturar versões, saída, código de retorno e estado após execução.

## Resistência a falhas
- Dependência ausente: erro claro, não auto-instalação.
- Operação cancelada: nenhuma mutação.
- Exit code diferente de zero, timeout e dados inválidos: falha sem success falso.
- Segundo Apply: ausência de mudança redundante.
- Logs exportados: sem segredos, com RunId e status real.

## Resultado
PASS somente para todos AC-008 comprovados; BLOCKED quando faltarem ferramentas/VM; FAIL para divergência de pós-condição, UAC indevido ou mutação inesperada. **Rollback:** Feature flag v2 reversível, PSD1 mantém execução como fallback; não migrar catálogos em massa antes da paridade.
