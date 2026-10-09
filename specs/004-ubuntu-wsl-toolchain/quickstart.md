# Quickstart e plano de validação: 004 — WSL2 Ubuntu e toolchain Linux

> Estes passos são um roteiro de **validação futura**, não uma confirmação de que funcionalidades existem. Nunca rodar Apply em host corporativo, com dados não descartáveis ou sem permissão.

## Antes de começar
1. Fazer checkout da branch `feat/004-ubuntu-wsl-toolchain` derivada de `main` atualizado.
2. Preparar VM snapshot ou ambiente isolado específico; registrar OS, arquitetura, PowerShell e estado das ferramentas.
3. Executar **somente** smoke tests não-mutáveis primeiro. Confrontar resultados com [spec.md](spec.md).
4. Aplicações reais requerem confirmação do usuário e snapshot restaurável, nunca CI compartilhado.

## Verificação automatizada segura
```powershell
python tools/check_specs.py
wsl --status; wsl --list --verbose
wsl -d <DISTRO> -- bash -lc 'command -v java; java -version; command -v mvn; mvn -version; command -v gradle; gradle --version'
```

Os comandos listados podem exigir ferramentas pré-instaladas e shell de plataforma. Substituir os marcadores de distro/paths pela configuração observada e **não** tomar falha por ausência de implementação como sucesso.

## Cenários de homologação
1. **AC-004-01** — WSL ausente apresenta Plan e PendingReboot quando necessário; não tenta prosseguir antes de reinicialização. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
2. **AC-004-02** — Distro inicializada e apt/SDKMAN/JDK21/Maven/Gradle passam em sessão Bash nova sem depender do host PATH. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
3. **AC-004-03** — Com duas distros, operação só modifica a distro indicada pelo usuário. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
4. **AC-004-04** — Apply×2 não duplica init do SDKMAN nem reinstala componentes satisfeitos. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
5. **AC-004-05** — Falha apt ou SDKMAN retorna exit code e mensagem sem marcar Installed e sem gravar senhas. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.

## Testes negativos obrigatórios
- Simular dependência ausente, retorno não zero e recusa de confirmação: nenhum success falso.
- Repetir Test/Plan e comparar estado/diff do filesystem/registry quando aplicável.
- Executar Apply novamente em VM e comparar estado sem duplicações.
- Garantir logs redigidos; preservar arquivo de diagnóstico quando falhar.
- Confirmar que `Implemented=false` impede Apply enquanto recurso não estiver completo.

## Resultado da fase
- **PASS** apenas se todos os critérios AC-004 tiverem evidências.
- **BLOCKED** quando ambiente necessário estiver indisponível; registrar sem forçar execução.
- **FAIL** se operação parcial, privilégio indevido ou falso sucesso forem detectados.
- Revisar rollback: Desabilitar passos de integração por opt-in, não executar wsl --unregister e nunca apagar distro/dados.
