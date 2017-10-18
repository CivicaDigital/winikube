Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name posh-git
Install-Module -Name Carbon -AllowClobber
Find-Module -Tag 'DSCResourceKit' | Install-Module -AllowClobber
