# 07 — Validação integrada

## Regras de aceite
- Revalidar o estado real de cada ambiente, mesmo que haja registro anterior de sucesso.
- Impedir toolchains Ubuntu se wsl.exe não reportar a distro instalada em versão 2 e funcional.
- Impedir ferramentas UCRT64 se MSYS2 não iniciar e não reportar MSYSTEM=UCRT64.
- Inspecionar versões efetivas de Java, Maven, Gradle, Python, Git, GCC e Docker por ambiente.
- Testar PATH e resolução dos executáveis, bem como diretórios nativos distintos.
- Confirmar que SDKMAN, `JAVA_HOME`, perfis Bash, PSReadLine e completions sobrevivem a uma nova sessão.
- Verificar as idempotências: segunda execução não reinstala/duplica PATH, não recria perfil, nem modifica mount que já está correto.
- Todas as etapas reportam exit code, stdout, stderr, evidência, versão efetiva e resultado final.

## Exemplos
```powershell
wsl.exe -l -v
wsl.exe -d Ubuntu-26.04 -- bash -lc 'java -version; mvn -version; gradle --version'
```

```bash
test -d /workspace/local/config
command -v java
command -v mvn
command -v gradle
```

Use o nome exato da distro instalada. A TUI não deve atribuir resultado `Installed` apenas com base na existência de arquivos JSON de estado.