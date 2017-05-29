function Remove-User
{
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string] $Username,

        [Parameter( Mandatory = $False)]
        [bool] $Confirm = $True
    )

    begin
    {
        $ErrorActionPreference = "Stop"
        Import-Module ActiveDirectory
    }

    process
    {
        try
        {
            Write-Output "$Username -- deleting AD user.."
            $User = Get-ADUser -Identity $Username -ErrorAction Stop
            $Remove = $User | Remove-ADUser -Confirm:$Confirm -ErrorAction Stop
            $Remove
        }
        catch
        {
            Write-Error "$Username -- could not remove user!"
            Write-Error $Error[0]
        }
    }
}
