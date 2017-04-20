[CmdletBinding()]
$PublicFunction  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateFunction = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

foreach ($import in @($PublicFunction + $PrivateFunction))
{
    Write-Verbose "Importing $import"
    if ($Import.Name -like "*test*") { continue }
    try
    {
        . $import.fullname
    }
    catch
    {
        throw "Could not import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $PublicFunction.Basename
