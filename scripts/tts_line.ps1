# TTS line generator (edge-tts, voice: zh-CN-XiaoyiNeural)
# Env vars (optional): EDGE_TTS (edge-tts executable), FFMPEG
param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Out
)

$exe = if ($env:EDGE_TTS) { $env:EDGE_TTS } else { "edge-tts" }
$ff  = if ($env:FFMPEG)   { $env:FFMPEG }   else { "ffmpeg" }

$clean = ($Text -replace "[\r\n\t]+", " ").Trim()
if (-not $clean) { throw "empty text" }

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$tmpMp3 = [System.IO.Path]::ChangeExtension($Out, ".mp3")
& $exe --voice zh-CN-XiaoyiNeural --text $clean --write-media $tmpMp3 2>$null
if (-not (Test-Path $tmpMp3)) { throw "edge-tts produced nothing" }

& $ff -y -loglevel error -i $tmpMp3 $Out
if (-not (Test-Path $Out)) { throw "ffmpeg convert failed" }
Remove-Item $tmpMp3 -Force -ErrorAction SilentlyContinue

Write-Output "SAVED $Out"
