# Feature Specification: 007 — Docker Desktop, validação integrada e backup/restore

**Status:** Backlog; proposta ainda não implementada.
**Branch de feature:** `feat/007-docker-backup-validation`
**Dependências:** Fases 002/004/006 quando o recurso correspondente está selecionado; feature de backup independente do Docker.

## Contexto
Diagnostica a integração Docker Windows/Ubuntu, gera relatório de ambiente e permite backup/restore ensaiado e seguro.

O código preexistente e a wiki são materiais distintos. A fase 007 não valida a execução de scripts pelo simples fato de documentá-los.

## Histórias de usuário
- **US1 / P1:** Quero saber se Docker Desktop centralizado está acessível sem misturar o engine WSL alternativo.
- **US2 / P2:** Quero gerar um diagnóstico de versões, mounts, credenciais e caminhos sem exportar dados secretos.
- **US3 / P3:** Quero ensaiar restauração antes de confiar em backups WSL, Windows e volumes Docker.

## Requisitos
- **FR-007-01:** Docker Desktop deve residir no host Windows; scripts Ubuntu usam integração explícita ao backend autorizado, sem alternar Docker engines automaticamente.
- **FR-007-02:** Detectar engine ativa e conflitos de socket/contexto; Plan nunca troca engine e Apply pede consentimento para mudanças de configuração.
- **FR-007-03:** Gerar inventário sanitizado em JSON/Markdown com versões, filesystem, status de comandos, sucesso/parcial/bloqueado e limites da coleta.
- **FR-007-04:** Backup de Windows, WSL e Docker deve especificar escopo, consistência, destino, integridade e criptografia; nunca copiar credenciais em texto puro.
- **FR-007-05:** Operação de restore exige seleção explícita do arquivo, destino isolado e confirmação de overwrite; nunca sobrescrever sistema de produção por padrão.
- **FR-007-06:** Teste de restauração em amostra obrigatória antes de exibir estado BackupValidado; falha de hash ou export truncado gera erro.

## Critérios de aceite
- **AC-007-01:** Em host sem Docker, o diagnóstico funciona, marca Docker ausente e não instala nem inicia engine.
- **AC-007-02:** Com WSL configurado, docker info mostra engine esperada sem troca silenciosa; conflito gera Blocked com correção manual.
- **AC-007-03:** Execução de diagnóstico produz artefato sem tokens/segredos e com evidência de versões verificáveis.
- **AC-007-04:** Backup de amostra validado por checksum e restore em diretório de teste; conteúdo comparado depois de recuperar.
- **AC-007-05:** Backups de distro não chamam wsl --unregister; opções de sobrescrita vêm desabilitadas por padrão.

## Não escopo
Orquestrar clusters/servidores, alterar containers de produção ou sincronizar credenciais no Google Drive.

## Requisitos globais e restrições
- Nenhum comando Test/Plan deve produzir efeito colateral; Apply explícito, confirmado, idempotente e verificável.
- Estado observado e evidência acima de histórico; cenários de falha nunca declarados concluídos.
- Operações administrativas granulares, logs redigidos e nenhum acesso automático a recursos corporativos.
- Preservar interfaces legadas até migração compatível e testada.
- Não renumerar os IDs PSD1 atuais para acomodar os números históricos da wiki Notion.

## Fontes consultadas e código de referência
- Notion: https://app.notion.com/p/3f4bf4c17f678106bb4eeb06c1e1c3e5
- Notion: https://app.notion.com/p/3f4bf4c17f67818f9380e81f50664e0b
- Notion: https://app.notion.com/p/3f3bf4c17f67819684addfb0d3e31e00
- Notion: https://app.notion.com/p/3f3bf4c17f6781f38e8fe4bef6440275
- Git: `docs/07-validacao.md`
- Git: `docs/08-backup.md`
- Git: `docs/arquitetura-executor.md`
- Git: `runbooks/07/runbook.ps1`
- Git: `runbooks/07/runbook.psd1`
- [Rastreabilidade](../../docs/notion-runbook-traceability.md)
- [Constituição](../../.specify/memory/constitution.md)

## Evidências de conclusão
- Cada AC-007 possui ambiente, comando e evidência redigida documentados no PR.
- Testes negativos, conflito de estado preexistente e idempotência demonstrados.
- Só marcar um runbook `Implemented=true` após validação observável.
