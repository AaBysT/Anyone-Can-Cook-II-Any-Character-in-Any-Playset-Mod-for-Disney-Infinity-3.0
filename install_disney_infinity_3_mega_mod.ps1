$ErrorActionPreference = "Stop"
$ModDir = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
trap {
    $msg = @("UNEXPECTED INSTALLER ERROR","Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')","","Message:",$_.Exception.Message,"","Location:",$_.InvocationInfo.PositionMessage,"","Script stack:",$_.ScriptStackTrace) -join [Environment]::NewLine
    try { $msg | Set-Content -LiteralPath (Join-Path $ModDir "install_mega_mod_last_error.txt") -Encoding UTF8 } catch {}
    Write-Host ""; Write-Host "UNEXPECTED INSTALLER ERROR:" -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Write-Host ""; Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkRed; Write-Host ""; Write-Host "The BAT window will remain open." -ForegroundColor Yellow; exit 1
}
$Expected = @{
    "startup.zip" = "babf0c65792050d191c562bc0cb9011a69dc74c42f16cb7c6ca2a0f651d68a24"
    "core.zip" = "971594c29b916466b7d82bb5b30f3485a2b12b3a56c47ed7b7f8423aeab12ea9"
    "theclonewars.zip" = "223bd1672cb704510884646feaeb392431245592932f7febd0bb4442546f217c"
    "empire.zip" = "fc84d7b792cb77a2d51d29713baef2438ad278f9ecca922d0a87290159538c01"
    "insideout.zip" = "8b38640091d770a994de3f5a234f3808e3e53ac5d9d3c6cc9814ba1a17e30132"
    "playsetx.zip" = "92f004e962db0292353d9af536b613bc963f894c3cad19ee68cf9a94a1623764"
}
function Die([string]$Message) { Write-Host ""; Write-Host "ERROR: $Message" -ForegroundColor Red; Write-Host ""; Read-Host "Press ENTER to close"; exit 1 }
function Find-ExactlyOne([string]$Root,[string]$Name) {
    $hits=@(Get-ChildItem -LiteralPath $Root -Filter $Name -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.FullName.StartsWith($ModDir,[System.StringComparison]::OrdinalIgnoreCase) })
    if($hits.Count -eq 0){Die "Could not find $Name anywhere under the selected game folder."}
    if($hits.Count -gt 1){Write-Host "";Write-Host "Found multiple copies of ${Name}:" -ForegroundColor Yellow;$hits|ForEach-Object{Write-Host "  $($_.FullName)"};Die "Refusing to guess which $Name is the real target."}
    return $hits[0].FullName
}
Clear-Host
Write-Host "================================================================="
Write-Host " DISNEY INFINITY 3.0 - MEGA ALL-CHARACTERS / ALL-PLAYSETS MOD V2"
Write-Host "================================================================="
Write-Host ""
Write-Host "105 official playable characters across:"
Write-Host "  Twilight of the Republic"
Write-Host "  Rise Against the Empire"
Write-Host "  Inside Out"
Write-Host "  The Force Awakens"
Write-Host ""
foreach($name in $Expected.Keys){$src=Join-Path $ModDir $name;if(-not(Test-Path -LiteralPath $src -PathType Leaf)){Die "Missing required mod file beside the installer: $name"};$hash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash.ToLowerInvariant();if($hash -ne $Expected[$name]){Die "$name does not match this build.`nExpected: $($Expected[$name])`nFound:    $hash"}}
Write-Host "Payload hashes: OK" -ForegroundColor Green;Write-Host ""
$GameRoot=Read-Host "Paste or drag the Disney Infinity 3.0 INSTALL folder here";$GameRoot=$GameRoot.Trim().Trim('"');if([string]::IsNullOrWhiteSpace($GameRoot)){Die "No game folder was provided."};if(-not(Test-Path -LiteralPath $GameRoot -PathType Container)){Die "That folder does not exist."};$GameRoot=[System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
Write-Host "";Write-Host "Locating game files..."
$KnownPlaysetTargets=@{
 "theclonewars.zip"="assets\gamedb\theclonewars\theclonewars.zip"
 "empire.zip"="assets\gamedb\empire\empire.zip"
 "insideout.zip"="assets\gamedb\insideout\insideout.zip"
 "playsetx.zip"="assets\gamedb\playsetx\playsetx.zip"
}
$Targets=@{}
foreach($name in $Expected.Keys){if($KnownPlaysetTargets.ContainsKey($name)){$candidate=Join-Path $GameRoot $KnownPlaysetTargets[$name];if(-not(Test-Path -LiteralPath $candidate -PathType Leaf)){Die "Could not find the expected GameDB target for ${name}:`n$candidate"};$Targets[$name]=[System.IO.Path]::GetFullPath($candidate)}else{$Targets[$name]=Find-ExactlyOne $GameRoot $name};Write-Host "  $name";Write-Host "    -> $($Targets[$name])"}
$PayloadExes=@(Get-ChildItem -LiteralPath $ModDir -Filter "*.exe" -File -Force -ErrorAction SilentlyContinue);$ExeInstall=$null
if($PayloadExes.Count -gt 1){Write-Host "";Write-Host "EXE files found in installer folder:" -ForegroundColor Yellow;$PayloadExes|ForEach-Object{Write-Host "  $($_.Name)"};Die "Put only ONE patched EXE beside the installer."}
elseif($PayloadExes.Count -eq 1){$payloadExe=$PayloadExes[0];$targetExe=Find-ExactlyOne $GameRoot $payloadExe.Name;$ExeInstall=@{Source=$payloadExe.FullName;Target=$targetExe;Hash=(Get-FileHash -LiteralPath $payloadExe.FullName -Algorithm SHA256).Hash.ToLowerInvariant();Name=$payloadExe.Name}}
Write-Host "";Write-Host "Installing..." -ForegroundColor Cyan
foreach($name in $Expected.Keys){Copy-Item -LiteralPath (Join-Path $ModDir $name) -Destination $Targets[$name] -Force;$installedHash=(Get-FileHash -LiteralPath $Targets[$name] -Algorithm SHA256).Hash.ToLowerInvariant();if($installedHash -ne $Expected[$name]){Die "Copy verification failed for $name."};Write-Host "  $name : OK" -ForegroundColor Green}
if($null -ne $ExeInstall){Copy-Item -LiteralPath $ExeInstall.Source -Destination $ExeInstall.Target -Force;$installedExeHash=(Get-FileHash -LiteralPath $ExeInstall.Target -Algorithm SHA256).Hash.ToLowerInvariant();if($installedExeHash -ne $ExeInstall.Hash){Die "Copy verification failed for $($ExeInstall.Name)."};Write-Host "  $($ExeInstall.Name) : OK" -ForegroundColor Green}
$FmvDir=Join-Path $GameRoot "assets\fmv";$FmvArchiveName="VENOM_DISABLED_FMV";$FmvArchiveDir=Join-Path $FmvDir $FmvArchiveName
Write-Host "";Write-Host "Disabling boot intro FMVs..." -ForegroundColor Cyan
if(Test-Path -LiteralPath $FmvDir -PathType Container){New-Item -ItemType Directory -Path $FmvArchiveDir -Force|Out-Null;$Pc1Live=Join-Path $FmvDir "pc1";$Pc1Archived=Join-Path $FmvArchiveDir "pc1";if((-not(Test-Path -LiteralPath $Pc1Live)) -and (Test-Path -LiteralPath $Pc1Archived)){Move-Item -LiteralPath $Pc1Archived -Destination $FmvDir -Force;Write-Host "  Restored pc1 to assets\fmv." -ForegroundColor Green};$fmvItems=@(Get-ChildItem -LiteralPath $FmvDir -Force -ErrorAction Stop|Where-Object{$_.FullName -ne $FmvArchiveDir -and $_.Name -ne "pc1"});foreach($item in $fmvItems){Move-Item -LiteralPath $item.FullName -Destination $FmvArchiveDir -Force};Write-Host "  pc1 preserved in assets\fmv." -ForegroundColor Green}else{Write-Host "  WARNING: assets\fmv was not found; intro-skip step was skipped." -ForegroundColor Yellow}
Write-Host "";Write-Host "=================================================================";Write-Host " MEGA MOD V2 INSTALL COMPLETE" -ForegroundColor Green;Write-Host "=================================================================";Write-Host "";Write-Host "All six archives and the patched EXE were installed and verified.";Write-Host "";Read-Host "Press ENTER to close"