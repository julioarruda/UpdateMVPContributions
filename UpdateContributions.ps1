#Install-module -Name MVP 
Param (
    [String]
    [Parameter(Mandatory=$true)]
    $GoogleApiKey,

    [String]
    [Parameter(Mandatory=$true)]
    $ChannelId,

    [String]
    [Parameter(Mandatory=$true)]
    $SubscriptionKey,

    [String]
    [Parameter(Mandatory=$true)]
    $StartCicleDate,
    
    [String]
    [Parameter(Mandatory=$true)]
    $ContributionTechnology,

    [Int]
    [ValidateRange(1, 999)]
    [Parameter(Mandatory=$false)]
    $ContribuitionLimitGet = 200
)

Function Main () {
    Write-Host "Getting contributions..."
    Set-MVPConfiguration -SubscriptionKey $SubscriptionKey
    $Contributions = Get-MVPContribution -Limit $ContribuitionLimitGet
    Write-Host "Returned $($Contributions.Count) contributions.`n"

    Write-Host "Getting YouTube videos..."
    $Videos = GetVideosYoutube($ChannelId, $GoogleApiId)
    Write-Host "Returned $($Videos.Count) videos.`n"

    foreach ($video in $Videos) {
        $videoId = $video.snippet.resourceId.videoId

        $entry = $Contributions -match $videoId
        if ($entry)
        {            
            Write-Host "Updating contribution [$($entry.Title)]..."
            UpdateConttribution $entry
        }
        else 
        {
            Write-Host "Adding new contribution [$($video.snippet.title)]..."
            AddContribution $video
        }
        Write-Host "Done.`n"
    }
}

#Function Get Views in Youtube Videos
Function GetViewsYoutube ($videoId) {

    $video_url = "https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$GoogleApiKey&part=snippet,contentDetails,statistics,status"    
    $web_client = new-object system.net.webclient
    $build_info = $web_client.DownloadString($video_url) | ConvertFrom-Json

    return $build_info.items.statistics.viewCount
}

#Function List videos IDs from YouTube Channel
Function GetVideosYoutube () {

    $channel_url = "https://www.googleapis.com/youtube/v3/channels?id=$ChannelId&key=$GoogleApiKey&part=contentDetails"
    $web_client = New-Object System.Net.WebClient
    $channel_info = $web_client.DownloadString($channel_url) | ConvertFrom-Json

    $uploadsId = $channel_info.items[0].contentDetails.relatedPlaylists.uploads        

    $playlist_url = "https://www.googleapis.com/youtube/v3/playlistItems?playlistId=$uploadsId&key=$GoogleApiKey&part=snippet&maxResults=50"
    $playlist_info = $web_client.DownloadString($playlist_url) | ConvertFrom-Json

    $videos = $playlist_info.items    
    
    return $videos
}

Function UpdateConttribution ($entry) {
    $contributionId = $entry.ContributionId 
    $youtubeUrl = $entry.ReferenceUrl 
    
    if ($entry.ReferenceUrl.Contains('youtu')) {
        $videoId = $youtubeUrl.Replace('https://youtu.be/', '').Replace('https://www.youtube.com/watch?v=', '')            
        $ContribDate = $entry.StartDate           
        
        if ([datetime]$ContribDate -ge [datetime]$StartCicleDate) {
                
            $views = GetViewsYoutube $videoId $GoogleApiId

            if ($entry.AnnualReach -eq $views) {
                Write-Host "Skipped: Same AnnualReach"
                return
            }

            Set-MVPContribution -ContributionID $contributionId -AnnualReach $views
            Write-Host "Updating Contribution $($contributionId) with $($views) views on $($ContribDate)..."
            #Alert - Sometimes the MVP API returns error 500.            
        }
        else {
            Write-Warning "Date Out Of Range - Contribution: $($contributionId) - Not Updated - $($ContribDate)"
        }
    }
}

Function AddContribution ($video) {
    $views = GetViewsYoutube $videoId $GoogleApiId

    $Splatting = @{
        startdate = $video.snippet.publishedAt
        Title = $video.snippet.title
        Description = $video.snippet.description
        ReferenceUrl = "https://youtu.be/$($video.id)"
        AnnualQuantity = '1' # Need to be 1 at least
        SecondAnnualQuantity = '0'
        AnnualReach = $views
        Visibility = 'EveryOne' # Get-MVPContributionVisibility
        ContributionType = 'Video/Webcast/Podcast' # Get-MVPContributionType
        ContributionTechnology = $ContributionTechnology # Get-MVPContributionArea
    }

    New-MVPContribution @splatting
}

Main
