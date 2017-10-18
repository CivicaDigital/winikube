Configuration WiniKubeHyperV {

    Import-DSCResource -ModuleName PsDesiredStateConfiguration
    Import-DSCResource -Module xPsDesiredStateConfiguration
    Import-DSCResource -Module xPendingReboot
    Import-DSCResource -Module xHyper-V
    Import-DSCResource -Module xNetworking

    Node $AllNodes.NodeName {

        # global variable?
        $VmDriver = 'hyperv'

        # apply base config
        WiniKubeBase Base {}

        # enable hyper-v
        Script EnableHyperV {
            GetScript = { return @{ 'result' = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online) } }
            SetScript = { Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All }
            TestScript = {
                $state = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online | select -ExpandProperty state)
                switch ($state) {
                    'Enabled' { return $true }
                    'Disabled' { return $false }
                }
            }
        }

        # reboot if newly installed
        xPendingReboot PostHyperV { 
            Name = 'PostHyperV'
        }
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        # download & install Docker for Windows
        xRemoteFile InstallDocker {
            Uri = 'https://download.docker.com/win/stable/InstallDocker.msi'
            DestinationPath = $ConfigurationData.Paths.Tmp + '/InstallDocker.msi'
        }
        Package DockerForWindows {
            Name = "Docker for Windows"
            Path = $ConfigurationData.Paths.Tmp + '/InstallDocker.msi'
            ProductId = ""
            Arguments = '/quiet /passive /log ' + $ConfigurationData.Paths.Tmp + '/DockerForWindowsInstall.log'
            DependsOn = "[xRemoteFile]InstallDocker"
        }

        ## creators update supports multiple NAT networks, so, we don't have to mix our stuff up with Docker's

        # create switch
        xVMSwitch WiniKubeSwitch {
            Name = $ConfigurationData.NATSwitchName
            Type = 'Internal'
        }

        # create NAT gateway
        xIPAddress WiniKubeNATGateway {
            IPAddress = $ConfigurationData.NATGatewayIP
            AddressFamily = 'IPv4'
            InterfaceAlias = 'vEthernet (' + $ConfigurationData.NATSwitchName + ')'
        }

        # create NAT network
        Script CreateNATNetwork {
            GetScript = { return @{ 'result' = $(Get-NetNat) } }
            SetScript = { New-NetNat -Name $Using:ConfigurationData.NATNetworkName -InternalIPInterfaceAddressPrefix $Using:ConfigurationData.NATNetworkPrefix }
            TestScript = {
                $exists = (Get-NetNat | select -expand name | select-string $Using:ConfigurationData.NATNetworkName)
                if ($exists -ne $null) {
                    return $true
                } else {
                    return $false
                }
            }
        }

        # disable Docker for Windows service
        ## NOPE

        # define a `minikube` service...

        # ...and start/stop helpers?

        # enable ingress addon

        # apply post config
        WiniKubePost Post {}

    }
}