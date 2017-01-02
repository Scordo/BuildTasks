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
[string] $overwriteReadOnly  = Get-VstsInput -Name overwriteReadOnly
[string] $assemblyFileVersionMustExistString  = Get-VstsInput -Name assemblyFileVersionMustExist
[string] $assemblyVersionMustExistString  = Get-VstsInput -Name assemblyVersionMustExist
[string] $assemblyInformationalVersionMustExistString  = Get-VstsInput -Name assemblyInformationalVersionMustExist
[string] $missingVersionPartDefaultString  = Get-VstsInput -Name missingVersionPartDefaultString
[bool] $assemblyVersionCustomMissingPartDefault = Get-VstsInput -Name assemblyVersionCustomMissingPartDefault -AsBool
[string] $assemblyVersionMissingPartDefaultString  = Get-VstsInput -Name assemblyVersionMissingPartDefaultString
[bool] $assemblyFileVersionCustomMissingPartDefault = Get-VstsInput -Name assemblyFileVersionCustomMissingPartDefault -AsBool
[string] $assemblyFileVersionMissingPartDefaultString  = Get-VstsInput -Name assemblyFileVersionMissingPartDefaultString
[bool] $assemblyInformationalVersionCustomMissingPartDefault = Get-VstsInput -Name assemblyInformationalVersionCustomMissingPartDefault -AsBool
[string] $assemblyInformationalVersionMissingPartDefaultString  = Get-VstsInput -Name assemblyInformationalVersionMissingPartDefaultString


Add-Type -TypeDefinition "public enum VersionBehavior { None, Custom, BuildNumber }"

function ExitWithCode([int] $exitcode)
{ 
	$host.SetShouldExit($exitcode) 
	exit 
}

