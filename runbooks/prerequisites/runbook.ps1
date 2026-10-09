[CmdletBinding()]
param(
    [ValidateSet('Test','Plan','Apply')][string]$Mode = 'Test',
    [string]$Version = '',
    [hashtable]$Context = @{}
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../src/TaskPhases.psm1')

function New-Check([string]$Id, [string]$Title, [bool]$Satisfied,
                   [string]$Detail, [string]$Repair = '') {
    return [pscustomobject]@{ Id=$Id; Title=$Title; Satisfied=$Satisfied;
        Detail=$Detail; Repair=$Repair }
}
function Get-Checks {
    if ($Context.ContainsKey('Probe')) {
        # Injected by contract tests; the public CLI never imports executable context from files.
        return @(& $Context.Probe)
    }
    if ($env:OS -ne 'Windows_NT') {
        return @(New-Check 'host' 'Windows 11 x64' $false 'Este executor requer Windows 11 x64.')
    }
    $checks = @()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $admin = (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $checks += New-Check 'administrator' 'Terminal administrador' $admin $(if($admin){'Token elevado.'}else{'Reabra pelo bootstrap e autorize o UAC.'})
    $psVersion = $PSVersionTable.PSVersion
    $checks += New-Check 'powershell' 'PowerShell 7.4 ou superior' ($psVersion.Major -eq 7 -and $psVersion -ge [version]'7.4') "Versão atual: $psVersion"
    $os = try { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $null }
    $version = $null
    $validWindows = ($null -ne $os -and [version]::TryParse([string]$os.Version, [ref]$version) -and
        $version.Major -eq 10 -and $version.Build -ge 22000)
    $checks += New-Check 'host' 'Windows 11' $validWindows $(if($os){"Build $($os.BuildNumber)"}else{'Não foi possível consultar o Windows.'})
    $arch = $env:PROCESSOR_ARCHITEW6432
    if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
    $checks += New-Check 'architecture' 'Arquitetura x64' ($arch -eq 'AMD64') "Arquitetura observada: $arch"
    $hypervisor = $null
    $firmware = $null
    try { $hypervisor = [bool](Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).HypervisorPresent } catch { }
    try { $firmware = [bool](Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1).VirtualizationFirmwareEnabled } catch { }
    $virtualization = ($hypervisor -eq $true -or $firmware -eq $true)
    $checks += New-Check 'virtualization' 'Virtualização para WSL2' $virtualization $(
        if($virtualization){'Hipervisor ativo ou virtualização habilitada no firmware.'}
        else{'Não foi possível confirmar virtualização; verifique BIOS/UEFI e a política de hipervisor.'})
    foreach ($item in @(
        @{Id='wsl-feature';Name='Microsoft-Windows-Subsystem-Linux';Title='Recurso WSL'},
        @{Id='vm-feature';Name='VirtualMachinePlatform';Title='Plataforma de Máquina Virtual'})) {
        $feature = try { Get-WindowsOptionalFeature -Online -FeatureName $item.Name -ErrorAction Stop } catch { $null }
        $state = if ($feature) { [string]$feature.State } else { 'Inacessível' }
        $repair = if ($state -eq 'Disabled') { "Enable-WindowsOptionalFeature:$($item.Name)" } else { '' }
        $checks += New-Check $item.Id $item.Title ($state -eq 'Enabled') "Estado: $state" $repair
    }
    return $checks
}
function Assert-Checks($Checks) {
    $ids = @('host','architecture','administrator','powershell','virtualization','wsl-feature','vm-feature')
    if (@($Checks).Count -ne $ids.Count) { throw 'Sondagem incompleta dos pré-requisitos; execução bloqueada.' }
    foreach ($id in $ids) {
        $matching = @($Checks | Where-Object Id -eq $id)
        if ($matching.Count -ne 1 -or $matching[0].Satisfied -isnot [bool]) { throw "Sondagem inválida: $id" }
    }
}
$checks = @(Get-Checks)
# On non-Windows, report the observed failure without attempting repairs.
if ($env:OS -eq 'Windows_NT' -or $Context.ContainsKey('Probe')) { Assert-Checks $checks }
$pending = @($checks | Where-Object { -not $_.Satisfied })
if ($Mode -eq 'Test') {
    foreach ($check in $checks) {
        Write-Ds1PhaseEvent -Context $Context -TaskId 'prerequisites' -StepId $check.Id -Phase 'Checagem' `
            -Status $(if($check.Satisfied){'Satisfeito'}else{'Requerido'}) -Result $check.Detail
    }
}
if ($Context.ContainsKey('ShowDetails') -and $Context.ShowDetails) {
    foreach ($check in $checks) {
        $state = if ($check.Satisfied) { 'OK' } else { 'PENDENTE' }
        Write-Host "[$state] $($check.Title): $($check.Detail)"
    }
}
if ($Mode -eq 'Test') {
    return @{ Succeeded=$true; Detected=($pending.Count -eq 0); Checks=$checks }
}
if ($Mode -eq 'Plan') {
    return @{ Succeeded=$true; Changes=@($pending | ForEach-Object {
        @{ Id=$_.Id; Title=$_.Title; Detail=$_.Detail; Repair=$_.Repair }
    }); Checks=$checks }
}
if ($pending.Count -eq 0) { return @{ Succeeded=$true; Changed=$false; Checks=$checks } }
$stepId = if ($Context.ContainsKey('StepId')) { [string]$Context.StepId } else { '' }
if (-not $stepId) { throw 'Apply requer StepId de uma pendência autorizada; use o fluxo interativo de pré-requisitos.' }
$chosen = @($pending | Where-Object Id -eq $stepId)
if ($chosen.Count -ne 1) { throw "Pendência ausente ou já resolvida: $stepId" }
$check = $chosen[0]
if (-not $check.Repair) { throw "Correção manual necessária para $($check.Title): $($check.Detail)" }
if ($Context.ContainsKey('Repair')) {
    $null = Invoke-Ds1LoggedAction -Context $Context -TaskId 'prerequisites' -StepId $stepId `
        -Command $check.Repair -Action { & $Context.Repair $stepId } -DescribeResult { 'Correção simulada concluída.' }
    return @{ Succeeded=$true; Changed=$true; StepId=$stepId }
}
if ($check.Repair -notmatch '^Enable-WindowsOptionalFeature:(Microsoft-Windows-Subsystem-Linux|VirtualMachinePlatform)$') {
    throw "Operação não permitida: $($check.Repair)"
}
$featureName = $Matches[1]
Write-Host "Habilitando recurso do Windows: $featureName"
$result = Invoke-Ds1LoggedAction -Context $Context -TaskId 'prerequisites' -StepId $stepId `
    -Command "Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart" `
    -Action { Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart -ErrorAction Stop } `
    -DescribeResult { param($r) "Estado: $($r.State); reinício necessário: $($r.RestartNeeded)" }
if ($result.RestartNeeded) { Write-Warning 'Reinicialização necessária; o fluxo será retomado após novo diagnóstico.' }
return @{ Succeeded=$true; Changed=$true; StepId=$stepId; PendingReboot=[bool]$result.RestartNeeded }
