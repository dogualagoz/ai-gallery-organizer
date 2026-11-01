# Değişiklik Günlüğü

Bu projedeki dikkate değer tüm değişiklikler bu dosyada tutulur.

Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) temel alınır;
sürümleme [Semantic Versioning](https://semver.org/lang/tr/) izler.
Her başlıktaki `+N` iOS build (CFBundleVersion) numarasıdır.

## [1.3.0+11] - 2026-11-02

Arayüzü baştan iOS diline taşıyan tasarım sürümü (Apple *Designing Fluid
Interfaces* ilkeleri). Free/Pro kuralları değişmedi.

### Eklenenler
- **Yeni gezinme:** `( Kütüphane | Temizle )` sekme pili + ayrık **Ara**
  sekmesi. Ayarlar Kütüphane'nin sağ üstünden sheet olarak açılır; kategori ve
  pano detayı sekme içinde açılır, kenardan geri kaydırma çalışır.
- **Fotoğraflar tarzı görüntüleyici:** koleksiyon içinde kaydırma, çift
  dokunuşla yaylı zoom, aşağı çekip kapatma; bilgi panelinde kategori
  değiştirme, etikete dokunup arama, OCR metnini kopyalama.
- **Seçim modu:** pano detayında Tümünü seç, Taşı / Paylaş / Sil araç çubuğu,
  taşımada Geri Al.
- **Ara sekmesi:** başlığa gömülü arama alanı, son aramalar, kategori filtre
  çipleri ve kelime bazlı arama dizini.
- **Ayarlar:** iOS gruplu liste; Aboneliği yönet, Geri bildirim ve Uygulamayı
  değerlendir satırları; tema seçimi segment kontrolle.
- **Temizle:** kesilebilir swipe destesi (kart animasyon sırasında da
  yakalanır), karar fırlatma hızına göre, Geri Al kartı çıktığı kenardan
  getirir. Bekleyen silmeler sekme rozeti ve alt çubukta durur; sekme
  değişimindeki sürpriz sistem diyaloğu kalktı.
- **Erişilebilirlik:** Hareketi Azalt tüm ekranlarda (yay ve kayma yerine
  çapraz geçiş, döngüler durur). En büyük yazı boyutlarında satırlar alt alta
  dizilir, pano ızgarası tek sütuna geçer, onboarding kaydırılır. İkon
  butonlarında VoiceOver etiketi ve 44pt dokunma alanı.
- Kütüphane'de **tek analiz modülü** (bekleyen / ilerleme / kota / sonuç);
  kota yalnız burada görünür.
- Fotoğraf izni iptal edilince boş galeri yerine "Ayarları Aç" durumu.

### Değiştirilenler
- **Görsel dil:** iOS sistem renkleri (gruplu zeminler), SF tipografi ölçeği
  (boyuta özgü tracking, 34pt büyük başlık), Cupertino bileşen ve ikonları;
  iris (#5457D6) yalnız aksan. Material ripple, SnackBar ve AlertDialog'lar
  yerine basış geri bildirimi, üstten durum bildirimi ve action sheet.
- **Hareket:** animasyonlar yayla ve o anki değerden başlar, gesture hızını
  devralır; sekme yalnız fırlatmadan sonra. Haptik görsel olayla aynı karede.
- Büyük başlıklar kaydırınca küçülür.
- Analiz efekti sadeleşti: duman, parçacık ve ışıma kalktı; kategorilere uçan
  küçük resimler yayla.
- Paywall ve Milestone sheet olarak açılır. Paywall'da kapatma yüklenirken de
  görünür, paket odaklı açılışta abonelik butonu katlanır; Milestone rozeti
  sheet yerleşince açılır.
- Onboarding: canlı sayfa göstergesi; izin reddi aynı sayfada ("Ayarları Aç" /
  "Şimdilik geç").
- Animasyonlu açılış ekranı ve sesi kaldırıldı (HIG: launch screen ilk ekrana
  benzemeli); yerine kısa çapraz geçiş.

### Düzeltmeler
- Swipe kartında ilk kaydırmadan sonra alt butonların çalışmaması (controller
  bağlantısı yeni kart kurulunca siliniyordu) ve çift atama yarışı.
- `CurvedAnimation` sızıntıları, analiz kartında boşta çalışan zamanlayıcı ve
  cam sekme çubuğu altındaki sürekli ticker.
- Pano detayında native geri kaydırmayla çakışan özel kenar kaydırması.
- Büyük yazıda plan kartı, Ayarlar satırları, analiz satırları ve çiplerdeki
  taşmalar.

### Bakım
- `audioplayers` ve `animations` bağımlılıkları, kullanılmayan l10n anahtarları
  ve ikon sabitleri kaldırıldı.
- Yeni testler: hareket fiziği, swipe kararı ve destesi, son aramalar, arama
  dizini, görüntüleyici, paywall, milestone ve Dynamic Type (AX5) taşma
  testleri.

## [1.2.0+10] - 2026-08-27

### Eklenenler
- **Cihaz içi kişiselleşme:** `CategoryPriorsService` kullanıcı düzeltmelerinden
  yerel öncelikler öğrenir (ayarlar kutusunda JSON, backend yok). Aynı sinyal
  yeterince tekrar edince (minVotes=3, minDominance=0.7) analiz AI kararını
  kullanıcı alışkanlığına göre günceller.
- **AI kararı izlenebilirliği:** `ScreenshotEntry.aiCategory` AI'ın ham kararını
  saklar; kullanıcı düzeltmesi ayrı yakalanır.
- **Kategori panolarında "NEW" rozeti:** Analiz turu bitince kategori dağılımı
  kalıcı tutulur; ilgili sistem panolarında yıldız tozu + NEW rozeti ve karo
  zıplama animasyonu gösterilir, pano açılınca rozet temizlenir.

### Değiştirilenler
- **Navigasyon çubuğu yeniden yazıldı:** `liquid_glass_renderer` bağımlılığı
  kaldırıldı; yeni `GlassPanel` (ClipRRect + BackdropFilter blur + yarı-opak
  dolgu + ince kenar + yumuşak gölge) Apple News+ tab bar referansına göre.
  Seçili sekme sade primary kapsül; kayma ve sürükleyerek geçiş korundu,
  şaşırtıcı refraksiyon/kabarcık efektleri kaldırıldı. Etiket/ikon kontrastı
  yükseldi, çubuk yüksekliği iOS 26 tab bar'a yaklaştırıldı (64→56).
- **Analiz promptu elden geçirildi:** 21 kategoriye tanım + karışan çiftler için
  ayrım kuralları eklendi. Sistem ekranları (ana + kilit ekranı) her zaman
  `lock_screen`'e gider, asla içerik kategorilerine düşmez. `lock_screen`
  etiketi "Ana ve Kilit Ekranı" olarak güncellendi.

### Düzeltmeler
- **Analizi yarıda kes/sıfırla anında durur:** `cancel()` turu hemen tamamlanmış
  sayar, kart anında özet moduna geçer; uçuş/kuyruk kapatılıp özet gerçek
  sonuca eşitlenir. İptalden sonra dönen in-flight sonuç artık Hive'a
  yazılmaz ve kredi harcamaz.
- **Toplu silme onayı iptal edilince tekrar sorulmaz:** iOS silme onayı iptal
  edilirse sekme geçişlerinde otomatik silme yeniden sorulmuyor; bekleyen
  silme sayacı artık dokunulabilir "sil" düğmesi ve iptal sonrası yönlendirme
  mesajı gösteriliyor.

### Bakım
- `hive_adapters.g.yaml` `aiCategory` alanı için `.g.dart` ile senkronlandı.
- Ajan/skill konfigürasyonları (`.agents/`, `.codex/`) ve mağaza gönderim
  asset'leri (`store_assets/`) eklendi; `AGENTS.md` ve `CLAUDE.md`'ye
  big-picture mimari akışı yazıldı.

## [1.1.0+9] - 2026-07-23

### Eklenenler
- **Sinematik analiz deneyimi:** Tam ekran analiz sahnesi — analiz edilen
  fotoğraflar havuzdan gerçek kategori karolarına uçar; anasayfada yükselen
  mor partiküller. Inline analiz istatistik kartı yerinde animasyonla açılır.
- **Analiz iptali:** Yarıda kes / sıfırla seçenekli pop-up + güvenilir teardown
  (arka planda süren tur state'i ezemez).
- **Kategori detayından yeniden analiz:** Bir kategoriyi kendi ekranından
  yeniden analiz etme; iOS kenar-kaydırma ile geri.
- **Haftalık kota rozeti** app bar'da.
- **Anasayfa son görüntüler** 21 ile sınırlanıp "Tümünü gör" tam ekran açıldı.
- **Toplu swipe silme:** biriktir + geri al + tek onay akışı.
- **Kategori yönetimi:** yeniden adlandır, taşı, tümünü sil.
- **App Store puanı isteği** olumlu anlarda (`in_app_review`).
- **Apple Offer Codes:** Ayarlar'dan kod kullanımı ile abonelik kanalı üzerinden
  ücretsiz Pro erişimi (offline gömülü kod sistemi kaldırıldı).
- **Animasyonlu açılış ekranı** (marka işareti + ses).
- Sayfa başlıkları ana ekranlara gömüldü, AppBar'lar kaldırıldı.

### Düzeltmeler
- Analiz yarıda iptal edilince oluşan çökme giderildi.
- Always-on partikül alanı kaldırılarak analiz sırasındaki lag çözüldü
  (liquid-glass/BackdropFilter altında sürekli ticker animasyonu maliyetli).
- App bar başlık taşması düzeltildi.

## [1.0.0] - 2026-07-22

### Eklenenler
- İlk App Store yayını. Galerideki screenshot'ları Gemini ile 21 kategoriye
  ayıran, aratan ve temizleten iOS uygulaması.
- Gemini AI pipeline (structured output, retry/backoff, worker pool, günlük kota).
- Freemium: haftalık AI analiz kotası, trial penceresi, consumable kredi
  paketleri; `in_app_purchase` (StoreKit 2) ile Pro abonelik + lifetime.
- Board'lar (sistem kategorileri + kullanıcı panoları) ve yerel arama.
- Auto-sort (Pro), swipe ile sıralama/silme.
- TR + EN lokalizasyon, açık/koyu tema.
- App Store gizlilik manifesti, App Check, izin metinleri.
