# Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$psVersion = $PSVersionTable.PSVersion.Major
Write-Host 'PowerShell major version: '$psVersion
if ($psVersion -lt 5){
    Write-Host "Ths PowerShell version is not supported by APEX Cloud Platform for Microsoft Azure API PowerShell Modules!" -ForegroundColor DarkRed
    Write-Host "Please activate APEX Cloud Platform for Microsoft Azure API using PowerShell version 5.0 or above." -ForegroundColor DarkRed
    exit
}
$Release = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' |  Get-ItemPropertyValue -Name Release
for ($i = 0; $i -lt $Release.count; $i++){
    Switch ($Release[$i]) {
        378389 {$NetFrameworkVersion = "4.5"}
        378675 {$NetFrameworkVersion = "4.5.1"}
        378758 {$NetFrameworkVersion = "4.5.1"}
        379893 {$NetFrameworkVersion = "4.5.2"}
        393295 {$NetFrameworkVersion = "4.6"}
        393297 {$NetFrameworkVersion = "4.6"}
        394254 {$NetFrameworkVersion = "4.6.1"}
        394271 {$NetFrameworkVersion = "4.6.1"}
        394802 {$NetFrameworkVersion = "4.6.2"}
        394806 {$NetFrameworkVersion = "4.6.2"}
        Default {$NetFrameworkVersion = "> 4.6.2"}
    }
    Write-Host '.Net Framework version: '$NetFrameworkVersion
}

# Add warning message for user
Write-Host 'Will remove all APEXCP modules, do you want to proceed? ' -ForegroundColor Yellow
[ValidateSet('Y','N')]$readhost = Read-Host '[Y or N] then press [Enter]:'
switch ($readhost) {
    Y {Write-Host 'Yes, continue executing script.'}
    N {Write-Host 'No, stop executing script.'; Exit}
}

$apexcpProfile = 'apexcp-profile.ps1'

# Reset PSModulePath to default setting
$CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
$UserPSModuleLocation = "$HOME\Documents\WindowsPowerShell\Modules"
$Env:PSModulePath = $CurrentValue + ";" + $UserPSModuleLocation
Write-Host ($Env:PSModulePath )

$psRootDirs = $Env:PSModulePath
$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psRootDirs += -Join(';', $currentPath)
Write-Host $psRootDirs
[Environment]::SetEnvironmentVariable("PSModulePath",$psRootDirs)
$folders = (dir -Directory).Name
$profileDir = -Join($currentPath, "\", $apexcpProfile)
Write-Host "remove profileDir: $profileDir"
if (Test-Path $profileDir){
    Remove-Item $profileDir -Confirm:$false -Recurse -Force
}
New-Item -Path $profileDir -Type File | Out-Null
$ignore =  @('.git', '.github', 'build', '.vscode', '.idea')

# Find the legacy build path in $profile file, remove the directory if legacy build exist
Write-Host "profile: $profile"
if(Test-Path $profile){
    $legacyPath = Get-Content $profile | findstr "apexcp-profile.ps1"
    if ($legacyPath -eq $profileDir){}
    else {
        $legacyPath = $legacyPath.Replace($apexcpProfile,'')
        Remove-Item $legacyPath -Recurse -Force
    }
}
## first line
$l1 = '$p=$Env:PSModulePath'
Add-Content $profileDir $l1
$l2 = -join('$p+=-join(";",', '"',$currentPath, '")')
Add-Content $profileDir $l2
$l3 = '[Environment]::SetEnvironmentVariable("PSModulePath", $p)'
Add-Content $profileDir $l3
foreach($folder in $folders){
    Write-Host $folder
    if (-not ($ignore -contains $folder)){
        # $l = -Join('Import-Module ', $folder, ' -DisableNameChecking')
        $l = -Join('Import-Module ', $folder)
        Add-Content $profileDir $l
    }
}
if(Test-Path $profile){
    (Get-Content $profile | Where-Object {$_ -notmatch $apexcpProfile}) | Out-File $profile
    $result = Get-ChildItem -path $profile -recurse | Select-string -pattern $profileDir -SimpleMatch
    if (-not $result){
        Add-Content $profile $profileDir}
    }

else {
    New-Item -Path $profile -Type File -Force | Out-Null
    Add-Content $profile $profileDir
}
Get-Module *APEXCP.Azure.API* | Remove-Module -Force
Invoke-Expression '& "$profile"'
