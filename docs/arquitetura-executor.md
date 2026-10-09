# Arquitetura do DS1 Setup Utility

## Contrato das tarefas
Cada tarefa tem ID estável, plataforma, dependências, permissões, seleção de versão, Test, Plan, Apply, Verify e (quando seguro) Undo. **A wiki descreve o mesmo processo, mas o script é a fonte executável.**

## Dependências e estado
Ciclo: Discover → Resolve graph → Test → Plan → Confirm → Apply → Verify → Persist. Bloquear dependentes de pré-requisitos com falha (ex.: Ubuntu não instalado impede SDKMAN). Registrar por ambiente: host, distro/MSYSTEM, ferramenta, versão solicitada/observada, data, tarefa, resultado e evidência. Não confiar cegamente em marcadores de sucesso anteriores. A reexecução deve detectar o estado atual e agir apenas no delta.

## Logging
Transmitir em tempo real stdout e stderr para terminal e arquivo UTF-8 por execução; salvar exit code, timestamps, ambiente e tarefa, mais resumo JSON. Logs de processo devem ser expurgados de tokens e segredos. Em comandos nativos, evitar buffering integral até o fim do processo. Registrar falhas e reinícios pendentes.

## Bootstrap sem dependências do ambiente

Entrada por PowerShell 5.1 ou 7, com ou sem elevação inicial; o bootstrap verifica UAC e solicita autorização para abrir sessão elevada. A TUI só inicia administrativa. UAC já pertence ao Windows; não instalar nem alterar sua política automaticamente. Se desabilitado e a sessão não for administrativa, interromper com diagnóstico.

PowerShell 7 compatível é reutilizado (mínimo 7.4 estável com assinatura Microsoft). Se ausente, solicitar autorização e instalar MSI oficial fixado em 7.6.6, validando SHA-256 e assinatura Microsoft. **WinGet não é pré-requisito.** Código 3010 exige reinicialização antes de continuar. O bootstrap não instala Rust, Git, .NET SDK, 7-Zip ou módulos para iniciar a interface.

A instalação limpa e a adoção de ambiente existente são cenários obrigatórios. `irm | iex` não fornece PSScriptRoot: o fluxo remoto resolve um commit e obtém seu ZIP; não presume diretório local. Snapshot por HTTPS/commit ainda não é release assinada DS1. Logs de bootstrap/MSI ficam no staging exclusivo preservado; logging integral do executor continua pendente.

A elevação com outra conta é bloqueada comparando SID do iniciador; HKCU, profiles e WSL não devem ser configurados para a conta errada. Elevação Windows não implica root Ubuntu. Filhos MSYS2 podem herdar o token elevado; não alegar redução automática de privilégio. Usuário Linux, permissões e execução de tarefas devem seguir o [plano detalhado](plano-de-execucao.md).

## TUI Rust e compatibilidade

Rust/Ratatui é a interface alvo, ainda não implementada. O motor PowerShell continua responsável por descoberta, dependências, execução e estado. Manifestos PSD1 existentes serão preservados; o motor oferecerá catálogo/eventos JSON à TUI, sem duplicar detectores nem exigir TOML. JSONL, captura nativa e schemas futuros não fazem parte do contrato v1 atual.

## Versionamento
Selecionar versões suportadas, não strings arbitrárias sem origem. Maven/Gradle: ZIP oficial e SHA; Java: WinGet ou SDKMAN por ID válido; Python: WinGet ou apt/pyenv conforme plataforma; pacman no MSYS2 respeita pacotes e compatibilidade. Reinstalação preserva configuração quando versões já correspondem. Em atualização, backups de configurações antes de mudar.

## Política de segurança
`irm | iex` é mecanismo de entrega solicitado, mas a documentação recomenda baixar e verificar uma versão fixada e hash/assinatura antes de executar com privilégio elevado. Nenhuma tarefa deve criar ou destruir recursos antes de Test/Plan/Confirm. Windows Defender/SmartScreen e ExecutionPolicy não devem ser desativados automaticamente.

## Fases

Ver [plano de execução M0–M11](plano-de-execucao.md), com dependências, tarefas e matriz de aceite.
1. Migrar e revisar os runbooks.
2. Implementar Test/Plan/Apply e estados.
3. Implementar menu e fluxo interativo de versões.
4. Testar em Windows limpo, Ubuntu WSL2 e MSYS2 reais, incluindo falhas, reboots e reruns.

## Descoberta dinâmica implementada

O catálogo ativo é formado por `runbooks/**/runbook.psd1`, com um handler PowerShell por runbook. A TUI não contém IDs fixos ou detectores por ferramenta. Novos runbooks aparecem após atualizar a cópia local e reiniciar ou pressionar R. O motor valida o grafo e chama Test/Plan/Apply pelo contrato comum; os dez instaladores históricos continuam planejados. Ver [contrato e exemplo de autoria](runbooks.md).
