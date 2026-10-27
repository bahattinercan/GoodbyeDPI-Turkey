# README (Windows bölümleri) ↔ `windows/` dizini denetim raporu — 2026-10-27

**Durum:** Tamamlandı (salt okuma denetimi; hiçbir dosya değiştirilmedi).
**Kapsam:** `README.md` içindeki Windows bölümleri — hizmet kurma (97–108), batch
kullanımı (110–120), **Güvenlik notları (Windows)** (121–128), **DNS ve Port'u
Düzenleme** (181–183), **SuperOnline Alternatif Yöntemler** (191–210) — ile
`windows/` dizininin karşılaştırılması. Ek olarak `Sık Karşılaşılan Sorunlar`
(166–179) satırlarında `.cmd` davranışına dokunan iddialar da denetlendi.

## Ortam ve yöntem

Bu makine Linux/x86_64 (`uname -s` → `Linux`, `uname -m` → `x86_64`). `.cmd`
dosyaları **çalıştırılmadı** (Windows gerekir); denetim `ls` / `cat -n` / `grep`
ile yapıldı. Sonuç etiketleri: **DOGRU / YANLIS / EKSIK / DOGRULANMADI**.
`DOGRULANMADI` = bu kapılarda (Linux + statik) kanıtlanamıyor, tahmin yazılmadı.

Çalıştırılan komutlar ve çıkış kodları:

| # | Komut | Çıkış | Çıktı |
|---|---|---|---|
| 1 | `ls windows/*.cmd \| wc -l` | 0 | **16** |
| 2 | `git ls-files windows` | 0 | 17 kayıt (16 `.cmd` + `README-BEN OKU.txt`) |
| 3 | `grep -c "15 \.cmd" README.md` | 1 | 0 eşleşme |
| 4 | `grep -n "_require_admin\|BEN OKU" README.md` | 1 | 0 eşleşme |
| 5 | `grep -rl -- "--dns-addr 77.88.8.8" windows/*.cmd \| wc -l` | 0 | 8 |
| 6 | `for f in windows/*.cmd; do grep -c '77\.88\.8\.8' "$f"; done` | 0 | 8 dosyada 1, 8 dosyada 0 |
| 7 | `grep -rin "sha256sum\|certutil" windows/*.cmd` | 1 | 0 eşleşme |
| 8 | `grep -rn "icacls" windows/*.cmd` | 1 | 0 eşleşme (tek kaynak `README-BEN OKU.txt:18`) |
| 9 | `grep -l "_require_admin" windows/*.cmd \| wc -l` | 0 | 8 |
| 10 | `grep -c "_require_admin" windows/turkey_dnsredir*.cmd` | 0 | 7 dosyanın hepsinde 0 |
| 11 | `grep -rn "0.2.3rc3" .github/` | 1 | 0 eşleşme |
| 12 | `file -b windows/*.cmd` (her dosya) | 0 | 16 dosya: CRLF, ASCII |
| 13 | `cat -n windows/*.cmd` / `cat -n README.md` | 0 | satır numaralı inceleme |

## 1) `.cmd` dosya sayısı

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| "`windows/` içinde **15** `.cmd` launchers … plus `README-BEN OKU.txt`" | `AGENTS.md:17`; gerçek: `ls windows/*.cmd \| wc -l` → **16**, `git ls-files windows` → 17 kayıt | **YANLIS** — gerçek sayı 16. 15, `_require_admin.cmd` hariç launcher sayısı; bu istisna `AGENTS.md:17`'de yazmıyor |
| README.md'de `.cmd` sayısına dair bir iddia var mı | `grep -c "15 \.cmd" README.md` → 0 eşleşme (exit 1) | **DOGRULANMADI** — README'de sayı iddiası yok; iddia yalnızca `AGENTS.md:17`de |

