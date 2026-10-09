# 05 — Workspaces, compartilhamentos e PATH

## Windows

## Ordem de execução corrigida — Guia B
**Pré-requisitos de criação:** antes de executar qualquer bloco de criação de `C:\workspace`, conclua a Etapa 02 (WSL2/Ubuntu iniciado e testado) e a Etapa 03 (MSYS2 UCRT64 atualizado, `MSYSTEM=UCRT64`, perfil criado no Terminal). Essa dependência evita links/mounts para ambientes ausentes.
## IDEs instaladas apenas no Windows
Instale VS Code e IntelliJ IDEA no host Windows pelo procedimento (consulte índice). Ubuntu e MSYS2 recebem apenas launchers e componentes de integração, sem pacotes gráficos completos.

## Pré-requisitos
Windows 11, PowerShell 7 e WinGet da etapa 01. Execute no PowerShell 7 com usuário habitual. Root C:workspace precisa permitir gravação ao usuário; privilégios elevados apenas para alterações protegidas.
## 1. Preparar raiz e diretórios
```powershell
$root='C:\workspace'
$dirs=@('projects\windows','projects\posix','dev\cache\windows','dev\cache\msys2-ucrt64','dev\build\windows','dev\build\msys2-ucrt64','dev\config','dev\tools','shared\documents','shared\downloads','shared\pictures','shared\music','shared\videos','local\env','local\bin','local\config','local\config\powershell','local\config\powershell\common','local\config\powershell\5.1','local\config\powershell\7','local\config\completion','local\config\prompt','local\docker')
$dirs | ForEach-Object { New-Item -ItemType Directory -Path (Join-Path $root $_) -Force | Out-Null }
$dirs | ForEach-Object { Test-Path -LiteralPath (Join-Path $root $_) }
```
## 2. Fazer inventário e backup antes de redirecionar pastas conhecidas
```powershell
$known=[ordered]@{documents=[Environment]::GetFolderPath('MyDocuments');pictures=[Environment]::GetFolderPath('MyPictures');music=[Environment]::GetFolderPath('MyMusic');videos=[Environment]::GetFolderPath('MyVideos')}
$key='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$known.downloads=[Environment]::ExpandEnvironmentVariables((Get-ItemProperty $key).'{374DE290-123F-4565-9164-39C4925E467B}')
$known.GetEnumerator() | Format-Table Name,Value
```
Primeiro garanta backup verificável e estado de OneDrive Known Folder Move/políticas corporativas. Para cada pasta conhecida, use Explorer → pasta conhecida → Propriedades → Local → Mover quando disponível, apontando ao respectivo `C:\workspace\shared\<nome>`. Confirme migração dos arquivos, acesso e estado no registro. A interface pode não oferecer Local/Mover para todas; nesses casos **não** altere registro por script genérico nem faça cópia arriscada sem método específico validado. Não use junction como substituto do redirecionamento oficial.
## 3. Perfil Windows
```powershell
$dest='C:\workspace\projects'
$link=Join-Path $HOME 'projects'
if(Test-Path -LiteralPath $link){ Write-Warning "O caminho já existe; verificar antes de criar junction" }
else { New-Item -ItemType Junction -Path $link -Target $dest }
```
## 4. Variáveis locais e configuração dos shells Windows
```powershell
$envroot='C:\workspace\local\env'
@('runtime.env.windows','env.gdrive.windows','env.docker.windows') | ForEach-Object { $p=Join-Path $envroot $_; if(-not(Test-Path $p)){ New-Item -ItemType File $p | Out-Null } }
```
Cada ambiente possui `local/env` próprio: **não** vincule esta pasta ao Ubuntu nem ao MSYS2. Arquivos portáveis opcionais podem ser copiados explicitamente com validação, nunca compartilhados como diretório inteiro. Use UTF-8 e um parser restrito KEY=VALUE; segredos devem ser criptografados fora de sincronizações não protegidas.
## 5. PATH do Windows e inicialização dos PowerShell 5.1/7
```powershell
$bin='C:\workspace\local\bin'
$existing=[Environment]::GetEnvironmentVariable('Path','User')
$parts=@($existing -split ';' | Where-Object { $_ })
if(-not @($parts | Where-Object { $_.TrimEnd('\') -ieq $bin }).Count){
  [Environment]::SetEnvironmentVariable('Path', (($parts+$bin) -join ';'), 'User')
}
if(-not @($env:Path -split ';' | Where-Object { $_.TrimEnd('\') -ieq $bin }).Count){
  $env:Path="$bin;$env:Path"
}
```
Os perfis `CurrentUserAllHosts` de **cada edição** PowerShell carregam somente `C:\workspace\local\config\powershell\init.ps1`; esse inicializador separa módulos `common`, `5.1` e `7` pelo `$PSVersionTable.PSVersion.Major`. Faça backup de `$PROFILE` e modifique uma vez; evite sobrescrever perfis corporativos.
## 6. Bootstrap idempotente dos perfis PowerShell 5.1 e 7
Execute este bloco **uma vez em cada edição**: primeiro no Windows PowerShell 5.1 (`powershell.exe`), depois no PowerShell 7 (`pwsh.exe`). O `$PROFILE.CurrentUserAllHosts` é diferente por edição, mas os dois carregam a **mesma configuração Windows** em `C:\workspace\local\config\powershell\init.ps1`.
```powershell
$Init = 'C:\workspace\local\config\powershell\init.ps1'
$ProfilePath = $PROFILE.CurrentUserAllHosts
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ProfilePath) | Out-Null
if (-not (Test-Path -LiteralPath $Init)) {
    New-Item -ItemType File -Force -Path $Init | Out-Null
}
if (-not (Test-Path -LiteralPath $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
}
$LoadLine = ". '$Init'"
$Lines = @(Get-Content -LiteralPath $ProfilePath -ErrorAction SilentlyContinue)
if ($Lines -notcontains $LoadLine) {
    Add-Content -LiteralPath $ProfilePath -Value $LoadLine
}
```
O `init.ps1` pode selecionar módulos por `$PSVersionTable.PSVersion.Major`: `common` para compatibilidade, `5.1` para Windows PowerShell e `7` para PowerShell 7. Mantenha PSReadLine, Oh My Posh e completação contextual opcionais e condicione o carregamento à disponibilidade de cada módulo. Antes de executar código de terceiros no perfil, valide sua origem e compatibilidade.
## Aceite
- [ ] Diretórios presentes
- [ ] Pastas conhecidas redirecionadas e dados verificados
- [ ] local/bin, local/env e local/config Windows criados
- [ ] PATH Windows aponta uma única vez para local/bin
- [ ] Segredos protegidos, sem montar local/env em outros ambientes
- [ ] Nenhum arquivo do Home sobrescrito
---

