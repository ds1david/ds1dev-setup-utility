[CmdletBinding()]
param(
  [switch]$List,
  [string]$Task,
  [switch]$Validate,
  [switch]$Plan,
  [switch]$Apply,
  [string]$Version
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  return ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) { throw 'Execute no Windows.' }
if (-not (Test-Admin)) { throw 'Requisito: abra PowerShell como administrador.' }
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Execute bootstrap.ps1 para instalar/localizar PowerShell 7.' }

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Catalog = Import-PowerShellDataFile (Join-Path $RepoRoot 'config\catalog.psd1')
$LogHome = Join-Path $env:ProgramData 'DS1DevSetup\logs'
$StateHome = Join-Path $env:ProgramData 'DS1DevSetup\state'
New-Item -ItemType Directory -Force -Path $LogHome,$StateHome | Out-Null
$runId = (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
$log = Join-Path $LogHome "run-$runId.log"
Start-Transcript -Path $log -IncludeInvocationHeader | Out-Null
function Test-Step([string]$id) {
  switch ($id) {
    '02' { return (Get-Command winget -ErrorAction SilentlyContinue) -and (Get-Command pwsh -ErrorAction SilentlyContinue) }
    '02.1' { return (Get-Command git -ErrorAction SilentlyContinue) -and (Get-Command java -ErrorAction SilentlyContinue) }
    '03' {
      if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
      $out = @(& wsl.exe --list --quiet 2>$null)
      if ($LASTEXITCODE -ne 0) { return $false }
      $ubuntu = @($out | ForEach-Object { ($_ -replace '[\u0000]', '').Trim() } | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1)
      if ($ubuntu.Count -eq 0) { return $false }
      $distro = $ubuntu[0]
      $null = & wsl.exe -d $distro -- /bin/sh -c 'test -f /etc/os-release && uname -s' 2>$null
      return ($LASTEXITCODE -eq 0)
    }
    '03.1' { return $false }
    '04' { return (Test-Path 'C:\msys64\usr\bin\bash.exe') }
    '04.1' { return $false }
    '05' { return (Test-Path 'C:\workspace\local\config') }
    '06' { return (Test-Path 'C:\workspace\local\config\powershell') }
    '06.1' { return [bool](Get-Command code -ErrorAction SilentlyContinue) }
    '07' { return $false }
    default { return $false }
  }
}
function Get-Step([string]$id) {
  $match = @($Catalog.Tasks | Where-Object { $_.Id -eq $id })
  if ($match.Count -ne 1) { throw "Tarefa desconhecida: $id" }
  return $match[0]
}
function Write-Observation([string]$id,[bool]$found) {
  $entry = [ordered]@{
    taskId = $id
    host = $env:COMPUTERNAME
    platform = 'Windows'
    observed = $found
    observedAt = (Get-Date).ToString('o')
    note = 'Observacao atual; nao comprova instalacao completa nem representa Apply bem-sucedido'
  }
  $path = Join-Path $StateHome ("observed-" + ($id -replace '[^a-zA-Z0-9.]','_') + ".json")
  $entry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
}
function Get-Status([string]$id) {
  $step = Get-Step $id
  foreach ($dependency in $step.DependsOn) {
    if (-not (Test-Step $dependency)) { return "Blocked ($dependency)" }
  }
  if (-not $step.Implemented) { return 'Planned' }
  if (Test-Step $id) { return 'Detected' }
  return 'Ready'
}
function Invoke-Step([string]$id,[string]$mode,[string]$requestedVersion) {
  $step = Get-Step $id
  $status = Get-Status $id
  Write-Host "[$id] $($step.Title) | $status | mode=$mode"
  if ($status -like 'Blocked*') { throw "Dependência não satisfeita: $status" }
  if ($requestedVersion -and -not $step.SupportsVersions) { throw "Versão explícita ainda não implementada para $id" }
  if ($mode -eq 'Test') {
    $detected = [bool](Test-Step $id)
    Write-Host "Detector: $detected"
    Write-Observation $id $detected
    return
  }
  if ($mode -eq 'Plan') {
    Write-Host ("Script previsto: " + $step.Script)
    Write-Host ("Versão solicitada: " + $(if($requestedVersion){$requestedVersion}else{'padrão'}))
    Write-Host 'Nenhuma mudança será executada neste modo.'
    return
  }
  if ($mode -eq 'Apply') {
    if (-not $step.Implemented) { throw 'Aplicação não implementada. Nenhuma alteração realizada.' }
    throw 'Apply bloqueado até implementação e testes de idempotência de cada tarefa.'
  }
}
try {
  Write-Host "DS1 Dev Setup Utility | $($PSVersionTable.PSVersion) | $runId"
  if ($List) {
    foreach ($s in $Catalog.Tasks) { Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id)) }
  } elseif ($Task) {
    Invoke-Step $Task $(if($Apply){'Apply'}elseif($Plan){'Plan'}else{'Test'}) $Version
  } elseif ($Validate) {
    foreach ($s in $Catalog.Tasks) {
      Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id))
    }
  } else {
    do {
      Write-Host ''
      foreach ($s in $Catalog.Tasks) { Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id)) }
      Write-Host '[Q] Sair  [V] Validar tudo'
      $choice = Read-Host 'Selecione uma etapa'
      if ($choice -eq 'Q') { break }
      if ($choice -eq 'V') { continue }
      if ($choice) {
        try {
          $s = Get-Step $choice
          Write-Host "Selecionado: $($s.Title)"
          $action = Read-Host 'T=Verificar P=Planejar A=Aplicar (bloqueado até homologação)'
          $ver = Read-Host 'Versão desejada (vazio = padrão)'
          $mode = switch ($action.ToUpperInvariant()) { 'P' {'Plan'} 'A' {'Apply'} default {'Test'} }
          Invoke-Step $choice $mode $ver
        } catch { Write-Warning $_.Exception.Message }
      }
    } while ($true)
  }
} finally {
  Write-Host "Log: $log"
  Stop-Transcript | Out-Null
}
