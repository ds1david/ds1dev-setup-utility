# Perfis de ambientes, imagens e versões compartilhadas — proposta v2

Estado: **modelo proposto; o executor atual ainda não interpreta estes arquivos**. Data: 2026-10-09.

[Contrato de runbooks v2](modelo-runbooks-v2.md) · [Plano](plano-de-execucao.md) · [Contrato atual](runbooks.md)

## Seleção expressa em YAML

Um perfil de execução YAML guarda as escolhas do usuário. O runbook YAML declara quais destinos e versões **sabe tratar**. O catálogo de compatibilidade do aplicativo informa quais imagens, intérpretes, provedores e versões foram **homologados**. Nenhuma dessas três fontes substitui uma checagem real da máquina.

Exemplo de intenção, **não executável na versão atual**:

```yaml
apiVersion: ds1.dev/profile/v1
kind: EnvironmentProfile
metadata:
  id: desenvolvimento
spec:
  requirements:
    host:
      powershell: {minimum: '7.4'}
      wsl: {major: 2}
      optionalFeatures:
        Microsoft-Windows-Subsystem-Linux: enabled
        VirtualMachinePlatform: enabled
  targets:
    - id: windows
      kind: windows
      identity: initiating-user
    - id: ubuntu
      kind: wsl
      selector:
        family: debian
        distribution: ubuntu
        release: "24.04"
        instance: Ubuntu-24.04
      provision:
        image: {catalog: ubuntu/24.04/x86_64}
        wslVersion: 2
        installRoot: 'D:\WSL\Ubuntu-24.04'
        linuxUser: dev
    - id: msys-ucrt
      kind: msys2
      selector:
        root: 'C:\msys64'
        msystem: UCRT64
        architecture: x86_64
      provision:
        image: {catalog: msys2/x86_64/stable}
  alignment:
    targets: [windows, ubuntu, msys-ucrt]
    mode: exact
    tools:
      python: {request: '3.12'}
      java: {request: '21', vendor: temurin}
      maven: {request: '3.9'}
      gradle: {request: '8'}
```

Os nomes `ubuntu/24.04/x86_64` e `msys2/x86_64/stable` são **chaves exemplificativas de catálogo**, não URLs nem artefatos prometidos. `requirements` admite estado ou versão exigida por item do checklist; o bootstrap mantém seus mínimos próprios e um perfil só pode exigir mais, nunca dispensá-los. `request` representa uma linha de versão desejada; o Plan deverá resolver uma versão concreta comum, ou bloquear. Não afirmar que a combinação do exemplo está disponível antes de consultar provedores e validar os três destinos.

## WSL: família, distribuição, release, imagem e instância

São cinco escolhas diferentes:

| Campo | Exemplo | Finalidade |
|---|---|---|
| `family` | `debian` | Selecionar o adaptador de pacotes e checagens da família. |
| `distribution` | `ubuntu` | Selecionar a distribuição concreta; não presumir que toda Debian é Ubuntu. |
| `release` | `24.04` | Versão do sistema operacional solicitada, distinta de WSL2 e das toolchains. |
| `provision.image` | `ubuntu/24.04/x86_64` | Escolher a imagem homologada, arquitetura, origem e método de instalação. |
| `instance` | `Ubuntu-24.04` | Nome da instância Windows registrada, que pode coexistir com outras imagens. |

O catálogo deve oferecer famílias candidatas **Debian/Ubuntu, Red Hat/Fedora, Arch, SUSE, Alpine e NixOS**, mas marcar cada distribuição/release/imagem como `supported`, `experimental`, `planned` ou `unavailable`. Apenas uma combinação `supported` e testada entra em Apply automático. Família não é prova de compatibilidade: Alpine tem ecossistema próprio, e NixOS exige adaptador declarativo específico. Red Hat/Fedora e SUSE também exigem provedores concretos por distribuição/release; não mapear tudo cegamente para um único comando de pacotes.

Para imagem listada por `wsl --list --online`, o provedor pode usar o identificador concreto retornado pela máquina. Para imagem homologada fora da lista, a instalação pode importar um TAR/artefato WSL com origem, digest e licença registrados. `wsl --import` cria instância com usuário inicial root, portanto o plano deve incluir criação/seleção do usuário Linux e verificação posterior. O nome da instância não valida o SO: após iniciar, conferir `/etc/os-release`, arquitetura, versão WSL2 e usuário efetivo. Nunca trocar, converter, apagar ou importar por cima de uma instância existente sem plano próprio e consentimento.

