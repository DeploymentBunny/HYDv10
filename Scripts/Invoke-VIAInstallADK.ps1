<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $Setup,

    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("Full","MDT","SCCM","SCVM")]
    $Role = "MDT"
)

switch ($Role)
{
    SCVM
    {
    try
        {
        #Install ADK
        Write-Output "Install for $Role"
        $sArgument = " /Features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool /norestart /quiet /ceip off"
        $Process = Start-Process $Setup -ArgumentList $sArgument -NoNewWindow -PassThru -Wait
        Write-Host "Process finished with return code: " $Process.ExitCode
        #Test-Path -Path 'HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\{e9e06304-a604-434b-b35f-d9beb94dc06d}'
        }
    Catch
        {
          $ErorMsg = $_.Exception.Message
          Write-Warning "Error during script: $ErrorMsg"
          Break
        }
    }
    MDT
    {
    try
        {
        #Install ADK
        Write-Output "Install for $Role"
        $sArgument = " /Features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool /norestart /quiet /ceip off"
        $Process = Start-Process $Setup -ArgumentList $sArgument -NoNewWindow -PassThru -Wait
        Write-Host "Process finished with return code: " $Process.ExitCode
        #Test-Path -Path 'HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\{e9e06304-a604-434b-b35f-d9beb94dc06d}'
        }
    Catch
        {
          $ErorMsg = $_.Exception.Message
          Write-Warning "Error during script: $ErrorMsg"
          Break
        }
    }
    Default
    {
    }
}