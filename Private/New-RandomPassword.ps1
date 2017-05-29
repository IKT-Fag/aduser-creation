function New-RandomPassword ($NumWords = 3)
{
    ## Generate a random password like "and3her0pay"
    $string = (Get-Content -Path ".\Data\1-1000.txt" -Raw) -split "\n"
    $pw = ""
    for($i=1; $i -le $numWords; $i++) {
        $pw += $string | Select-Object -Index (Get-Random -Minimum 0 -Maximum 1000)
        if ($i -ne $numWords) {
            $pw += (Get-Random -Minimum 0 -Maximum 9)
        }
    }
    Write-Output $pw
}