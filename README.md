<!--
  Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

  This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
  Use of this software and the intellectual property contained therein is expressly limited to the terms and
  conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.
-->

# PowerShell Modules for Dell APEX Cloud Platform for Microsoft Azure
The APEX Cloud Platform PowerShell Modules enable you to install Azure Stack HCI OS on the hosts and deploy a APEX Cloud Platform for Azure cluster using PowerShell cmdlets.  Each public API has a corresponding PowerShell cmdlet included in the ACP Azure PowerShell modules.

## How to install the ACP Azure PowerShell Modules

You can install the modules using either of the following methods:
* Import the modules manually using the standard PowerShell commands.
* Import the modules using the installer.
### Using standard PowerShell commands
* Extract the module contents to the following directory: C:\Program 
Files\WindowsPowerShell\Modules.
* To import the module, run the following command from PowerShell:<br>
`Import-Module APEXCP.Azure.API`
* To confirm that the module has imported successfully, run the following command and modules with name containing “APEXCP.Azure.API” should be listed<br>
`Get-Module`
### Using the installer
* Extract the modules into a folder.
* Go to that folder and run `.\install.ps1`
* When prompted with “Will remove all APEXCP modules, do you want to proceed?”, type Y or y. 
## PowerShell cmdlets
Commands are available for the following modules:<br>
* APEXCP.Azure.API.SysBringup
* APEXCP.Azure.API.Certificate

Following is an example of listing the commands for the APEXCP.Azure.API.SysBringup module:<br>
`Get-Command -Module APEXCP.Azure.API.SysBringup`

To list all the commands available for all modules, run:<br>
`Get-Command -Module APEXCP.Azure.API.*`

To show help information for a command, run:<br>
`Get-Help <Command_Name>`

For example, `Get-Help Start-SystemBringup`

