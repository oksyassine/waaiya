# The Microsoft Store package (MSIX) of a built and bundled Windows app (flutter build windows + bundle_windows.sh):
#
#   pwsh desktop/tool/make_msix.ps1 -App desktop/build/windows/x64/runner/Release -Out waaiya.msix [-Version 1.2.13.0]
#
# Version: the Store wants four numbers, the first not 0 and the last 0; the app's version (desktop/pubspec.yaml,
# 0.2.13+15) becomes major+1.minor.patch.0 = 1.2.13.0, so it keeps growing with the app's. The package is not
# signed: the Store signs it. CI signs a copy with a test certificate to install it (windows/test/msix_test.py).
# Needs the Windows SDK (makeappx.exe, makepri.exe), as on GitHub's Windows runners.
param(
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Version = ""
)
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$msix = Join-Path $repo "desktop/windows/msix"

if (-not $Version) {
    $v = (Select-String -Path (Join-Path $repo "desktop/pubspec.yaml") -Pattern '^version:\s*(\d+)\.(\d+)\.(\d+)').Matches[0].Groups
    $Version = "{0}.{1}.{2}.0" -f ([int]$v[1].Value + 1), $v[2].Value, $v[3].Value
}
if ($Version -notmatch '^[1-9]\d*\.\d+\.\d+\.0$') { throw "Store version ${Version}: four numbers, first not 0, last 0" }

$sdk = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.*\x64\makeappx.exe" |
    Sort-Object { [version]$_.Directory.Parent.Name } | Select-Object -Last 1
if (-not $sdk) { throw "Windows SDK not found (makeappx.exe)" }
$bin = $sdk.DirectoryName
Write-Host "Windows SDK tools: $bin; package version $Version"

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("waaiya-msix-" + [guid]::NewGuid().ToString("N"))
$stage = Join-Path $tmp "package"
$res = Join-Path $tmp "resources"
New-Item -ItemType Directory -Force $stage, $res | Out-Null
Copy-Item -Recurse -Force (Join-Path $App "*") $stage
Copy-Item -Recurse -Force (Join-Path $msix "Assets") $stage
$manifest = (Get-Content -Raw (Join-Path $msix "AppxManifest.xml")).Replace("@VERSION@", $Version)
[IO.File]::WriteAllText((Join-Path $stage "AppxManifest.xml"), $manifest, [Text.UTF8Encoding]::new($false))

# resources.pri: lets Windows pick the tile image for the screen's scale (Assets\*.scale-200.png); indexed from a
# folder with only the images and the manifest, so the app's own files stay out of it
Copy-Item -Recurse (Join-Path $msix "Assets") $res
Copy-Item (Join-Path $stage "AppxManifest.xml") $res
& "$bin\makepri.exe" createconfig /cf (Join-Path $tmp "priconfig.xml") /dq en-US /pv 10.0.0 /o
if ($LASTEXITCODE) { throw "makepri createconfig: exit $LASTEXITCODE" }
& "$bin\makepri.exe" new /pr $res /cf (Join-Path $tmp "priconfig.xml") /mn (Join-Path $res "AppxManifest.xml") `
    /of (Join-Path $stage "resources.pri") /o
if ($LASTEXITCODE) { throw "makepri new: exit $LASTEXITCODE" }

& "$bin\makeappx.exe" pack /d $stage /p $Out /o
if ($LASTEXITCODE) { throw "makeappx pack: exit $LASTEXITCODE" }
Remove-Item -Recurse -Force $tmp
Write-Host ("{0}: {1:N1} MB, version {2}" -f $Out, ((Get-Item $Out).Length / 1MB), $Version)
