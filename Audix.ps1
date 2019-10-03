$Host.UI.RawUI.WindowTitle = "Windows Powershell" + $Host.Version

Write-Host -ForegroundColor Cyan       "_______       _____________          "
Write-Host -ForegroundColor Cyan       "_______       _____________          "
Write-Host -ForegroundColor Cyan       "___    |___  _______  /__(_)___  __  "
Write-Host -ForegroundColor Cyan       "__  /| |  / / /  __  /__  /__  |/_/  "
Write-Host -ForegroundColor Cyan       "_  ___ / /_/ // /_/ / _  / __>  <    "
Write-Host -ForegroundColor Cyan       "/_/  |_\__,_/ \__,_/  /_/  /_/|_|    "
Write-Host -ForegroundColor DarkCyan   "@Littl3field                         "

#------------------------------------------------------------------------
# Check script is running as admin
#------------------------------------------------------------------------

function ValAdmin
{
    [CmdletBinding()]
    param (
    )

    # Check against the generic administrator role (language neutral).
    $AdministratorRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    # Get the current user identity
    $CurrentWindowsPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()

    # Output error if script not ran with administrator role
    if ($CurrentWindowsPrincipal.IsInRole($AdministratorRole) -eq $false)
    { 
    Write-Host -ForegroundColor Cyan "`n [ERROR] You are NOT a local administrator.  Run this script after logging on with a local administrator account."
    }

    # Output success if script ran with administrator role
    if ($CurrentWindowsPrincipal.IsInRole($AdministratorRole) -eq $true) 
    {
    Write-Host -ForegroundColor Cyan "`n [SUCCESS] Script is running with a local admin account."
    }

    # Return value
    return $CurrentWindowsPrincipal.IsInRole($AdministratorRole)

}
$IsValAdmin = ValAdmin
Start-Sleep -Seconds 2

#------------------------------------------------------------------------
# List All Auditpol Categories as CSV
#------------------------------------------------------------------------

function ListCategoryAllCsv
{
    [CmdletBinding()]
    param ()

    (auditpol.exe /get /category:* /r) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }
}

#------------------------------------------------------------------------
# List All Auditpol Subcategories as CSV
#------------------------------------------------------------------------

function ListSubcategoryAllCsv
{
    [CmdletBinding()]
    param ()

    (auditpol.exe /list /subcategory:* /r) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }
}

#------------------------------------------------------------------------
# Get Current Audit Policy
#------------------------------------------------------------------------

function GetAuditPol
{
    [CmdletBinding()]
    param (
    )

    # User helper function to execute auditpol queries
    $csvAuditCategories = ListSubcategoryAllCsv | ConvertFrom-Csv
    $csvAuditSettings   = ListCategoryAllCsv | ConvertFrom-Csv

    foreach ($csvAuditCategory in $csvAuditCategories)
    {
        # If the Category/Subcategory field starts with two blanks, it is a
        # subcategory entry - else a category entry.
        if ($csvAuditCategory.'GUID' -like '{*-797A-11D9-BED3-505054503030}')
        {
            $lastCategory     = $csvAuditCategory.'Category/Subcategory'
            $lastCategoryGuid = $csvAuditCategory.GUID
        }
        else
        {
            $csvAuditSetting = $csvAuditSettings | Where-Object { $_.'Subcategory GUID' -eq $csvAuditCategory.GUID }

            $auditPolicy = New-Object -TypeName PSObject -Property @{
                ComputerName    = $csvAuditSetting.'Machine Name'
                Category        = $lastCategory
                CategoryGuid    = $lastCategoryGuid
                Subcategory     = $csvAuditSetting.'Subcategory'
                SubcategoryGuid = $csvAuditSetting.'Subcategory GUID'
                AuditSuccess    = $csvAuditSetting.'Inclusion Setting' -like '*Success*'
                AuditFailure    = $csvAuditSetting.'Inclusion Setting' -like '*Failure*'
            }

            $auditPolicy.PSTypeNames.Insert(0, 'SecurityFever.AuditPolicy')

            Write-Output $auditPolicy
        }
    }
}
$CurrentAuditPol = GetAuditPol
#Write-Output $CurrentAuditPol

#------------------------------------------------------------------------
# Define export filepath for audit policy
#------------------------------------------------------------------------

