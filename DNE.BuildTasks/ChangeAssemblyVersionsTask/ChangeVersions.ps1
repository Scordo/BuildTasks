[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

[string] $assemblyInformationalVersionBehaviorString = Get-VstsInput -Name assemblyInformationalVersionBehaviorString
[string] $assemblyInformationalVersionString  = Get-VstsInput -Name assemblyInformationalVersionString
[string] $assemblyInformationalVersionBuildNumberRegex  = Get-VstsInput -Name assemblyInformationalVersionBuildNumberRegex
[string] $assemblyInformationalVersionPrefixString  = Get-VstsInput -Name assemblyInformationalVersionPrefixString
[string] $assemblyInformationalVersionPostfixString  = Get-VstsInput -Name assemblyInformationalVersionPostfixString
[string] $assemblyVersionBehaviorString  = Get-VstsInput -Name assemblyVersionBehaviorString
[string] $assemblyVersionString  = Get-VstsInput -Name assemblyVersionString
[string] $assemblyVersionBuildNumberRegex  = Get-VstsInput -Name assemblyVersionBuildNumberRegex
[string] $assemblyFileVersionBehaviorString  = Get-VstsInput -Name assemblyFileVersionBehaviorString
[string] $assemblyFileVersionString  = Get-VstsInput -Name assemblyFileVersionString
[string] $assemblyFileVersionBuildNumberRegex  = Get-VstsInput -Name assemblyFileVersionBuildNumberRegex
[string] $recursiveSearch  = Get-VstsInput -Name recursiveSearch
[string] $fileNamePattern  = Get-VstsInput -Name fileNamePattern
[string] $searchDirectory  = Get-VstsInput -Name searchDirectory


Add-Type -TypeDefinition "public enum VersionBehavior { None, Custom, BuildNumber }"

function ExitWithCode([int] $exitcode)
{ 
	$host.SetShouldExit($exitcode) 
	exit 
}

function ReplaceVersionInFileContent([string] $currentFileContent, [string] $attributeName, [string] $newVersion)
{
	$attributPattern= "\[\s*assembly\s*:\s*$($attributeName)Version(Attribute)?\s*\(.*?\)\s*\]"
	$newVersionAttribute = '[assembly:'+$attributeName+'Version("'+$newVersion+'")]'

	Write-Verbose "Replacing $($attributeName)Version-Attribute.."

	$attributeMatches = $currentFileContent | select-string -Pattern $attributPattern

	if ($attributeMatches.Matches.Count -eq 0)
	{
		Write-Verbose "Found no existing $($attributeName)Version-Attribute"
		$currentFileContent = $currentFileContent+"`n$newVersionAttribute" 
		Write-Verbose "Added $($attributeName)Version-Attribute as $newVersionAttribute"
	}
	else
	{
		$currentFileContent = $currentFileContent -replace $attributPattern, $newVersionAttribute
		Write-Verbose "Replaced $($attributeName)Version-Attribute with $newVersionAttribute"
	}

	return $currentFileContent
}


function ReplaceMultipleVersionsInFile ([string] $filePath, [string] $informationalVersion, [string] $assemblyVersion,[string] $fileVersion)
{
	Write-Verbose ""
	Write-Host "Going to update version info of file $filePath .."

	$fileContent = [IO.File]::ReadAllText($filePath)

	if ($assemblyVersion)
	{
		$fileContent = ReplaceVersionInFileContent -currentFileContent $fileContent -newVersion $assemblyVersion -attributeName "Assembly"
	}

	if ($fileVersion)
	{
		$fileContent = ReplaceVersionInFileContent -currentFileContent $fileContent -newVersion $fileVersion -attributeName "AssemblyFile"
	}

	if ($informationalVersion)
	{
		$fileContent = ReplaceVersionInFileContent -currentFileContent $fileContent -newVersion $informationalVersion -attributeName "AssemblyInformational"
	}

	Write-Verbose "Writing version modifications"
	[IO.File]::WriteAllText($filePath, $fileContent)
}

function GetVersionPartDottedString([System.Text.RegularExpressions.Match] $match, [string] $groupName)
{
	if ($match.Groups[$groupName].Success)
	{
		return $match.Groups[$groupName].Value + "." 
	}
	
	return "0."
}

function SetChangesetNumber()
{
	$matches = [System.Text.RegularExpressions.Regex]::Matches($env:BUILD_SOURCEVERSION, '^C?(?<cs>\d+)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase);
	if ($matches.Count -eq 0) 
	{
		$script:TfvcChangeset = $null;
	}
	else
	{
		$script:TfvcChangeset = $matches[0].Groups["cs"].Value
	}
}

function GetVersionNumberFromBuildNumber([string] $buildNumberPattern, [string] $prefixString, [string] $postfixString)
{
	$versionMatches = [System.Text.RegularExpressions.Regex]::Matches($env:BUILD_BUILDNUMBER, $buildNumberPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase);

	if ($versionMatches.Count -eq 0)
	{
		Write-Warning "Could not find a Buildnumber-Version-Match for regex pattern: $($buildNumberPattern). Keeping the defaults!"
		return $null;
	}

	if ($versionMatches.Count -gt 1)
	{
		Write-Warning "Found $($versionMatches.Count) Buildnumber-Version-Matches for regex pattern: $($buildNumberPattern). Keeping the defaults!"
		return $null;
	}
	
	$firstMatch = $versionMatches[0]

	[string] $versionString = GetVersionPartString -match $firstMatch -groupName "prefix";
	$versionString += $prefixString
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "major";
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "minor";
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "build";
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "revision";
	$versionString = $versionString.TrimEnd('.')
	$versionString += $postfixString
	$versionString += GetVersionPartString -match $firstMatch -groupName "postfix";

	return $versionString;
}

function GetVersionPartString([System.Text.RegularExpressions.Match] $match, [string] $groupName)
{
	if ($match.Groups[$groupName].Success)
	{
		return $match.Groups[$groupName].Value 
	}
	
	return ""
}



Write-Host "Entering script $($MyInvocation.MyCommand.Name)"
Write-Host ""
Write-Host "Parameter Values:"
foreach($key in $PSBoundParameters.Keys)
{
	Write-Host ("`t" + $key + ' = ' + $PSBoundParameters[$key])
}
Write-Host "`tBuild.BuildNumber = $env:BUILD_BUILDNUMBER" 
Write-Host "`tBuild.SourceVersion = $env:BUILD_SOURCEVERSION"
SetChangesetNumber
Write-Host "`tTfvcChangeset = $TfvcChangeset"


#Convert the flags to boolean values

[VersionBehavior] $assemblyInformationalVersionBehavior = $assemblyInformationalVersionBehaviorString;
[VersionBehavior] $assemblyVersionBehavior = $assemblyVersionBehaviorString;
[VersionBehavior] $assemblyFileVersionBehavior = $assemblyFileVersionBehaviorString;
[bool] $isRecursiveSearch = [bool]::Parse($recursiveSearch)    

if ($assemblyInformationalVersionBehavior -eq [VersionBehavior]::None  -AND $assemblyVersionBehavior -eq [VersionBehavior]::None -AND $assemblyFileVersionBehavior -eq [VersionBehavior]::None)
{
	Write-Host "You must at least select one version bevahior which os not 'Keep defaults'!"  -ForegroundColor Red
	ExitWithCode -exitcode 1
}

Write-Host ""
Write-Host "Versions to apply:"

switch ($assemblyInformationalVersionBehavior)
{
	"None" 
	{ 
		$assemblyInformationalVersionString = $null
		Write-Host "`tAssemblyInformationalVersion: Do nothing is configured"
		continue
	}
	"BuildNumber" 
	{ 
		$prefix = $ExecutionContext.InvokeCommand.ExpandString($assemblyInformationalVersionPrefixString)
		Write-Host "`tPrefix: $prefix"
		$postfix = $ExecutionContext.InvokeCommand.ExpandString($assemblyInformationalVersionPostfixString)
		Write-Host "`tPostfix: $postfix"
		$assemblyInformationalVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyInformationalVersionBuildNumberRegex -prefixString $prefix -postfixString $postfix
		Write-Host "`tAssemblyInformationalVersion: $assemblyInformationalVersionString"
		continue
	}
	"Custom" 
	{
		$assemblyInformationalVersionString = $ExecutionContext.InvokeCommand.ExpandString($assemblyInformationalVersionString)
		Write-Host "`tAssemblyInformationalVersion: $assemblyInformationalVersionString"
		continue 
	}
}

switch ($assemblyVersionBehavior)
{
	"None" 
	{ 
		$assemblyVersionString = $null
		Write-Host "`tAssemblyVersion: Do nothing is configured"

		continue
	}
	"BuildNumber" 
	{ 
		$assemblyVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyVersionBuildNumberRegex -prefixString "" -postfixString "" 
		Write-Host "`tAssemblyVersion: $assemblyVersionString"

		continue
	}
	"Custom" 
	{
		$assemblyVersionString = $ExecutionContext.InvokeCommand.ExpandString($assemblyVersionString)
		Write-Host "`tAssemblyVersion: $assemblyVersionString"
		continue 
	}
}

switch ($assemblyFileVersionBehavior)
{
	"None" 
	{ 
		$assemblyFileVersionString = $null 
		Write-Host "`tAssemblyFileVersion: Do nothing is configured"
		
		continue
	}
	"BuildNumber" 
	{ 
		$assemblyFileVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyFileVersionBuildNumberRegex -prefixString "" -postfixString "" 
		Write-Host "`tAssemblyFileVersion: $assemblyFileVersionString"

		continue
	}
	"Custom" 
	{
		$assemblyFileVersionString = $ExecutionContext.InvokeCommand.ExpandString($assemblyFileVersionString)
		Write-Host "`tAssemblyFileVersion: $assemblyFileVersionString"
		continue 
	}
}

Write-Host ""

$foundFiles = Get-ChildItem -Path $searchDirectory -Filter $fileNamePattern -Recurse:$isRecursiveSearch -ErrorAction SilentlyContinue -Force

ForEach( $foundFile in $foundFiles) 
{
	ReplaceMultipleVersionsInFile -filePath $foundFile.Fullname -informationalVersion $assemblyInformationalVersionString -assemblyVersion $assemblyVersionString -fileVersion $assemblyFileVersionString
}

Write-Host ""
Write-Host "Replaced version info in $($foundFiles.Count) files." 
Set-VstsTaskVariable -Name DNE_AssemblyInformationalVersionString -Value $assemblyInformationalVersionString
Set-VstsTaskVariable -Name DNE_AssemblyVersionString -Value $assemblyVersionString
Set-VstsTaskVariable -Name DNE_AssemblyFileVersionString -Value $assemblyFileVersionString

