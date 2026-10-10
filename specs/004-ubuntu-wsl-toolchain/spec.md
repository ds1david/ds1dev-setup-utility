# Feature Specification: 004 — WSL2 Ubuntu e toolchain Linux

**Status:** Proposta para execução futura; não certifica código pronto.
**Feature branch recomendada:** `feat/004-ubuntu-wsl-toolchain`
**Fonte:** Git atual + wiki Notion (consulta 2026-10-09). **Dependências:** 002 e pré-requisitos Windows; fase 003 não deve ser exigida quando desnecessária para o runbook Linux.

## Contexto
Ubuntu WSL2 configurado, sem cruzamento acidental para binários Windows.

O repositório já contém implementação parcial e testes. A entrega desta fase deve ser um delta pequeno, verificável e isolado da infraestrutura existente. Não recriar o projeto do zero e não assumir que exemplos de documentação já funcionem.

## Histórias de usuário
- **US1 (P1):** Como desenvolvedor quero instalar WSL2/Ubuntu sem depender de uma distro previamente inicializada.
- **US2 (P2):** Como usuário do Ubuntu quero instalar Git/Python/SDKMAN/Java 21/Maven/Gradle em ext4 com diagnósticos reais.
- **US3 (P3):** Como operador quero ser informado de reboot e retomar só depois de reiniciar.

## Requisitos
- **FR-004-01:** Descobrir WSL, feature Windows, distro e versão; não supor nome Ubuntu-24.04/26.04 fixo.
- **FR-004-02:** Separar habilitação de feature/reboot da inicialização do usuário Linux e instalações apt/SDKMAN.
- **FR-004-03:** Executar comandos dentro de distro explicitamente selecionada, sem colar strings inseguras nem esconder código de saída.
- **FR-004-04:** Instalar toolchain Ubuntu em HOME e filesystem Linux, não em /mnt/c nem via binários .exe do Windows.
- **FR-004-05:** Testar versão exata de Java 21 quando selecionada e origem do comando via command -v/readlink -f; preferir wrappers Maven/Gradle por projeto.

## Critérios de aceite
- **AC-004-01:** WSL ausente apresenta Plan e PendingReboot quando necessário; não tenta prosseguir antes de reinicialização.
- **AC-004-02:** Distro inicializada e apt/SDKMAN/JDK21/Maven/Gradle passam em sessão Bash nova sem depender do host PATH.
- **AC-004-03:** Com duas distros, operação só modifica a distro indicada pelo usuário.
- **AC-004-04:** Apply×2 não duplica init do SDKMAN nem reinstala componentes satisfeitos.
- **AC-004-05:** Falha apt ou SDKMAN retorna exit code e mensagem sem marcar Installed e sem gravar senhas.

## Não escopo
Compartilhamento global de pastas, Docker integration e MSYS2.

## Condições não funcionais e segurança
- Ações mutáveis somente via confirmação; testes e planos sem efeitos colaterais.
- Falha deve ser explícita, não transformar erro em `Installed` nem mascarar `exit code`.
- Registrar evidência e versão, redigindo segredo e preservando identidade.
- Regressão dos comandos/IDs atuais proibida salvo migração deliberada e testada.

## Fontes e rastreabilidade
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f67810a837fe1f0ea0c2e20
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f6781b0accad94fd9735775
- Git: `runbooks/03/runbook.ps1`
- Git: `runbooks/03.1/runbook.ps1`
- Git: `docs/03-wsl.md`
- Git: `docs/03.1-toolchain-ubuntu.md`
- Constituição: `../../.specify/memory/constitution.md`
- Rastreabilidade: `../../docs/notion-runbook-traceability.md`

## Métricas e evidência de saída
- 100% dos critérios AC desta fase demonstrados em testes e/ou ensaio manual controlado.
- Dois Apply consecutivos quando aplicável, com ausência de mutação redundante.
- Caminhos negativos testados e reportados no PR, junto de limitações de plataforma.
- Nenhum `Implemented=true` sem prova real de pós-condição.
