function Confirm-IsNotNullOrEmpty($String)
{
    if ([string]::IsNullOrWhiteSpace($Givenname) -or [string]::IsNullOrEmpty($Givenname))
    {
        ## $String is either $Null, empty or whitespace
        return $True
    }
    return $False
}
