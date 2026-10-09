@{
    SchemaVersion = 1
    Tasks = @(
        @{ Id='02'; Title='Preparacao Windows'; DependsOn=@(); Script='tasks/02-windows.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='03'; Title='Preparacao WSL2 Ubuntu'; DependsOn=@('02'); Script='tasks/03-wsl.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='04'; Title='Preparacao MSYS2 UCRT64'; DependsOn=@('02'); Script='tasks/04-msys2.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='05'; Title='Workspaces e PATH'; DependsOn=@('02','03','04'); Script='tasks/05-workspaces.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='02.1'; Title='Toolchain Windows'; DependsOn=@('02','05'); Script='tasks/02.1-windows.ps1'; Implemented=$false; SupportsVersions=$true }
        @{ Id='03.1'; Title='Toolchain Ubuntu'; DependsOn=@('03','05'); Script='tasks/03.1-ubuntu.ps1'; Implemented=$false; SupportsVersions=$true }
        @{ Id='04.1'; Title='Toolchain MSYS2'; DependsOn=@('04','05'); Script='tasks/04.1-msys2.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='06'; Title='Personalizacao de shells'; DependsOn=@('05'); Script='tasks/06-shells.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='06.1'; Title='IDEs e integracoes'; DependsOn=@('03','04','05'); Script='tasks/06.1-ides.ps1'; Implemented=$false; SupportsVersions=$false }
        @{ Id='07'; Title='Validacao integrada'; DependsOn=@('02','03','04','05'); Script='tasks/07-validacao.ps1'; Implemented=$false; SupportsVersions=$false }
    )
}
