<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $Setup,

    [Parameter(Mandatory=$False,Position=1)]
    [ValidateSet("Default")]
    $Role = "Default",

    [Parameter(Mandatory=$False,Position=2)]
    $SCORProductKey,
    
    [Parameter(Mandatory=$true,Position=3)]
    $SCORSAccount,
    
    [Parameter(Mandatory=$true,Position=4)]
    $SCORSAccountPW,
    
    [Parameter(Mandatory=$true,Position=5)]
    $SCORDBSrv
)

$SCORProductKey

switch ($Role)
{
    Default
    {
        If(!($SCORProductKey -eq "NA"))
        {
            $Argument = "/Silent /Key:$SCORProductKey /ServiceUserName:$SCORSAccount /ServicePassword:$SCORSAccountPW /Components:All /DbServer:$SCORDBSrv /DbNameNew:Orchestrator /WebServicePort:81 /WebConsolePort:82 /OrchestratorRemote /UseMicrosoftUpdate:1 /SendTelemetryReports:0 /EnableErrorReporting:never"
        }
        Else
        {
            $Argument = "/Silent /ServiceUserName:$SCORSAccount /ServicePassword:$SCORSAccountPW /Components:All /DbServer:$SCORDBSrv /DbNameNew:Orchestrator /WebServicePort:81 /WebConsolePort:82 /OrchestratorRemote /UseMicrosoftUpdate:1 /SendTelemetryReports:0 /EnableErrorReporting:never"
        }
    }
}


try
    {
        Write-Output "Executing $Setup $Argument"
        $Process = Start-Process -FilePath """$Setup""" -ArgumentList $Argument -NoNewWindow -PassThru -Wait
        Write-Output "Process finished with return code: " $Process.ExitCode
    }
Catch
    {
        $ErorMsg = $_.Exception.Message
        Write-Warning "Error during script: $ErrorMsg"
        Break
    }
