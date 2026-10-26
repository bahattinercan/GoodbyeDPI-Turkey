@ECHO OFF
net session >nul 2>&1
IF ERRORLEVEL 1 (
    echo Bu dosyayi yonetici olarak calistirmalisiniz.
    echo Sag tik -^> Yonetici olarak calistir
    pause
    exit /b 1
)
exit /b 0
