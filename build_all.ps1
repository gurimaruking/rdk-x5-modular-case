# Build all STLs and preview images for rdk-x5-modular-case
#
# Usage: pwsh ./build_all.ps1

$ErrorActionPreference = "Stop"
$openscad = "C:\Program Files\OpenSCAD\openscad.exe"
if (-not (Test-Path $openscad)) {
    Write-Error "OpenSCAD not found at $openscad. Adjust path or install OpenSCAD."
    exit 1
}

$here = $PSScriptRoot
$src = Join-Path $here "rdk_x5_case.scad"
New-Item -ItemType Directory -Force (Join-Path $here "stl") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $here "images") | Out-Null

$targets = @(
    @{ Name = "case_base";   Show = 1 },
    @{ Name = "lid_default"; Show = 2 },
    @{ Name = "lid_open";    Show = 3 },
    @{ Name = "lid_vesa";    Show = 4 }
)

foreach ($t in $targets) {
    $stl = Join-Path $here "stl/$($t.Name).stl"
    $png = Join-Path $here "images/$($t.Name).png"
    Write-Host "[$($t.Name)] STL..."
    & $openscad -o $stl -D "SHOW=$($t.Show)" $src
    Write-Host "[$($t.Name)] PNG..."
    & $openscad -o $png --imgsize=1000,800 --colorscheme=Tomorrow -D "SHOW=$($t.Show)" $src
}

# Assembly preview
$asm = Join-Path $here "images/assembly_preview.png"
Write-Host "[assembly] PNG..."
& $openscad -o $asm --imgsize=1200,900 --colorscheme=Tomorrow -D "SHOW=0" $src

Write-Host "`nDone. Outputs:"
Get-ChildItem (Join-Path $here "stl") | Format-Table Name, Length
Get-ChildItem (Join-Path $here "images") | Format-Table Name, Length