Na TUI, a seleção aparece como **família → distribuição → release → imagem/arquitetura → nome/local da instância → usuário**. Instância já existente pode ser adotada se as checagens corresponderem; caso contrário, mostrar conflito. Escolher apenas `family: debian` sem imagem concreta não autoriza instalação: o usuário ou um perfil homologado precisa fixar distribuição e release antes do Apply.

## MSYS2: instalação, ambiente e imagem

MSYS2 não tem distribuições Linux equivalentes a Ubuntu/Fedora. Suas escolhas são **raiz de instalação** (`C:\msys64` ou personalizada), **arquitetura**, **release/arquivo base** da instalação e **ambiente `MSYSTEM`** como UCRT64 ou CLANG64. O ambiente altera PATH e toolchain; não é interpretador. Uma instalação pode conter mais de um ambiente, mas cada instância de tarefa precisa identificar um deles. A primeira homologação do DS1 continua UCRT64 x64; outros ambientes serão incluídos conforme adaptadores e testes.

O provedor deve detectar a instalação existente e a integridade de `pacman`, selecionar artefato oficial com hash e verificar os pacotes no ambiente indicado. Uma imagem base fixada não congela automaticamente o repositório `pacman`. Se a versão exata compartilhada não puder ser obtida naquele MSYS2, mostrar bloqueio ou alternativa **explicitamente aprovada**; não instalar outra versão nem fazer downgrade global silencioso.

## Uma versão lógica comum, binários próprios de cada sistema

`alignment.mode: exact` significa **a mesma versão efetiva do produto** em todos os destinos incluídos: Python `3.12.x` resolve para um mesmo `3.12.patch`; Maven e Gradle para a mesma versão completa; Java inclui a distribuição escolhida (por exemplo, Temurin) e sua versão/build compatível. Artefatos, hashes, instaladores e caminhos serão diferentes por sistema. A versão do Windows, release da distro, WSL, MSYS2 e recursos opcionais são requisitos **específicos do destino** e têm suas próprias restrições; não faz sentido igualá-los entre ambientes.

O resolver compara um catálogo versionado, metadados dos provedores, arquitetura, release do SO, compatibilidade Java/Gradle/Maven e instalações externas já existentes. A TUI mostra as **versões comuns realmente resolvíveis** para os destinos selecionados; `3.10`, `3.11`, `3.12` etc. são apenas linhas candidatas até a validação. A disponibilidade de um patch binário muda com o ciclo de manutenção: por exemplo, releases recentes da linha Python 3.10 passaram a ser apenas de código fonte no site oficial, o que pode impedir um instalador Windows oficial para o mesmo patch oferecido no Linux.

Plano e arquivo de lock devem registrar, por ferramenta e destino: versão efetiva comum, fornecedor/distribuição, revisão do pacote, origem e SHA-256 do artefato, provedor, arquitetura, imagem do sistema, identidade/instância, resultado de checagem e motivos de incompatibilidade. O lock é **resultado da resolução**, nunca uma declaração de que algo já está instalado. Se não houver versão comum, o grupo alinhado fica `Blocked`; não instalar primeiro Windows e descobrir depois que MSYS2 não pode corresponder. O usuário pode reduzir os destinos ou criar outro perfil explicitamente, mas o modo `exact` não será relaxado silenciosamente.

Exemplo de saída planejada (valores fictícios):

| Ferramenta | Pedido | Windows | WSL Ubuntu | MSYS2 UCRT64 | Resultado |
|---|---|---|---|---|---|
| Python | `3.12` | `3.12.P` | `3.12.P` | `3.12.P` | Satisfeito **somente se** todos os três provedores comprovarem `P` e os artefatos. |
| Java | Temurin `21` | `21.U+B` | `21.U+B` | indisponível | **Blocked**; nenhum Apply deste grupo. |

`P`, `U` e `B` são marcadores, não versões instaláveis. Uma exceção futura (por exemplo, aceitar mesmo `major.minor` com patches diferentes) exigirá modo distinto, aprovação visível e log de divergência. Não será o comportamento padrão.

