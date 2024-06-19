# Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = Get-Location
$items = Get-ChildItem $currentPath
$buildDir = -join($currentPath, '\build')
write-host "buildDir: $buildDir"
$ignore = @('.gitlint','CODEOWNERS', 'Jenkinsfile', 'apexcp-profile.ps1', 'build.ps1')
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Confirm:$false -Force -Recurse
}
New-Item -Path $buildDir -ItemType Directory | Out-Null


function build {
    param (
        $from , $to
    )

    Copy-Item -Path $from -Destination $to -Confirm:$false -Recurse -Force
}

foreach($item in $items){
    write-host "item: $item"
    if ($item.Name.StartsWith('.') -or $item.Name.StartsWith('build') -or $item.Name.EndsWith('.md')){
        continue
    }
    if ($ignore.Contains($item.Name)){
        continue
    }
    $dir = -join($currentPath, '\', $item.Name)
    $dir2 = -join($buildDir, '\', $item.Name)
    write-host "dir: $dir"
    write-host "dir2: $dir2"
    build -from $dir -to $dir2
}

Write-Host 'Done.'






