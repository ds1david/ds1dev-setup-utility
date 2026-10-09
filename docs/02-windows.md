# 02 — Preparação Windows

> Documento migrado do Notion e reorganizado. **Revise caminhos, versões e efeitos antes de aplicar.** A instalação deve ser testada em máquina de laboratório e reexecutada para validar idempotência.


## 1. Pré-requisitos e diagnóstico
**Ponto de partida:** Windows 11 já instalado, conta com permissões necessárias, conexão à internet e WinGet (App Installer). **Não crie ainda** links/mounts de WSL/MSYS2 ou a estrutura definitiva; isso ocorrerá depois de instalar os três ambientes.
```powershell
winver
winget --version
Get-ComputerInfo | Select-Object WindowsProductName,OsBuildNumber,HyperVisorPresent
```
Se WinGet não existir, atualizar o App Installer por fonte oficial Microsoft. O Windows 11 permanece o host das IDEs gráficas e do Docker Desktop.
## 2. Instalação do ambiente e utilitários essenciais
Abra **PowerShell**, com elevação somente quando o instalador solicitar:
```powershell
winget search --id Microsoft.PowerShell -e
winget search --id Microsoft.WindowsTerminal -e
winget source update
winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements
```
PowerShell 7 usa `pwsh.exe` e não substitui o Windows PowerShell 5.1. Abra uma sessão PowerShell 7 depois da instalação.
## 3. Atualizações, reinicialização e PATH
```powershell
winget source update
winget upgrade
winget --version
pwsh --version
```
`winget upgrade` apenas mostra atualizações; revise cada pacote antes de instalar. Execute Windows Update pelo painel Configurações e reinicie quando solicitado. Reabra Windows Terminal após instalações que alterem o PATH. Se o ícone do Terminal ficar genérico, tente Reparar nas opções avançadas do aplicativo; não use Redefinir sem backup.
## 4. Instalação de dependências e ferramentas Windows
## 5. Integração com Windows Terminal
**Perfis PowerShell 5.1 e PowerShell 7:** ambos serão conectados ao inicializador nativo Windows `C:\workspace\local\config\powershell\init.ps1` pelo (consulte índice deste repositório) após criar a estrutura. O PATH do usuário inclui `C:\workspace\local\bin` uma única vez, compartilhado pelas duas edições PowerShell.
Abra Windows Terminal → Configurações (`Ctrl+,`) → Inicialização → Perfil padrão → **PowerShell** apontando para `pwsh.exe`, não `powershell.exe` (5.1). Se necessário, crie perfil com `C:\Program Files\PowerShell\7\pwsh.exe`. Preserve PowerShell 5.1.
Os perfis Ubuntu e MSYS2 UCRT64 serão criados/validados nas etapas 02 e 03.
## 6. Validação final antes da próxima etapa
```powershell
$PSVersionTable | Select-Object PSVersion,PSEdition
(Get-Process -Id $PID).Path
git --version
py --list
py -3.13 --version
python --version
winget list --id Microsoft.Sysinternals.Suite -e
winget list --id gerardog.gsudo -e
winget list --id Notepad++.Notepad++ -e
winget list --id 7zip.7zip -e
winget list --id RARLab.WinRAR -e
```
Esperado: versão principal 7, PSEdition Core e processo pwsh.exe. `python` pode resolver um alias da Store: nesse caso valide primeiro `py -3.13` e corrija o alias/PATH. Sysinternals pode não colocar executáveis individuais no PATH.
## 7. Dependências das próximas etapas
**Próxima:** Etapa 02 instala WSL2/Ubuntu; Etapa 03 instala MSYS2 UCRT64. Somente depois siga (consulte índice deste repositório); Docker Desktop na subpágina **01.01 — Docker Desktop no Windows: pré-requisitos, instalação e engine**, e VS Code/IntelliJ pelo (consulte índice deste repositório).
## Checklist
- [ ] Windows 11 e WinGet validados
- [ ] PowerShell 7/Terminal instalados, atualizações e reinicializações concluídas
- [ ] Git e Python 3.13 instalados e validados
- [ ] OpenJDK Temurin 21 instalado pelo WinGet
- [ ] Maven obtido do ZIP oficial e validado por SHA-512
- [ ] MAVEN_HOME e PATH idempotentes; Maven validado em nova sessão
- [ ] JAVA_HOME detectado e configurado; java e javac 21 encontrados no PATH
- [ ] Gradle baixado em ZIP oficial, hash SHA-256 conferido, GRADLE_HOME e PATH configurados e validados
- [ ] Sysinternals, gsudo, Notepad++, 7-Zip e WinRAR instalados
- [ ] PowerShell 7 definido como perfil padrão do Windows Terminal
- [ ] Validação geral aprovada; apto para Etapa 02
---


