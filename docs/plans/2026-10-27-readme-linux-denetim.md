# README.md "Linux Kullanıcıları İçin" bölümü — kaynak denetimi (2026-10-27)

**Durum:** Tamamlandı. Salt okuma denetimi; hiçbir kaynak dosya değişmedi.
**Kapsam:** `README.md:12-50` (Linux bölümü) ↔ `linux/README.md`, `linux/scripts/`, `linux/build.sh`, `linux/Makefile`, `linux/systemd/`.
**Üretilen:** yalnızca bu dosya.
**Yöntem:** `ls` sayımı, `grep -rn`, dosya okuma, `bash -n`. Hiçbir betik çalıştırılmadı (root ister, sistem ayarı değiştirir).

Sonuç sözlüğü: **DOGRU** = iddia kaynakta doğrulandı · **YANLIS** = kaynak iddiayı çürütüyor · **EKSIK** = iddia kısmen doğru ama önemli bir nuans/eksik anlatılmış · **DOGRULANMADI** = kanıt bulunamadı (tahmin yok).

Kanıt sütunundaki `linux/...:satır` referansları bu worktree'teki satır numaralarıdır.

---

## 1. Yedi tek seferlik betik

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `linux/scripts/turkey_dnsredir.sh` var, varsayılan yöntem | `linux/scripts/turkey_dnsredir.sh:7` → `run_method_oneshot default` | DOGRU |
| `turkey_dnsredir_alternative_superonline.sh` var | `linux/scripts/turkey_dnsredir_alternative_superonline.sh:7` → `run_method_oneshot alt` | DOGRU |
| `alternative2…alternative6_superonline.sh` beşi de var | `linux/scripts/turkey_dnsredir_alternative2_superonline.sh:7` (alt2), `..._alternative3_...:7` (alt3), `..._alternative4_...:7` (alt4), `..._alternative5_...:7` (alt5), `..._alternative6_...:7` (alt6) | DOGRU |
| Toplam sayı 7 (`README.md:31` "diğer altı yöntem" + varsayılan) | `ls -1 linux/scripts/turkey_dnsredir*.sh | wc -l` → `7` | DOGRU |
| 7 yöntemin hepsi ortak katmanda tanımlı (kod tarafı) | `linux/scripts/_lib.sh:248` (`_METHODS="default alt alt2 alt3 alt4 alt5 alt6"`), `linux/scripts/_lib.sh:263-270` (argüman tablosu) | DOGRU |
| "Tüm betikler `linux/scripts/` altındadır" (`README.md:32`) | `ls linux/scripts/` → 15 betik + `_lib.sh`, başka dizinde betik yok | DOGRU |
| "Ctrl-C ile durduğunuzda ağ ayarları otomatik geri döner" (`README.md:32`) | `linux/scripts/_lib.sh:1067-1071` (`trap ... EXIT/INT/TERM`) → `:1060-1065` `_gdt_cleanup` → `restore_state` (`:669`); tuzak `run_method_oneshot` içinde kuruluyor: `:1268` | DOGRU (statik okuma; betik çalıştırılmadı) |

## 2. Servis betikleri

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `service_install_dnsredir_turkey.sh` var | `linux/scripts/service_install_dnsredir_turkey.sh:7` → `run_method_service_install default` | DOGRU |
| `service_install_dnsredir_turkey_alternative_superonline.sh` var | `linux/scripts/service_install_dnsredir_turkey_alternative_superonline.sh:7` (alt) | DOGRU |
| `..._alternative2…6_superonline.sh` beşi de var | dosya adları + satır 7: alt2, alt3, alt4, alt5, alt6 | DOGRU |
| `service_remove.sh` var | `linux/scripts/service_remove.sh:7` → `run_service_remove` (`linux/scripts/_lib.sh:1333-1352`) | DOGRU |
| Sayım: 7 kurulum betiği + 1 kaldırma betiği | `ls -1 linux/scripts/service_*.sh | wc -l` → `8` (7 installer + `service_remove.sh`) | DOGRU |
| `README.md:36` servis bölümü yalnız varsayılan kurulumu ve kaldırmayı anlatıyor; 7 servis varyantının varlığından söz etmiyor | `README.md:36` ↔ `linux/README.md:53-59` (varyantlar orada listelenmiş) | EKSIK |

