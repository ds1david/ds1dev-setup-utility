# Quickstart e plano de validação: 003 — Instalação Windows básica, Java/Maven/Gradle

> Estes passos são um roteiro de **validação futura**, não uma confirmação de que funcionalidades existem. Nunca rodar Apply em host corporativo, com dados não descartáveis ou sem permissão.

## Antes de começar
1. Fazer checkout da branch `feat/003-windows-toolchain` derivada de `main` atualizado.
2. Preparar VM snapshot ou ambiente isolado específico; registrar OS, arquitetura, PowerShell e estado das ferramentas.
3. Executar **somente** smoke tests não-mutáveis primeiro. Confrontar resultados com [spec.md](spec.md).
4. Aplicações reais requerem confirmação do usuário e snapshot restaurável, nunca CI compartilhado.

## Verificação automatizada segura
```powershell
python tools/check_specs.py
pwsh -NoProfile -File tests/runbooks.tests.ps1
java -version; javac -version; mvn -version; gradle --version
```

Os comandos listados podem exigir ferramentas pré-instaladas e shell de plataforma. Substituir os marcadores de distro/paths pela configuração observada e **não** tomar falha por ausência de implementação como sucesso.

## Cenários de homologação
1. **AC-003-01** — Em VM Windows limpa, sequência explícita instala Git/Python/JDK21/Maven/Gradle e version checks passam. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
2. **AC-003-02** — Em VM com Java/Maven preexistentes, Plan mostra o que preservar e solicita aprovação antes de modificar seleção. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
3. **AC-003-03** — Apply executado duas vezes não duplica PATH nem reinstala quando estado já atende. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
4. **AC-003-04** — Pacote com checksum inválido é recusado antes de extração e qualquer mudança de ambiente. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.
5. **AC-003-05** — Java -version, javac -version, mvn -version e gradle --version usam origem Windows correta em nova sessão. Registre pré-condição, comando executado, saída/código, evidência de pós-condição e se houve qualquer mutação inesperada.

## Testes negativos obrigatórios
- Simular dependência ausente, retorno não zero e recusa de confirmação: nenhum success falso.
- Repetir Test/Plan e comparar estado/diff do filesystem/registry quando aplicável.
- Executar Apply novamente em VM e comparar estado sem duplicações.
- Garantir logs redigidos; preservar arquivo de diagnóstico quando falhar.
- Confirmar que `Implemented=false` impede Apply enquanto recurso não estiver completo.

## Resultado da fase
- **PASS** apenas se todos os critérios AC-003 tiverem evidências.
- **BLOCKED** quando ambiente necessário estiver indisponível; registrar sem forçar execução.
- **FAIL** se operação parcial, privilégio indevido ou falso sucesso forem detectados.
- Revisar rollback: Backup de PATH e variáveis e instruções de remoção reversível; não remover instalação previamente existente.
