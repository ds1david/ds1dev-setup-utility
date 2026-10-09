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
Import-Module (Join-Path $PSScriptRoot 'Runbooks.psm1') -Force
$RunbookRoot = Join-Path $RepoRoot 'runbooks'
$Catalog = @{ Tasks = @(Get-RunbookCatalog -Root $RunbookRoot) }
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
  $step = Get-Step $id
  try { Test-RunbookDependencies -Runbook $step -Catalog $Catalog.Tasks }
  catch { return "Blocked ($($_.Exception.Message))" }
  if (-not $step.Implemented) { return 'Planned' }
  if (Test-Step $id) { return 'Detected' }
  return 'Ready'
}
function Invoke-Step([string]$id,[string]$mode,[string]$requestedVersion) {
  $step = Get-Step $id
  Write-Host "[$id] $($step.Title) | mode=$mode | environment=$($step.Environment)"
  # Test permite diagnóstico mesmo com pré-requisitos ausentes; Plan/Apply são bloqueados.
  if ($mode -ne 'Test') { Test-RunbookDependencies -Runbook $step -Catalog $Catalog.Tasks }
  $context = @{ RunId=$runId; LogPath=$log; StateHome=$StateHome; Environment=$step.Environment }
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
        try { $Catalog = @{ Tasks = @(Get-RunbookCatalog -Root $RunbookRoot) } }
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
