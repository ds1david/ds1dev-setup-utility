# Implementation Plan: 007 — Docker Desktop, validação integrada e backup/restore

> Documento técnico inicial; executar `$speckit-plan` e atualizar decisões em branch própria antes da codificação.

## Resumo
Diagnostica a integração Docker Windows/Ubuntu, gera relatório de ambiente e permite backup/restore ensaiado e seguro.

## Contexto técnico
- Host: Windows 11; PowerShell 5.1 para bootstrap e PS7 como runtime principal.
- Preservar contratos atuais PSD1 v1 e runbooks existentes; YAML v2 e Rust não estão prontos na baseline.
- Executar testes sem instalar ou modificar computador do desenvolvedor.
- Dependências: Fases 002/004/006 quando o recurso correspondente está selecionado; feature de backup independente do Docker.

## Constituição e avaliação de risco
Confirmar privilégio mínimo, confirmação, observabilidade, idempotência, fontes verificadas, independência de ambientes e rollback. Não tomar o código atual como automaticamente aderente: registrar dívida técnica e criar testes de regressão.

## Estratégia de implementação
1. Dividir Docker, validação e backup em tarefas discretas que não impõem dependência cruzada.
2. Preferir comandos de diagnóstico somente-leitura e JSON com allowlist de propriedades.
3. Versionar contratos e dados mínimos de restore e criar modo simulado para CI.
4. Introduzir gates de criptografia e recuperação real em VM antes de qualquer afirmação de proteção.

## Artefatos existentes a avaliar
- `docs/07-validacao.md`
- `docs/08-backup.md`
- `docs/arquitetura-executor.md`
- `runbooks/07/runbook.ps1`
- `runbooks/07/runbook.psd1`

## Contratos e estrutura a produzir
- Fluxo de entrada, estados, erro e pós-condições explícitos por runbook/adaptador.
- Testes unitários do contrato, testes de integração em VM e documentação com fontes Notion.
- Gate com evidência dos AC-007; sem alterações de IDs existentes e sem confundir feature flag com implementação.

## Validação recomendada
- `docker context ls; docker info`
- `wsl --list --verbose`
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- Ensaiar dois Apply na VM quando houver ação mutável; comparar diffs.
- Testar confirmação negada, dependência indisponível, falha parcial e logs sem segredo.

## Rollback e implantação
Não substituir backups existentes; restauração apenas sob destino temporário por padrão; reverter ajustes no Docker Desktop com backup prévio.

## Checklist de saída
Implementação limitada à fase, testes/CI green, pós-condições verificadas, evidências anexadas e PR revisada.
