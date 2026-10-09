#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InitiatingSid = '',
    [ValidatePattern('^$|^[0-9a-f]{40}$')][string]$SourceCommit = ''
)
$ErrorActionPreference = 'Stop'

function Test-Ds1Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Ds1UacEnabled {
    # UAC is an OS component, not an installable dependency.
    $policy = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop
    return ([int]$policy.EnableLUA -ne 0)
}

function ConvertTo-Ds1Literal([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}


function ConvertFrom-Ds1WebContent($Content) {
    if ($Content -is [byte[]]) {
        return ([Text.Encoding]::UTF8.GetString($Content)).TrimStart([char]0xFEFF)
    }
    if ($Content -is [string]) { return $Content.TrimStart([char]0xFEFF) }
    throw 'Resposta HTTP do bootstrap nao contem texto ou bytes UTF-8.'
}

function New-Ds1ElevationCommand([string]$Body, [string]$ErrorLog) {
    # This wrapper runs ONLY in the child process. Its exit must not close the caller.
    $template = @'
$ErrorActionPreference = 'Stop'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    __BODY__
} catch {
    $failure = $_
    $details = ($failure | Format-List * -Force | Out-String) + "`r`nScriptStackTrace:`r`n" + $failure.ScriptStackTrace
    try {
        Set-Content -LiteralPath __ERROR_LOG__ -Value $details -Encoding UTF8 -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine('Nao foi possivel gravar o diagnostico: ' + $_.Exception.Message)
    }
    [Console]::Error.WriteLine($details)
    [Console]::Error.WriteLine('Diagnostico da elevacao: ' + __ERROR_LOG__)
    # Write-Error with ErrorActionPreference=Stop would abort the catch before this pause.
    try { $null = Read-Host 'Falha no bootstrap. Pressione Enter para fechar e voltar ao terminal original' } catch { }
    exit 1
}
'@
    return $template.Replace('__BODY__', $Body).Replace('__ERROR_LOG__', (ConvertTo-Ds1Literal $ErrorLog))
}

function Get-Ds1NativeArchitecture {
    $arch = $env:PROCESSOR_ARCHITEW6432
    if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
    switch ($arch) {
        'AMD64' { return 'x64' }
        'ARM64' { return 'arm64' }
        default { throw "Arquitetura Windows nao suportada pelo bootstrap: $arch" }
    }
}

function Get-Ds1PowerShell {
    $candidates = @()
    # Prefer the current runtime if it is already PowerShell 7.
    if ($PSVersionTable.PSVersion.Major -eq 7) {
        $candidates += Join-Path $PSHOME 'pwsh.exe'
    }
    foreach ($root in @($env:ProgramW6432, $env:ProgramFiles, $env:LOCALAPPDATA)) {
        if ($root) {
            $candidates += Join-Path $root 'PowerShell\7\pwsh.exe'
            $candidates += Join-Path $root 'Microsoft\PowerShell\7\pwsh.exe'
        }
    }
    $candidates += @(Get-Command pwsh.exe -CommandType Application -All -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        # Do not execute an arbitrary pwsh.exe planted on PATH in an elevated process.
        $signature = Get-AuthenticodeSignature -LiteralPath $candidate
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') { continue }
        $versionOutput = & $candidate -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()'
        if ($LASTEXITCODE -ne 0) { continue }
        $versionText = ($versionOutput | Out-String).Trim()
        $version = $null
        if ([version]::TryParse($versionText, [ref]$version) -and $version.Major -eq 7 -and $version -ge [version]'7.4') {
            return [pscustomobject]@{ Path = $candidate; Version = $versionText }
        }
    }
    return $null
}

function New-Ds1Stage {
    $path = Join-Path $env:TEMP ('ds1dev-setup-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $path | Out-Null
    # Restrict administrative staging to the effective account and SYSTEM.
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    foreach ($identity in @($sid, (New-Object Security.Principal.SecurityIdentifier('S-1-5-18')))) {
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $path -AclObject $acl
    return $path
}

function Get-Ds1MsiRelease([string]$Architecture) {
    # Deliberately pinned. Update only with a reviewed bootstrap change.
    $version = '7.6.6'
    $name = "PowerShell-$version-win-$Architecture.msi"
    $base = "https://github.com/PowerShell/PowerShell/releases/download/v$version"
    return [pscustomobject]@{ Version = $version; Name = $name; Url = "$base/$name"; HashUrl = "$base/hashes.sha256" }
}

function Get-Ds1ExpectedHash([string]$Text, [string]$Name) {
    $hashes = @()
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*([0-9a-fA-F]{64})\s+\*?(.+?)\s*$') {
            if ($Matches[2] -ceq $Name) { $hashes += $Matches[1] }
        }
    }
    if ($hashes.Count -ne 1) { throw "Checksum ausente ou ambiguo para $Name." }
    return $hashes[0]
}

