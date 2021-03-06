[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$Global:RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "SharePointDSC.Reverse"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\Modules\$ModuleName\$ModuleName.psm1") -Force
$Script:spFarmAccount = $null
Describe "SharePointDsc.Reverse" {    
    InModuleScope $ModuleName {
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")        
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue     
        Import-Module $CurrentSharePointStubModule -WarningAction SilentlyContinue        

        Context "Validate Environment Data Extract" {       
            Mock Get-PSSnapin { return $null } -ModuleName "SharePointDsc.Reverse"
            Mock Add-PSSnapin { return $null } -ModuleName "SharePointDsc.Reverse"
            Mock Get-Credential { return $null } -ModuleName "SharePointDsc.Reverse"
            Mock Get-WmiObject {return $osInfo} -ModuleName "SharePointDsc.Reverse"  
     
            # Mocking the Get-SPServer cmdlet
            $wfe1 = New-Object -TypeName PSObject
            Add-Member -InputObject $wfe1 -MemberType NoteProperty -Name Name -Value "SPWFE1"

            $wfe2 = New-Object -TypeName PSObject
            Add-Member -InputObject $wfe2 -MemberType NoteProperty -Name Name -Value "SPWFE2"

            $servers = @($wfe1, $wfe2)

            Mock Get-SPServer {return $servers} -ModuleName "SharePointDsc.Reverse"

            # Mocking the Get-WmiObject cmdlet
            $osInfo = New-Object -TypeName PSObject
            Add-Member -InputObject $osInfo -MemberType NoteProperty -Name OSName -Value "Windows Server 2012 R2"
            Add-Member -InputObject $osInfo -MemberType NoteProperty -Name OSArchitecture -Value "x64"
            Add-Member -InputObject $osInfo -MemberType NoteProperty -Name Version -Value "15.0.0.0"

            # Mocking the Get-SPDatabase cmdlet
            Mock Get-SPDatabase { return $null } -ModuleName "SharePointDsc.Reverse"

            It "Read information about the Operating System" {
                Read-OperatingSystemVersion -ScriptBlock { return "value" } 
            }

            It "Read information about SQL Server" {
                Read-SQLVersion -ScriptBlock { return "value" }
            }

            It "Read information about the SharePoint version" {
                Read-SPProductVersions -ScriptBlock { return "value" }
            }        
        }

        Context "Validate Prerequisites for Reverse DSC script"{
            It "Read information about the required dependencies"{
                Set-Imports -ScriptBlock { return "value" }
            }
        }

        Context "Validate SharePoint Components Data Extract" {       

            # Mocking the Get-SPDSCInstalledProductVersion cmdlet
            $productVersionInfo = New-Object -TypeName PSObject
            Add-Member -InputObject $productVersionInfo -MemberType NoteProperty -Name FileMajorPart -Value "16"
            Mock Get-SPDSCInstalledProductVersion { return $productVersionInfo } -ModuleName "SharePointDsc.Reverse"

            Mock Get-WmiObject {return $osInfo} -ModuleName "SharePointDsc.Reverse"    
            Mock Get-SPWebApplication{return $null}
            Mock Get-SPManagedPath { return $null }
            Mock Get-SPManagedAccount { return $null }
            Mock Get-SPSite { return $null }
            Mock Get-SPServiceApplicationPool { return $null }
            Mock Get-SPDiagnosticConfig { return $null }
                 
            It "Read information about the farm's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPCreateFarm\MSFT_SPCreateFarm.psm1")
                $testParams = @{
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                    Passphrase =  New-Object System.Management.Automation.PSCredential ("PASSPHRASEUSER", (ConvertTo-SecureString "MyFarmPassphrase" -AsPlainText -Force))
                    AdminContentDatabaseName = "Admin_Content"
                    CentralAdministrationAuth = "Kerberos"
                    CentralAdministrationPort = 1234
                    InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                }
                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}                
                Read-SPFarm -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }                
                Set-ConfigurationSettings -ScriptBlock { return "value" }
            }
            
            It "Read information about the Web Applications' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPWebApplication\MSFT_SPWebApplication.psm1")
                $testParams = @{
                    Name = "SharePoint Sites"
                    ApplicationPool = "SharePoint Web Apps"
                    ApplicationPoolAccount = "DEMO\ServiceAccount"
                    Url = "http://sites.sharepoint.com"
                    AuthenticationMethod = "NTLM"
                    Ensure = "Present"
                }

                Import-Module $modulePath             
                Mock Get-TargetResource{return $testParams}
                Read-SPWebApplications -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Managed Paths' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedPath\MSFT_SPManagedPath.psm1")   
                $testParams = @{
                    WebAppUrl   = "http://sites.sharepoint.com"
                    RelativeUrl = "teams"
                    Explicit    = $false
                    HostHeader  = $false
                    Ensure      = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams} 
                Read-SPManagedPaths -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Managed Accounts' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedAccount\MSFT_SPManagedAccount.psm1")
                $testParams = @{
                    Account = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                    EmailNotification = 7
                    PreExpireDays = 7
                    Schedule = ""
                    Ensure = "Present"
                    AccountName = "username"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-SPManagedAccounts -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Service Application Pools' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPServiceAppPool\MSFT_SPServiceAppPool.psm1")
                $testParams = @{
                    Name = "Service pool"
                    ServiceAccount = "DEMO\svcSPServiceApps"
                    Ensure = "Present"
                }

                Import-Module $modulePath                
                Mock Get-TargetResource{return $testParams}
                Read-SPServiceApplicationPools -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Site Collections' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSite\MSFT_SPSite.psm1")
                $testParams = @{
                    Url = "http://site.sharepoint.com"
                    OwnerAlias = "DEMO\User"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-SPSites -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Service Instances' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPServiceInstance\MSFT_SPServiceInstance.psm1")
                $testParams = @{
                    Name = "Service pool"
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-SPServiceInstance { return $null } -ModuleName "SharePointDsc.Reverse"
                Mock Get-TargetResource{return $testParams}
                Read-SPServiceInstance -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Usage Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPUsageApplication\MSFT_SPUsageApplication.psm1")
                $testParams = @{
                    Name = "Usage Service App"
                    UsageLogCutTime = 60
                    UsageLogLocation = "L:\UsageLogs"
                    UsageLogMaxFileSizeKB = 1024
                    UsageLogMaxSpaceGB = 10
                    DatabaseName = "SP_Usage"
                    DatabaseServer = "sql.test.domain"
                    FailoverDatabaseServer = "anothersql.test.domain"
                    Ensure = "Present"
                }

                Import-Module $modulePath

                # Mocking the Get-SPUsageApplication
                Mock Get-SPUsageApplication { return $null } -ModuleName "SharePointDsc.Reverse"
                Mock Get-TargetResource{return $testParams}
                Read-UsageServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the State Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPStateServiceApp\MSFT_SPStateServiceApp.psm1")
                $testParams = @{
                    Name = "State Service App"
                    DatabaseName = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    DatabaseCredentials = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-SPStateServiceApplication { return $null } -ModuleName "SharePointDSC.Reverse"
                Mock Get-TargetResource{return $testParams}
                Read-StateServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the User Profile Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPUserProfileServiceApp\MSFT_SPUserProfileServiceApp.psm1")
                $testParams = @{
                    Name = "User Profile Service App"
                    ApplicationPool = "SharePoint Service Applications"
                    FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-UserProfileServiceapplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Cache Accounts' configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPCacheAccounts\MSFT_SPCacheAccounts.psm1")
                $testParams = @{
                    WebAppUrl = "http://test.sharepoint.com"
                    SuperUserAlias = "DEMO\SuperUser"
                    SuperReaderAlias = "DEMO\SuperReader"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-CacheAccounts -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Secure Store Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSecureStoreServiceApp\MSFT_SPSecureStoreServiceApp.psm1")
                $testParams = @{
                    Name = "Secure Store Service Application"
                    ApplicationPool = "SharePoint Search Services"
                    AuditingEnabled = $false
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-SecureStoreServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the BCS Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPBCSServiceApp\MSFT_SPBCSServiceApp.psm1")
                $testParams = @{
                    Name = "Test App"
                    ApplicationPool = "Test App Pool"
                    DatabaseName = "Test_DB"
                    DatabaseServer = "TestServer\Instance"
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-BCSServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Search Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSearchServiceApp\MSFT_SPSearchServiceApp.psm1")
                $testParams = @{
                    Name = "Search Service Application"
                    ApplicationPool = "SharePoint Search Services"
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-SearchServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }

            It "Read information about the Managed Metadata Service Application's configuration" {
                $modulePath = (Join-Path $Global:RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedMetadataServiceApp\MSFT_SPManagedMetadataServiceApp.psm1")
                $testParams = @{
                    Name = "Managed Metadata Service App"
                    ApplicationPool = "SharePoint Service Applications"
                    DatabaseServer = "databaseserver\instance"
                    DatabaseName = "SP_MMS"
                    Ensure = "Present"
                }

                Import-Module $modulePath
                Mock Get-TargetResource{return $testParams}
                Read-ManagedMetadataServiceApplication -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
            }
        }
    }
}
