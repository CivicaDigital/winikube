# Winikube

Winikube uses Powershell DSC to [somewhat] install and configure Docker, Minikube and [kd](https://github.com/UKHomeOffice/kd) on Windows 10.

It supports both Hyper-V and Virtualbox drivers, to varying levels of completeness.

## Usage

1. Run `firstrun.cmd`, as an Adminstrator, to:
	- Enable Powershell script execution
	- Install the required Powershell modules

2. Run `build.cmd` to compile the configuration.

3. Run `apply.cmd`, as an adminstrator, to apply the configuration. You will be prompted to choose between Virtualbox and Hyper-V virtualization drivers.

## Requirements

Hardware virtualization must be enabled in BIOS/UEFI.

### Hyper-V

The Hyper-V functionality requires Windows 10 release 1703 (Creators' Update), to allow for the creation of multiple NAT gateways.

## Issues

Please see https://github.com/CivicaDigital/winikube/issues.