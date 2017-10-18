@{

    AllNodes = @(
    	@{
    		NodeName = 'localhost'
    	}
    );

    Versions = @{
		Kubectl = '1.8.0'
		MiniKube = '0.22.3'
		Kd = '0.4.0'
    }
    Paths = @{
		Base = 'c:\winikube'
		Bin = 'c:\winikube\bin'
		Tmp = 'c:\winikube\tmp'
	}
	NATNetworkName = 'WiniKubeNAT'
	NATSwitchName = 'WiniKubeNATSwitch'
	NATGatewayIP = '172.16.76.1/24'
	NATNetworkPrefix = '172.16.76.0/24'

}