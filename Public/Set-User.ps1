function Set-User
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("UPN")]
        [string] $UserPrincipalName,

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("SAM")]
        [string] $SamAccountName,

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("Email", "proxyaddresses")]
        [string] $EmailAddress,

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("Server", "InfrastructureMaster")]
        [string] $ADServer,

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("Groups")]
        [string[]] $Group = @(),

        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("OU")]
        [string] $OUPath
    )

    begin
    {
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$False
        Write-Verbose "Starting user configuration.."
    }

    process
    {
        ## Check to see if OU exists
        if (!([adsi]::Exists("LDAP://$OUPath")))
        {
            Write-Verbose "$OUPath -- does not exists"
            Write-Verbose "Will attempt to create OU"
            ## TODO
        }

        try
        {
            $ErrorActionPreference = "Stop"

            ## Get a refrence to the user in AD
            Write-Verbose "$SamAccountName - getting user.."
            $User = Get-ADuser -Filter { UserPrincipalName -eq $UserPrincipalName }

            ## TODO
            ## Homefolders
            Write-Verbose "$SamAccountName - setting homefolder.."
            ## HomeDirectory

            ## Set Proxyaddresses to prevet "@onmicrosoft"-email account
            Write-Verbose "$SamAccountName - setting proxyaddresses.."
            $User | Set-ADUser -Add @{ Proxyaddresses = "SMTP:" + $EmailAddress }

            ## Add user to group(s)
            Write-Verbose "$SamAccountName - adding user to groups.."
            $Group | ForEach-Object {
                Add-ADGroupMember -Identity $PSItem -Members $User
            }

            ## Enable the user
            Write-Verbose "$SamAccountName -- enabling user"
            $User | Set-ADUser -Enabled $True

            ## Move the user to $OUPath
            Write-Verbose "$SamAccountName -- moving user to new OU.."
            $User | Move-ADObject -TargetPath $OUPath -Confirm:$False

            $Success = $True
            Write-Verbose "$SamAccountName -- successfully created the user!"
        }
        catch
        {
            $Error[0]
            $Success = $False
        }
        
        ## Return an object with information about the user
        [PSCustomObject]@{
            UserPrincipalName   = $UserPrincipalName
            SamAccountName      = $SamAccountName
            Succeeded           = $Success
            Group               = $Group
        }
    }
}
