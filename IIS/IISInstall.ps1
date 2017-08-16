#Requires -RunAsAdministrator
#Only support after powershell 4.0

#please run it in admin right
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

#read profile
$hostName= $env:COMPUTERNAME+"."+$env:USERDNSDOMAIN
$ProfilePath = "$PSScriptRoot\Profile\ServerProfile.json"
$ServerProfile = Get-Content "$ProfilePath" | ConvertFrom-Json

if($ServerProfile.ServerHostName.($hostName) -eq $null){
    write-host "Profile Not found!"
    exit 1
}


#Enable IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestMonitor
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic

#install choco (https://chocolatey.org/install)
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Enable webdeploy
choco install webdeploy /y
#Enable urlrewrite
choco install urlrewrite /y


#Check installed Features
Get-WindowsOptionalFeature -Online | where {$_.state -eq "Enabled"} | ft -Property featurename


if(Test-path "IIS:\Sites\Default Web Site"){
Remove-Item "IIS:\Sites\Default Web Site" -Force -Recurse
}


#Set param
Import-Module WebAdministration
$AppPoolName=$ServerProfile.ServerHostName.($hostName).AppPoolName
$PhysicalPath=$ServerProfile.ServerHostName.($hostName).PhysicalPath
$SiteName=$ServerProfile.ServerHostName.($hostName).SiteName
$BindingPort=$ServerProfile.ServerHostName.($hostName).BindingPort

#Create App Pool
if(!(Test-path "IIS:\AppPools\$AppPoolName")){
New-Item "IIS:\AppPools\$AppPoolName"
}

#Create Site Physical Path
if(!(Test-path "$PhysicalPath")){
mkdir "$PhysicalPath" -Force
}

#Create WebSite, set app pool , start site
if(!(Test-path "iis:\Sites\$SiteName")){
#Create WebSite
New-Item "iis:\Sites\$SiteName" -bindings @{protocol="http";bindingInformation="*:"+$BindingPort+":"} -physicalPath "$PhysicalPath"
#set app pool
Set-ItemProperty "iis:\Sites\$SiteName" -name applicationPool -value "$AppPoolName"
#Start website
Start-WebSite -Name "$SiteName" 
}
