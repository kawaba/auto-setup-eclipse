@echo off
echo ============================================
echo Eclipse プラグイン インストール (Shift-JIS版)
echo ============================================
echo.
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

powershell.exe -ExecutionPolicy Bypass -File "%~dp0plugins.ps1"
