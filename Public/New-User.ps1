function New-User
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True,
                    ParameterSetName = "BulkUser")]
        [string] $CSVPath,

        [Parameter( Mandatory = $True,
                    ParameterSetName = "IndividualUser",
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("Firstname")]
        [string] $Givenname,

        [Parameter( Mandatory = $False,
                    ParameterSetName = "IndividualUser",
                    ValueFromPipelineByPropertyName = $True)]
        [string] $Middlename = $Null,

        [Parameter( Mandatory = $True,
                    ParameterSetName = "IndividualUser",
                    ValueFromPipelineByPropertyName = $True)]
        [Alias("Lastname")]
        [string] $Surname,

        [Parameter( Mandatory = $True,
                    ParameterSetName = "IndividualUser",
                    ValueFromPipelineByPropertyName = $True)]
        [string[]] $Group = @(),

        [Parameter( Mandatory = $True,
                    ParameterSetName = "IndividualUser",
                    ValueFromPipelineByPropertyName = $True)]
        [string] $OUPath
    )

    begin
    {
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$False

        ## Domain info
        $Domain = Get-ADDomain
        $DomainLdapName = $DomainInfo.DistinguishedName
        $DomainName = $Domain.Name + ".no"
        $ADServer = $Domain.InfrastructureMaster

        ## Current date and time
        $DateT = Get-Date

        Write-Verbose "Starting user creation.."
    }

    process
    {
        ## Create a collection of objects of all the users in the .csv-file,
        ## and then call New-User again, but with an object with all of the users.
        if ($CSVPath)
        {
            ## Return error if $CSVPath is not valid
            Test-Path -Path $CSVPath -ErrorAction Stop | Out-Null

            $Collection = @()
            $Users = Import-Csv -Path $CSVPath -Delimiter ";" -Encoding UTF7
            foreach ($User in $Users)
            {
                Write-Verbose "$($User.Givenname) -- loaded from csv."
                $UserObj = [PSCustomObject]@{
                    Givenname   = $User.Givenname
                    Middlename  = $User.Middlename
                    Surname     = $User.Surname
                    Group       = ($User.Group) -split ","
                    OUPath      = $User.OUPath
                }
                $Collection += $UserObj
            }
            ## Call New-User again, but with the .csv-file data converted
            ## into a collection of objects. This saves us from lots of 
            ## extra code.
            $Collection | New-User
            break
        }

        ## check to see if "Givenname" is empty. If so, we skip this one.
        if ([string]::IsNullOrWhiteSpace($Givenname) -or [string]::IsNullOrEmpty($Givenname))
        {
            Write-Verbose "skipping user because GivenName is empty"
            continue
        }

        ## Start creating user(s)
        Write-Verbose "$Givenname $Surname -- starting to create user."

        ## Naming-scheme related stuff
        ## Users will be named like so: "2017PetBom"
        $GivennameChars = 3
        $SurnameChars = 3
        if ($Givenname.Length -lt $GivennameChars) { $GivennameChars = 2 }
        if ($Surname.Length -lt $SurnameChars) { $SurnameChars = 2 }
        $GivennameShort = $Givenname.Substring(0, $GivennameChars)
        $SurnameShort   = $Surname.Substring(0, $SurnameChars)

        ## Creating Full name
        if ([string]::IsNullOrEmpty($Middlename))
        {
            $Fullname = "$Givenname $Surname"
        }
        else
        {
            $Fullname = "$Givenname $Middlename $Surname"
        }

        ## Creating SamAccountName
        $SamAccountName = "$($DateT.Year)" + $GivennameShort + $SurnameShort
        $SamAccountName = Remove-NorwegianCharacters -String $SamAccountName

        ## Creating Email-address
        $EmailAddress = ($Fullname -replace " ", ".") + "." + `
                        "$($DateT.Year)" + "@$DomainName"

        $EmailAddress = Remove-NorwegianCharacters -String $EmailAddress

        ## Creating UPN
        $UserPrincipalName = $SamAccountName + "@$DomainName"

        ## Creating a first-time password
        $PasswordParams = @{
            String      = New-RandomPassword
            AsPlainText = $True
            Force       = $True
        }
        $Password = ConvertTo-SecureString @PasswordParams

        ## Check if the user already exists
        if (Get-ADUser -Filter { UserPrincipalName -eq $UserPrincipalName })
        {
            Write-Error "$UserPrincipalName -- already exists, skipping!"
            continue
        }

        ## Create the user
        Write-Verbose "$UserPrincipalName -- creating user.."
        try
        {
            $NewAdUserParam = @{
                Name                    = $Fullname
                DisplayName             = $Fullname
                Givenname               = $Givenname
                Surname                 = $Surname
                UserPrincipalName       = $UserPrincipalName
                SamAccountName          = $SamAccountName
                AccountPassword         = $Password
                ChangePasswordAtLogon   = $True
                EmailAddress            = $EmailAddress
                Description             = $UserPrincipalName
                Enabled                 = $False ## We enable the user(s) later on
            }
            New-ADUser @NewAdUserParam -ErrorAction Stop
            Write-Verbose "$UserPrincipalName -- successfully created user."
        }
        catch
        {
            #Write-Error "$UserPrincipalName -- could not create user!"
            $Error[0]
            continue
        }

        ## Create an object of the user that we return.
        ## Useful to for example pipe to Set-User
        $UserObject = [PSCustomObject]@{
            Name                = $Fullname
            Givenname           = $Givenname
            Surname             = $Surname
            UserPrincipalName   = $UserPrincipalName
            SamAccountName      = $SamAccountName
            AccountPassword     = $Password
            EmailAddress        = $EmailAddress
            Description         = $UserPrincipalName
            Enabled             = $False 
            Group               = $Group
            ADServer            = $ADServer
            OUPath              = $OUPath
        }
        $UserObject
    }
}
