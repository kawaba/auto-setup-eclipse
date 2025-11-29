$ErrorActionPreference = "Stop"

# スクリプトがあるディレクトリ(プロジェクトフォルダ)
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# eclipseフォルダのパス
$EclipseDir = "$BaseDir\eclipse"
$LogFile = "$BaseDir\plugin-install.log"
$IniPath = "$EclipseDir\eclipse.ini"
$IniBackupPath = "$EclipseDir\eclipse.ini.backup"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Eclipse プラグイン インストールスクリプト" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$eclipseExe = "$EclipseDir\eclipse.exe"
if (!(Test-Path $eclipseExe)) {
    Write-Host "エラー: eclipse.exe が見つかりません" -ForegroundColor Red
    Write-Host "パス: $eclipseExe" -ForegroundColor Gray
    pause
    exit 1
}

if (!(Test-Path $IniPath)) {
    Write-Host "エラー: eclipse.ini が見つかりません" -ForegroundColor Red
    Write-Host "パス: $IniPath" -ForegroundColor Gray
    pause
    exit 1
}

Write-Host "重要: Eclipseを一度起動して終了しましたか?" -ForegroundColor Yellow
Write-Host "(初回起動で設定ファイルが作成されます)" -ForegroundColor Gray
Write-Host ""
$response = Read-Host "はい [Y] / いいえ [N]"
if ($response -notmatch "^[Yy]") {
    Write-Host ""
    Write-Host "まず、Eclipseを起動して終了してから、このスクリプトを実行してください。" -ForegroundColor Yellow
    pause
    exit 0
}

Write-Host ""
Write-Host "プラグインのインストールを開始します..." -ForegroundColor Cyan
Write-Host ""

# eclipse.ini の一時的な修正
Write-Host "eclipse.ini をバックアップして一時的に修正します..." -ForegroundColor Yellow
Copy-Item $IniPath $IniBackupPath -Force
$Ini = Get-Content $IniPath
$IniModified = $Ini | ForEach-Object {
    if ($_ -match "^-Xverify:none") { "# TEMP_DISABLED: $_" }
    elseif ($_ -match "^-javaagent:.*pleiades") { "# TEMP_DISABLED: $_" }
    else { $_ }
}
$IniModified | Set-Content $IniPath -Encoding Default
Write-Host "eclipse.ini を一時的に修正しました" -ForegroundColor Green
Write-Host ""

function InstallPlugin($name, $iu, $repo) {
    Write-Host "--------------------------------------------" -ForegroundColor Gray
    Write-Host "インストール中: $name" -ForegroundColor Yellow
    "インストール中: $name ($(Get-Date))" | Out-File -Append $LogFile -Encoding Default
    
    $process = Start-Process -FilePath $eclipseExe -ArgumentList @(
        "-application", "org.eclipse.equinox.p2.director",
        "-nosplash", 
        "-repository", $repo, 
        "-installIU", $iu
    ) -Wait -PassThru -WindowStyle Hidden
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] 成功: $name" -ForegroundColor Green
        "成功: $name" | Out-File -Append $LogFile -Encoding Default
        Write-Host ""
        return $true
    } else {
        Write-Host "[NG] 失敗: $name (Exit Code: $($process.ExitCode))" -ForegroundColor Red
        "失敗: $name (Exit Code: $($process.ExitCode))" | Out-File -Append $LogFile -Encoding Default
        Write-Host ""
        return $false
    }
}

