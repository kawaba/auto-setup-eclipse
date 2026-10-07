$ErrorActionPreference = "Stop"

# TLS 1.2 を強制 (Windows PowerShell 5.1 で必要)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# ===========================================
# 設定
# ===========================================
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkDir = Join-Path $BaseDir "temp"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

# Eclipse 2026-09 (Java Developers, Windows x86_64)
#   Spring Tools 5.4.0 (e4.41) に合わせて 2026-09 (4.41) を使用。フォールバックは JAIST ミラー
$EclipseUrl         = "https://download.eclipse.org/technology/epp/downloads/release/2026-09/R/eclipse-java-2026-09-R-win32-x86_64.zip"
$EclipseUrlFallback = "https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2026-09/R/eclipse-java-2026-09-R-win32-x86_64.zip"
$EclipseZip = "$WorkDir\eclipse.zip"

# JDK 25 (Temurin / Adoptium)
$JdkUrl = "https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse"
$JdkZip = "$WorkDir\jdk.zip"

# Pleiades (Eclipse 日本語化プラグイン)
#   正規配布元は JAIST ミラーのみ (willbrains.jp は JS リダイレクトで JAIST を指している)
#   pleiades.zip はプラグイン本体のみ (直下に plugins/ features/)。k-webs は古い版のコピーなのでフォールバック
$PleiadesUrl         = "https://ftp.jaist.ac.jp/pub/mergedoc/pleiades/build/stable/pleiades.zip"
$PleiadesUrlFallback = "https://k-webs.jp/lecture/download/pleiades-win.zip"

$PleiadesZip = "$WorkDir\pleiades.zip"

$EclipseDir = "$BaseDir\eclipse"

Write-Host "=== Eclipse 2026-09 + JDK 25 セットアップ開始 ===" -ForegroundColor Cyan

# ===========================================
# ZIPファイル妥当性チェック (PKマジックバイト + 最小サイズ)
# ===========================================
function Test-ValidZip($path, $minSize = 1MB) {
    if (-not (Test-Path $path)) { return $false }
    try {
        $len = (Get-Item $path).Length
        if ($len -lt $minSize) {
            Write-Host "  -> File too small ($len bytes)" -ForegroundColor DarkYellow
            return $false
        }
        $fs = [System.IO.File]::OpenRead($path)
        try {
            $buf = New-Object byte[] 4
            [void]$fs.Read($buf, 0, 4)
        } finally {
            $fs.Close()
        }
        $isZip = ($buf[0] -eq 0x50 -and $buf[1] -eq 0x4B -and $buf[2] -eq 0x03 -and $buf[3] -eq 0x04)
        if (-not $isZip) {
            Write-Host "  -> Not a ZIP signature: $($buf[0].ToString('X2')) $($buf[1].ToString('X2')) $($buf[2].ToString('X2')) $($buf[3].ToString('X2'))" -ForegroundColor DarkYellow
        }
        return $isZip
    } catch {
        Write-Host "  -> Validation error: $_" -ForegroundColor DarkYellow
        return $false
    }
}

# ===========================================
# 単一URLからのDLを最大 $maxRetries 回試行
# ===========================================
function Invoke-DownloadWithRetry($url, $path, $maxRetries = 3, $delaySec = 5) {
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-Host "  Attempt $i/$maxRetries : $url"
            Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing -TimeoutSec 600
            return $true
        } catch {
            Write-Host "  Attempt $i failed: $_" -ForegroundColor Yellow
            if (Test-Path $path) { Remove-Item $path -Force }
            if ($i -lt $maxRetries) {
                Write-Host "  Waiting $delaySec seconds before retry..." -ForegroundColor DarkGray
                Start-Sleep -Seconds $delaySec
            }
        }
    }
    return $false
}

