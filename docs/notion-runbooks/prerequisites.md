# prerequisites — Pré-requisitos Windows

> Guia de rastreabilidade derivado da wiki Notion (consultada 2026-10-09). **Documento não executável**. Conteúdo da wiki pode não estar totalmente implementado no código atual; **não** concluir que Apply funciona com base nesta página.

## Identificação
- **Identificador documental:** `prerequisites`
- **Ambiente:** Windows
- **Fase planejada:** [001/002](../phase-gates.md)
- **Privilégio previsto:** Administrador apenas para modificar recursos opcionais; diagnóstico sem admin (alvo fase 002).
- **Manifesto de código:** [runbooks/prerequisites/runbook.psd1](../../runbooks/prerequisites/runbook.psd1)
- **Script atual:** [runbook.ps1](../../runbooks/prerequisites/runbook.ps1)
- **Implemented (em main no levantamento):** `true`.
- **Dependências reais do manifesto:** nenhuma.

## Valor entregue após a implementação
Detectar virtualização, recursos opcionais requeridos ao WSL2 e reboot pendente antes de permitir tarefas dependentes.

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
1. Verificar recursos do sistema por estado observado e diferenciar o que já está habilitado do que falta.
2. Oferecer somente alterações explicitamente selecionadas; não habilitar Hyper-V completo sem necessidade de Windows containers.
3. Após habilitar componente Windows, sinalizar reboot e impedir avanço até reiniciar/revalidar.

## Diagnóstico manual de referência (somente leitura)
Comandos contextualizados para o shell correto; ausência de ferramenta deve resultar em diagnóstico, não instalação. NÃO são prova de que os runbooks atuais suportam estes testes:

~~~text
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
wsl --status
~~~

## Critérios de aceite observáveis
- [ ] Estado inicial e pré-requisitos descobertos corretamente.
- [ ] Test/Plan executados sem alterações (a fase 002 deve viabilizar execução sem admin).
- [ ] Apply solicita confirmação específica e revalida pré-condições.
- [ ] Implementação realmente observada, não inferida do log.
- [ ] Segunda aplicação idempotente; backup/reversão cobrem mudanças de arquivo/profile.
- [ ] Falha parcial, ausência de privilégio e reboot pendente tratados sem falso sucesso.
- [ ] Evidência de testes registrada no PR da fase 001/002.

## Restrições, riscos e divergências conhecidas
- Habilitar recursos Windows pode exigir administrador/reinício.
- Detector parcial não prova que WSL/Ubuntu estão inicializáveis.

## Fontes Notion
- [Página Notion: arch](https://app.notion.com/p/3f3bf4c17f678117b4b3ffe0ccd4b228)
- [Página Notion: runbook](https://app.notion.com/p/3f4bf4c17f678106bcc8e235868647dc)
- [Página Notion: dockerwin](https://app.notion.com/p/3f4bf4c17f678106bb4eeb06c1e1c3e5)

## Links do repositório
- [Especificações e gates](../phase-gates.md)
- [Correspondência de numeração](../notion-runbook-traceability.md)
- [Contrato atual PSD1 v1](../runbooks.md)
