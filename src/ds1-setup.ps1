[CmdletBinding()]
param(
  [switch]$List,
  [string]$Task,
  [switch]$Validate,
  [switch]$Plan,
  [switch]$Apply,
  [string]$Version,
  [switch]$NoTui
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
Import-Module (Join-Path $PSScriptRoot 'Runbooks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Preflight.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Tui.psm1') -Force
$RunbookRoot = Join-Path $RepoRoot 'runbooks'
$Catalog = @{ Tasks = @(Get-RunbookCatalog -Root $RunbookRoot) }
$StatusCache = @{}
$LogHome = Join-Path $env:ProgramData 'DS1DevSetup\logs'
$StateHome = Join-Path $env:ProgramData 'DS1DevSetup\state'
New-Item -ItemType Directory -Force -Path $LogHome,$StateHome | Out-Null
$runId = (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
$log = Join-Path $LogHome "run-$runId.log"
Start-Transcript -Path $log -IncludeInvocationHeader | Out-Null
function Test-Step([string]$id) {
  $step = Get-Step $id
  return (Invoke-RunbookHandler -Runbook $step -Mode Test).Detected
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
    platform = (Get-Step $id).Environment
    observed = $found
    observedAt = (Get-Date).ToString('o')
    note = 'Observacao atual; nao comprova instalacao completa nem representa Apply bem-sucedido'
  }
  $path = Join-Path $StateHome ("observed-" + ($id -replace '[^a-zA-Z0-9.]','_') + ".json")
  $entry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
}
function Get-Status([string]$id) {
  $cached = $StatusCache[$id]
  if ($cached -and ((Get-Date) - $cached.At).TotalSeconds -lt 15) { return $cached.Value }
  $step = Get-Step $id
  $state = try {
    Test-RunbookDependencies -Runbook $step -Catalog $Catalog.Tasks
    if (-not $step.Implemented) { 'Planned' }
    elseif (Test-Step $id) { 'Detected' }
    else { 'Ready' }
  } catch { "Blocked ($($_.Exception.Message))" }
  $StatusCache[$id] = @{At=(Get-Date);Value=$state}
  return $state
}
function Invoke-Step([string]$id,[string]$mode,[string]$requestedVersion) {
  $StatusCache.Clear()
  $step = Get-Step $id
  Write-Host "[$id] $($step.Title) | mode=$mode | environment=$($step.Environment)"
  # The global prerequisite gate applies even to read-only execution of other runbooks.
  Test-RunbookDependencies -Runbook $step -Catalog $Catalog.Tasks
  $context = @{ RunId=$runId; LogPath=$log; StateHome=$StateHome; Environment=$step.Environment }
  if ($id -eq 'prerequisites') { $context.ShowDetails = $true }
  $result = Invoke-RunbookHandler -Runbook $step -Mode $mode -Version $requestedVersion -Context $context
  if ($mode -eq 'Test') {
    Write-Host "Detector: $($result.Detected)"
    Write-Observation $id $result.Detected
  } elseif ($mode -eq 'Apply') {
    # Sucesso de Apply só é aceito após uma nova verificação da versão solicitada.
    $verification = Invoke-RunbookHandler -Runbook $step -Mode Test -Version $requestedVersion -Context $context
    if (-not $verification.Detected) { throw 'Apply terminou, mas a pós-verificação falhou.' }
    $record = @{ TaskId=$id; Environment=$step.Environment; Version=$requestedVersion;
      AppliedAt=(Get-Date).ToString('o'); RunId=$runId; Result=$result }
    $record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $StateHome ("applied-$($step.Environment)-$id-$runId.json")) -Encoding UTF8
  }
}
try {
  Write-Host "DS1 Dev Setup Utility | $($PSVersionTable.PSVersion) | $runId"
  # Every entry point checks the real host before releasing the catalog.
  # The prerequisite runbook itself remains available for explicit diagnosis.
  if (-not ($Task -eq 'prerequisites' -and -not $Apply)) {
    $consent = {
      param($check,$attempt)
      if ([Console]::IsInputRedirected) { throw 'Correção exige consentimento interativo. Abra o bootstrap em um terminal Windows.' }
      $reason = @($check.Detail,"Operação: $($check.Repair)","Tentativa $attempt de 2.",
        'Sem este requisito, os demais runbooks não poderão ser executados.')
      $answer = Show-Ds1Modal 'CORRIGIR PRÉ-REQUISITO' $reason 'Autoriza esta correção? [s/N]'
      return $answer
    }
    $null = Invoke-Ds1Preflight -Catalog $Catalog.Tasks -Context @{RunId=$runId;LogPath=$log;StateHome=$StateHome} -Consent $consent
  }
  if ($List) {
    foreach ($s in $Catalog.Tasks) { Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id)) }
  } elseif ($Task) {
    if ($Task -eq 'prerequisites' -and $Apply) { Write-Host 'Pré-requisitos verificados pelo fluxo de autorização.'; return }
    Invoke-Step $Task $(if($Apply){'Apply'}elseif($Plan){'Plan'}else{'Test'}) $Version
  } elseif ($Validate) {
    foreach ($s in $Catalog.Tasks) {
      Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id))
    }
  } else {
    if (-not $NoTui) {
      $handled = Start-Ds1Tui -Catalog $Catalog.Tasks -Status {param($id) Get-Status $id} -Execute {
        param($id,$mode,$requestedVersion) Invoke-Step $id $mode $requestedVersion
      } -Reload { $Catalog = @{ Tasks = @(Get-RunbookCatalog -Root $RunbookRoot) }; $StatusCache.Clear(); return $Catalog.Tasks }
      if ($handled) { return }
      Write-Host 'Terminal sem suporte ao layout interativo; usando menu linear.'
    }
    do {
      Write-Host ''
      foreach ($s in $Catalog.Tasks) { Write-Host ("{0,-6} {1,-35} {2}" -f $s.Id,$s.Title,(Get-Status $s.Id)) }
      Write-Host '[Q] Sair  [V] Validar tudo  [R] Recarregar runbooks locais'
      $choice = Read-Host 'Selecione uma etapa'
      if ($choice -eq 'Q') { break }
      if ($choice -eq 'V') {
        foreach ($taskEntry in $Catalog.Tasks) {
          try { Invoke-Step $taskEntry.Id 'Test' '' } catch { Write-Warning $_.Exception.Message }
        }
        continue
      }
      if ($choice -eq 'R') {
        try { $Catalog = @{ Tasks = @(Get-RunbookCatalog -Root $RunbookRoot) }; $StatusCache.Clear() }
        catch { Write-Warning $_.Exception.Message }
        continue
      }
      if ($choice) {
        try {
          $s = Get-Step $choice
          Write-Host "Selecionado: $($s.Title)"
          $action = Read-Host 'T=Verificar P=Planejar A=Aplicar (somente runbooks implementados)'
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
