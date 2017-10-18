Configuration WiniKubeBase {

    # Before Hyper-V- or Virtualbox-specific config.
    # Not compiled directly, called on by the other configurations.

    Import-DSCResource -ModuleName PsDesiredStateConfiguration
    Import-DSCResource -Module xPsDesiredStateConfiguration

    Node $AllNodes.NodeName {

        # ensure  paths exist
        File BasePath {
            DestinationPath = $ConfigurationData.Paths.Base
            Type = 'directory'
        }
        foreach ($path in $ConfigurationData.Paths.GetEnumerator()) {
            File $path.key {
                DestinationPath = $path.value
                Type = 'directory'
                DependsOn = "[File]BasePath"
            }
        }

        # ensure the `bin` folder is in $PATH
        Script SetPath {
            GetScript = { return @{ 'result' = "$Env:Path" } }
            SetScript = {
                $BinPath = "$Using:ConfigurationData.Paths.Bin"
                [Environment]::SetEnvironmentVariable("Path", "${BinPath};${Env:Path}", "Machine")
            }
            TestScript = {
                $exists = $Env:Path | select-string "$Using:ConfigurationData.Paths.Bin"
                if ($exists -ne $null) {
                    return $true
                } else {
                    return $false
                }
            }
        }

        # download & install kubectl
        xRemoteFile kubectl {
            Uri = 'https://storage.googleapis.com/kubernetes-release/release/v' + $ConfigurationData.Versions.Kubectl + '/bin/windows/amd64/kubectl.exe'
            DestinationPath = $ConfigurationData.Paths.Bin + '/kubectl.exe'
            DependsOn = "[File]Bin"
        }

        # download & install minikube
        xRemoteFile minikube {
            Uri = 'https://storage.googleapis.com/minikube/releases/v' + $ConfigurationData.Versions.Minikube + '/minikube-windows-amd64.exe'
            DestinationPath = $ConfigurationData.Paths.Bin + '/minikube.exe'
            DependsOn = "[File]Bin"
        }

        # download & install kd
        xRemoteFile kd {
            Uri = 'https://github.com/UKHomeOffice/kd/releases/download/v' + $ConfigurationData.Versions.Kd + '/kd_darwin_amd64'
            DestinationPath = $ConfigurationData.Paths.Bin + '/kd.exe'
            DependsOn = "[File]Bin"
        }
    }
}

Configuration WiniKubePost {

    # After Hyper-V- or Virtualbox-specific config.
    # Not compiled directly, called on by the other configurations.

    Import-DSCResource -ModuleName PsDesiredStateConfiguration
    Import-DSCResource -Module xPsDesiredStateConfiguration
    Import-DSCResource -Module xPendingReboot
    Import-DSCResource -Module xHyper-V
    Import-DSCResource -Module xNetworking

    Node $AllNodes.NodeName {

        # start minikube, to set configuration
        Script MinikubeStart {
            GetScript = { return @{ 'result' = $null } }
            SetScript = {
                switch ($VmDriver) {
                    hyperv { $args='--vm-driver hyperv --hyperv-virtual-switch WiniKubeNATSwitch' }
                    virtualbox { $args='--vm-driver virtualbox' }
                }
                Invoke-Command -ScriptBlock { $ConfigurationData.Paths.Bin + '\minikube.exe start ' + $args }
            }
            TestScript = { return $false }
        }

        # enable ingress addon
        Script MinikubeEnableIngress {
            GetScript = { return @{ 'result' = $null } }
            SetScript = {
                Invoke-Command -ScriptBlock {
                    $ConfigurationData.Paths.Bin + '\minikube.exe addons enable ingress'
                }
            }
            TestScript = {
                $ingress = Invoke-Command -ScriptBlock {
                    $ConfigurationData.Paths.Bin + '\minikube.exe addons list'
                }
                $ingress = echo $ingress | Select-String -List ingress | select -expand line
                $ingress = $ingress.split(':')[1]
                switch ($ingress) {
                    enabled { return $true }
                    default { return $false }
                }
            }
        }

        # stop minikube
        Script MinikubeStop {
            GetScript = { return @{ 'result' = $null } }
            SetScript = {
                Invoke-Command -ScriptBlock { $ConfigurationData.Paths.Bin + '\minikube.exe stop' }
            }
            TestScript = { return $false }
        }

    }
    
}

. .\winikube_hyperv.ps1
WiniKubeHyperV -ConfigurationData .\config.psd1

. .\winikube_virtualbox.ps1
WiniKubeVirtualBox -ConfigurationData .\config.psd1

Write-Output ''
Get-Childitem -Directory -Filter .\* | ForEach-Object {
    Write-Output "Clearing metadata from $_"
    Clear-MofAuthoringMetadata -Path $_.FullName
}
