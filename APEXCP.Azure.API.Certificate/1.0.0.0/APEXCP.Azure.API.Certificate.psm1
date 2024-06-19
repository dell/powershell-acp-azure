# Copyright (c) 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$IPV6_ADDR_PATTERN = "^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:)|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}(:[0-9A-Fa-f]{1,4}){1,2})|(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){1,3})|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){1,4})|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){1,5})|([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){1,6})|(:(:[0-9A-Fa-f]{1,4}){1,7})|(([0-9A-Fa-f]{1,4}:){6}(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){5}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){0,1}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){0,2}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){0,3}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){0,4}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(:(:[0-9A-Fa-f]{1,4}){0,5}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}))$"

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\APEXCP.Azure.API.Common\" + $currentVersion + "\APEXCP.Azure.API.Common.ps1"
. "$commonPath"



<#
.SYNOPSIS
Upload LDAPs certificate into Cloud Platform Manager before cluster deployment

.PARAMETER Server
Required. APEX Cloud Platform Manager IP address.

.PARAMETER Cert
Required. LDAPs certificate file path.

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

    $cert_contents = Get-Content -Path $Cert
    $result = $cert_contents -join "\n"
    $list = @{
        "cert_type" = "ROOT"
        "cert" = $result
	}
	$data = @()
	$data += $list
	$body = (ConvertTo-Json $data).Replace("\\n","\n")

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
        Handle-RestMethodInvokeException -URL $url
    }
}


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
