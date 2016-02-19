#invoke-expression -Command ".\$PSScriptRoot\Task1\ChangeVersions.ps1"


# assemblyInformationalVersionBehavior
[string] $p1 = "BuildNumber" 
# assemblyInformationalVersionString              
[string] $p2 = "1.2.3 Release"   
# assemblyInformationalVersionBuildNumberRegex
[string] $p3 = "(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)\.(?<revision>\d+)-(?<postfix>.+)"      
[string] $p4 = ""      
[string] $p5 = " "      

# assemblyVersionBehavior
[string] $p6 = "Custom" 
# assemblyVersionString              
[string] $p7 = "1.2.0.0"   
# assemblyVersionBuildNumberRegex
[string] $p8 = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      

# assemblyFileVersionBehavior
[string] $p9 = "Custom" 
# assemblyFileVersionString              
[string] $p10 = "1.2.3.4"   
# assemblyFileVersionBuildNumberRegex
[string] $p11 = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      


# recursiveSearch            
[string] $p12 = "true"              
# fileNamePattern
[string] $p13 = "AssemblyInfo.cs"    
# searchDirectory
[string] $p14 = "D:\Temp\P1"         

[Environment]::SetEnvironmentVariable("BUILD_BUILDNUMBER", "20160219-1.5.51.1-Main", "Process")

& ((Split-Path $MyInvocation.MyCommand.Path) + "\ChangeAssemblyVersionsTask\ChangeVersions.ps1") $p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 $p13 $p14 -verbose