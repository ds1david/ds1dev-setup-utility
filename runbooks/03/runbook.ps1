[CmdletBinding()]
param([ValidateSet('Test','Plan','Apply')][string]$Mode='Test',
      [string]$Version='', [hashtable]$Context=@{})
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Test-CurrentState {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
    $out = @(& wsl.exe --list --quiet 2>$null)
    if ($LASTEXITCODE -ne 0) { return $false }
    $ubuntu = @($out | ForEach-Object { ($_ -replace '[\u0000]', '').Trim() } | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1)
    if ($ubuntu.Count -eq 0) { return $false }
    $null = & wsl.exe -d $ubuntu[0] -- /bin/sh -c 'test -f /etc/os-release && uname -s' 2>$null
    return ($LASTEXITCODE -eq 0)
}
if ($Mode -eq 'Test') {
    # Detector histórico parcial. Não comprova instalação completa nem versão exata.
    # Nenhum detector histórico verifica ainda uma versão exata.
    $detected = if ($Version) { $false } else { [bool](Test-CurrentState) }
    return @{ Succeeded=$true; Detected=$detected }
}
if ($Mode -eq 'Plan') {
    Write-Host 'Rotina de instalação ainda não implementada; consulte a documentação.'
    return @{ Succeeded=$true; Changes=@(); Implemented=$false }
}
throw 'Instalador ainda não implementado.'
