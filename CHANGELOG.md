# Değişiklik Günlüğü

Bu projedeki dikkate değer tüm değişiklikler bu dosyada tutulur.

Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) temel alınır;
sürümleme [Semantic Versioning](https://semver.org/lang/tr/) izler.
Her başlıktaki `+N` iOS build (CFBundleVersion) numarasıdır.

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
