#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/TaskPhases.psm1') -Force
$root = Join-Path ([IO.Path]::GetTempPath()) ('ds1-phases-' + [guid]::NewGuid().ToString('N'))
$script:assertionCount = 0
function Assert([bool]$condition,[string]$message) { if (-not $condition) { throw "FAIL: $message" }; $script:assertionCount++ }
try {
    $null = New-Item -ItemType Directory -Path $root
    $checks = @(
        [pscustomobject]@{Satisfied=$true},
        [pscustomobject]@{Satisfied=$false}
    )
    Assert ((Get-Ds1CheckState @{Detected=$false;Checks=$checks}) -eq 'Parcial') 'estado misto'
    $checks[0].Satisfied=$false
    Assert ((Get-Ds1CheckState @{Detected=$false;Checks=$checks}) -eq 'Requerido') 'nenhum atendido'
    $checks[0].Satisfied=$true; $checks[1].Satisfied=$true
    Assert ((Get-Ds1CheckState @{Detected=$true;Checks=$checks}) -eq 'Satisfeito') 'todos atendidos'
    Assert ((Get-Ds1CheckState @{Detected=$true}) -eq 'Satisfeito') 'runbook antigo'
    $commands = Join-Path $root 'commands.jsonl'
    $context = @{CommandLogPath=$commands}
    $result = Invoke-Ds1LoggedAction -Context $context -TaskId first -StepId wsl -Command 'Enable-TestFeature -NoRestart' `
        -Action { [pscustomobject]@{State='Enabled'} } -DescribeResult {param($r) "Estado: $($r.State)"}
    Assert ($result.State -eq 'Enabled') 'resultado devolvido ao chamador'
    try {
        $null = Invoke-Ds1LoggedAction -Context $context -TaskId first -StepId vm -Command 'Enable-TestVM' `
            -Action { throw 'Falha simulada' } -DescribeResult {param($r) 'não deve executar'}
        throw 'Falha esperada não ocorreu'
    } catch { Assert ($_.Exception.Message -eq 'Falha simulada') 'erro propagado ao chamador' }
    $events = @(Get-Ds1PhaseEvents -Path $commands -TaskId first)
    Assert ($events.Count -eq 4) 'entrada e resultado para cada comando'
    Assert ($events[1].Command -eq 'Enable-TestFeature -NoRestart' -and $events[1].Result -eq 'Estado: Enabled' -and $events[1].Status -eq 'Satisfeito') 'comando e resultado detalhados'
    Assert ($events[3].Status -eq 'Erro' -and $events[3].Result -eq 'Falha simulada') 'erro detalhado'
    Assert (@(Get-Ds1PhaseEvents -Path $commands -TaskId other).Count -eq 0) 'filtro por tarefa'
    $transcript = Join-Path $root 'run.log'
    Set-Content -LiteralPath $transcript -Value 'transcrição simulada'
    $copies = @(Export-Ds1SessionLogs -Directory (Join-Path $root 'export') -TranscriptPath $transcript -CommandLogPath $commands)
    Assert ($copies.Count -eq 2 -and (Test-Path $copies[0]) -and (Test-Path $copies[1])) 'exportação ao destino escolhido'
    Write-Host "PASS: $script:assertionCount verificações de fases e logs"
} finally { Remove-Item -LiteralPath $root -Recurse -Force }
