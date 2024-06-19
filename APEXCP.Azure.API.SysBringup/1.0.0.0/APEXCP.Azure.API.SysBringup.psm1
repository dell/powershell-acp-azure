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
Start system bring up workflow

.PARAMETER Server
Required. Primary Host IP address with OS_PROVISION mode or APEX Cloud Platform Manager IP address for CLUSTER_DEPLOYMENT mode.

.PARAMETER Conf
Required. Json configuration file as the body of system bring up API

.PARAMETER Mode
Required. System Bringup mode. The supported values are OS_PROVISION and CLUSTER_DEPLOYMENT.
Install Azure OS with OS_PROVISION and Deploy cluster with CLUSTER_DEPLOYMENT

.Notes
You can run this cmdlet to start system bring up or restart system bring up if failed.

.EXAMPLE
PS> Start-SystemBringup -Server <APEX Cloud Platform Manager IP or Primary host IP> -Conf <Json file to the path> -Mode <system Bringup mode>

1.Start to install Azure Stack HCI OS through Primary host, with the specified json configuration input in OS_PROVISION mode
2.Start to deploy cluster through APEX Cloud Platform Manager, with specified json configuration input in CLUSTER_DEPLOYMENT mode
#>
function Start-SystemBringup {
    param(
        [Parameter(Mandatory = $true)]
        # APEX Cloud Platform Manager IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OS_PROVISION','CLUSTER_DEPLOYMENT')]
        # Initialize mode
        [String] $Mode

    )


    $url = Build-RestMethodURL -Server $Server -Mode $Mode

    $body = Get-Content $Conf
    try {
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -eq 5) {
            $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"
        } else {
            $response =  Invoke-RestMethod -SkipCertificateCheck -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"
        }

        if ($response -and $response.request_id) {
            Write-Host "Request ID  : "$response.request_id
        } else {
            $responseJson = $response | ConvertTo-Json
            Write-Host $responseJson
        }
    } catch {
        Handle-RestMethodInvokeException -URL $url -Exception $_
    }
}

<#
.SYNOPSIS
Build Rest API URL

.PARAMETER Server
Required. Primary Host IP address with OS_PROVISION mode or APEX Cloud Platform Manager IP address for CLUSTER_DEPLOYMENT mode.

.PARAMETER Mode
Required. System Bringup mode
Install Azure Stack HCI OS with OS_PROVISION or Deploy cluster with CLUSTER_DEPLOYMENT
#>
function Build-RestMethodURL{
    param(
        [Parameter(Mandatory = $true)]
        # APEX Cloud Platform Manager IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Initialize mode
        [String] $Mode

    )

    if ($Mode -eq "OS_PROVISION") {
        $uri = "/rest/apex-cp/v1/system/initialize?mode=OS_PROVISION"
    } else{
        $uri = "/rest/apex-cp/v1/system/initialize?mode=CLUSTER_DEPLOYMENT"
    }
    $url = Get-Url -Server $Server -Uri $uri

    return $url
}

<#
.SYNOPSIS
Handle exception of REST API calling

.PARAMETER URL
Required. Rest API URL

.PARAMETER Msg
Required. Additional error message
#>
function Handle-RestMethodInvokeException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $Exception,

        [Parameter(Mandatory = $false)]
        # Additional error message
        [String] $Msg
    )

    if (-not $Exception.Exception) {
        return
    }
    $errorMessage = $Exception.Exception.Message
    $statuscode = $Exception.Exception.Response.StatusCode.value__
    if ($statuscode -eq "400" -and $Exception.ErrorDetails.Message.Contains("error_code")){
        Write-Host  $Exception.ErrorDetails
        break
    }

    if ($statuscode -eq "404" -and $Exception.ErrorDetails.Message.Contains("error_code")){
        Write-Host  $Exception.ErrorDetails
        break
    }

    if ($statuscode -eq "500" -and $Exception.ErrorDetails.Message.Contains("error_code")){
        Write-Host  $Exception.ErrorDetails.Message
        break
    }

    if (Get-Member -InputObject $Exception.Exception -Name 'Response') {
        try {
            $result = $Exception.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
        } catch {
            if ($Msg) {
                Write-Host $Msg
            }
            Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Cannot get more information."
        }
    }
    if ($Msg) {
        Write-Host $Msg
    }
    Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Response body: $responseBody"
}

