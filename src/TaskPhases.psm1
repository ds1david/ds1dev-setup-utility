Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Ds1CheckState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$TestResult)
    if ($TestResult.ContainsKey('Checks')) {
        $checks = @($TestResult.Checks)
        if ($checks.Count -eq 0) { throw 'Lista de checagens vazia.' }
        $satisfied = @($checks | Where-Object { $_.Satisfied -eq $true }).Count
        if ($satisfied -eq $checks.Count) { return 'Satisfeito' }
        if ($satisfied -eq 0) { return 'Requerido' }
        return 'Parcial'
    }
    if ($TestResult.Detected) { return 'Satisfeito' }
    return 'Requerido'
}

function Write-Ds1PhaseEvent {
    [CmdletBinding()]
    param([hashtable]$Context = @{}, [Parameter(Mandatory)][string]$TaskId,
          [Parameter(Mandatory)][string]$StepId, [Parameter(Mandatory)][string]$Phase,
          [Parameter(Mandatory)][string]$Status, [string]$Command = '', [string]$Result = '')
    if (-not $Context.ContainsKey('CommandLogPath') -or -not $Context.CommandLogPath) { return }
    $entry = [ordered]@{ At=(Get-Date).ToString('o'); TaskId=$TaskId; StepId=$StepId;
        Phase=$Phase; Status=$Status; Command=$Command; Result=$Result }
    Add-Content -LiteralPath $Context.CommandLogPath -Value (ConvertTo-Json $entry -Compress -Depth 6) -Encoding UTF8
}

function Invoke-Ds1LoggedAction {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Context, [Parameter(Mandatory)][string]$TaskId,
          [Parameter(Mandatory)][string]$StepId, [Parameter(Mandatory)][string]$Command,
          [Parameter(Mandatory)][scriptblock]$Action,
          [Parameter(Mandatory)][scriptblock]$DescribeResult)
    Write-Ds1PhaseEvent $Context $TaskId $StepId 'Execução' 'Em execução' $Command
    try {
        $result = & $Action
        $summary = [string](& $DescribeResult $result)
        Write-Ds1PhaseEvent $Context $TaskId $StepId 'Execução' 'Satisfeito' $Command $summary
        return $result
    } catch {
        Write-Ds1PhaseEvent $Context $TaskId $StepId 'Execução' 'Erro' $Command $_.Exception.Message
        throw
    }
}

function Get-Ds1PhaseEvents {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$TaskId = '')
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if (-not $line.Trim()) { continue }
        $entry = $line | ConvertFrom-Json
        if (-not $TaskId -or $entry.TaskId -eq $TaskId) { $entry }
    }
}

function Export-Ds1SessionLogs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][string]$TranscriptPath,
          [Parameter(Mandatory)][string]$CommandLogPath)
    $folder = [IO.Path]::GetFullPath($Directory)
    $null = New-Item -ItemType Directory -Force -Path $folder
    $saved = @()
    foreach ($path in @($TranscriptPath,$CommandLogPath)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $destination = Join-Path $folder ([IO.Path]::GetFileName($path))
            if ([IO.Path]::GetFullPath($path) -ne $destination) {
                if (Test-Path -LiteralPath $destination) { throw "Destino já contém $destination; escolha outra pasta." }
                Copy-Item -LiteralPath $path -Destination $destination -ErrorAction Stop
            }
            $saved += $destination
        }
    }
    return $saved
}

Export-ModuleMember -Function Get-Ds1CheckState,Write-Ds1PhaseEvent,Invoke-Ds1LoggedAction,Get-Ds1PhaseEvents,Export-Ds1SessionLogs
