# Quickstart: 007 — Docker Desktop, validação integrada e backup/restore

> Roteiro de ensaio FUTURO em VM restaurável. Executar somente ações não mutáveis no host normal. A lista abaixo **não confirma** que os recursos já existem.

## Preparar
1. Fazer checkout da branch `feat/007-docker-backup-validation` e registrar commit SHA, OS e versão de pwsh.
2. Revisar [spec.md](spec.md), constituição e matriz Notion; selecionar VM sem dados não recuperáveis.
3. Antes de qualquer Apply, executar Test/Plan, verificar suas saídas e observar se arquivos/PATH/registry mudaram.
4. Obter confirmação específica do usuário para cada execução mutável.

## Verificações seguras / dependentes de ambiente
```powershell
python tools/check_specs.py
docker context ls; docker info
wsl --list --verbose
pwsh -NoProfile -File tests/runbooks.tests.ps1
```
Marcadores como distro/paths devem ser substituídos pelo valor **observado**, nunca assumir valores fixos. A ausência de `cargo`, `docker` ou `gcc` é estado `Blocked/NotInstalled`, não conclusão.

## Cenários observáveis
1. **AC-007-01:** Em host sem Docker, o diagnóstico funciona, marca Docker ausente e não instala nem inicia engine. Capturar versões, saída, código de retorno e estado após execução.
2. **AC-007-02:** Com WSL configurado, docker info mostra engine esperada sem troca silenciosa; conflito gera Blocked com correção manual. Capturar versões, saída, código de retorno e estado após execução.
3. **AC-007-03:** Execução de diagnóstico produz artefato sem tokens/segredos e com evidência de versões verificáveis. Capturar versões, saída, código de retorno e estado após execução.
4. **AC-007-04:** Backup de amostra validado por checksum e restore em diretório de teste; conteúdo comparado depois de recuperar. Capturar versões, saída, código de retorno e estado após execução.
5. **AC-007-05:** Backups de distro não chamam wsl --unregister; opções de sobrescrita vêm desabilitadas por padrão. Capturar versões, saída, código de retorno e estado após execução.

## Resistência a falhas
- Dependência ausente: erro claro, não auto-instalação.
- Operação cancelada: nenhuma mutação.
- Exit code diferente de zero, timeout e dados inválidos: falha sem success falso.
- Segundo Apply: ausência de mudança redundante.
- Logs exportados: sem segredos, com RunId e status real.

## Resultado
PASS somente para todos AC-007 comprovados; BLOCKED quando faltarem ferramentas/VM; FAIL para divergência de pós-condição, UAC indevido ou mutação inesperada. **Rollback:** Não substituir backups existentes; restauração apenas sob destino temporário por padrão; reverter ajustes no Docker Desktop com backup prévio.