## Ubuntu WSL2


## Dependências
Etapas 01–03 concluídas: Windows pronto, distribuição WSL2 instalada/inicializada, MSYS2 UCRT64 instalado e atualizado com perfil Windows Terminal. Guia B concluído criando a estrutura comum `C:\workspace`. **Só então executar comandos de criação, mounts e links em ****`/workspace`****.** Docker Desktop será instalado conforme (consulte índice) e integrado via (consulte índice). Cada distribuição possui seu próprio ext4.
## 1. Ubuntu já preparado
A instalação, atualização e as toolchains Git, Python, Java 21, Maven e Gradle via SDKMAN foram concluídas na (consulte índice). Não reinstalar neste guia.
## 2. Diretórios nativos
```bash
sudo mkdir -p /workspace/projects/linux /workspace/dev/{cache,build,config,tools} /workspace/local/{bin,env,config,docker/config,docker/data,docker/logs,docker/staging} /workspace/shared/{documents,downloads,pictures,music,videos} /workspace/windows/projects
sudo chown -R "$USER:$(id -gn)" /workspace/projects /workspace/dev /workspace/local/bin /workspace/local/env /workspace/local/config /workspace/local/docker
```
NÃO faça chown recursivo em `/mnt/c` nem em `/workspace/shared` (pontos de montagem NTFS). Já `/workspace/local/env` é ext4 nativo e pode pertencer ao usuário Ubuntu.
## 3. Mounts persistentes
```bash
findmnt -M /mnt/c
sudo cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
sudo nano /etc/fstab
```
Adicione uma vez:
```plain text
/mnt/c/workspace/shared/documents /workspace/shared/documents none bind 0 0
/mnt/c/workspace/shared/downloads /workspace/shared/downloads none bind 0 0
/mnt/c/workspace/shared/pictures /workspace/shared/pictures none bind 0 0
/mnt/c/workspace/shared/music /workspace/shared/music none bind 0 0
/mnt/c/workspace/shared/videos /workspace/shared/videos none bind 0 0
/mnt/c/workspace/projects /workspace/windows/projects none bind 0 0
```
**Não monte a pasta ****`C:\workspace\local\env`**** em ****`/workspace/local/env`****: env e config são nativos e independentes no Ubuntu.** Em `/etc/wsl.conf`, preservar demais seções e garantir `[automount] enabled=true, root=/mnt/, mountFsTab=true` em linhas separadas. Ative com `sudo mount -a`; valide `findmnt -M /workspace/shared/documents` e `findmnt -M /workspace/windows/projects`. Reinicie com `wsl --terminate <distro>` no PowerShell e valide novamente.
## 4. Links Home (somente se não existirem)
```bash
for name in projects dev shared; do
  target="/workspace/$name"
  [ -e "$HOME/$name" ] || [ -L "$HOME/$name" ] || ln -s "$target" "$HOME/$name"
done
for name in documents downloads pictures music videos; do
  [ -e "$HOME/$name" ] || [ -L "$HOME/$name" ] || ln -s "/workspace/shared/$name" "$HOME/$name"
done
```
Se já existir arquivo/diretório no Home, não substitua automaticamente; migre de modo controlado.
## 5. PATH, configurações e Docker
Adicione ao `~/.bashrc` uma única vez:
```bash
case ":$PATH:" in
  *:/workspace/local/bin:*) ;;
  *) export PATH="/workspace/local/bin:$PATH" ;;
esac
if [[ -r /workspace/local/config/bash/init.bash ]]; then
  source /workspace/local/config/bash/init.bash
fi
```
`/workspace/local/{bin,env,config}` permanece inteiramente no ext4. Configure SDKMAN e completions no inicializador local do Bash, sem usar links para configurações Windows. Para acesso Docker use (consulte índice); não instale segunda engine.
## Aceite
- [ ] /workspace é ext4
- [ ] Mounts de pastas pessoais ativos após reinício
- [ ] local/bin, local/env e local/config são ext4 e não bind mounts
- [ ] /workspace/local/bin no PATH sem duplicação
- [ ] Scripts do Home apontam à origem esperada
- [ ] Integração Docker verificada no guia 02.01
---

