# Xiaoyi TTS line generator (edge-tts)
param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Out
)

$exe = 'D:\ruanjian\dsh-pet-venv\Scripts\edge-tts.exe'
$ff = 'D:\ruanjian\DSH\workspace\tools\ffmpeg.exe'

$clean = ($Text -replace "[\r\n\t]+", " ").Trim()
if (-not $clean) { throw "empty text" }

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$tmpMp3 = [System.IO.Path]::ChangeExtension($Out, ".mp3")
& $exe --voice zh-CN-XiaoyiNeural --text $clean --write-media $tmpMp3 2>$null
if (-not (Test-Path $tmpMp3)) { throw "edge-tts produced nothing" }

& $ff -y -loglevel error -i $tmpMp3 $Out
if (-not (Test-Path $Out)) { throw "ffmpeg convert failed" }

Write-Output "SAVED $Out"
