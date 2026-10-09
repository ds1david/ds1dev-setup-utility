# 04 — Preparação MSYS2 UCRT64

> Documento migrado do Notion e reorganizado. **Revise caminhos, versões e efeitos antes de aplicar.** A instalação deve ser testada em máquina de laboratório e reexecutada para validar idempotência.


## 1. Pré-requisitos e diagnóstico
Concluir etapas 01 (Windows/PowerShell/Terminal/Git/Python) e 02 (Ubuntu WSL2 instalado e validado). **Não criar diretórios nem links do workspace agora**; os guias B/E dependem do MSYS2 instalado. MSYS2 é um ambiente POSIX para compilar binários Windows em NTFS, não um filesystem separado.
**Fonte oficial:** [MSYS2 — instalação e downloads](https://www.msys2.org/). Consulte também [ambientes](https://www.msys2.org/docs/environments/) e [pacotes](https://packages.msys2.org/).
## 2. Instalação do MSYS2 UCRT64
No PowerShell 7:
```powershell
winget search --id MSYS2.MSYS2 -e
winget install --id MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
```
Ou baixe o instalador no site oficial. Anote o caminho; padrão comum: `C:\msys64`. Abra **MSYS2 UCRT64** pelo Menu Iniciar, evitando confundir com MSYS/MINGW64/CLANG64. Teste `echo "$MSYSTEM"` = `UCRT64`.
## 3. Atualizações do pacman
No UCRT64:
```bash
pacman -Syu
```
Se o pacman atualizar componentes básicos e solicitar fechar o terminal, feche e reabra o ambiente **UCRT64**, repetindo `pacman -Syu` até concluir. Somente então avance à instalação dos pacotes.
## 5. Integração ao Windows Terminal
No PowerShell:
```powershell
$MsysRoot='C:\msys64'
Test-Path "$MsysRoot\msys2_shell.cmd"
Test-Path "$MsysRoot\ucrt64.exe"
```
Windows Terminal → Configurações (`Ctrl+,`) → Adicionar perfil → Novo perfil vazio:
- **Nome:** `MSYS2 UCRT64`.
- **Linha de comando:** `C:\msys64\msys2_shell.cmd -defterm -here -no-start -ucrt64` (ajuste para diretório real).
- **Diretório inicial:** `%USERPROFILE%` enquanto `C:\workspace` não existir; depois pode usar `C:\workspace`.
- **Ícone:** selecione um ícone válido do próprio MSYS2 se encontrado.
Salve, abra nova aba, confira `echo "$MSYSTEM"` = `UCRT64` e `command -v gcc` apontando para `/ucrt64/bin/gcc`. PowerShell 7 continua perfil padrão.
## 6. Validação de pacotes e compilação
```bash
echo "$MSYSTEM"
command -v git gcc g++ make autoconf automake libtool cmake ninja
git --version
gcc --version
gcc -dumpmachine
autoconf --version | head -n 1
automake --version | head -n 1
libtool --version | head -n 1
cmake --version | head -n 1
ninja --version
tmp="$(mktemp -d)"
printf '#include <stdio.h>\nint main(void){puts("UCRT64 OK");return 0;}\n' > "$tmp/check.c"
gcc "$tmp/check.c" -o "$tmp/check.exe"
"$tmp/check.exe"
rm -rf -- "$tmp"
```
Esperado: MSYSTEM=UCRT64, compilador GCC em `/ucrt64/bin` e o teste imprimindo `UCRT64 OK`. Algumas ferramentas Autotools residem em `/usr/bin`.
## 7. Dependências das próximas etapas
A estrutura MSYS2 e o PATH próprio são documentados no (consulte índice deste repositório). Use /workspace/local/\{bin,env,config\} dentro da instalação MSYS2, jamais /opt/local/bin ou /c/workspace/local/bin como substituto.
Seguir (consulte índice deste repositório), (consulte índice deste repositório), (consulte índice deste repositório). Não criar estrutura enquanto falta ambiente.
## Checklist
- [ ] Instalador de fonte oficial, diretório da instalação registrado
- [ ] pacman atualizado (reabertura UCRT64 quando necessária)
- [ ] Git, GCC/G++, Autotools, CMake e Ninja disponíveis
- [ ] Perfil UCRT64 criado no Windows Terminal e validado
- [ ] Compilação de teste aprovada
- [ ] Pronto para criar estruturas de pastas
---


[Voltar ao índice](01-indice.md)
