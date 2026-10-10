# Runbooks documentados a partir do Notion

> Este diretório materializa a correspondência entre a wiki Notion, o catálogo do GitHub e as specs. **Não executa scripts**. A consulta à wiki é referência documental, não evidência de implementação.

| Documento | Ambiente | Estado de código | Spec |
|---|---|---|---|
| [prerequisites — Pré-requisitos Windows](prerequisites.md) | Windows | Parcial: manifesto Implemented=true | 001/002 |
| [02 — Preparação Windows / ferramentas básicas](02.md) | Windows | Planejado | 003 |
| [02.1 — Toolchain Windows Java/Maven/Gradle](02.1.md) | Windows | Planejado | 003 |
| [03 — WSL2 e Ubuntu](03.md) | Ubuntu | Planejado | 004 |
| [03.1 — Toolchain Ubuntu com SDKMAN](03.1.md) | Ubuntu | Planejado | 004 |
| [04 — MSYS2 UCRT64 inicial](04.md) | MSYS2 | Planejado | 005 |
| [04.1 — MSYS2 GCC/CMake/Ninja](04.1.md) | MSYS2 | Planejado | 005 |
| [05 — Workspaces e PATH sem mistura](05.md) | Integrated | Planejado | 006 |
| [06 — Perfis shells e completions](06.md) | Integrated | Planejado | 006 |
| [06.1 — VS Code e IntelliJ no Windows](06.1.md) | Integrated | Planejado | 006 |
| [07 — Validação integrada final](07.md) | Integrated | Planejado | 007 |
| [docker-win — Docker Desktop no Windows (futuro)](docker-win.md) | Windows | Planejado | 007 |
| [docker-wsl — Docker Ubuntu WSL integration (futuro)](docker-wsl.md) | Ubuntu | Planejado | 007 |
| [backup — Backup/restauração (futuro)](backup.md) | Integrated | Planejado | 007 |

## Leitura e operação
1. Abrir o documento do runbook e a página Notion fonte.
2. Confirmar `Implemented` real lendo o manifesto na branch em uso; o estado acima é fotografia de 2026-10-09.
3. Usar os comandos da seção diagnóstico somente no shell correto e sem dados sensíveis.
4. Para executar, usar o motor e o script **local revisado**. Não baixar nem executar scripts da wiki, e não considerar `-Plan` não elevado disponível enquanto fase 002 estiver pendente.
5. Registrar diferenças importantes de ordem: o Notion Windows/WSL/MSYS2 usa 01/02/03; runbooks Git usam 02/03/04. Os toolchains 02.1/03.1/04.1 atualmente dependem de 05 apesar de a wiki instalar toolchains antes de workspaces. Isto é dívida técnica a resolver via specs, não licença para editar IDs silenciosamente.
6. Para fontes adicionais (toolchain avançada, caches, backup e validação), consultar [matriz principal](../notion-runbook-traceability.md).

## Evidência de aceite
Relatórios do PR devem conter comandos, ambiente, testes, logs redigidos, estado inicial/final, resultado de segunda aplicação, rollback e limitações. Só depois se marca `Implemented=true`.
