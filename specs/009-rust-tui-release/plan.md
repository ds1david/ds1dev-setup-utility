# Implementation Plan: 009 — TUI Rust/Ratatui e distribuição confiável

> Documento técnico inicial; executar `$speckit-plan` e atualizar decisões em branch própria antes da codificação.

## Resumo
UI navegável e pacote de release verificável com seleção consciente, plano e execução via motor estável.

## Contexto técnico
- Host: Windows 11; PowerShell 5.1 para bootstrap e PS7 como runtime principal.
- Preservar contratos atuais PSD1 v1 e runbooks existentes; YAML v2 e Rust não estão prontos na baseline.
- Executar testes sem instalar ou modificar computador do desenvolvedor.
- Dependências: 002, 008 aprovados; cobertura 003–007 representada sem prometer instalações ausentes.

## Constituição e avaliação de risco
Confirmar privilégio mínimo, confirmação, observabilidade, idempotência, fontes verificadas, independência de ambientes e rollback. Não tomar o código atual como automaticamente aderente: registrar dívida técnica e criar testes de regressão.

## Estratégia de implementação
1. Contratar interface estável entre Rust TUI e motor PowerShell para que saída estruturada e falhas não dependam de parsing de console.
2. Modelar estados da UI e fluxo de confirmação com testes de snapshot/unitário.
3. Revisar ergonomia de terminal (Unicode/resize/cancel) e fallback CLI sem runtime Rust em máquina do usuário.
4. Construir release reprodutível com hashes e testes E2E em VM descartável.

## Artefatos existentes a avaliar
- `src/Tui.psm1`
- `src/ds1-setup.ps1`
- `docs/tui-windows.md`
- `docs/guia-de-testes.md`
- `README.md`

## Contratos e estrutura a produzir
- Fluxo de entrada, estados, erro e pós-condições explícitos por runbook/adaptador.
- Testes unitários do contrato, testes de integração em VM e documentação com fontes Notion.
- Gate com evidência dos AC-009; sem alterações de IDs existentes e sem confundir feature flag com implementação.

## Validação recomendada
- `pwsh -NoProfile -File tests/runbooks.tests.ps1`
- `cargo test`
- `python tools/check_specs.py`
- Ensaiar dois Apply na VM quando houver ação mutável; comparar diffs.
- Testar confirmação negada, dependência indisponível, falha parcial e logs sem segredo.

## Rollback e implantação
Manter CLI/TUI PowerShell como fallback, nunca alterar manifests/runbooks por navegação da UI.

## Checklist de saída
Implementação limitada à fase, testes/CI green, pós-condições verificadas, evidências anexadas e PR revisada.
