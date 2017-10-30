@echo off
setlocal enabledelayedexpansion

choice /c HVN /m "Please choose Hyper-V (H), Virtualbox (V), or no action (N)"
if errorlevel 3 exit
if errorlevel 2 set driver=Virtualbox
if errorlevel 1 set driver=HyperV

set command=Start-DscConfiguration -Path .\WiniKube_DRIVER -Wait -Verbose -Force
call set command=%command:_DRIVER=!driver!%

wevtutil set-log Microsoft-Windows-Dsc/Analytic /q:true /e:true

net start WinRM
powershell -command %command%
net stop WinRM