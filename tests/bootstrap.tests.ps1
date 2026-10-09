#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$path = Join-Path (Split-Path $PSScriptRoot -Parent) 'bootstrap.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
# Import only function definitions. Never invoke bootstrap or install on a test host.
foreach ($node in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    . ([scriptblock]::Create($node.Extent.Text))
}
$count = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }; $script:count++
}
function Assert-Throws([scriptblock]$Action, [string]$Message) {
    $threw = $false
    try { & $Action | Out-Null } catch { $threw = $true }
    Assert $threw $Message
}
function Get-ItemProperty { return [pscustomobject]@{ EnableLUA = 1 } }
Assert (Get-Ds1UacEnabled) 'Enabled UAC was not detected'
function Get-ItemProperty { return [pscustomobject]@{ EnableLUA = 0 } }
Assert (-not (Get-Ds1UacEnabled)) 'Disabled UAC was not detected'
Assert ((ConvertTo-Ds1Literal "C:\David's folder\bootstrap.ps1") -ceq "'C:\David''s folder\bootstrap.ps1'") 'Literal escaping failed'
$hash = 'a' * 64
Assert ((Get-Ds1ExpectedHash "$hash *PowerShell.msi" 'PowerShell.msi') -eq $hash) 'Hash filename selection failed'
Assert ((Get-Ds1ExpectedHash "$hash  PowerShell.msi`r`n" 'PowerShell.msi') -eq $hash) 'CRLF hash failed'
Assert-Throws { Get-Ds1ExpectedHash "$hash Other.msi" 'PowerShell.msi' } 'Missing hash accepted'
Assert-Throws { Get-Ds1ExpectedHash "$hash PowerShell.msi`n$hash PowerShell.msi" 'PowerShell.msi' } 'Ambiguous hash accepted'
Assert (-not (Assert-Ds1InstallerExit 0)) 'MSI success failed'
Assert (Assert-Ds1InstallerExit 3010) 'MSI reboot failed'
Assert-Throws { Assert-Ds1InstallerExit 1603 } 'MSI failure accepted'
$release = Get-Ds1MsiRelease 'x64'
Assert ($release.Url -eq 'https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-x64.msi') 'Release is not pinned'
$oldArch = $env:PROCESSOR_ARCHITECTURE; $oldWow = $env:PROCESSOR_ARCHITEW6432
try {
    $env:PROCESSOR_ARCHITECTURE = 'x86'; $env:PROCESSOR_ARCHITEW6432 = 'AMD64'
    Assert ((Get-Ds1NativeArchitecture) -eq 'x64') 'WOW64 detection failed'
    $env:PROCESSOR_ARCHITEW6432 = ''; $env:PROCESSOR_ARCHITECTURE = 'ARM64'
    Assert ((Get-Ds1NativeArchitecture) -eq 'arm64') 'ARM64 detection failed'
    $env:PROCESSOR_ARCHITECTURE = 'x86'
    Assert-Throws { Get-Ds1NativeArchitecture } 'Unsupported architecture accepted'
} finally { $env:PROCESSOR_ARCHITECTURE = $oldArch; $env:PROCESSOR_ARCHITEW6432 = $oldWow }

# Negative installation paths must never invoke an installer or network on denial.
function Read-Host { return 'n' }
function Invoke-WebRequest { throw 'NETWORK MUST NOT BE CALLED' }
function Start-Process { throw 'INSTALLER MUST NOT BE CALLED' }
$denied = $false
try { Install-Ds1PowerShell -Stage $env:TEMP -Architecture x64 } catch { $denied = $_.Exception.Message -like 'Instalacao nao autorizada*' }
Assert $denied 'Refusing consent did not stop before network/install'

# Downloads are mocked. A checksum mismatch must block MSI execution.
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
    function Read-Host { return 's' }
    function Invoke-WebRequest { param($Uri, $OutFile, [switch]$UseBasicParsing)
        if ($Uri -like '*hashes.sha256') { Set-Content -LiteralPath $OutFile -Value (('0' * 64) + ' PowerShell-7.6.6-win-x64.msi') }
        else { Set-Content -LiteralPath $OutFile -Value 'not a real installer' }
    }
    $blocked = $false
    try { Install-Ds1PowerShell -Stage $tempRoot -Architecture x64 } catch { $blocked = $_.Exception.Message -like 'SHA-256 divergente*' }
    Assert $blocked 'Checksum mismatch did not stop installer'
    function Get-FileHash { return [pscustomobject]@{ Hash = ('0' * 64) } }
    function Get-AuthenticodeSignature { return [pscustomobject]@{ Status = 'NotSigned'; SignerCertificate = $null } }
    $blocked = $false
    try { Install-Ds1PowerShell -Stage $tempRoot -Architecture x64 } catch { $blocked = $_.Exception.Message -like 'Assinatura Microsoft*' }
    Assert $blocked 'Unsigned MSI did not stop installer'
} finally { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
Write-Host "PASS: $count bootstrap checks (no installation performed)."
