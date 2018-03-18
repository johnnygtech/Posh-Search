param(
    [parameter()][string[]]$startAddresses
);

begin
{
    . .\functions.ps1

    $config = ConvertTo-Hashtable (ConvertFrom-Json (Get-Content .\config -Raw))


    if(!$linkstate)
    {   
        #Threadsafe 
        $linkstate = [hashtable]::Synchronized(@{})

        $config.startAddresses.value | %{
            $linkstate.Add($_,@{"state"="queued";"referrer"="root"})
        }
    }
}

process 
{

    $crawlJob = {
        #Get TOP queued url
        $urlToCrawl = @($linkstate.keys | ?{$($linkstate.$_).state -eq "queued"})[0]

        $hasBeenCrawled = Get-LastCrawl -url $urlToCrawl -dataDir $($config.dataDir)
        if($hasBeenCrawled.Length -eq 0)
        {
            #Set to pending
            $linkstate.$urlToCrawl.add("crawler",$env:COMPUTERNAME)
            #Get Page Data
            $response = Invoke-WebRequest $urlToCrawl -UseDefaultCredentials
            #Add onsite links to link queue
            $response.Links.href | %{
                $currentUrl = $_
                $offSite = $($currentUrl -contains "://" -and $currentUrl -notcontains $urlToCrawl)
                if(!$offsite)
                {
                    #handle relative links
                    if($currentUrl -notcontains $urlToCrawl)
                    {
                        $compiledUrl = "$urlToCrawl$currentUrl"
                        $linkstate.add($compiledUrl,@{"state"="queued";"referrer"="$urlToCrawl"})
                    }
                }
            }

            $wordBreakerPath = "$($config.sysRoot)\wordbreaker.ps1"
            Start-Job -Name "Processing $urlToCrawl" -ScriptBlock {& $args[0] $args[1]} -ArgumentList $wordBreakerPath,$($response),$urlHash
            if($?)
            {
                $linkstate.$urlToCrawl.state = "processed"
            }
        }
        else
        {
            $linkstate.$urlToCrawl.state = "skipped"
        }
    }

    #do{
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("linkstate",$linkstate)
        $runspace.SessionStateProxy.SetVariable("config",$config)
        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace
        $powershell.AddScript($crawlJob) | Out-Null
        $handle = $powershell.BeginInvoke()

        <#
        $linkstate.keys | %{

            Write-Output "$_ - $($linkstate.$_.state)"

        }
        #>
    #}while($($linkstate.values.state -contains "queued"))
}

end
{

    #recurse
    

}