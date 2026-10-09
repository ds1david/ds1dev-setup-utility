#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Abra Windows PowerShell 5.1 ou PowerShell 7 como administrador para iniciar.'
}
if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) { throw 'O bootstrap requer Windows.' }
Write-Host 'DS1 Setup bootstrap: nao instala modulos nem runtimes para a interface.'
$pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if (-not $pwsh) {
    Write-Warning 'PowerShell 7 nao encontrado. E o unico prerequisito instalavel antes da interface.'
    $answer = Read-Host 'Deseja instalar PowerShell 7 via WinGet? [s/N]'
    if ($answer -notin @('s','S','sim','SIM')) { throw 'PowerShell 7 necessario. Nenhuma instalacao executada.' }
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'WinGet nao encontrado. Instale PowerShell 7 via fonte oficial autenticada e execute novamente.'
    }
    & winget.exe install --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "Falha instalacao pwsh: exit code $LASTEXITCODE" }
    $candidate = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw 'PowerShell 7 instalado mas ainda nao encontrado. Abra uma nova sessao elevada e execute novamente.'
    }
    $pwshPath = $candidate
} else { $pwshPath = $pwsh.Source }
$entry = Join-Path $PSScriptRoot 'src\ds1-setup.ps1'
if ($PSScriptRoot -and (Test-Path -LiteralPath $entry)) {
    & $pwshPath -NoProfile -File $entry
    exit $LASTEXITCODE
}
Write-Warning 'Modo remoto: sera baixado um ZIP da branch main. Este bootstrap NAO autentica criptograficamente a revisao baixada.'
Write-Warning 'Para uso seguro como administrador, prefira baixar uma release com SHA-256/assinatura fixados, verificar e executar localmente.'
$ok = Read-Host 'Confirma baixar esta revisao nao fixada do GitHub? [s/N]'
if ($ok -notin @('s','S','sim','SIM')) { throw 'Download cancelado.' }
$root = Join-Path $env:TEMP ('ds1dev-setup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $root | Out-Null
$zip = Join-Path $root 'source.zip'
try {
    Invoke-WebRequest -Uri 'https://github.com/ds1david/ds1dev-setup-utility/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $root
    $entry = Join-Path $root 'ds1dev-setup-utility-main\src\ds1-setup.ps1'
    if (-not (Test-Path -LiteralPath $entry)) { throw 'Pacote sem src/ds1-setup.ps1.' }
    & $pwshPath -NoProfile -File $entry
    exit $LASTEXITCODE
} finally {
    Write-Host "Staging: $root"
    Write-Host 'Remova o diretorio temporario apos conferir logs e integridade.'
}
