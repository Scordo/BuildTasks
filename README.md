# JH - Build & Release Tools
This extension contains helpful build tasks.

1. **Change Assembly Versions**

	This task can version assemblies by using the build number or by manually defining the version number to set.
	This can be done for 3 different versions separately: AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion
	Supported languages are: C# and VB.Net
	

## Task: Change Assembly Versions

### General Properties

* __Directory__ 
	* This is the directory where to search for files containing any of the 3 Assembly-Version attributes
* __Filename__
	* The filenames to find in the directory defined above. For example __"AssemblyInfo.cs"__ would find __"$/Temp/AssemblyInfo.cs"__ if __"$/Temp"__ was set for the directory.
	* If you want to update both, CSHARP and VB.Net assemblyinfo, you can set __"AssemblyInfo.*"__. This would match __"$/Temp/AssemblyInfo.cs"__ and __"$/Temp/AssemblyInfo.vb"__ if __"$/Temp"__ was set for the directory.
* __Recursive__
	* If recursive is checked, all sub directories of the above defined directory are included into the search
* __Overwrite readonly__
	* If this is checked, readonly files will be overwritten. If this is not checked and a read-only file has to be updated, the task will fail with an error message

### Versioning behavior - Keep defaults - do nothing

This version behavior does nothing. It just leaves the configured attribute "as is" and does not run any action.

### Versioning behavior - Provide a static version or use variables to define the version

This version behavior is ued to provide a static version. You can either set it to a constanst value like "1.2.3.4" or you can use variables provided by the team foundation infrastructure or the ones defined in the build definition. There is also a special Variable $TfvcChangeset, which will give you the latest changeset number of TFVC without the leading "C".

* __AssemblyVersion__ 
	
* __Fail if attribute does not exist__ 
	* If this is checked, the task would fail, if the configured attribute is not found in all matched files.

* __Examples for AssemblyVersion__
	* 1.0.0.$TfvcChangeset
		* could for example result in: "1.0.0.26118"
	* 1.0.0.$TfvcChangeset $(Build.SourceBranchName)
		* could for example result in: "1.0.0.26118 FeatureBranch1"
		* would only be valid for AssemblyInformationalVersion, because a descriptive string is in the version

### Versioning behavior - Extract the version from the Buildnumber using a regular expression

This version behavior is ued to extract the version from the variable $(Build.BuildNumber) using the regular expression provided in "Buildnumber Version-Regex".

* __Buildnumber Version-Regex__ 
	* The regular expression used to extract version parts from the variable $(Build.BuildNumber)
	* The following groups are supported
		* prefix
		* major
		* minor
		* build
		* revision
		* postfix
	* The resulting version number will be a concatination of all the groups in the above order with a dot between the group values of "major", "minor", "build" or "revision" and no seperator after group "prefix" and before "postfix"
		* **p**refix**m**ajor.**m**inor.**b**uild.**r**evision**p**ostfix
	* If any of the groups "major", "minor", "build" or "revision" was not matched the number "0" will be set or it
		* If revision is missing: **p**refix**ma**jor.**m**inor.**b**uild.0**p**ostfix
	* If any of the groups "prefix" or "postfix" was not matched an empty string will be set or it
		* If prefix is missing: **m**ajor.**m**inor.**b**uild.**r**evision**p**ostfix
	* When using this behavior for "AssemblyInformationalVersion", there are two more properties: Prefix and Postfix
		* The concatination would then be: **p**refix**p**refixProperty**m**ajor.**m**inor.**b**uild.**r**evision**p**ostfixProperty**p**ostfix

* __Prefix__ 
	* An optional string which is put in front of the matched version numbers, but after an optionally matched prefix-regex-group. 	

* __Postfix__ 
	* An optional string which is put at the end of the matched version numbers, but before an optionally matched postfix-regex-group. 
	
* __Fail if attribute does not exist__ 
	* If this is checked, the task would fail, if the configured attribute is not found in all matched files.

* __Custom default for missing version group__
	* If this is checked, you can provide an own default value for missing groups ("major", "minor", "build" or "revision") in the "__Buildnumber Version-Regex__". For example you can leave the input "__Default for missing version group__" blank to have an empty default.
	* If this is __not__ checked, "0." will be the default for missing groups ("major", "minor", "build" or "revision") in the "__Buildnumber Version-Regex__".

* __Default for missing version group__
	* Here you can provide a default for missing missing groups ("major", "minor", "build" or "revision") in the "__Buildnumber Version-Regex__".

* __Examples__
	* (?&lt;major&gt;\\d+)\\.(?&lt;minor&gt;\\d+)\\.(?&lt;build&gt;\\d+)\\.(?&lt;revision&gt;\\d+)
		* for value "Build 15 - 1.2.3.4 - master" this will match: major = 1, minor = 2, build = 3 and revision = 4, resulting in version 1.2.3.4
	
## Changelog
---
Version: 3.0.0 - 20th of Jan 2017
* Added option to specify a custom default value for missing version groups in regex of Versioning behavior "Extract the version from the Buildnumber using a regular expression

Version: 2.0.0 - 22nd of Dec 2016
* Added option for each version attribute to specify whether the attribute must exists in the target files before replacement

Version: 1.0.10 - 22nd of Dec 2016
* Added space between "[assembly:" and the attribute name in the C#-Version. This is to satisfy a stylecop rule. ([assembly:AssemblyVersion("1.0.10.0")] --> [assembly: AssemblyVersion("1.0.10.0")])

Version: 1.0.9 - 4h of Nov 2016
* Added support vor VB.net (*.vb)

Version: 1.0.8 - 28th of Oct 2016
* Added option to overwrite readonly files

Version: 1.0.6 - 2nd of July 2016
* Fixed extension icon - got broken somehow

Version: 1.0.5 - 2nd of July 2016
* Fixed bug in detecting TfvcChangeset for VSTS only (Build.SourceVersion is no longer prefix with 'C')

Version: 1.0.4 - 2nd of July 2016
* After executing the task you can now use the generated versions in further build steps using the following variables: $(DNE_AssemblyVersionString), $(DNE_AssemblyFileVersionString) and $(DNE_AssemblyInformationalVersionString)

Version: 1.0.3 - 29th of February 2016
* Fixed a bug with usage of variable $TfvcChangeset in "prefix" and "postfix" of "Change Assembly Versions" Task 

Version: 1.0.2 - 29th of February 2016
* Fixed a bug with prefix and postfix regex groups of "Change Assembly Versions" Task 
* Added possibility to use special variable $TfvcChangeset in mode "Provide a static version or use variables to define the version." of "Change Assembly Versions" Task. This variable is the tfs changeset number without the leading "C".
* Added possibility to use special variable $TfvcChangeset in mode "Extract the version from the Buildnumber using a regular expression" of "Change Assembly Versions" Task for "prefix" and "postfix". This variable is the tfs changeset number without the leading "C".

Version: 1.0.1 - 26th of February 2016
* Improved logging of "Change Assembly Versions" Task 