function Assert-Ds1InstallerExit([int]$Code) {
    if ($Code -eq 0) { return $false }
    if ($Code -eq 3010) { return $true }
    throw "Instalacao PowerShell falhou (msiexec exit code $Code). Consulte o log MSI."
}

function Install-Ds1PowerShell([string]$Stage, [string]$Architecture) {
    $release = Get-Ds1MsiRelease $Architecture
    Write-Host "PowerShell 7 compativel nao localizado (minimo 7.4 estavel, assinatura Microsoft)."
    Write-Host "Proposta: instalar PowerShell $($release.Version) $Architecture via MSI oficial, mantendo o Windows PowerShell 5.1."
    Write-Host "Origem: $($release.Url)"
    Write-Host 'Nao requer WinGet, Git, 7-Zip ou modulos adicionais.'
    $answer = Read-Host 'Autoriza baixar e instalar o PowerShell 7? [s/N]'
    if ($answer.Trim() -notin @('s', 'sim')) { throw 'Instalacao nao autorizada. Nenhum instalador executado.' }
    $msi = Join-Path $Stage $release.Name
    $hashFile = Join-Path $Stage 'hashes.sha256'
    Invoke-WebRequest -Uri $release.HashUrl -OutFile $hashFile -UseBasicParsing
    Invoke-WebRequest -Uri $release.Url -OutFile $msi -UseBasicParsing
    $expected = Get-Ds1ExpectedHash (Get-Content -LiteralPath $hashFile -Raw) $release.Name
    if ((Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash -ine $expected) { throw 'SHA-256 divergente; instalacao bloqueada.' }
    $signature = Get-AuthenticodeSignature -LiteralPath $msi
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') {
        throw 'Assinatura Microsoft do MSI invalida; instalacao bloqueada.'
    }
    $log = Join-Path $Stage 'powershell-install.log'
    $msiexec = Join-Path $env:WINDIR 'System32\msiexec.exe'
    $arguments = '/i "{0}" /qn /norestart /L*v "{1}" ADD_PATH=1 ENABLE_PSREMOTING=0' -f $msi, $log
    $process = Start-Process -FilePath $msiexec -ArgumentList $arguments -Wait -PassThru
    $reboot = Assert-Ds1InstallerExit $process.ExitCode
    if ($reboot) { Write-Warning 'Instalador solicita reinicializacao. Salve o trabalho e reinicie antes de continuar.' }
    return $reboot
}

function Resolve-Ds1SourceCommit {
    $response = Invoke-RestMethod -Uri 'https://api.github.com/repos/ds1david/ds1dev-setup-utility/commits/main' -Headers @{ 'User-Agent' = 'DS1DevSetup' }
    if ($response.sha -notmatch '^[0-9a-f]{40}$') { throw 'GitHub retornou uma revisao invalida.' }
    return $response.sha
}

