<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $Source
)

try
    {
        #Install ADK
        Write-Output "Install MDT"
        $sArgument = " /i ""$Source"" /qb"
        $Process = Start-Process msiexec.exe -ArgumentList $sArgument -NoNewWindow -PassThru -Wait
        Write-Host "Process finished with return code: " $Process.ExitCode
        #Test-Path -Path 'HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\{e9e06304-a604-434b-b35f-d9beb94dc06d}'
    }
Catch
    {
        $ErorMsg = $_.Exception.Message
        Write-Warning "Error during script: $ErrorMsg"
        Break
    }
