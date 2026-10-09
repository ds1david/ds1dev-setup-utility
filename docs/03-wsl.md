# 03 — Preparação WSL2 e Ubuntu

> Documento migrado do Notion e reorganizado. **Revise caminhos, versões e efeitos antes de aplicar.** A instalação deve ser testada em máquina de laboratório e reexecutada para validar idempotência.


## 1. Pré-requisitos e diagnóstico
Windows 11 e [preparação básica Windows (02)](02-windows.md) concluídos. MSYS2 não é dependência do Ubuntu.
No PowerShell 7 (eleve apenas se o WSL solicitar):
```powershell
wsl --version
wsl --status
wsl --list --online
```
Verifique recursos de virtualização e Windows Update antes de resolver falhas.
## 2. Instalação do ambiente WSL2/Ubuntu
Escolha uma distribuição exibida na lista (exemplo Ubuntu-24.04):
```powershell
wsl --install -d Ubuntu-24.04
wsl -l -v
```
Reinicie quando solicitado, abra o Ubuntu, defina usuário e senha Linux. A distribuição precisa utilizar WSL versão 2. Se a distro recém-instalada aparecer em versão 1, verifique os requisitos e então execute `wsl --set-version Ubuntu-24.04 2`. Para versões/nome diferentes substitua pelo nome listado em `wsl -l -v`.
## 3. Atualizações do WSL e Ubuntu
No PowerShell 7:
```powershell
wsl --update
wsl --status
```
Dentro do Ubuntu:
```bash
sudo apt update
sudo apt full-upgrade -y
```
Não execute `wsl --shutdown` enquanto estiver usando uma sessão Linux ou com serviços críticos em execução. Feche as sessões e reinicie quando necessário.
## 5. Integração com Windows Terminal
**Configuração nativa do Bash:** após criar a estrutura no (consulte índice deste repositório), o `~/.bashrc` carregará `/workspace/local/config/bash/init.bash` e incluirá `/workspace/local/bin` no PATH idempotentemente. Esses arquivos ficam em ext4, não em `C:\workspace`.
Instalações atuais do WSL geralmente geram um perfil Ubuntu automaticamente no Windows Terminal. Abra uma nova aba Ubuntu e confira `pwd`, `whoami` e `uname -a`. Caso não apareça, em Configurações → Adicionar um novo perfil → Novo perfil vazio, crie perfil **Ubuntu (WSL2)** com linha de comando `wsl.exe -d Ubuntu-24.04` (ajuste para o nome listado) e diretório inicial padrão do usuário Linux. Preserve PowerShell 7 como perfil padrão.
VS Code e IntelliJ continuarão instalados no Windows; configuração de `code .` e `idea .` no (consulte índice deste repositório).
## 6. Validação do ambiente

No PowerShell, use o nome real da distribuição:

```powershell
wsl.exe --list --verbose
# Substitua pelo nome da distribuição escolhida antes de executar.
wsl.exe -d Ubuntu-24.04 -- bash -lc 'id; uname -r'
```

Exigir WSL versão 2 e usuário Linux inicializado. A presença de wsl.exe não basta. Git, Python, SDKMAN e builds são validados em [03.1](03.1-toolchain-ubuntu.md), após o workspace nativo estar pronto.

## Próximos passos e aceite

- [ ] WSL2 instalado e distribuição selecionada inicializada
- [ ] Usuário Linux correto e distribuição inicia sem erro
- [ ] Atualizações autorizadas e reinício tratados
- [ ] Perfil Ubuntu do Terminal validado

Seguir [05 — Workspace Ubuntu](05-workspaces.md), depois [03.1 — Toolchain](03.1-toolchain-ubuntu.md). MSYS2 não é requisito dessas tarefas. Integração Docker depende do Docker Desktop do host, conforme abaixo.

## Docker Ubuntu


## Objetivo e dependências
Configurar **acesso ao Docker Desktop do Windows dentro do Ubuntu WSL2**, sem instalar outro Docker Engine. Primeiro concluir 01 (Windows), 02 (WSL), e (consulte índice deste repositório). A engine Linux do Docker Desktop é a preferencial; Windows containers são um modo alternativo exclusivo.
## 1. Habilitar integração WSL2
No Windows, abra Docker Desktop → Settings → General → habilite **Use the WSL 2 based engine** (quando disponível). Em Settings → Resources → **WSL Integration**, habilite a sua distribuição Ubuntu. Salve e aguarde reiniciar o Docker Desktop. Confira o nome real da distribuição via `wsl -l -v`; não dependa de um nome de versão fixo.
## 2. Diagnóstico no Ubuntu
```bash
command -v docker
docker version
docker context ls
docker info --format '{{.OSType}}'
docker compose version
```
Espere `linux` em `docker info --format '{{.OSType}}'`. Caso não funcione, confirme Docker Desktop iniciado no host, modo Linux, integração habilitada para esta distro e shell reiniciado. Não instale `docker.io` ou `docker-ce` no Ubuntu como tentativa de correção: criaria uma segunda engine.
## 3. Wrapper com política de engine
Os wrappers Linux devem residir em `/workspace/local/bin` (**ext4 nativo**). Esse diretório deve existir após o guia C e estar no PATH apenas uma vez. Arquivo `/workspace/local/bin/ds1-docker`:
```bash
#!/usr/bin/env bash
set -euo pipefail
actual="$(command docker info --format '{{.OSType}}')"
if [[ "$actual" != linux ]]; then
  printf 'Docker bloqueado: engine=%s; esperado=linux\n' "$actual" >&2
  exit 2
fi
exec docker "$@"
```
Dê `chmod 750 /workspace/local/bin/ds1-docker` e teste com `ds1-docker compose version`. Trata-se de uma política do wrapper e **não** de restrição a chamadas diretas ao Docker.
## 4. Diretórios e volumes
- Dockerfiles e arquivos Compose Linux: `/workspace/projects/infra/containers` no ext4;
- Dados locais passíveis de bind mounts: `/workspace/local/docker/data`, organizados por serviço; não confundir com os volumes nomeados geridos pela engine;
- Configurações de shell Docker: `/workspace/local/config`, sem substituir o diretório `dev/config` usado por projetos;
- Logs e staging conforme guia C. Não sincronize bancos ou volumes Docker ativos com Google Drive.
## 5. Validação e operação segura
```bash
docker info --format '{{.OSType}}'
docker compose version
docker ps
```
Antes de trocar Docker Desktop para Windows containers, encerre workloads Linux, garanta backup consistente e revalide a engine na volta. Se estiver no modo Windows, a integração WSL pode não estar disponível.
## Checklist
- [ ] Docker Desktop instalado e executando no host Windows
- [ ] Engine Linux ativa
- [ ] Integração Ubuntu WSL2 habilitada
- [ ] Docker e Compose funcionam no Ubuntu
- [ ] Wrapper aponta para /workspace/local/bin e bloqueia engine não-Linux
- [ ] Dados e volumes não sincronizados como arquivos ativos
---
