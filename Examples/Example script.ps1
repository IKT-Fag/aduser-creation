Import-Module "C:\Users\admin\Documents\GitHub\aduser-creation\ADUser-Creation.psm1"

New-User -Givenname "Trygve" -Surname "Eikeland" -Group "Elever" -OUPath "OU=Brukere,OU=IKT-FAG,DC=IKT-FAG,DC=NO" |
Set-User | Sync-UserToAzure -Credential (Get-Credential) -UserType Student
