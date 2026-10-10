# Quickstart: 009 — TUI Rust/Ratatui e distribuição confiável

> Roteiro de ensaio FUTURO em VM restaurável. Executar somente ações não mutáveis no host normal. A lista abaixo **não confirma** que os recursos já existem.

## Preparar
1. Fazer checkout da branch `feat/009-rust-tui-release` e registrar commit SHA, OS e versão de pwsh.
2. Revisar [spec.md](spec.md), constituição e matriz Notion; selecionar VM sem dados não recuperáveis.
3. Antes de qualquer Apply, executar Test/Plan, verificar suas saídas e observar se arquivos/PATH/registry mudaram.
4. Obter confirmação específica do usuário para cada execução mutável.

## Verificações seguras / dependentes de ambiente
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
cargo test
```
Marcadores como distro/paths devem ser substituídos pelo valor **observado**, nunca assumir valores fixos. A ausência de `cargo`, `docker` ou `gcc` é estado `Blocked/NotInstalled`, não conclusão.

## Cenários observáveis
1. **AC-009-01:** TUI lista todos os runbooks que CLI lista, com dependências e estados equivalentes. Capturar versões, saída, código de retorno e estado após execução.
2. **AC-009-02:** Abertura/fechamento, navegação, busca, Test e Plan não provocam instalação nem alteração de PATH. Capturar versões, saída, código de retorno e estado após execução.
3. **AC-009-03:** Confirmação recusada cancela seleção inteira ou ação indicada sem Apply oculto. Capturar versões, saída, código de retorno e estado após execução.
4. **AC-009-04:** Erros de subprocesso, pending reboot e logs continuam visíveis na interface e exportáveis de forma redigida. Capturar versões, saída, código de retorno e estado após execução.
5. **AC-009-05:** Pacote release inclui checksums e processo de verificação documentado; teste de instalação a partir de Windows limpo registra evidências. Capturar versões, saída, código de retorno e estado após execução.
6. **AC-009-06:** Rodar fixture inofensiva que dorme por pelo menos 5 segundos sem produzir saída; registrar frames distintos, tempo decorrido, comando sanitizado e troca por status final até o primeiro refresh. Repetir com falha exit code 1, timeout, Ctrl+C, erro de spawn e sucesso de processo com pós-condição falsa.
7. **AC-009-07:** Rodar em Windows Terminal e Console Host, janelas 80×24 e 120×32; repetir com `DS1_NO_SPINNER=1`, stdout redirecionado e fallback ASCII. Verificar que logs não contêm frames/OSC e que o título original é restaurado quando o recurso estiver ligado.
8. **AC-009-08:** Simular três comandos concorrentes e eventos duplicados/atrasados. Verificar spinner e duração por comando; finalizar em ordem distinta e comprovar que nenhum indicador ativo fica órfão. Em prompt de confirmação, mostrar `Aguardando ação`, não animação enganosa.
9. **AC-009-09:** Registrar fixture interativa com 10 frames Braille, intervalo nominal de 80–100 ms, spinner ciano `#00A3FF` ou ANSI ciano, timer cinza/esmaecido e descrição legível atualizados na MESMA linha; verificar final `✔` verde ou `✖` vermelho com causa e duração. Testar monocromático e contraste.
10. **AC-009-10:** Repetir fluxo `? Confirmar [s/N]` → `⠋ Executando... (4s)` → `◌ Verificando resultado...` → resultado; reprovação/negação não provoca `running` e processo com exit 0 mas pós-checagem negativa nunca recebe `✔`. Testar título ativo/restaurado e modo sem animação.

## Resistência a falhas
- Dependência ausente: erro claro, não auto-instalação.
- Operação cancelada: nenhuma mutação.
- Exit code diferente de zero, timeout e dados inválidos: falha sem success falso.
- Segundo Apply: ausência de mudança redundante.
- Logs exportados: sem segredos, com RunId e status real.
- Spinner ativo no silêncio não é prova de progresso: confirmar estado do processo e pós-verificação. Se a UI perder vínculo, mostrar `Interrompido/Estado desconhecido` em vez de animação infinita.

## Resultado
PASS somente para todos AC-009 comprovados; BLOCKED quando faltarem ferramentas/VM; FAIL para divergência de pós-condição, UAC indevido ou mutação inesperada. **Rollback:** Manter CLI/TUI PowerShell como fallback, nunca alterar manifests/runbooks por navegação da UI.
