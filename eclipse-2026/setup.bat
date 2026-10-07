@echo off
echo ============================================
echo Eclipse セットアップ (Shift-JIS版)
echo ============================================
echo.

REM 実行ポリシーの事前確認
REM グループポリシーで実行ポリシーが決められていると -ExecutionPolicy Bypass は無視される
set "EFFECTIVE_POLICY="
for /f "usebackq delims=" %%P in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ExecutionPolicy"`) do set "EFFECTIVE_POLICY=%%P"
if /i "%EFFECTIVE_POLICY%"=="Restricted" goto :policy_blocked
if /i "%EFFECTIVE_POLICY%"=="AllSigned" goto :policy_blocked

echo このスクリプトは以下を実行します:
echo - Eclipse 2026-09 のインストール
echo - JDK 25 のセットアップ
echo - Pleiades による日本語化
echo - PlemolJP HS フォントのインストール (SPD 表示用)
echo - プラグインインストールガイドの作成
echo.
echo プラグインは、Eclipse起動後に別途インストールが必要です。
echo.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%~dp0setup.ps1'"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 goto :setup_failed

echo.
echo ============================================
echo セットアップ完了
echo ============================================
echo.
echo 次の手順:
echo 1. eclipse\eclipse.exe を起動
echo 2. Eclipse を一度終了
echo 3. plugins.bat を実行
echo.
pause
exit /b 0

:setup_failed
echo.
echo ============================================
echo [エラー] セットアップに失敗しました
echo ============================================
echo 上に表示されたエラーメッセージを確認してください。
echo ダウンロードに失敗した場合は、ネットワークを確認してから
echo もう一度 setup.bat を実行してください。
echo.
pause
exit /b 1

:policy_blocked
echo [エラー] PowerShell スクリプトを実行できません
echo.
echo グループポリシーで実行ポリシーが "%EFFECTIVE_POLICY%" に設定されているため、
echo setup.ps1 を実行できません。-ExecutionPolicy Bypass も無視されます。
echo.
echo 対処法:
echo  - 会社や学校の PC の場合は、PC の管理者に相談してください
echo  - 個人の PC の場合は、グループポリシーの
echo    「スクリプトの実行を有効にする」の設定を確認してください
echo.
pause
exit /b 1