## 3. Derleme: `cd linux && ./build.sh` → `linux/bin/ciadpi`

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| Çıktı yolu `linux/bin/ciadpi` (`README.md:22`) | `linux/build.sh:31` (`BIN_DIR="${SCRIPT_DIR}/bin"`), `linux/build.sh:93` (`cp -f "$BYEDPI_DIR/ciadpi" "$BIN_DIR/ciadpi"`), `linux/build.sh:96` (log) | DOGRU |
| Üretilen dosya diskte gerçekten var (önceki bir derlemeden) ve gitignored | `ls -l linux/bin/ciadpi` → 97016 B; `.gitignore:9` (`linux/bin/`) | DOGRU |
| `./build.sh` bu oturumda çalıştırılıp binary üretti mi (çalışma zamanı kanıtı) | constraint gereği çalıştırılmadı; bu makinede `make -C linux build` ağı çalıştırır | DOGRULANMADI |
| "derleme için `git` / `make` / `gcc`" (`README.md:18`) | `linux/build.sh:42` → `for tool in git make cc` (kontrol edilen `cc`, `gcc` değil); `linux/README.md:16` doğru yazıyor (`cc` / `gcc`) | EKSIK |
| "`systemd`" koşulsuz gereksinim gibi sunuluyor (`README.md:18`) | `linux/scripts/_lib.sh:239-241` `require_systemd` yalnız servis modunda çağrılıyor; `linux/README.md:15` "(servis modu için)" diyor | EKSIK |
| `make build` alternatifi Linux bölümünde yok | `linux/Makefile:11-15`, `linux/README.md:25` | EKSIK |
| byedpi kaynağı `linux/third_party/byedpi` altına klonlanıyor | `linux/build.sh:29-30, 54` | DOGRU |