## Runbook reutilizável por destino

O runbook pode declarar aplicação em cada destino de um grupo e buscar a versão comum já resolvida:

```yaml
spec:
  target:
    forEach: {profileGroup: alignment.targets}
  inputs:
    version:
      type: version
      fromProfile: python
  requires: [prerequisites, environment-ready]
  tasks:
    - id: python
      checks:
        - id: exact-version
          output: ds1.check/v1
          variants:
            windows: {shell: pwsh, file: scripts/windows/Test-Python.ps1}
            wsl: {shell: sh, file: scripts/linux/Test-Python.sh}
            msys2: {shell: bash, file: scripts/msys2/Test-Python.sh}
      apply:
        - id: install
          fixes: [exact-version]
          when: {anyRequired: [exact-version]}
          approval: explicit
          variants:
            windows: {shell: pwsh, file: scripts/windows/Install-Python.ps1}
            wsl: {shell: bash, file: scripts/linux/Install-Python.sh}
            msys2: {shell: bash, file: scripts/msys2/Install-Python.sh}
```

Este fragmento **ilustra a forma proposta**, não scripts já existentes. `variants` exige exatamente uma implementação homologada para cada destino selecionado; o schema também poderá admitir um provedor portável que implemente essa interface. A checagem usa shells disponíveis antes da instalação do próprio Python. A expansão gera IDs concretos como `tool.python@ubuntu`, mantendo checagens, logs e versões separados por instância.

## Ordem de preparação e bloqueios

1. Bootstrap e checagens do host (UAC, PowerShell, recursos WSL2) continuam possíveis com apenas PowerShell 5.1 inicial.
2. Escolher o perfil e observar instalações existentes, famílias, imagens/versões do SO e destino MSYS2. Planejar e pedir consentimento por instalação ou adoção de imagem. Uma imagem WSL ausente é requisito **Requerido**, não ausência de Python.
3. Provisionar somente imagens/instâncias autorizadas; reabrir após reinício quando necessário, verificar SO, usuário, arquitetura e provedores reais. Não prometer disponibilidade de ferramenta só por ter instalado a imagem.
4. Resolver e aprovar a matriz comum de versões para o grupo selecionado; executar serialmente as tarefas, rechecando cada versão por destino. Se algum destino se tornar incompatível, parar antes da próxima mutação e mostrar o motivo.

Requisitos específicos do host e criação de ambiente ficam em tarefas próprias; a política atual de gate global de recursos WSL2 permanece até decisão explícita em contrário. A UI deve distinguir “imagem não instalada”, “instância existente incompatível”, “versão indisponível”, “reinício pendente” e “erro de sondagem”.

## Aceite e trabalho pendente

- [ ] Catálogo de imagens/provedores com origem, arquitetura, checksum, licença, modo de instalação e estado de suporte, sem URLs improvisadas no YAML.
- [ ] Adaptadores por família/distribuição e MSYSTEM testados em imagem limpa **e** instância já configurada; NixOS e distribuições não homologadas continuam fora do Apply.
- [ ] Resolver versão exata comum, validar compatibilidades Java/Gradle/Maven e distinguir patch do produto de revisão do pacote.
- [ ] Gerar lock determinístico e mostrar matriz de disponibilidade na TUI antes da primeira mutação de toolchain.
- [ ] Testar reexecução NoOp, imagem existente, conflito de nome/raiz, Python sem binário para um destino, alteração da imagem, reinício e recusa de consentimento.
- [ ] Validar os exemplos e o schema com o compilador v2; o YAML aqui é design, não um fluxo já executável.

## Referências

- [Distribuições disponíveis e instâncias WSL](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
- [Importar imagem WSL e usuário inicial](https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro)
- [Ambientes MSYS2](https://www.msys2.org/docs/environments/)
- [Instalador MSYS2](https://www.msys2.org/docs/installer/)
- [Pacotes MSYS2](https://www.msys2.org/docs/package-management/)
- [Compatibilidade Gradle/Java](https://docs.gradle.org/current/userguide/compatibility.html)
- [Requisitos Maven/Java](https://maven.apache.org/download.cgi)
- [Exemplo de limite de binários Python 3.10](https://www.python.org/downloads/release/python-31012/)
