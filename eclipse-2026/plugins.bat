@echo off
echo ============================================
echo Eclipse プラグイン インストール (Shift-JIS版)
echo ============================================
echo.

REM 実行ポリシーの事前確認
REM グループポリシーで実行ポリシーが決められていると -ExecutionPolicy Bypass は無視される
set "EFFECTIVE_POLICY="
for /f "usebackq delims=" %%P in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ExecutionPolicy"`) do set "EFFECTIVE_POLICY=%%P"
if /i "%EFFECTIVE_POLICY%"=="Restricted" goto :policy_blocked
if /i "%EFFECTIVE_POLICY%"=="AllSigned" goto :policy_blocked

echo このスクリプトは eclipse.ini を一時的に修正して
echo プラグインをインストールします。
echo.
echo 【重要】このスクリプトを実行する前に:
echo.
echo  1. Eclipse を一度起動してください
echo  2. ワークスペースを選択してください
echo  3. Eclipse を終了してください
echo.
echo 上記の手順を完了していない場合、
echo プラグインのインストールに失敗します。
echo.
echo ============================================
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%~dp0plugins.ps1'"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0plugins.ps1"
REM 成功時は plugins.ps1 が起動したクリーンアップがこのファイルを削除するので、すぐに終了する
if not errorlevel 1 exit /b 0

echo.
echo [エラー] プラグインのインストール処理が異常終了しました
echo 上に表示されたエラーメッセージを確認してください。
echo.
pause
exit /b 1

:policy_blocked
echo [エラー] PowerShell スクリプトを実行できません
echo.
echo グループポリシーで実行ポリシーが "%EFFECTIVE_POLICY%" に設定されているため、
echo plugins.ps1 を実行できません。-ExecutionPolicy Bypass も無視されます。
echo.
echo 対処法:
echo  - 会社や学校の PC の場合は、PC の管理者に相談してください
echo  - 個人の PC の場合は、グループポリシーの
echo    「スクリプトの実行を有効にする」の設定を確認してください
echo.
pause
exit /b 1
