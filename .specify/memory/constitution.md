# Constituição — DS1 Dev Setup Utility

> Versão 1.0.0 | Ratificação inicial: 2026-10-09 | Estado: base para discussão e execução com Spec Kit.

## I. Segurança, privilégio mínimo e consentimento
Toda operação mutável deve exigir escolha e confirmação explícitas, comunicar efeitos e delimitar privilégios ao necessário. Test/Plan nunca alteram máquina, profiles, registro, rede ou filesystem. Recusar elevar identidade de usuário distinta; tokens e senhas nunca em logs. Download verificado por HTTPS + hash/assinatura quando disponível; nunca executar código remoto não verificado.

## II. Estado observado e idempotência
Não confiar somente em histórico ou flag de catálogo. Verificar pré-condição → plano → confirmação → aplicação → verificação do estado realmente observado. Aplicar duas vezes preserva estado sem duplicar PATH, perfil, mount ou instalação. Reboot sempre suspende avanço até nova inicialização pelo usuário.

## III. Evolução de código legado por fatias
`bootstrap.ps1`, `src/*.psm1`, `src/ds1-setup.ps1`, `runbooks/**/*.psd1` e `tests/*.ps1` são ativos existentes. Preservar interface pública, IDs e contrato PSD1 v1 salvo migração compatível e opt-in. Recursos propostos YAML v2, Rust TUI e gerenciadores de versões **não são funcionalidades existentes**.

## IV. Fonte executável local, wiki rastreável
Notion explica objetivo, procedimentos e riscos; Git contém o código revisado que realmente executa. Documentar link e versão/data de consulta da fonte Notion, sem depender dela online. Não executar runbook apenas por ler sua wiki. Traçar docs ↔ runbook ↔ spec ↔ testes.

## V. Separação real de ambientes
Windows NTFS `C:\workspace`, Ubuntu ext4 `/workspace` e MSYS2 UCRT64 `/workspace` dentro da instalação MSYS2 são raízes independentes. Somente pastas explicitamente escolhidas são compartilhadas. IDEs gráficas e Docker Desktop ficam no Windows; routing WSL/MSYS2 declara interpretador e destino sem contaminação de PATH.

## VI. Testabilidade e evidência
Cada feature entrega critério de aceite observável, testes negativos, tratamento de falhas, smoke test seguro, documentação e rollback quando viável. Executar unitários e checks de contrato em Linux/Windows; instalação real somente em ambiente descartável. Preservar logs redigidos e informar limites da cobertura.

## VII. Entrega incremental e ausência de falsos positivos
Fases independentes geram valor útil mesmo sem TUI final. `Implemented` só vira `true` após testes completos da funcionalidade. Uma documentação ou plano não autoriza anúncio de sucesso operacional. Cada PR apresenta gate de saída com evidência; não marcar uma fase como pronta pela simples criação de arquivos.

## VIII. Reprodutibilidade e reversibilidade
Instalação desde Windows 11 limpo (PowerShell 5.1, WinGet opcional) e diagnóstico de máquina configurada. Usar versão fixada, origem oficial, hashes, persistência segura e backups de arquivos a modificar. Reversão não destrutiva por default; operação irreversível precisa de confirmação separada.

## Governança
- Esta constituição prevalece sobre exemplos históricos quando houver conflito, mas divergências com o sistema atual geram tarefas de migração e **não** justificam mudanças ocultas.
- Alteração de princípio exige PR, racional, impacto nas specs afetadas e ajuste semântico da versão.
- Cada spec, plan e tasks referenciam estas regras e exibem suas exceções/decisões.
