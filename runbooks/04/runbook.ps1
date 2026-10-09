[CmdletBinding()]
param([ValidateSet('Test','Plan','Apply')][string]$Mode='Test',
      [string]$Version='', [hashtable]$Context=@{})
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Test-CurrentState {
    return (Test-Path 'C:\msys64\usr\bin\bash.exe')
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
