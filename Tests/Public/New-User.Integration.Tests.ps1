Remove-Module ADUser-Creation
Import-Module "C:\Users\admin\Documents\GitHub\aduser-creation\ADUser-Creation.psm1"
Import-Module ActiveDirectory

function Get-PesterName
{
    Write-Output ("$(Get-Random -Minimum 999 -Maximum 9999)Pester")
}

$Global:NewUserParams = @{
    'Givenname' = ""
    'Middlename' = ''
    'Surname' = 'UnitTest'
    'Group' = @('2isa', 'elever', 'Local Admins')
    'OUPath' = 'OU=PowerShellTest,OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO'
}

InModuleScope ADUser-Creation {
    Describe '(INTEGRATION TEST)Individual New-User' {
        Context 'Should NOT fail checks' {
            ## Change the givenname 
            $NewUserParams.Givenname = Get-PesterName
            It 'Does not Throw' {
                { New-User @NewUserParams -ErrorAction Stop } | Should Not Throw
            }

            $NewUserParams.Givenname = Get-PesterName
            It 'Shoud not return Null or Empty' {
                New-User @NewUserParams | Should Not BeNullOrEmpty
            }
        }

        Context 'Test individual user creation' {
            $User = Get-PesterName

            It 'Should return [PSCustomObject]' {
                $NewUserParams.Givenname = $User
                New-User @NewUserParams | Should BeOfType [PSCustomObject]
            }

            It 'Should exist in AD' {
                Get-ADUser -Filter {Givenname -eq $User} | Should Be $True
            }
        }
    }

    Describe 'CSV New-User' {
        
    }

    Describe 'Cleanup' {
        It 'Should remove all users created' {
            $Users = Get-ADUser -Filter {Givenname -like "*Pester"}
            $Users | Remove-User -Confirm:$False
        }
    }
}
