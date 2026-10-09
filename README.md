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

## Princípios

1. PowerShell 5.1 ou 7 **elevado** como entrada inicial; PowerShell 7 é requisito do executor principal. O bootstrap pode instalar PowerShell 7 após confirmação; processos filhos não herdam automaticamente uma nova sessão.
2. **Bootstrap sem instalar dependências para si próprio:** apenas recursos já disponíveis no Windows e ferramentas nativas do SO. Baixar o pacote é distinto de executar suas tarefas.
3. **Estado observado acima do estado registrado:** nunca concluir que uma ferramenta existe apenas porque um manifesto diz que foi instalada.
4. Cada ação deve suportar detecção do estado atual, planejamento e aplicação condicional, com logs completos e redigidos contra segredos.
5. WSL/Ubuntu e MSYS2 são dependências bloqueantes: não executar toolchains nem personalização antes da validação da instalação do respectivo ambiente.
6. Versionamento selecionável para Java, Maven, Gradle, Python e outras ferramentas somente quando houver estratégia de instalação e verificação daquela versão.
7. `C:\workspace\local\{bin,env,config}` (Windows), `/workspace/local/{bin,env,config}` (Ubuntu ext4) e `/workspace/local/{bin,env,config}` (MSYS2 sob o diretório da instalação) são **independentes**.

## Início

O ponto de entrada planejado é `bootstrap.ps1`. **Não use `irm ... | iex` para baixar e executar código administrativo não revisado.** Prefira baixar o arquivo de uma release fixada, inspecionar sua assinatura/hash e depois executá-lo num PowerShell elevado.

## Protótipo disponível (somente diagnóstico)

- `bootstrap.ps1`: exige administrador Windows, reconhece PowerShell 5.1/7, oferece instalação de PowerShell 7 e inicia o protótipo de TUI.
- `src/ds1-setup.ps1`: lista tarefas, mostra bloqueios de dependências, permite `-Plan` e `-Validate`, registra transcrição da sessão e observações em `%ProgramData%\\DS1DevSetup`.
- `config/catalog.psd1`: grafo inicial de tarefas. **Nenhuma tarefa está marcada como Implemented** e `-Apply` é bloqueado até implementação e testes. A seleção de versão já faz parte do contrato, mas os instaladores versionados ainda não existem.

Para uso local, após revisar o conteúdo:

```powershell
# Abrir PowerShell como administrador
.\\bootstrap.ps1
```

O modo `irm ... | iex` é tecnicamente possível apontando para o bootstrap remoto, mas **não é a opção recomendada para executar código elevado de uma branch mutável**. Para produção, usar uma release com hash ou assinatura verificável.

## Limitações atuais

O protótipo ainda **não** realiza instalações de Java, Maven, Gradle, Python, Ubuntu, MSYS2 ou perfis, tampouco implementa execução nativa de todos os scripts ou logging multiplexado de subprocessos. O log atual é a transcrição PowerShell e não substitui captura auditável de stdout/stderr de futuros processos. As páginas migradas são documentação histórica revisada parcialmente; ainda precisam ser transformadas em procedimentos de instalação definitivos e testados.

Veja [arquitetura](docs/arquitetura-executor.md) para os estados, invariantes e limitações.