# ===========================================
# ダウンロード関数 (検証 + リトライ + フォールバック)
# ===========================================
function DownloadFile($url, $path, $fallbackUrl = $null, $minSize = 1MB) {
    # 既存ファイルがあれば妥当性チェック
    if (Test-Path $path) {
        if (Test-ValidZip $path $minSize) {
            Write-Host "Already exists (verified): $path" -ForegroundColor DarkGreen
            return
        } else {
            Write-Host "Existing file is invalid. Removing: $path" -ForegroundColor Yellow
            Remove-Item $path -Force
        }
    }

    $urls = @($url)
    if ($fallbackUrl) { $urls += $fallbackUrl }

    foreach ($u in $urls) {
        Write-Host "Downloading from: $u"
        if (Invoke-DownloadWithRetry $u $path 3 5) {
            if (Test-ValidZip $path $minSize) {
                Write-Host "Download verified: $path" -ForegroundColor DarkGreen
                return
            } else {
                Write-Host "Downloaded file is not a valid ZIP. Will try next URL." -ForegroundColor Yellow
                if (Test-Path $path) { Remove-Item $path -Force }
            }
        }
    }

    # 全URL失敗
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Red
    Write-Host " ダウンロードに失敗しました: $path" -ForegroundColor Red
    Write-Host " 試行したURL:" -ForegroundColor Red
    foreach ($u in $urls) { Write-Host "   - $u" -ForegroundColor Red }
    Write-Host ""
    Write-Host " 対処法:" -ForegroundColor Yellow
    Write-Host " 1. ブラウザで上記URLを開いて手動でダウンロード" -ForegroundColor Yellow
    Write-Host " 2. ダウンロードしたファイルを次の場所に配置:" -ForegroundColor Yellow
    Write-Host "      $path" -ForegroundColor Yellow
    Write-Host " 3. setup.ps1 を再実行 (既存ファイルは検証後に再利用される)" -ForegroundColor Yellow
    Write-Host "==============================================================" -ForegroundColor Red
    throw "Download failed for $path"
}

# ===========================================
# Eclipse ダウンロード & 展開
# ===========================================
DownloadFile $EclipseUrl $EclipseZip $EclipseUrlFallback 50MB
Write-Host "Extracting Eclipse..."
Expand-Archive -Force -Path $EclipseZip -DestinationPath $BaseDir

# ===========================================
# JDK25 ダウンロード & 展開
# ===========================================
DownloadFile $JdkUrl $JdkZip $null 50MB
Write-Host "Extracting JDK..."
Expand-Archive -Force -Path $JdkZip -DestinationPath "$EclipseDir\jdk"

# ===========================================
# Pleiades ダウンロード & 展開
# ===========================================
DownloadFile $PleiadesUrl $PleiadesZip $PleiadesUrlFallback 5MB
Write-Host "Extracting Pleiades..."
Expand-Archive -Force -Path $PleiadesZip -DestinationPath "$WorkDir\pleiades"

Copy-Item "$WorkDir\pleiades\plugins"  -Destination $EclipseDir -Recurse -Force
Copy-Item "$WorkDir\pleiades\features" -Destination $EclipseDir -Recurse -Force

# ===========================================
# eclipse.ini の書き換え
# ===========================================
$IniPath = "$EclipseDir\eclipse.ini"
$Ini = Get-Content $IniPath

# 既存の JustJ の -vm 設定を削除
$Ini = $Ini | Where-Object { $_ -notmatch "^-vm$" -and $_ -notmatch "justj" }

# 展開された JDK フォルダ名を自動検出
$JdkDir = Get-ChildItem "$EclipseDir\jdk" | Where-Object { $_.PSIsContainer } | Select-Object -First 1

# 正しい JDK パスを追加
$vmLines = @(
    "-vm",
    "jdk\$($JdkDir.Name)\bin\javaw.exe"
)

# 先頭に追加
$Ini = $vmLines + $Ini

# Pleiades の必須行 (末尾)
$Ini += "-Xverify:none"
$Ini += "-javaagent:plugins/jp.sourceforge.mergedoc.pleiades/pleiades.jar"

$Ini | Set-Content $IniPath -Encoding Default

Write-Host "eclipse.ini updated." -ForegroundColor Cyan

Write-Host "`n=== セットアップ完了! ===" -ForegroundColor Green
Write-Host "Eclipse を eclipse/eclipse.exe から起動してください。" -ForegroundColor White
Write-Host "`n次に: plugins.bat を実行してプラグインをインストールしてください。" -ForegroundColor Yellow
