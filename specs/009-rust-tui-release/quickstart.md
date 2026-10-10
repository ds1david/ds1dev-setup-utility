# Quickstart: 009 — TUI Rust/Ratatui e distribuição confiável

> Roteiro de ensaio FUTURO em VM restaurável. Executar somente ações não mutáveis no host normal. A lista abaixo **não confirma** que os recursos já existem.

## Preparar
1. Fazer checkout da branch `feat/009-rust-tui-release` e registrar commit SHA, OS e versão de pwsh.
2. Revisar [spec.md](spec.md), constituição e matriz Notion; selecionar VM sem dados não recuperáveis.
3. Antes de qualquer Apply, executar Test/Plan, verificar suas saídas e observar se arquivos/PATH/registry mudaram.
4. Obter confirmação específica do usuário para cada execução mutável.

## Verificações seguras / dependentes de ambiente
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
cargo test
python tools/check_specs.py
```
Marcadores como distro/paths devem ser substituídos pelo valor **observado**, nunca assumir valores fixos. A ausência de `cargo`, `docker` ou `gcc` é estado `Blocked/NotInstalled`, não conclusão.

## Cenários observáveis
1. **AC-009-01:** TUI lista todos os runbooks que CLI lista, com dependências e estados equivalentes. Capturar versões, saída, código de retorno e estado após execução.
2. **AC-009-02:** Abertura/fechamento, navegação, busca, Test e Plan não provocam instalação nem alteração de PATH. Capturar versões, saída, código de retorno e estado após execução.
3. **AC-009-03:** Confirmação recusada cancela seleção inteira ou ação indicada sem Apply oculto. Capturar versões, saída, código de retorno e estado após execução.
4. **AC-009-04:** Erros de subprocesso, pending reboot e logs continuam visíveis na interface e exportáveis de forma redigida. Capturar versões, saída, código de retorno e estado após execução.
5. **AC-009-05:** Pacote release inclui checksums e processo de verificação documentado; teste de instalação a partir de Windows limpo registra evidências. Capturar versões, saída, código de retorno e estado após execução.

## Resistência a falhas
- Dependência ausente: erro claro, não auto-instalação.
- Operação cancelada: nenhuma mutação.
- Exit code diferente de zero, timeout e dados inválidos: falha sem success falso.
- Segundo Apply: ausência de mudança redundante.
- Logs exportados: sem segredos, com RunId e status real.

## Resultado
PASS somente para todos AC-009 comprovados; BLOCKED quando faltarem ferramentas/VM; FAIL para divergência de pós-condição, UAC indevido ou mutação inesperada. **Rollback:** Manter CLI/TUI PowerShell como fallback, nunca alterar manifests/runbooks por navegação da UI.
