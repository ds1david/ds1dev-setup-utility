# Quickstart e plano de validação: 002 — Executor seguro, catálogo e diagnóstico sem admin

> Estes passos são um roteiro de **validação futura**, não uma confirmação de que funcionalidades existem. Nunca rodar Apply em host corporativo, com dados não descartáveis ou sem permissão.

## Antes de começar
1. Fazer checkout da branch `feat/002-safe-executor-contract` derivada de `main` atualizado.
2. Preparar VM snapshot ou ambiente isolado específico; registrar OS, arquitetura, PowerShell e estado das ferramentas.
3. Executar **somente** smoke tests não-mutáveis primeiro. Confrontar resultados com [spec.md](spec.md).
4. Aplicações reais requerem confirmação do usuário e snapshot restaurável, nunca CI compartilhado.

## Verificação automatizada segura
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
pwsh -NoProfile -File tests/preflight.tests.ps1
pwsh -NoProfile -File tests/task-phases.tests.ps1
```

Os comandos listados podem exigir ferramentas pré-instaladas e shell de plataforma. Substituir os marcadores de distro/paths pela configuração observada e **não** tomar falha por ausência de implementação como sucesso.

## Cenários de homologação
1. **AC-002-01** — Com usuário padrão e runbooks não implementados, -List/-Plan/-Validate terminam sem UAC, escrita em ProgramData protegido ou outras mutações. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
2. **AC-002-02** — PSD1 v1 continua carregando todos os IDs existentes e bloqueando Apply com Implemented=false. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
3. **AC-002-03** — Manifesto malicioso ou inválido é rejeitado antes de executar qualquer script. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
4. **AC-002-04** — Apply com confirmação recusada não executa ação; Apply permitido verifica estado final e trata falhas de comando nativo. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
5. **AC-002-05** — Testes de contrato e de logs demonstram ausência de segredos e distinção de sucesso, parcial, bloqueado e erro. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.

## Testes negativos obrigatórios
- Simular dependência ausente, retorno não zero e recusa de confirmação: nenhum success falso.
- Repetir Test/Plan e comparar estado/diff do filesystem/registry quando aplicável.
- Executar Apply novamente em VM e comparar estado sem duplicações.
- Garantir logs redigidos; preservar arquivo de diagnóstico quando falhar.
- Confirmar que `Implemented=false` impede Apply enquanto recurso não estiver completo.

## Resultado da fase
- **PASS** apenas se todos os critérios AC-002 tiverem evidências.
- **BLOCKED** quando ambiente necessário estiver indisponível; registrar sem forçar execução.
- **FAIL** se operação parcial, privilégio indevido ou falso sucesso forem detectados.
- Revisar rollback: Backout de novo dispatcher mantendo contrato v1; logs antigos continuam legíveis.