## MSYS2 UCRT64


## Dependências e finalidade
Conclua Etapas 01, 02, 03 e guia B antes de criar os caminhos. A instalação do MSYS2, pacman, GCC e Autotools pertence **somente à Etapa 03**; aqui configuramos o filesystem, os perfis e o PATH. MSYS2 é um runtime POSIX sobre NTFS, não um ext4 próprio.
## 1. Raiz MSYS2 /workspace sem compartilhar C:workspace
No MSYS2 UCRT64, adote `/workspace` como diretório **dentro da instalação MSYS2**, normalmente `C:\msys64\workspace` no Windows. Não utilize `/c/workspace` como origem do workspace nativo MSYS2.
```bash
echo "$MSYSTEM"  # UCRT64
mkdir -p /workspace/projects/posix \
  /workspace/dev/{cache,build,config,tools} \
  /workspace/local/{bin,env,config}
realpath /workspace
realpath /c/workspace
```
**Condição:** `realpath /workspace` deve resolver à pasta própria da instalação MSYS2, enquanto `/c/workspace` continua sendo a estrutura Windows, distinta. Não crie link simbólico `/workspace -> /c/workspace`. Se a instalação não mapear `/workspace` para seu diretório nativo, crie a pasta `workspace` na raiz da instalação MSYS2 (ex.: `C:\msys64\workspace`) e confirme `realpath`.
## 2. PATH persistente e idempotente
No `~/.bashrc` do MSYS2 adicione **uma vez**:
```bash
case ":$PATH:" in
  *:/workspace/local/bin:*) ;;
  *) export PATH="/workspace/local/bin:$PATH" ;;
esac
```
Teste:
```bash
source ~/.bashrc
printf '%s\n' "$PATH" | tr ':' '\n' | grep -Fx /workspace/local/bin
command -v gcc
```
Não transfira scripts para `/opt/local/bin`. Pacotes do pacman permanecem em `/usr` e `/ucrt64`.
## 3. Personalização do shell
```bash
mkdir -p /workspace/local/config/{bash,completion,prompt}
```
Inclua no `~/.bashrc` do MSYS2 **uma única vez**:
```bash
if [[ -r /workspace/local/config/bash/init.bash ]]; then
  source /workspace/local/config/bash/init.bash
fi
```
O arquivo `init.bash` deve carregar aliases, funções, completion de Git/Maven/Gradle/Docker e prompt, somente quando o utilitário correspondente estiver disponível, sem executar downloads ou builds na inicialização. Use a configuração MSYS2 própria, não a configuração Ubuntu/Windows.
## 4. Compartilhamentos explícitos com Windows
Quando necessário, acesso direto a `/c/workspace/shared` (pastas pessoais) e `/c/workspace/projects` (projetos Windows). Não vincule `/workspace/local/{bin,env,config}` a `/c/workspace/local`. Dados de cada shell permanecem nativos e independentes.
## 5. Docker via host Windows
Se instalado no host, `docker.exe` pode ser chamado pelo MSYS2. Verifique `docker.exe info --format '{{.OSType}}'` e a política de engine do (consulte índice). Não instale uma engine Docker adicional por pacman.
## Aceite
- [ ] /workspace MSYS2 é separado de /c/workspace Windows
- [ ] /workspace/local/\{bin,env,config\} existe
- [ ] PATH inclui /workspace/local/bin uma única vez
- [ ] Bash configura-se com init.bash MSYS2 próprio
- [ ] GCC UCRT64 e acesso opcional a arquivos Windows funcionam
---

