# Implementation Plan: 006 — Workspaces nativos, shells e IDEs

> Documento técnico inicial; executar `$speckit-plan` e atualizar decisões em branch própria antes da codificação.

## Resumo
Cria três workspaces independentes e perfis de shell reaplicáveis, integrando IDEs Windows sem compartilhar configurações internas.

## Contexto técnico
- Host: Windows 11; PowerShell 5.1 para bootstrap e PS7 como runtime principal.
- Preservar contratos atuais PSD1 v1 e runbooks existentes; YAML v2 e Rust não estão prontos na baseline.
- Executar testes sem instalar ou modificar computador do desenvolvedor.
- Dependências: Fases 002, 004 e 005; cada subetapa exige apenas seu ambiente.

## Constituição e avaliação de risco
Confirmar privilégio mínimo, confirmação, observabilidade, idempotência, fontes verificadas, independência de ambientes e rollback. Não tomar o código atual como automaticamente aderente: registrar dívida técnica e criar testes de regressão.

## Estratégia de implementação
1. Separar criação da raiz nativa de compartilhamento opt-in para evitar vínculos acidentais.
2. Tratar profiles como trechos gerenciados com marcadores únicos, backup timestamp e política de conflito.
3. Testar path translation com espaços, UTF-8 e UNC; preferir comandos oficiais do VS Code remoto e IntelliJ/WSL quando disponíveis.
4. Introduzir testes de integração em VM para o bind/mount somente depois de detecção das três raízes.

## Artefatos existentes a avaliar
- `runbooks/05/runbook.ps1`
- `runbooks/06/runbook.ps1`
- `runbooks/06.1/runbook.ps1`
- `docs/05-workspaces.md`
- `docs/06-shells.md`
- `docs/06.1-ides.md`

## Contratos e estrutura a produzir
- Fluxo de entrada, estados, erro e pós-condições explícitos por runbook/adaptador.
- Testes unitários do contrato, testes de integração em VM e documentação com fontes Notion.
- Gate com evidência dos AC-006; sem alterações de IDs existentes e sem confundir feature flag com implementação.

## Validação recomendada
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- `wsl -d <DISTRO> -- bash -lc 'findmnt -T /workspace; command -v java'`
- `gcc -dumpmachine`
- Ensaiar dois Apply na VM quando houver ação mutável; comparar diffs.
- Testar confirmação negada, dependência indisponível, falha parcial e logs sem segredo.

## Rollback e implantação
Restaurar arquivos de profile/Terminal/fstab pelo backup; não remover pastas existentes nem desmontar volumes não gerenciados.

## Checklist de saída
Implementação limitada à fase, testes/CI green, pós-condições verificadas, evidências anexadas e PR revisada.
