# TUI Windows — experiência inspirada no Linutil

Status: **especificação e mockups conceituais; primeira TUI PowerShell funcional, TUI Rust pendente**. Data: 2026-10-09.

Incremento funcional: estados Satisfeito/Requerido/Parcial por tarefa, Erro após falha de execução, tecla **L** para eventos detalhados e pergunta de exportação dos logs ao sair. O painel expandido de fases, seleção em lote, console rolável e TUI Rust desta especificação ainda são metas futuras.

[Índice](01-indice.md) · [Plano M0–M11](plano-de-execucao.md) · [Executor](arquitetura-executor.md)

## Direção visual e referência

Adotar identidade **DS1 Modern Terminal**, inspirada nas propostas visuais apresentadas para uma TUI de workflow (painéis arredondados, cores atenuadas, seleção múltipla e logs vivos) e nas referências existentes do Linutil. Não presumir que a paleta fornecida seja um padrão oficial ou uma implementação oficial do GitHub Spec Kit: é uma decisão visual própria do DS1. Identidade, mensagens e segurança permanecem DS1, em português; não reutilizar logotipos de terceiros.

Referência inspecionada: [Linutil](https://github.com/ChrisTitusTech/linutil/tree/0b0f7449e79275a7ad5cd1c0dee48c6d71f1f7f1), incluindo preview oficial, `tui/src/theme.rs`, `hint.rs` e `running_command.rs`. O código de referência usa terminal virtual para comandos e permite salvar seu log; DS1 exige gravação automática contínua e buffers de tela limitados. Não transpor o executor baseado em `sh -c` para Windows.

As três capturas enviadas pelo usuário foram inspecionadas: Linutil em Ubuntu-26.04 no Windows Terminal, inclusive catálogo multiseleção e comando em execução. Elas mostram busca no topo, marca acima de um box **pequeno** de categorias à esquerda, box **maior** de itens à direita com indicadores `[D]` e `[*]`, confirmação sobreposta e um box inferior de comandos de navegação. Durante uma instalação, a saída ocupa o box da direita e o rodapé troca os atalhos conforme o contexto. Os mockups refletem essa composição, com marca própria DS1 e estados de instalação Windows.

## Design system DS1 Modern Terminal — catálogo e execução

**Status: especificação de produto (futuro).** Aplicação prioritária à TUI Rust/Ratatui da fase 009; a TUI PowerShell existente pode evoluir progressivamente, sem exigir suporte a hex, Rounded ou Rust no bootstrap PowerShell 5.1. Tokens de tema não redefinem o contrato do motor, a autorização nem a origem do estado. A visualização proposta pelo usuário não é prova de que o GitHub Spec Kit distribuído implemente esta interface.

### Paleta proposta e semântica

| Token DS1 | Valor preferencial | Aplicação |
|---|---|---|
| `background` | `#282C34` | Fundo escuro de referência, adaptável ao tema do terminal |
| `panel.border` | `#4B5263` | Bordas discretas `Rounded` quando Unicode e largura permitirem |
| `focus.cursor` | `#C678DD` | `❯` magenta/violeta, seleção **de foco**, independente do checkbox |
| `focus.alternate` | `#D19A66` | Variante **âmbar**, não magenta/ciano; nunca confundir com cor de sucesso |
| `selection.checked` | `#56B6C2` | `[x]` ciano: incluído no **plano pretendido**, não instalado |
| `selection.checkedVerified` | `#98C379` | Verde apenas para estado realmente verificado; não usar verde de sucesso para uma mera seleção |
| `execution.spinner` | `#61AFEF` | Ciano-azulado do tema Modern Terminal; pode compartilhar estilo do spinner anterior `#00A3FF` como **variante** |
| `approval.prompt` | `#E5C07B` | `?` e avisos exigindo aprovação/entrada |
| `text.primary` | `#ABB2BF` | Títulos, comandos sanitizados e descrições legíveis |
| `text.muted` | `#5C6370` | Dicas secundárias, nunca texto crítico/erros sem contraste suficiente |
| `result.success` / `result.failure` | `#98C379` / `#E06C75` | `✔` sucesso somente após Verify; `✖` falha com causa explícita |
| `focus.background` | `#343A45` | Fundo discreto na linha sob cursor, sem ocultar estado ou checkbox |

**Acessibilidade e compatibilidade:** os valores são preferências de tema, não requisitos de truecolor. Validar contraste do texto cinza (especialmente `#5C6370` em fundo `#282C34`; subir luminância quando necessário); suporte a ANSI 16/256 cores e `NO_COLOR`. Bordas `Rounded` (Unicode) degradam para box simples ASCII/Unicode; indicadores `❯`, `✔`, `✖`, Braille e checkboxes têm alternativas `>`, `[OK]`, `[FAIL]`, `[RUNNING]`. Não depender de Nerd Fonts, ícones de múltiplas células ou frames ANSI no log. Emojis não são necessários. Preservar nomes de tokens/estados ao trocar de backend.

**Decisão de compatibilidade com o spinner anterior:** `#61AFEF` é o padrão para o tema *Modern Terminal*, `#00A3FF` é uma variante de destaque do design anterior, e ANSI ciano é fallback. Ambos significam atividade, não sucesso; o mesmo evento de execução governa todos. Tick nominal de 80–100 ms permanece, sem reescrever logs por frame.

### Duas vistas, uma única identidade

1. **Catálogo global (visão existente Linutil):** manter categorias compactas à esquerda (aproximadamente 23%) e catálogo de runbooks à direita (77%). Seleção múltipla, filtros e descrições funcionam no catálogo; nenhum runbook é executado ao entrar.
2. **Detalhe/execução de um runbook (nova visão Modern Terminal):** três zonas interativas: passos (40%), detalhes e *live logs* (60%) e barra inferior de prompt/status/atalhos. O nome do runbook, ambiente-alvo, filtros, plano e progresso ficam no cabeçalho. A navegação a partir do catálogo abre esta visão, sem alterar o manifesto PSD1 nem exigir adicionar IDs na TUI.
3. **Execução em lote de runbooks:** reutilizar o modelo de tarefas e dependências do motor; cada runbook pode abrir a vista detalhada, mas o progresso global deve continuar consultável. O plano agregado e a aprovação referenciam **IDs**, versões, destinos, dependências e ações concretas, não índices visíveis da lista.

### Wireframe semântico da vista de runbook

O exemplo é uma **fixture visual não executável**; a aparência não certifica que comandos foram executados ou que o runbook `Deploy Staging` existe no projeto:

```text
╭─ DS1 / Runbook: Deploy Staging ─────┬─ Detalhes e logs ao vivo ───────────────────────────╮
│ ❯ [x] ✔ 1. Validar pré-requisitos  │ [10:15:00] INFO Checagem do ambiente concluída     │
│   [x] ⠋ 2. Instalar dependências   │ [10:15:01] RUN  uv pip install ...                 │
│   [ ] ○ 3. Limpar cache            │ ⠋ Executando instalação... (4s)                   │
│   [x] ? 4. Aplicar migrações       │ [10:15:02] INFO Aguardando autorização do passo 4  │
│   [ ] ○ 5. Reiniciar serviços      │                                                    │
├─────────────────────────────────────┴────────────────────────────────────────────────────┤
│ ? Passo 4 exige autorização. Rever escopo e confirmar? [s/N]                             │
│ [↑↓/jk] Navegar  [Espaço] Marcar  [a] Todos elegíveis  [p] Plano  [Enter] Detalhes        │
╰──────────────────────────────────────────────────────────────────────────────────────────╯
```

**Distinção crítica:** `❯` representa **foco/cursor**, `[x]` representa **seleção no lote**, e `✔/⠋/?/○/✖` representa **estado de execução observado**, três eixos independentes. O usuário pode selecionar tarefa já conforme (o plano a mostra como NoOp), ou ver uma tarefa executando que já estava selecionada antes. A tela nunca usa `[x]` como prova de instalação. Durante uma execução, seleção é congelada para o plano fixado; para uma nova tentativa, voltar ao planejamento e revalidar.

### Contrato de layout, foco e estados

| Região | Critério |
|---|---|
| Cabeçalho | Nome do runbook, target real, etapa/total, status global e contagem `Selecionados N / Elegíveis M / Bloqueados B` |
| Lista de passos (40%) | `❯` cursor, `[x]/[ ]` seleção e ícone de estado separados; título, número, dependências, bloqueios e status acessíveis; rolagem virtual em listas extensas |
| Detalhes e logs (60%) | Mostra descrição da etapa focada, pré/pós-condições, comando **sanitizado**, versão, target, risco/permissão, stdout/stderr, spinner/timer por comando, saída persistida/posição de scroll |
| Barra inferior | Prompts que exigem ação, autorização explícita, progresso agregado, erros relevantes e atalhos do contexto; prompt não pode ser encoberto por logs nem frames de spinner |
| Modal de revisão | Plano congelado, delta observado, dependências, escopo do batch, privilégios e operação potencialmente destrutiva, com `Cancelar` preselecionado |
| Responsividade | Em largura ≥120 e altura ≥32, 40/60 mais barra; 80×24 a 119×31 usa lista e detalhes alternáveis por Tab; abaixo de 80×24 ou sem TTY, CLI linear sem bordas/animação |

Os logs continuam visíveis durante a execução e oferecem `PageUp/PageDown`, `End` para voltar a acompanhar a saída, filtros INFO/WARN/ERROR (somente apresentação) e `L` para abrir/exportar detalhes; scroll manual desliga auto-follow até `End`. A UI nunca trunca os arquivos persistidos por causa do limite de memória da TUI. Resize, caracteres combinantes, linhas longas e stdout sem newline não devem quebrar input, spinner ou bordas.

### Navegação e permissões (estado, foco e confirmação)

| Tecla / contexto | Comportamento |
|---|---|
| `↑/↓`, `j/k` com **foco na lista** | Mover o cursor sem marcar/desmarcar nem disparar comandos; `j/k` não são atalhos durante edição de texto ou modal |
| `Espaço` com foco na lista | Marcar/desmarcar a etapa elegível; atualizar apenas a intenção de plano, não executar |
| `a` com foco na lista | Marcar todos os **elegíveis do escopo/filtro atual**; nova pressão pode desmarcar esses itens. Excluir bloqueados, passos não implementados e irrelevantes; jamais ocultar dependência |
| `Enter` sobre categoria/runbook/passo | Abrir subgrupo/detalhes ou **revisão do plano** quando já estiver na ação explícita `Revisar execução`; **nunca** executar Apply diretamente |
| `p` / `P` | Gerar/exibir plano sem efeitos colaterais; revisar dependências, permissões, versões e NoOp |
| `A` / botão textual `Aplicar` | Abrir confirmação contextual do plano fixado. Somente uma confirmação posterior pode iniciar Apply; padrão `Não/Cancelar`, com privilégio mínimo |
| `Tab/Shift+Tab` | Alternar foco entre lista, painel de logs, busca/prompt e ações disponíveis |
| `L` | Expandir/alternar painel de logs e sessão; `PageUp/PageDown/End` controlam scroll/follow |
| `/` | Entrar na busca; ao digitar, `a`, `j`, `k`, `p` e `Enter` pertencem ao campo e não disparam ações globais |
| `Esc`, `q` | Voltar/cancelar modal; durante execução, abrir fluxo de cancelamento seguro (não encerrar processo à força) |
| `R` | Atualizar catálogo **somente ocioso**; em batch em andamento, bloquear alteração de definição/seleção |
| `F1` / `?` fora de prompt | Ajuda/atalhos contextualizados; se `?` estiver em campo de confirmação, recebe apenas a semântica local |

A seleção é conjunto estável de IDs de passos/runbooks, independente do índice de tela; mudança de busca, reordenação e scroll **não** altera quais itens estavam selecionados. O `a` opera apenas no escopo explícito exibido e deve informar seu alcance (`5 elegíveis neste filtro`) antes de revisão. Para listas hierárquicas, o plano resolve dependências e as apresenta explicitamente; não supor seleção automática de dependentes nem executar pré-requisito silenciosamente. Uma tarefa bloqueada pode ser inspecionada, mas sua confirmação fica desabilitada com motivo. Itens já executando não podem ter seleção alterada até término. O motor preserva Test/Plan/Apply/Verify e valida novamente estado antes de aplicar.

### Implementação incremental e limites do exemplo em Rust

O trecho Ratatui fornecido pelo usuário é **referência de renderização**, não código pronto para produção: seu `RunbookStep { selected, status }` não modela bloqueio, erro, verificação, cancelamento, dependências, identidade de comando nem operação assíncrona. Em produção separar `UiFocus`, `SelectionSet`, `ObservedStepStatus`, `ExecutionState` e `PromptState`; receber snapshots/eventos do runner, não executar subprocessos dentro de `draw_ui`. `StepStatus::Running(frame)` deve ser derivado do estado da operação + tick do renderer, nunca usado como evidência de processo vivo. `Ratatui ListState` conserva cursor; `[x]` vem do conjunto de seleções; estado/cores vêm do domínio. Renderização é função pura do estado e do frame, sem mutação do host.

O bootstrap PowerShell 5.1 permanece mínimo e sem dependências extras. A interface provisória PowerShell 7 pode adotar seleção, rodapé e tokens compatíveis conforme fase 002; não declarar paridade com a futura TUI Rust antes de testes reais. Testar por fixture sem operações de instalação e validar terminal Console Host, Windows Terminal, cores 16/256/truecolor e fallback sem Unicode.


## Duas etapas com a mesma linguagem visual

### 1. Bootstrap: PowerShell 5.1 nativo

A tela inicial deve existir **antes** de PowerShell 7, WinGet e Windows Terminal. Usar `System.Console`/recursos nativos, sem módulos externos, fontes especiais, download de UI ou compilação. Não implementar novamente um catálogo de runbooks aqui: o bootstrap só prepara o executor.

- Cabeçalho: DS1 Dev Setup, fase “Inicialização”, Windows/arquitetura, shell atual, usuário e estado de elevação.
- Busca na faixa superior: desativada durante as poucas etapas fixas do bootstrap; permanece visível para manter a composição.
- Esquerda: marca DS1 acima de um box compacto de categorias/etapas. O espaço restante não precisa ser preenchido; dados do host entram no cabeçalho ou em detalhes.
- Direita: box principal maior com requisitos e estados observados, na mesma posição em que o console exibirá os comandos ao executar. Valores desconhecidos aparecem como “Verificando” ou “Não verificado”, nunca como sucesso.
- Janela sobreposta: consentimento contextual para UAC, instalação do MSI ou pacote DS1, sempre com efeitos e opção de cancelar.
- Rodapé: box de comandos de navegação, com duas colunas e teclas dependentes do contexto. Log completo por tecla L e indicação persistente de seu caminho. Uma falha conserva a mensagem em janela sobreposta. A opção inicial de qualquer confirmação de instalação é “Cancelar”.

![Bootstrap conceitual](assets/tui-bootstrap.svg)

Estados visuais devem refletir observação real: “Encontrado”, “Ausente”, “Inacessível”, “Aguardando autorização”, “Em execução”, “Falhou”, “Reinício necessário”. Cor é complementar ao texto. Um candidato inacessível a pwsh.exe aparece como aviso, mas não interrompe a busca por outros candidatos válidos.

O exemplo do mockup mostra Windows limpo; ele não representa o estado real da máquina do usuário.

### 2. Console de runbooks: Rust + Ratatui

Depois de PS7 compatível validado e pacote verificado, abrir a interface completa com o mesmo tema. Categorias e tarefas vêm do motor, usando os manifestos dinâmicos; adicionar runbook não exige recompilar Rust.

![Console de runbooks conceitual](assets/tui-runbooks.svg)

| Região | Conteúdo e comportamento |
|---|---|
| Cabeçalho | Versão DS1/revisão, usuário, administrador, ambiente e instância selecionados |
| Busca no topo | Filtro incremental por título, ID e ferramenta; desliga atalhos globais enquanto o campo recebe texto |
| Catálogo global: categorias à esquerda, aproximadamente 23% da largura | Marca acima; categorias dentro de um box compacto cuja altura acompanha os itens, deixando espaço livre abaixo |
| Catálogo global: runbooks à direita, aproximadamente 77% da largura | Diretórios e runbooks, seleção em lote, estado observado, versão e dependência bloqueante; ocupa a maior parte da altura |
| Dentro de um runbook: passos 40% / detalhes e logs 60% | Atalho para detalhes, checklist independente de estado observado, logs live e status por comando; barra inferior mantém prompts/ajuda |
| Janelas sobrepostas | Detalhes da tarefa, seleção de versão, plano, confirmação e diagnóstico de falha; nenhuma instalação por Enter na lista |
| Box inferior em toda a largura | Lista explícita de comandos pertinentes ao foco, em colunas, como nas capturas de referência |
| Console de execução | Dentro da vista de runbook, logs ao vivo ocupam o painel direito sem ocultar a lista de passos; o rodapé mantém prompt/status/atalhos e caminhos do log |

Mostrar ambiente como Windows / Ubuntu WSL2 / MSYS2, e a instância específica (nome da distro ou raiz MSYS2). Não confundir “pacote instalado” com “configuração validada”. Uma tarefa bloqueada permanece visível, com motivo e opção de incluir o pré-requisito no plano; não instalar dependências silenciosamente.

## Fluxo do bootstrap e consentimentos

1. Abrir a tela nativa e detectar host/terminal sem alterar configuração.
2. Exibir necessidade de elevação. Ao autorizar, restaurar cursor/modo de console, explicar que uma nova janela poderá abrir e solicitar UAC pelo Windows.
3. Reconstruir a tela no filho elevado, mantendo revisão e identidade. Não prometer migrar o processo para a mesma aba: o Windows controla a abertura da janela elevada.
4. Detectar PS7, incluindo diretórios reais MSI/MSIX e candidatos do PATH. Exibir avisos individualmente; não executar candidato sem validação.
5. Se ausente: mostrar versão/arquitetura/origem do MSI, solicitar autorização e executar com progresso observável. Se presente: mostrar “Reutilizar”, sem reinstalar.
6. Validar resultado e reinício pendente. Não abrir a TUI completa se houver reinício obrigatório.
7. Mostrar revisão do pacote DS1, integridade disponível e autorização de execução. Snapshot de desenvolvimento não deve aparecer como “release assinada”.
8. Encerrar renderização nativa e abrir TUI Rust. Enquanto Rust não estiver entregue, abrir o menu PowerShell atual, identificado como provisório.

UAC não é instalável. Não substituir o diálogo seguro do Windows por uma imitação dentro da TUI. Nenhuma senha deve ser solicitada/capturada pela interface DS1 para elevação Windows. Se UAC for cancelado, a tela original mostra cancelamento, sem erro genérico nem loop.

## Navegação e execução

| Tecla e foco | Ação planejada |
|---|---|
| `↑/↓`, `j/k` quando a lista tem foco | Navegar sem executar ou marcar |
| `Tab/Shift+Tab` | Alternar entre lista, detalhes/logs, busca e prompt |
| `Espaço` na lista | Marcar/desmarcar passo elegível, sem Apply |
| `a` na lista | Selecionar/desmarcar elegíveis **do filtro atual**, excluindo bloqueados |
| `Enter` | Abrir detalhe/subgrupo ou avançar em diálogo contextual; **não** executar a partir da lista |
| `/` | Buscar título, ID ou ferramenta |
| `V` | Verificar estado real |
| `P/p` | Mostrar plano imutável do lote/steps |
| `A` | Abrir revisão de Apply + confirmação separada, padrão Cancelar |
| `E` | Escolher versão/parâmetros da tarefa focada |
| `L`, `PageUp/PageDown/End` | Abrir e navegar logs, pausar/retomar auto-follow |
| `R` | Recarregar catálogo local apenas quando ocioso |
| `F1`, `?` fora do prompt | Ajuda contextual |
| `Esc/Q` | Voltar/sair quando ocioso; durante Apply pedir cancelamento seguro |

No bootstrap, só disponibilizar as teclas pertinentes às suas etapas fixas. Mouse é opcional; todas as ações devem funcionar pelo teclado. No campo de busca, letras são texto, não atalhos globais.

Versões são escolhidas por ferramenta, com provedor, arquitetura e compatibilidade; a mesma tela pode selecionar Java, Maven, Gradle e Python com versões diferentes. Confirmar o plano mostra ações efetivas e itens que já estão conformes. “Latest” é resolvido e fixado antes da confirmação.

Ao aplicar, na **vista de um runbook** o painel direito mostra a saída contínua enquanto a lista de passos permanece à esquerda, mantendo resumo do lote e progresso. No **catálogo global**, entrar nos detalhes do runbook leva à vista 40/60, sem iniciar Apply. Exibir comando com argumentos sensíveis ocultos, ambiente, stdout/stderr, resultado e caminho do log. Permitir PageUp/PageDown, voltar ao acompanhamento ao vivo e expandir detalhes. O fim da tarefa nunca fecha a tela automaticamente; falhas preservam contexto e motivo.

## Padrão visual de execução — spinner, timer e transição de estados

**Especificação, ainda não implementação.** O DS1 deve reproduzir a ergonomia de feedback das CLIs modernas (por exemplo, instalações via `uv` e sessões Codex), mas com identidade própria. A linha de status é **dinâmica e persistente**: a mesma linha visual passa de espera para atividade e resultado final; linhas de stdout/stderr do comando são preservadas em painel/log separado, sem misturar frames de animação.

### Exemplo canônico — linha única por comando

```text
? Executar migração da tabela users? [s/N]              ← aguardando confirmação

⠋ Executando migração da tabela users... (4s)          ← execução ativa, spinner ciano
⠙ Executando migração da tabela users... (4.1s)        ← próximo frame na MESMA linha

✔ Migração da tabela users concluída! (5.2s)           ← conclusão validada

✖ Falha ao conectar ao banco de dados. (1.1s)          ← exemplo de erro
```

Os exemplos acima são **estados alternativos** e frames sucessivos, não cinco linhas a anexar ao log. Quando a aplicação diferencia operação de tarefa/runbook, usar uma linha de resumo da tarefa e uma linha por comando ativo; a linha-pai agrega o estado dos filhos, sem simular execução para ações não iniciadas. Em etapas opacas, só mostrar a etapa inteira, a menos que o próprio script emita checkpoints instrumentados.

### Tokens de estilo e comportamento

| Elemento | Estilo de referência | Regra |
|---|---|---|
| Spinner | Ciano `#00A3FF` / equivalente ANSI ciano | 10 quadros Braille `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`, alternando a cada **80–100 ms**, limitado a aproximadamente 10–12,5 frames/s enquanto ativo |
| Texto principal | Cor de primeiro plano do tema, legível | `Executando <descrição legível>...`; comando real redigido disponível nos detalhes, nunca exibir token/senha |
| Metadados | Cinza/esmaecido (`dim`) | Tempo decorrido `(4s)`, `(5.2s)`, `(1m12s)`; progresso percentual só se houver fonte real verificável |
| Aguardando ação | `?` neutro ou amarelo | Exibir pergunta e ação padrão segura, como `[s/N]`; **não** iniciar spinner antes de consentimento |
| Concluído | `✔` verde + frase conclusiva | Somente depois de `exitCode=0` e da pós-verificação exigida; substituir o spinner, manter duração |
| Erro | `✖` vermelho + causa curta | Exibir falha real, duração e código/categoria nos detalhes; nenhuma mensagem genérica que esconda erro |
| Aguardando/pausado | `?` amarelo + `Aguardando ação` | Pausar spinner durante prompts/UAC/input que dependam do usuário |
| Verificando | `◌` neutro + `Verificando resultado...` | Processo já encerrou, mas pós-condição está pendente; não declarar sucesso antes da verificação |
| Cancelado/timeout/reinício | `!` amarelo + estado explícito | Parar animação; preservar motivo, resultado e próximos passos |
| Sem TTY/acessibilidade | `[RUNNING]`, `[OK]`, `[FAIL]` | Sem frames repetidos nem dependência de Braille/Nerd Fonts |

Ciano `#00A3FF` é uma **preferência visual**, não uma exigência de truecolor: quando indisponível, usar a cor ANSI mais próxima; sob `NO_COLOR`, usar monocromático, mantendo texto e símbolos de estado. O texto atenuado não deve perder contraste essencial. Os símbolos finais `✔/✖` também têm fallback ASCII `[OK]/[FAIL]`. Evitar emojis multicoluna; preservar o layout sob fontes e encodings diferentes.

**Timer:** usar relógio monotônico no processo de renderização, iniciando em `command.started` e congelando em `command.finished` ou equivalente; não zerar ao redesenhar/rolar. Sugestão: durante a execução mostrar segundos inteiros, ou um decimal quando disponível; após a conclusão, exibir a duração final com até uma casa decimal, e `m/s` para períodos longos. O tempo decorrido não prova progresso real nem substitui heartbeat do supervisor.

### Máquina de estados canônica

```text
[?] Aguardando autorização
    ├── Não autorizado ──> [-] Cancelado (sem iniciar o comando)
    └── Autorizado ──> [⠋] Executando (timer + spinner)
                           ├── [?] Aguardando ação ──> [⠋] Retomado
                           ├── [!] Cancelado / Timeout / Interrompido
                           └── Processo terminou ──> [◌] Verificando
                                                        ├── [✔] Sucesso confirmado
                                                        ├── [✖] Pós-verificação falhou
                                                        └── [!] Reinício necessário
```

Um processo não iniciado, uma falha de spawn ou recusa de consentimento **nunca** ganha spinner fictício. Terminar com código zero não significa, por si, que o runbook alcançou o estado desejado. Eventos tardios/duplicados não podem ressuscitar estados terminais. Em perda de comunicação, reconciliar com o supervisor/processo; se isso falhar, mostrar `Interrompido/Estado desconhecido`, não spinner eterno. A interface nunca altera a semântica Test/Plan/Apply/Verify nem mascara falhas.

### Renderização no terminal, título e logs

- O renderizador (TUI PowerShell atual ou Rust/Ratatui futuro) processa eventos estruturados `runId/taskId/stepId/commandId`; **não** observa `kill -0`/stdout como única fonte de verdade e **não** executa strings arbitrárias via `eval`, `bash -c` ou `Invoke-Expression`.
- Atualizar só as linhas afetadas a cada tick (80–100 ms) e não emitir uma linha nova por frame; não interromper leitura de stdout/stderr, input ou cancelamento. A renderização pode desacelerar em terminais lentos; a execução jamais deve depender do FPS.
- Suportar várias tarefas simultâneas sem colisão. Quando largura for insuficiente, truncar apenas a descrição visual e manter ícone/estado/timer; caminho e comando completos e **sanitizados** permanecem nos detalhes. Redimensionamentos e saída intensa não podem apagar prompts nem quebrar painel.
- Durante a execução, se houver suporte detectado e o DS1 controlar a sessão, refletir a tarefa ativa no **título da aba/janela**, por exemplo `⠋ DS1 — Migração users (4s)`; o comportamento pode ser desativado e deve restaurar o título anterior em sucesso/erro/Ctrl+C/exceção. A atualização de título não é garantia em todo Windows Terminal/Console Host; no Windows, usar somente mecanismo compatível e nunca injetar OSC quando saída estiver redirecionada. O spinner inline independe do título.
- PowerShell 5.1 no bootstrap e terminais sem Braille usam spinner ASCII (`| / - \`), ou estado textual estático se cursor/host não permitir animação. `DS1_NO_SPINNER=1`, sem TTY, leitor de tela ou movimento reduzido desativam animação (sem desativar diagnósticos). `NO_COLOR` desativa apenas as cores.
- **Logs persistidos** (`events.jsonl`, stdout/stderr, export, transcript) contêm somente transições, tempos, resultados e saída real do processo com segredos redigidos. Frames, retornos de carro usados para redesenhar, códigos ANSI/OSC e títulos de janela não pertencem ao log. Quando `Start-Transcript` ou host não permitir separar renderização e transcript com segurança, usar o modo textual estático.
- Usar `[s/N]` somente como exemplo de interação em português: a opção negativa é padrão para ações mutáveis; não pedir/registrar senhas na TUI.

**Matriz mínima de aceite:** comando silencioso ≥5 s, tempo crescente e ≥2 quadros distintos; atualização a cada 80–100 ms em host apropriado sem travar a UI; sucesso com verificação, exit 0 mas verificação negativa, falha de spawn, exit 1, timeout, cancelamento, UAC/entrada pendente, dois ou mais comandos concorrentes, resize 80×24/120×32, Windows Terminal/Console Host, sem TTY, `NO_COLOR`, `DS1_NO_SPINNER=1`, Unicode indisponível, logs sem frames/segredos e restauração de título. Referências: [002](../specs/002-safe-executor-contract/spec.md), [008](../specs/008-yaml-v2-runner/spec.md), [009](../specs/009-rust-tui-release/spec.md).


![Console durante a execução](assets/tui-execucao.svg)

Ctrl+C solicita cancelamento pelo motor. Para operação que não pode ser interrompida com segurança, mostrar “Cancelamento pendente” e não iniciar a próxima tarefa. Não afirmar rollback universal de instaladores. Encerrar processo à força é uma ação separada e explícita.

## Compatibilidade Windows e execução interativa

- PowerShell é o shell; Console Host/Windows Terminal são hospedeiros. Testar ambos, sem exigir instalar Terminal.
- Layout completo a partir de 120×32 caracteres; entre 80×24 e esse limite usar lista + detalhes alternáveis; abaixo disso oferecer modo linear. Não redimensionar a janela do usuário à força.
- Tema DS1 Modern Terminal: fundo escuro, bordas muted, cursor violeta, checkbox ciano, spinner azul-ciano, permissão amarela, sucesso verde e erro vermelho; degradar para paleta ANSI/monocromática. Não depender de RGB/ANSI no bootstrap.
- Bordas arredondadas discretas na TUI Rust quando Unicode compatível; fallback para borda simples e texto monoespaçado; sem Nerd Fonts, emojis ou glyphs obrigatórios. Testar acentos e caminhos Unicode; restaurar encoding/cursor/cores ao sair.
- Sessão sem console interativo, saída redirecionada, ISE ou terminal incompatível: modo textual com as mesmas confirmações e diagnósticos, sem entrar em loop de teclas.
- UAC, falha de spawn, exceção, Ctrl+C e resize devem restaurar estado do console. Não limpar o histórico de diagnóstico ao sair.
- Pipes/eventos estruturados são padrão para execução não interativa. Tarefas que exigem terminal real usam adaptador ConPTY validado em Windows, com canal de controle separado. Saída de PTY pode combinar stdout/stderr: registrar como terminal, sem atribuir uma origem fictícia.
- O motor persiste logs enquanto a UI mantém apenas uma janela limitada de linhas. Não acumular toda saída de instalações na memória; logs excluem segredos e não capturam senhas digitadas.

## Implementação incremental vinculada ao plano

| Entrega | Marco | Resultado e aceite |
|---|---|---|
| B1 — Renderizador inicial | M1 | Tela nativa PS5.1, fallback linear, resize/foco/teclas, sem dependências |
| B2 — Estados e consentimento | M1 | UAC, descoberta PS7, recusa, MSI e reboot integrados; mesmos handlers, sem duplicar regras |
| B3 — Diagnóstico persistente | M1/M2 | Erro real visível no filho e pai, console/log acessível; regressões dos testes de campo preservadas |
| U1 — Esqueleto Rust | M10 | Catálogo global 23/77 e detalhe de runbook 40/60 + rodapé, tema DS1 Modern Terminal, estados e navegação j/k/Espaço/a por fixtures; mock não instala |
| U2 — Catálogo e planos | M2–M4/M10 | Catálogo real, bloqueios, versões e lotes via protocolo; sem IDs fixos na UI |
| U3 — Execução visível | M2/M10 | Streaming, scroll, confirmação, cancelamento, resultado e logs automáticos |
| U4 — Pacote Windows | M11 | Artefato pré-compilado, verificação e transição bootstrap → TUI sem Cargo no host |

Desenvolver B1–B3 após estabilizar a detecção atual. U1 pode usar fixtures para validar experiência, mas não deve mascarar o trabalho pendente do motor; U2/U3 exigem seus contratos. Esta especificação detalha M1/M10/M11, não declara esses marcos concluídos nem muda o contrato v1 dos runbooks.

## Matriz de aceite visual e funcional

- [ ] Windows limpo com PS5.1 e Console Host exibe bootstrap sem instalação prévia de UI.
- [ ] PS7 já instalado é mostrado e reutilizado; alias inacessível gera aviso individual.
- [ ] UAC aceito, recusado e com outra conta têm resultados distintos e legíveis.
- [ ] Autorização de instalar PS7 é separada da autorização de elevar.
- [ ] PS5.1/PS7 em Console Host e Windows Terminal; telas 80×24, 120×32 e resize durante log.
- [ ] Caminhos com espaços/acentos e temas de alto contraste legíveis, sem fonte especial.
- [ ] Teclas em busca não disparam ações; Enter no catálogo ou lista de passos não aplica; confirmação posterior começa em cancelar.
- [ ] Visualizar catálogo 23/77 e runbook 40/60 com rodapé; `j/k`, Espaço, `a`, Tab e foco `❯` testados em lista longa.
- [ ] Seleção múltipla permanece por IDs após filtro/scroll; checkbox distinto de status; bloqueados/Não implementados não são selecionados pelo `a`; plano mostra dependências sem instalá-las silenciosamente.
- [ ] Painel direito mantém detalhes e logs vivos com scroll, auto-follow e prompts no rodapé, sem perder dados persistidos.
- [ ] Tema com borda rounded e fallback, cores semânticas, `NO_COLOR`, contraste revisado e estado legível apenas por texto.
- [ ] Uma tarefa nova aparece sem alterar a UI, respeitando manifestos e dependências.
- [ ] Logs de saída intensa permanecem completos no arquivo, memória de UI limitada e rolagem responsiva.
- [ ] Erro anterior à transcrição, falha nativa e cancelamento não fecham o diagnóstico.
- [ ] Modo textual preserva funcionalidade em terminal incompatível.
- [ ] Retorno ao terminal restaura cursor, cores e modo de entrada; nenhuma instalação é anunciada sem pós-verificação.

## Primeira implementação funcional (PowerShell 7)

O menu provisório foi substituído por um layout nativo PowerShell com categorias derivadas dos manifestos (`Category`), box de tarefas, rodapé de comandos, busca, seleção de versão, Test/Plan/Apply e confirmação. O preflight roda antes de abrir o catálogo; os consentimentos de correção são modais textuais. Em Console Host sem 80×24 ou com entrada/saída redirecionada, permanece o menu linear. Ao executar uma tarefa, a lista cede lugar à saída do comando, retornando após Enter. O log atual é `Start-Transcript`; a captura integral de processos e a TUI Rust ainda pertencem aos marcos M2/M10. Testes automatizados cobrem o motor; testes interativos Windows permanecem necessários para homologar navegação, cores e redimensionamento.