<#
.SYNOPSIS
Get progress status of system bring up

.PARAMETER CloudPlatformManagerIP
APEX Cloud Platform Manager IP address is required for OS_PROVISION and CLUSTER_DEPLOYMENT mode.

.PARAMETER PrimaryHostIP
Primary Host IP address is required for OS_PROVISION mode.
Primary Host IP address is not used for CLUSTER_DEPLOYMENT mode.

.PARAMETER Mode
Required. System Bringup mode. The supported values are OS_PROVISION and CLUSTER_DEPLOYMENT.

# .Notes
You can run this cmdlet to query progress status of system bring up

.EXAMPLE
PS> Get-BringupProgressStatus -CloudPlatformManagerIP <APEX Cloud Platform Manager IP> -PrimaryHostIP <Primary host IP> -Mode <system Bringup mode>

1.Gets progress status of install Azure Stack HCI OS through Primary Host or APEX Cloud Platform Manager IP in OS_PROVISION mode

.EXAMPLE
PS> Get-BringupProgressStatus -CloudPlatformManagerIP <APEX Cloud Platform Manager IP> -Mode <system Bringup mode>

2.Gets progress status of cluster deploy progress through APEX Cloud Platform Manager in CLUSTER_DEPLOYMENT mode

#>
function Get-BringupProgressStatus{
    param(
        [Parameter(Mandatory = $true)]
        # APEX Cloud Platform Manager IP
        [String] $CloudPlatformManagerIP,

        [Parameter(Mandatory = $false)]
        # Primary host IP
        [String] $PrimaryHostIP,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OS_PROVISION','CLUSTER_DEPLOYMENT')]
        # Initialize mode
        [String] $Mode
    )

    if ($mode -eq "OS_PROVISION") {
        Monitor-OSProvisionStatus -CloudPlatformManagerIP $CloudPlatformManagerIP -PrimaryHostIP $PrimaryHostIP
    } else {
        Monitor-ClusterDeploymentStatus -CloudPlatformManagerIP $CloudPlatformManagerIP
    }
}

function Monitor-OSProvisionStatus {
    param(
        [String] $CloudPlatformManagerIP,
        [String] $PrimaryHostIP
    )

    if (-not $PrimaryHostIP) {
        Write-Error "Primary host IP is required for OS_PROVISION mode. Please specify -PrimaryHostIP <Primary host IP>"
        return
    }
    $Server = $CloudPlatformManagerIP
    $CloudPlatformManageConn = Test-Connection $CloudPlatformManagerIP -count 1 -Quiet
    if (-not $CloudPlatformManageConn) {
        $Server = $PrimaryHostIP
        $PrimaryHostConn = Test-Connection $PrimaryHostIP -count 1 -Quiet
        if (-not $PrimaryHostConn) {
            $message = "Can not connect to Cloud Platform Manager or Primary host, Please check whether the Azure Stack HCI OS is being installed on the specified hosts now and please try it later..."
            Write-Host $message
            return
        }
    }
    $uri = "/rest/apex-cp/v1/system/initialize/status?mode=OS_PROVISION"

    $OSProvisionDisconnectTimeout = 2*3600
    $OSProvisionDisconnectStep = "OS Provisioning For Primary Node"
    $exception = $null

    $url = Get-Url -Server $Server -Uri $uri
    try {
        $response, $exception = Get-Status -Url $url
        if (-not $exception) {
            return
        }

        $Conn = Test-Connection $Server -count 1 -Quiet
        if (-not $Conn -and ($null -ne $response) -and ($response.step.contains($OSProvisionDisconnectStep)) -and ($Server -eq $PrimaryHostIP) ) {
            # wait for primary node provision complete
            $TimeoutMessage = "Failed to complete OS Provisioning within $OSProvisionDisconnectTimeout seconds. "
            $TimeoutMessage += "Please check whether the Azure Stack HCI OS is being installed on the specified hosts and try it later..."
            $connected = Monitor-DisconnectStatus -Server $CloudPlatformManagerIP -Timeout $OSProvisionDisconnectTimeout -MessagePrefix "OS Provisioning For Primary Node" -TimeoutMessage $TimeoutMessage
            if (-not $connected) {
                return
            }
            # check result again after Cloud Platform Manager is available
            $url = Get-Url -Server $CloudPlatformManagerIP -Uri $uri
            $response, $exception = Get-Status -Url $url
            if (-not $exception) {
                return
            }
        }
        if ($exception) {
            Write-Error $exception.Exception.Message
            throw $exception
        }
    } catch {
        Handle-RestMethodInvokeException -URL $url -Exception $_
    }
}

