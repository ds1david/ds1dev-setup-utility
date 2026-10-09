# Runbooks descobertos dinamicamente

A TUI lê recursivamente `runbooks/**/runbook.psd1`. Não há lista de IDs nem detectores específicos na interface. Para adicionar uma tarefa, publique uma pasta com manifesto e script; não altere `src/ds1-setup.ps1` nem o antigo `config/catalog.psd1`.

## Adicionar um runbook

Crie `runbooks/minha-tarefa/runbook.psd1`:

```powershell
@{
    SchemaVersion = 1
    Id = 'minha-tarefa'
    Title = 'Minha tarefa Windows'
    Category = 'Aplicativos'
    Environment = 'Windows' # Windows, Ubuntu, MSYS2 ou Integrated
    DependsOn = @('02')
    Script = 'runbook.ps1'  # Relativo à pasta deste manifesto
    Implemented = $false   # Habilitar Apply somente após implementar e testar
    SupportsVersions = $false
}
```

Crie o script correspondente:

```powershell
[CmdletBinding()]
param(
    [ValidateSet('Test','Plan','Apply')][string]$Mode = 'Test',
    [string]$Version = '',
    [hashtable]$Context = @{}
)
$ErrorActionPreference = 'Stop'

if ($Mode -eq 'Test') {
    # Substitua pela verificação real do estado desejado.
    return @{ Succeeded = $true; Detected = $false }
}
if ($Mode -eq 'Plan') {
    Write-Host 'Instalador ainda não implementado.'
    return @{ Succeeded = $true; Changes = @(); Implemented = $false }
}
throw 'Implementar Apply idempotente antes de habilitá-lo no manifesto.'
```

Após atualizar a cópia local do repositório, abra o utilitário ou pressione **R — Recarregar runbooks locais**. O novo item aparecerá pelo título e ID declarados. Também funciona na CLI:

```powershell
.\src\ds1-setup.ps1 -List
.\src\ds1-setup.ps1 -Task minha-tarefa -Plan
.\src\ds1-setup.ps1 -Task minha-tarefa -Apply
```

O último comando será bloqueado enquanto `Implemented` for falso.

## Contrato de execução

| Modo | Responsabilidade do script | Resultado obrigatório |
|---|---|---|
| Test | Observar o estado real, sem instalar ou configurar | `@{ Succeeded=$true; Detected=<booleano> }` |
| Plan | Mostrar as alterações previstas, sem aplicá-las | `@{ Succeeded=$true; Changes=@(...) }` |
| Apply | Revalidar o estado e aplicar apenas as diferenças | `@{ Succeeded=$true; ... }` |

Cada chamada deve retornar **um único hashtable** pelo fluxo de sucesso. Use `Write-Host`, `Write-Warning` e erros para mensagens visíveis; comandos que retornam dados devem ter sua saída capturada e exibida explicitamente, sem contaminar o objeto de resultado. Falhas de comandos nativos exigem verificar `$LASTEXITCODE` e lançar erro. `Succeeded=$false` também é tratado como falha.

A interface verifica os pré-requisitos globais e as dependências transitivas antes de Test/Plan/Apply; não instala dependências automaticamente. O runbook `prerequisites` continua disponível para diagnosticar o host quando o gate está bloqueado. Após Apply, o executor exige uma nova detecção bem-sucedida e registra uma execução em `%ProgramData%\DS1DevSetup\state`, identificada por ambiente, tarefa e execução. O histórico não substitui a detecção real.

`Version` é encaminhada ao script quando `SupportsVersions=$true`. Nesse caso, o autor deve implementar instalação **e detecção da versão exata**. O motor não conhece Java, Maven ou qualquer outra ferramenta. `Context` fornece `RunId`, `LogPath`, `StateHome` e `Environment`. Os scripts Windows podem chamar WSL ou MSYS2, inicializando explicitamente o ambiente de destino; o manifesto não realiza esse roteamento por si só.

## Descoberta e atualização

- A descoberta ocorre no início e ao pressionar R. Ela não baixa código automaticamente enquanto o menu está aberto.
- Um push ao GitHub só passa a aparecer depois de atualizar a cópia local, ou iniciar novamente pelo bootstrap remoto que baixa o pacote.
- Manifestos com campos obrigatórios ausentes, IDs duplicados, dependências desconhecidas, ciclos ou script fora da própria pasta são rejeitados antes da execução.
- O manifesto é importado como dados PowerShell. Não há interpretação automática dos comandos Markdown da wiki: documentação explica e o script executa.
- Runbooks são código administrativo do repositório. Este contrato não é uma sandbox nem uma garantia automática de idempotência; cada script precisa ser revisado e testado.

## Limites da migração atual

As dez tarefas históricas foram convertidas para manifestos e handlers individuais, preservando `Implemented=$false`. Seus detectores continuam parciais e não homologam a instalação completa. O executor aceita Apply de novos runbooks implementados, mas os instaladores históricos ainda não existem.

O log continua baseado em `Start-Transcript`. A captura integral, em tempo real, de stdout/stderr de todos os subprocessos ainda precisa de um executor de processos próprio. Recarregar runbooks não resolve essa limitação.

## Testes

Sem instalar módulos adicionais:

```powershell
pwsh -NoProfile -File .\tests\runbooks.tests.ps1
pwsh -NoProfile -File .\tests\preflight.tests.ps1
```

O teste adiciona um segundo runbook em uma pasta temporária e verifica descoberta, execução e passagem de versão sem mudanças na interface. Também cobre dependências ausentes, ciclos, duplicações, caminhos inválidos, resultados inválidos e bloqueios de Apply. Não instala ferramentas no host.

[Índice](01-indice.md) · [Arquitetura do executor](arquitetura-executor.md)

## Gate global de pré-requisitos — primeira implementação

`runbooks/prerequisites` é executado automaticamente na entrada. Sua sequência observa privilégios administrativos, PowerShell 7.4+, Windows 11 x64, virtualização para WSL2 e estados dos recursos opcionais WSL/VirtualMachinePlatform. As outras tarefas são bloqueadas pelo motor mesmo quando adicionadas dinamicamente sem `DependsOn` explícito. O próprio runbook pode ser consultado por Test/Plan.

Para uma pendência reparável (`Disabled` em um dos dois recursos opcionais), o motor apresenta o comando e pede autorização para aquela etapa. Uma recusa gera explicação e segunda oportunidade. Duas recusas encerram a sessão antes de outro runbook. `Enable-WindowsOptionalFeature -All -NoRestart` é a única operação implementada neste runbook; exige consentimento. Após Apply, a etapa é verificada outra vez; se houver reinício pendente, a execução para até novo diagnóstico. UAC, versão PS7, BIOS/UEFI e Windows incompatível devem ser resolvidos fora deste runbook (bootstrap ou ação manual) e são mostrados como bloqueios.

Esta é uma política global expressa pelo usuário, inclusive para tarefas Windows que não usam WSL2. Distro Ubuntu e MSYS2 permanecem dependências específicas dos seus próprios runbooks. O preflight não instala uma distribuição Ubuntu nem altera BCD/BIOS. A validação real do DISM/Windows está pendente; testes automatizados usam sondagens simuladas e não alteram o host.

A TUI PowerShell 7 atual permite Tab e setas para categorias/tarefas, `/` para busca, E para versão, V/P/A e modal de confirmação, além de fallback linear em terminal incompatível. A TUI Rust planejada continua em M10. O `Start-Transcript` ainda não substitui o executor de stdout/stderr nativo previsto em M2.
