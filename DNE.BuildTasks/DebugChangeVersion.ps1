Import-Module ((Split-Path $MyInvocation.MyCommand.Path) + "\ChangeAssemblyVersionsTask\ps_modules\VstsTaskSdk") -ArgumentList @{ NonInteractive = $true }

$env:BUILD_SOURCEVERSION = "C12345"
$env:BUILD_BUILDNUMBER = "20160219-1.5.51.1-Main"

$env:INPUT_assemblyInformationalVersionBehaviorString = "BuildNumber" 
$env:INPUT_assemblyInformationalVersionString = "1.2.3 Release"   
$env:INPUT_assemblyInformationalVersionBuildNumberRegex = "(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)\.(?<revision>\d+)-(?<postfix>.+)"      
$env:INPUT_assemblyInformationalVersionPrefixString = ""
$env:INPUT_assemblyInformationalVersionPostfixString = " "
$env:INPUT_assemblyInformationalVersionMustExist = "false"

$env:INPUT_assemblyVersionBehaviorString = "Custom" 
$env:INPUT_assemblyVersionString = '1.2.0.$TfvcChangeset'   
$env:INPUT_assemblyVersionBuildNumberRegex = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      
$env:INPUT_assemblyVersionMustExist = "false"

$env:INPUT_assemblyFileVersionBehaviorString = "Custom" 
$env:INPUT_assemblyFileVersionString = "1.2.3.4"   
$env:INPUT_assemblyFileVersionBuildNumberRegex = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      
$env:INPUT_assemblyFileVersionMustExist = "false"

$env:INPUT_recursiveSearch = "true"
$env:INPUT_fileNamePattern = "AssemblyInfo.*"    
$env:INPUT_searchDirectory = "D:\Temp\P1"
$env:INPUT_overwriteReadOnly = "true"

[string ]$scriptLocation = ((Split-Path $MyInvocation.MyCommand.Path) + "\ChangeAssemblyVersionsTask\ChangeVersions.ps1")
Invoke-VstsTaskScript -ScriptBlock ([scriptblock]::Create($scriptLocation)) -Verbose

Write-Host DNE_AssemblyInformationalVersionString = (Get-VstsTaskVariable -Name DNE_AssemblyVersionString)
Write-Host DNE_AssemblyInformationalVersionString = (Get-VstsTaskVariable -Name DNE_AssemblyFileVersionString)
Write-Host DNE_AssemblyInformationalVersionString = (Get-VstsTaskVariable -Name DNE_AssemblyInformationalVersionString)