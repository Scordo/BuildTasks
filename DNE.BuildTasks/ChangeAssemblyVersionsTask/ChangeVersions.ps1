[CmdletBinding()]
param(
	[string] $assemblyInformationalVersionBehaviorString,
	[string] $assemblyInformationalVersionString,
	[string] $assemblyInformationalVersionBuildNumberRegex,
	[string] $assemblyInformationalVersionPrefixString,
	[string] $assemblyInformationalVersionPostfixString,
	[string] $assemblyVersionBehaviorString,
	[string] $assemblyVersionString,
	[string] $assemblyVersionBuildNumberRegex,
	[string] $assemblyFileVersionBehaviorString,
	[string] $assemblyFileVersionString,
	[string] $assemblyFileVersionBuildNumberRegex,
	[string] $recursiveSearch,
	[string] $fileNamePattern,
	[string] $searchDirectory
)


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
	Write-Host "Going to remove VersionInfo from file $filePath .."

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

function GetVersionPartString([System.Text.RegularExpressions.Match] $match, [string] $groupName)
{
	if ($match.Groups[$groupName].Success)
	{
		return $match.Groups[$groupName].Value 
	}
	
	return ""
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


Write-Host "Entering script $MyInvocation.MyCommand.Name"
Write-Host "Parameter Values"
foreach($key in $PSBoundParameters.Keys)
{
	Write-Host ($key + ' = ' + $PSBoundParameters[$key])
}
Write-Host "Build.BuildNumber = $env:BUILD_BUILDNUMBER" 

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

switch ($assemblyInformationalVersionBehavior)
{
	"None" { $assemblyInformationalVersionString = $null; continue; }
	"BuildNumber" { $assemblyInformationalVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyInformationalVersionBuildNumberRegex -prefixString $assemblyInformationalVersionPrefixString -postfixString $assemblyInformationalVersionPostfixString; continue; }
}

switch ($assemblyVersionBehavior)
{
	"None" { $assemblyVersionString = $null; continue; }
	"BuildNumber" { $assemblyVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyVersionBuildNumberRegex -prefixString "" -postfixString "" ; continue; }
}

switch ($assemblyFileVersionBehavior)
{
	"None" { $assemblyFileVersionString = $null; continue; }
	"BuildNumber" { $assemblyFileVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyFileVersionBuildNumberRegex -prefixString "" -postfixString "" ; continue; }
}


$foundFiles = Get-ChildItem -Path $searchDirectory -Filter $fileNamePattern -Recurse:$isRecursiveSearch -ErrorAction SilentlyContinue -Force

ForEach( $foundFile in $foundFiles) 
{
	ReplaceMultipleVersionsInFile -filePath $foundFile.Fullname -informationalVersion $assemblyInformationalVersionString -assemblyVersion $assemblyVersionString -fileVersion $assemblyFileVersionString
}

Write-Verbose ""
Write-Host "Replaced version information in $($foundFiles.Count) files." 


