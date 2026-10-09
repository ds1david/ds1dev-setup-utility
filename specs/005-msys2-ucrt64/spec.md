# Feature Specification: 005 — MSYS2 UCRT64 funcional e isolado

**Status:** Proposta para execução futura; não certifica código pronto.
**Feature branch recomendada:** `feat/005-msys2-ucrt64`
**Fonte:** Git atual + wiki Notion (consulta 2026-10-09). **Dependências:** 002 aprovado; Windows suportado e instalador MSYS2 revisado.

## Contexto
MSYS2 UCRT64 instalado com gerenciador pacman, GCC/CMake/Ninja e perfil de Terminal verificável.

O repositório já contém implementação parcial e testes. A entrega desta fase deve ser um delta pequeno, verificável e isolado da infraestrutura existente. Não recriar o projeto do zero e não assumir que exemplos de documentação já funcionem.

## Histórias de usuário
- **US1 (P1):** Como usuário quero preparar toolchain nativa MSYS2 UCRT64 sob demanda sem trocar o Bash principal.
- **US2 (P2):** Como usuário com MSYS2 fora de C:\msys64 quero detectar o diretório real e preservar minha instalação.
- **US3 (P3):** Como mantenedor quero verificar a cadeia GCC e CMake com compilação pequena sem modificar projetos do usuário.

## Requisitos
- **FR-005-01:** Detectar instalação MSYS2 e UCRT64 sem caminho fixo; escolher explicitamente MSYSTEM=UCRT64.
- **FR-005-02:** Executar pacman -Syu com eventuais reaberturas exigidas, sem declarar sucesso prematuro.
- **FR-005-03:** Instalar Git, GCC/G++, Make/Autotools, CMake e Ninja por pacotes corretos do prefixo UCRT64.
- **FR-005-04:** Criar perfil Windows Terminal somente se autorizado e verificar startup diretório correto; não iniciar em System32.
- **FR-005-05:** Separar /workspace MSYS2 do C:\workspace Windows e do /workspace Ubuntu; PATH e caches exclusivos.

## Critérios de aceite
- **AC-005-01:** Em VM com MSYS2 ausente, Plan demonstra instalação e Apply autorizado passa validações do UCRT64.
- **AC-005-02:** MSYSTEM retornado é UCRT64 e gcc -dumpmachine corresponde ao target Windows MinGW.
- **AC-005-03:** Compilação C++ de teste via CMake + Ninja completa em pasta temporária com limpeza controlada.
- **AC-005-04:** Segundo Apply não duplica perfil Terminal nem PATH e não atualiza pacotes desnecessários.
- **AC-005-05:** Se pacman precisar reinício da shell, runbook retorna estado pendente e orienta usuário, sem loops infinitos.

## Não escopo
Mover repositórios entre filesystems, instalar IDEs ou compartilhar local/bin com WSL.

## Condições não funcionais e segurança
- Ações mutáveis somente via confirmação; testes e planos sem efeitos colaterais.
- Falha deve ser explícita, não transformar erro em `Installed` nem mascarar `exit code`.
- Registrar evidência e versão, redigindo segredo e preservando identidade.
- Regressão dos comandos/IDs atuais proibida salvo migração deliberada e testada.

## Fontes e rastreabilidade
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f678125addff0e3fa032ded
- Wiki Notion: https://app.notion.com/p/3f3bf4c17f6781ceb904c318f64a327b
- Git: `runbooks/04/runbook.ps1`
- Git: `runbooks/04.1/runbook.ps1`
- Git: `docs/04-msys2.md`
- Git: `docs/04.1-toolchain-msys2.md`
- Constituição: `../../.specify/memory/constitution.md`
- Rastreabilidade: `../../docs/notion-runbook-traceability.md`

## Métricas e evidência de saída
- 100% dos critérios AC desta fase demonstrados em testes e/ou ensaio manual controlado.
- Dois Apply consecutivos quando aplicável, com ausência de mutação redundante.
- Caminhos negativos testados e reportados no PR, junto de limitações de plataforma.
- Nenhum `Implemented=true` sem prova real de pós-condição.