## 4. Servis adı `goodbyedpi-turkey`

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| Unit adı `goodbyedpi-turkey` (`README.md:36`) | `linux/scripts/_lib.sh:27` (`UNIT_NAME="goodbyedpi-turkey"`) | DOGRU |
| Kurulan dosya `/etc/systemd/system/goodbyedpi-turkey.service` | `linux/scripts/_lib.sh:28`, yazım/etkinleştirme `:1316-1317`, kaldırma `:1340-1342` | DOGRU |
| Şablon dosyası ada uygun | `linux/scripts/_lib.sh:29` (`UNIT_TEMPLATE="$LINUX_DIR/systemd/$UNIT_NAME.service.template"`), diskte `linux/systemd/goodbyedpi-turkey.service.template` | DOGRU |
| "şablon **içinde** servis adı" (task'ın alt kümesi) | `grep -n "goodbyedpi-turkey" linux/systemd/goodbyedpi-turkey.service.template` → exit 1 (eşleşme yok). Ad, unit dosyasının adından gelir; şablon yalnız `ExecStart=@CIADPI@ @ARGS@` taşır (`linux/systemd/goodbyedpi-turkey.service.template:11`), yer tutucular `linux/scripts/_lib.sh:1247-1248` ile doldurulur | DOGRU (isim dosya adından; içerikte string yok) |
| `systemctl status goodbyedpi-turkey` / `journalctl -u goodbyedpi-turkey -f` komutları doğru ada işaret ediyor (`README.md:36`) | ada karşı kanıt `linux/scripts/_lib.sh:27`; kod `journalctl -u "$unit" -n 20` çağırıyor (`:1211`) | DOGRU |
| Kalıntı/durum dizini de aynı adı taşıyor | `linux/scripts/_lib.sh:24-25` (`/var/lib/goodbyedpi-turkey/prev-state.env`), `linux/README.md:75` | DOGRU |

## 5. README'de geçen ortam değişkenleri kodda var mı

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `GOODBYEDPI_DNS` kodda var (`README.md:44`) | `linux/scripts/_lib.sh:279` (`local policy="${GOODBYEDPI_DNS:-}"`), geçersiz değer koruması `:283`, sudo beyaz listesi `:74` | DOGRU |
| `GOODBYEDPI_DNS=off` DNS'i dokunmaz | `linux/scripts/_lib.sh:282`, `:288-294`, `:300-301`; test `linux/tests/lib-test.sh:221` | DOGRU |
| `GOODBYEDPI_DNS=legacy` eski yöntem tablosu davranışı | `linux/scripts/_lib.sh:282`, `:315-319` (default/alt3/alt4/alt5 → yandex; alt/alt2/alt6 → off) | DOGRU |
| Varsayılan DNS Yandex, `77.88.8.8` / `77.88.8.1` (`README.md:44`) | `linux/scripts/_lib.sh:31-32` (sabitler), `:280` (varsayılan `yandex`), uygulama `:826-827`, gizlilik uyarısı `:304` | DOGRU |
| `CIADPI_HOST` bir ortam değişkeni olarak ayarlanabilir (`README.md:46`: "`CIADPI_HOST=0.0.0.0` yapılmamalı") | `linux/scripts/_lib.sh:21` koşulsuz atama (`CIADPI_HOST="127.0.0.1"`) → dışarıdan verilen değer kaynaklandığında ezilir; sudo beyaz listesinde yok (`linux/scripts/_lib.sh:74` = `DRY_RUN,GOODBYEDPI_ARGS,GOODBYEDPI_PROXY_MODE,GOODBYEDPI_DNS`). Tek fiili override yolu `GOODBYEDPI_ARGS` içine `--ip` yazmak (`linux/scripts/_lib.sh:259-262`, `:1242`) | EKSIK |
| Varsayılan dinleme adresi `127.0.0.1:1080` | `linux/scripts/_lib.sh:21-22`; çağrı `:1146`, `:1153` (`--ip`/`--port`) | DOGRU |
| `BYEDPI_COMMIT` pin'i var (`README.md:48`) | `linux/build.sh:26` (`ba532298de7b28cfe854aea83d061369d13ca290`), karşılaştırma `:62`, uyuşmazlıkta klon silinir `:76-77` | DOGRU |
| `BYEDPI_ALLOW_UNPINNED=1 ./build.sh` pini atlar | `linux/build.sh:63-67` (uyarı) ve `:75` ( talimat satırı) | DOGRU |
| Yeni SHA "yazılması" gerektiği (`README.md:48`) | `linux/build.sh:74` `BYEDPI_COMMIT=<sha> ./build.sh` ile de geçilebiliyor (belgelenmemiş ama tutarlı) | DOGRU |
| `BYEDPI_REPO` / `BYEDPI_REF` README'de hiç anılmıyor | `linux/build.sh:16-17` | EKSIK |

## 6. Kalıntı kontrolü komutları kodda karşılık buluyor mu

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| `systemctl is-active goodbyedpi-turkey` (`README.md:40`) | `linux/scripts/_lib.sh:1193` (`systemctl is-active --quiet "$unit"`) | DOGRU |
| `pgrep -a ciadpi` (`README.md:40`) | `linux/scripts/_lib.sh:1135` — yalnızca hata mesajı **metninde** geçiyor; betiğin kendisi `pgrep` çağırmıyor (kodda başka `pgrep` yok) | EKSIK |
| `gsettings get org.gnome.system.proxy mode` (`README.md:40`) | `linux/scripts/_lib.sh:589` (kayıt anında okuma), geri yükleme `:701-703`, yazma `:770` | DOGRU |
| `resolvectl dns <arayüz>` (`README.md:40`) | `linux/scripts/_lib.sh:575` (mevcut DNS okuma), uygulama `:826`, geri yükleme `:730-734` | DOGRU |
| `systemctl status goodbyedpi-turkey` (`README.md:36`) | kodda `systemctl status` çağrısı yok; kullanılanlar `is-active` `:1193`, `list-unit-files` `:1337`, `stop/disable` `:1302-1303`, `daemon-reload`/`enable --now` `:1316-1317`. Unit adı doğru olduğu için komut geçerli | EKSIK |
| `journalctl -u goodbyedpi-turkey -f` | `linux/scripts/_lib.sh:1211` (`journalctl -u "$unit" -n 20 --no-pager`) | DOGRU |
| "Takıldığınızda `sudo ./scripts/service_remove.sh` ile temizleyip yeniden deneyin" (`README.md:40`) | `linux/scripts/_lib.sh:1333-1352` (stop+disable+unit silme+`transparent_down`+`restore_state`) | DOGRU |
| Şeffaf mod kalıntı temizliği `iptables -t nat -F GOODBYEDPI_TURKEY` (`linux/README.md:106,143`) | `linux/scripts/_lib.sh:39` (`IPT_CHAIN="GOODBYEDPI_TURKEY"`), kurulum `:937-948`, kaldırma `:993-995` | DOGRU |
| `nft delete table ip goodbyedpi_turkey` (`linux/README.md:144`) | `linux/scripts/_lib.sh:38` (`NFT_TABLE="goodbyedpi_turkey"`), kurulum `:909-911` | DOGRU |

## 7. `linux/README.md`'de olup üst README'nin Linux bölümünde olmayan konular

| Konu | Kanıt (`linux/README.md` ↔ `README.md`) | Sonuç |
|---|---|---|
| Şeffaf (transparent) mod nasıl açılır: `sudo GOODBYEDPI_PROXY_MODE=transparent ./scripts/...` | `linux/README.md:77-89`; kod `linux/scripts/_lib.sh:35, 44-47, 1269-1273` ↔ üst bölümde yalnız IPv6 notu var (`README.md:47`), değişken adı hiç geçmiyor | EKSIK |
| `socks` / `transparent` iki mod; GNOME yoksa `environment.d` dosyasına düşülmesi | `linux/README.md:79-80, 152-154`; kod `linux/scripts/_lib.sh:541-545` | EKSIK |
| 7 yöntem tablosu (argümanlar + DNS sütunu) | `linux/README.md:35-43` ↔ `README.md:31-32` yalnız dosya adlarını sayıyor | EKSIK |
| `DRY_RUN=1` önizleme (sistem komutları çalışmaz) | `linux/README.md:118-122`; kod `linux/scripts/_lib.sh:34, 199-201`, `_GDT_SUDO_KEEP` `:74` | EKSIK |
| Doğrulama kapıları: `make check` / `make test` | `linux/README.md:110-116`; `linux/Makefile:23-35`, `linux/tests/static-checks.sh`, `linux/tests/lib-test.sh` | EKSIK |
| `make build` / `make clean` | `linux/README.md:25, 29`; `linux/Makefile:11-21` | EKSIK |
| Argümanları `GOODBYEDPI_ARGS` ile ezme | `linux/README.md:138-139`; kod `linux/scripts/_lib.sh:259-262` | EKSIK |
| Sorun giderme: `203/EXEC` + `ProtectHome=read-only` | `linux/README.md:126-131`; şablon `linux/systemd/goodbyedpi-turkey.service.template:19-22` | EKSIK |
| Sorun giderme: dconf/dbus hatası, `runuser -u $SUDO_USER` ile masaüstü kullanıcısına yazma | `linux/README.md:146-151`; kod `linux/scripts/_lib.sh:407-412` (`runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS=...`, yoksa `sudo -u`) | EKSIK |
| Şeffaf modun `CAP_NET_ADMIN` istediği, servis modunda otomatik eklendiği | `linux/README.md:88`; kod `linux/scripts/_lib.sh:1244-1245, 1249-1250` | EKSIK |
| DNS arka ucu: `resolvectl` yoksa `/etc/resolv.conf` yolu | `linux/README.md:19`; kod `linux/scripts/_lib.sh:484, 488, 832-833` | EKSIK |
| "Neyin doğrulanmadığı" (yalnız statik + stub test; "kesin çalışır" iddiası yok) | `linux/README.md:156-159` ↔ `README.md:12-50` içinde karşılığı yok | EKSIK |
| Üst bölümün `linux/README.md`'ye link vermesi (`README.md:10, 40`) | dosya var: `linux/README.md` (159 satır) | DOGRU |

## 8. Linux bölümündeki diğer somut iddialar

| İddia | Kanıt (dosya:satır) | Sonuç |
|---|---|---|
| Motor byedpi/ciadpi, kullanıcı alanında SOCKS5 proxy; `--fake`, `--md5sig`, `--disorder` kullanılır (`README.md:14`) | `linux/build.sh:4-12`; `linux/scripts/_lib.sh:264-270` (ör. default: `--fake -1 --md5sig --ttl 8 --split 1+s --disorder 3+s --tlsrec 3+s --mod-http hcsmix,dcsmix`) | DOGRU |
| "VPN değildir: trafiğiniz başka ülkeye taşınmaz" (`README.md:14`) | kodda tünelleme/uzak gateway yok; yalnız yerel `--ip 127.0.0.1` (`linux/scripts/_lib.sh:21, 1146`) ve `REDIRECT`/`REDIRECT to :1080` (`:892, 910`) | DOGRU (statik okuma) |
| Root ister; şifre yalnız gerçek terminalde sorulabilir; TTY yoksa "terminal" hatası; 3 denemede `pam_faillock` ~10 dk kilit (`README.md:26-27`) | `linux/scripts/_lib.sh:181-185` (TTY algılama), `:195-231` (denemeden durma + `sudo -v` talimatı), `:224-226` (`pam_faillock` ~10 dk, `faillock --user ... --reset`). Not: hata metni birebir "terminal gereklidir" değil → `:216` "terminal (TTY) yok" | DOGRU |
| Süreç root; `--fake`/`--md5sig` için `CAP_NET_RAW` + ham soket (`README.md:45`) | `linux/systemd/goodbyedpi-turkey.service.template:14-15`; hata açıklaması `linux/scripts/_lib.sh:1134`, `:1216` | DOGRU |
| Unit sandbox anahtarları: `NoNewPrivileges`, `ProtectSystem=strict`, `RestrictAddressFamilies` (`README.md:45`) | şablon `:16`, `:18`, `:32` (+ `ProtectHome=read-only` `:22`, `SystemCallFilter` `:38`) | DOGRU |
| "bir seferlik modda bu sınır yoktur" (`README.md:45`) | `linux/scripts/_lib.sh:1146, 1153` (ciadpi doğrudan, sandbox'sız) | DOGRU |
| IPv6: `ip6tables` / `nft ip6` yoksa yalnız IPv4 kuralı + sızıntı olasılığı (`README.md:47`) | `linux/scripts/_lib.sh:924` (yetenek tespiti), `:933-935` (uyarı), `:962` (nft ip6 uyarısı), IPv6 kuralları `:942-948` | DOGRU |
| İş bitince `sudo ./scripts/service_remove.sh` kalıntı bırakmaz (`README.md:49`) | `linux/scripts/_lib.sh:1333-1352`; proxy yazımı başarısızsa sıfırdan farklı çıkış `:1347-1350` | DOGRU |
| `linux/README.md` içeriğinin üst bölümle çelişmemesi | DNS: `README.md:44` ↔ `linux/README.md:93-96`; pin: `README.md:48` ↔ `linux/README.md:107-108`; IPv6: `README.md:47` ↔ `linux/README.md:102-103`; sandbox: `README.md:45` ↔ `linux/README.md:97-99` | DOGRU |

## 9. Denetim sırasında çıkan ek tutarsızlıklar (düzeltme YAPILMADI, yalnız kayıt)

| # | Bulgu | Kanıt (dosya:satır) | Sonuç |
|---|---|---|---|
| E1 | 6 betiğin başı yorumu "DNS degistirilmez" diyor, ama varsayılan DNS politikası tüm yöntemlerde `yandex` | yorumlar: `linux/scripts/turkey_dnsredir_alternative_superonline.sh:3`, `..._alternative2_...:3`, `..._alternative6_...:3` ve servis karşılıklarının satır 3'ü ↔ davranış: `linux/scripts/_lib.sh:279-280`, `:313-314`; `linux/README.md:45` "hepsi Yandex zorlar" | YANLIS (kod yorumu bayat; kullanıcı metni değil) |
| E2 | `CIADPI_HOST` override edilemiyor olması `linux/README.md`'de de aynı biçimde anlatılıyor | `linux/README.md:100` ↔ `linux/scripts/_lib.sh:21, 74` | EKSIK |
| E3 | Rozet "Platform: Windows | macOS" diyor; Linux bölümü var | `README.md:2` ↔ `README.md:10, 12` | EKSIK |
| E4 | `build.sh` derleyiciyi `cc` olarak kontrol ediyor, üst README `gcc` diyor (yukarıda §3'te sayıldı) | `linux/build.sh:42` ↔ `README.md:18` | EKSIK |
| E5 | `README.md:26`'daki hata metni alıntılanan sözcüklerle birebir aynı değil | `README.md:26` ("terminal gereklidir") ↔ `linux/scripts/_lib.sh:216` ("terminal (TTY) yok") | DOGRU (anlam aynı) |

---

## Sonuç sayımı (yukarıdaki 9 tablo, madde başına)

| Sonuç | Adet |
|---|---|
| DOGRU | 47 |
| YANLIS | 1 |
| EKSIK | 23 |
| DOGRULANMADI | 1 |
| **Toplam satır** | **72** |

Bölüm dağılımı: §1=7 · §2=6 · §3=7 · §4=6 · §5=10 · §6=9 · §7=13 · §8=9 · §9=5 (= 72).

Sayım bu dosya üzerinde yeniden üretilebilir:

```sh
awk -F'|' '/^\|/ && NF>=4 { v=$(NF-1); gsub(/^[ \t]+|[ \t]+$/,"",v)
  if (v ~ /^DOGRULANMADI/) d++; else if (v ~ /^YANLIS/) y++; else if (v ~ /^EKSIK/) e++
  else if (v ~ /^DOGRU/) g++ } END { print g+0, y+0, e+0, d+0, g+y+e+d }' \
  docs/plans/2026-10-27-readme-linux-denetim.md   # → 47 1 23 1 72
```

Öne çıkan üç gerçek sorun:
1. **`CIADPI_HOST` bir ayar gibi sunuluyor** (`README.md:46`, `linux/README.md:100`) ama `_lib.sh:21` koşulsuz atıyor, sudo beyaz listesinde (`_lib.sh:74`) yok → dışarıdan verilen değer etkisiz. Doğru override yolu `GOODBYEDPI_ARGS` ile `--ip`.
2. **6 betiğin başı yorumu "DNS degistirilmez" diyor**, kod varsayılan olarak Yandex DNS'i zorluyor (`_lib.sh:279-280`). Yorumlar güncellenmeli (kullanıcıya görünmeyen metin).
3. Üst README'nin Linux bölümü **şeffaf mod açılışını, `DRY_RUN`, `GOODBYEDPI_ARGS`, `make check`/`make test` ve sorun giderme başlıklarını** hiç anlatmıyor; hepsi `linux/README.md`'de var (link veriliyor: `README.md:40`).

## Çalıştırılan komutlar ve çıkış kodları

| Komut | Çıkış |
|---|---|
| `bash -n linux/build.sh linux/scripts/*.sh` | `0` (17 dosya: `build.sh` + 16 betik) |
| `ls -1 linux/scripts/turkey_dnsredir*.sh \| wc -l` | `0` → `7` |
| `ls -1 linux/scripts/service_*.sh \| wc -l` | `0` → `8` |
| `grep -rn "GOODBYEDPI_DNS" linux/ \| wc -l` | `0` → `23` |
| `grep -n "goodbyedpi-turkey" linux/systemd/goodbyedpi-turkey.service.template` | `1` (eşleşme yok — ad dosya adından gelir) |
| `git check-ignore -v linux/bin/ciadpi` | `0` → `.gitignore:9:linux/bin/` |
| `git diff --name-only` | `0` → boş (hiçbir izlenen dosya değişmedi) |
| `git status --short` | `0` → 3 satır: bu rapor + paralel worker'lara ait 2 dosya (aşağıya bkz.) |

Çalıştırılmayan şeyler: `linux/scripts/*.sh`, `linux/build.sh`, `make build`, `make check`, `make test` (tuzak: root ister / sistem ayarı değiştirir / ağ indirir). Bu nedenle **çalışma zamanına** dair hiçbir iddia doğrulanmadı; tüm DOGRU sonuçları `bash -n` + grep + dosya okumaya dayanır.

## Dokunulmayanlar

`README.md`, `linux/**`, `docs/plans/README.md` değişmedi (`git diff --name-only` boş). `git add` / `commit` / `push` yok.

`git status --short` çıktısı (bu worker yalnız birinci dosyayı üretti): `?? docs/plans/2026-10-27-readme-linux-denetim.md` (bu rapor) ve paralel worker'lara ait `?? docs/plans/2026-10-27-readme-denetim.md`, `?? docs/plans/2026-10-27-readme-windows-denetim.md`. Görev başlangıcında `git status --short` boştu; diğer iki dosya bu oturumda başka worker'lardan geldi, bu worker onlara dokunmadı.
