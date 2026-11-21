# CI only: gives a GitHub Windows runner, which has no sound card, an audio output by installing the Scream
# virtual audio driver (https://github.com/duncanthrax/scream, MS-PL), and starts the Windows Audio service.
# Adapted from spytify's scripts/ci/windows-audio-device.ps1 (https://github.com/spytify/spytify, MIT licence,
# Copyright (c) 2018 Spytify by jwallet).
$ErrorActionPreference = "Stop"
Set-Service -Name Audiosrv -StartupType Automatic
Start-Service -Name Audiosrv
$zip = Join-Path $env:RUNNER_TEMP "Scream3.6.zip"
$dir = Join-Path $env:RUNNER_TEMP "Scream"
Invoke-WebRequest https://github.com/duncanthrax/scream/releases/download/3.6/Scream3.6.zip -OutFile $zip
# the release archive, pinned: a changed file is not installed as a driver
$want = "25ea5e778b4e6995a98d448b9b5f6d321f681663f1aeeec69d8e63183d008b19"
$have = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
Write-Host "Scream3.6.zip sha256 $have"
if ($have -ne $want) { throw "Scream3.6.zip: checksum $have, expected $want" }
Expand-Archive -Path $zip -DestinationPath $dir -Force
$sys = Get-ChildItem -Path $dir -Recurse -Filter Scream.sys | Where-Object { $_.FullName -match "x64" } | Select-Object -First 1
if (-not $sys) { $sys = Get-ChildItem -Path $dir -Recurse -Filter Scream.sys | Select-Object -First 1 }
$inf = Join-Path $sys.DirectoryName "Scream.inf"
$devcon = Get-ChildItem -Path $dir -Recurse -Filter "devcon*.exe" | Where-Object { $_.Name -match "x64" -or $_.Name -eq "devcon.exe" } | Select-Object -First 1
Write-Host "driver $inf, devcon $($devcon.FullName)"
# Trusting the driver's signer keeps Windows from asking before it installs.
$cert = (Get-AuthenticodeSignature $sys.FullName).SignerCertificate
$store = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()
Push-Location $sys.DirectoryName
& $devcon.FullName install $inf "*Scream"
Pop-Location
# The service picks up the new output once it starts again; on a runner it sometimes refuses the first time.
Stop-Service -Name Audiosrv -Force -ErrorAction SilentlyContinue
for ($i = 1; $i -le 10; $i++) {
  try { Start-Service -Name Audiosrv; break } catch { Write-Host "Windows Audio did not start ($i): $($_.Exception.Message)"; Start-Sleep -Seconds 3 }
}
if ((Get-Service -Name Audiosrv).Status -ne "Running") { throw "Windows Audio is not running" }
Get-CimInstance Win32_SoundDevice | Format-Table Name, Status