[Voltar ao índice](01-indice.md)

## Docker Desktop no Windows


## Objetivo
Docker Desktop instalado **somente no Windows**, com WSL2 como backend preferencial. A execução de Linux e Windows containers é mutuamente exclusiva e exige troca deliberada de engine. Pré-requisitos da etapa 01 e instalação do WSL da etapa 02.
## 1. Preparar o Windows ANTES de instalar o Docker Desktop
**Dependências:** Windows 11 já instalado → Etapa 01 (PowerShell 7/Terminal/WinGet) → Etapa 02 (WSL2/Ubuntu instalado e testado) → Etapa 03 (MSYS2 UCRT64 instalado e Terminal configurado) → estrutura comum Windows (guia B). Execute os diagnósticos abaixo no **PowerShell 7 elevado (Executar como administrador)** quando for alterar recursos do Windows. Os comandos de inspeção podem ser executados normalmente sem elevação.
### 1.1 Verificar sistema, arquitetura, RAM, BIOS/UEFI e virtualização
```powershell
Get-ComputerInfo | Select-Object WindowsProductName,WindowsVersion,OsBuildNumber,OsArchitecture,HyperVisorPresent
Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory,HypervisorPresent
Get-CimInstance Win32_Processor | Select-Object Name,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions
wsl --version
wsl --status
wsl -l -v
```
Confirme Windows 11 atualizado e arquitetura compatível, pelo menos 8 GiB RAM, suporte a SLAT e virtualização ligada na BIOS/UEFI. Alguns indicadores CIM de virtualização podem ficar indisponíveis ou ser pouco conclusivos quando já existe hipervisor ativo; verifique também **Gerenciador de Tarefas → Desempenho → CPU → Virtualização**. Se a BIOS estiver desabilitada, habilite Intel VT-x/AMD-V pelo firmware e reinicie; nenhum comando DISM substitui essa opção física.
### 1.2 Inspecionar os recursos opcionais do Windows
```powershell
$names = @('Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform','Microsoft-Hyper-V','Containers')
$names | ForEach-Object {
  $f = Get-WindowsOptionalFeature -Online -FeatureName $_ -ErrorAction SilentlyContinue
  [pscustomobject]@{FeatureName=$_;State=if($f){$f.State}else{'NotFound'}}
} | Format-Table -AutoSize
```
**Obrigatórios para WSL2/Linux containers:** `Microsoft-Windows-Subsystem-Linux` e `VirtualMachinePlatform` habilitados. **Somente se for utilizar Windows containers:** `Microsoft-Hyper-V` e `Containers`. Não habilite Hyper-V completo apenas por usar o backend WSL2.
### 1.3 Habilitar somente recursos ausentes do WSL2
Em PowerShell **administrador**:
```powershell
$required = @('Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform')
foreach ($name in $required) {
  $state = (Get-WindowsOptionalFeature -Online -FeatureName $name).State
  if ($state -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName $name -All -NoRestart
  }
}
```
Caso a etapa 02 já tenha concluído corretamente, não deverá haver alterações. Se algum componente foi habilitado agora, **salve o trabalho e reinicie o Windows antes de continuar**. Reexecute 1.2 após o reboot para confirmar que não permanece em `EnablePending`.
### 1.4 Verificar configuração de boot do hipervisor e serviços
```powershell
bcdedit /enum '{current}'
Get-Service vmcompute,LxssManager,WslService,LanmanServer -ErrorAction SilentlyContinue |
  Select-Object Name,Status,StartType
Get-CimInstance Win32_Service -Filter "Name='LanmanServer'" |
  Select-Object Name,State,StartMode
```
Em `bcdedit`, procure `hypervisorlaunchtype`. Se estiver `Off`, a inicialização do hipervisor foi desabilitada e pode impedir o WSL2. **Não altere automaticamente**: primeiro descubra se houve uma decisão anterior de coexistência com VMware/VirtualBox ou política corporativa. Quando autorizada, a correção é `bcdedit /set hypervisorlaunchtype auto` (administrador) seguida de reboot. O serviço `LanmanServer` deve estar habilitado e com inicialização automática conforme requisitos do Docker Desktop. Um serviço ausente na consulta não comprova, isoladamente, que a instalação está defeituosa: serviços do WSL variam conforme a versão do Windows.
### 1.5 Atualizar e validar o WSL2 antes do Docker Desktop
```powershell
wsl --update
wsl --shutdown
wsl --version
wsl --list --verbose
wsl -d Ubuntu-24.04 -- uname -r
```
Substitua `Ubuntu-24.04` pelo nome **exato** retornado em `wsl -l -v`. A distribuição deve estar na versão **2** e iniciar corretamente. A versão do pacote WSL deve satisfazer o requisito mínimo atual do Docker (WSL 2.1.5 ou superior). Para suporte adicional de isolamento, o Docker pode exigir versão de WSL mais recente.
### 1.6 Escolher modo de instalação: per-user ou all-users
- **Per-user:** suficiente para Linux containers com backend WSL2; normalmente não precisa instalação administrativa.
- **All-users:** escolher se deseja suportar **Windows containers** futuramente. Esse modo exige permissões de administrador e integração privilegiada; a instalação per-user não oferece containers Windows.
- Para Windows containers, confirme **Windows Pro/Enterprise** e só então habilite Hyper-V completo e Containers (PowerShell Admin):
```powershell
# EXECUTAR APENAS quando Windows containers forem necessários e suportados
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
```
Salve o trabalho e reinicie antes de instalar/trocar o backend. Caso você use somente Linux containers, **não execute o bloco de Hyper-V e Containers**.
### 1.7 Instalar Docker Desktop com WinGet
```powershell
winget source update
winget search --id Docker.DockerDesktop -e
winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements
```
**Antes de confirmar o instalador, verifique se o modo selecionado será per-user ou all-users.** Como o projeto prevê Windows containers como opção futura, escolha all-users caso realmente precise dessa capacidade e tenha privilégios. O WinGet pode invocar instaladores com opções próprias; não presuma que o comando padrão força all-users. Verifique o modo de instalação exibido e utilize o instalador oficial com suas opções documentadas quando for necessário selecioná-lo explicitamente.
Após instalar, reinicie se solicitado. Abra Docker Desktop e conclua a configuração. Para o uso prioritário Linux: **Settings → General → Use WSL 2 based engine**, quando exibido; **Settings → Resources → WSL Integration** → habilite a distribuição desejada. O modo Windows exige troca deliberada da engine, com interrupção prévia dos workloads.
### 1.8 Diagnóstico do host após instalação
```powershell
docker version
docker context ls
docker info --format '{{.OSType}}'
wsl -l -v
Get-Service com.docker.service -ErrorAction SilentlyContinue |
  Select-Object Name,Status,StartType
```
O resultado inicial esperado de `docker info --format '{{.OSType}}'` é `linux`. O serviço `com.docker.service` **não é um requisito universal no modo per-user com WSL2**; sua presença e necessidade dependem do modo de instalação/backend. No Ubuntu integrado: `docker info --format '{{.OSType}}'` deve retornar `linux` também.
### 1.9 Erros frequentes e verificação antes de tentar reinstalar
- **WSL 1 ou distro não inicia:** `wsl -l -v`; confirme recursos, virtualização BIOS e reinicialização.
- **Erro de virtualização/0x80370102:** revisar VirtualMachinePlatform, hipervisor no boot e BIOS/UEFI.
- **Docker engine não inicia:** abrir Docker Desktop, revisar Settings e confirmar WSL atualizado; não apagar distribuições nem diretórios de dados Docker por tentativa.
- **WSL Integration não aparece:** confirme modo Linux/WSL2; no modo Windows containers essa tela pode não estar disponível.
- **Windows containers indisponíveis:** verifique edição Windows, instalação all-users, recursos Hyper-V e Containers, reinicialização e política da organização.
- **Conflito com outro hipervisor:** revise requisitos de coexistência; não desabilite WSL/Hyper-V ou altere BCD sem diagnóstico.
## Checklist dos componentes Windows
- [ ] Windows 11 compatível e atualizado
- [ ] BIOS/UEFI com virtualização habilitada
- [ ] RAM e suporte SLAT verificados
- [ ] Microsoft-Windows-Subsystem-Linux = Enabled
- [ ] VirtualMachinePlatform = Enabled
- [ ] WSL2 atualizado, Ubuntu versão 2 e inicializável
- [ ] Sem reinicialização pendente dos componentes Windows
- [ ] LanmanServer configurado de forma compatível
- [ ] Modo per-user ou all-users escolhido conscientemente
- [ ] Se Windows containers: edição suportada, Hyper-V e Containers habilitados
- [ ] Docker Desktop instalado e aberto
- [ ] Engine Linux validada e WSL Integration habilitada
## Referências oficiais
[Requisitos e instalação Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) · [Instalação WSL](https://learn.microsoft.com/pt-br/windows/wsl/install/) · [Passos manuais recursos opcionais WSL](https://learn.microsoft.com/en-us/windows/wsl/install-manual)
## 2. Verificar
```powershell
docker version
docker context ls
docker info --format '{{.OSType}}'
```
No Ubuntu integrado: `docker info --format '{{.OSType}}'`. Antes de operar, verifique o contexto selecionado e o sistema operacional retornado.
## 3. Wrapper com política *fail closed*
Wrappers devem residir em `C:\workspace\local\bin` (PowerShell) e `/workspace/local/bin` (Linux); em cada instalação MSYS2 use bin nativo próprio. Exemplo de esqueleto PowerShell que verifica o ENGINE mas NÃO substitui todas as opções do Docker:
```powershell
# ds1-docker.ps1: chamar explicitamente, sem mascarar docker.exe
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$DockerArgs)
$expected='linux' # alterar para 'windows' apenas no perfil do host validado
$actual=(& docker.exe info --format '{{.OSType}}' 2>$null)
if($LASTEXITCODE -ne 0 -or $actual -ne $expected){throw "Docker bloqueado: esperado=$expected encontrado=$actual"}
& docker.exe @DockerArgs
exit $LASTEXITCODE
```
## Operação exclusiva Linux/Windows containers
Antes de alternar a engine Linux para Windows ou voltar: inventarie workloads, realize backup consistente por serviço, interrompa containers do modo atual, confirme ausência de workloads ativos, alterne no Docker Desktop e valide novamente `docker info --format '{{.OSType}}'`. Não automatize troca de engine enquanto houver workloads em execução. O wrapper que verifica `OSType` controla apenas chamadas realizadas por ele; a CLI Docker direta continua acessível.
## Dados Docker no Windows
Quando for usar Windows containers, arquivos e binds específicos podem ficar em `C:\workspace\local\docker`. Linux containers e bases de dados que exigem desempenho nativo devem seguir as orientações do (consulte índice deste repositório). Volumes nomeados Docker são gerenciados pelo engine, não equivalem automaticamente à pasta `local/docker/data`. Não sincronize data dirs ativos com Google Drive.
## Aceite
- [ ] Docker Desktop instalado no Windows e atualizado
- [ ] Engine Linux validada via docker info
- [ ] Backend WSL2 e integração da distribuição configurados
- [ ] Modo Windows containers habilitado apenas quando necessário, com requisitos e privilégios conhecidos
- [ ] Wrapper de Windows verifica a engine esperada
- [ ] Política de troca exclusiva compreendida
