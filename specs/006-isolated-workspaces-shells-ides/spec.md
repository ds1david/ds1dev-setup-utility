# Feature Specification: 006 — Workspaces nativos, shells e IDEs

**Status:** Backlog; proposta ainda não implementada.
**Branch de feature:** `feat/006-isolated-workspaces-shells-ides`
**Dependências:** Fases 002, 004 e 005; cada subetapa exige apenas seu ambiente.

## Contexto
Cria três workspaces independentes e perfis de shell reaplicáveis, integrando IDEs Windows sem compartilhar configurações internas.

O código preexistente e a wiki são materiais distintos. A fase 006 não valida a execução de scripts pelo simples fato de documentá-los.

## Histórias de usuário
- **US1 / P1:** Quero desenvolver com origem nativa para Windows, Ubuntu e MSYS2, sem precisar de push/pull para trocar de shell em um mesmo ambiente.
- **US2 / P2:** Quero que oh-my-posh e completions funcionem sem duplicar init/PATH e sem quebrar PowerShell 5.1, 7 ou Bash.
- **US3 / P3:** Quero chamar code/idea a partir do Linux/MSYS2 para abrir a IDE no Windows usando os caminhos corretos.

## Requisitos
- **FR-006-01:** Garantir Windows C:\workspace no NTFS, Ubuntu /workspace em ext4 e MSYS2 /workspace sob raiz do MSYS2; verificar localização física, não apenas existência da pasta.
- **FR-006-02:** Criar projetos/dev/shared/local com configuração nativa por ambiente; local/{bin,env,config} são isolados e não são links entre hosts.
- **FR-006-03:** Permitir compartilhamento somente de diretórios pessoais explicitamente autorizados e jamais redirecionar .git, caches, credenciais, configurações locais sem indicação.
- **FR-006-04:** Incluir local/bin exatamente uma vez no PATH de cada shell, preservar conteúdos preexistentes e fazer backup antes de editar profile/fstab/Terminal JSON.
- **FR-006-05:** Integrar PowerShell 5.1/7 e Bash Ubuntu/UCRT64; provider para oh-my-posh + completions Maven, Gradle, Docker Compose com fallback documentado.
- **FR-006-06:** Integração code/idea deve traduzir paths de forma correta e não instalar IDE no Linux; não supor 'idea' disponível.

## Critérios de aceite
- **AC-006-01:** Cada workspace retorna diretório físico distinto; no MSYS2 o caminho canônico pertence à instalação MSYS2, no Ubuntu pertence a filesystem Linux ext4.
- **AC-006-02:** Reexecução de Apply não duplica PATH, mounts fstab, completions, aliases ou perfil Terminal.
- **AC-006-03:** Alterações de compartilhamento exibem plano por pasta e exigem escolha; não há link nem permissão ampliada sem consentimento.
- **AC-006-04:** Invocar code . e idea . abre diretório correto na IDE Windows ou produz diagnóstico claro se IDE não estiver instalada.
- **AC-006-05:** Shells continuam inicializando se completions/oh-my-posh estiverem indisponíveis, preservando prompts anteriores.

## Não escopo
Instalar Docker ou fornecer um filesystem único físico para os três sistemas.

## Requisitos globais e restrições
- Nenhum comando Test/Plan deve produzir efeito colateral; Apply explícito, confirmado, idempotente e verificável.
- Estado observado e evidência acima de histórico; cenários de falha nunca declarados concluídos.
- Operações administrativas granulares, logs redigidos e nenhum acesso automático a recursos corporativos.
- Preservar interfaces legadas até migração compatível e testada.
- Não renumerar os IDs PSD1 atuais para acomodar os números históricos da wiki Notion.

## Fontes consultadas e código de referência
- Notion: https://app.notion.com/p/3f3bf4c17f6781fbbaace656e14b83c3
- Notion: https://app.notion.com/p/3f3bf4c17f6781b0accad94fd9735775
- Notion: https://app.notion.com/p/3f3bf4c17f6781ceb904c318f64a327b
- Notion: https://app.notion.com/p/3f3bf4c17f6781039b87f6371e7c94b3
- Git: `runbooks/05/runbook.ps1`
- Git: `runbooks/06/runbook.ps1`
- Git: `runbooks/06.1/runbook.ps1`
- Git: `docs/05-workspaces.md`
- Git: `docs/06-shells.md`
- Git: `docs/06.1-ides.md`
- [Rastreabilidade](../../docs/notion-runbook-traceability.md)
- [Constituição](../../.specify/memory/constitution.md)

## Evidências de conclusão
- Cada AC-006 possui ambiente, comando e evidência redigida documentados no PR.
- Testes negativos, conflito de estado preexistente e idempotência demonstrados.
- Só marcar um runbook `Implemented=true` após validação observável.
