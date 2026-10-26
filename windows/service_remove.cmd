@ECHO OFF
CALL "%~dp0_require_admin.cmd" || EXIT /B 1
echo Hizmeti kaldirmak icin:
echo Bu batch dosyasini yonetici olarak calistirmaniz gerekmektedir.
echo Sag Tik - Yonetici Olarak Calistir.
echo Eger yonetici olarak calistirdiysaniz herhangi bir tusa basin.
pause
sc stop "GoodbyeDPI" >nul 2>&1
sc delete "GoodbyeDPI" >nul 2>&1
sc stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1
