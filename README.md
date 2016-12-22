# JH - Build & Release Tools
This extension contains helpful build tasks.

1. **Change Assembly Versions**

	This task can version assemblies by using the build number or by manually defining the version number to set.
	This can be done for 3 different versions separately: AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion
	Supported languages are: C# and VB.Net

**Changelog**
---
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