## 2) README'de adı geçen betikler gerçekten var mı

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `service_install_dnsredir_turkey.cmd` var (README:103, 108) | `windows/service_install_dnsredir_turkey.cmd:1-24` | **DOGRU** |
| `service_remove.cmd` var (README:108, 170, 173, 187, 198) | `windows/service_remove.cmd:1-11` | **DOGRU** |
| `turkey_dnsredir.cmd` var (README:116, 119, 183) | `windows/turkey_dnsredir.cmd:1-11` | **DOGRU** |
| `turkey_dnsredir_alternative1_superonline.cmd` var (README:200 "(1/2/3/4/5/6)") | Dizinde böyle dosya yok; Metod 1 numarasız: `windows/turkey_dnsredir_alternative_superonline.cmd:8` | **YANLIS** — `alternative1` adlı dosya yok, isimlendirme numarasız |
| `turkey_dnsredir_alternative{2,3,4,5,6}_superonline.cmd` var (README:200) | `windows/turkey_dnsredir_alternative2_superonline.cmd:8`, `..._3:8`, `..._4:8`, `..._5:8`, `..._6:8` | **DOGRU** |
| `service_install_dnsredir_turkey_alternative1_superonline.cmd` var (README:201) | Böyle dosya yok; numarasız: `windows/service_install_dnsredir_turkey_alternative_superonline.cmd:21` | **YANLIS** |
| `service_install_dnsredir_turkey_alternative{2,3,4,5,6}_superonline.cmd` var (README:201, 173) | `windows/service_install_dnsredir_turkey_alternative2_superonline.cmd:21`, `..._3:19`, `..._4:19`, `..._5:19`, `..._6:19` | **DOGRU** |
| README:173 betik adlarını `.cmd` uzantısız veriyor (`service_install_dnsredir_turkey_alternative2_superonline`) | Dosya uzantılı mevcut: `windows/service_install_dnsredir_turkey_alternative2_superonline.cmd:1` | **DOGRU** (dosya var; eksik uzantı üslup) |

## 3) `_require_admin.cmd` ve `README-BEN OKU.txt` README'de geçiyor mu

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `_require_admin.cmd` README'de hiç geçmiyor | `grep -n "_require_admin" README.md` → 0 eşleşme (exit 1); dosya mevcut ve davranışı tanımlı: `windows/_require_admin.cmd:2-8` | **EKSIK** — admin kapısı README'de anlatılmıyor |
| `README-BEN OKU.txt` README'de hiç geçmiyor | `grep -n "BEN OKU" README.md` → 0 eşleşme (exit 1); dosya mevcut: `windows/README-BEN OKU.txt:14-22` | **EKSIK** — ZIP içindeki ikinci kullanıcı belgesine README'de bağlantı yok |

