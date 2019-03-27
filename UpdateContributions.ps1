#Install-module -Name MVP 

$SubscriptionKey = 'aaabbbbcdbbcjdbjkcdjk8129310i0asd' 
Set-MVPConfiguration -SubscriptionKey $SubscriptionKey
$ContribuitionLimitGet = 200
$StartCicleDate = "2018-04-01"

$GoogleApiId = "sdklansdjhausfaksfnklasjansjvnajkscnjasjc"

#Function Get Views in Youtube Videos
function GetViewsYoutube($videoId,$GoogleApiKey)
{

    $video_url = "https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$GoogleApiKey&part=snippet,contentDetails,statistics,status"
    $web_client = new-object system.net.webclient
    $build_info=$web_client.DownloadString("$($video_url)") | ConvertFrom-Json
    return $build_info.items.statistics.viewCount

}

$Contributions = Get-MVPContribution -Limit $ContribuitionLimitGet

foreach($contribs in $Contributions)
{
    if($contribs.ContributionTypeName -eq "Video/Webcast/Podcast")
    {
        $contributionId = $contribs.ContributionId 
        $youtubeUrl = $contribs.ReferenceUrl 

       
        if($contribs.ReferenceUrl.Contains('youtu'))
        {
            $videoId = $youtubeUrl.Replace('https://youtu.be/','').Replace('https://www.youtube.com/watch?v=','')
            $ContribDate = $contribs.StartDate           
            
            if([datetime]$ContribDate -ge [datetime]$StartCicleDate)
            {
                    
                    $views = GetViewsYoutube $videoId $GoogleApiId
                    Set-MVPContribution -ContributionID $contributionId -AnnualReach $views
                    Write-Host "Updating Contribution: $($contributionId) - AnnualReach: $($views) - $($ContribDate)"
                    #Alert - Sometimes the MVP API returns error 500.
                    Start-Sleep -s 15
            }
            else
            {
                    Write-Warning "Date Out Of Range - Contribution: $($contributionId) - Not Updated - $($ContribDate)"
            }
           
            
        }

    }
}

