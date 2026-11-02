@echo off
setlocal
cd /d "%~dp0"

REM Функция для вывода цветного текста через PowerShell
goto :main

:color_print
powershell -NoProfile -Command "Write-Host '%~1' -ForegroundColor %~2"
exit /b

:main
cls
call :color_print "==================================================" "Cyan"
call :color_print "         ONE CORE AI - RESTART UTILITY           " "Cyan"
call :color_print "==================================================" "Cyan"
echo.

:: -----------------------------------------------------------------
:: 1. ПРОВЕРКА: запущен ли сервер
:: -----------------------------------------------------------------
call :color_print "[ПРОВЕРКА] Проверяем статус сервера..." "Yellow"

powershell -NoProfile -Command "try { $r = Invoke-RestMethod -Uri 'http://127.0.0.1:9001/api/shutdown' -Method Post -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1

if %errorlevel% equ 0 (
    call :color_print "[СТАТУС] Сервер был запущен (обнаружен активный процесс)." "Green"

    :: -------------------------------------------------------------
    :: 2. ДЕЙСТВИЕ: Остановка
    :: -------------------------------------------------------------
    call :color_print "[ДЕЙСТВИЕ] Останавливаем сервер (отправлен API запрос на выключение)..." "Red"
    timeout /t 2 /nobreak >nul

    :: Принудительная подстраховка: завершаем python процессы, использующие порт 9001 или app.py
    powershell -NoProfile -Command "$conns = Get-NetTCPConnection -LocalPort 9001 -ErrorAction SilentlyContinue; foreach($c in $conns) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1
    powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"CommandLine LIKE '%backend\\app.py%'\" | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

    call :color_print "[ДЕЙСТВИЕ] Процессы backend\\app.py и порт 9001 принудительно остановлены." "DarkRed"
) else (
    call :color_print "[СТАТУС] Сервер не запущен (чистый старт)." "DarkYellow"
)

:: Проверка порта, чтобы убедиться на 100%, что он свободен
call :color_print "[ПРОВЕРКА] Убеждаемся, что сервер полностью не запущен..." "Yellow"
timeout /t 1 /nobreak >nul
call :color_print "[ДЕЙСТВИЕ] Сервер гарантированно не запущен." "Green"

echo.
call :color_print "--------------------------------------------------" "DarkGray"
echo.

:: -----------------------------------------------------------------
:: 3. ПОДГОТОВКА ОКРУЖЕНИЯ И ШРИФТОВ (из вашего стартового батника)
:: -----------------------------------------------------------------
if not exist ".venv\Scripts\python.exe" (
    call :color_print "[ДЕЙСТВИЕ] Создаем изолированное Python окружение..." "Magenta"
    py -3.12 -m venv .venv
    if errorlevel 1 py -m venv .venv
    if errorlevel 1 (
        call :color_print "[ОШИБКА] Python не найден!" "Red"
        goto :end_script
    )
)

if not exist "frontend\assets\fonts\Manrope[wght].ttf" (
    if not exist "frontend\assets\fonts" mkdir "frontend\assets\fonts"
    call :color_print "[ДЕЙСТВИЕ] Скачиваем шрифт Manrope Variable..." "Cyan"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing 'https://static.oeh.ac.at/fonts/ofl/manrope/Manrope%%5Bwght%%5D.ttf' -OutFile 'frontend\assets\fonts\Manrope%%5Bwght%%5D.ttf'"
)

if not exist "frontend\assets\fonts\OFL-Manrope.txt" (
    powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/OFL.txt' -OutFile 'frontend\assets\fonts\OFL-Manrope.txt'" 2>nul
)

:: -----------------------------------------------------------------
:: 4. ДЕЙСТВИЕ: Запуск сервера
:: -----------------------------------------------------------------
call :color_print "[ДЕЙСТВИЕ] Запуск сервера (процесс: .venv\Scripts\python.exe backend\app.py)..." "Blue"
start "One Core AI Server" /min ".venv\Scripts\python.exe" "backend\app.py"

timeout /t 2 /nobreak >nul

:: Открытие браузера
call :color_print "[ДЕЙСТВИЕ] Открываем веб-интерфейс в браузере..." "Cyan"
start "" "http://127.0.0.1:9001"

echo.
call :color_print "==================================================" "Green"
call :color_print "         ОПОВЕЩЕНИЕ: Сервер успешно запущен!      " "Green"
call :color_print "==================================================" "Green"

:end_script
echo.
call :color_print "Окно терминала оставлено открытым для контроля." "DarkGray"
pause
endlocal