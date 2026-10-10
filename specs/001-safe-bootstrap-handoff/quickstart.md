# Quickstart e plano de validação: 001 — Handoff seguro PS5.1 → UAC → PS7

> Estes passos são um roteiro de **validação futura**, não uma confirmação de que funcionalidades existem. Nunca rodar Apply em host corporativo, com dados não descartáveis ou sem permissão.

## Antes de começar
1. Fazer checkout da branch `feat/001-safe-bootstrap-handoff` derivada de `main` atualizado.
2. Preparar VM snapshot ou ambiente isolado específico; registrar OS, arquitetura, PowerShell e estado das ferramentas.
3. Executar **somente** smoke tests não-mutáveis primeiro. Confrontar resultados com [spec.md](spec.md).
4. Aplicações reais requerem confirmação do usuário e snapshot restaurável, nunca CI compartilhado.

## Verificação automatizada segura
```powershell
python tools/check_specs.py
powershell.exe -NoProfile -File tests/bootstrap.tests.ps1
powershell.exe -NoProfile -File tests/bootstrap-handoff.tests.ps1
pwsh -NoProfile -File tests/bootstrap-discovery.tests.ps1
```

Os comandos listados podem exigir ferramentas pré-instaladas e shell de plataforma. Substituir os marcadores de distro/paths pela configuração observada e **não** tomar falha por ausência de implementação como sucesso.

## Cenários de homologação
1. **AC-001-01** — Execução PS5.1 não elevada com UAC recusado retorna status diferente de zero e mensagem compreensível, sem nova instalação. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
2. **AC-001-02** — Elevação com mesmo usuário e pwsh já instalado inicia uma única instância do executor; janela original não fica presa após abortar. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
3. **AC-001-03** — Processo elevado encerrado inesperadamente e timeout simulado produzem diagnóstico com RunId e caminho de log existente; nenhum processo órfão. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
4. **AC-001-04** — Conta UAC diferente é rejeitada antes de alterar o profile do usuário original. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
5. **AC-001-05** — Testes de bootstrap e handoff existentes passam nos dois shells no Windows; testes negativos documentam evidência. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.

## Testes negativos obrigatórios
- Simular dependência ausente, retorno não zero e recusa de confirmação: nenhum success falso.
- Repetir Test/Plan e comparar estado/diff do filesystem/registry quando aplicável.
- Executar Apply novamente em VM e comparar estado sem duplicações.
- Garantir logs redigidos; preservar arquivo de diagnóstico quando falhar.
- Confirmar que `Implemented=false` impede Apply enquanto recurso não estiver completo.

## Resultado da fase
- **PASS** apenas se todos os critérios AC-001 tiverem evidências.
- **BLOCKED** quando ambiente necessário estiver indisponível; registrar sem forçar execução.
- **FAIL** se operação parcial, privilégio indevido ou falso sucesso forem detectados.
- Revisar rollback: Manter o bootstrap anterior disponível por tag/commit; alteração só em branch; falha operacional encerra sem mutação irreversível.
