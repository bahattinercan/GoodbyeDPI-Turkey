# GoodbyeDPI-Turkey

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#bu-fork-nedir)
[![Downloads](https://img.shields.io/github/downloads/bahattinercan/GoodbyeDPI-Turkey/total.svg)](https://github.com/bahattinercan/GoodbyeDPI-Turkey/releases)

## Bu fork nedir?

Bu depo, Türkiye'de bazı internet servis sağlayıcılarının (ISS) DNS değişikliğini
engellemesi ve belirli sitelere erişimi kısıtlaması nedeniyle, asıl proje
[GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI)'ın düzenlenmiş bir sürümüdür.
Amaç Discord ve benzeri engelli site/uygulamalara VPN'siz, hız kaybı olmadan
girebilmektir. Yazılım, ISS ağlarındaki "Derin Paket İnceleme" (DPI) sistemlerini
atlatır: optik ayırıcı veya port yansıtma ile çalışan pasif DPI'yi ve sıralı
bağlanan aktif DPI'yi işler. **VPN değildir:** trafiğiniz başka bir ülkeye
taşınmaz, oyunlarda ve genel kullanımda hız değişikliği yaratmaz.

Platform başına motor farklıdır, çünkü Windows'un WinDivert çekirdek sürücüsünün
Linux ve macOS'ta karşılığı yoktur:

| Platform | Motor | Durum | Ayrıntılı belge |
|---|---|---|---|
| Windows | GoodbyeDPI + WinDivert çekirdek sürücüsü | Birincil hedef | bu belge |
| Linux | byedpi (`ciadpi`), kullanıcı alanında SOCKS5 proxy | Port | [linux/README.md](linux/README.md) |
| macOS | byedpi (`ciadpi`), kullanıcı alanında SOCKS5 proxy | Port | [macos/README.md](macos/README.md) |

## İçindekiler

- [Hızlı başlangıç](#hızlı-başlangıç)
- [Dosyaları indirme](#dosyaları-indirme)
- [Windows](#windows)
- [Linux](#linux)
- [macOS](#macos)
- [Güvenlik ve güven](#güvenlik-ve-güven)
- [Kaynaktan derleme ve CI](#kaynaktan-derleme-ve-ci)
- [Proje yapısı](#proje-yapısı)
- [Katkı ve lisans](#katkı-ve-lisans)
- [Bağış ve destek](#bağış-ve-destek)
- [Yasal uyarı](#yasal-uyarı)
- [Ek: tarihli notlar](#ek-tarihli-notlar)

## Hızlı başlangıç

| Platform | En kısa yol | Ön koşul |
|---|---|---|
| Windows | ZIP'i bir klasöre çıkar, `service_install_dnsredir_turkey.cmd` dosyasına sağ tık → **Yönetici Olarak Çalıştır** | Yönetici yetkisi |
| Linux | `cd linux && ./build.sh` ardından `sudo ./scripts/turkey_dnsredir.sh` | `sudo` ve gerçek terminal |
| macOS | `./macos/build.sh` ardından `sudo ./macos/scripts/turkey_dnsredir.sh` | Xcode Command Line Tools, `sudo` |

> [!IMPORTANT]
> Windows'ta yönetici yetkisi, Linux/macOS'ta root yetkisi zorunludur. Linux ve
> macOS betikleri `sudo` şifresini yalnızca gerçek bir terminal penceresinde
> sorabilir; ayrıntı ve tuzaklar için [Yönetici ve root yetkisi](#yönetici-ve-root-yetkisi)
> bölümünü okuyun.

## Dosyaları indirme

Bu forkun kendi sürümleri **en son sürüm** sayfasında yayınlanır:

<https://github.com/bahattinercan/GoodbyeDPI-Turkey/releases/latest>

| Paket | Platform | İçerik |
|---|---|---|
| `goodbyedpi-<sürüm>.zip` | Windows x86_64 | `goodbyedpi.exe`, WinDivert (x64), `windows/*.cmd`, `README-BEN OKU.txt`, `README.md`, `REVERT.md`, `LICENSE`, `SHA256SUMS` |
| `goodbyedpi-<sürüm>-x86.zip` | Windows 32-bit | aynı düzen, WinDivert x86 |
| `goodbyedpi-<sürüm>-linux.tar.gz` | Linux | `linux/` portu (`build.sh`, `Makefile`, `scripts/`, `systemd/`, `tests/`, `README.md`) ve kök `README.md`, `REVERT.md`, `LICENSE`; derlenmiş `ciadpi` **yoktur** |
| `goodbyedpi-<sürüm>-macos-arm64.tar.gz` | macOS Apple Silicon | `bin/ciadpi`, `scripts/`, `launchd/…plist.template`, `README.md` |
| `goodbyedpi-<sürüm>-macos-x86_64.tar.gz` | macOS Intel | aynı içerik, Intel derlemesi |
| `SHA256SUMS` | — | Yukarıdaki paketlerin SHA256 özeti |

> [!NOTE]
> macOS Apple Silicon (`arm64`) paketi, GitHub'ın arm64 runner kapasitesi
> nedeniyle bazı sürümlerde yer almayabilir. Her sürümde hangi paketlerin
> yayınlandığı o sürümün release notlarında belirtilir.

> [!NOTE]
> Bu paketler CI'da (GitHub Actions) üretilir: `release-*` etiketi
> gönderildiğinde Windows ve macOS derlemeleri paketlenir ve GitHub Release'e
> eklenir. Paket adlarındaki `<sürüm>` etiket adından gelir; bu dosya sabit bir
> sürüm numarası içermez. Yayın akışı
> [Kaynaktan derleme ve CI](#kaynaktan-derleme-ve-ci) bölümündedir.

İndirdiğiniz paketi `SHA256SUMS` ile doğrulayabilirsiniz:

```bash
sha256sum -c SHA256SUMS
```

Windows'ta tek bir dosyayı doğrulamak için yönetici komut isteminde
`certutil -hashfile <dosya> SHA256` çalıştırın.

## Windows

### Windows gereksinimleri

Windows 7, 8, 8.1, 10 veya 11. Tüm adımlar **yönetici olarak** çalıştırılmalıdır.
ZIP'i çıkardığınız klasörü sonradan taşımayın.

### Hizmet kurarak kullanma

Hizmet bir kez kurulur ve bilgisayar her açıldığında otomatik başlar.

1. ZIP dosyasını bilgisayarınıza indirin ([Dosyaları indirme](#dosyaları-indirme)).
2. ZIP'i herhangi bir dizine çıkarın.
3. `service_install_dnsredir_turkey.cmd` dosyasına sağ tık → **Yönetici Olarak Çalıştır**.
4. Açılan konsolda herhangi bir tuşa basın.
5. Pencere, hizmet kurulduğunda kapanır ve hizmet otomatik başlar.

> [!NOTE]
> Kaldırmak için aynı klasördeki `service_remove.cmd` dosyasını yönetici olarak
> çalıştırın. Kaldırma ve DNS geri alma adımları [Kaldırma](#kaldırma)
> bölümündedir.

### Batch dosyası ile kullanma

Tek seferlik kullanım: pencere kapatıldığında koruma sona erer.

1. ZIP dosyasını indirip bir dizine çıkarın.
2. `turkey_dnsredir.cmd` dosyasına sağ tık → **Yönetici Olarak Çalıştır**.

> [!NOTE]
> `turkey_dnsredir.cmd` betiği `goodbyedpi.exe` için **ikinci bir konsol
> penceresi** açar ve kendisi hemen kapanır. Koruma, `goodbyedpi.exe`
> penceresi kapatıldığında sona erer. Bu yöntemde bilgisayarı yeniden
> başlattığınızda korumayı elle yeniden açmanız gerekir.

### Klasör düzeni ve taşıma

- ZIP'in içinde mimariye göre `x86\` ve `x86_64\` alt klasörleri bulunur; her
  birinde `goodbyedpi.exe` ve WinDivert dosyaları vardır. Betikler çalıştıkları
  mimariye göre doğru alt klasöre girer, alt klasörleri ayırmayın.
- ZIP'i çıkardığınız konumdan taşımayın: kurulan hizmet, `.cmd` dosyasını
  çalıştırdığınız yolu kullanır, dosyaları taşırsanız hizmet çalışmaz.
  Rahatsız olmayacağınız bir konum seçin, örneğin `C:\GoodbyeDPI\`.
- Yönetici kontrolü: hizmet betikleri `_require_admin.cmd` yardımcı betiğini
  çağırır ve yönetici değilseniz uyarıp çıkar. Tek seferlik `turkey_dnsredir*.cmd`
  betiklerinde bu kontrol yoktur; onları yönetici olarak sizin başlatmanız
  gerekir.
- Klasör izinleri ve hizmetin çalıştığı hesap için
  [Kurulum klasörü ve izinler](#kurulum-klasörü-ve-izinler) bölümüne bakın.
- ZIP içindeki ikinci kullanıcı belgesi: [windows/README-BEN OKU.txt](windows/README-BEN%20OKU.txt).

### DNS ve port düzenleme

Ön ayarların bir kısmı Yandex DNS'i (`77.88.8.8` / `77.88.8.1`) sabit olarak
kullanır. Somut durum: `windows/` altındaki **16 betikten 8'i** `--dns-addr
77.88.8.8` taşır; bu, **7 ön ayarın 4'üne** denk gelir (varsayılan yöntem ve
alternatif 3, 4, 5 — hem tek seferlik hem hizmet betiği). Alternatif 1, 2 ve
6'da ön ayarlı DNS yoktur.

- DNS'i değiştirmek için ilgili `.cmd` dosyasındaki `--dns-addr 77.88.8.8
  --dns-port 1253` kısmını (ve varsa `--dnsv6-addr` / `--dnsv6-port`
  karşılığını) düzenleyin veya silin.
- Alternatif 1, 2 ve 6 kullanacaksanız DNS'i Windows ayarlarından değiştirin:
  [Windows 10 için](https://www.ipsorgu.com/windows_10_dns_degistirme.php),
  [Windows 11 için](https://www.ipsorgu.com/windows_11_dns_degistirme.php).
- Önerilen çözümleyiciler: Yandex DNS `77.88.8.8` / `77.88.8.1`, Cloudflare DNS
  `1.1.1.1` / `1.0.0.1`.
- Yandex DNS'in gizlilik ve MITM riski [Yandex DNS](#yandex-dns) bölümündedir.

Ön ayarların tamamı:

| Ön ayar (dosya adı soneki) | Yöntem numarası | `goodbyedpi.exe` argümanları | Ön ayarlı DNS |
|---|---|---|---|
| `turkey_dnsredir` | varsayılan | `-5 --set-ttl 5 --dns-addr …` | Yandex |
| `…_alternative_superonline` | Metod 1 | `--set-ttl 3` | yok |
| `…_alternative2_superonline` | Metod 2 | `-5` | yok |
| `…_alternative3_superonline` | Metod 3 | `--set-ttl 3 --dns-addr …` | Yandex |
| `…_alternative4_superonline` | Metod 4 | `-5 --dns-addr …` | Yandex |
| `…_alternative5_superonline` | Metod 5 | `-9 --dns-addr …` | Yandex |
| `…_alternative6_superonline` | Metod 6 | `-9` | yok |

### SuperOnline alternatif yöntemleri

SuperOnline Fiber kullanıyorsanız ve "Discord update failed - retrying in **
seconds" hatası alıyorsanız aşağıdaki sırayı deneyin.

**1- Alternatif CMD dosyaları**

> [!NOTE]
> Daha önce başka bir hizmet kurduysanız önce `service_remove.cmd` ile onu
> kaldırın, sonra aşağıdaki adımları uygulayın.

- Aşağıdaki dosya adlarında numarasız olan **Metod 1**'dir; `2`…`6` sonekleri
  Metod 2…6'yı verir:
  `turkey_dnsredir_alternative_superonline.cmd`,
  `turkey_dnsredir_alternative2_superonline.cmd` … `turkey_dnsredir_alternative6_superonline.cmd`.
  Hizmet kurmak için aynı desenin `service_install_dnsredir_turkey_…` ile
  başlayan karşılıklarını kullanın. Hepsi sağ tık → **Yönetici Olarak Çalıştır**
  ile başlatılır; pencere açıldığında bir tuşa basın.
- Ardından Windows DNS ayarınızı değiştirin (yukarıdaki
  [DNS ve port düzenleme](#dns-ve-port-düzenleme) bölümü).
- Bilgisayarı yeniden başlatın.

**2- VPN ile kaba kuvvet**

Hizmeti kurduktan sonra herhangi bir Windows VPN'i açıp Discord'u başlatın.
Discord açıldıktan sonra VPN'i kapatın ve kullanmaya devam edin.

**3- Benzer programlar**

SecureDNSClient veya Zapret isimli programları da deneyebilirsiniz (bu forkun
kapsamında değildir; rehberleri için kendi belgelerine bakın).

### WinDivert dosyalarını silmek

WinDivert dosyalarını silmeye çalıştığınızda "dosya kullanımda" hatası alırsanız
önce `service_remove.cmd` dosyasını yönetici olarak çalıştırın, sonra silin.
WinDivert açık kaynaklıdır: [WinDivert 2.2: Windows Packet Divert](https://github.com/basil00/WinDivert).

### Kaldırma

GoodbyeDPI'ı tamamen kapatmak, hizmeti ve dosyalarını silmek ve DNS atamasını
geri almak için [REVERT.md](REVERT.md) rehberini izleyin. macOS tarafının
kaldırılması da aynı rehberde anlatılır; Linux için
[Servis olarak kullanma](#servis-olarak-kullanma) bölümündeki
`service_remove.sh` adımını kullanın.

### Sorun giderme

**"WinDivert dosyaları bulunamadı" hatası (yanlış virüs algılaması):**
Antivirüsünüze ZIP'i çıkardığınız klasörü istisna olarak ekleyin. Windows
Defender için [bu rehberi](https://support.microsoft.com/tr-tr/windows/windows-g%C3%BCvenli%C4%9Fi-ne-d%C4%B1%C5%9Flama-ekleme-811816c0-4dfd-af4a-47e4-c301afe13b26),
Kaspersky için [bu rehberi](https://support.kaspersky.com/ksos/8.5/tr-TR/227390.htm)
izleyin. İstisna eklemek sorunu çözmüyorsa Kaspersky'yi tamamen kaldırmanız
gerekebilir; ayrıntı [Antivirüs ve Kaspersky](#antivirüs-ve-kaspersky).

**Hizmet başlatılırken "Dosya yolu bulunamadı" hatası:**
ZIP'i çıkardığınız konumdan taşıdıysanız ya da bazı dosyaları sildiyseniz oluşur.
ZIP'i yeniden bir konuma çıkarın, önce `service_remove.cmd` dosyasını yönetici
olarak çalıştırın, sonra seçtiğiniz `.cmd` dosyasını tekrar çalıştırın.

**Bazı siteler yavaş açılıyor veya hiç açılmıyor:**
Bu sorun TTL ayarı içeren yöntemlerde görülür. TTL kullanmayan yöntemler
**alternatif 5 ve 6**'dır (`-9` ön ayarı; alternatif 2 ve 4 ise `-5` içindeki
`--auto-ttl` nedeniyle TTL kullanır). Başka bir betikle kurulum yaptıysanız
önce `service_remove.cmd` dosyasını yönetici olarak çalıştırın, sonra
`service_install_dnsredir_turkey_alternative5_superonline.cmd` veya
`service_install_dnsredir_turkey_alternative6_superonline.cmd` dosyasını
yönetici olarak çalıştırıp talimatları izleyin.

**Discord web'de açılıyor ama uygulama açılmıyor:**
Genellikle fiber tarifelerde görülür ve kesin bir çözümü yoktur. Denenebilecek
yol: [WinDivertTool.exe](https://github.com/basil00/WinDivertTool/releases/download/v2.2.0/WinDivertTool.exe)
tanı aracını indirip çalıştırın; konsolun altındaki listede WinDivert kullanan
uygulamaları görürsünüz. Birden fazla varsa, en son kurduğunuz konumdaki hariç
diğerlerini silin ve bilgisayarı yeniden başlatın.

**Ethernet bağlantısı sorunu:**
İnternete ethernet adaptörüyle bağlanıyorsanız ve tüm yöntemleri denediyseniz,
**harmanprecious** kullanıcısının [şu rehberine](https://www.technopat.net/sosyal/konu/goodbyedpi-ethernet-kartiyla-calismiyorsa-ne-yapilmali.3619948/)
bakabilirsiniz.

## Linux

Linux tarafı `linux/` dizinindedir. WinDivert sürücüsünün Linux'ta karşılığı
olmadığı için bu port, kullanıcı alanında çalışan **byedpi (`ciadpi`)** SOCKS5
proxy'sini ve Linux'a özgü `--fake`, `--md5sig`, `--disorder` tekniklerini
kullanır. VPN değildir: trafik başka ülkeye taşınmaz, paketler yerel proxy
üzerinden yeniden düzenlenir. Yöntem tablosu ve şeffaf mod için
[linux/README.md](linux/README.md).

### Linux gereksinimleri

- Linux + `systemd` (yalnız servis modu için gerekir).
- Derleme için `git`, `make` ve bir C derleyicisi (`cc` / `gcc`).
- `sudo` yetkisi ve gerçek bir terminal.
- Şeffaf mod için `iptables` **veya** `nft`; DNS için `systemd-resolved`
  (`resolvectl`) önerilir, yoksa `/etc/resolv.conf` kullanılır.

### Derleme

```bash
cd linux
./build.sh                 # ya da: make build
```

Çıktı: `linux/bin/ciadpi`. `build.sh` byedpi kaynağını `linux/third_party/byedpi`
altına klonlar ve belirli bir commit'e (`BYEDPI_COMMIT`) sabitler. Pini
güncellemek için önce `BYEDPI_ALLOW_UNPINNED=1 ./build.sh` ile derleyin, sonra
yeni SHA'yı `linux/build.sh` içine yazın.

### Tek seferlik kullanım

```bash
cd linux
sudo ./scripts/turkey_dnsredir.sh                                  # varsayılan yöntem
sudo ./scripts/turkey_dnsredir_alternative_superonline.sh          # Metod 1
sudo ./scripts/turkey_dnsredir_alternative2_superonline.sh         # Metod 2
sudo ./scripts/turkey_dnsredir_alternative6_superonline.sh         # Metod 6
```

Numarasız `alternative` dosyası Metod 1'dir; `alternative2` … `alternative6`
Metod 2…6'yı verir. Tüm koşucular `linux/scripts/` altındadır. Ctrl-C ile
durduğunuzda ağ ayarları otomatik geri döner.

- Önizleme: `DRY_RUN=1 ./scripts/turkey_dnsredir.sh` hiçbir sistem komutunu
  çalıştırmaz, yalnızca ne yapacağını yazar.
- Argümanları ezmek: `sudo GOODBYEDPI_ARGS='--split 1+s --disorder 3+s' ./scripts/turkey_dnsredir.sh`.
- Şeffaf mod: `sudo GOODBYEDPI_PROXY_MODE=transparent ./scripts/turkey_dnsredir.sh`.

### Servis olarak kullanma

```bash
sudo ./scripts/service_install_dnsredir_turkey.sh     # kur
systemctl status goodbyedpi-turkey                    # durum
journalctl -u goodbyedpi-turkey -f                    # günlük
sudo ./scripts/service_remove.sh                      # kaldır
```

Hizmet dosyası `/etc/systemd/system/goodbyedpi-turkey.service`, şablonu
`linux/systemd/goodbyedpi-turkey.service.template`. Varsayılan dinleme adresi
`127.0.0.1:1080`. Alternatif yöntemler için `service_install_dnsredir_turkey_alternative*_superonline.sh`
betikleri vardır.

### Kalıntı kontrolü ve sorun giderme

```bash
systemctl is-active goodbyedpi-turkey
pgrep -a ciadpi
gsettings get org.gnome.system.proxy mode
resolvectl dns <arayüz>
```

Takıldığınızda `sudo ./scripts/service_remove.sh` ile temizleyip yeniden
deneyin. Şeffaf modda kalan kurallar için `linux/README.md` içindeki
`iptables` / `nft` temizleme komutlarına bakın.

### Doğrulama ve testler

```bash
cd linux
make check                 # bash -n ile tüm betiklerin sözdizimi
make test                  # stub testleri, root gerekmez
```

Test dosyaları `linux/tests/static-checks.sh` ve `linux/tests/lib-test.sh`
altındadır. Bu depoda Linux tarafı yalnızca bu iki kapıyla doğrulanmıştır;
gerçek DPI atlatma davranışı ISS'ye ve ağa bağlıdır.

### Güvenlik notları (Linux)

- DNS varsayılan olarak Yandex'e (`77.88.8.8` / `77.88.8.1`) zorlanır. Kapatmak
  için `GOODBYEDPI_DNS=off`, eski yöntem tablosu davranışı için
  `GOODBYEDPI_DNS=legacy` kullanın. Gizlilik gerekçesi
  [Yandex DNS](#yandex-dns) bölümünde.
- Süreç root olarak çalışır ve `--fake`, `--md5sig` için `CAP_NET_RAW` ile ham
  soket kullanır. systemd unit'i sandbox anahtarlarıyla (`NoNewPrivileges`,
  `ProtectSystem=strict`, `RestrictAddressFamilies`) sınırlıdır; tek seferlik
  modda bu sınır yoktur.
- `CIADPI_HOST` bir ortam değişkeni **değildir**: `linux/scripts/_lib.sh`
  değeri koşulsuz `127.0.0.1` yapar ve sudo beyaz listesinde yer almaz. Proxy'yi
  başka adrese açmak için `GOODBYEDPI_ARGS` içine `--ip` yazın. Proxy'yi tüm
  ağa açmak (`0.0.0.0`) önerilmez.
- Şeffaf modda IPv6 desteği `ip6tables` / `nft ip6` varlığına bağlıdır; yoksa
  yalnız IPv4 kuralı kurulur ve IPv6 sızıntısı olabilir.
- Kalıntı bırakmamak için işiniz bittiğinde `sudo ./scripts/service_remove.sh`
  çalıştırın.

## macOS

macOS'ta WinDivert sürücüsü olmadığı için Windows kodu aynen çalışmaz. Bu port,
aynı DPI atlatma tekniklerini kullanan ama kullanıcı alanında SOCKS5 proxy olarak
çalışan **byedpi (`ciadpi`)** aracını sarmalar. Ayrıntılı eşleme ve sorun giderme
için [macos/README.md](macos/README.md).

### macOS gereksinimleri

macOS 12 (Monterey) veya üstü, Intel veya Apple Silicon, Xcode Command Line
Tools (`xcode-select --install`) ve `sudo` yetkisi.

### Kurulum

```bash
git clone https://github.com/bahattinercan/GoodbyeDPI-Turkey.git
cd GoodbyeDPI-Turkey
./macos/build.sh           # byedpi'yi klonlar, ciadpi'yi derler
```

Çıktı: `macos/bin/ciadpi`.

### Kullanım

```bash
sudo ./macos/scripts/turkey_dnsredir.sh                       # tek seferlik
sudo ./macos/scripts/service_install_dnsredir_turkey.sh       # hizmet kur
sudo ./macos/scripts/service_remove.sh                        # kaldır
```

- Hizmet durumu: `sudo launchctl print system/com.cagritaskn.goodbyedpi-turkey`,
  günlük: `tail -f /var/log/goodbyedpi-turkey.log`.
- Alternatif yöntemler: `turkey_dnsredir_alternative*_superonline.sh` (numarasız
  olan Metod 1) ve `service_install_dnsredir_turkey_alternative*_superonline.sh`.
- Tek seferlik modda Ctrl-C ile çıktığınızda proxy ve DNS ayarları otomatik
  geri alınır.

### Split tunnel

Hizmet betikleri sistem geneli SOCKS proxy kurar, yani tüm TLS trafiği
desync'ten geçer; bazı siteler bölünmüş ClientHello'yu reddeder. `split_tunnel.sh`
sistem geneli SOCKS ayarını bir PAC dosyasıyla değiştirir; yalnızca
`macos/split-tunnel-domains.txt` içindeki alan adları `ciadpi`'ye gider:

```bash
sudo ./macos/scripts/split_tunnel.sh on        # PAC'a geç
sudo ./macos/scripts/split_tunnel.sh status    # mevcut durum
sudo ./macos/scripts/split_tunnel.sh off       # sistem geneli SOCKS'a dön
```

Domain listesi ilk çalıştırmada `/usr/local/etc/goodbyedpi-turkey/` altına
kopyalanır; orada düzenleyip `on` komutunu tekrar çalıştırın.

### macOS'ta ne çalışır, ne çalışmaz

- Çalışır: TLS ClientHello bölme (`--split`), ters sıralı segment gönderme
  (`--disorder`), TLS kayıt bölme (`--tlsrec`), OOB byte (`--oob`), HTTP başlık
  karıştırma (`--mod-http`).
- Çalışmaz: Windows'un "sahte paket + düşük TTL" hilesi (`--set-ttl`,
  `--auto-ttl`, `--fake-from-hex`) byedpi'da macOS için desteklenmez; yerine
  yukarıdaki tekniklerin daha agresif kombinasyonları kullanılır.

### Güvenlik notları (macOS)

- Betikler root ister ve sistem geneli proxy/DNS ayarlarını değiştirir; çıkışta
  ya da `service_remove.sh` ile geri alınır.
- Hizmet bir LaunchDaemon olarak kurulur (`/Library/LaunchDaemons/com.cagritaskn.goodbyedpi-turkey.plist`).
- DNS varsayılan yöntemde Yandex'e ayarlanır; gerekçe ve riskler
  [Yandex DNS](#yandex-dns) bölümünde.

## Güvenlik ve güven

Bu bölüm, platformlar arasında ortak olan güvenlik konularını tek yerde toplar.

### Yönetici ve root yetkisi

- **Windows:** Tüm adımlar **yönetici olarak** çalıştırılmalıdır; hizmet
  `LocalSystem` hesabıyla çalışır.
- **Linux / macOS:** Betikler root ister ve `sudo` şifresi **yalnızca gerçek bir
  terminal penceresinde** sorulabilir. Komutu Orca, IDE veya ajan terminalinden
  çalıştırırsanız "terminal (TTY) yok" hatası alırsınız. Üst üste 3 hatalı
  denemede hesap `pam_faillock` ile yaklaşık 10 dakika kilitlenir
  (`faillock --user <kullanıcı> --reset` ile açılır).
- Doğru sıra: gerçek bir terminal açın, proje dizinine gidin, `sudo -v` ile
  şifreyi bir kez girin, sonra komutu çalıştırın.

### Antivirüs ve Kaspersky

Program açık kaynak olduğu için tüm kodu inceleyebilirsiniz. VirusTotal'de
görülen uyarılar `WinDivert.dll` ve `WinDivert64.sys` dosyalarının işlevlerinden
kaynaklanan yanlış pozitiflerdir; bu dosyalar da açık kaynaklıdır ve
incelenebilir. Tüm klasörü veya ZIP'i [VirusTotal](https://www.virustotal.com/gui/home/upload)
gibi bir sitede taratıp sonuçları kendiniz görebilirsiniz.

[VirusTotal sonuçlarında](https://www.virustotal.com/gui/file/3ca863444ce065361b1152e1dddae1147962fc78b90c17ff346efbb35bd146ee)
73 antivirüs programı içinde (bağlantıdaki sayfada 66 program görünür, çünkü
bazıları `.zip` dosyalarını çevrimiçi taramayı desteklemez) yazılımı zararlı
işaretleyen tek ürün Kaspersky'dir; bu hatalı bir uyarıdır.

> [!CAUTION]
> Kaspersky antivirüs yazılımı, Rus hükümetiyle olan anlaşması nedeniyle
> GoodbyeDPI'ın çalışmasına engel olur. Kaspersky'yi kullanıyor, kullandıysanız
> ya da devre dışı olsa bile sisteminizde bulunduruyorsanız tamamen kaldırın;
> aksi halde GoodbyeDPI büyük olasılıkla çalışmayacaktır. Yerine başka bir
> antivirüs ya da Windows Defender kullanabilirsiniz (Windows Defender 2025
> itibariyle kötü amaçlı yazılım ve siteleri engellemekte yeterlidir).

> [!NOTE]
> Kaspersky'yi ZIP indirirken devre dışı bırakmak, indirdikten sonra dışlamalara
> eklemek veya geçici olarak kapatmak sorunu çözmez. GoodbyeDPI'ı doğru
> kullanabilmek için Kaspersky'den tamamen kurtulmanız gerekir.

### Yandex DNS

Ön ayarların bir bölümü DNS'i Yandex'e (`77.88.8.8` / `77.88.8.1`) zorlar
(hangi dosyalar: [DNS ve port düzenleme](#dns-ve-port-düzenleme)). Yandex
üçüncü taraf bir çözümleyicidir ve DNS sorguları şifresiz (düz metin) gider;
bu yüzden MITM'e açıktır.

- Windows: ilgili `.cmd` dosyasından `--dns-addr` satırını silin veya kendi
  çözümleyicinizi yazın.
- Linux: `GOODBYEDPI_DNS=off` ile DNS'e hiç dokunulmaz, `GOODBYEDPI_DNS=legacy`
  ile eski yöntem tablosu davranışı kullanılır.
- macOS: split tunnel modunda da DNS gerekir, çünkü ISS çözümleyicisi engelli
  alan adlarını yanlış IP'ye çözebilir.

### WinDivert ve Bitcoin adresi

WinDivert dosyalarının açıklamalarında ya da silmeye çalışırken karşılaşacağınız
Bitcoin adresi sizi korkutmasın. WinDivert, açık kaynaklı bir Windows paket
inceleme/değiştirme kütüphanesidir; sahibi [basil00](https://github.com/basil00)
isimli geliştiricidir ve kütüphaneyi [GitHub - WinDivert](https://github.com/basil00/WinDivert)
deposunda ücretsiz paylaşır. Geliştirici bu kütüphaneden gelir elde etmiyor ama
bağış kabul ediyor; `.dll` ve `.sys` açıklamalarındaki Bitcoin adresi basil00'a
ait bağış cüzdanıdır. Aynı adres resmi sitesindeki
[bağış sayfasında](https://reqrypt.org/donate.html) da yer alır.

### Bütünlük doğrulama

Bu fork kendi sürümlerini yayınlar ve her paket SHA256 özeti taşır. Her Windows
ZIP'inin kökünde bir `SHA256SUMS` dosyası bulunur; bu dosya arşivin içindeki
dosyaları düz adlarıyla listeler. Ayrıca release sayfasında, yayınlanan tüm
paketleri kapsayan ayrı bir `SHA256SUMS` asset'i yer alır.

- Paketi ve `SHA256SUMS` asset'ini release sayfasından indirip aynı klasöre
  koyun.
- Linux/macOS: paketin bulunduğu klasörde `sha256sum -c SHA256SUMS`
  çalıştırın; her satır `OK` demelidir (macOS'ta `sha256sum` coreutils ile
  gelir).
- Windows: ZIP'i çıkardığınız klasördeki `SHA256SUMS` arşiv içeriğini doğrular.
  Yalnızca `.exe` denetlemek isterseniz yönetici komut isteminde
  `certutil -hashfile goodbyedpi.exe SHA256` çalıştırın ve çıktıyı ZIP içindeki
  `SHA256SUMS` satırıyla karşılaştırın.
- Release sayfasındaki `SHA256SUMS` beş paketin tümünü kapsar; ZIP içindeki
  dosya ise yalnızca o arşivin içeriğini doğrular.

### Kurulum klasörü ve izinler

- ZIP'i yönetici-yazılabilir bir klasöre çıkarın (örneğin
  `C:\Program Files\GoodbyeDPI`). İndirilenler veya Masaüstü gibi
  kullanıcı-yazılabilir konumlardan hizmet kurmayın: hizmet `LocalSystem`
  hesabıyla çalıştığı için `goodbyedpi.exe` dosyasını sonradan değiştirebilen
  herkes SYSTEM yetkisi elde eder.
- Klasör izinlerini sıkılaştırmak için yönetici komut isteminde:
  `icacls "C:\Program Files\GoodbyeDPI" /inheritance:r /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "Users:(OI)(CI)RX"`
  komutunu çalıştırın; kalıtımı kapatır, yalnızca yönetici, SYSTEM ve
  okuma-yürütme izni bırakır.
- `WinDivert.dll` ve `WinDivert64.sys` aynı klasörden yüklendiği için klasör
  yazılabilir olmamalıdır.
- Antivirüs kullanıyorsanız programı kaldırmak yerine GoodbyeDPI klasörünü
  istisnaya ekleyin ve dosya hash'ini doğrulayın.

### Proxy ve ağ maruziyeti

- Windows'ta hizmet `LocalSystem` olarak çalışır; klasör izinleri yukarıdaki
  gibi kısıtlanmalıdır.
- Linux'ta proxy varsayılan olarak `127.0.0.1:1080` dinler. `CIADPI_HOST` bir
  ortam değişkeni değildir; adresi değiştirmek için `GOODBYEDPI_ARGS` içine
  `--ip` yazın ve proxy'yi tüm ağa açmaktan kaçının.
- Şeffaf modda IPv6 kuralları `ip6tables` / `nft ip6` varsa kurulur; yoksa IPv6
  sızıntısı olabilir.
- macOS'ta hizmet sistem geneli SOCKS proxy ve DNS ayarlarını değiştirir; iş
  bitince `service_remove.sh` ile geri alın.

## Kaynaktan derleme ve CI

### Windows (MinGW ve WinDivert)

`src/` altındaki kaynak, WinDivert başlıkları ve kitaplıklarıyla birlikte
MinGW-w64 ile derlenir. CI'daki adımların eşdeğeri:

1. MinGW-w64 kurun (`gcc-mingw-w64`).
2. [WinDivert 2.2.2-A](https://github.com/basil00/WinDivert/releases/download/v2.2.2/WinDivert-2.2.2-A.zip)
   arşivini indirip açın (`WinDivert-2.2.2-A/`). CI bu arşivin SHA256'sını
   doğrular.
3. Derleyin:

```bash
cd src && make clean
make CPREFIX=x86_64-w64-mingw32- BIT64=1 \
     WINDIVERTHEADERS=../WinDivert-2.2.2-A/include \
     WINDIVERTLIBS=../WinDivert-2.2.2-A/x64 -j4
```

32 bit için `CPREFIX=i686-w64-mingw32-` ve `WINDIVERTLIBS=../WinDivert-2.2.2-A/x86`
kullanın. Çıktı `src/goodbyedpi.exe`; yanına ilgili mimarinin `WinDivert.dll`
ve `.sys` dosyaları kopyalanır.

### Linux ve macOS

- Linux: `cd linux && ./build.sh` (ya da `make build`); byedpi klonlanır ve
  `ciadpi` derlenir ([Derleme](#derleme)).
- macOS: `./macos/build.sh`; Xcode Command Line Tools gerekir, çıktı
  `macos/bin/ciadpi` ([Kurulum](#kurulum)).

### CI artifact'ları

`.github/workflows/build.yml` derlemeleri çalıştırır: `ubuntu-latest` üzerinde
Windows (x86_64 ve 32-bit), `macos-15-intel` ve `macos-14` üzerinde macOS
derlemeleri. Artifact'lar 14 gün saklanır:

| Artifact adı | İçerik |
|---|---|
| `goodbyedpi_x86_64_<kısa-sha>` | `goodbyedpi.exe`, `WinDivert.dll`, `WinDivert64.sys`, `windows/*.cmd`, `README-BEN OKU.txt`, `README.md`, `REVERT.md`, `LICENSE`, `SHA256SUMS` |
| `goodbyedpi_x86_<kısa-sha>` | `goodbyedpi.exe`, `WinDivert.dll`, `WinDivert32.sys`, `WinDivert64.sys`, `windows/*.cmd`, `README-BEN OKU.txt`, `README.md`, `REVERT.md`, `LICENSE`, `SHA256SUMS` |
| `goodbyedpi-turkey_macos_arm64_<kısa-sha>` | `bin/ciadpi`, `scripts/*.sh`, `launchd/…plist.template`, `README.md` |
| `goodbyedpi-turkey_macos_x86_64_<kısa-sha>` | aynı içerik, Intel derlemesi |

Diğer iş akışları: `linux-static.yml` (Linux betikleri için `bash -n`,
`linux/tests/*` ve Makefile kontrolü) ve `shell-static.yml` (macOS betikleri
için `bash -n`, `macos/tests/static-checks.sh` ve plist şablonunun XML
doğrulaması).

### Yayın akışı (release)

Sürüm numarası workflow'a veya bu dosyaya yazılmaz; etiketten türetilir.
Yayınlamak için etiketi gönderin:

```bash
git tag release-<sürüm>
git push origin release-<sürüm>
```

`release-*` etiketi `build.yml` iş akışını tetikler. GitHub, tag push'unda
`paths` filtresini uygulamaz; bu yüzden etiket hangi dosyaları içerirse içersin
iş akışı çalışır. Windows ve macOS derlemeleri bittikten sonra `release` işi
devreye girer: artifact'ları paketlere çevirir, tüm asset'ler için tek bir
`SHA256SUMS` yazar ve `gh release create` ile GitHub Release'i oluşturur. Paket
adları ve içerikleri [Dosyaları indirme](#dosyaları-indirme) bölümündedir.

İndirdikten sonra doğrulama:

```bash
sha256sum -c SHA256SUMS
```

> [!NOTE]
> Yayın yalnızca `release-*` etiketlerinde çalışır; `workflow_dispatch` ve
> derleme amaçlı branch push'ları release oluşturmaz. Release'i oluşturan iş
> `contents: write` iznine sahiptir, derleme işleri salt okunur kalır.

## Proje yapısı

| Yol | İçerik |
|---|---|
| `src/` | Upstream GoodbyeDPI C kaynakları (WinDivert ile derlenir) |
| `windows/` | 16 `.cmd` betiği (15 başlatıcı + `_require_admin.cmd`) ve `README-BEN OKU.txt` |
| `linux/` | Linux portu: `build.sh`, `Makefile`, `scripts/`, `systemd/`, `tests/`, `README.md` |
| `macos/` | macOS portu: `build.sh`, `Makefile`, `scripts/`, `launchd/`, `tests/`, `split-tunnel-domains.txt`, `README.md` |
| `docs/plans/` | Çok adımlı işlerin plan ve denetim kayıtları |
| `.github/` | CI iş akışları ve issue şablonları |
| `REVERT.md` | Kaldırma ve DNS geri alma rehberi |
| `LICENSE` | Apache License 2.0 |

## Katkı ve lisans

- Lisans: **Apache License 2.0** ([LICENSE](LICENSE)). Upstream proje
  [ValdikSS/GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI); bu fork Türkiye
  ön ayarlarını ve Linux/macOS portlarını ekler.
- Hata bildirimi ve öneri için `.github/ISSUE_TEMPLATE/` altındaki şablonları
  kullanın.
- Değişiklik göndermeden önce yerel kapıları çalıştırın:
  `bash macos/tests/static-checks.sh` (depo kökünden) ve `cd linux && make check && make test`.
- Depo çalışma kuralları `AGENTS.md` dosyasındadır; çok adımlı işlerin kayıtları
  `docs/plans/` altında tutulur.

## Bağış ve destek

Bu programı kullanmak tamamen ücretsizdir ve kullanımından gelir elde
edilmiyor. Çalışmaların devamı için destek olabilirsiniz:

**GitHub Sponsor:**

[![Sponsor](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/cagritaskn)

**Patreon:**

[![Static Badge](https://img.shields.io/badge/cagritaskn-purple?logo=patreon&label=Patreon)](https://www.patreon.com/cagritaskn/membership)

## Yasal uyarı

> [!IMPORTANT]
> Bu uygulamanın kullanımından doğan her türlü yasal sorumluluk kullanan kişiye
> aittir. Uygulama yalnızca eğitim ve araştırma amaçlarıyla yazılmış ve
> düzenlenmiştir; bu uygulamayı bu şartlar altında kullanmak ya da kullanmamak
> kullanıcının kendi seçimidir. Açık kaynak kodlarının paylaşıldığı bu
> platformdaki düzenlenmiş proje, bilgi paylaşımı ve kodlama eğitimi amaçlarıyla
> yazılmış ve düzenlenmiştir.

## Ek: tarihli notlar

### SplitWire-Turkey hakkında (29.07.2025)

Bazı kullanıcılar Discord'a erişmekte veya diğer web sitelerindeki bazı
içeriklerin yüklenmemesinde sorun bildirdiği için, farklı metotlarla aynı işi
yapan **[SplitWire-Turkey](https://github.com/cagritaskn/SplitWire-Turkey)**
uygulaması yayınlandı. GoodbyeDPI'ı kaldırdıktan sonra
([kaldırma rehberi](REVERT.md)) bu aracı deneyebilirsiniz.

### Kaspersky hakkında (13.01.2025)

Bu tarihte eklenen not: Kaspersky antivirüsü GoodbyeDPI'ın çalışmasını
engelliyor ve tamamen kaldırılması gerekiyor. Güncel ve ayrıntılı anlatım
[Antivirüs ve Kaspersky](#antivirüs-ve-kaspersky) bölümündedir.
