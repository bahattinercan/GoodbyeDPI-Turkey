# README.md Denetimi (2026-10-27)

**Kapsam:** `README.md` (233 satır) + onu besleyen dosyalar: `linux/`, `macos/`,
`windows/`, `src/`, `.github/workflows/`, `docs/plans/`, `REVERT.md`, `LICENSE`.
**Tür:** Salt okuma denetimi. Bu dosya dışında hiçbir dosya değiştirilmedi.
**Durum:** Bulgular onay bekliyor. README yeniden yazımı ayrı bir görev.

## Doğrulama ortamı ve yöntem

Host: Linux x86_64. macOS/Windows runtime adımları burada **çalıştırılamaz**;
o maddeler "doğrulanmadı" olarak işaretlendi.

Çalıştırılan komutlar ve çıkış kodları:

| Komut | Exit | Sonuç |
|---|---|---|
| `wc -l README.md` | 0 | `233 README.md` |
| `grep -n '^#' README.md` | 0 | 31 satır; 4'ü (`:149, 154, 157, 160`) ```bash bloğu içindeki yorum → **27 gerçek başlık** (2'si `h1`, gövde ortasında) |
| `git tag -l` | 0 | **boş** (bu depoda hiç tag yok) |
| `git status --short` | 0 | boş (denetim öncesi ağaç temiz) |
| `bash macos/tests/static-checks.sh` | 0 | `static-checks: 19 scripts, 0 failures` |
| `bash -n macos/scripts/*.sh macos/build.sh` | 0 | hepsi ayrışıyor |
| `bash -n linux/scripts/*.sh linux/build.sh` | 0 | hepsi ayrışıyor |
| `xmllint --noout macos/launchd/com.cagritaskn.goodbyedpi-turkey.plist.template` | 0 | iyi biçimli XML |
| `curl -o /dev/null -w '%{http_code}' -L <25 tekil URL>` | 0 | 23 × `200`, 1 × `403`, 1 × `000` (ayrıntı: Bulgu 24) |
| `curl api.github.com/repos/cagritaskn/GoodbyeDPI-Turkey/contents/` | 0 | kökte `linux/` **yok** |
| `curl api.github.com/repos/bahattinercan/GoodbyeDPI-Turkey/releases` | 0 | `release count: 0` |
| `curl api.github.com/repos/bahattinercan/GoodbyeDPI-Turkey/tags` | 0 | `tag count: 0` |
| `curl -H 'Accept: application/vnd.github.html+json' .../readme` | 0 | GitHub'ın **kendi render çıktısı** (aşağıdaki markdown bulgularının kanıtı) |
| `unzip -l /tmp/gdpi.zip` (release ZIP'i, depo dışına indirildi) | 0 | 30 dosya — içerik listesi Bulgu 4'te |

Render kanıtının bu dosyaya ait olduğunun doğrulaması: yerel `README.md` blob sha
`3b51fa4dcf3a2b6b9f11d952f2bfe42e73af02af`, GitHub API'nin döndürdüğü
`README.md` sha'sı ile **aynı** (`git hash-object README.md` → aynı değer).
Yani aşağıda "render" diye anılan HTML, bu dosyanın gerçek GitHub çıktısıdır.

---

## Bulgular

Her bulgu `dosya:satır` kanıtıyla verilmiştir. Kanıtı olmayan iddia yazılmadı.

### A. Yapı ve akış

**1. Belgenin H1 başlığı yok; iki H1 gövdenin ortasında duruyor.**
`README.md:1` badge'lerle başlıyor, dosyada `# ` ile başlayan bir başlık satırı
ilk 50 satırda hiç yok. GitHub render çıktısındaki başlık sırası şöyle başlıyor:
`h2 Linux Kullanıcıları İçin`, `h3 Gereksinimler`, … ve ancak
`README.md:51`'de `h1 SplitWire-Turkey Hakkında Önemli Not (29.07.2025)`,
`README.md:56`'da `h1 Kaspersky Antivirüsü Hakkında Önemli Not (13.01.2025)`.
Yani belge "başlıksız" açılıyor, iki H1 ise *not* başlığı olarak gövde ortasında
kullanılıyor. Projenin adı hiçbir yerde başlık olarak geçmiyor (yalnızca
`README.md:66`'daki `h2`de uzun bir tarif olarak).
*Etki:* GitHub'ın otomatik "Table of contents"u, ekran okuyucular ve arama
motorları belge hiyerarşisini yanlış okuyor; sayfa başlığı projeyi tanıtmıyor.

**2. Sıralama ters: Linux bölümü, "Özet" ve proje tanıtımından önce geliyor.**
`README.md:12` `## Linux Kullanıcıları İçin` → `README.md:62` `## Özet` →
`README.md:66` `## GoodbyeDPI — Derin Paket İnceleme (DPI) atlatma aracı`.
Yani okuyucu, yazılımın ne olduğunu öğrenmeden önce `sudo`, `pam_faillock`,
`systemd` ve `CAP_NET_RAW` ayrıntılarına giriyor (`README.md:24-49`).
*Etki:* İlk kez gelen ziyaretçi (projenin ana kitlesi Windows kullanıcısı,
`README.md:97-128`) 50 satırlık Linux operasyon detayını atlamak zorunda.

**3. "Özet" ile tanıtım aynı cümleyi iki kez söylüyor.**
`README.md:64`: "Bu proje Discord ve diğer engelli site ve uygulamalara VPN'siz …
girmek için GoodbyeDPI'ın düzenlenmiş bir versiyonudur."
`README.md:68`: "… bu durumu bertaraf etmek için asıl proje olan
[GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI)'ın düzenlenmiş bir
versiyonudur."
İki ayrı `h2` (`62`, `66`) altında neredeyse aynı tanım var.
*Etki:* Gereksiz uzunluk; hangi başlığın "giriş" olduğu belirsiz.

**4. Üstte ardışık blockquote yığını var (iki ayrı blok, üç mesaj).**
`README.md:5-6` bir blockquote, `README.md:8-10` ikinci bir blockquote
(`README.md:7` boş satırla ayrılmış). Render çıktısında belge genelinde
toplam **2** `<blockquote>` var, ikisi de sayfa başında. İçerikleri: macOS
desteği duyurusu, `macos/README.md` yönlendirmesi, Linux desteği duyurusu.
*Etki:* Sayfa, badge'lerin hemen altında üç ayrı "duyuru kutusu" ile açılıyor;
hepsi tek bir "Hızlı başlangıç" tablosuna/paragrafına indirgenebilir.

**5. İçindekiler tablosu yok.**
27 gerçek başlıklı (render çıktısındaki `h1`–`h3` sayısı: 27), 233 satırlık belgede `README.md` içinde hiçbir TOC bağlantısı yok
(`grep -c 'İçindekiler' README.md` → 0). Buna karşılık `README.md:6` gibi
yerlerde tek bir başlığa mutlak URL ile anchor verilmiş
(`#macos-kullan%C4%B1c%C4%B1lar%C4%B1-i%CC%87%C3%A7in`).
*Not (olumlu):* o anchor **doğru** — render çıktısındaki id
`macos-kullanıcıları-i̇çin` ile birebir eşleşiyor. Sorun anchor değil, TOC'un
hiç olmaması.

### B. Bozuk / riskli markdown

**6. Başlıktan hemen sonra gelen çıplak `>` satırları.**
`README.md:52`, `README.md:57`, `README.md:196`, `README.md:231` — her biri bir
`#`/`##`/`###` başlığının **hemen** altında, tek başına `>`.
Render çıktısında bunlar callout bloğunun ilk (boş) satırı oluyor: boş
`<blockquote>` sayısı 0, yani görünür bir kırılma yok ama ham markdown'da
gereksiz gürültü ve kopyala-yapıştır hatası izi.
*Etki:* Bakım sırasında "bu `>` neyi açıyor?" sorusu; bir sonraki düzenlemede
callout kolayca kırılır.

**7. "Lazy continuation" yüzünden düz metin callout'un İÇİNE düşüyor (gerçek render hatası).**
`README.md:59` `>` ile başlıyor, ama `README.md:60` `>` olmadan devam ediyor:
`Kaspersky'i GoodbyeDPI ZIP dosyasının indirme işlemi sırasında devre dışı
bırakmanız …`. GitHub render çıktısında bu cümle
`<div class="markdown-alert markdown-alert-caution">` **içindeki** `<p>`nin
parçası olarak çıkıyor (kanıt: `/tmp/rd.html`, `markdown-alert-caution`
bloğu; metin "…son derece yeterlidir.)" satırından sonra satır sonu ile aynı
paragrafta devam ediyor).
Aynı hata `README.md:83-85`: `>` yalnızca `83`'te var, `84` ve `85` düz metin →
WinDivert/bağış açıklamasının tamamı `markdown-alert-important` kutusunun
içine giriyor (render çıktısında `ImportantWinDivert dosyalarının
açıklamalarında …` olarak doğrulandı).
*Etki:* "Uyarı kutusu" sanılan yerlerde aslında 5-6 satırlık açıklama metni
var; kutu görsel olarak şişiyor ve metin yanlış yere ait görünüyor.

**8. İki başlıkta görünmez karakter (U+200B, zero-width space) var.**
`README.md:62` `## Özet​` ve `README.md:185` `## WinDivert.dll ve
WinDivert64.sys Dosyalarını Silmek​` — her ikisinde de başlık metninin sonunda
`U+200B`. Render çıktısındaki anchor id'leri de bunu taşıyor:
`id="user-content-özet"` ve `id="user-content-windivertdll-ve-windivert64sys-dosyalarını-silmek"`.
*Etki:* Elle yazılan `#özet` gibi bir bağlantı kırılır; arama/kopyalamada
görünmez karakter taşınır. (`REVERT.md` başlıklarında da aynı karakter var,
`REVERT.md:1`, `REVERT.md:16`, `REVERT.md:47` — bu görevin kapsamı dışı,
not olarak kaydedildi.)

**9. Satır sonu boşlukları.**
`README.md:176` ve `README.md:178` satır sonunda trailing whitespace
(`cat -A` → `… gerekiyor. ` ve `… sorunu: $`).
*Etki:* `.editorconfig` ihlali; diff gürültüsü.

**10. Windows bölümündeki "Güvenlik notları" `h2`/`h3` hiyerarşisine bağlı değil.**
`README.md:121` `**Güvenlik notları (Windows)**` düz kalın metin olarak duruyor,
oysa aynı belgede Linux tarafı için `README.md:42` `### Güvenlik notları (kısa)`
gerçek başlık. Aynı kavram iki platformda iki farklı markdown seviyesinde.
*Etki:* TOC/çapa üretilemez, tutarsız gezinme.

### C. Tekrar (satır numaralı)

**11. Kaspersky: 5 ayrı yerde, 11 kez.**
`README.md:56` (1), `README.md:59` (3), `README.md:60` (2), `README.md:80` (2),
`README.md:167` (3). Ölçüm: `grep -n -i -o kaspersky README.md | cut -d: -f1 | uniq -c`
→ `1 56 · 3 59 · 2 60 · 2 80 · 3 167`.
*Etki:* Aynı "Kaspersky'i tamamen kaldırın" talimatı dört farklı üslupla
tekrarlanıyor; biri (60) yanlış callout içinde (Bulgu 7).

**12. Yandex DNS: 4 ayrı yerde, 7 kez; `77.88.8.8` 4 yerde.**
`README.md:44` (2 + IP), `README.md:126` (1 + 2 IP), `README.md:183` (3 + IP),
`README.md:202` (1 + IP). Ölçüm: `yandex` → `2 44 · 1 126 · 3 183 · 1 202`;
`77.88.8.8` → `1 44 · 2 126 · 1 183 · 1 202`.

**13. Yönetici/sudo: 21 satırda 24 kez.**
`README.md:18, 24, 26, 27, 36 (×2), 40, 49, 73, 103, 108, 116, 119, 123, 124 (×2),
155, 158, 161, 170, 173 (×2), 187, 201`.

**14. Hizmet kaldırma (`service_remove`): 9 kez, 9 ayrı satır.**
`README.md:36, 40, 49, 108, 161, 170, 173, 187, 198`.

**15. Aynı iki DNS rehber linki birebir iki kez.**
`README.md:183` ve `README.md:202` — `ipsorgu.com/windows_10_dns_degistirme.php`
ve `.../windows_11_dns_degistirme.php` çifti aynı cümle kalıbıyla tekrarlanıyor
(`**Windows 10 için [buradan](…)**`). Ölçüm: host dağılımında
`4 https://www.ipsorgu.com` (2 tekil URL × 2 kullanım).

### D. Bağlantı doğruluğu

**16. 10 GitHub bağlantısı bu fork'a değil, ebeveyn repoya (`cagritaskn`) gidiyor.**
`git remote -v` → `origin https://github.com/bahattinercan/GoodbyeDPI-Turkey`.
README'deki github.com linklerinin sahip dağılımı:
`10 cagritaskn`, `4 basil00`, `1 ValdikSS`, `1 sponsors`.
Satırlar: `README.md:3` (Downloads badge + releases),
`README.md:6` (macOS anchor), `README.md:54` (×2: SplitWire + REVERT),
`README.md:101`, `README.md:114`, `README.md:132` (REVERT), `README.md:150`
(`git clone`), `README.md:170` (ZIP).
**HTTP durumu:** hepsi `200` (doğrulandı) — yani **kırık link değil**, ama
**yanlış depoya** işaret ediyor.

**17. `git clone` satırı bu fork'un Linux dizinini getirmiyor.**
`README.md:150` `git clone https://github.com/cagritaskn/GoodbyeDPI-Turkey.git`.
GitHub contents API kanıtı: `cagritaskn/GoodbyeDPI-Turkey` kökünde
`.editorconfig, .github, .gitignore, LICENSE, README.md, REVERT.md, macos, src, windows`
— **`linux/` yok**. Aynı reponun render edilmiş README'sinde
`linux-kullanıcıları-için` id'si de yok (yalnız `macos-kullanıcıları-i̇çin` var).
*Etki:* macOS hızlı başlangıcı çalışır (o repoda `macos/` var), ama bu fork'un
README'sindeki `linux/` bölümü (`README.md:12-49`) clone edilen ağaçta yok.

**18. ZIP linki Windows-only bir release'e gidiyor; bu fork'un macOS/Linux içeriği ZIP'te yok.**
`README.md:101`, `README.md:114`, `README.md:170` aynı URL:
`…/releases/download/release-0.2.3rc3-turkey/goodbyedpi-0.2.3rc3-turkey.zip`
(HTTP `200`, 308.802 bayt, indirildi). `unzip -l` içeriği (30 dosya):
`licenses/` (4 dosya), `README-BENİ OKU.txt`, **8** `.cmd` dosyası,
`x86/` + `x86_64/` (`goodbyedpi.exe`, `WinDivert.dll`, `WinDivert*.sys`).
İçerikte **`SHA256SUMS` yok**, `_require_admin.cmd` yok, `linux/`/`macos/` yok.

**19. README'nin `SHA256SUMS` talimatı bu ZIP'te karşılıksız.**
`README.md:127`: "``certutil -hashfile goodbyedpi.exe SHA256`` çıktısını sürüm
notundaki veya ``SHA256SUMS`` dosyasındaki değerle karşılaştırın."
Kanıt: ZIP içerik listesinde `SHA256SUMS` **yok** (Bulgu 18); repoda ise
`SHA256SUMS` yalnızca CI artifact'ı olarak üretiliyor
(`.github/workflows/build.yml:82`, `:102`) ve release'e eklenmiyor.
*Etki:* Kullanıcıya "doğrula" deniyor, doğrulayacak dosya verilmiyor.

**20. Sürüm adı bu fork için tanımsız — karar gerekiyor.**
`git tag -l` → **boş** (exit 0). GitHub API: `bahattinercan/GoodbyeDPI-Turkey`
→ `tag count: 0`, `release count: 0`. Yani `release-0.2.3rc3-turkey` etiketi ve
`goodbyedpi-0.2.3rc3-turkey.zip` varlığı **yalnızca** `cagritaskn` deposunda.
README üç yerde (`README.md:101, 114, 170`) bu adı bu fork'un sürümüymüş gibi
kullanıyor.
**⚠️ KULLANICIYA SORULACAK:** bu fork için doğru sürüm adı/numarası nedir?
(Uydurma numara yazılmadı; seçenekler: (a) bu fork için yeni release + tag
üret, (b) README'de "Windows ZIP, ebeveyn reponun 0.2.3rc3 sürümüdür" diye
açıkça belirt, (c) ZIP'i bu fork'un CI artifact'ından üret.)

**21. Harici link sağlığı: 25 tekil URL'nin 23'ü `200`.**
Doğrulananlar (`200`): 3 shields.io badge, `github.com/cagritaskn/…` (repo,
REVERT blob, ZIP), `github.com/cagritaskn/SplitWire-Turkey`,
`github.com/ValdikSS/GoodbyeDPI`, `github.com/basil00`, `github.com/basil00/WinDivert`,
`github.com/basil00/WinDivertTool/releases/download/v2.2.0/WinDivertTool.exe`,
`github.com/sponsors/cagritaskn`, `patreon.com/cagritaskn/membership`,
`virustotal.com/gui/home/upload`, `virustotal.com/gui/file/3ca863…`,
`support.microsoft.com/…`, `support.kaspersky.com/ksos/8.5/tr-TR/227390.htm`,
`ipsorgu.com` × 2.
**Doğrulanamayanlar:** `https://www.technopat.net/sosyal/konu/…3619948/` → `403`
(bot koruması; link ölü demek değil, tarayıcıyla kontrol edilmeli);
`https://reqrypt.org/donate.html` → `000` (bu host'tan bağlantı kurulamadı;
ağ/DNS engeli olabilir, "ölü" olarak işaretlenmedi).

**22. Depo içi metadata da ebeveyn repoyu gösteriyor (README dışı, destek kanıtı).**
`linux/systemd/goodbyedpi-turkey.service.template:3` →
`Documentation=https://github.com/cagritaskn/GoodbyeDPI-Turkey`.
`macos/README.md:42` → `git clone https://github.com/cagritaskn/GoodbyeDPI-Turkey.git`.
*Not:* Bu iki dosya bu görevin salt-okuma kapsamında; **düzeltilmedi**, yalnız
olarak raporlandı (README yeniden yazılırken karar verilmesi gereken tutarlılık).

### E. Eksik kapsam

**23. CI'ın ürettiği artifact'lar README'de hiç yok.**
`.github/workflows/build.yml:87` → `goodbyedpi_x86_64_<sha>` (+`SHA256SUMS`, `:82`),
`:107` → `goodbyedpi_x86_<sha>` (+`SHA256SUMS`, `:102`),
`:152-156` → `goodbyedpi-turkey_macos_x86_64_<sha>` / `_macos_arm64_<sha>`
(matrix `macos-15-intel`, `macos-14`; `:120`). README'de `artifact` kelimesi
**0** kez geçiyor (`grep -c artifact README.md` → 0).

**24. Kaynaktan derleme (MinGW + WinDivert 2.2.2-A) anlatılmıyor.**
`build.yml:24-27`: `WINDIVERT_URL=…/v2.2.2/WinDivert-2.2.2-A.zip`,
`WINDIVERT_SHA256=63cb4176…`, `:47-50` `gcc-mingw-w64`, `:69-72`
`make CPREFIX=x86_64-w64-mingw32- BIT64=1 WINDIVERTHEADERS=…`.
README'de `MinGW` **0**, `WinDivert 2.2.2` **0**. Linux/macOS için derleme
anlatılıyor (`README.md:20-22`, `README.md:146-152`) ama Windows için hiç yok.
*Etki:* Asimetri: bir platformda "kaynaktan derle" var, asıl platformda yok.

**25. Diğer besleyen dosyalar README'de yok.**
`docs/plans` → 0, `README-BEN` → 0 (`windows/README-BEN OKU.txt` mevcut),
`linux/tests` → 0, `make check` → 0, `make test` → 0
(`linux/Makefile:23-35` bu hedefleri tanımlıyor; `linux/tests/static-checks.sh`,
`linux/tests/lib-test.sh` mevcut), `LICENSE` bölümü yok — lisans yalnızca
`README.md:1`'deki badge'de geçiyor, metinde "lisans/apache" 0 kez.

**26. `REVERT.md` Linux kaldırmayı kapsamıyor.**
`REVERT.md` başlıkları: `:11` "GoodbyeDPI-Turkey'i ve Dosyaları Tamamen Silmek",
`:18` "DNS Atamasını Geri Almak", `:49` "macOS'ta Kaldırma",
`:85` "WinDivert SYS Dosyaları Kullanımda Hatası". **Linux bölümü yok**
(`grep -i linux REVERT.md` → hiçbir başlık/isim eşleşmiyor).
Buna karşılık `README.md:132` genel ifadeyle "**[bu rehberi]** takip edebilirsiniz"
diyor; Linux kullanıcısı orada kendine ait adım bulamaz.

### F. Tutarlılık (dosya adı / sayı iddiaları)

**27. `windows/` sayısı ve adları: 16 `.cmd`, 13'ü README'de adıyla yok.**
`ls -1 windows/*.cmd | wc -l` → **16** (AGENTS.md'deki "15 `.cmd`" ifadesi de
gerçekle uyuşmuyor; README sayı vermiyor ama "15" iddiası dolaşımda).
README'de `.cmd` adı olarak geçenler: `service_install_dnsredir_turkey.cmd`
(`:103`), `service_remove.cmd` (`:108`), `turkey_dnsredir.cmd` (`:116`) — hepsi
**var**. Adı hiç geçmeyenler: `_require_admin.cmd` (hiç anılmıyor) + 12
`*_alternative*_superonline.cmd` (yalnız desen olarak anılıyor, `:200-201`).

**28. `alternative(1/2/3/4/5/6)` deseni yanlış: `alternative1` diye dosya yok.**
`README.md:200-201`: `turkey_dnsredir_alternative(1/2/3/4/5/6)_superonline.cmd`
ve `service_install_dnsredir_turkey_alternative(1/2/3/4/5/6)_superonline.cmd`.
Gerçek dosya adları: `…_alternative_superonline.cmd` (numarasız) +
`…_alternative2..6_superonline.cmd` → 6 dosya, "1" numaralı yok.
*Etki:* Kullanıcı `…_alternative1_…` arıyor, bulamıyor.

**29. Linux yöntem sayısı kendi içinde çelişkili.**
`README.md:31`: "diğer **altı** yöntem … `alternative_superonline.sh` ile
`alternative2` … `alternative6` arasındadır (**2, 3, 4, 5, 6** sonekleri)."
Altı yöntem = `alternative` + `2..6`; ama parantez yalnızca 5 sonek sayıyor.
`ls -1 linux/scripts/*.sh` → 16 dosya (`_lib.sh` + 15 koşucu), yani 1 varsayılan
+ 6 alternatif = 7 tek-seferlik koşucu doğru, **ifade** hatalı.

**30. "Ön ayarların 5'i Yandex DNS" iddiası yanlış: 8 dosya Yandex kullanıyor.**
`README.md:126`: "Ön ayarların **5'i** varsayılan olarak Yandex DNS'e
(77.88.8.8 / 77.88.8.1) yönlendirir."
`grep -l '77\.88\.8\.8' windows/*.cmd | wc -l` → **8**:
`turkey_dnsredir.cmd`, `turkey_dnsredir_alternative3/4/5_superonline.cmd`,
`service_install_dnsredir_turkey.cmd`,
`service_install_dnsredir_turkey_alternative3/4/5_superonline.cmd`.
`README.md:183` ise "alternatif 3, 4, 5'te önayarlı Yandex var; 1, 2, 6'da yok"
diyor — bu **doğru** (alternatif 1/2/6 dosyalarında `--dns-addr` yok). Yani
`:126` ile `:183` birbiriyle çelişiyor; doğru olan `:183`.

**31. `README.md:173` iki dosya adını uzantısız yazıyor.**
`service_install_dnsredir_turkey_alternative2_superonline` ve
`…alternative4_superonline` — `.cmd` yok (karşılaştır `:187`, `:198` aynı
dosyaları `.cmd` ile yazıyor). Dosyalar `windows/` altında `.cmd` uzantısıyla var.

---

## Önerilen yeni iskelet

Başlık ağacı (H1 tek, platformlar H2, ayrıntı H3; sıra: tanıtım → hızlı başlangıç
→ platform bölümleri → ortak konular → ekler):

```
# GoodbyeDPI-Turkey
## Bu fork nedir?                        (tek paragraf + 3 satırlık platform tablosu)
## Hızlı başlangıç                       (platform → tek komut/tek adım tablosu)
### Windows
### Linux
### macOS
## İçindekiler                           (27 başlık yerine ~12)
## Nasıl çalışır (ve ne değildir)        (DPI atlatma, VPN değil; WinDivert vs byedpi)
## Windows
### Gereksinimler ve yönetici yetkisi
### Hizmet kurarak kullanma
### Batch dosyası ile kullanma (tek seferlik)
### SuperOnline alternatif yöntemleri   (alternative / 2..6 tablosu, tek yerde)
### DNS ve port değiştirme
### Kaldırma                            (REVERT.md'ye tek bağlantı)
### Sorun giderme                       (WinDivert, taşıma hatası, yavaş siteler, Discord)
## Linux
### Gereksinimler
### Derleme                             (./build.sh, make build, make check, make test)
### Sudo ve gerçek terminal şartı
### Tek seferlik kullanım
### Servis olarak kullanma              (systemd unit adı, journalctl, remove)
### Kalıntı kontrolü ve sorun giderme
### Güvenlik notları
## macOS
### Gereksinimler ve derleme
### Tek seferlik kullanım / servis / split-tunnel
### Güvenlik notları
## Güvenlik ve güven                    (TEK yer: hash/SHA256SUMS, WinDivert+Bitcoin,
                                         antivirüs/Kaspersky, Yandex DNS, yönetici yetkisi)
## Kaynaktan derleme ve CI               (MinGW + WinDivert 2.2.2-A; artifact adları + SHA256SUMS)
## Proje yapısı                         (src/ windows/ linux/ macos/ docs/ tablosu)
## Katkı ve lisans                      (Apache 2.0, ISSUE_TEMPLATE, CI workflow'ları)
## Bağış ve destek
## Yasal uyarı
## Ek: tarihli notlar                   (SplitWire-Turkey 29.07.2025, Kaspersky 13.01.2025
                                         → callout değil, tarihli "Ek" bölümü)
```

İlkeler:
- Belgede **tek** `#` (H1) olur; tarihli notlar H1 olmaktan çıkar (Bulgu 1).
- Tanıtım, "Özet" ve platform duyuruları **tek** yerde birleşir (Bulgu 2, 3, 4).
- Kaspersky/Yandex/sudo/`service_remove` her biri **tek** bölümde anlatılır,
  diğer yerler o bölüme bağlantı verir (Bulgu 11-14).
- Callout kullanılırsa her satır `>` ile başlar (Bulgu 6, 7); başlıklarda
  görünmez karakter olmaz (Bulgu 8).
- Tüm iç bağlantılar `#anchor` (mutlak `github.com/...` değil) olur (Bulgu 16).

---

## Yapılabilecekler (öncelik sırası)

**P0 — yanlış bilgi / yanlış hedef (kullanıcıyı yanıltır)**

1. **Link sahipliğini netleştir** (Bulgu 16, 17, 22): 10 `cagritaskn` linkini bu
   fork'a (`bahattinercan`) çevir ya da "bu ZIP/sürüm ebeveyn repoya aittir"
   diye açıkça yaz. `git clone` satırı bu fork'un URL'si olmalı.
2. **Sürüm adı kararı** (Bulgu 20): ⚠️ kullanıcıya sorulacak; tahmin yazılmayacak.
3. **`SHA256SUMS` talimatını düzelt** (Bulgu 19): ya ZIP'e/CI artifact'ına
   `SHA256SUMS` ekle ve README'de artifact adını ver, ya da talimatı kaldır.
4. **Tek H1 + tanıtım öne** (Bulgu 1, 2, 3): belge `# GoodbyeDPI-Turkey` ile
   açılsın, Linux bölümü tanıtımdan sonra gelsin, "Özet" ile tanıtım birleşsin.
5. **Lazy continuation'ları kapat** (Bulgu 7): `README.md:60`, `84`, `85`
   satırlarına `>` ekle veya callout dışına çıkar.
6. **"Ön ayarların 5'i" → 8** (Bulgu 30): `:126` ile `:183` çelişkisi giderilsin.

**P1 — eksik kapsam / yapısal boşluk**

7. **İçindekiler tablosu ekle** (Bulgu 5) ve başlıklardaki `U+200B`'yi temizle (Bulgu 8).
8. **"Kaynaktan derleme ve CI" bölümü** (Bulgu 23, 24): MinGW + WinDivert
   2.2.2-A adımları, `goodbyedpi_x86_64_<sha>` / `_x86_` / `_macos_arm64_` /
   `_macos_x86_64_` artifact adları, 14 günlük saklama.
9. **Kaspersky/Yandex/sudo/`service_remove` tekrarını tek bölüme indir**
   (Bulgu 11-14), diğer yerlerde bağlantı bırak.
10. **Linux `make check` / `make test`** ve `linux/tests/` README'de anılsın
    (Bulgu 25) — `docs/plans/` ve `windows/README-BEN OKU.txt` de.
11. **`REVERT.md`'ye Linux kaldırma bölümü** ekle veya README'de "Linux için
    `sudo ./scripts/service_remove.sh`" satırını açık tut (Bulgu 26).
12. **Lisans bölümü** ekle (Apache 2.0, `LICENSE`) — şu an yalnız badge var (Bulgu 25).
13. **Platform badge'ini düzelt** (Bulgu 2 ile aynı kök): `Platform-Windows |
    macOS` → Linux da sayılmalı (`Windows | Linux | macOS`).
14. **`.cmd` desenlerini düzelt** (Bulgu 27, 28, 31): `alternative(1/2/3/4/5/6)`
    → `alternative` + `2..6`; `_require_admin.cmd` belgeye girsin; uzantısız
    adlar `.cmd` olsun.
15. **Windows güvenlik notlarını gerçek başlık yap** (Bulgu 10), macOS/Linux ile
    aynı seviyede (`### Güvenlik notları`).

**P2 — hijyen**

16. Trailing whitespace temizliği (`README.md:176, 178`) (Bulgu 9).
17. `ipsorgu` DNS link çiftini tek yerde tut (Bulgu 15).
18. Tarihli notları (SplitWire 29.07.2025, Kaspersky 13.01.2025) "Ek" bölümüne
    taşı; H1 kullanma (Bulgu 1).
19. Linux yöntem sayısı cümlesini düzelt: "altı yöntem" + 5 sonek çelişkisi (Bulgu 29).
20. `reqrypt.org` ve `technopat.net` linklerini tarayıcıyla doğrula (Bulgu 21).

---

## Doğrulanmayan maddeler

- macOS runtime adımları (`./macos/build.sh`, `sudo ./macos/scripts/*.sh`,
  launchd kurulumu): bu host Linux; **doğrulanmadı**.
- Windows runtime adımları (`.cmd` çalıştırma, hizmet kurma/kaldırma, `icacls`,
  `certutil`): bu host Linux; **doğrulanmadı**.
- `https://www.technopat.net/...` → HTTP `403` (bot koruması). Linkin canlı olup
  olmadığı **doğrulanmadı**.
- `https://reqrypt.org/donate.html` → `000` (bağlantı kurulamadı). **Doğrulanmadı**;
  "kırık" olarak sınıflandırılmadı.
- Release ZIP'inin **içeriği** doğrulandı (`unzip -l`), ancak ZIP içindeki
  `.exe`/`.sys` dosyalarının çalışırlığı **doğrulanmadı**.
- GitHub Actions workflow'larının gerçekten yeşil çalıştığı **doğrulanmadı**
  (yalnız YAML okundu; bu host'ta MinGW/macOS runner yok).

## Kullanıcıya sorulacaklar

1. Bu fork için doğru sürüm adı/etiketi nedir? (`release-0.2.3rc3-turkey`
   yalnız `cagritaskn` deposunda var; burada tag/release yok.)
2. README bu fork'u mu (`bahattinercan`) yoksa ebeveyn repoyu mu birincil
   kaynak göstermeli? (10 link + `git clone` + systemd `Documentation=`)
3. Windows ZIP'i bu fork'un CI'ından mı üretilecek, yoksa "ebeveyn reponun
   sürümü" olarak mı anılacak?
