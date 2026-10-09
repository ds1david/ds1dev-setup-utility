# Arquitetura do DS1 Setup Utility

## Contrato das tarefas
Cada tarefa tem ID estável, plataforma, dependências, permissões, seleção de versão, Test, Plan, Apply, Verify e (quando seguro) Undo. **A wiki descreve o mesmo processo, mas o script é a fonte executável.**

## Dependências e estado
Ciclo: Discover → Resolve graph → Test → Plan → Confirm → Apply → Verify → Persist. Bloquear dependentes de pré-requisitos com falha (ex.: Ubuntu não instalado impede SDKMAN). Registrar por ambiente: host, distro/MSYSTEM, ferramenta, versão solicitada/observada, data, tarefa, resultado e evidência. Não confiar cegamente em marcadores de sucesso anteriores. A reexecução deve detectar o estado atual e agir apenas no delta.

## Logging
Transmitir em tempo real stdout e stderr para terminal e arquivo UTF-8 por execução; salvar exit code, timestamps, ambiente e tarefa, mais resumo JSON. Logs de processo devem ser expurgados de tokens e segredos. Em comandos nativos, evitar buffering integral até o fim do processo. Registrar falhas e reinícios pendentes.

## Bootstrap sem dependências do ambiente
Entrada PowerShell 5.1 ou 7 já presente no Windows, **somente elevado**. Bootstrap é capaz de verificar PowerShell 7 e instalar após confirmação (usando WinGet se disponível, senão exigir instalador oficial autenticado). Após instalação, relançar em pwsh elevado. A UI deve executar sem módulos externos; não se deve tentar usar a API do GitHub sem rede ou credenciais necessárias. Antes de C:\workspace existir, usar staging temporário.

O requisito de execução como administrador é restrito ao ponto de entrada Windows: comandos Ubuntu rodarão como usuário comum, com sudo isolado; MSYS2 com identidade do usuário. Não executar todos os processos filhos como root por conveniência.

## Versionamento
Selecionar versões suportadas, não strings arbitrárias sem origem. Maven/Gradle: ZIP oficial e SHA; Java: WinGet ou SDKMAN por ID válido; Python: WinGet ou apt/pyenv conforme plataforma; pacman no MSYS2 respeita pacotes e compatibilidade. Reinstalação preserva configuração quando versões já correspondem. Em atualização, backups de configurações antes de mudar.

## Política de segurança
`irm | iex` é mecanismo de entrega solicitado, mas a documentação recomenda baixar e verificar uma versão fixada e hash/assinatura antes de executar com privilégio elevado. Nenhuma tarefa deve criar ou destruir recursos antes de Test/Plan/Confirm. Windows Defender/SmartScreen e ExecutionPolicy não devem ser desativados automaticamente.

## Fases
1. Migrar e revisar os runbooks.
2. Implementar Test/Plan/Apply e estados.
3. Implementar menu e fluxo interativo de versões.
4. Testar em Windows limpo, Ubuntu WSL2 e MSYS2 reais, incluindo falhas, reboots e reruns.
