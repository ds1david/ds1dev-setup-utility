# Quickstart: 006 — Workspaces nativos, shells e IDEs

> Roteiro de ensaio FUTURO em VM restaurável. Executar somente ações não mutáveis no host normal. A lista abaixo **não confirma** que os recursos já existem.

## Preparar
1. Fazer checkout da branch `feat/006-isolated-workspaces-shells-ides` e registrar commit SHA, OS e versão de pwsh.
2. Revisar [spec.md](spec.md), constituição e matriz Notion; selecionar VM sem dados não recuperáveis.
3. Antes de qualquer Apply, executar Test/Plan, verificar suas saídas e observar se arquivos/PATH/registry mudaram.
4. Obter confirmação específica do usuário para cada execução mutável.

## Verificações seguras / dependentes de ambiente
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
wsl -d <DISTRO> -- bash -lc 'findmnt -T /workspace; command -v java'
gcc -dumpmachine
```
Marcadores como distro/paths devem ser substituídos pelo valor **observado**, nunca assumir valores fixos. A ausência de `cargo`, `docker` ou `gcc` é estado `Blocked/NotInstalled`, não conclusão.

## Cenários observáveis
1. **AC-006-01:** Cada workspace retorna diretório físico distinto; no MSYS2 o caminho canônico pertence à instalação MSYS2, no Ubuntu pertence a filesystem Linux ext4. Capturar versões, saída, código de retorno e estado após execução.
2. **AC-006-02:** Reexecução de Apply não duplica PATH, mounts fstab, completions, aliases ou perfil Terminal. Capturar versões, saída, código de retorno e estado após execução.
3. **AC-006-03:** Alterações de compartilhamento exibem plano por pasta e exigem escolha; não há link nem permissão ampliada sem consentimento. Capturar versões, saída, código de retorno e estado após execução.
4. **AC-006-04:** Invocar code . e idea . abre diretório correto na IDE Windows ou produz diagnóstico claro se IDE não estiver instalada. Capturar versões, saída, código de retorno e estado após execução.
5. **AC-006-05:** Shells continuam inicializando se completions/oh-my-posh estiverem indisponíveis, preservando prompts anteriores. Capturar versões, saída, código de retorno e estado após execução.

## Resistência a falhas
- Dependência ausente: erro claro, não auto-instalação.
- Operação cancelada: nenhuma mutação.
- Exit code diferente de zero, timeout e dados inválidos: falha sem success falso.
- Segundo Apply: ausência de mudança redundante.
- Logs exportados: sem segredos, com RunId e status real.

## Resultado
PASS somente para todos AC-006 comprovados; BLOCKED quando faltarem ferramentas/VM; FAIL para divergência de pós-condição, UAC indevido ou mutação inesperada. **Rollback:** Restaurar arquivos de profile/Terminal/fstab pelo backup; não remover pastas existentes nem desmontar volumes não gerenciados.
