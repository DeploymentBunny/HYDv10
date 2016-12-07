[cmdletbinding(SupportsShouldProcess=$true)]

Param
(
    [parameter(Position=0,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $Group,

    [parameter(Position=1,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $DomainNetBios,

    [parameter(Position=2,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $RemoteFQDN
)

function Zip-FilesInFolder( $zipfilename, $sourcedir )
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipFilename, $CompressionLevel, $false)
}

$UserGroup = $Group + "@" + $DomainNetBios
$RDGWCert = New-SelfSignedCertificate -DnsName $RemoteFQDN -CertStoreLocation Cert:\LocalMachine\my
$CertFolderStore = "c:\RootCert"
Import-Module RemoteDesktopServices
New-Item -Path "RDS:\GatewayServer\CAP" -Name "$Group" -UserGroups $UserGroup -AuthMethod 1
Set-Item -Path "RDS:\GatewayServer\CAP\$Group\IdleTimeout" -Value 120
Set-Item -Path "RDS:\GatewayServer\CAP\$Group\SessionTimeout" -Value 480 -SessionTimeoutAction 0

New-Item -Path "RDS:\GatewayServer\RAP" -Name "Allow Connections To Everywhere" -UserGroups $UserGroup -ComputerGroupType 2
Set-Item -Path "RDS:\GatewayServer\RAP\Allow Connections To Everywhere\PortNumbers" -Value 3389,3390

Set-Item -Path "RDS:\GatewayServer\SSLCertificate\Thumbprint" -Value $RDGWCert.Thumbprint -Verbose

New-Item -Path $CertFolderStore -ItemType Directory
Export-Certificate -Cert $RDGWCert -Type CERT -FilePath $CertFolderStore\root.cer -Force

Zip-FilesInFolder -ZipFilename C:\inetpub\wwwroot\root.zip -SourceDir $CertFolderStore

