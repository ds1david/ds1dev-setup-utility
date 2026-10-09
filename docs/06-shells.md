# 06 — Personalização de shells e completion

Os arquivos local/bin, local/env e local/config são **independentes** nos três ambientes: Windows em C:\workspace; Ubuntu no ext4 /workspace; MSYS2 em /workspace sob a instalação MSYS2.

## PowerShell 5.1 e 7
- Perfis CurrentUserAllHosts de cada edição são independentes, mas carregam C:\workspace\local\config\powershell\init.ps1.
- Módulos common/5.1/7 devem ser condicionais à edição e à versão de cada módulo.
- PATH inclui somente uma entrada para C:\workspace\local\bin.
- PSReadLine provê histórico e sugestões; Oh My Posh cuida do prompt; posh-git e argument completers são separados.

## Ubuntu Bash
- ~/.bashrc carrega /workspace/local/config/bash/init.bash apenas se existente.
- SDKMAN deve ser inicializado na sessão Bash e não por execução de Java Windows.
- bash-completion e complementos específicos de Maven, Gradle, Docker Compose e Git devem ser registrados de forma idempotente.

## MSYS2 UCRT64 Bash
- ~/.bashrc carrega /workspace/local/config/bash/init.bash MSYS2 próprio.
- MSYSTEM=UCRT64 e PATH compatível com /ucrt64 e /usr.
- /workspace/local/bin aponta ao workspace **MSYS2**, não /c/workspace.

## Regras
Nenhum profile deve baixar ou executar código remoto durante inicialização. Fazer backup antes de editar, preservar conteúdo já existente, evitar PATH duplicado e testar nova sessão. 