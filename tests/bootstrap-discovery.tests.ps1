#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path (Split-Path $PSScriptRoot -Parent) 'bootstrap.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($node in $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    . ([scriptblock]::Create($node.Extent.Text))
}
$count = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }; $script:count++
}
# Mock only candidate discovery and OS boundaries. No candidate is ever executed.
$script:candidates = @('inaccessible-alias', 'working-install')
$script:queried = @()
function Get-Ds1PowerShellCandidates { return $script:candidates }
function Test-Path { param($LiteralPath, $PathType, $ErrorAction)
    if ($LiteralPath -eq 'path-access-denied') { throw [IO.IOException]::new('Access denied') }
    return ($LiteralPath -ne 'missing')
}
function Get-AuthenticodeSignature { param($LiteralPath, $ErrorAction)
    if ($LiteralPath -eq 'inaccessible-alias') { throw [IO.IOException]::new('Cannot access execution alias') }
    if ($LiteralPath -eq 'unsigned') { return @{Status='NotSigned';SignerCertificate=$null} }
    if ($LiteralPath -eq 'other-signer') { return @{Status='Valid';SignerCertificate=@{Subject='CN=Other, O=Other'}} }
    return @{Status='Valid';SignerCertificate=@{Subject='CN=Microsoft Corporation, O=Microsoft Corporation, C=US'}}
}
function Get-Ds1PowerShellVersion { param($Path)
    $script:queried += $Path
    if ($Path -eq 'cannot-start') { throw 'Failed to start' }
    if ($Path -eq 'old') { return '7.2.0' }
    if ($Path -eq 'preview') { return '7.7.0-preview.1' }
    return '7.6.6'
}
$result = Get-Ds1PowerShell -WarningVariable diagnostics -WarningAction SilentlyContinue
Assert ($result.Path -eq 'working-install') 'Unreadable alias blocked valid install'
Assert ($script:queried -notcontains 'inaccessible-alias') 'Unverified alias was executed'
Assert (($diagnostics | Out-String) -match 'inaccessible-alias') 'Failed candidate path was not logged'
$script:candidates = @('missing','path-access-denied','unsigned','other-signer','cannot-start','old','preview','working-install')
$script:queried = @()
$result = Get-Ds1PowerShell -WarningAction SilentlyContinue
Assert ($result.Path -eq 'working-install') 'Other invalid candidates blocked discovery'
Assert ($script:queried -notcontains 'unsigned' -and $script:queried -notcontains 'other-signer') 'Invalid signature was executed'
$script:candidates = @('inaccessible-alias')
$result = Get-Ds1PowerShell -WarningAction SilentlyContinue
Assert ($null -eq $result) 'Only unreadable candidate should return no compatible runtime'
$script:candidates = @()
Assert ($null -eq (Get-Ds1PowerShell)) 'Empty discovery should return null'
Write-Host "PASS: $count discovery checks (mocked Windows boundaries)."
