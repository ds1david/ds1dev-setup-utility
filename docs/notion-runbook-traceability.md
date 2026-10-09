# Rastreabilidade Notion → runbooks → specs

> Fontes consultadas: 2026-10-09. As páginas são manuais/decisões, não scripts confiáveis para execução automática. O Git é a origem do código local revisado. Em caso de divergência, registrar uma decisão e preservar o contrato já publicado até migração.

## Convenção de IDs — atenção à divergência
O Notion usa **01 Windows**, **02 WSL2** e **03 MSYS2**. O repositório atual usa runbooks **02 Windows**, **03 WSL2** e **04 MSYS2**. Os IDs **são chaves públicas**; esta documentação preserva os IDs existentes. Não renumerar `runbook.psd1` sem migração e testes de compatibilidade.

| Tema | Página Notion (fonte) | Doc Git atual | Runbook Git | Spec |
|---|---|---|---|---|
| Índice geral | [Setup completo](https://app.notion.com/p/3f3bf4c17f6781c58c77d0a4123e44a3) | [01 índice](01-indice.md) | — | 001–009 |
| Arquitetura e dependências | [A arquitetura](https://app.notion.com/p/3f3bf4c17f678117b4b3ffe0ccd4b228) | [executor](arquitetura-executor.md) | prerequisites | 001/002 |
| Windows/WinGet/PowerShell | [01 Windows](https://app.notion.com/p/3f3bf4c17f67812e828ad07f279c20a7) | [02 Windows](02-windows.md) | 02 / 02.1 | 001/003 |
| WSL2/Ubuntu/SDKMAN | [02 WSL](https://app.notion.com/p/3f3bf4c17f67810a837fe1f0ea0c2e20) | [03 WSL](03-wsl.md) | 03 / 03.1 | 004 |
| MSYS2 UCRT64 | [03 MSYS2](https://app.notion.com/p/3f3bf4c17f678125addff0e3fa032ded) | [04 MSYS2](04-msys2.md) | 04 / 04.1 | 005 |
| Windows workspace | [B estrutura Windows](https://app.notion.com/p/3f3bf4c17f6781fbbaace656e14b83c3) | [05 workspaces](05-workspaces.md) | 05 | 006 |
| WSL ext4/workspace | [C Ubuntu workspace](https://app.notion.com/p/3f3bf4c17f6781b0accad94fd9735775) | [05 workspaces](05-workspaces.md) | 05 | 006 |
| MSYS workspace | [E MSYS UCRT64](https://app.notion.com/p/3f3bf4c17f6781ceb904c318f64a327b) | [05 workspaces](05-workspaces.md) | 05 | 006 |
| Shells e IDEs | [F IDEs](https://app.notion.com/p/3f3bf4c17f6781039b87f6371e7c94b3) | [06 shells](06-shells.md), [06.1 IDE](06.1-ides.md) | 06 / 06.1 | 006 |
| Docker Windows | [01.01 Docker Windows](https://app.notion.com/p/3f4bf4c17f678106bb4eeb06c1e1c3e5) | [arquitetura](arquitetura-executor.md) | futuro, ID a definir | 007 |
| Docker Ubuntu | [02.01 Docker Ubuntu](https://app.notion.com/p/3f4bf4c17f67818f9380e81f50664e0b) | [arquitetura](arquitetura-executor.md) | futuro, ID a definir | 007 |
| Backups | [08 backups](https://app.notion.com/p/3f3bf4c17f67819684addfb0d3e31e00) | [08 backups](08-backup.md) | futuro, ID a definir | 007 |
| Verificação | [09 verificação](https://app.notion.com/p/3f3bf4c17f6781f38e8fe4bef6440275) | [07 validação](07-validacao.md) | 07 | 007 |
| Runbook/TUI | [DS1 Setup Utility](https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc) | [runbooks](runbooks.md), [YAML v2](modelo-runbooks-v2.md), [TUI](tui-windows.md) | todos | 002/008/009 |

## Fonte e estado
- Para cada execução documentada, informar: `task_id`, plataforma, privilégio, pré-requisitos, `Test`, `Plan`, `Apply`, pós-condição, idempotência, rollback e evidências.
- `Implemented=false` indica que o `Apply` ainda está indisponível **mesmo que a página Notion contenha comandos manuais**.
- Evitar copiar comandos de versão desatualizada como automação sem fixar versão, hash e origem oficial.
- Referências explicativas curtas por tarefa: [runbooks documentados](notion-runbooks/README.md).
