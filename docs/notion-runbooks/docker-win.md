# docker-win — Docker Desktop no Windows (futuro)

> Guia de rastreabilidade derivado da wiki Notion (consultada 2026-10-09). **Documento não executável**. Conteúdo da wiki pode não estar totalmente implementado no código atual; **não** concluir que Apply funciona com base nesta página.

## Identificação
- **Identificador documental:** `docker-win`
- **Ambiente:** Windows
- **Fase planejada:** [007](../phase-gates.md)
- **Privilégio previsto:** Elevação só para recursos/instalação que realmente exijam admin; instalação per-user quando viável.
- **Estado:** somente documentação; não existe runbook executável catalogado com este identificador. Sem ID público definitivo, não publicar manifesto antes de revisar dependências/nomes.

## Valor entregue após a implementação
Docker Desktop com engine Linux via WSL2 e escolha explícita entre per-user/all-users.

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
1. Verificar VirtualMachinePlatform, WSL atualizado, virtualização, Windows edition.
2. Não habilitar Hyper-V completo apenas para Linux containers.
3. Validar docker info, backend e política fail closed para troca de engines.

## Diagnóstico manual de referência (somente leitura)
Comandos contextualizados para o shell correto; ausência de ferramenta deve resultar em diagnóstico, não instalação. NÃO são prova de que os runbooks atuais suportam estes testes:

~~~text
docker context ls
docker info
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
- Runbook ainda não existe no catálogo; ID final precisa de decisão compatível.
- Não alternar Windows/Linux engine automaticamente.

## Fontes Notion
- [Página Notion: dockerwin](https://app.notion.com/p/3f4bf4c17f678106bb4eeb06c1e1c3e5)
- [Página Notion: runbook](https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc)

## Links do repositório
- [Especificações e gates](../phase-gates.md)
- [Correspondência de numeração](../notion-runbook-traceability.md)
- [Contrato atual PSD1 v1](../runbooks.md)
