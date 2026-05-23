# Genera el icono de la app y los assets de Play Store para botslode
# Salida:
#   assets/icon/botlode_logo.png            (1024x1024, fuente para flutter_launcher_icons)
#   assets/play_store/play_store_icon_512.png   (512x512)
#   assets/play_store/feature_graphic_1024x500.png (1024x500)

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$iconDir = Join-Path $projectRoot "assets\icon"
$playStoreDir = Join-Path $projectRoot "assets\play_store"

if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Path $iconDir -Force | Out-Null }
if (-not (Test-Path $playStoreDir)) { New-Item -ItemType Directory -Path $playStoreDir -Force | Out-Null }

function New-RoundedRectPath {
    param([int]$x, [int]$y, [int]$w, [int]$h, [int]$r)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-BotIcon {
    param([int]$size, [bool]$transparentBg = $false)

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    # Factor de escala (todo se diseñ a 1024)
    $s = $size / 1024.0

    if ($transparentBg) {
        $g.Clear([System.Drawing.Color]::Transparent)
    } else {
        # Fondo: rectangulo de esquinas redondeadas para que cumpla con safe area
        # Pero ademas tipico cuadrado lleno cuando se usa como launcher.
        $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 5, 5, 8))
        $g.FillRectangle($bgBrush, 0, 0, $size, $size)
        $bgBrush.Dispose()

        # Glow radial muy sutil detras del bot
        $glowSize = [int](720 * $s)
        $glowX = [int](($size - $glowSize) / 2)
        $glowY = [int](($size - $glowSize) / 2)
        $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $glowPath.AddEllipse($glowX, $glowY, $glowSize, $glowSize)
        $glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush $glowPath
        $glowBrush.CenterColor = [System.Drawing.Color]::FromArgb(50, 255, 190, 50)
        $glowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 5, 5, 8))
        $g.FillPath($glowBrush, $glowPath)
        $glowBrush.Dispose()
        $glowPath.Dispose()
    }

    # Dimensiones cabeza (diseñ a 1024) - 560x540 centrado, dentro de safe zone (~683)
    $headW = [int](560 * $s)
    $headH = [int](540 * $s)
    $headX = [int](($size - $headW) / 2)
    $headY = [int](($size - $headH) / 2 + 30 * $s)
    $headR = [int](115 * $s)

    # ANTENA - linea vertical + bola en la punta
    $antBottom = [int]($headY + 8 * $s)
    $antTop = [int]($headY - 55 * $s)
    $antCenterX = [int]($headX + $headW / 2)
    $antThick = [int](14 * $s); if ($antThick -lt 2) { $antThick = 2 }

    $antBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point ($antCenterX - 10), $antTop),
        (New-Object System.Drawing.Point ($antCenterX + 10), $antBottom),
        [System.Drawing.Color]::FromArgb(255, 220, 165, 25),
        [System.Drawing.Color]::FromArgb(255, 150, 100, 0)
    )
    $g.FillRectangle($antBrush, [int]($antCenterX - $antThick/2), $antTop, $antThick, ($antBottom - $antTop))
    $antBrush.Dispose()

    # Bola con glow
    $ballR = [int](32 * $s)
    $ballCenterY = [int]($antTop - 4 * $s)
    $ballX = $antCenterX - $ballR
    $ballY = $ballCenterY - $ballR

    # Glow exterior
    $glowR = [int]($ballR * 2.2)
    $ballGlowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $ballGlowPath.AddEllipse(($antCenterX - $glowR), ($ballCenterY - $glowR), $glowR * 2, $glowR * 2)
    $ballGlowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush $ballGlowPath
    $ballGlowBrush.CenterColor = [System.Drawing.Color]::FromArgb(140, 255, 220, 80)
    $ballGlowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 200, 0))
    $g.FillPath($ballGlowBrush, $ballGlowPath)
    $ballGlowBrush.Dispose()
    $ballGlowPath.Dispose()

    # Bola solida
    $ballBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point $ballX, $ballY),
        (New-Object System.Drawing.Point ($ballX + $ballR * 2), ($ballY + $ballR * 2)),
        [System.Drawing.Color]::FromArgb(255, 255, 240, 145),
        [System.Drawing.Color]::FromArgb(255, 225, 160, 25)
    )
    $g.FillEllipse($ballBrush, $ballX, $ballY, $ballR * 2, $ballR * 2)
    $ballBrush.Dispose()

    # Highlight en la bola
    $ballHigh = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 255, 255, 230))
    $bhR = [int]($ballR * 0.35)
    $g.FillEllipse($ballHigh, ($ballX + $ballR * 0.35), ($ballY + $ballR * 0.3), $bhR * 2, $bhR * 2)
    $ballHigh.Dispose()

    # OREJAS laterales (sensores rectangulares)
    $earW = [int](42 * $s)
    $earH = [int](190 * $s)
    $earY = [int]($headY + ($headH - $earH) / 2)
    $earR = [int](18 * $s)
    $earOffset = [int](12 * $s)

    $leftEarPath = New-RoundedRectPath ($headX - $earW + $earOffset) $earY $earW $earH $earR
    $rightEarPath = New-RoundedRectPath ($headX + $headW - $earOffset) $earY $earW $earH $earR

    $earBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point $headX, $earY),
        (New-Object System.Drawing.Point $headX, ($earY + $earH)),
        [System.Drawing.Color]::FromArgb(255, 210, 150, 25),
        [System.Drawing.Color]::FromArgb(255, 140, 90, 5)
    )
    $g.FillPath($earBrush, $leftEarPath)
    $g.FillPath($earBrush, $rightEarPath)
    $earBrush.Dispose()
    $leftEarPath.Dispose()
    $rightEarPath.Dispose()

    # Detalle interior de las orejas (lineas oscuras)
    $earDetailPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 60, 40, 0)), (3 * $s)
    $edY1 = [int]($earY + $earH * 0.35)
    $edY2 = [int]($earY + $earH * 0.55)
    $g.DrawLine($earDetailPen, ($headX - $earW + $earOffset + 8 * $s), $edY1, ($headX + $earOffset - 4 * $s), $edY1)
    $g.DrawLine($earDetailPen, ($headX - $earW + $earOffset + 8 * $s), $edY2, ($headX + $earOffset - 4 * $s), $edY2)
    $g.DrawLine($earDetailPen, ($headX + $headW - $earOffset + 8 * $s), $edY1, ($headX + $headW + $earW - $earOffset - 12 * $s), $edY1)
    $g.DrawLine($earDetailPen, ($headX + $headW - $earOffset + 8 * $s), $edY2, ($headX + $headW + $earW - $earOffset - 12 * $s), $edY2)
    $earDetailPen.Dispose()

    # CABEZA PRINCIPAL - cuadrado redondeado dorado
    $headPath = New-RoundedRectPath $headX $headY $headW $headH $headR

    $headBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point $headX, $headY),
        (New-Object System.Drawing.Point ($headX + $headW), ($headY + $headH)),
        [System.Drawing.Color]::FromArgb(255, 255, 210, 85),
        [System.Drawing.Color]::FromArgb(255, 175, 120, 5)
    )
    $g.FillPath($headBrush, $headPath)
    $headBrush.Dispose()

    # Highlight superior interno
    $hlPath = New-RoundedRectPath ($headX + [int](25 * $s)) ($headY + [int](25 * $s)) ($headW - [int](50 * $s)) ([int]($headH * 0.42)) ([int]($headR - 25 * $s))
    $hlBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point $headX, $headY),
        (New-Object System.Drawing.Point $headX, ($headY + [int]($headH * 0.42))),
        [System.Drawing.Color]::FromArgb(70, 255, 255, 220),
        [System.Drawing.Color]::FromArgb(0, 255, 255, 220)
    )
    $g.FillPath($hlBrush, $hlPath)
    $hlBrush.Dispose()
    $hlPath.Dispose()

    # Borde interior oscuro
    $borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(130, 70, 45, 0)), ([float](6 * $s))
    $g.DrawPath($borderPen, $headPath)
    $borderPen.Dispose()
    $headPath.Dispose()

    # OJOS - ojeras oscuras circulares con pupilas doradas brillantes
    $eyeR = [int](58 * $s)
    $eyeD = $eyeR * 2
    $eyeY = [int]($headY + 175 * $s)
    $leftEyeX = [int]($headX + 105 * $s)
    $rightEyeX = [int]($headX + $headW - 105 * $s - $eyeD)

    foreach ($eyeX in @($leftEyeX, $rightEyeX)) {
        # Socket oscuro
        $socketBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point $eyeX, $eyeY),
            (New-Object System.Drawing.Point ($eyeX + $eyeD), ($eyeY + $eyeD)),
            [System.Drawing.Color]::FromArgb(255, 8, 6, 4),
            [System.Drawing.Color]::FromArgb(255, 35, 25, 10)
        )
        $g.FillEllipse($socketBrush, $eyeX, $eyeY, $eyeD, $eyeD)
        $socketBrush.Dispose()

        # Pupila dorada
        $pupR = [int]($eyeR * 0.58)
        $pupD = $pupR * 2
        $pupX = $eyeX + [int](($eyeD - $pupD) / 2)
        $pupY = $eyeY + [int](($eyeD - $pupD) / 2)

        # Glow pupila
        $pgR = [int]($pupR * 1.6)
        $pgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $pgPath.AddEllipse(($eyeX + $eyeR - $pgR), ($eyeY + $eyeR - $pgR), $pgR * 2, $pgR * 2)
        $pgBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush $pgPath
        $pgBrush.CenterColor = [System.Drawing.Color]::FromArgb(160, 255, 220, 90)
        $pgBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 200, 0))
        $g.FillPath($pgBrush, $pgPath)
        $pgBrush.Dispose()
        $pgPath.Dispose()

        # Pupila solida
        $pupBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point $pupX, $pupY),
            (New-Object System.Drawing.Point ($pupX + $pupD), ($pupY + $pupD)),
            [System.Drawing.Color]::FromArgb(255, 255, 240, 140),
            [System.Drawing.Color]::FromArgb(255, 220, 160, 25)
        )
        $g.FillEllipse($pupBrush, $pupX, $pupY, $pupD, $pupD)
        $pupBrush.Dispose()

        # Highlight
        $hR = [int]($pupR * 0.32)
        $hBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230, 255, 255, 230))
        $g.FillEllipse($hBrush, ($pupX + $pupR * 0.5), ($pupY + $pupR * 0.4), $hR * 2, $hR * 2)
        $hBrush.Dispose()
    }

    # BOCA - visor/pantallita oscura con 3 leds dorados
    $mouthW = [int](200 * $s)
    $mouthH = [int](48 * $s)
    $mouthX = [int]($headX + ($headW - $mouthW) / 2)
    $mouthY = [int]($headY + 350 * $s)
    $mouthR = [int](16 * $s)
    $mouthPath = New-RoundedRectPath $mouthX $mouthY $mouthW $mouthH $mouthR

    $mouthBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point $mouthX, $mouthY),
        (New-Object System.Drawing.Point $mouthX, ($mouthY + $mouthH)),
        [System.Drawing.Color]::FromArgb(255, 10, 7, 3),
        [System.Drawing.Color]::FromArgb(255, 40, 28, 12)
    )
    $g.FillPath($mouthBrush, $mouthPath)
    $mouthBrush.Dispose()
    $mouthPath.Dispose()

    # 3 dashes dorados dentro del visor
    $dashBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 210, 60))
    $dashW = [int](28 * $s)
    $dashH = [int](10 * $s)
    $dashGap = [int](18 * $s)
    $totalDashW = $dashW * 3 + $dashGap * 2
    $dashStartX = [int]($mouthX + ($mouthW - $totalDashW) / 2)
    $dashY = [int]($mouthY + ($mouthH - $dashH) / 2)
    for ($i = 0; $i -lt 3; $i++) {
        $dx = $dashStartX + $i * ($dashW + $dashGap)
        $g.FillRectangle($dashBrush, $dx, $dashY, $dashW, $dashH)
    }
    $dashBrush.Dispose()

    # VENTILACION inferior (3 lineas)
    $ventStartY = [int]($headY + $headH - 95 * $s)
    $ventLineGap = [int](16 * $s)
    $ventW = [int]($headW * 0.55)
    $ventX = [int]($headX + ($headW - $ventW) / 2)
    $ventPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 100, 65, 0)), ([float](5 * $s))
    for ($i = 0; $i -lt 3; $i++) {
        $y = $ventStartY + $i * $ventLineGap
        $g.DrawLine($ventPen, $ventX, $y, ($ventX + $ventW), $y)
    }
    $ventPen.Dispose()

    $g.Dispose()
    return $bmp
}