$plugins = @(
    # Web開発ツール - 基本
    @{ Name = "Eclipse Web Tools"; IU = "org.eclipse.wst.web_ui.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    @{ Name = "Eclipse XML Editor"; IU = "org.eclipse.wst.xml_ui.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    @{ Name = "Eclipse JSON Editor"; IU = "org.eclipse.wst.json_ui.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    
    # Wild Web Developer
    @{ Name = "Wild Web Developer"; IU = "org.eclipse.wildwebdeveloper.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    @{ Name = "Wild Web Developer Node.js Embedded"; IU = "org.eclipse.wildwebdeveloper.embedder.node.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    
    # WST Server Tools
    @{ Name = "WST Server Adapters"; IU = "org.eclipse.wst.server_adapters.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },
    @{ Name = "WST Server UI"; IU = "org.eclipse.wst.server_ui.feature.feature.group"; Repo = "https://download.eclipse.org/releases/2024-09" },

    # Spring Tools 4(Eclipse 2024-09 / 4.33専用リポジトリ)
    @{ Name = "Spring Tools 4 Main Feature"; IU = "org.springframework.boot.ide.main.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/4.32.2.RELEASE/e4.37/" },

#   @{ Name = "Spring Boot Language Server"; IU = "org.springframework.tooling.boot.ls.feature";               Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/e4.37/" },
#   @{ Name = "Spring Boot Language Server"; IU = "org.springframework.tooling.boot.ls.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/latest/"  },
#   @{ Name = "Spring Boot Language Server"; IU = "org.springframework.tooling.boot.ls.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/4.32.2.RELEASE/e4.37/" },
    @{ Name = "Spring Boot Language Server"; IU = "org.springframework.tooling.boot.ls.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/latest/,https://download.eclipse.org/releases/latest/" },

#   @{ Name = "Spring Boot Dashboard"; IU = "org.springframework.ide.eclipse.boot.dash.feature";               Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/e4.37/" },
#   @{ Name = "Spring Boot Dashboard"; IU = "org.springframework.ide.eclipse.boot.dash.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/latest/" },
#   @{ Name = "Spring Boot Dashboard"; IU = "org.springframework.ide.eclipse.boot.dash.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/4.32.2.RELEASE/e4.37/" },
    @{ Name = "Spring Boot Dashboard"; IU = "org.springframework.ide.eclipse.boot.dash.feature.feature.group"; Repo = "https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/latest/,https://download.eclipse.org/releases/latest/" },

    # GitHub Copilot
    @{ Name = "GitHub Copilot"; IU = "com.microsoft.copilot.eclipse.feature.feature.group"; Repo = "https://azuredownloads-g3ahgwb5b8bkbxhd.b01.azurefd.net/github-copilot/" },
    
    # Java 25 Support
    @{ Name = "Java 25 Support"; IU = "org.eclipse.jdt.javanextpatch.feature.group"; Repo = "https://download.eclipse.org/jdt/updates/4.37-P-builds/" }
)

$successCount = 0
$failCount = 0

foreach ($plugin in $plugins) {
    if (InstallPlugin $plugin.Name $plugin.IU $plugin.Repo) { $successCount++ }
    else { $failCount++ }
}

# eclipse.ini を元に戻す
Write-Host "--------------------------------------------" -ForegroundColor Gray
Write-Host "eclipse.ini を元に戻します..." -ForegroundColor Yellow
if (Test-Path $IniBackupPath) {
    Copy-Item $IniBackupPath $IniPath -Force
    Remove-Item $IniBackupPath -Force
    Write-Host "eclipse.ini を復元しました" -ForegroundColor Green
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "インストール完了" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "成功: $successCount 個" -ForegroundColor Green
Write-Host "失敗: $failCount 個" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "一部のプラグインのインストールに失敗しました。" -ForegroundColor Yellow
    Write-Host "詳細は plugin-install.log を確認してください。" -ForegroundColor Yellow

} else {
    Write-Host "すべてのプラグインが正常にインストールされました!" -ForegroundColor Green

    Write-Host ""

    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "クリーンアップ処理の準備" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    # EPFファイルをeclipseフォルダに移動
    $EpfFile = "$BaseDir\font-color-compiler-java25.epf"
    if (Test-Path $EpfFile) {
        Write-Host "font-color-compiler-java25.epf を eclipse フォルダに移動中..." -ForegroundColor Yellow
        Move-Item $EpfFile $EclipseDir -Force
        Write-Host "[OK] EPFファイルを移動しました" -ForegroundColor Green
    } else {
        Write-Host "[警告] font-color-compiler-java25.epf が見つかりません" -ForegroundColor Yellow
    }
    Write-Host ""

    # クリーンアップ用の一時バッチファイルを作成
    $CleanupBatPath = "$BaseDir\__cleanup__.bat"
    
    # バッチファイルの中身
    # 変更点: 待機時間を5秒にし、確実にPSが終了するのを待つ
    # 変更点: 最後の行で自分自身を確実に削除する構文に変更
    $CleanupBatContent = @"
@echo off
timeout /t 5 /nobreak >nul

rem ログファイルを削除
if exist "$BaseDir\plugin-install.log" del /f /q "$BaseDir\plugin-install.log" 2>nul

rem フォルダを削除 (Eclipse/Javaのロック解除待ちを含む)
if exist "$BaseDir\temp" rmdir /s /q "$BaseDir\temp" 2>nul
#if exist "$BaseDir\workspace" rmdir /s /q "$BaseDir\workspace" 2>nul

rem スクリプト類を削除
del /f /q "$BaseDir\*.ps1" 2>nul
del /f /q "$BaseDir\*.bat" 2>nul

rem バッチファイル自身を削除して終了
(goto) 2>nul & del "%~f0"
"@
    
    # Shift-JIS エンコーディングでバッチファイルを作成
    [System.IO.File]::WriteAllText($CleanupBatPath, $CleanupBatContent, [System.Text.Encoding]::GetEncoding(932))
    
    Write-Host "不要なファイルとフォルダを削除します。" -ForegroundColor Yellow
    Write-Host "何かキーを押すと、このウィンドウを閉じてクリーンアップを実行します" -ForegroundColor Cyan
    Write-Host "なお、削除に少し時間がかかる場合があります" -ForegroundColor Cyan    # ここでユーザー入力を待つ
    Write-Host "キーを押してそのままお待ちください" -ForegroundColor Cyan    # ここでユーザー入力を待つ
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # 別プロセスでクリーンアップバッチを実行
    Start-Process -FilePath $CleanupBatPath -WindowStyle Hidden
    
    # PowerShellを即座に終了させる（これでファイルのロックが外れる）
    exit
}
pause
