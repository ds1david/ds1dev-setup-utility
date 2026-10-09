# 02 — Preparação Windows

[Índice](01-indice.md) · [Toolchain Windows](02.1-toolchain-windows.md) · [Plano](plano-de-execucao.md)

## Entrada em Windows limpo ou existente

O mínimo de entrada é Windows 11 suportado com Windows PowerShell 5.1, rede e autorização administrativa. **WinGet, PowerShell 7 e Windows Terminal não são presumidos instalados.**

O `bootstrap.ps1` verifica UAC e elevação, solicita autorização para elevar e procura PowerShell 7 estável compatível (mínimo 7.4). Se ausente, oferece MSI oficial 7.6.6, com SHA-256 e assinatura Microsoft verificados, sem exigir WinGet. Se presente, reutiliza. UAC já faz parte do Windows e não é instalado pelo script. Uma conta diferente na elevação é bloqueada para proteger o escopo do usuário.

O bootstrap tem testes isolados; a execução completa no Windows limpo ainda requer homologação. Os runbooks de preparação continuam pendentes. Consulte o [plano M1/M5](plano-de-execucao.md).

## Preparação básica

Inventariar antes de modificar. O runbook deverá instalar/configurar WinGet (App Installer oficial), Windows Terminal e utilitários selecionados; PowerShell 7 já deve ser reaproveitado do bootstrap. A ausência de WinGet é trabalho desta preparação, não motivo para impedir o bootstrap. Não atualizar todos os pacotes existentes indiscriminadamente.

Diagnóstico no PowerShell 7:

```powershell
$PSVersionTable
Get-Command winget.exe,pwsh.exe -ErrorAction SilentlyContinue
Get-ComputerInfo | Select-Object WindowsProductName,OsBuildNumber,HyperVisorPresent
```

Quando WinGet já estiver funcional, os exemplos abaixo são comandos manuais a revisar; não substituem os futuros runbooks idempotentes:

```powershell
winget search --id Microsoft.WindowsTerminal -e
winget install --id Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
```

PowerShell 5.1 permanece disponível. Perfis e personalização pertencem a [06](06-shells.md); instalações/variáveis/validações de Git, Python, Java, Maven, Gradle e utilitários de desenvolvimento pertencem a [02.1](02.1-toolchain-windows.md).

### 4.2 Instalar Sysinternals Suite
Pacote Microsoft de administração e diagnóstico: Process Explorer, Process Monitor, Autoruns, TCPView, Handle, PsExec e outras ferramentas. O pacote contém utilitários avançados; algumas exigem elevação e aceitação da licença na primeira execução.
```powershell
winget search --id Microsoft.Sysinternals.Suite -e
winget install --id Microsoft.Sysinternals.Suite -e --accept-source-agreements --accept-package-agreements
winget list --id Microsoft.Sysinternals.Suite -e
```
**Atenção:** versões anteriores do manifesto da suíte já apresentaram falha de hash quando o arquivo ZIP oficial mudou. **Nunca desabilite verificação de hash ou integridade** para contornar. Se ocorrer, obtenha a suíte pela [página oficial da Microsoft](https://learn.microsoft.com/pt-br/sysinternals/downloads/sysinternals-suite), confira integridade e extraia em uma pasta apropriada de ferramentas Windows; registre a instalação. O pacote WinGet pode não adicionar todos os utilitários individualmente ao PATH. Valide o diretório instalado com `winget list` e localize `procexp64.exe`, `procmon64.exe` ou equivalentes na instalação, em vez de presumir que todos funcionarão pelo nome no terminal.
### 4.3 Instalar gsudo
`gsudo` permite solicitar elevação de **comandos Windows** a partir do PowerShell ou Terminal. Não substitui autorização administrativa, não concede permissões inexistentes e **não é o sudo Linux**.
```powershell
winget search --id gerardog.gsudo -e
winget install --id gerardog.gsudo -e --accept-source-agreements --accept-package-agreements
```
Feche e reabra os terminais para atualizar o PATH. Valide:
```powershell
Get-Command gsudo -ErrorAction SilentlyContinue
gsudo --version
gsudo whoami /groups
```
A última linha pode solicitar confirmação do Controle de Conta de Usuário (UAC). Use `gsudo` somente para comandos específicos que exigem elevação; evite trabalhar em um shell elevado permanentemente. Se precisar usar o gsudo dentro do MSYS2, configure a integração Bash separadamente após instalar o UCRT64.

## Aceite da preparação básica

- [ ] PS7 compatível disponível, com PS5.1 preservado
- [ ] WinGet funcional ou diagnóstico de bloqueio explícito
- [ ] Terminal e utilitários selecionados validados
- [ ] Instalações preexistentes preservadas
- [ ] Reinício pendente tratado antes das tarefas dependentes

WSL (03) e MSYS2 (04) são preparações independentes após esta base. Docker é uma subetapa opcional abaixo: sua dependência de WSL não deve bloquear nem criar ciclo no preparo básico Windows.

## Docker Desktop no Windows


## Objetivo
Docker Desktop instalado **somente no Windows**, com WSL2 como backend preferencial. A execução de Linux e Windows containers é mutuamente exclusiva e exige troca deliberada de engine. Pré-requisitos da etapa 01 e instalação do WSL da etapa 02.
## 1. Preparar o Windows ANTES de instalar o Docker Desktop
**Dependências:** preparação básica Windows concluída e WSL2 operacional (03). MSYS2 não é requisito do Docker Desktop. Wrappers e diretórios personalizados dependem do workspace correspondente (05). Execute os diagnósticos abaixo no **PowerShell 7 elevado (Executar como administrador)** quando for alterar recursos do Windows. Os comandos de inspeção podem ser executados normalmente sem elevação.
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

## Diagnóstico de falha após UAC

Se o processo elevado falhar, o bootstrap deve mostrar a exceção original na janela elevada, aguardar Enter e reproduzir o diagnóstico na sessão original. O caminho `ds1dev-setup-<id>/elevation-error.log` é mostrado antes da elevação. Esse log cobre inclusive falhas anteriores ao início da transcrição administrativa.

O primeiro teste real em PowerShell 5.1 retornou apenas código 1. Foi identificado e corrigido um erro no tratamento da exceção: `Write-Error` com preferência `Stop` interrompia o próprio catch antes da pausa. Também foi adicionada conversão explícita de bytes UTF-8 para texto no download remoto, para não passar conteúdo binário a `ScriptBlock.Create`. A causa inicial desse teste ainda depende do novo diagnóstico; não confundir a correção de observabilidade com homologação completa do bootstrap.
