# Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\APEXCP.Azure.API.Common\" + $currentVersion + "\APEXCP.Azure.API.Common.ps1"
. "$commonPath"

<#
.SYNOPSIS
Handle exception of REST API calling

.PARAMETER URL
Required. Rest API URL

#>
function Handle-RestMethodInvokeException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL
    )

    $errorMessage = $_.Exception.Message
    $statuscode = $_.Exception.Response.StatusCode.value__
    if ($statuscode -eq "400" -and $_.ErrorDetails.Message.Contains("AZ_05_4_0003")){
        Write-Host  $_.ErrorDetails
        break
    }
    if (Get-Member -InputObject $_.Exception -Name 'Response') {
        try {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
        } catch {
            Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Cannot get more information."
        }
    }
    Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Response body: $responseBody"
}

<#
.Synopsis
Get auto-discovered hosts.

.Parameter Server
Primary Host IP.

.Notes
You can run this cmdlet to get auto-discovered hosts.

.Example
C:\PS>Get-AutoDiscoveryHosts -Server <Primary Host IP>

Get auto-discovered hosts.

#>

function Get-AutoDiscoveryHosts {
    param(
        # Primary Host IP
        [Parameter(Mandatory = $true)]
        [String] $Server
    )

    $uri = "/rest/apex-cp/v1/system/initialize/nodes"
    $url = Get-Url -Server $Server -Uri $uri

    try {
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -eq 5) {
            $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method GET -ContentType "application/json"
        } else{
            $response = Invoke-RestMethod -SkipCertificateCheck -Uri $url -UseBasicParsing -Method GET -ContentType "application/json"
        }

        $responseJson = $response | ConvertTo-Json -depth 10
        Write-Host $responseJson


    } catch {
        Handle-RestMethodInvokeException -URL $url
    }
}

