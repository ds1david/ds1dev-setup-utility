# Spec Kit Status Report: instalacao Windows / Codex

> Este commit entrega o instalador do projeto, nao a execucao no computador do desenvolvedor. Os artefatos oficiais da extensao devem ser gerados por specify extension add.

## Identidade e origem
- Extensao comunitaria Status Report, ID status-report, versao 1.4.2 (release 2026-09-11).
- Repositorio https://github.com/Open-Agent-Tools/spec-kit-status
- Arquivo https://github.com/Open-Agent-Tools/spec-kit-status/archive/refs/tags/v1.4.2.zip
- Extensao requer Spec Kit >= 1.0.0.
- O manifesto upstream declara effect read-write. O comando cria/atualiza specs/spec-status.md a cada execucao; este snapshot e ignorado pelo Git.
- Integracao oficial para Codex: skill $speckit-status-report-show (depois de instalar e reiniciar o Codex).

## 1. Verificar instalacao oficial do Spec Kit
Executar no PowerShell 7 sem elevacao, na raiz do projeto:

    cd C:\workspace\projects\ds1dev-setup-utility
    git status --short
    specify version
    Test-Path .specify\scripts
    Test-Path .specify\templates

O repositório remoto inclui constituição e nove specs, mas o checkout pode ainda nao conter a inicializacao oficial. Se os dois diretórios faltarem, preservar e commitar todo trabalho, criar branch separada e executar:

    git switch -c chore/spec-kit-official-init
    specify init --here --force --non-interactive --integration codex --script ps
    git status --short
    git diff -- .specify .agents AGENTS.md

O parametro --force pode sobrescrever arquivos. Revisar diffs, preservar AGENTS.md e constituicao, commitar a inicializacao antes do passo seguinte. Se o Spec Kit ja foi inicializado localmente, NAO executar init novamente.

## 2. Instalar Status Report (apenas com checkout limpo)

    pwsh -NoProfile -File ./tools/install-speckit-status-report.ps1 -Mode Test
    pwsh -NoProfile -File ./tools/install-speckit-status-report.ps1 -Mode Plan
    pwsh -NoProfile -File ./tools/install-speckit-status-report.ps1 -Mode Apply

O Apply solicita confirmacao PowerShell e a CLI pode solicitar segunda confirmacao devido a origem comunitaria. Nao elevar, nao contornar confirmacoes e nao executar scripts remotos diretamente. O instalador utiliza comando oficial e exige checkout Git limpo.

Equivalente manual:

    specify extension add status-report --from https://github.com/Open-Agent-Tools/spec-kit-status/archive/refs/tags/v1.4.2.zip

## 3. Validar e versionar arquivos gerados

    specify extension list
    specify extension info status-report
    git status --short
    git diff -- .specify .agents

O Spec Kit gerara .specify/extensions/status-report, registro em .specify/extensions.yml e comando/skill Codex na integracao ativa. Revisar esse conjunto antes de fazer commit. Nao commitar specs/spec-status.md nem *-config.local.yml.

Reiniciar Codex e invocar:

    $speckit-status-report-show
    $speckit-status-report-show --all
    $speckit-status-report-show --feature 001
    $speckit-status-report-show --verbose

Para executar o coletor PowerShell diretamente, depois de validar caminho da instalacao:

    pwsh -NoProfile -File ./.specify/extensions/status-report/scripts/powershell/Get-ProjectStatus.ps1 -Json

O comando gera snapshot. O indicador de artefatos e tarefas NAO comprova implementacao das fases 001-009 do DS1.

## 4. Regressao

    python tools/check_specs.py
    pwsh -NoProfile -File tests/runbooks.tests.ps1
    pwsh -NoProfile -File tests/bootstrap.tests.ps1

Respeitar os gates em docs/phase-gates.md. A extensao nao pode habilitar nenhum runbook com Implemented=false.

## Referencias
- https://github.github.com/spec-kit/reference/extensions.html
- https://github.com/Open-Agent-Tools/spec-kit-status
- [Codex e Spec Kit](codex-speckit.md)
