Import-Module "C:\Users\admin\Documents\GitHub\aduser-creation\ADUser-Creation.psm1"
$Path = ".\Example CSV.csv"

New-User -CSVPath $Path | Set-User 
