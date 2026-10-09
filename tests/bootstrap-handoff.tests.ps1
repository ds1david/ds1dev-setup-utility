#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$path = Join-Path (Split-Path $PSScriptRoot -Parent) 'bootstrap.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($node in $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    . ([scriptblock]::Create($node.Extent.Text))
}
$count = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }; $script:count++
}
$source = "'bootstrap test'"
Assert ((ConvertFrom-Ds1WebContent $source) -ceq $source) 'Text response failed'
Assert ((ConvertFrom-Ds1WebContent ([Text.Encoding]::UTF8.GetBytes($source))) -ceq $source) 'Byte response failed'
Assert ((ConvertFrom-Ds1WebContent ([byte[]](@(239,187,191) + [Text.Encoding]::UTF8.GetBytes($source)))) -ceq $source) 'UTF8 BOM response failed'
$bad = $false
try { ConvertFrom-Ds1WebContent ([pscustomobject]@{ error = 'unexpected' }) } catch { $bad = $true }
Assert $bad 'Unexpected HTTP response accepted'
# Reproduce the remote handoff, including embedding the decoder into a fresh child.
$decoder = 'function ConvertFrom-Ds1WebContent { ' + ${function:ConvertFrom-Ds1WebContent}.ToString() + ' }; '
$probe = $decoder + '$code = ConvertFrom-Ds1WebContent ([Text.Encoding]::UTF8.GetBytes("param([string]`$Value); `$Value")); & ([scriptblock]::Create($code)) -Value decoded'
Assert ((& ([scriptblock]::Create($probe))) -eq 'decoded') 'Remote script decoding/invocation failed'

$root = Join-Path ([IO.Path]::GetTempPath()) ('ds1-handoff-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $log = Join-Path $root "failure with space and 'quote.log"
    $command = New-Ds1ElevationCommand -Body "throw 'DS1_HANDOFF_ROOT_CAUSE'" -ErrorLog $log
    $null = [Management.Automation.Language.Parser]::ParseInput($command, [ref]$tokens, [ref]$errors)
    Assert ($errors.Count -eq 0) 'Generated command is invalid'
    $shell = (Get-Process -Id $PID).Path
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    # NonInteractive makes the pause fail immediately; the catch must still preserve the error.
    $savedPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $shell -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $savedPreference
    Assert ($code -eq 1) 'Child did not return failure'
    Assert (Test-Path -LiteralPath $log) 'Error was not persisted'
    Assert ((Get-Content -LiteralPath $log -Raw) -match 'DS1_HANDOFF_ROOT_CAUSE') 'Original cause was lost'
    Assert (($output | Out-String) -match 'DS1_HANDOFF_ROOT_CAUSE') 'Cause was not displayed'
    # A logging failure must not obscure the original error.
    $command = New-Ds1ElevationCommand -Body "throw 'DS1_NO_LOG_ROOT_CAUSE'" -ErrorLog (Join-Path $root 'missing/failure.log')
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $ErrorActionPreference = 'Continue'
    $output = & $shell -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $savedPreference
    Assert ($code -eq 1 -and ($output | Out-String) -match 'DS1_NO_LOG_ROOT_CAUSE') 'Logging failure hid the cause'
} finally { Remove-Item -LiteralPath $root -Recurse -Force }
Write-Host "PASS: $count handoff checks (child process, no UAC or installation)."