function Invoke-Ds1Bootstrap([string]$LocalRoot, [string]$LocalScript) {
    if ($env:OS -ne 'Windows_NT') { throw 'O bootstrap requer Windows.' }
    # TLS 1.2 on stock Windows PowerShell; do not weaken certificate validation.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if ($InitiatingSid -and $InitiatingSid -ne $sid) {
        throw 'A elevacao usou outra conta Windows. Abra o terminal com a conta-alvo antes de configurar perfis ou WSL.'
    }
    $uac = Get-Ds1UacEnabled
    $admin = Test-Ds1Administrator
    Write-Host "UAC habilitado: $uac | Sessao administrativa: $admin"
    if (-not $uac) { Write-Warning 'UAC desabilitado por configuracao do Windows. O bootstrap nao altera essa politica.' }
    if (-not $admin) {
        if (-not $uac) { throw 'Sessao sem elevacao e UAC desabilitado. Solicite ao administrador uma sessao administrativa.' }
        $answer = Read-Host 'Autoriza abrir uma sessao administrativa? O Windows solicitara UAC. [s/N]'
        if ($answer.Trim() -notin @('s', 'sim')) { Write-Host 'Elevacao cancelada. Nenhuma instalacao executada.'; return }
        if ($LocalScript -and (Test-Path -LiteralPath $LocalScript)) {
            $command = '& ' + (ConvertTo-Ds1Literal $LocalScript) + ' -InitiatingSid ' + (ConvertTo-Ds1Literal $sid)
        } else {
            $commit = $SourceCommit
            if (-not $commit) { $commit = Resolve-Ds1SourceCommit }
            $url = "https://raw.githubusercontent.com/ds1david/ds1dev-setup-utility/$commit/bootstrap.ps1"
            # Include the decoder in the child before the downloaded bootstrap exists.
            $decoder = 'function ConvertFrom-Ds1WebContent { ' + ${function:ConvertFrom-Ds1WebContent}.ToString() + ' }; '
            $command = $decoder + '$response = Invoke-WebRequest -UseBasicParsing -Uri ' + (ConvertTo-Ds1Literal $url) + '; $code = ConvertFrom-Ds1WebContent $response.Content; & ([scriptblock]::Create($code)) -InitiatingSid ' + (ConvertTo-Ds1Literal $sid) + ' -SourceCommit ' + (ConvertTo-Ds1Literal $commit)
        }
        $handoff = New-Ds1Stage
        $errorLog = Join-Path $handoff 'elevation-error.log'
        Write-Host "Diagnostico em caso de falha na sessao elevada: $errorLog"
        $command = New-Ds1ElevationCommand -Body $command -ErrorLog $errorLog
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $shell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        try {
            $child = Start-Process -FilePath $shell -Verb RunAs -ArgumentList "-NoLogo -NoProfile -EncodedCommand $encoded" -Wait -PassThru
        } catch {
            throw "Elevacao nao concluida ou cancelada no UAC. Nenhuma instalacao iniciada por esta sessao. $($_.Exception.Message)"
        }
        if ($child.ExitCode -ne 0) {
            if (Test-Path -LiteralPath $errorLog -PathType Leaf) {
                Write-Host (Get-Content -LiteralPath $errorLog -Raw)
            }
            throw "Bootstrap elevado terminou com codigo $($child.ExitCode). Diagnostico: $errorLog"
        }
        return
    }
    $architecture = Get-Ds1NativeArchitecture
    $stage = New-Ds1Stage
    $transcribing = $false
    try {
        Start-Transcript -LiteralPath (Join-Path $stage 'bootstrap.log') | Out-Null
        $transcribing = $true
        $pwsh = Get-Ds1PowerShell
        if (-not $pwsh) {
            if (Install-Ds1PowerShell -Stage $stage -Architecture $architecture) { return }
            $pwsh = Get-Ds1PowerShell
            if (-not $pwsh) { throw 'Instalador terminou mas PS7 compativel nao foi localizado. Consulte o log; nao reinstale automaticamente.' }
        }
        Write-Host "Reutilizando PowerShell $($pwsh.Version): $($pwsh.Path)"
        $entry = $null
        if ($LocalRoot) {
            $candidate = Join-Path $LocalRoot 'src\ds1-setup.ps1'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $entry = $candidate }
        }
        if (-not $entry) {
            $commit = $SourceCommit
            if (-not $commit) { $commit = Resolve-Ds1SourceCommit }
            Write-Host "Pacote fonte: ds1david/ds1dev-setup-utility@$commit"
            Write-Warning 'O snapshot GitHub usa HTTPS e commit fixado, mas ainda nao e uma release assinada do DS1.'
            $answer = Read-Host 'Autoriza baixar e executar este snapshot do projeto? [s/N]'
            if ($answer.Trim() -notin @('s','sim')) { throw 'Download do projeto nao autorizado.' }
            $zip = Join-Path $stage 'source.zip'
            Invoke-WebRequest -Uri "https://github.com/ds1david/ds1dev-setup-utility/archive/$commit.zip" -OutFile $zip -UseBasicParsing
            Expand-Archive -LiteralPath $zip -DestinationPath $stage
            $entry = Join-Path $stage "ds1dev-setup-utility-$commit\src\ds1-setup.ps1"
            if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { throw 'Pacote incompleto: executor ausente.' }
        }
        & $pwsh.Path -NoLogo -NoProfile -File $entry
        if ($LASTEXITCODE -ne 0) { throw "Executor terminou com codigo $LASTEXITCODE." }
    } finally {
        if ($transcribing) { Stop-Transcript | Out-Null }
        Write-Host "Logs e staging preservados em: $stage"
    }
}

# Empty in irm | iex; never Join-Path an empty PSScriptRoot.
Invoke-Ds1Bootstrap -LocalRoot $PSScriptRoot -LocalScript $PSCommandPath
