Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Ds1Preflight {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$Catalog,
          [hashtable]$Context = @{},
          [scriptblock]$Consent = { param($check,$attempt) Read-Host "Autoriza corrigir $($check.Title)? [s/N]" })
    $matches = @($Catalog | Where-Object Id -eq 'prerequisites')
    if ($matches.Count -ne 1) { throw 'Runbook prerequisites ausente ou duplicado; os demais permanecem bloqueados.' }
    $preflight = $matches[0]
    $diagnosticContext = @{} + $Context
    $diagnosticContext.ShowDetails = $true
    $test = Invoke-RunbookHandler -Runbook $preflight -Mode Test -Context $diagnosticContext
    if ($test.Detected) { Write-Host 'Pré-requisitos atendidos. Runbooks liberados.'; return $true }
    $plan = Invoke-RunbookHandler -Runbook $preflight -Mode Plan -Context $Context
    foreach ($change in @($plan.Changes)) {
        # A fresh probe prevents acting on an issue already resolved outside the utility.
        $fresh = Invoke-RunbookHandler -Runbook $preflight -Mode Test -Context $Context
        if (@($fresh.Checks | Where-Object { $_.Id -eq $change.Id -and -not $_.Satisfied }).Count -eq 0) { continue }
        if (-not $change.Repair) {
            throw "Pré-requisito exige ação manual: $($change.Title). $($change.Detail) Os demais runbooks permanecem bloqueados."
        }
        $accepted = $false
        for ($attempt=1; $attempt -le 2; $attempt++) {
            $answer = & $Consent $change $attempt
            if ($answer -is [bool]) { $accepted = $answer }
            elseif ($null -ne $answer) { $accepted = ([string]$answer).Trim() -in @('s','S','sim','SIM') }
            if ($accepted) { break }
            Write-Warning "Sem $($change.Title), os demais runbooks não poderão ser executados."
            if ($attempt -eq 1) { Write-Host 'Solicitando autorização mais uma vez para esta correção.' }
        }
        if (-not $accepted) { throw "Autorização negada duas vezes para $($change.Title). Execução encerrada; nenhum outro runbook será executado." }
        $applyContext = @{} + $Context
        $applyContext.StepId = $change.Id
        $applied = Invoke-RunbookHandler -Runbook $preflight -Mode Apply -Context $applyContext
        if ($applied.ContainsKey('PendingReboot') -and $applied.PendingReboot) { throw "Reinicialização necessária após $($change.Title). Reinicie e execute novamente; runbooks bloqueados até lá." }
        $verification = Invoke-RunbookHandler -Runbook $preflight -Mode Test -Context $Context
        if (@($verification.Checks | Where-Object { $_.Id -eq $change.Id -and -not $_.Satisfied }).Count) {
            throw "Correção de $($change.Title) não passou na verificação posterior; runbooks bloqueados."
        }
    }
    $final = Invoke-RunbookHandler -Runbook $preflight -Mode Test -Context $Context
    if (-not $final.Detected) { throw 'Ainda há pré-requisitos pendentes; runbooks bloqueados.' }
    Write-Host 'Pré-requisitos atendidos. Runbooks liberados.'
    return $true
}
Export-ModuleMember -Function Invoke-Ds1Preflight
