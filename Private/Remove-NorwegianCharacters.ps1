function Remove-NorwegianCharacters($String)
{
    ## Strips æ, ø, å from a string
    $String -replace "æ", "ae" -replace "ø", "oe" -replace "å", "aa"
}
