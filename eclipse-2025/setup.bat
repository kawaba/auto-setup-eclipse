@echo off
echo ============================================
echo Eclipse セットアップ (Shift-JIS版)
echo ============================================
echo.
echo このスクリプトは以下を実行します:
echo - Eclipse 2025-09 のインストール
echo - JDK 25 のセットアップ
echo - Pleiades による日本語化
echo - プラグインインストールガイドの作成
echo.
echo プラグインは、Eclipse起動後に別途インストールが必要です。
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
echo ============================================
echo セットアップ完了
echo ============================================
echo.
echo 次の手順:
echo 1. eclipse\eclipse.exe を起動
echo 2. Eclipse を一度終了
echo 3. install-plugins.bat を実行
echo.
pause
