$ErrorActionPreference = "Stop"

# ===========================================
# 設定
# ===========================================
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkDir = Join-Path $BaseDir "temp"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

# Eclipse 2025-09
#$EclipseUrl = "https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2025-09/R/eclipse-java-2025-09-R-win32-x86_64.zip"
$EclipseUrl =  "https://ftp.jaist.ac.jp/pub/eclipse/technology/epp/downloads/release/2025-12/R/eclipse-java-2025-12-R-win32-x86_64.zip"

$EclipseZip = "$WorkDir\eclipse.zip"

# JDK 25(Temurin)
$JdkUrl = "https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse"
$JdkZip = "$WorkDir\jdk.zip"

# Pleiades
$PleiadesUrl = "https://ftp.jaist.ac.jp/pub/mergedoc/pleiades/build/stable/pleiades-win.zip"
$PleiadesZip = "$WorkDir\pleiades.zip"

$EclipseDir = "$BaseDir\eclipse"

Write-Host "=== Eclipse 2025-12 + JDK 25 セットアップ開始 ===" -ForegroundColor Cyan

# ===========================================
# ダウンロード関数
# ===========================================
function DownloadFile($url, $path) {
    if (!(Test-Path $path)) {
        Write-Host "Downloading $url ..."
        Invoke-WebRequest $url -OutFile $path
    } else {
        Write-Host "Already exists: $path"
    }
}

# ===========================================
# Eclipse ダウンロード & 展開
# ===========================================
DownloadFile $EclipseUrl $EclipseZip
Write-Host "Extracting Eclipse..."
Expand-Archive -Force -Path $EclipseZip -DestinationPath $BaseDir

# ===========================================
# JDK25 ダウンロード & 展開
# ===========================================
DownloadFile $JdkUrl $JdkZip
Write-Host "Extracting JDK..."
Expand-Archive -Force -Path $JdkZip -DestinationPath "$EclipseDir\jdk"

# ===========================================
# Pleiades ダウンロード & 展開
# ===========================================
DownloadFile $PleiadesUrl $PleiadesZip
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

# Pleiades の必須行(末尾)
$Ini += "-Xverify:none"
$Ini += "-javaagent:plugins/jp.sourceforge.mergedoc.pleiades/pleiades.jar"

$Ini | Set-Content $IniPath -Encoding Default

Write-Host "eclipse.ini updated." -ForegroundColor Cyan

Write-Host "`n=== セットアップ完了! ===" -ForegroundColor Green
Write-Host "Eclipse を eclipse/eclipse.exe から起動してください。" -ForegroundColor White
Write-Host "`n次に: install-plugins.bat を実行してプラグインをインストールしてください。" -ForegroundColor Yellow

