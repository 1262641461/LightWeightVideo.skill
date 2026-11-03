# Safe H3 runner: reserve VRAM/RAM for the desktop, unload models and stop ComfyUI when done.
#
# Required env vars (or pass as parameters):
#   COMFY_DIR : path to your ComfyUI folder
#   COMFY_PY  : python.exe of the ComfyUI venv
# Optional:
#   H3_TOOL   : path to h3_i2v.py (defaults to the copy next to this script)
param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$Image,
    [string]$OutPrefix = "h3/run",
    [int]$W = 768,
    [int]$H = 768,
    [int]$Len = 124,
    [int]$Steps = 8,
    [double]$ReserveVRAM = 2.5,
    [string]$ComfyDir = $env:COMFY_DIR,
    [string]$Python = $env:COMFY_PY,
    [string]$Tool = $env:H3_TOOL
)

$ErrorActionPreference = "Stop"
if (-not $ComfyDir) { throw "set COMFY_DIR to your ComfyUI folder" }
if (-not $Python)   { throw "set COMFY_PY to the python.exe of the ComfyUI venv" }
if (-not $Tool)     { $Tool = Join-Path $PSScriptRoot "h3_i2v.py" }

function Wait-Comfy {
    param([int]$TimeoutSec = 240)
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $TimeoutSec) {
        try {
            $r = Invoke-WebRequest "http://127.0.0.1:8188/system_stats" -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Seconds 3
    }
    return $false
}

$listening = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue
$started = $false
if (-not $listening) {
    Write-Host "[1/4] starting ComfyUI (lowvram, reserve-vram $ReserveVRAM)"
    Start-Process -FilePath $Python -ArgumentList @(
        "main.py", "--lowvram", "--reserve-vram", "$ReserveVRAM",
        "--listen", "127.0.0.1", "--port", "8188"
    ) -WorkingDirectory $ComfyDir -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $env:TEMP "comfy.log") `
      -RedirectStandardError (Join-Path $env:TEMP "comfy.err.log")
    $started = $true
    if (-not (Wait-Comfy 240)) { throw "ComfyUI start timeout" }
} else {
    Write-Host "[1/4] ComfyUI already running, reuse it"
    if (-not (Wait-Comfy 60)) { throw "ComfyUI not responding" }
}

try {
    Write-Host "[2/4] submitting job"
    & $Python $Tool $Prompt $OutPrefix $Image $W $H $Len $Steps
    if ($LASTEXITCODE -ne 0) { throw "generation failed with code $LASTEXITCODE" }
    Write-Host "[3/4] generation done"
}
finally {
    try {
        Invoke-WebRequest "http://127.0.0.1:8188/free" -Method Post -Body '{"unload_models":true,"free_memory":true}' -UseBasicParsing -TimeoutSec 10 | Out-Null
    } catch { }
    Start-Sleep -Seconds 2
    if ($started) {
        $c = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue
        if ($c) { Stop-Process -Id ($c | Select-Object -First 1).OwningProcess -Force }
        Write-Host "[4/4] ComfyUI stopped"
    }
}
