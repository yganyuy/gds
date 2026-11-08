@echo off
cd /d "%~dp0"
chcp 65001 >nul

echo ====================================================
echo [1/3] 正在编译 Windows...
echo ====================================================
python -m SCons
if %ERRORLEVEL% NEQ 0 goto error

echo.
echo ====================================================
echo [2/3] 正在编译 Android Debug...
echo ====================================================
python -m SCons platform=android arch=arm64 target=template_debug
if %ERRORLEVEL% NEQ 0 goto error

echo.
echo ====================================================
echo [3/3] 正在编译 Android Release...
echo ====================================================
python -m SCons platform=android arch=arm64 target=template_release
if %ERRORLEVEL% NEQ 0 goto error

echo.
echo ====================================================
echo 所有编译任务已完成！
echo ====================================================
pause
exit

:error
echo.
echo [错误] 编译失败，请检查上面的红色报错信息！
pause
exit