Remove-Module ADUser-Creation
Import-Module "C:\Users\admin\Documents\GitHub\aduser-creation\ADUser-Creation.psm1"

InModuleScope ADUser-Creation {
    Describe 'Individual New-User' {

        Context 'Should NOT fail checks' {
            ## Mocks that makes external modules succeed
            Mock -CommandName New-ADUser -MockWith { return $True }
            Mock -CommandName Get-ADUser -MockWith { return $False }
            Mock -CommandName Import-Module -MockWith { return $True }

            $NewUserParams = @{
                'Givenname' = "Pester$(Get-Random -Minimum 1000 -Maximum 9999)"
                'Middlename' = ''
                'Surname' = 'UnitTest'
                'Group' = @('2isa', 'elever', 'Local Admins')
                'OUPath' = 'OU=PowerShellTest,OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO'
            }

            It 'Does not Throw' {
                { New-User @NewUserParams -ErrorAction Stop } | Should Not Throw
            }

            It 'Shoud not return Null or Empty' {
                New-User @NewUserParams | Should Not BeNullOrEmpty
            }
        }

        Context 'Should FAIL tests' {
            ## Mocks that makes external modules succeed
            It 'Should Throw on New-ADUser' {
                Mock -CommandName New-ADUser -MockWith { return $False } # FAIL
                Mock -CommandName Get-ADUser -MockWith { return $False }
                Mock -CommandName Import-Module -MockWith { return $True }
                $NewUserParams = @{
                    'Givenname' = "Pester$(Get-Random -Minimum 1000 -Maximum 9999)"
                    'Middlename' = ''
                    'Surname' = 'UnitTest'
                    'Group' = @('2isa', 'elever', 'Local Admins')
                    'OUPath' = 'OU=PowerShellTest,OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO'
                }

                { New-ADUser @NewUserParams -ErrorAction Stop } | Should Throw
            }

            It 'Should Throw on Get-ADUser' {
                Mock -CommandName New-ADUser -MockWith { return $True }
                Mock -CommandName Get-ADUser -MockWith { return $True } # FAIL
                Mock -CommandName Import-Module -MockWith { return $True }
                $NewUserParams = @{
                    'Givenname' = "Pester$(Get-Random -Minimum 1000 -Maximum 9999)"
                    'Middlename' = ''
                    'Surname' = 'UnitTest'
                    'Group' = @('2isa', 'elever', 'Local Admins')
                    'OUPath' = 'OU=PowerShellTest,OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO'
                }

                { New-ADUser @NewUserParams -ErrorAction Stop } | Should Throw
            }
        }

        Context 'Test individual user creation' {
            Mock -CommandName New-ADUser -MockWith { return $True }
            Mock -CommandName Get-ADUser -MockWith { return $False }
            Mock -CommandName Import-Module -MockWith { return $True }

            It 'Returns [PSCustomObject]' {
                $NewUserParams = @{
                    'Givenname' = "Pester$(Get-Random -Minimum 1000 -Maximum 9999)"
                    'Middlename' = ''
                    'Surname' = 'UnitTest'
                    'Group' = @('2isa', 'elever', 'Local Admins')
                    'OUPath' = 'OU=PowerShellTest,OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO'
                }
                New-User @NewUserParams | Should BeOfType [PSCustomObject]
            }
        }
    }

    Describe 'CSV New-User' {
        
    }
}