function ExportFilePath {
        [CmdletBinding()]
        param (
        [Parameter(Mandatory=$True,ValueFromPipeline, HelpMessage = 'You need to provide a valid filepath example C:\Users\admin\Desktop')]
        [string]$SetExportFilepath
        )

        $validate = Test-Path $SetExportFilePath
        Start-Sleep -Seconds 0.5
        If ($validate -eq $true) {     
            Write-Host -ForegroundColor Cyan "`n[SUCCESS] $SetExportFilepath is a valid filepath."
            Start-Sleep -Seconds 0.5
            $a = $CurrentAuditPol
            $filename = "AudixOutput.txt"
            $a | Out-File -FilePath $SetExportFilepath'\AudixOutput.txt'
            Start-Sleep -Seconds 0.5
            Write-Host -ForegroundColor Cyan "[SUCCESS] Audit Policy exported to $SetExportFilepath $filename"
            }
               
        else
        {Write-Host -ForegroundColor Cyan "[ERROR] $SetExportFilepath is not valid, please define a valid filepath. Example: C:\Users\admin\Desktop"}
        return $ExportAudixFilepath
        }

#------------------------------------------------------------------------
# Ask user if they would like to export the current Audit Policy
#------------------------------------------------------------------------

Write-Host -ForegroundColor Cyan "`n[INFO] Would you like to export the current Audit Policy? (y/n)"
$confirmation = Read-Host 
Start-Sleep -Seconds 1
if ($confirmation -eq 'y') {
    Write-Host -ForegroundColor Cyan "[INFO] Please specify the filepath to export to. Example C:\Users\admin\Desktop"
    ExportFilePath}
    else {Write-Host -ForegroundColor Cyan "[INFO] Current Audit Policy will NOT be exported"
            }

#------------------------------------------------------------------------
# Perform backup of current Audit Policy
#------------------------------------------------------------------------

function BackupFilepath
{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$True,ValueFromPipeline, HelpMessage = 'You need to provide a valid filepath to export the backup to. Example C:\Users\admin\Desktop')]
    [string]$SetBackupFilePath
        )

    $validatebackup = Test-Path $SetBackupFilePath
    Start-Sleep -Seconds 0.5
    If ($validatebackup -eq $true) {
    Write-Host -ForegroundColor Cyan "`n[SUCCESS] $SetBackupFilePath is a valid filepath."
    Start-Sleep -Seconds 0.5
    $Backupfilename = "\AuditpolBackup.csv"
    $Join = $SetBackupFilePath + $Backupfilename
    Start-Sleep -Seconds 0.5
    (auditpol.exe /backup /file:$join) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }
        Write-Host -ForegroundColor Cyan "`n[SUCCESS] Audit Policy backup completed"
    }

    else
        {Write-Host -ForegroundColor Cyan "[ERROR] $filepath is not valid, please define a valid filepath. Example: C:\Users\admin\Desktop"}
    
    return $ExportAudixFilepath
    }

#------------------------------------------------------------------------
# Ask user if they would like to perform an Audit Policy backup
#------------------------------------------------------------------------

Write-Host -ForegroundColor Cyan "`n[INFO] Would you like to create a backup of the current audit policy? (y/n)"
$confirmation = Read-Host 
if ($confirmation -eq 'y') {
    Start-Sleep -Seconds 0.5
    Write-Host -ForegroundColor Cyan "[INFO] Please specify the filepath to export to. Example C:\Users\admin\Desktop"
    Backupfilepath
}
    else {Write-Host -ForegroundColor Cyan "[INFO] Current Audit Policy will NOT be backed up"
            }

#------------------------------------------------------------------------
# Perform Audit Policy Change
#------------------------------------------------------------------------

