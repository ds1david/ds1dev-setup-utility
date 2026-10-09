# DS1 Dev Setup Utility

Instalador e manual de preparação para Windows 11, Ubuntu WSL2 e MSYS2 UCRT64.

> **Estado:** documentação migrada e runtime inicial em desenvolvimento. Não executar comandos de instalação sem revisar o plano. Nenhuma instalação é presumida como concluída a partir do histórico de execução.

## Guia de documentação

- [01 — Índice e arquitetura](docs/01-indice.md)
- [02 — Preparação Windows](docs/02-windows.md) · [02.1 — Toolchain Windows](docs/02.1-toolchain-windows.md)
- [03 — Preparação WSL2](docs/03-wsl.md) · [03.1 — Toolchain Ubuntu](docs/03.1-toolchain-ubuntu.md)
- [04 — Preparação MSYS2](docs/04-msys2.md) · [04.1 — Toolchain MSYS2](docs/04.1-toolchain-msys2.md)
- [05 — Pastas, mounts, links e PATH](docs/05-workspaces.md)
- [06 — Shells e completions](docs/06-shells.md) · [06.1 — IDEs](docs/06.1-ides.md)
- [07 — Verificação integrada](docs/07-validacao.md)
- [08 — Backup e recuperação](docs/08-backup.md)
- [Arquitetura do executor, segurança e idempotência](docs/arquitetura-executor.md)
- [Adicionar runbooks sem alterar a TUI](docs/runbooks.md)
- [Proposta de contrato YAML v2 para tarefas e interpretadores](docs/modelo-runbooks-v2.md)
- [Plano detalhado de execução e critérios de aceite](docs/plano-de-execucao.md)

## Princípios

1. Entrada Windows PowerShell 5.1 ou PowerShell 7, inclusive em Windows limpo sem WinGet. O bootstrap verifica UAC/elevação, pede autorização para elevar e reutiliza PowerShell 7 estável compatível (mínimo 7.4) ou oferece instalar o MSI oficial fixado. O executor inicia somente elevado.
2. **Bootstrap sem instalar dependências para si próprio:** apenas recursos já disponíveis no Windows e ferramentas nativas do SO. Baixar o pacote é distinto de executar suas tarefas.
3. **Estado observado acima do estado registrado:** nunca concluir que uma ferramenta existe apenas porque um manifesto diz que foi instalada.
4. Cada ação deve suportar detecção do estado atual, planejamento e aplicação condicional, com logs completos e redigidos contra segredos.
5. O gate inicial exige os recursos Windows necessários ao WSL2 antes de liberar qualquer outro runbook. Ubuntu e MSYS2 continuam dependências específicas das tarefas dos seus ambientes.
6. Versionamento selecionável para Java, Maven, Gradle, Python e outras ferramentas somente quando houver estratégia de instalação e verificação daquela versão.
7. `C:\workspace\local\{bin,env,config}` (Windows), `/workspace/local/{bin,env,config}` (Ubuntu ext4) e `/workspace/local/{bin,env,config}` (MSYS2 sob o diretório da instalação) são **independentes**.

## Início

O ponto de entrada é `bootstrap.ps1`. Funciona por arquivo e foi preparado para `irm | iex`; a homologação ponta a ponta em Windows limpo continua pendente.

- UAC é um componente do Windows, não um pacote a instalar. Sem elevação, o bootstrap pede autorização e solicita UAC; se recusado, não instala.
- PowerShell 7 existente e compatível é reutilizado. Ausente, solicita consentimento para baixar o MSI oficial **7.6.6**, confere SHA-256 e assinatura Microsoft e instala sem depender do WinGet.
- Windows PowerShell 5.1 permanece instalado. Reinício solicitado pelo MSI interrompe o fluxo antes da TUI.
- Se a elevação usar outra conta Windows, o bootstrap bloqueia para evitar configurar profiles/WSL do usuário errado.
- A UI atual continua em PowerShell. A versão Rust está no [plano](docs/plano-de-execucao.md).

Execução remota solicitada (branch de desenvolvimento, ainda não uma release homologada):

```powershell
irm https://raw.githubusercontent.com/ds1david/ds1dev-setup-utility/main/bootstrap.ps1 | iex
```

O primeiro script é executado da origem informada; durante o handoff remoto, o snapshot é fixado por commit. Isso **não equivale a uma release assinada**. Para execução reprodutível, use URL de commit revisado ou arquivo local revisado. A distribuição assinada/verificada do DS1 permanece no marco M11.

## Executor e runbooks dinâmicos

- `bootstrap.ps1`: verifica UAC/administrador, solicita elevação e instalação de PS7 quando necessárias, verifica MSI oficial e inicia o protótipo de TUI.
- `src/ds1-setup.ps1`: lista tarefas, mostra bloqueios de dependências, permite `-Plan` e `-Validate`, registra transcrição da sessão e observações em `%ProgramData%\\DS1DevSetup`.
- `src/Runbooks.psm1`: descobre manifestos, valida dependências e executa handlers Test/Plan/Apply.
- `runbooks/**/runbook.psd1`: catálogo descoberto por pasta. Adicionar manifesto e script é suficiente; pressione R para recarregar a cópia local. O antigo `config/catalog.psd1` não é consumido.
- O runbook `prerequisites` verifica Windows/elevação/PowerShell/virtualização/recursos WSL2 automaticamente e bloqueia os demais até estar conforme. As dez tarefas históricas permanecem com `Implemented=$false`. Novos runbooks com Apply implementado podem ser executados; a verificação posterior é obrigatória. Os instaladores versionados históricos ainda não existem.
- `tests/runbooks.tests.ps1`: testes sem módulos externos para descoberta, execução e validação do contrato.
- `src/TaskPhases.psm1`: estados de checagem por tarefa, registro JSONL de fases/comandos e exportação dos logs. Na TUI, **L** mostra os eventos da tarefa; ao sair de uma sessão interativa, é possível escolher onde salvar uma cópia da transcrição e do JSONL. Os originais ficam em `%ProgramData%\DS1DevSetup\logs`.

Para uso local, após revisar o conteúdo:

```powershell
# O bootstrap oferece elevação se necessário
.\\bootstrap.ps1
```

O modo `irm ... | iex` é tecnicamente possível apontando para o bootstrap remoto, mas **não é a opção recomendada para executar código elevado de uma branch mutável**. Para produção, usar uma release com hash ou assinatura verificável.

## Limitações atuais

A TUI PowerShell 7 é navegável por categorias e busca, mostra bloqueios e permite Test/Plan/Apply de runbooks implementados, com seleção de versão quando suportada. O protótipo ainda **não** realiza instalações de Java, Maven, Gradle, Python, Ubuntu, MSYS2 ou perfis, tampouco implementa execução nativa de todos os scripts ou captura integral de stdout/stderr de subprocessos. Os registros detalhados de comando/resultados dependem da instrumentação de cada runbook; por enquanto, a correção dos recursos opcionais Windows está instrumentada. As páginas migradas são documentação histórica revisada parcialmente; ainda precisam ser transformadas em procedimentos de instalação definitivos e testados.

Veja [arquitetura](docs/arquitetura-executor.md) para os estados, invariantes e limitações.


- [Especificação visual: bootstrap Windows e TUI inspirada no Linutil](docs/tui-windows.md)
