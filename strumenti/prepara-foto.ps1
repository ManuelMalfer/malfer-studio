# Prepara le foto per il sito Malfer Studio.
#
# Come si usa:
#   1. Metti le foto (JPG dalla Nikon) nella cartella "foto-originali", dentro sottocartelle
#      che diventano le categorie del sito, per esempio:
#         foto-originali\Piatti\tagliatelle-al-ragu.jpg
#         foto-originali\Sale\sala-con-camino.jpg
#      Il nome del file diventa la didascalia ("tagliatelle-al-ragu" -> "Tagliatelle al ragu").
#      Se il nome e' quello della macchina (DSC_1234) la didascalia e' il nome della categoria.
#      Due foto speciali, direttamente in "foto-originali":
#         copertina.jpg  -> la foto grande in apertura (meglio orizzontale)
#         manuel.jpg     -> la tua foto in "Chi sono" (meglio verticale)
#   2. Lancia:  powershell -ExecutionPolicy Bypass -File strumenti\prepara-foto.ps1
#   3. Il risultato va in "foto" (rimpicciolite, senza dati GPS) con l'elenco foto.json.
#
# Le foto originali NON vanno su GitHub (la cartella e' in .gitignore).

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$radice = Split-Path -Parent $PSScriptRoot
$orig   = Join-Path $radice "foto-originali"
$dest   = Join-Path $radice "foto"
$mini   = Join-Path $dest "mini"

if (-not (Test-Path $orig)) {
  New-Item -ItemType Directory -Path $orig | Out-Null
  Write-Host "Ho creato la cartella foto-originali: mettici le foto e rilancia." -ForegroundColor Yellow
  exit
}
# ripulisce le foto preparate l'altra volta
if (Test-Path $dest) { Get-ChildItem $dest -Recurse -File -Include *.jpg, foto.json | Remove-Item -Force }
New-Item -ItemType Directory -Force -Path $dest, $mini | Out-Null

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }

function Salva-Ridotta($sorgente, $uscita, $lato, $qualita) {
  $img = [System.Drawing.Image]::FromFile($sorgente)
  try {
    # rotazione secondo l'EXIF (foto verticali)
    if ($img.PropertyIdList -contains 0x0112) {
      switch ([int]$img.GetPropertyItem(0x0112).Value[0]) {
        3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
      }
    }
    $f = [Math]::Min(1.0, $lato / [Math]::Max($img.Width, $img.Height))
    $w = [int][Math]::Round($img.Width * $f); $h = [int][Math]::Round($img.Height * $f)
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $p = New-Object System.Drawing.Imaging.EncoderParameters 1
    $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$qualita)
    $bmp.Save($uscita, $codec, $p)   # salvata da zero: nessun dato EXIF/GPS
    $bmp.Dispose()
    return @{ w = $w; h = $h }
  } finally { $img.Dispose() }
}

function Nome-Pulito($s) {
  $t = $s.ToLower() -replace "[^a-z0-9]+", "-"
  return $t.Trim("-")
}
function Didascalia($file, $cat) {
  $n = [IO.Path]::GetFileNameWithoutExtension($file)
  if ($n -match "^[A-Za-z_]{0,5}[_-]?\d{3,}$") { return $cat }   # nome della macchina (DSC_1234, _DSC1234, IMG_0001)
  $n = ($n -replace "[-_]+", " " -replace "\s+\d+$", "").Trim()
  if (-not $n) { return $cat }
  return $n.Substring(0,1).ToUpper() + $n.Substring(1)
}

$elenco = [ordered]@{ copertina = $null; ritratto = $null; foto = @() }

foreach ($speciale in @(@{ nome = "copertina"; lato = 2400; q = 80 }, @{ nome = "manuel"; lato = 1000; q = 82 })) {
  $f = Get-ChildItem $orig -File | Where-Object { $_.BaseName -ieq $speciale.nome -and $_.Extension -match "^\.jpe?g$" } | Select-Object -First 1
  if ($f) {
    $out = Join-Path $dest ($speciale.nome + ".jpg")
    Salva-Ridotta $f.FullName $out $speciale.lato $speciale.q | Out-Null
    if ($speciale.nome -eq "copertina") { $elenco.copertina = "foto/copertina.jpg" } else { $elenco.ritratto = "foto/manuel.jpg" }
    Write-Host "OK  $($f.Name)"
  }
}

$n = 0
foreach ($cartella in Get-ChildItem $orig -Directory | Sort-Object Name) {
  $cat = $cartella.Name
  foreach ($f in Get-ChildItem $cartella.FullName -File | Where-Object { $_.Extension -match "^\.jpe?g$" } | Sort-Object Name) {
    $n++
    $base = "{0:D3}-{1}" -f $n, (Nome-Pulito $cat)
    $grande = Salva-Ridotta $f.FullName (Join-Path $dest "$base.jpg") 2000 82
    $piccola = Salva-Ridotta $f.FullName (Join-Path $mini "$base.jpg") 800 76
    $elenco.foto += [ordered]@{
      grande = "foto/$base.jpg"; mini = "foto/mini/$base.jpg"
      w = $piccola.w; h = $piccola.h; cat = $cat; alt = (Didascalia $f.Name $cat)
    }
    Write-Host "OK  $cat\$($f.Name)"
  }
}

$json = $elenco | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText((Join-Path $dest "foto.json"), $json, (New-Object System.Text.UTF8Encoding $false))
$mb = [Math]::Round(((Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 1)
Write-Host ""
Write-Host "Fatto: $n foto nella galleria, $mb MB in tutto." -ForegroundColor Green
if (-not $elenco.copertina) { Write-Host "Manca copertina.jpg (la foto grande in apertura)." -ForegroundColor Yellow }
if (-not $elenco.ritratto)  { Write-Host "Manca manuel.jpg (la tua foto in Chi sono)." -ForegroundColor Yellow }
