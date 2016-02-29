# JH - Build & Release Tools
This extension contains helpful build tasks.

1. **Change Assembly Versions**

	This task can version assemblies by using the build number or by manually defining the version number to set.
	This can be done for 3 different versions separately: AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion

**Changelog**
---
Version: 1.0.3 - 29th of February 2016
* Fixed a bug with usage of variable $TfvcChangeset in "prefix" and "postfix" of "Change Assembly Versions" Task 

Version: 1.0.2 - 29th of February 2016
* Fixed a bug with prefix and postfix regex groups of "Change Assembly Versions" Task 
* Added possibility to use special variable $TfvcChangeset in mode "Provide a static version or use variables to define the version." of "Change Assembly Versions" Task. This variable is the tfs changeset number without the leading "C".
* Added possibility to use special variable $TfvcChangeset in mode "Extract the version from the Buildnumber using a regular expression" of "Change Assembly Versions" Task for "prefix" and "postfix". This variable is the tfs changeset number without the leading "C".

Version: 1.0.1 - 26th of February 2016
* Improved logging of "Change Assembly Versions" Task 