function Monitor-ClusterDeploymentStatus {
    param(
        [String] $CloudPlatformManagerIP
    )

    $CloudPlatformManageConn = Test-Connection $CloudPlatformManagerIP -count 1 -Quiet
    if (-not $CloudPlatformManageConn) {
        $message = "Can not connect to Cloud Platform Manager, Please check whether the Azure Stack HCI OS installed or not"
        Write-Host $message
        return
    }

    $ClusterDeploymentDisconnectTimeout = 1800
    $ClusterDeploymentDisconnectStep = @(
        "Disable Unused Network Adapter",
        "Restart Nodes and Wait it up",
        "Monitor Cluster Deployment Progress",
        "Rename Non-primary Server's Hostname",
        "Rename Primary Server's Hostname")
    $MaxDisconnectCount = 5
    $uri = "/rest/apex-cp/v1/system/initialize/status?mode=CLUSTER_DEPLOYMENT"
    $url = Get-Url -Server $CloudPlatformManagerIP -Uri $uri

    $DisconnectCount = 0
    $DisconnectStep = $null
    try {
        while ($DisconnectCount -lt $MaxDisconnectCount) {
            $response, $exception = Get-Status -Url $url
            if (-not $exception) {
                return
            }
            if ($null -eq $response) {
                Write-Error "Failed to get status response."
                break
            }
            if ($null -ne $response.step) {
                $DisconnectStep = $response.step
            }
            $DisconnectCount += 1
            Write-Host "Cloud Platform Manager disconnected during cluster deployment, attempt $DisconnectCount ..."
            $Conn = Test-Connection $CloudPlatformManagerIP -count 1 -Quiet
            $ExpectedDisconnectStep = $false
            foreach ($step in $ClusterDeploymentDisconnectStep) {
                if ($DisconnectStep.contains($step)) {
                    $ExpectedDisconnectStep = $true
                    break
                }
            }
            if (-not $Conn -and $ExpectedDisconnectStep) {
                # wait for cloud platform manager reconnection
                $TimeoutMessage = "Failed to reconnect Cloud Platform Manager within $ClusterDeploymentDisconnectTimeout seconds. Please try it later..."
                $connected = Monitor-DisconnectStatus -Server $CloudPlatformManagerIP -Timeout $ClusterDeploymentDisconnectTimeout -MessagePrefix "Cluster Deployment" -TimeoutMessage $TimeoutMessage
                if (-not $connected) {
                    return
                }
            } else {
                Write-Host "Unexpected disconnection at step: $DisconnectStep"
                break
            }
        }
        if ($DisconnectCount -eq $MaxDisconnectCount) {
            Write-Host "Failed to complete Cluster Deployment within $MaxDisconnectCount attempts. "
        }
        if ($exception) {
            Write-Error $exception.Exception.Message
            throw $exception
        }
    } catch {
        Write-Host "Unexpected exception during monitoring cluster deployment status: $_"
        Handle-RestMethodInvokeException -URL $url -Exception $_
    }
}

