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
        [ValidateSet("Student", "Teacher", "Admin", "Alumni", "NoLicense")]
        [string] $UserType
    )

    begin
    {
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$False

        try
        {
            Import-Module ADSync -ErrorAction Stop -Verbose:$False
        }
        catch
        {
            Write-Error "ADSync not installed on this computer. Will not be able to license user(s)."
        }

        Connect-AzureAD -Credential $Credential -ErrorAction Stop -Verbose:$False

        Write-Verbose "Waiting for users to be synced with AzureAD."

        ## Wait time between Get-AzureADUser attempts
        $sec = 3

        ## Available licenses in o365
        $Licenses = [PSCustomObject]@{
            # STANDARDWOFFPACK_STUDENT
            Student = "314c4481-f395-4525-be8b-2ec4bb1e9d91"
            # STANDARDWOFFPACK_FACULTY
            Teacher = "94763226-9b3c-4e75-a931-5c89701abe66" 
            # EXCHANGESTANDARD_ALUMNI
            Alumni  = "aa0f9eb7-eff2-4943-8424-226fb137fcad"
            # STANDARDWOFFPACK_STUDENT, STANDARDWOFFPACK_FACULTY
            Admin   = @("314c4481-f395-4525-be8b-2ec4bb1e9d91",
                        "94763226-9b3c-4e75-a931-5c89701abe66")
        }
    }

    process
    {
        ## Sync the user to Azure AD
        $SyncSycle = Start-ADSyncSyncCycle -PolicyType Delta -ErrorAction Stop
        if ($SyncSycle.Result -ne "Success")
        {
            Write-Error "ADSyncSycle delta was not a success.."
            Write-Error $Error[0]
        }
        while (!(Get-AzureADUser -ObjectId $UserPrincipalName -ErrorAction SilentlyContinue))
        {
            Write-Verbose "$UserPrincipalName -- not yet synced, waiting $sec seconds"
            Start-Sleep -Seconds $sec
        }
        Write-Verbose "$UserPrincipalName -- successfully synced with AzureAD!"

        ## License the user
        $Obj = [PSCustomObject]@{
            UserPrincipalName   = $UserPrincipalName
            License             = $UserType
            Success             = $Null
        }
        ## Just return if the user doesn't need a license
        if ($UserType -eq "NoLicense")
        {
            Write-Verbose "$UserPrincipalName -- specified NoLicense, skipping"
            $Obj.Success = $True
            $Obj
            break
        }

        Write-Verbose "$UserPrincipalName -- attempting to license user"
        try
        {
            $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
            $License.SkuId = $Licenses.$UserType

            $AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
            $AssignedLicenses.AddLicenses = $License
            Set-AzureADUserLicense -ObjectId $UserPrincipalName -AssignedLicenses $AssignedLicenses

            Write-Verbose "$UserPrincipalName -- assigned license: $UserType"
            $Obj.Success = $True
        }
        catch
        {
            $Error[0]
            $Obj.Success = $False
        }

        $Obj
    }
}
