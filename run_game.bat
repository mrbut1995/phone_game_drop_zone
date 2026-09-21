@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Drop Zone Game Launcher (Godot 4)
echo ===================================================

set GODOT_BIN_DIR=D:\Godots\app dev\Godot Source Code\godot\bin

set GODOT_EXE=
for %%F in ("%GODOT_BIN_DIR%\*.exe") do (
    set "GODOT_EXE=%%F"
    goto :found_exe
)

:found_exe
if "%GODOT_EXE%"=="" (
    echo [ERROR] Khong tim thay file .exe cua Godot trong:
    echo "%GODOT_BIN_DIR%"
    pause
    exit /b 1
)

echo [INFO] Su dung Godot Binary: "%GODOT_EXE%"
echo [INFO] Dang khoi chay game tu project directory...
echo.

"%GODOT_EXE%" --path "%~dp0." res://scenes/game.tscn

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [NOTE] Chuong trinh ket thuc voi ma loi: %ERRORLEVEL%
    pause
)
