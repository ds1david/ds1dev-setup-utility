# Feature Specification: 003 — Instalação Windows básica, Java/Maven/Gradle

**Status:** Proposta para execução futura; não certifica código pronto.
**Feature branch recomendada:** `feat/003-windows-toolchain`
**Fonte:** Git atual + wiki Notion (consulta 2026-10-09). **Dependências:** 002 aprovado; pré-requisitos Windows observados e confirmação para cada ação.

## Contexto
Usuário instala e valida ferramentas de desenvolvimento Windows sob demanda, inclusive quando WinGet ou PATH faltam.

O repositório já contém implementação parcial e testes. A entrega desta fase deve ser um delta pequeno, verificável e isolado da infraestrutura existente. Não recriar o projeto do zero e não assumir que exemplos de documentação já funcionem.

## Histórias de usuário
- **US1 (P1):** Como usuário com Windows limpo quero instalar Git, Python, JDK 21, Maven e Gradle por etapas, com dependências claras.
- **US2 (P2):** Como usuário em ambiente preexistente quero detectar a instalação e não substituir versões sem consentimento.
- **US3 (P3):** Como mantenedor quero diagnóstico que prove java, javac, mvn e gradle usando o JDK esperado.

## Requisitos
- **FR-003-01:** Oferecer tarefas granulares para WinGet/Terminal/Git/Python/Java 21/Maven/Gradle sem interpretar versão não suportada como instalada.
- **FR-003-02:** Não supor WinGet ou Gradle disponível no catálogo WinGet; usar origem oficial, ZIP binário e SHA-256/SHA-512 onde aplicável.
- **FR-003-03:** Descobrir caminhos sob usuário e máquina, comparar JAVA_HOME/MAVEN_HOME/GRADLE_HOME/PATH e preservar entradas existentes.
- **FR-003-04:** Test sem alteração; Plan enumera downloads, mudanças de variáveis, risco de conflito e reinício de terminal.
- **FR-003-05:** Apply idempotente instala apenas faltantes, faz backup de configuração e exige hash/assinatura e confirmação antes de modificar PATH.

## Critérios de aceite
- **AC-003-01:** Em VM Windows limpa, sequência explícita instala Git/Python/JDK21/Maven/Gradle e version checks passam.
- **AC-003-02:** Em VM com Java/Maven preexistentes, Plan mostra o que preservar e solicita aprovação antes de modificar seleção.
- **AC-003-03:** Apply executado duas vezes não duplica PATH nem reinstala quando estado já atende.
- **AC-003-04:** Pacote com checksum inválido é recusado antes de extração e qualquer mudança de ambiente.
- **AC-003-05:** Java -version, javac -version, mvn -version e gradle --version usam origem Windows correta em nova sessão.

## Não escopo
SDKMAN, distribuição Ubuntu ou path /workspace ext4, IDEs, Rust.

## Condições não funcionais e segurança
- Ações mutáveis somente via confirmação; testes e planos sem efeitos colaterais.
- Falha deve ser explícita, não transformar erro em `Installed` nem mascarar `exit code`.
- Registrar evidência e versão, redigindo segredo e preservando identidade.
- Regressão dos comandos/IDs atuais proibida salvo migração deliberada e testada.

## Fontes e rastreabilidade
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f67812e828ad07f279c20a7
- Git: `runbooks/02/runbook.ps1`
- Git: `runbooks/02.1/runbook.ps1`
- Git: `runbooks/02/runbook.psd1`
- Git: `runbooks/02.1/runbook.psd1`
- Git: `docs/02-windows.md`
- Git: `docs/02.1-toolchain-windows.md`
- Constituição: `../../.specify/memory/constitution.md`
- Rastreabilidade: `../../docs/notion-runbook-traceability.md`

## Métricas e evidência de saída
- 100% dos critérios AC desta fase demonstrados em testes e/ou ensaio manual controlado.
- Dois Apply consecutivos quando aplicável, com ausência de mutação redundante.
- Caminhos negativos testados e reportados no PR, junto de limitações de plataforma.
- Nenhum `Implemented=true` sem prova real de pós-condição.
