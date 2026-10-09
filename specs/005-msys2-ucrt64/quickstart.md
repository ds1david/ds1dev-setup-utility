# Quickstart e plano de validação: 005 — MSYS2 UCRT64 funcional e isolado

> Estes passos são um roteiro de **validação futura**, não uma confirmação de que funcionalidades existem. Nunca rodar Apply em host corporativo, com dados não descartáveis ou sem permissão.

## Antes de começar
1. Fazer checkout da branch `feat/005-msys2-ucrt64` derivada de `main` atualizado.
2. Preparar VM snapshot ou ambiente isolado específico; registrar OS, arquitetura, PowerShell e estado das ferramentas.
3. Executar **somente** smoke tests não-mutáveis primeiro. Confrontar resultados com [spec.md](spec.md).
4. Aplicações reais requerem confirmação do usuário e snapshot restaurável, nunca CI compartilhado.

## Verificação automatizada segura
```powershell
python tools/check_specs.py
pacman --version
gcc -dumpmachine; cmake --version; ninja --version
```

Os comandos listados podem exigir ferramentas pré-instaladas e shell de plataforma. Substituir os marcadores de distro/paths pela configuração observada e **não** tomar falha por ausência de implementação como sucesso.

## Cenários de homologação
1. **AC-005-01** — Em VM com MSYS2 ausente, Plan demonstra instalação e Apply autorizado passa validações do UCRT64. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
2. **AC-005-02** — MSYSTEM retornado é UCRT64 e gcc -dumpmachine corresponde ao target Windows MinGW. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
3. **AC-005-03** — Compilação C++ de teste via CMake + Ninja completa em pasta temporária com limpeza controlada. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
4. **AC-005-04** — Segundo Apply não duplica perfil Terminal nem PATH e não atualiza pacotes desnecessários. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
5. **AC-005-05** — Se pacman precisar reinício da shell, runbook retorna estado pendente e orienta usuário, sem loops infinitos. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.

## Testes negativos obrigatórios
- Simular dependência ausente, retorno não zero e recusa de confirmação: nenhum success falso.
- Repetir Test/Plan e comparar estado/diff do filesystem/registry quando aplicável.
- Executar Apply novamente em VM e comparar estado sem duplicações.
- Garantir logs redigidos; preservar arquivo de diagnóstico quando falhar.
- Confirmar que `Implemented=false` impede Apply enquanto recurso não estiver completo.

## Resultado da fase
- **PASS** apenas se todos os critérios AC-005 tiverem evidências.
- **BLOCKED** quando ambiente necessário estiver indisponível; registrar sem forçar execução.
- **FAIL** se operação parcial, privilégio indevido ou falso sucesso forem detectados.
- Revisar rollback: Nunca remover pacotes de usuário ou MSYS2 preexistente; reverter somente entradas de PATH/profile geradas com backup.
