param(
    [parameter()][string]$raw
);

. .\functions.ps1
$config = ConvertTo-Hashtable (ConvertFrom-Json (Get-Content .\config -Raw))

begin
{

    $content = $raw.Content


    ##remove special Characters
}

process 
{
    ##Split on SPACE

    ##Split on period

    ##Split on underscore
}

end
{

}


