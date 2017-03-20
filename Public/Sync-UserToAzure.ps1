function Sync-UserToAzure
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True)]
        [PSCredential] $Credential,

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("UPN")]
        [string] $UserPrincipalName,

        [Parameter( Mandatory = $True)]
        [ValidateSet("Student", "Teacher", "Admin","Alumni", "NoLicense")]
        [string] $UserType
    )

    begin
    {
        Import-Module ActiveDirectory, ADSync -ErrorAction Stop -Verbose:$False
        Connect-AzureAD -Credential $Credential -ErrorAction Stop -Verbose:$False

        Write-Verbose "Waiting for users to be synced with AzureAD."

        ## Wait time between Get-AzureADUser attempts
        $sec = 3

        ## Available licenses in o365
        $Licenses = @{
            Student = "STANDARDWOFFPACK_STUDENT"
            Teacher = "STANDARDWOFFPACK_FACULTY"
            Alumni  = "EXCHANGESTANDARD_ALUMNI"
            Admin   = @("STANDARDWOFFPACK_STUDENT", "STANDARDWOFFPACK_FACULTY")
        }
    }

    process
    {
        ## Sync the user to Azure AD
        $SyncSycle = Start-ADSyncSyncCycle -PolicyType Delta
        if ($SyncSycle.Result -ne "Success")
        {
            Write-Error "ADSyncSycle delta was not a success.."
        }
        while (!(Get-AzureADUser -ObjectId $UserPrincipalName -ErrorAction SilentlyContinue))
        {
            Write-Verbose "$UserPrincipalName -- not yet synced, waiting $sec seconds"
            Start-Sleep -Seconds $sec
        }
        Write-Verbose "$UserPrincipalName -- successfully synced with AzureAD!"

        ## License the user
        $Obj = @[PSCustomObject]@{
            UserPrincipalName   = $UserPrincipalName
            License             = $UserType
        }
        ## Just return if the user doesn't need a license
        if ($UserType -eq "NoLicense")
        {
            Write-Verbose "$UserPrincipalName -- specified NoLicense, skipping"
            $Obj
            break
        }

        Write-Verbose "$UserPrincipalName -- attempting to license user"
        $AzureADUser = Get-AzureADUser -ObjectId $UserPrincipalName
        $AzureADUser | Set-AzureADUserLicense -AssignedLicenses $Licenses.$UserType
        Write-Verbose "$UserPrincipalName -- assigned license: $UserType"

        $Obj
    }
}