function Monitor-DisconnectStatus {
    param(
        [String] $Server,
        [String] $Timeout,
        [String] $MessagePrefix,
        [String] $TimeoutMessage
    )
    
    $SleepInterval = 60
    Write-Host "$MessagePrefix is in progress, please wait for a while..."
    $startTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    # Wait for Cloud Platform Manager to be available
    while ($true) {
        $currentTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        if ($currentTimestamp - $startTimestamp -gt $Timeout) {
            Write-Error $TimeoutMessage
            return $false
        }
        $Connection = Test-Connection $Server -count 1 -Quiet
        if ($Connection) {
            # check day1 service status
            $url = Get-Url -Server $Server -Uri "/rest/apex-cp/v1/system/initialize/status"
            $response, $exception = Send-RestAPI -Url $Url
            if ($exception.Exception.Response -and $exception.Exception.Response.StatusCode -eq "InternalServerError") {
                break
            }
        }
        Start-Sleep -s $SleepInterval
    }
    return $true
}

function Get-Status{
    param(
        [String] $Url
    )

    $SleepInterval = 8
    $retryCount = 3000
    $response = $null
    for ($i=1; $i -le $retryCount; $i++) {
        $response, $exception = Send-RestAPI -Url $Url
        if ($exception) {
            return $response, $exception
        }

        cls

        Write-Host "------------------------Response Begin------------------------"
        Write-Host "Query Seq          : "$i
        Write-Host "ID                 : "$response.id
        Write-Host "State              : "$response.state
        Write-Host "Step               : "$response.step
        Write-Host "Progress           : "$response.progress
        Write-Host "Error              : "$response.error

        $UserPSModuleLocation = "$HOME\Documents\WindowsPowerShell\Modules"
        if ($Mode -eq "OS_PROVISION")
        {
            $filePath = $UserPSModuleLocation + "\Bootstap_Bringup_Progress_Status.json"
        }
        else
        {
            $filePath = $UserPSModuleLocation + "\Deploy_Cluster_Progress_Status.json"
        }
        $fileExist = Test-Path $filePath
        if (-not$fileExist)
        {
            New-Item -Path $filePath -Type File -Force | Out-Null
        }
        $response | ConvertTo-Json -depth 100 | Out-File $filePath
        Write-Host "Detailed Response  : "$filePath
        Write-Host "------------------------Response End--------------------------"

        if ($response.state -eq "FAILED")
        {
            if ($Mode -eq "OS_PROVISION") {
                Write-Host "Azure Stack HCI OS install in failed status. Please check detailed response file for more or restart bring up process"
            } else {
                Write-Host "Cluster deploy in failed status. Please check detailed response file for more or restart bring up process"
            }
            break
        }
        if ($response.state -eq "COMPLETED")
        {
            if ($Mode -eq "OS_PROVISION") {
                Write-Host "Azure Stack HCI OS installation successfully completed!"
            } else {
                Write-Host "Cluster deployment system bring up successfully completed!"
            }
            break
        }
        Start-Sleep -s $SleepInterval
    }
    return $response, $null
}

function Send-RestAPI {
    param(
        [String] $Url
    )
    
    $psVersion = $PSVersionTable.PSVersion.Major
    try {
        if ($psVersion -eq 5)
        {
            $response = Invoke-RestMethod -Uri $Url -UseBasicParsing -Method GET -ContentType "application/json"
        }
        else
        {
            $response = Invoke-RestMethod -SkipCertificateCheck -Uri $Url -UseBasicParsing -Method GET -ContentType "application/json"
        }
    } catch {
        return $response, $_
    }
    return $response, $null
}