# Runbooks descobertos dinamicamente

Este documento descreve o contrato **PSD1/PowerShell v1 em execução**. O [modelo YAML v2](modelo-runbooks-v2.md) é uma proposta de migração; arquivos YAML ainda não são interpretados pelo app.

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

## Fases, estados e logs da primeira implementação

Cada runbook é uma tarefa. A checagem (`Test`) informa **Satisfeito**, **Requerido** ou **Parcial** quando o resultado possui uma lista `Checks` com itens satisfeitos e pendentes. Handlers antigos com apenas `Detected` são mapeados para Satisfeito/Requerido; não ganham checagens granulares fictícias. Tarefas ainda não implementadas indicam `(planejado)`.

Antes de Apply, o motor reexecuta Test. Se estiver conforme, termina como NoOp sem chamar Apply. Caso contrário, executa o handler e só registra **Satisfeito** após um Test posterior bem-sucedido; falhas são marcadas **Erro**. O runbook `prerequisites` é a primeira lista detalhada: host, arquitetura, administrador, PowerShell, virtualização e dois recursos opcionais Windows. Cada correção autorizada tem ID próprio, comando exibível, início e resultado gravados. O handler continua responsável pela idempotência interna quando a tarefa contém mais de uma operação.

Use `Write-Ds1PhaseEvent` para registrar checagens e `Invoke-Ds1LoggedAction` para operações de novos handlers: o segundo exige o texto seguro do comando e uma descrição explícita do resultado ou erro. Nunca incluir tokens, senhas ou argumentos sigilosos. O caminho JSONL é fornecido em `Context.CommandLogPath`. Os registros incluem data, tarefa, etapa, fase, estado, comando e resultado. O log de transcrição da sessão é separado e ainda não captura fielmente stdout/stderr de todos os executáveis nativos.

### Vistas futuras da TUI e seleção de steps (ainda não implementadas)

O catálogo dinâmico atual será mantido. Na futura TUI Rust, o catálogo global continua com categorias e runbooks (aprox. 23/77); ao **abrir um runbook**, uma vista de três zonas apresenta **passos à esquerda (40%)**, **detalhes e logs à direita (60%)** e **prompt/status/atalhos abaixo**. O tema DS1 Modern Terminal usa painéis arredondados quando compatíveis, foco violeta, checkbox ciano, spinner azul-ciano e fallback ANSI/ASCII. Ver [contrato completo](tui-windows.md#design-system-ds1-modern-terminal--catálogo-e-execução).

Na lista, `❯` marca o **cursor**, `[x]` indica **seleção**, e `✔/⠋/?/○/✖` representa estado real; selecionar não é instalar. `↑/↓` ou `j/k` navegam, Espaço marca, `a` altera apenas os elegíveis do filtro, `p` mostra o plano, `L` abre logs e `Enter` abre detalhes. **Enter nunca chama Apply diretamente.** A ação mutável exige plano revalidado e confirmação posterior, com Cancelar como padrão. A seleção por IDs persiste ao filtrar/reordenar/rolar; dependências são exibidas sem serem instaladas silenciosamente. A barra inferior protege o prompt enquanto os logs e os indicadores progridem.

**Granularidade honesta:** runbooks PSD1 v1 que executam um único handler opaco não oferecem automaticamente passos internos. Para eles, a vista mostra **uma unidade de execução**; lista detalhada de cinco steps só existe se o motor expuser checks/ações instrumentadas ou quando os steps YAML v2 forem declarados e suportados. Nenhum mockup, listagem ou ícone prova que uma etapa foi executada. Este bloco é documentação de **comportamento pretendido**, não do menu PowerShell atualmente entregue.
### Indicador visual de execução (especificado, pendente de implementação)

A interface deverá usar a **mesma linha** para aguardar consentimento (`? Executar ... [s/N]`), animar uma operação ativa (`⠋ Executando ... (4s)`), mostrar verificação pendente e substituir o spinner por `✔ Concluído! (5.2s)` ou `✖ Falhou: <motivo> (1.1s)`. O spinner padrão tem quadros Braille, ciano preferencial `#00A3FF` e atualização nominal a cada 80–100 ms; timer e metadados ficam esmaecidos. Ação sem stdout ainda permanece visível enquanto o processo estiver realmente ativo. Em terminais limitados usar ASCII ou estado textual estático, sem poluir logs.

O motor identifica o comando por `runId/taskId/stepId/commandId` e informa transições reais; o renderer não deve deduzir vida do processo somente de stdout nem recorrer a `eval`. Uma etapa monolítica aparece como etapa inteira enquanto não existirem checkpoints internos. O catálogo/TUI PowerShell atual ainda **não implementa este comportamento**; ver [especificação visual](tui-windows.md#padrão-visual-de-execução--spinner-timer-e-transição-de-estados), [fase 002](../specs/002-safe-executor-contract/spec.md) e [runner fase 008](../specs/008-yaml-v2-runner/spec.md).

Na TUI, **L** abre as etapas da tarefa selecionada e uma falha mostra as etapas imediatamente. No menu linear, **L** solicita o ID da tarefa (vazio para todas). Ao sair de uma sessão interativa, o app pergunta se deseja copiar ambos os arquivos e solicita uma pasta; nunca sobrescreve arquivo existente nesse destino. Sem terminal interativo, não há prompt; os originais continuam em `%ProgramData%\DS1DevSetup\logs`. Validar conteúdos antes de compartilhar logs, inclusive a transcrição.
