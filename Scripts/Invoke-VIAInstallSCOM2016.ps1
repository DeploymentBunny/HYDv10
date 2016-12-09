<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $SCOMSetup,

    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("Default","Complete","OMServer","OMWebConsole","OMReporting","OMConsole")]
    $SCOMRole = "Default",

    [Parameter(Mandatory=$false,Position=2)]
    $ManagementGroupName,

    [Parameter(Mandatory=$false,Position=3)]
    $SqlServerInstance,
    
    [Parameter(Mandatory=$false,Position=4)]
    $DWSqlServerInstance, 
    
    [Parameter(Mandatory=$false,Position=5)]
    $DatareaderUser,
    
    [Parameter(Mandatory=$false,Position=6)]
    $DatareaderPassword,
    
    [Parameter(Mandatory=$false,Position=7)]
    $DataWriterUser,
    
    [Parameter(Mandatory=$false,Position=8)]
    $DataWriterPassword,
    
    [Parameter(Mandatory=$false,Position=9)]
    $DASAccountUser,
    
    [Parameter(Mandatory=$false,Position=10)]
    $DASAccountPassword,
    
    [Parameter(Mandatory=$false,Position=11)]
    $ActionAccountUser,
    
    [Parameter(Mandatory=$false,Position=12)]
    $ActionAccountPassword,

    [Parameter(Mandatory=$false,Position=13)]
    $SRSInstance,

    [Parameter(Mandatory=$false,Position=14)]
    $WebSiteName = "Default Web Site"
)

