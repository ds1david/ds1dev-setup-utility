#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/Runbooks.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../src/Preflight.psm1') -Force
$pre = (Get-RunbookCatalog -Root (Join-Path $PSScriptRoot '../runbooks') | Where-Object Id -eq prerequisites)
$catalog = @($pre)
$script:checks = 0
function Assert([bool]$condition,[string]$message) { if(-not $condition){throw "FAIL: $message"};$script:checks++ }
function Assert-Throws([scriptblock]$action,[string]$pattern) {
    $errorText=''
    try { & $action | Out-Null } catch { $errorText=$_.Exception.Message }
    Assert ($errorText -match $pattern) "Expected [$pattern] but got [$errorText]"
}
$script:featureEnabled = $false
$script:repairCalls = @()
$script:promptCalls = @()
$probe = {
    foreach($id in @('host','architecture','administrator','powershell','virtualization','wsl-feature','vm-feature')) {
        [pscustomobject]@{ Id=$id; Title=$id; Satisfied=($id -ne 'wsl-feature' -or $script:featureEnabled);
            Detail="status of $id"; Repair=$(if($id -eq 'wsl-feature'){'Enable-WindowsOptionalFeature:Microsoft-Windows-Subsystem-Linux'}else{''}) }
    }
}
$repair = {param($id) $script:repairCalls += $id; $script:featureEnabled=$true}
$context = @{Probe=$probe;Repair=$repair}
$result=Invoke-RunbookHandler -Runbook $pre -Mode Test -Context $context
Assert (-not $result.Detected) 'Missing WSL feature was not detected'
$plan=Invoke-RunbookHandler -Runbook $pre -Mode Plan -Context $context
Assert (@($plan.Changes).Count -eq 1 -and $plan.Changes[0].Id -eq 'wsl-feature') 'Plan must identify only the pending step'
Assert ($script:repairCalls.Count -eq 0) 'Test/Plan performed a repair'
Assert-Throws { Invoke-RunbookHandler -Runbook $pre -Mode Apply -Context $context } 'StepId'
$decline = {param($check,$attempt) $script:promptCalls += $attempt; return 'n'}
Assert-Throws { Invoke-Ds1Preflight -Catalog $catalog -Context $context -Consent $decline } 'negada duas vezes'
Assert ($script:promptCalls.Count -eq 2 -and $script:repairCalls.Count -eq 0) 'Two refusals must abort without repair'
$script:promptCalls=@()
$secondChance = {param($check,$attempt) $script:promptCalls += $attempt; if($attempt -eq 1){return 'n'};return 's'}
Assert (Invoke-Ds1Preflight -Catalog $catalog -Context $context -Consent $secondChance) 'Second permission should allow repair'
Assert ($script:promptCalls.Count -eq 2 -and $script:repairCalls.Count -eq 1) 'Repair should run once after consent'
$script:promptCalls=@()
Assert (Invoke-Ds1Preflight -Catalog $catalog -Context $context -Consent $decline) 'Re-run on compliant host should pass'
Assert ($script:promptCalls.Count -eq 0 -and $script:repairCalls.Count -eq 1) 'Compliant rerun should be NoOp'
$script:featureEnabled=$false
$manualProbe = {
    foreach($id in @('host','architecture','administrator','powershell','virtualization','wsl-feature','vm-feature')) {
      [pscustomobject]@{Id=$id;Title=$id;Satisfied=($id -ne 'virtualization');Detail='Requires BIOS/UEFI';Repair=''}
    }
}
Assert-Throws { Invoke-Ds1Preflight -Catalog $catalog -Context @{Probe=$manualProbe;Repair=$repair} -Consent $secondChance } 'ação manual'
Assert ($script:repairCalls.Count -eq 1) 'Manual block must not invoke an unsafe repair'
Write-Host "PASS: $script:checks prerequisite checks (mocked, no Windows changes)."
