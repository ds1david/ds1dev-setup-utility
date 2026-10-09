# backup — Backup/restauração (futuro)

> Guia de rastreabilidade derivado da wiki Notion (consultada 2026-10-09). **Documento não executável**. Conteúdo da wiki pode não estar totalmente implementado no código atual; **não** concluir que Apply funciona com base nesta página.

## Identificação
- **Identificador documental:** `backup`
- **Ambiente:** Integrated
- **Fase planejada:** [007](../phase-gates.md)
- **Privilégio previsto:** Usuário para backup; admin apenas se leitura protegida exigida.
- **Estado:** somente documentação; não existe runbook executável catalogado com este identificador. Sem ID público definitivo, não publicar manifesto antes de revisar dependências/nomes.

## Valor entregue após a implementação
Backup Windows, WSL, Docker e dados sincronizados com ensaio obrigatório de restore.

## Pré-condições
- Identificar host, usuário, versões, privilégios e ferramentas presentes; preservar instalações existentes.
- Observar o grafo de dependências, sem instalar dependências automaticamente.
- Execução real de mutações apenas com consentimento e backup, em VM de homologação antes do host principal.

## Fluxo Test → Plan → Apply → Verify
**Test:** inspecionar o estado observável e diferenciar `Installed`, `Partial`, `Blocked`, `NeedsReboot` e `NotInstalled`, sem elevar nem escrever.

**Plan:** listar mudanças, fontes de download, versão/hash, efeitos sobre PATH/filesystem/registry, necessidade de sudo/UAC, reboot e rollback. Nenhuma mutação.

**Apply:** executar *somente após autorização* e apenas quando a fase estiver implementada e testada. Interromper em erro e não continuar dependentes; idempotência obrigatória.

**Verify:** repetir detectores independentemente do histórico, provar versão/origem e registrar resultado sanitizado. Apply×2 não pode duplicar configuração.

## Ações esperadas
1. Definir escopo, compressão, criptografia e consistência de export WSL.
2. Comparar hashes; realizar restore amostral para destino isolado.
3. Nunca reimportar sobre distro de produção ou sobrescrever dados sem confirmação separada.

## Diagnóstico manual de referência (somente leitura)
Comandos contextualizados para o shell correto; ausência de ferramenta deve resultar em diagnóstico, não instalação. NÃO são prova de que os runbooks atuais suportam estes testes:

~~~text
wsl --list --verbose
Get-Command restic -ErrorAction SilentlyContinue
~~~

## Critérios de aceite observáveis
- [ ] Estado inicial e pré-requisitos descobertos corretamente.
- [ ] Test/Plan executados sem alterações (a fase 002 deve viabilizar execução sem admin).
- [ ] Apply solicita confirmação específica e revalida pré-condições.
- [ ] Implementação realmente observada, não inferida do log.
- [ ] Segunda aplicação idempotente; backup/reversão cobrem mudanças de arquivo/profile.
- [ ] Falha parcial, ausência de privilégio e reboot pendente tratados sem falso sucesso.
- [ ] Evidência de testes registrada no PR da fase 007.

## Restrições, riscos e divergências conhecidas
- Runbook não existe e texto Notion é guia, não backup comprovado.
- Google Drive não equivale a backup consistente de volumes ativos Docker/WSL.

## Fontes Notion
- [Página Notion: backup](https://app.notion.com/p/3f3bf4c17f67819684addfb0d3e31e00)
- [Página Notion: validate](https://app.notion.com/p/3f3bf4c17f6781f38e8fe4bef6440275)

## Links do repositório
- [Especificações e gates](../phase-gates.md)
- [Correspondência de numeração](../notion-runbook-traceability.md)
- [Contrato atual PSD1 v1](../runbooks.md)