## 4) "Ön ayarların 5'i Yandex DNS'e yönlendirir"

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| README:126 "Ön ayarların **5'i** varsayılan olarak Yandex DNS'e (77.88.8.8/77.88.8.1) yönlendirir" | `grep -rl -- "--dns-addr 77.88.8.8" windows/*.cmd \| wc -l` → **8 dosya**: `service_install_dnsredir_turkey.cmd:20`, `..._alternative3_superonline.cmd:19`, `..._alternative4_superonline.cmd:19`, `..._alternative5_superonline.cmd:19`, `turkey_dnsredir.cmd:8`, `turkey_dnsredir_alternative3_superonline.cmd:8`, `..._4:8`, `..._5:8` → **7 ön ayarın 4'ü** (base, alt3, alt4, alt5); DNS'siz: `..._alternative_superonline.cmd:21`, `..._alternative2_superonline.cmd:21`, `..._alternative6_superonline.cmd:19` | **YANLIS** — doğru sayı 4/7 ön ayar (16 `.cmd`den 8'i) |
| `windows/README-BEN OKU.txt:20` "Bu forktaki **7 ön ayarın 5'i**" | Aynı 8 dosya (yukarıdaki satırlar); DNS'siz 3 ön ayar aynı kanıtlarla doğrulanıyor | **YANLIS** — 7 ön ayarın 4'ü DNS önyüklüyor |
| "…`--dns-addr 77.88.8.8 --dns-port 1253` kısmını (ve varsa IPv6 karşılığını) silin" (README:126) | Metin betiklerde birebir: `windows/service_install_dnsredir_turkey.cmd:20`, `windows/turkey_dnsredir.cmd:8`; bayraklar kaynakta tanımlı: `src/goodbyedpi.c:184-186`, `src/goodbyedpi.c:999-1001` | **DOGRU** |
| "alt 3, 4, 5'te önyarlı Yandex DNS var; 1, 2, 6'da yok" (README:183) | Var: `..._3_superonline.cmd:19`, `..._4:19`, `..._5:19` (+ launcher `:8`); yok: `..._superonline.cmd:21`, `..._2:21`, `..._6:19` (+ launcher `:8`) | **DOGRU** |
| "Bu forktaki komut dosyalarında varsayılan olarak **Yandex DNS kullanılmaktadır**" (README:183) | 16 `.cmd`den yalnız 8'inde `--dns-addr` var (satır listesi yukarıda); 8'inde hiç yok | **EKSIK** — genelleme yanıltıcı, yarısında DNS önyoklemesi yok |
| "DNS/port'u `turkey_dnsredir.cmd` ve `service_install_dnsredir_turkey.cmd` dosyalarını düzenleyerek değiştirin" (README:183) | Sabit DNS içeren 6 dosya daha var: `turkey_dnsredir_alternative3_superonline.cmd:8`, `..._4:8`, `..._5:8`, `service_install_dnsredir_turkey_alternative3_superonline.cmd:19`, `..._4:19`, `..._5:19` | **EKSIK** — düzenlenmesi gereken dosyaların yarısı eksik listelenmiş |

## 5) `icacls` örneği ve `certutil -hashfile … SHA256` önerisi

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| README:124'teki `icacls "C:\Program Files\GoodbyeDPI" /inheritance:r …` komutu `windows/` kaynağından geliyor | Birebir aynı metin: `windows/README-BEN OKU.txt:18` (komut satırı: `windows/README-BEN OKU.txt:18`) | **DOGRU** — kaynaksız değil |
| İzin sıkılaştırma adımı betikler tarafından yapılıyor/öneri betikte geçiyor | `grep -rn "icacls" windows/*.cmd` → 0 eşleşme (exit 1) | **EKSIK** — yalnız elle çalıştırılan bir adım, hiçbir `.cmd` içinde yok |
| README:127 "`certutil -hashfile goodbyedpi.exe SHA256` çıktısını … karşılaştırın" | Aynı öneri `windows/` içinde: `windows/README-BEN OKU.txt:21` | **DOGRU** |
| README:127 "…veya **`SHA256SUMS` dosyasındaki** değerle karşılaştırın" | `windows/` altında SHA256SUMS üreten hiçbir adım yok: `grep -rin "sha256sum\|certutil" windows/*.cmd` → 0 eşleşme (exit 1). Tek üreten yer CI: `.github/workflows/build.yml:82` ve `.github/workflows/build.yml:102`; yalnız `actions/upload-artifact`e konuyor, 14 gün: `build.yml:89`, `build.yml:109` | **EKSIK** — önerinin kaynağı CI artefatı; `windows/` dizininde karşılığı yok |
| Yayınlanan sürümde (sürüm notu / release asset) SHA256SUMS mevcut mu | Depoda release asset üreten iş yok: `grep -rn "0.2.3rc3" .github/` → 0 eşleşme (exit 1); `build.yml` yalnız workflow artefatı üretiyor (`build.yml:87`, `build.yml:107`) | **DOGRULANMADI** — Kapı B/C (GitHub Releases) gerektirir |
| README:128 "Antivirüs: klasörü istisnaya ekleyin + hash doğrulayın" | `windows/README-BEN OKU.txt:22` | **DOGRU** |
| README:123 "hizmet **LocalSystem** hesabıyla çalıştığı için … SYSTEM yetkisi elde eder" | `sc create` satırlarında `obj=` parametresi yok → Windows varsayılanı LocalSystem: `windows/service_install_dnsredir_turkey.cmd:20`; beyan metni: `windows/service_install_dnsredir_turkey.cmd:5` | **DOGRU** (repo içi beyan + parametre yokluğu; fiilî davranış Kapı C) |
| README:125 "`WinDivert.dll` ve `WinDivert64.sys` **aynı klasörden** yüklendiği için klasör yazılabilir olmamalıdır" | Betikler exe'yi alt klasörde arıyor: `windows/turkey_dnsredir.cmd:3-6` (`PUSHD "%_arch%"`), `windows/service_install_dnsredir_turkey.cmd:8-10,20`; CI exe+dll+sys'i düz dizine koyuyor: `.github/workflows/build.yml:77`, `build.yml:99` | **DOGRULANMADI** — yayın ZIP'inin klasör düzeni depoda yok; "aynı klasör" ifadesi alt klasör yapısıyla tam örtüşmüyor |

## 6) "Yönetici Olarak Çalıştırmanız mecburidir" ↔ `_require_admin.cmd`

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| README:73 yönetici zorunluluğu ile `_require_admin.cmd` davranışı tutarlı | `windows/_require_admin.cmd:2-8` (`net session` → uyarı → `pause` → `exit /b 1`); 8 betikte çağrı: `service_install_dnsredir_turkey.cmd:3`, 6 alternatif `:3`, `service_remove.cmd:2` (`grep -l … \| wc -l` → 8) | **DOGRU** |
| Aynı zorunluluk batch (one-shot) betiklerinde de denetleniyor (README:116 "yönetici olarak çalıştırın") | `grep -c "_require_admin" windows/turkey_dnsredir*.cmd` → 7 dosyanın hepsinde 0; ör. `windows/turkey_dnsredir.cmd:1-8` | **EKSIK** — 7 one-shot betikte admin kapısı yok, denetimsiz çalışıyor |
| README:123 "ZIP'i yönetici-yazılabilir klasöre çıkarın" uyarısı betikte duruma bağlı veriliyor | Uyarı koşulsuz basılıyor: `windows/service_install_dnsredir_turkey.cmd:4-7` ("Bu klasor kullanici tarafindan yazilabilir bir konumdadir") — konum tespiti yok | **EKSIK** — sabit metin, doğru konumda kurulsa bile uyarı veriyor |
| README:104 "Açılan konsol penceresinde herhangi bir tuşuna basın" | `pause`: `windows/service_install_dnsredir_turkey.cmd:17`; alternatiflerde `:16`/`:18` | **DOGRU** |
| README:105 "Pencere, hizmet kurulduğunda otomatik olarak kapanacak ve hizmet de otomatik olarak başlayacaktır" | `sc start "GoodbyeDPI"`: `windows/service_install_dnsredir_turkey.cmd:22`; betik sonunda `pause` yok, yalnız `POPD`: `:24` | **DOGRU** |
| README:91 "bilgisayarınız her yeniden başlatıldığında otomatik olarak çalışır" | `start= "auto"`: `windows/service_install_dnsredir_turkey.cmd:20` (7 servis betiğinde aynı) | **DOGRU** |
| README:95 "hizmet `.cmd` dosyasını çalıştırdığınız dosya yolunu kullanacağından taşırsanız çalışmaz" | `PUSHD "%~dp0"`: `windows/service_install_dnsredir_turkey.cmd:2` + `binPath= "\"%CD%\%_arch%\goodbyedpi.exe\""`: `:20` | **DOGRU** |

## 7) README'de anlatılıp `windows/` karşılığı olmayan / tersi durumlar

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| README:112 "Bir komut penceresi açılır … **bu pencere kapatıldığında** çalışmaya son verilir" (ve README:119) | `start "" goodbyedpi.exe …` yeni bir konsol açar, launcher betiği hemen biter: `windows/turkey_dnsredir.cmd:8,10-11` (7 one-shot betikte aynı desen) | **YANLIS** — iki pencere var; kapatılması gereken `goodbyedpi.exe` konsoludur, `.cmd` penceresi değil |
| README:187 `service_remove.cmd` yalnız dosya silmeyi kolaylaştırıyor | Betik `WinDivert` servisini de durdurup siliyor: `windows/service_remove.cmd:10-11` (GoodbyeDPI için `:8-9`) — README'de bu anlatılmıyor | **EKSIK** |
| `x86/` ve `x86_64/` alt klasör bağımlılığı README'de anlatılıyor mu | Betikler mimariye göre alt klasöre giriyor: `windows/turkey_dnsredir.cmd:3-6`, `windows/service_install_dnsredir_turkey.cmd:8-10,20` — README'de hiç geçmiyor | **EKSIK** |
| Yayın ZIP'i bu alt klasör düzenini içeriyor mu | CI sahnelemesi düz düzen üretiyor: `.github/workflows/build.yml:77`, `build.yml:99`; ZIP depoda yok | **DOGRULANMADI** |
| README:101/114 `goodbyedpi-0.2.3rc3-turkey.zip` varlığı | Depoda/CI'da bu adda üretim yok (`grep -rn "0.2.3rc3" .github/` → 0 eşleşme, exit 1); CI artefat adları `goodbyedpi_x86_64_<sha>` / `goodbyedpi_x86_<sha>`: `build.yml:87`, `build.yml:107` | **DOGRULANMADI** — ZIP yalnız GitHub Releases'ta, bu depoda kanıtı yok |
| Dosya adlandırması README:200-201 ile betiğin kendi etiketi tutarlı | `service_install_dnsredir_turkey_alternative5_superonline.cmd:12` başlıkta "(Alternatif Metod 4)" diyor ama tanım `:20` "Metod 5"; `..._alternative6_superonline.cmd:12` aynı hata, `:20` "Metod 6" | **YANLIS** — betiğin ekran etiketi hatalı (README'nin dosya adları doğru) |
| Metod 1 ve 2 betikleri kendini doğru numaralandırıyor | `..._alternative_superonline.cmd:12,22` ve `..._alternative2_superonline.cmd:12` "(Alternatif Metod)" numarasız, oysa tanım `:22` "Metod 2"; README "alternatif metod 1/2" diyor (README:183) | **EKSIK** |
| DNS'siz ön ayarlarda betik, Windows DNS ayarı için kullanıcıyı uyarıyor (README:183, 201) | alt1 ve alt2 uyarıyor: `service_install_dnsredir_turkey_alternative_superonline.cmd:16-17`, `..._alternative2_superonline.cmd:16-17`; alt6'da uyarı yok: `..._alternative6_superonline.cmd:12-15` ve DNS yok `:19` | **EKSIK** — Metod 6'da DNS hatırlatması eksik |
| README:173 "TTL ayarı **içermeyen** 2 ve 4 numaralı alternatif metodları kullanın" | `-5` ön ayarı `--auto-ttl` içeriyor: `src/goodbyedpi.c:1053`; alt2 = `-5`: `..._alternative2_superonline.cmd:21`, alt4 = `-5 --dns-addr …`: `..._alternative4_superonline.cmd:19` → 2 ve 4'te TTL mekanizması **var**. `-9`'da TTL yok: `src/goodbyedpi.c:1057`; alt5/alt6 = `-9`: `..._alternative5_superonline.cmd:19`, `..._alternative6_superonline.cmd:19` → TTL'siz olanlar 5 ve 6 | **YANLIS** — iddia tam tersi; TTL'siz alternatifler 5 ve 6 |
| README:196-201 "SuperOnline alternatif yöntemler" 12 betikle karşılanıyor | 6 launcher + 6 servis betiği mevcut: `turkey_dnsredir_alternative{,_2.._6}_superonline.cmd`, `service_install_dnsredir_turkey_alternative{,_2.._6}_superonline.cmd` (`git ls-files windows`) | **DOGRU** |
| README güvenlik notları ile ZIP içi belge tutarlı | README:123-128 ↔ `windows/README-BEN OKU.txt:16-22` (6 madde birebir; tek ortak hata DNS sayısı → bkz. 4.1/4.2) | **DOGRU** (karşılıklı tutarlılık; içerik hatası ayrı satırlarda) |

## Sonuç dağılımı

| Sonuç | Satır sayısı |
|---|---|
| DOGRU | 19 |
| YANLIS | 8 |
| EKSIK | 12 |
| DOGRULANMADI | 5 |
| **Toplam** | **44** |

Gerçek `.cmd` sayısı: **16** (`ls windows/*.cmd | wc -l`, exit 0).

## Öneriler (düzeltme yapılmadı — task kuralı: "Düzeltme gerekiyorsa YAPMA, rapora yaz")

1. `README.md:126` ve `windows/README-BEN OKU.txt:20`: "5'i" → "4'ü" (7 ön ayarın; 16 betiğin 8'i).
2. `README.md:200-201`: `alternative1` diye bir dosya yok; ya betikler `..._alternative1_...` olarak
   yeniden adlandırılır (kullanıcı README'den kopyalıyor — `AGENTS.md` "Do not touch: renaming script
   files") ya da README "(1/…)" kalıbı "numarasız = Metod 1" şeklinde açıklanır.
3. `README.md:183`: DNS önyoklemesi olan 6 betik daha listelenmeli; "varsayılan olarak Yandex DNS"
   cümlesi 8 betik için geçerli olacak şekilde daraltılmalı.
4. `README.md:127`: SHA256 doğrulama önerisi CI artefatına (`.github/workflows/build.yml:82,102`)
   dayanıyor; release asset'inde SHA256SUMS yoksa "sürüm notundaki değer" ifadesi kaldırılmalı.
5. `README.md:173`: TTL'siz yöntemler 5 ve 6 (`-9`, `src/goodbyedpi.c:1057`); 2 ve 4 `-5` içindeki
   `--auto-ttl` nedeniyle TTL kullanıyor (`src/goodbyedpi.c:1053`).
6. `windows/service_install_dnsredir_turkey_alternative5/6_superonline.cmd:12`: ekran başlığı
   "(Alternatif Metod 4)" → 5 ve 6 olarak düzeltilmeli.
7. `windows/service_install_dnsredir_turkey_alternative6_superonline.cmd`: DNS hatırlatma `echo`'su
   eklenmeli (alt1/alt2'deki `:16-17` emsali).
8. One-shot `turkey_dnsredir*.cmd` betikleri `windows/_require_admin.cmd`'i çağırmıyor; README:73
   "mecburidir" iddiası ya betiklerde uygulanmalı ya da README "hizmet betiklerinde denetlenir"
   şeklinde netleştirilmeli.
9. `README.md`: `_require_admin.cmd` ve `README-BEN OKU.txt` dosyalarından söz edilmeli; `x86/` ve
   `x86_64/` alt klasör bağımlılığı anlatılmalı; batch yönteminde açılan ikinci pencere
   (`start ""`, `windows/turkey_dnsredir.cmd:8`) açıklanmalı.
10. `AGENTS.md:17`: "15 `.cmd`" → "16 `.cmd` (15 launcher + `_require_admin.cmd` yardımcı betiği)".

## Doğrulanamayanlar (Kapı B/C bekliyor)

- Yayın ZIP'inin (`goodbyedpi-0.2.3rc3-turkey.zip`) iç düzeni, `x86/`+`x86_64/` alt klasörleri ve
  `SHA256SUMS` içerip içermediği.
- `sc create` sonrası servisin fiilen LocalSystem çalıştırması, `icacls` çıktısı, WinDivert sürücüsünün
  yüklenmesi ve gerçek DPI atlatma davranışı (yalnız gerçek Windows makinesinde, Kapı C).
- Bu denetimde hiçbir `.cmd` çalıştırılmadı; `bash -n` / `shellcheck` `.cmd` için uygulanabilir değil.