Function Get-VIAOSVersion([ref]$OSv){
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    Switch -Regex ($OS.Version)
    {
    "6.1"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 7 SP1"}
                Else
            {$OSv.value = "Windows Server 2008 R2"}
        }
    "6.2"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8"}
                Else
            {$OSv.value = "Windows Server 2012"}
        }
    "6.3"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8.1"}
                Else
            {$OSv.value = "Windows Server 2012 R2"}
        }
    "10"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 10"}
                Else
            {$OSv.value = "Windows Server 2016"}
        }
    DEFAULT { "Version not listed" }
    } 
}
Function Import-VIASMSTSENV{
    try{
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        Write-Output "$ScriptName - tsenv is $tsenv "
        $MDTIntegration = $true
        
        #$tsenv.GetVariables() | % { Write-Output "$ScriptName - $_ = $($tsenv.Value($_))" }
    }
    catch{
        Write-Output "$ScriptName - Unable to load Microsoft.SMS.TSEnvironment"
        Write-Output "$ScriptName - Running in standalonemode"
        $MDTIntegration = $false
    }
    Finally{
        if ($MDTIntegration -eq $true){
            $Logpath = $tsenv.Value("LogPath")
            $LogFile = $Logpath + "\" + "$ScriptName.txt"
        }
    Else{
            $Logpath = $env:TEMP
            $LogFile = $Logpath + "\" + "$ScriptName.txt"
        }
    }
    Return $MDTIntegration
}
Function Start-VIALogging{
    Start-Transcript -path $LogFile -Force
}
Function Stop-VIALogging{
    Stop-Transcript
}
Function Invoke-VIAExe{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

    if($Arguments -eq "")
    {
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
    }else{
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
Function Invoke-VIAMsi{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MSI,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

    #Set MSIArgs
    $MSIArgs = "/i " + $MSI + " " + $Arguments

    if($Arguments -eq "")
    {
        $MSIArgs = "/i " + $MSI

        
    }
    else
    {
        $MSIArgs = "/i " + $MSI + " " + $Arguments
    
    }
    Write-Verbose "Running Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
Function Invoke-VIAMsu{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MSU,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

        #Set MSIArgs
    $MSUArgs = $MSU + " " + $Arguments

    if($Arguments -eq "")
    {
        $MSUArgs = $MSU

        
    }
    else
    {
        $MSUArgs = $MSU + " " + $Arguments
    
    }

    Write-Verbose "Running Start-Process -FilePath wusa.exe -ArgumentList $MSUArgs -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath wusa.exe -ArgumentList $MSUArgs -NoNewWindow -Wait -Passthru
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}

# Set Vars
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$SOURCEROOT = "$SCRIPTDIR\Source"
$LANG = (Get-Culture).Name
$OSV = $Null
$ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE

#Try to Import SMSTSEnv
. Import-VIASMSTSENV

#Start Transcript Logging
. Start-VIALogging

#Detect current OS Version
. Get-VIAOSVersion -osv ([ref]$osv) 

#Output base info
Write-Output ""
Write-Output "$ScriptName - ScriptDir: $ScriptDir"
Write-Output "$ScriptName - SourceRoot: $SOURCEROOT"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - OS Name: $osv"
Write-Output "$ScriptName - OS Architecture: $ARCHITECTURE"
Write-Output "$ScriptName - Current Culture: $LANG"
Write-Output "$ScriptName - Integration with MDT(LTI/ZTI): $MDTIntegration"
Write-Output "$ScriptName - Log: $LogFile"

#Generate more info
if($MDTIntegration -eq "YES"){
    $TSMake = $tsenv.Value("Make")
    $TSModel = $tsenv.Value("Model")
    $TSMakeAlias = $tsenv.Value("MakeAlias")
    $TSModelAlias = $tsenv.Value("ModelAlias")
    $TSOSDComputerName = $tsenv.Value("OSDComputerName")
    Write-Output "$ScriptName - Make:: $TSMake"
    Write-Output "$ScriptName - Model: $TSModel"
    Write-Output "$ScriptName - MakeAlias: $TSMakeAlias"
    Write-Output "$ScriptName - ModelAlias: $TSModelAlias"
    Write-Output "$ScriptName - OSDComputername: $TSOSDComputerName"
}

#Custom Code Starts--------------------------------------

switch ($SCOMRole)
{
    OMServer
    {
        $SCOMArguments = "/silent /install /components:OMServer /ManagementGroupName:$ManagementGroupName /SqlServerInstance:$SqlServerInstance /DatabaseName:OperationsManager /DWSqlServerInstance:$DWSqlServerInstance /DWDatabaseName:OperationsManagerDW /DatareaderUser:$DatareaderUser /DatareaderPassword:$DatareaderPassword /DataWriterUser:$DataWriterUser /DataWriterPassword:$DataWriterPassword /DASAccountUser:$DASAccountUser /DASAccountPassword:$DASAccountPassword /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1 /ActionAccountUser:$ActionAccountUser /ActionAccountPassword:$ActionAccountPassword"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"
    }
    OMConsole
    {
        $SCOMArguments = "/silent /install /components:OMConsole /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"
    }
    OMReporting
    {
        $SCOMArguments = "/silent /install /components:OMReporting /SRSInstance:$SRSInstance /DataReaderUser:$DataWriterUser /DataReaderPassword:$DataWriterPassword /SendODRReports:0 /UseMicrosoftUpdate:0"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"
    }
    OMWebConsole
    {
        #$WebSiteName = "Default Web Site"
        $SCOMArguments = "/silent /install /components:OMWebConsole /ManagementServer:$env:COMPUTERNAME /WebSiteName:$WebSiteName /WebConsoleAuthorizationMode:Mixed /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"
    }
    Complete
    {
        $SCOMArguments = "/silent /install /components:OMServer /ManagementGroupName:$ManagementGroupName /SqlServerInstance:$SqlServerInstance /DatabaseName:OperationsManager /DWSqlServerInstance:$DWSqlServerInstance /DWDatabaseName:OperationsManagerDW /DatareaderUser:$DatareaderUser /DatareaderPassword:$DatareaderPassword /DataWriterUser:$DataWriterUser /DataWriterPassword:$DataWriterPassword /DASAccountUser:$DASAccountUser /DASAccountPassword:$DASAccountPassword /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1 /ActionAccountUser:$ActionAccountUser /ActionAccountPassword:$ActionAccountPassword"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"

        $SCOMArguments = "/silent /install /components:OMReporting /SRSInstance:$SRSInstance /DataReaderUser:$DataWriterUser /DataReaderPassword:$DataWriterPassword /SendODRReports:0 /UseMicrosoftUpdate:0"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"

        $SCOMArguments = "/silent /install /components:OMConsole /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"

        $SCOMArguments = "/silent /install /components:OMWebConsole /ManagementServer:$env:COMPUTERNAME /WebSiteName:$WebSiteName /WebConsoleAuthorizationMode:Mixed /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1"
        Write-Output "Executing.."
        $Process = Start-Process -FilePath $SCOMSetup -ArgumentList $SCOMArguments -NoNewWindow -PassThru -Wait
        $ExeExitCode = $Process.ExitCode
        Write-Output "Process finished with return code: $ExeExitCode"
    }
    Default
    {
    }
}

#Custom Code Ends--------------------------------------

. Stop-VIALogging