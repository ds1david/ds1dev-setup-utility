Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Test-Ds1Terminal {
    try { return (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and
        [Console]::WindowWidth -ge 80 -and [Console]::WindowHeight -ge 24) }
    catch { return $false }
}
function Write-Ds1Frame([array]$Tasks,[array]$Categories,[int]$CategoryIndex,[int]$Selected,
                       [bool]$CategoriesFocused,[string]$Query,[hashtable]$Versions,[scriptblock]$Status) {
    $width=[Console]::WindowWidth; $height=[Console]::WindowHeight
    $left=[Math]::Min(27,[Math]::Max(21,[int]($width*.24)))
    $rightX=$left+2; $rightWidth=$width-$rightX-1; $footerY=$height-6
    [Console]::Clear()
    function Put([int]$x,[int]$y,[string]$value,[ConsoleColor]$color='Gray') {
        if($y -ge [Console]::WindowHeight -or $x -ge [Console]::WindowWidth){return}
        [Console]::SetCursorPosition($x,$y)
        $old=[Console]::ForegroundColor;[Console]::ForegroundColor=$color
        [Console]::Write($value.Substring(0,[Math]::Min($value.Length,[Console]::WindowWidth-$x)))
        [Console]::ForegroundColor=$old
    }
    function Box([int]$x,[int]$y,[int]$w,[int]$h,[string]$label) {
        Put $x $y ('+'+('-'*($w-2))+'+')
        for($i=1;$i -lt $h-1;$i++){Put $x ($y+$i) '|';Put ($x+$w-1) ($y+$i) '|'}
        Put $x ($y+$h-1) ('+'+('-'*($w-2))+'+')
        Put ($x+2) $y (' '+$label+' ') 'Yellow'
    }
    Put 2 0 'DS1 DEV SETUP | Catálogo dinâmico' 'Cyan'
    Put 2 1 ('Busca: '+$(if($Query){$Query}else{'[/] digite para filtrar'}))
    Put 2 3 'Windows • WSL2 • MSYS2' 'Cyan'
    Box 0 5 $left ([Math]::Min($footerY-6,$Categories.Count+3)) 'CATEGORIAS'
    for($i=0;$i -lt $Categories.Count;$i++){
        Put 2 (6+$i) ($(if($i -eq $CategoryIndex){'> '}else{'  '})+$Categories[$i]) $(if($i -eq $CategoryIndex -and $CategoriesFocused){'Cyan'}else{'Yellow'})
    }
    Box $rightX 3 $rightWidth ($footerY-3) 'ITENS DE CONFIGURAÇÃO'
    Box 0 $footerY $width 6 'COMANDOS DE NAVEGAÇÃO'
    Put 2 ($footerY+1) '[Tab] trocar painel    [Up/Down] navegar    [Enter] verificar'
    Put 2 ($footerY+2) '[/] buscar            [E] escolher versão   [P] planejar'
    Put 2 ($footerY+3) '[V] verificar  [A] aplicar  [L] logs  [R] recarregar  [Q] sair' 'Yellow'
    $visible=[Math]::Max(1,$footerY-6);$start=[Math]::Max(0,$Selected-$visible+1)
    if($Selected -lt $visible){$start=0}
    for($i=$start;$i -lt [Math]::Min($Tasks.Count,$start+$visible);$i++){
        $task=$Tasks[$i]
        Put ($rightX+2) (5+$i-$start) ('  '+$task.Title+' - verificando...') 'Yellow'
        $state=& $Status $task.Id
        $requested=if($Versions.ContainsKey($task.Id)){" v$($Versions[$task.Id])"}else{''}
        $line=('{0}{1,-27} {2}{3}' -f $(if($i -eq $Selected){'> '}else{'  '}),$task.Title,$state,$requested)
        Put ($rightX+2) (5+$i-$start) ($line.PadRight([Math]::Max($line.Length,$rightWidth-4))) $(if($i -eq $Selected -and -not $CategoriesFocused){'Cyan'}elseif($state -like 'Blocked*'){'Yellow'}else{'Gray'})
    }
    if($Tasks.Count -eq 0){Put ($rightX+2) 5 'Nenhum runbook nesta categoria/busca.' 'Yellow'}
}
function Show-Ds1Modal([string]$Title,[string[]]$Lines,[string]$Prompt='Pressione Enter para voltar') {
    Write-Host ''
    Write-Host ('+--- '+$Title+' '+('-'*[Math]::Max(0,60-$Title.Length))+'+') -ForegroundColor Yellow
    foreach($line in $Lines){Write-Host ('| '+$line)}
    Write-Host ('+----------------------------------------------------------------+') -ForegroundColor Yellow
    return (Read-Host $Prompt)
}
function Start-Ds1Tui([array]$Catalog,[scriptblock]$Status,[scriptblock]$Execute,
                      [scriptblock]$Reload,[scriptblock]$Logs = {}) {
    if(-not(Test-Ds1Terminal)){return $false}
    $oldColor=[Console]::ForegroundColor;$selected=0;$categoryIndex=0;$categoriesFocused=$false
    $query='';$versions=@{}
    try {
        while($true){
            $categories=@('Todos')+@($Catalog|ForEach-Object Category|Sort-Object -Unique)
            if($categoryIndex -ge $categories.Count){$categoryIndex=0}
            $tasks=@($Catalog|Where-Object {
                ($categoryIndex -eq 0 -or $_.Category -eq $categories[$categoryIndex]) -and
                (-not $query -or $_.Title -like "*$query*" -or $_.Id -like "*$query*")
            })
            if($selected -ge $tasks.Count){$selected=[Math]::Max(0,$tasks.Count-1)}
            Write-Ds1Frame $tasks $categories $categoryIndex $selected $categoriesFocused $query $versions $Status
            $key=[Console]::ReadKey($true).Key
            switch($key){
                'Tab' {$categoriesFocused=-not $categoriesFocused}
                'UpArrow' {if($categoriesFocused){$categoryIndex=[Math]::Max(0,$categoryIndex-1);$selected=0}else{$selected=[Math]::Max(0,$selected-1)}}
                'DownArrow' {if($categoriesFocused){$categoryIndex=[Math]::Min($categories.Count-1,$categoryIndex+1);$selected=0}else{$selected=[Math]::Min($tasks.Count-1,$selected+1)}}
                'Q' {return $true}
                'R' {$Catalog=@(& $Reload);$categoryIndex=0;$selected=0;$query=''}
                'Oem2' { [Console]::Clear();$query=(Read-Host 'Buscar por título ou ID').Trim();$selected=0 }
                {$_ -in 'Enter','V','P','A','E','L'} {
                    if($tasks.Count -eq 0){continue}
                    $task=$tasks[$selected];$mode=switch($key){'P'{'Plan'}'A'{'Apply'}'V'{'Test'}default{'Test'}}
                    [Console]::Clear();Write-Host "[$($task.Id)] $($task.Title) | $mode" -ForegroundColor Cyan
                    try {
                        if($key -eq 'L') { & $Logs $task.Id }
                        elseif($key -eq 'E'){
                            if(-not $task.SupportsVersions){Write-Host 'Este runbook não admite versão explícita.'}
                            else {$inputVersion=Read-Host 'Versão desejada (vazio = padrão)';if($inputVersion){$versions[$task.Id]=$inputVersion}else{$null=$versions.Remove($task.Id)}}
                        }elseif($key -eq 'A'){
                            $answer=Show-Ds1Modal 'CONFIRMAR EXECUÇÃO' @("Tarefa: $($task.Title)",'O plano será verificado antes da aplicação.') 'Autoriza aplicar? [s/N]'
                            if($answer -notin @('s','S','sim','SIM')){Write-Host 'Aplicação cancelada.'}
                            else{& $Execute $task.Id $mode $(if($versions.ContainsKey($task.Id)){$versions[$task.Id]}else{''})}
                        }else{& $Execute $task.Id $mode $(if($versions.ContainsKey($task.Id)){$versions[$task.Id]}else{''})}
                    }catch{
                        Write-Host "FALHA: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host 'Etapas e resultado dos comandos registrados:' -ForegroundColor Yellow
                        & $Logs $task.Id
                    }
                    $null=Read-Host 'Pressione Enter para voltar à lista (saída permanece no log)'
                }
            }
        }
    }finally{[Console]::ForegroundColor=$oldColor;try{[Console]::CursorVisible=$true}catch{}}
}
Export-ModuleMember -Function Test-Ds1Terminal,Show-Ds1Modal,Start-Ds1Tui
