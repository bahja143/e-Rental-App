Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot "assets\images\launcher_icon.png"

if (-not (Test-Path -LiteralPath $sourcePath)) {
  throw "Launcher source not found: $sourcePath"
}

function New-ResizedPng {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height
  )

  $directory = Split-Path -Parent $OutputPath
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  $source = [System.Drawing.Image]::FromFile($InputPath)
  try {
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    try {
      $bitmap.SetResolution($source.HorizontalResolution, $source.VerticalResolution)
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.DrawImage(
          $source,
          [System.Drawing.Rectangle]::new(0, 0, $Width, $Height),
          0,
          0,
          $source.Width,
          $source.Height,
          [System.Drawing.GraphicsUnit]::Pixel
        )
      }
      finally {
        $graphics.Dispose()
      }

      $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
      $bitmap.Dispose()
    }
  }
  finally {
    $source.Dispose()
  }
}

function New-IcoFromPng {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Size
  )

  $tempPng = [System.IO.Path]::GetTempFileName()
  try {
    $tempResizedPng = [System.IO.Path]::ChangeExtension($tempPng, ".png")
    Move-Item -LiteralPath $tempPng -Destination $tempResizedPng
    New-ResizedPng -InputPath $InputPath -OutputPath $tempResizedPng -Width $Size -Height $Size

    $pngBytes = [System.IO.File]::ReadAllBytes($tempResizedPng)
    $memoryStream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($memoryStream)
    try {
      $writer.Write([UInt16]0)
      $writer.Write([UInt16]1)
      $writer.Write([UInt16]1)
      $iconDimension = if ($Size -ge 256) { 0 } else { [byte]$Size }
      $writer.Write([byte]$iconDimension)
      $writer.Write([byte]$iconDimension)
      $writer.Write([byte]0)
      $writer.Write([byte]0)
      $writer.Write([UInt16]1)
      $writer.Write([UInt16]32)
      $writer.Write([UInt32]$pngBytes.Length)
      $writer.Write([UInt32]22)
      $writer.Write($pngBytes)
      [System.IO.File]::WriteAllBytes($OutputPath, $memoryStream.ToArray())
    }
    finally {
      $writer.Dispose()
      $memoryStream.Dispose()
    }
  }
  finally {
    Remove-Item -LiteralPath $tempResizedPng -ErrorAction SilentlyContinue
  }
}

$androidIcons = @{
  "android\app\src\main\res\mipmap-mdpi\ic_launcher.png" = 48
  "android\app\src\main\res\mipmap-hdpi\ic_launcher.png" = 72
  "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" = 96
  "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" = 144
  "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" = 192
}

$iosIcons = @{
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png" = 20
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png" = 40
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png" = 60
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png" = 29
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png" = 58
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png" = 87
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png" = 40
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png" = 80
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png" = 120
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png" = 120
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png" = 180
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png" = 76
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png" = 152
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png" = 167
  "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png" = 1024
}

$macosIcons = @{
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png" = 16
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png" = 32
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png" = 64
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png" = 128
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png" = 256
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png" = 512
  "macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png" = 1024
}

$webIcons = @{
  "web\favicon.png" = 32
  "web\icons\Icon-192.png" = 192
  "web\icons\Icon-512.png" = 512
  "web\icons\Icon-maskable-192.png" = 192
  "web\icons\Icon-maskable-512.png" = 512
}

foreach ($entry in $androidIcons.GetEnumerator()) {
  New-ResizedPng -InputPath $sourcePath -OutputPath (Join-Path $projectRoot $entry.Key) -Width $entry.Value -Height $entry.Value
}

foreach ($entry in $iosIcons.GetEnumerator()) {
  New-ResizedPng -InputPath $sourcePath -OutputPath (Join-Path $projectRoot $entry.Key) -Width $entry.Value -Height $entry.Value
}

foreach ($entry in $macosIcons.GetEnumerator()) {
  New-ResizedPng -InputPath $sourcePath -OutputPath (Join-Path $projectRoot $entry.Key) -Width $entry.Value -Height $entry.Value
}

foreach ($entry in $webIcons.GetEnumerator()) {
  New-ResizedPng -InputPath $sourcePath -OutputPath (Join-Path $projectRoot $entry.Key) -Width $entry.Value -Height $entry.Value
}

New-IcoFromPng -InputPath $sourcePath -OutputPath (Join-Path $projectRoot "windows\runner\resources\app_icon.ico") -Size 256

Write-Output "Launcher icons generated from $sourcePath"
