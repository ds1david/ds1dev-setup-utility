Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RunbookCatalog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)
    $rootPath = (Resolve-Path -LiteralPath $Root).ProviderPath
    $tasks = @()
    $ids = @{}
    foreach ($file in Get-ChildItem -LiteralPath $rootPath -Filter 'runbook.psd1' -File -Recurse | Sort-Object FullName) {
        $data = Import-PowerShellDataFile -LiteralPath $file.FullName
        foreach ($key in 'SchemaVersion','Id','Title','Environment','DependsOn','Script','Implemented','SupportsVersions') {
            if (-not $data.ContainsKey($key)) { throw "Manifesto $($file.FullName): falta $key" }
        }
        if ($data.SchemaVersion -ne 1) { throw "SchemaVersion incompatível: $($file.FullName)" }
        if ($data.Id -isnot [string] -or $data.Id -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') { throw 'Id inválido.' }
        if ($ids.ContainsKey($data.Id)) { throw "Id duplicado: $($data.Id)" }
        if ($data.Title -isnot [string] -or [string]::IsNullOrWhiteSpace($data.Title)) { throw 'Title inválido.' }
        if (-not $data.ContainsKey('Category')) { $data.Category = 'Outros' }
        if ($data.Category -isnot [string] -or [string]::IsNullOrWhiteSpace($data.Category)) { throw 'Category inválida.' }
        if ($data.Environment -notin 'Windows','Ubuntu','MSYS2','Integrated') { throw 'Environment inválido.' }
        if ($data.Implemented -isnot [bool] -or $data.SupportsVersions -isnot [bool]) { throw 'Flags devem ser booleanas.' }
        if ($data.DependsOn -isnot [array]) { throw 'DependsOn deve ser um array.' }
        if ($data.Script -isnot [string] -or [string]::IsNullOrWhiteSpace($data.Script) -or [IO.Path]::IsPathRooted($data.Script)) { throw 'Script deve ser um caminho relativo.' }
        $scriptPath = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $data.Script))
        $prefix = $file.DirectoryName + [IO.Path]::DirectorySeparatorChar
        $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
        if (-not $scriptPath.StartsWith($prefix, $comparison) -or [IO.Path]::GetExtension($scriptPath) -ne '.ps1' -or -not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Script inválido ou fora da pasta do runbook: $($data.Id)" }
        $data.ScriptPath = $scriptPath
        $data.ManifestPath = $file.FullName
        $ids[$data.Id] = $data
        $tasks += $data
    }
    foreach ($task in $tasks) {
        foreach ($dependency in $task.DependsOn) {
            if ($dependency -isnot [string] -or -not $ids.ContainsKey($dependency)) { throw "Dependência desconhecida em $($task.Id): $dependency" }
        }
    }
    # Percurso em profundidade: rejeitar ciclos antes de chamar qualquer script.
    $visiting = @{}; $visited = @{}
    function Visit-Runbook([string]$Id) {
        if ($visiting.ContainsKey($Id)) { throw "Ciclo de dependências: $Id" }
        if ($visited.ContainsKey($Id)) { return }
        $visiting[$Id] = $true
        foreach ($dependency in $ids[$Id].DependsOn) { Visit-Runbook $dependency }
        $visiting.Remove($Id)
        $visited[$Id] = $true
    }
    foreach ($task in $tasks) { Visit-Runbook $task.Id }
    return $tasks | Sort-Object Id
}

function Invoke-RunbookHandler {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Runbook,
          [ValidateSet('Test','Plan','Apply')][string]$Mode = 'Test',
          [string]$Version = '', [hashtable]$Context = @{})
    if ($Version -and -not $Runbook.SupportsVersions) { throw "Runbook $($Runbook.Id) não suporta versão explícita." }
    if ($Mode -eq 'Apply' -and -not $Runbook.Implemented) { throw "Aplicação ainda não implementada: $($Runbook.Id)" }
    # stdout fica reservado ao resultado estruturado. Mensagens usam Write-Host/Warning/Error.
    $output = @(& $Runbook.ScriptPath -Mode $Mode -Version $Version -Context $Context)
    if ($output.Count -ne 1 -or $output[0] -isnot [hashtable]) { throw "Runbook $($Runbook.Id) deve retornar um único hashtable." }
    $result = $output[0]
    if (-not $result.ContainsKey('Succeeded') -or $result.Succeeded -isnot [bool]) { throw 'Resultado deve conter Succeeded booleano.' }
    if (-not $result.Succeeded) { throw "Runbook falhou: $($Runbook.Id) ($Mode)" }
    if ($Mode -eq 'Test' -and (-not $result.ContainsKey('Detected') -or $result.Detected -isnot [bool])) { throw 'Test deve retornar Detected booleano.' }
    return $result
}

function Test-RunbookDependencies {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Runbook, [Parameter(Mandatory)][array]$Catalog)
    $byId = @{}; foreach ($task in $Catalog) { $byId[$task.Id] = $task }
    if ($Runbook.Id -ne 'prerequisites') {
        if (-not $byId.ContainsKey('prerequisites')) { throw 'Runbook prerequisites ausente; execução bloqueada.' }
        $preflight = Invoke-RunbookHandler -Runbook $byId['prerequisites'] -Mode Test
        if (-not $preflight.Detected) { throw 'Pré-requisitos Windows pendentes; execução bloqueada.' }
    }
    $checked = @{}
    function Test-Dependency([string]$Id) {
        if ($checked.ContainsKey($Id)) { return }
        if (-not $byId.ContainsKey($Id)) { throw "Dependência desconhecida: $Id" }
        foreach ($parent in $byId[$Id].DependsOn) { Test-Dependency $parent }
        $result = Invoke-RunbookHandler -Runbook $byId[$Id] -Mode Test
        if (-not $result.Detected) { throw "Dependência não satisfeita: $Id" }
        $checked[$Id] = $true
    }
    foreach ($dependency in $Runbook.DependsOn) { Test-Dependency $dependency }
}

Export-ModuleMember -Function Get-RunbookCatalog,Invoke-RunbookHandler,Test-RunbookDependencies
