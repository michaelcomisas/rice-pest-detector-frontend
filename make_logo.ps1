# Run this from your Flutter project's ROOT folder (the one with pubspec.yaml).
# Usage:  powershell -ExecutionPolicy Bypass -File make_logo.ps1

Add-Type -AssemblyName System.Drawing

$projectRoot = (Get-Location).Path

function Create-RiceLogo {
    param (
        [string]$outputPath,
        [int]$size = 1024,
        [bool]$withBackground = $true,
        [double]$scale = 1.8   # how big the plant is (1.8 keeps it inside Android's safe zone)
    )

    # Make sure the target folder exists
    $dir = Split-Path $outputPath -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($withBackground) {
        # Solid cream background (required for iOS, looks good on Android too)
        $g.Clear([System.Drawing.Color]::FromArgb(255, 253, 245, 224))
    } else {
        $g.Clear([System.Drawing.Color]::Transparent)
    }

    # Center the drawing: the plant's original center is about (262, 252)
    $g.TranslateTransform($size / 2, $size / 2)
    $g.ScaleTransform($scale, $scale)
    $g.TranslateTransform(-262, -252)

    $goldColor = [System.Drawing.Color]::FromArgb(232, 138, 0)
    $greenColor = [System.Drawing.Color]::FromArgb(21, 128, 61)

    $goldBrush = New-Object System.Drawing.SolidBrush($goldColor)
    $greenBrush = New-Object System.Drawing.SolidBrush($greenColor)

    $goldPen = New-Object System.Drawing.Pen($goldColor, 6)
    $goldPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $goldPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # --- Stalks ---
    $g.DrawBezier($goldPen,
        (New-Object System.Drawing.PointF(270, 430)),
        (New-Object System.Drawing.PointF(250, 320)),
        (New-Object System.Drawing.PointF(210, 200)),
        (New-Object System.Drawing.PointF(245, 70)))

    $g.DrawBezier($goldPen,
        (New-Object System.Drawing.PointF(260, 350)),
        (New-Object System.Drawing.PointF(280, 280)),
        (New-Object System.Drawing.PointF(300, 220)),
        (New-Object System.Drawing.PointF(340, 150)))

    # --- Grain helper ---
    function Draw-Grain {
        param ($cx, $cy, $angle, $sizeX = 32, $sizeY = 16)
        $state = $g.Save()
        $g.TranslateTransform($cx, $cy)
        $g.RotateTransform($angle)

        $sx = [single]$sizeX
        $sy = [single]$sizeY
        $half = [single]($sizeY / 2)

        $path1 = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path1.AddEllipse([single](-$sx), [single](-$half), $sx, $sy)
        $g.FillPath($goldBrush, $path1)

        $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path2.AddEllipse([single]0, [single](-$half), $sx, $sy)
        $g.FillPath($goldBrush, $path2)

        $g.Restore($state)
    }

    $leftGrains = @(
        @{X=245; Y=75;  A=-40; SX=28; SY=14},
        @{X=238; Y=95;  A=-35; SX=32; SY=16},
        @{X=228; Y=120; A=-30; SX=36; SY=18},
        @{X=218; Y=150; A=-20; SX=40; SY=20},
        @{X=212; Y=180; A=-10; SX=42; SY=21},
        @{X=212; Y=210; A=0;   SX=44; SY=22},
        @{X=218; Y=240; A=10;  SX=44; SY=22},
        @{X=228; Y=270; A=20;  SX=42; SY=21},
        @{X=240; Y=300; A=25;  SX=38; SY=19}
    )
    foreach ($gi in $leftGrains) {
        Draw-Grain -cx $gi.X -cy $gi.Y -angle $gi.A -sizeX $gi.SX -sizeY $gi.SY
    }

    $rightGrains = @(
        @{X=340; Y=150; A=40; SX=24; SY=12},
        @{X=325; Y=170; A=35; SX=28; SY=14},
        @{X=310; Y=195; A=30; SX=32; SY=16},
        @{X=298; Y=225; A=25; SX=36; SY=18},
        @{X=288; Y=255; A=20; SX=38; SY=19},
        @{X=278; Y=285; A=15; SX=38; SY=19},
        @{X=268; Y=315; A=10; SX=34; SY=17}
    )
    foreach ($gi in $rightGrains) {
        Draw-Grain -cx $gi.X -cy $gi.Y -angle $gi.A -sizeX $gi.SX -sizeY $gi.SY
    }

    # --- Leaves ---
    $lp1 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $lp1.AddBezier(
        (New-Object System.Drawing.PointF(275, 435)),
        (New-Object System.Drawing.PointF(230, 360)),
        (New-Object System.Drawing.PointF(180, 300)),
        (New-Object System.Drawing.PointF(185, 255)))
    $lp1.AddBezier(
        (New-Object System.Drawing.PointF(185, 255)),
        (New-Object System.Drawing.PointF(200, 310)),
        (New-Object System.Drawing.PointF(250, 380)),
        (New-Object System.Drawing.PointF(275, 435)))
    $g.FillPath($greenBrush, $lp1)

    $lp2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $lp2.AddBezier(
        (New-Object System.Drawing.PointF(275, 435)),
        (New-Object System.Drawing.PointF(305, 380)),
        (New-Object System.Drawing.PointF(320, 320)),
        (New-Object System.Drawing.PointF(315, 250)))
    $lp2.AddBezier(
        (New-Object System.Drawing.PointF(315, 250)),
        (New-Object System.Drawing.PointF(310, 310)),
        (New-Object System.Drawing.PointF(290, 370)),
        (New-Object System.Drawing.PointF(275, 435)))
    $g.FillPath($greenBrush, $lp2)

    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $goldBrush.Dispose(); $greenBrush.Dispose(); $goldPen.Dispose()
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Saved: $outputPath"
}

# App icon (solid background) -> used by flutter_launcher_icons
Create-RiceLogo -outputPath "$projectRoot\assets\icon\app_icon.png" -size 1024 -withBackground $true

# Logo for use inside the app (transparent background)
Create-RiceLogo -outputPath "$projectRoot\assets\images\app_logo_full.png" -size 1024 -withBackground $false -scale 2.2