function New-FeatureGraphic {
    param([string]$outPath)

    $w = 1024
    $h = 500
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # Fondo gradient diagonal
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point $w, $h),
        [System.Drawing.Color]::FromArgb(255, 10, 8, 14),
        [System.Drawing.Color]::FromArgb(255, 24, 16, 6)
    )
    $g.FillRectangle($bgBrush, 0, 0, $w, $h)
    $bgBrush.Dispose()

    # Patron diagonal sutil
    $linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(12, 255, 200, 50)), 1
    for ($i = -500; $i -lt $w + 500; $i += 28) {
        $g.DrawLine($linePen, $i, 0, ($i + 500), $h)
    }
    $linePen.Dispose()

    # Glow dorado en el centro-derecha
    $rGlowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rGlowPath.AddEllipse(($w - 500), ($h / 2 - 450), 900, 900)
    $rGlowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush $rGlowPath
    $rGlowBrush.CenterColor = [System.Drawing.Color]::FromArgb(60, 255, 175, 30)
    $rGlowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.FillPath($rGlowBrush, $rGlowPath)
    $rGlowBrush.Dispose()
    $rGlowPath.Dispose()

    # Bot icon (transparente, lado izquierdo)
    $botSize = 380
    $botImg = New-BotIcon -size $botSize -transparentBg $true
    $botX = 60
    $botY = ($h - $botSize) / 2
    $g.DrawImage($botImg, $botX, $botY, $botSize, $botSize)
    $botImg.Dispose()

    # Linea vertical sutil separando bot/texto
    $sepPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(80, 200, 150, 30)), 1.5
    $g.DrawLine($sepPen, 470, 110, 470, 390)
    $sepPen.Dispose()

    # Titulo BOTLODE en dorado, bold, grande
    $fontFamily = New-Object System.Drawing.FontFamily "Segoe UI"
    $titleFont = New-Object System.Drawing.Font $fontFamily, ([float]78), ([System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point 510, 145),
        (New-Object System.Drawing.Point 510, 245),
        [System.Drawing.Color]::FromArgb(255, 255, 220, 95),
        [System.Drawing.Color]::FromArgb(255, 200, 145, 15)
    )
    $g.DrawString("BOTLODE", $titleFont, $titleBrush, 510, 140)
    $titleFont.Dispose()
    $titleBrush.Dispose()

    # Subtitulo
    $subFont = New-Object System.Drawing.Font $fontFamily, ([float]24), ([System.Drawing.FontStyle]::Regular)
    $subBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230, 220, 195, 150))
    $g.DrawString("FACTORY  TERMINAL", $subFont, $subBrush, 518, 260)
    $subFont.Dispose()
    $subBrush.Dispose()

    # Tagline
    $tagFont = New-Object System.Drawing.Font $fontFamily, ([float]18), ([System.Drawing.FontStyle]::Italic)
    $tagBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190, 180, 160, 125))
    $g.DrawString("Tu fabrica de bots con IA", $tagFont, $tagBrush, 522, 312)
    $tagFont.Dispose()
    $tagBrush.Dispose()

    # Pequeños marcadores tipo blueprint en esquinas
    $cornerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, 200, 145, 30)), 2
    # esquina superior izquierda
    $g.DrawLine($cornerPen, 20, 20, 50, 20)
    $g.DrawLine($cornerPen, 20, 20, 20, 50)
    # esquina inferior derecha
    $g.DrawLine($cornerPen, $w - 50, $h - 20, $w - 20, $h - 20)
    $g.DrawLine($cornerPen, $w - 20, $h - 50, $w - 20, $h - 20)
    $cornerPen.Dispose()

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

Write-Host "[1/3] Generando icono principal 1024x1024..."
$mainIcon = New-BotIcon -size 1024 -transparentBg $false
$mainPath = Join-Path $iconDir "botlode_logo.png"
$mainIcon.Save($mainPath, [System.Drawing.Imaging.ImageFormat]::Png)
$mainIcon.Dispose()

Write-Host "[2/3] Generando icono Play Store 512x512..."
$psIcon = New-BotIcon -size 512 -transparentBg $false
$psPath = Join-Path $playStoreDir "play_store_icon_512.png"
$psIcon.Save($psPath, [System.Drawing.Imaging.ImageFormat]::Png)
$psIcon.Dispose()

Write-Host "[3/3] Generando feature graphic 1024x500..."
$fgPath = Join-Path $playStoreDir "feature_graphic_1024x500.png"
New-FeatureGraphic -outPath $fgPath

Write-Host ""
Write-Host "OK - Archivos generados:"
Write-Host "  - $mainPath"
Write-Host "  - $psPath"
Write-Host "  - $fgPath"
