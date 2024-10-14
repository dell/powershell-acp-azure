# Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.


$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$commonVersion = "1.0.0"
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\APEXCP.Azure.API.Common\" + $commonVersion + "\APEXCP.Azure.API.Common.ps1"
. "$commonPath"



<#
.SYNOPSIS
Upload LDAPs certificate into Cloud Platform Manager before cluster deployment

.PARAMETER Server
Required. APEX Cloud Platform Manager IP address.

.PARAMETER Cert
Required. LDAPs certificate file path.
The format of the LDAPs certificate file need to follow the following format:
[
	{
        "cert_type": "ROOT",
        "cert": "-----BEGIN CERTIFICATE-----\n<raw cert content>\n-----END CERTIFICATE-----"
    },
	{
        "cert_type": "INTERMEDIATE",
        "cert": "-----BEGIN CERTIFICATE-----\n<raw cert content>\n-----END CERTIFICATE-----"
	},
    ...
]
The supported cert_type are ROOT and INTERMEDIATE.

.Notes
You can run this cmdlet to start system bring up or restart system bring up if failed.

.EXAMPLE
PS> Initialize-LDAPsCertificate -Server <APEX Cloud Platform Manager IP> -Cert <LDAPs certificate file path>

Upload LDAPs root CA certificate and intermediate CA certificates to APEX Cloud Platform Manager Server
#>
function Initialize-LDAPsCertificate {
    param(
        [Parameter(Mandatory = $true)]
        # APEX Cloud Platform Manager IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # LDAPs Certificate file
        [String] $Cert
    )


    $uri = "/rest/apex-cp/v1/ldaps-certs/initialize"
    $url = Get-Url -Server $Server -Uri $uri

    $body = Get-Content -Path $Cert

    try {
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -eq 5) {
            $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"
        } else {
            $response =  Invoke-RestMethod -SkipCertificateCheck -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"
        }

        $responseJson = $response | ConvertTo-Json
        Write-Host $responseJson

    } catch {
        Write-RestMethodInvokeException -URL $url
    }
}


<#
.SYNOPSIS
Handle exception of REST API calling

.PARAMETER URL
Required. Rest API URL
#>
function Write-RestMethodInvokeException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL
    )

    $errorMessage = $_.Exception.Message
    $statuscode = $_.Exception.Response.StatusCode.value__

    if ($statuscode -eq "400" -and $_.ErrorDetails.Message.Contains("error_code")){
        Write-Host  $_.ErrorDetails
        break
    }

    if ($statuscode -eq "500" -and $_.ErrorDetails.Message.Contains("error_code")){
        Write-Host  $_.ErrorDetails.Message
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