function ReplaceVersionInFileContent([string] $filePath, [string] $currentFileContent, [string] $attributeName, [string] $newVersion, [string] $fileExtension, [bool] $mustExist)
{
	$attributPattern = "";
	$newVersionAttribute = "";

	switch ($fileExtension)
	{
		"vb"
		{
			# Case for visual basic
			$attributPattern= "\<\s*assembly\s*:\s*$($attributeName)Version(Attribute)?\s*\(.*?\)\s*\>"
			$newVersionAttribute = '<Assembly: '+$attributeName+'Version("'+$newVersion+'")>'
		}
		default
		{
			# C# is the default case
			$attributPattern= "\[\s*assembly\s*:\s*$($attributeName)Version(Attribute)?\s*\(.*?\)\s*\]"
			$newVersionAttribute = '[assembly: '+$attributeName+'Version("'+$newVersion+'")]'
		}
	}

	Write-Verbose "Replacing $($attributeName)Version-Attribute.."

	$attributeMatches = $currentFileContent | select-string -Pattern $attributPattern

	if ($attributeMatches.Matches.Count -eq 0)
	{
		if ($mustExist)
		{
			Write-Error "Could not find $($attributeName)VersionAttribute in file $($filePath)!"
		}

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


function ReplaceMultipleVersionsInFile ([string] $filePath, [string] $informationalVersion, [bool] $informationalVersionMustExist, [string] $assemblyVersion, [bool] $assemblyVersionMustExist,[string] $fileVersion, [bool] $fileVersionMustExist, [bool] $overwriteReadOnlyFile)
{
	Write-Verbose ""
	Write-Host "Going to update version info of file $filePath .."

	$fileExtension = [IO.Path]::GetExtension($filePath).TrimStart(".").ToLower();
	$fileContent = [IO.File]::ReadAllText($filePath)


	if ($assemblyVersion)
	{
		$fileContent = ReplaceVersionInFileContent -filePath $filePath -currentFileContent $fileContent -newVersion $assemblyVersion -attributeName "Assembly" -fileExtension $fileExtension -mustExist $assemblyVersionMustExist
	}

	if ($fileVersion)
	{
		$fileContent = ReplaceVersionInFileContent -filePath $filePath -currentFileContent $fileContent -newVersion $fileVersion -attributeName "AssemblyFile" -fileExtension $fileExtension -mustExist $fileVersionMustExist
	}

	if ($informationalVersion)
	{
		$fileContent = ReplaceVersionInFileContent -filePath $filePath -currentFileContent $fileContent -newVersion $informationalVersion -attributeName "AssemblyInformational" -fileExtension $fileExtension -mustExist $informationalVersionMustExist
	}

	$file = Get-Item $filePath

	if ($overwriteReadOnlyFile -and $file.IsReadOnly -eq $true)  
	{  
		Write-Verbose "Removing readonly flag from file $filePath .."
		$file.IsReadOnly = $false   
	}

	Write-Verbose "Writing version modifications"
	[IO.File]::WriteAllText($filePath, $fileContent)
}

function GetVersionPartDottedString([System.Text.RegularExpressions.Match] $match, [string] $groupName, [string] $missingPartDefaultValue)
{
	if ($match.Groups[$groupName].Success)
	{
		return $match.Groups[$groupName].Value + "." 
	}
	
	return $missingPartDefaultValue
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

function GetVersionNumberFromBuildNumber([string] $buildNumberPattern, [string] $prefixString, [string] $postfixString, [string] $missingPartDefaultValue)
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
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "major" -missingPartDefaultValue $missingPartDefaultValue;
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "minor" -missingPartDefaultValue $missingPartDefaultValue;
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "build" -missingPartDefaultValue $missingPartDefaultValue;
	$versionString += GetVersionPartDottedString -match $firstMatch -groupName "revision" -missingPartDefaultValue $missingPartDefaultValue;
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
[bool] $assemblyFileVersionMustExist = If ($assemblyFileVersionMustExistString -eq $null -or $assemblyFileVersionMustExistString -eq '') {$false} Else {[bool]::Parse($assemblyFileVersionMustExistString)}
[bool] $assemblyVersionMustExist = If ($assemblyVersionMustExistString -eq $null -or $assemblyVersionMustExistString -eq '') {$false} Else {[bool]::Parse($assemblyVersionMustExistString)}
[bool] $informationalVersionMustExist = If ($assemblyInformationalVersionMustExistString -eq $null -or $assemblyInformationalVersionMustExistString -eq '') {$false} Else {[bool]::Parse($assemblyInformationalVersionMustExistString)}
[bool] $isRecursiveSearch = [bool]::Parse($recursiveSearch)    
[bool] $overwriteReadOnlyFiles = If ($overwriteReadOnly -eq $null -or $overwriteReadOnly -eq '') {$false} Else {[bool]::Parse($overwriteReadOnly)}

if ($assemblyInformationalVersionBehavior -eq [VersionBehavior]::None  -AND $assemblyVersionBehavior -eq [VersionBehavior]::None -AND $assemblyFileVersionBehavior -eq [VersionBehavior]::None)
{
	Write-Host "You must at least select one version behavior which is not 'Keep defaults'!"  -ForegroundColor Red
	ExitWithCode -exitcode 1
}

if ($assemblyVersionCustomMissingPartDefault -ne $true)
{
	$assemblyVersionMissingPartDefaultString = "0."
}

if ($assemblyFileVersionCustomMissingPartDefault -ne $true)
{
	$assemblyFileVersionMissingPartDefaultString = "0."
}

if ($assemblyInformationalVersionCustomMissingPartDefault -ne $true)
{
	$assemblyInformationalVersionMissingPartDefaultString = "0."
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
		$assemblyInformationalVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyInformationalVersionBuildNumberRegex -prefixString $prefix -postfixString $postfix -missingPartDefaultValue $assemblyInformationalVersionMissingPartDefaultString
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
		$assemblyVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyVersionBuildNumberRegex -prefixString "" -postfixString "" -missingPartDefaultValue $assemblyVersionMissingPartDefaultString
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
		$assemblyFileVersionString = GetVersionNumberFromBuildNumber -buildNumberPattern $assemblyFileVersionBuildNumberRegex -prefixString "" -postfixString "" -missingPartDefaultValue $assemblyFileVersionMissingPartDefaultString
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
	ReplaceMultipleVersionsInFile -filePath $foundFile.Fullname -informationalVersion $assemblyInformationalVersionString -informationalVersionMustExist $informationalVersionMustExist -assemblyVersion $assemblyVersionString -assemblyVersionMustExist $assemblyVersionMustExist -fileVersion $assemblyFileVersionString -fileVersionMustExist $assemblyFileVersionMustExist -overwriteReadOnlyFile $overwriteReadOnlyFiles
}

Write-Host ""
Write-Host "Replaced version info in $($foundFiles.Count) files." 
Set-VstsTaskVariable -Name DNE_AssemblyInformationalVersionString -Value $assemblyInformationalVersionString
Set-VstsTaskVariable -Name DNE_AssemblyVersionString -Value $assemblyVersionString
Set-VstsTaskVariable -Name DNE_AssemblyFileVersionString -Value $assemblyFileVersionString

