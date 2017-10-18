Configuration WiniKubeVirtualbox {

    Import-DSCResource -ModuleName PsDesiredStateConfiguration
    Import-DSCResource -Module xPsDesiredStateConfiguration
    Import-DSCResource -Module xPendingReboot

    Node $AllNodes.NodeName {

        # global variable?
        $VmDriver = 'virtualbox'

        # apply base config
        WiniKubeBase Base {}

        # Docker Toolbox includes:
        # - Docker Client
        # - Docker Machine
        # - VirtualBox
        # - Kinematic (Beta)
        # - Git (optional?)

        # disable Hyper-V
        Script EnableHyperV {
            GetScript = { return @{ 'result' = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online) } }
            SetScript = { Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All }
            TestScript = {
                $state = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online | select -ExpandProperty state)
                switch ($state) {
                    'Enabled' { return $false }
                    'Disabled' { return $true }
                }
            }
        }

        # reboot if required
        xPendingReboot PostDockerToolbox {
            Name = 'PostDockerToolbox'
        }
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        # download docker toolbox
        xRemoteFile DockerToolboxInstaller {
            Uri = 'https://download.docker.com/win/stable/DockerToolbox.exe'
            DestinationPath = $ConfigurationData.Paths.Tmp + '/DockerToolbox.exe'
        }

        # install Docker Toolbox
        Package DockerToolbox {
            Name = "DockerToolbox"
            Path = $ConfigurationData.Paths.Tmp + '/DockerToolbox.exe'
            ProductId = ""
            Arguments = '/silent /norestart /saveinf=' + $ConfigurationData.Paths.Tmp + '/DockerToolBoxInstall.inf /log=' + $ConfigurationData.Paths.Tmp + 'DockerToolboxInstall.log'
            DependsOn = "[xRemoteFile]DockerToolboxInstaller"
        }

        # apply post config
        WiniKubePost Post {}


    }
    
}