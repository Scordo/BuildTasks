#invoke-expression -Command ".\$PSScriptRoot\Task1\ChangeVersions.ps1"


# assemblyInformationalVersionBehavior
[string] $p1 = "BuildNumber" 
# assemblyInformationalVersionString              
[string] $p2 = "1.2.3 Release"   
# assemblyInformationalVersionBuildNumberRegex
[string] $p3 = "(?<major>\d+).(?<minor>\d+).(?<build>\d+)"      

# assemblyVersionBehavior
[string] $p4 = "Custom" 
# assemblyVersionString              
[string] $p5 = "1.2.0.0"   
# assemblyVersionBuildNumberRegex
[string] $p6 = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      

# assemblyFileVersionBehavior
[string] $p7 = "Custom" 
# assemblyFileVersionString              
[string] $p8 = "1.2.3.4"   
# assemblyFileVersionBuildNumberRegex
[string] $p9 = "(?<major>\\d+).(?<minor>\\d+).(?<build>\\d+).(?<revision>\\d+)"      


# recursiveSearch            
[string] $p10 = "true"              
# fileNamePattern
[string] $p11 = "AssemblyInfo.cs"    
# searchDirectory
[string] $p12 = "D:\Temp\P1"         

[Environment]::SetEnvironmentVariable("BUILD_BUILDNUMBER", "DayZ 10.2334.4 Beta Build", "Process")

& ((Split-Path $MyInvocation.MyCommand.Path) + "\Task1\ChangeVersions.ps1") $p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 $p10 $p11 $p12 -verbose