$argumentList= @(
'"Security State Change" /success:enable /failure:enable'
'"Security System Extension" /success:enable /failure:enable'
'"System Integrity" /success:enable /failure:enable'
'"IPsec Driver" /success:disable /failure:disable'
'"Other System Events" /success:disable /failure:enable'
'"Logon" /success:enable /failure:enable'
'"Logoff" /success:enable /failure:enable'
'"Account Lockout" /success:enable /failure:enable'
'"IPsec Main Mode" /success:disable /failure:disable'
'"IPsec Quick Mode" /success:disable /failure:disable'
'"IPsec Extended Mode" /success:disable /failure:disable'
'"Special Logon" /success:enable /failure:enable'
'"Other Logon/Logoff Events" /success:enable /failure:enable'
'"Network Policy Server" /success:enable /failure:enable'
'"File System" /success:enable /failure:enable'
'"Registry" /success:enable /failure:enable'
'"Kernel Object" /success:enable /failure:enable'
'"SAM" /success:disable /failure:disable'
'"Certification Services" /success:enable /failure:enable'
'"Application Generated" /success:enable /failure:enable'
'"Handle Manipulation" /success:disable /failure:disable'
'"File Share" /success:enable /failure:enable'
'"Filtering Platform Packet Drop" /success:disable /failure:disable'
'"Filtering Platform Connection" /success:disable /failure:disable'
'"Other Object Access Events" /success:disable /failure:disable'
'"Sensitive Privilege Use" /success:disable /failure:disable'
'"Non Sensitive Privilege Use" /success:disable /failure:disable'
'"Other Privilege Use Events" /success:disable /failure:disable'
'"Process Creation" /success:enable /failure:enable'
'"Process Termination" /success:enable /failure:enable'
'"DPAPI Activity" /success:disable /failure:disable'
'"RPC Events" /success:enable /failure:enable'
'"Audit Policy Change" /success:enable /failure:enable'
'"Authentication Policy Change" /success:enable /failure:enable'
'"Authorization Policy Change" /success:enable /failure:enable'
'"MPSSVC Rule-Level Policy Change" /success:disable /failure:disable'
'"Filtering Platform Policy Change" /success:disable /failure:disable'
'"Other Policy Change Events" /success:disable /failure:enable'
'"User Account Management" /success:enable /failure:enable'
'"Computer Account Management" /success:enable /failure:enable'
'"Security Group Management" /success:enable /failure:enable'
'"Distribution Group Management" /success:enable /failure:enable'
'"Application Group Management" /success:enable /failure:enable'
'"Other Account Management Events" /success:enable /failure:enable'
'"Directory Service Access" /success:enable /failure:enable'
'"Directory Service Changes" /success:enable /failure:enable'
'"Directory Service Replication" /success:disable /failure:disable'
'"Detailed Directory Service Replication" /success:disable /failure:disable'
'"Credential Validation" /success:enable /failure:enable'
'"Kerberos Service Ticket Operations" /success:enable /failure:enable'
'"Other Account Logon Events" /success:enable /failure:enable'
'"Kerberos Authentication Service" /success:enable /failure:enable'
)

function RunAuditPolicyChange
{
    [CmdletBinding()]
    param (
        )
    
    foreach ($policy in $argumentList) {
        Start-Sleep -Seconds 2
        $command = "auditpol.exe /set /subcategory:"
        $join = $command + $policy
        (iex $join) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }

        }
    }

#------------------------------------------------------------------------
# Force Advance Audit Policy by applying SCENoApply Regkey
#------------------------------------------------------------------------

function AddSCNoApplyLegacy
{
    [CmdletBinding()]
    param (
        )
    Start-Sleep -Seconds 2
    $LSARegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $Name = "Version"
    $value = "1"
    $SCENoApply = "SCENoApplyLegacyAuditPolicy"
    $REG_DWORD = "DWORD"

    New-ItemProperty -Path $LSARegistryPath -Name $SCENoApply -Value $value -PropertyType $REG_DWORD
    Get-ItemProperty $LSARegistryPath

    }


#------------------------------------------------------------------------
# Ask user if they would like to perform the audit policy change
#------------------------------------------------------------------------

Write-Host -ForegroundColor Cyan "`n[INFO] Would you like to set the Audit Policy to the Audix recommended settings? (y/n)"
$confirmation = Read-Host 
if ($confirmation -eq 'y') {
    Write-Host -ForegroundColor Cyan "[INFO] Running Audit Policy Changes"
    Start-Sleep -Seconds 0.1
    RunAuditPolicyChange
    Write-Host -ForegroundColor Cyan "`n[INFO] Forcing Advanced Audit Policy setting"
    AddSCNoApplyLegacy
}
    else {Write-Host -ForegroundColor Cyan "[INFO] The current audit policy will NOT be changed"
            }
