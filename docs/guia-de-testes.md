# Guia de testes de validação

Este roteiro valida a implementação disponível. Use **Windows 11 x64 em uma VM com checkpoint** para as etapas que podem instalar PowerShell 7 ou habilitar recursos do Windows. Registre a revisão testada, a configuração inicial e as escolhas em cada prompt. Testes com mocks em CI não substituem o teste de UAC, MSI, WSL2 e terminal no Windows.

## 1. Contrato automatizado, sem instalação

No diretório raiz de uma cópia do repositório, execute em **Windows PowerShell 5.1**:

```powershell
$PSVersionTable.PSVersion.ToString()
git rev-parse HEAD
.\tests\bootstrap.tests.ps1
.\tests\bootstrap-handoff.tests.ps1
.\tests\bootstrap-discovery.tests.ps1
```

Esses testes importam somente funções do bootstrap, usam mocks de rede/instalador e criam um processo filho que falha de propósito. Esperado: `PASS: 17`, `PASS: 11` e `PASS: 7`, sem UAC e sem instalação. Se `git` não existir, registre a revisão pela URL/commit usado para obter os arquivos.

No **PowerShell 7**, na mesma revisão, execute:

```powershell
pwsh -NoProfile -File .\tests\runbooks.tests.ps1
pwsh -NoProfile -File .\tests\preflight.tests.ps1
pwsh -NoProfile -File .\tests\task-phases.tests.ps1
pwsh -NoProfile -File .\tests\bootstrap.tests.ps1
pwsh -NoProfile -File .\tests\bootstrap-handoff.tests.ps1
pwsh -NoProfile -File .\tests\bootstrap-discovery.tests.ps1
```

Esperado: `PASS: 49`, `PASS: 13`, `PASS: 11`, `PASS: 17`, `PASS: 11`, `PASS: 7`. O workflow **Runbook contract** executa o contrato em Windows e Ubuntu; os testes PS5.1 somente no Windows. Confira que todos os jobs estão verdes na revisão testada. Uma falha do CI ou desses comandos bloqueia a próxima etapa de homologação.

## 2. Ambiente parcialmente preparado: começar pelo PS5.1

Faça um checkpoint da VM e registre: `winver`, `$PSVersionTable.PSVersion`, `whoami /user`, `Get-Command pwsh,winget -ErrorAction SilentlyContinue`, `wsl.exe --list --verbose` (pode falhar se WSL não existir) e se a sessão já está elevada. Abra um **Windows PowerShell 5.1 não elevado** com a mesma conta que receberá WSL/perfis.

Se já há checkout local da revisão sob teste, na raiz:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Para reproduzir o fluxo remoto usado no primeiro teste de campo:

```powershell
irm https://raw.githubusercontent.com/ds1david/ds1dev-setup-utility/main/bootstrap.ps1 | iex
```

`main` pode mudar; anote o commit mostrado como `Pacote fonte` e a hora do teste. Para fixar uma revisão antes do handoff remoto, substitua o valor de `$revision` pelo SHA de 40 caracteres já revisado:

```powershell
$revision = 'COLE_AQUI_O_SHA_DE_40_CARACTERES'
$url = "https://raw.githubusercontent.com/ds1david/ds1dev-setup-utility/$revision/bootstrap.ps1"
$script = irm $url
& ([scriptblock]::Create([string]$script)) -SourceCommit $revision
```

Observe: prompt de elevação, UAC, mesma identidade Windows, descoberta de PS7, consentimento separado para instalar PS7 caso falte, e consentimento para baixar snapshot se a entrada foi remota. Em máquina parcialmente pronta, PS7 compatível deve ser reutilizado; não deve haver reinstalação. Se houver falha elevada, copie o texto exibido e o caminho de `elevation-error.log`; `bootstrap.log` fica no staging informado pelo bootstrap. Um código 1 sem causa exibida reproduz o defeito anterior e deve ser registrado.

## 3. Diagnóstico do preflight e da TUI

Em **PS7 elevado**, na raiz do mesmo checkout, rode primeiro os modos de diagnóstico:

