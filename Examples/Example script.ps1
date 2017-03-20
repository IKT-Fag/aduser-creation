Import-Module ADUser-Creation

New-User -CSVPath ".\Example CSV.csv" | Set-User | 
    Sync-UserToAzure -Credential (Get-Credential) -UserType "Admin"
