@ECHO OFF
PUSHD "%~dp0"
CALL "%~dp0_require_admin.cmd" || (POPD & EXIT /B 1)
echo UYARI: Bu klasor kullanici tarafindan yazilabilir bir konumdadir.
echo Hizmet LocalSystem hesabiyla calisir, bu yuzden klasordeki dosyalari
echo yetkisiz kisiler degistirebilir. ZIP arsivini yalnizca yoneticinin
echo yazabildigi bir klasore cikarin (or. C:\Program Files\GoodbyeDPI).
set _arch=x86
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set _arch=x86_64)
IF DEFINED PROCESSOR_ARCHITEW6432 (set _arch=x86_64)

echo DNS zorlamasini kaldiracak hizmeti yuklemek icin:
echo Bu batch dosyasini yonetici olarak calistirmaniz gerekmektedir.
echo Sag Tik - Yonetici Olarak Calistir.
echo Eger yonetici olarak calistirdiysaniz herhangi bir tusa basin.
echo Bu metodu kullaniyorsaniz ayrica Windows ayarlarindan DNS degistirmenize gerek yoktur.
pause
sc stop "GoodbyeDPI"
sc delete "GoodbyeDPI"
sc create "GoodbyeDPI" binPath= "\"%CD%\%_arch%\goodbyedpi.exe\" -5 --set-ttl 5 --dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253" start= "auto"
sc description "GoodbyeDPI" "Turkiye icin DNS zorlamasini kaldirir."
sc start "GoodbyeDPI"

POPD