```powershell
pwsh -NoProfile -File .\src\ds1-setup.ps1 -Task prerequisites
pwsh -NoProfile -File .\src\ds1-setup.ps1 -Task prerequisites -Plan
```

Esperado: cada cheque de host, arquitetura, administrador, versão de PS, virtualização e recursos WSL2 aparece com motivo. Esses comandos não aplicam correções, mas registram transcript, observações e eventos em `%ProgramData%\DS1DevSetup\logs` e podem oferecer exportação dos logs ao encerrar. Se Windows ou virtualização não puderem ser corrigidos pelo aplicativo, registre a pendência e não marque o gate como satisfeito.

Depois, entre pela TUI com `pwsh -NoProfile -File .\src\ds1-setup.ps1` em terminal interativo de ao menos 80 colunas por 24 linhas. O preflight inicial pode pedir autorização **por correção** para habilitar recursos opcionais WSL2; a operação altera o Windows e pode exigir reinício. Teste separadamente em checkpoints da VM:

| Cenário | Resultado esperado |
|---|---|
| Recusar uma vez, depois aceitar | A pendência é explicada, a autorização é repetida, a correção é tentada e revalidada. |
| Recusar duas vezes | A sessão aborta, sem liberar outros runbooks ou alterar o recurso recusado. |
| Autorizar recurso desativado | O comando e resultado aparecem no log; reinício pendente impede liberar o restante até reiniciar e revalidar. |
| Todos os requisitos satisfeitos | Aparecem categorias à esquerda, itens à direita e comandos abaixo; Tab, setas, Enter, V, P, L, R, / e Q funcionam. |
| Tarefa histórica sem Apply | Deve permanecer identificada como planejada; não declara instalação concluída. |

Na saída interativa escolha `s` para exportar logs e uma pasta de teste com espaços no nome; confira um `run-*.log` e um `commands-*.jsonl` legíveis. Teste também `n`: os originais permanecem no ProgramData. Cuidado ao compartilhar logs: transcript pode conter caminhos e dados da conta.

## 4. Instalação limpa em VM descartável

Prepare Windows 11 x64 com PS5.1 nativo, sem PS7, WinGet, Git, WSL ou MSYS2 como dependências **do teste**. Registre build, arquitetura, conta, UAC e virtualização de firmware; preserve um checkpoint antes de iniciar. Use a entrada remota com commit fixado do item 2 no PS5.1 não elevado. Autorize UAC e, somente depois de revisar origem e hash, a instalação do MSI oficial proposta no prompt. Autorize separadamente o snapshot e as correções WSL2 do preflight. A entrada por arquivo local é alternativa quando os arquivos já foram transferidos para a VM.

Aceite inicial: PS7 instalado e validado sem WinGet; bootstrap continua no PS7 elevado sob a mesma conta; preflight comunica pendências e bloqueia runbooks até conformidade; após reinício manual, execute novamente e verifique que PS7 e recursos já conformes não são reinstalados. Repita também a recusa de UAC, de MSI e do snapshot restaurando o checkpoint entre casos. Não use uma VM de trabalho para provocar falha deliberada de instalação.

## 5. Evidências e limites

Para cada execução registre: SHA, versão/build Windows, PS inicial/final, nível administrativo, estado anterior/posterior de cada requisito, respostas dadas, código de saída, reinício, `bootstrap.log`/`elevation-error.log`, transcript `run-*.log` e eventos `commands-*.jsonl`. A ausência de mudança após a segunda execução é evidência de idempotência somente das correções já implementadas.

O YAML v2, perfis de distribuição/versões e script runner por interpretador são **especificações**, ainda sem executor. Java, Maven, Gradle, Python, imagens WSL selecionáveis, MSYS2 e os demais runbooks históricos ainda não têm instalação homologada; não marque esses cenários como validados pelo menu atual. Consulte [o plano](plano-de-execucao.md) para os critérios futuros e [a validação integrada](07-validacao.md) para o aceite completo por ambiente.
