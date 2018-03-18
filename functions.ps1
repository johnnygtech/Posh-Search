Function Get-StringHash
{
#http://jongurgul.com/blog/get-stringhash-get-filehash/ 
    param(
        [parameter()]$string
        ,[parameter()][validateSet(
            "SHA",
            #"SHA1",
            #"System.Security.Cryptography.SHA1",
            #"System.Security.Cryptography.HashAlgorithm",
            "MD5",
            #"System.Security.Cryptography.MD5",
            "SHA256",
            #"SHA-256",
            #"System.Security.Cryptography.SHA256",
            "SHA384",
            #"SHA-384",
            #"System.Security.Cryptography.SHA384",
            "SHA512"
            #"SHA-512",
            #"System.Security.Cryptography.SHA512"
        )]$algorithm = "SHA256"
    );

    $StringBuilder = New-Object System.Text.StringBuilder 
    [System.Security.Cryptography.HashAlgorithm]::Create($algorithm).ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
            $string = $null
            [Void]$StringBuilder.Append($_.ToString("x2")
        ) 
    } 
    $StringBuilder.ToString() 
}

function ConvertTo-Hashtable
{
#http://stackoverflow.com/questions/22002748/hashtables-from-convertfrom-json-have-different-type-from-powershells-built-in-h
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

function Get-LastCrawl
{
    param(
        [parameter()][string]$url
        ,[parameter()]$dataDir
    );

    $hash = Get-StringHash $url
    Set-Location $dataDir;
    $it=0;do{$current = "$($hash[$it])$($hash[$it+1])$($hash[$it+2])$($hash[$it+3])"; set-Location $(New-Item -ItemType Directory -Name $current);$it = $it+4}until($it -eq 64)

    $item = Get-item doesntexist -ErrorAction SilentlyContinue
    if(!$?)
    {
        $item = New-Item -Name $hash -ItemType File
    }

    return $item
}