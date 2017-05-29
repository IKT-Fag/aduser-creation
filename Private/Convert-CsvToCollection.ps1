function Convert-CsvToCollection
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True
        )]
        $CSVPath
    )

    Test-Path -Path $CSVPath -ErrorAction Stop | Out-Null

    $Collection = @()
    $Users = Import-Csv -Path $CSVPath -Delimiter ";" -Encoding UTF7
    foreach ($User in $Users) {
        Write-Verbose "$($User.Givenname) -- loaded from csv."
        $UserObj = [PSCustomObject]@{
            Givenname  = $User.Givenname
            Middlename = $User.Middlename
            Surname    = $User.Surname
            Group      = ($User.Group) -split ","
            OUPath     = $User.OUPath
        }
        $Collection += $UserObj
    }

    return [Array]($Collection)
}
