# AI Screenshot Organizer — Proje Dökümanı

> **Amaç:** Kullanıcının galerisindeki ekran görüntülerini (screenshot) yapay zeka ile otomatik kategorize eden, arayan ve organize etmeyi sağlayan bir iOS uygulaması. Stash uygulamasından ilham alır.
>
> **Hedef:** 1 gün içinde App Store'a gönderilebilir bir v1 (MVP) çıkarmak.
>
> **Bu döküman iki yerde kullanılacak:**
> 1. **Claude Design** — UI/UX tasarımını üretmek için (Bölüm 1–4).
> 2. **Claude Code** — implementasyonu yapmak için (tüm bölümler + Bölüm 8: token/context stratejisi).

---

## 1. Ürün Özeti

Kullanıcılar günlük hayatta yüzlerce ekran görüntüsü biriktirir ve bunlar galeride dağınık durur:

- WhatsApp / mesaj görüntüleri
- Yanlışlıkla alınan kilit ekranı görüntüleri
- Şifreler, notlar, kodlar
- Instagram / sosyal medya paylaşımları
- Market sepeti, alışveriş listeleri
- Makbuz, fatura, bilet görüntüleri

Uygulama bu screenshot'ları galeriden okur, her birini AI ile analiz eder (kategori + etiket + içindeki metin), ve kullanıcının hızlıca **bulmasını, filtrelemesini ve temizlemesini** sağlar.

**Temel değer önerisi:** "Her ekran görüntüsü otomatik sıralanır, tüm kütüphaneniz aranabilir olur."

---

## 2. Kapsam (v1 / MVP)

### Dahil olan özellikler (v1)
- Galeriye erişim izni ve sadece **screenshot** medyalarını çekme (iOS `PHAssetMediaSubtype.photoScreenshot`)
- Manuel "İçeri aktar / Senkronize et" akışı ile screenshot'ları listeye alma
- Her screenshot için AI analizi: **kategori**, **3 etiket**, **OCR metni** (varsa)
- Grid (ızgara) galeri görünümü + thumbnail lazy loading
- Kategori/board bazlı görünüm (ör. "Kilit Ekranı", "Sosyal Medya", "Alışveriş", "Notlar/Şifreler", "Mesajlar")
- Metin ve etiket bazlı arama (local)
- Swipe ile hızlı aksiyon (sil / board'a taşı)
- Detay ekranı (tek screenshot + etiketleri + OCR metni)
- Paywall / abonelik ekranı + free trial
- TR + EN lokalizasyon
- App Store gerekli ekranları (onboarding, izin açıklama, gizlilik, restore purchases)

### v1'e DAHİL OLMAYAN (sonraki sürüm)
- Otomatik arka plan işleme (yeni screenshot alınınca otomatik sıralama) — *iOS background processing 1 günde riskli, v2'ye bırakıldı*
- Bulut senkronizasyon / kullanıcı hesabı
- Android sürümü (screenshot tespiti Android'de `MediaStore` üzerinden farklı çalışır, ayrı iş)
- Çoklu cihaz senkronu

---

## 3. Freemium Modeli

Stash'ten ilham alan ücretsiz/ücretli ayrımı:

| Özellik | Ücretsiz (Free) | Pro |
|---|---|---|
| Manuel swipe sıralama | İlk 100 sıralama | Sınırsız |
| Özel board (kategori) sayısı | 3 board | Sınırsız |
| Otomatik AI sıralama | İlk 100 screenshot | Sınırsız |
| Tüm kütüphanede metin araması | Kilitli | Açık |
| Toplu silme (ör. tüm kilit ekranı ss'leri) | Kilitli | Açık |

**Fiyatlandırma planları (referans — final rakamlar App Store Connect'te ayarlanır):**
- Aylık abonelik
- Yıllık abonelik (14 gün ücretsiz deneme, "Save 50%" vurgusu)
- Lifetime (tek seferlik ödeme)

**Not:** Yıllık plan varsayılan seçili gelir (en yüksek dönüşüm). Paywall'da 14 günlük ücretsiz deneme vurgulanır.

---

## 4. Tasarım Yönü (Claude Design için)

> **Not:** Renk paleti, tipografi ve genel görsel dil bilinçli olarak **belirlenmedi** — bu kararı Claude Design'ın kendisine bırakıyoruz. Ekli Stash Pro ekran görüntüsü sadece **fonksiyonel referans** olarak veriliyor (paywall'da hangi bilgiler/aksiyonlar bulunmalı), görsel stil kopyalanmayacak; Claude Design kendi özgün estetiğini önersin.

### Fonksiyonel gereksinimler (stil değil, davranış)
- Sıcak/soğuk, koyu/açık tema tercihi Claude Design'ın önerisine açık.
- Paywall'da bulunması gereken bilgiler: özellik listesi (free vs pro farkları), 3 plan kartı (aylık/yıllık/lifetime), öne çıkan plan vurgusu, ücretsiz deneme CTA'sı, Restore/Terms/Privacy linkleri.
- Grid galeri görünümü, board/kategori ayrımı, swipe aksiyonu görsel olarak sezilebilir olmalı.

### Üretilecek ekranlar (Claude Design'da mockup)
1. **Onboarding** (3 ekran): ne işe yarar, izin isteme gerekçesi, başla.
2. **Ana galeri (grid görünüm):** üstte arama çubuğu, screenshot ızgarası, altta board sekmeleri.
3. **Board / kategori görünümü:** kategorilere ayrılmış liste veya sekmeli görünüm.
4. **Detay ekranı:** tek screenshot büyük, altında etiketler + OCR metni + aksiyonlar.
5. **Arama ekranı / sonuçları.**
6. **Swipe aksiyon görünümü:** kart üstünde sağa/sola swipe (sil / board'a ekle).
7. **Paywall:** ekteki Stash Pro referansına benzer düzen — özellik listesi + 3 plan kartı + "14 günlük ücretsiz deneme başlat" CTA + Restore/Terms/Privacy linkleri.
8. **Boş durum (empty state):** henüz screenshot yokken.

> **Claude Design notu:** Bu ekranları detaylı piksel-mükemmel yapmaya çalışma; hızlı bir yön mockup'ı yeterli. Sonra Claude Code'a handoff edilecek. Referans olarak Stash Pro paywall ekran görüntüsü verildi — sadece **hangi bilgi/aksiyonların bulunması gerektiği** (fonksiyonel yapı) referans alınır, **görsel stil birebir kopyalanmaz**. Renk paleti ve tipografi seçimini Claude Design özgün olarak önersin; 2-3 farklı yön denenip karşılaştırılabilir.

---

## 5. Teknik Mimari

### Stack
- **Framework:** Flutter (Dart)
- **State management:** Riverpod (az boilerplate, ölçeklenebilir)
- **Navigasyon:** go_router
- **Galeri erişimi:** `photo_manager` paketi (iOS'ta screenshot filtreleme native destekli, thumbnail cache dahil)
- **Local veri saklama:** Isar veya Drift *(varsayım — onaya tabi; gizlilik + hız için local seçildi, App Store privacy formunu basitleştirir)*
- **AI:** Google Gemini 2.5 Flash, **Firebase AI Logic (Vertex AI in Firebase)** üzerinden
- **Swipe UI:** `flutter_slidable` veya kart tabanlı bir paket (sıfırdan yazma)
- **IAP / abonelik:** Native StoreKit 2 (kendi implementasyonumuz) — *kritik risk, bkz. Bölüm 7*
- **Lokalizasyon:** Flutter `intl` / `flutter_localizations` (TR + EN)

### AI etiketleme akışı
1. Kullanıcı "İçeri aktar" der → `photo_manager` ile screenshot'lar çekilir.
2. Her screenshot için (veya batch halinde) görsel Firebase AI Logic üzerinden Gemini 2.5 Flash'a gönderilir.
3. Gemini'den **yapılandırılmış JSON** istenir:
   ```json
   {
     "category": "lock_screen | social | shopping | notes_passwords | messages | receipts | other",
     "tags": ["etiket1", "etiket2", "etiket3"],
     "ocr_text": "görselde okunan metin (varsa)"
   }
   ```
4. Sonuç local DB'ye yazılır. Görsel **saklanmaz**, sadece analiz için geçici gönderilir.

### Gizlilik ilkesi (App Store privacy için kritik)
- Screenshot'lar kullanıcının cihazında kalır.
- AI analizi için gönderilen görsel geçici işlenir, **kalıcı saklanmaz**.
- Bu durum App Store privacy formunda doğru beyan edilmeli (veri toplama minimumda).
- Firebase App Check ile API kötüye kullanımı engellenir.

---

## 6. App Store Gereklilikleri (Checklist)

- [ ] **Restore Purchases** butonu (paywall'da zorunlu — eksikse review reddedilir)
- [ ] Abonelik şartları, otomatik yenileme açıklaması, iptal bilgisi paywall'da görünür
- [ ] Terms of Use (EULA) + Privacy Policy linkleri
- [ ] Foto kütüphanesi izin açıklaması (`NSPhotoLibraryUsageDescription` — neden erişildiği net anlatılmalı)
- [ ] App Privacy formu (App Store Connect) doğru doldurulmalı
- [ ] Free trial mekanizması App Store Connect'te introductory offer olarak tanımlanmalı
- [ ] App ikonu, ekran görüntüleri, açıklama metni (TR + EN)
- [ ] Test hesabı / review notu (Apple reviewer'ın AI özelliğini test edebilmesi için)

> **Uyarı:** Apple, IAP akışlarını (satın alma, restore, trial) review sırasında bizzat test eder. Bu akış eksik/hatalıysa reddedilir. IAP en riskli kalem.

---

## 7. Risk Haritası (Fable 5 ile yapılacak kritik kısımlar)

Aşağıdaki kısımlar **karmaşık / hataya açık / uzun-ufuklu** olduğu için **Claude Fable 5** ile yapılmalı. Geri kalan rutin işler **Sonnet 5** ile yapılır (maliyet + hız).

| Kısım | Neden riskli | Model |
|---|---|---|
| Mimari planlama & dosya yapısı | Bir kere doğru kurulmazsa sonra pahalı | **Fable 5** |
| `photo_manager` screenshot filtreleme + izin akışı | Native davranış, iOS'a özgü tuzaklar | **Fable 5** |
| StoreKit 2 IAP (satın alma, restore, trial, receipt) | App Store review'da test edilir, en riskli | **Fable 5** |
| Firebase AI Logic + Gemini structured JSON entegrasyonu | Çok adımlı, parse hatasına açık | Sonnet 5 → takılırsa Fable 5 |
| Galeri grid + thumbnail + lazy loading | Rutin | Sonnet 5 |
| Board / kategori ekranları | Rutin | Sonnet 5 |
| Arama (local) | Rutin | Sonnet 5 |
| Swipe aksiyonları (paketle) | Rutin | Sonnet 5 |
| Lokalizasyon (TR/EN) | Rutin, tekrar eden | Sonnet 5 |
| Cilalama (empty state, animasyon) | Rutin | Sonnet 5 |

---

## 8. Token & Context Stratejisi (Claude Code için — ZORUNLU OKUMA)

> Bu bölüm Claude Code'un uzun süre çalışırken **düşük maliyetli** ve **odaklı** kalması için kurallar içerir. Her kural uygulanmalı.

### 8.1 Görev başına temiz context
- Her yeni ana bloğa (iskelet → galeri import → AI etiketleme → arama → paywall → cilalama) geçerken **yeni oturum / `/clear`** kullan.
- İstisna: bir önceki blokla **doğrudan** ilişkili küçük iş (az önce yazılan kodun dokümantasyonu gibi) → context taşınabilir.
- Farklı bir feature'a geçiyorsan → mutlaka temizle.

### 8.2 Subagent kullan (en büyük tasarruf)
- **Kural:** Bir iş 5'ten fazla dosya okuyacaksa veya "araştırma/keşif" niteliğindeyse → ana sohbete değil **subagent**'a yaptır. Subagent kendi context'inde çalışır, ana session'a sadece özet döner.
- Bu projede subagent kullanılacak yerler:
  - `photo_manager` / StoreKit API'lerini araştırma → subagent
  - Bitmiş bir bloğu diff olarak fresh context'te review ettirme → subagent
  - Bağımsız iki iş paralel yürüyecekse (backend vs UI) → biri subagent'a
- `.claude/agents/` altına bir `code-reviewer` subagent tanımla; her blok sonunda diff'i PLAN'a göre kontrol etsin.

### 8.3 CLAUDE.md sıkı tut
- CLAUDE.md = her turn otomatik yüklenir → sadece **her zaman gereken** bilgi (stack, konvansiyonlar, komutlar, renk paleti, klasör yapısı).
- Belirli anlarda gereken bilgi → **skill**'e taşı (aşağıda öneriler).
- Test: "Bu satırı silsem Claude hata yapar mı?" Hayırsa sil.

### 8.4 Aktif `/compact`
- Auto-compact %95'te devreye girer ve model o an en zayıf halinde özetler (kayıp olur).
- Bunun yerine blok bitince **manuel** `/compact` at ve neyin korunacağını söyle:
  `/compact Flutter dosya yapısını ve photo_manager/StoreKit kararlarını koru, deneme-yanılma detaylarını özetle`
- CLAUDE.md'ye compact policy ekle: "Compact yaparken değiştirilen dosya listesini ve test/build komutlarını mutlaka koru."

### 8.5 Küçük, odaklı task'lar
- "Uygulamanın tamamını yaz" değil → "sadece grid görünümünü ve thumbnail loading'i yaz" gibi dar promptlar.
- Az token, daha doğru sonuç, kolay review.

### 8.6 Model routing disiplini
- Rutin Flutter widget/ekran → **Sonnet 5**
- Plan + native/riskli kısımlar (Bölüm 7) → **Fable 5**
- Basit read-only review/keşif → **Haiku** subagent (built-in "Explore")

### 8.7 Başarısız denemede `/clear`
- Aynı hata 2. kez tekrarlanıyorsa context "kirlenmiş" sayılır → düzelt demek yerine `/clear` at, öğrendiğini yeni ve daha iyi bir ilk prompt'a koyarak baştan başla.

### 8.8 Hızlı sorular için `/btw`
- Context'e girmesi gerekmeyen küçük sorular (paket versiyonu vb.) için `/btw` — cevap ayrı overlay'de çıkar, history şişmez.

### 8.9 Önerilen skill'ler (bu proje için)
- **flutter-conventions:** proje klasör yapısı, Riverpod pattern, isimlendirme (her zaman gerekli olmadığı için CLAUDE.md yerine skill).
- **commit-convention:** Conventional Commits ile düzenli checkpoint (her blok sonu commit).
- **ios-release-check:** App Store gönderim öncesi checklist (Bölüm 6) — deploy öncesi tetiklenir.

> Her blok sonunda: manuel `/compact` + git commit = düzenli checkpoint. Böylece hem uzun çalışır hem token kontrollü kalır.

---

## 9. Clean Code & Yorum Standartları (ZORUNLU)

> Uygulama hızlı yazılacak ama kod **incelenebilir ve bakımı yapılabilir** olmalı. Claude Code her dosyada aşağıdaki kurallara uymalı.

### 9.1 Genel prensipler
- Fonksiyon/metot tek bir işi yapmalı (Single Responsibility). Bir widget/fonksiyon 40-50 satırı geçiyorsa parçalanmalı.
- Anlamlı, açıklayıcı isimlendirme (`x`, `data`, `temp` gibi belirsiz isimler yasak).
- Magic number/string kullanılmaz — sabitler (`const`) tanımlanır ve isimlendirilir.
- Tekrar eden kod (3+ kez) ortak bir fonksiyona/widget'a çıkarılır (DRY).
- Hata yönetimi sessizce yutulmaz — her `try/catch` en azından loglanır veya kullanıcıya anlamlı bir durum gösterir.

### 9.2 Yorum satırı standartları (senin kod okuman için)
- **Her dosyanın başında** kısa bir açıklama: dosyanın ne işe yaradığı, hangi katmana ait olduğu (ör. `// Bu dosya screenshot'ların local DB işlemlerini yönetir (repository katmanı).`)
- **Her public fonksiyon/metot üstünde** ne yaptığını, parametrelerini ve dönüş değerini açıklayan kısa bir yorum (Dart doc formatı `///` kullanılır).
- **Karmaşık/non-obvious mantığın olduğu satırlarda** *"neden böyle yapıldığı"* açıklanır — *"ne yaptığı"* değil (kod zaten onu gösterir). Örnek:
  ```dart
  // photo_manager iOS'ta screenshot'ları PHAssetMediaSubtype.screenshot ile
  // filtreliyor; bu yüzden burada ek bir MIME kontrolüne gerek yok.
  final screenshots = await PhotoManager.getAssetPathList(...);
  ```
- **TODO/FIXME etiketleri** açıkça işaretlenir: `// TODO(v2): Otomatik arka plan senkronizasyonu eklenecek.`
- Yorumlar Türkçe yazılabilir (senin gözden geçirmen kolaylaşsın diye) — kod (değişken/fonksiyon isimleri) İngilizce kalır (Flutter/Dart konvansiyonu).

### 9.3 Dosya/katman organizasyonu
- **Feature-first** klasör yapısı önerilir (`lib/features/gallery/`, `lib/features/paywall/` gibi) — her feature kendi widget/state/repository dosyalarını içerir.
- Ortak/paylaşılan kod `lib/core/` veya `lib/shared/` altında toplanır.
- UI (widget), state (Riverpod provider) ve veri erişimi (repository) katmanları ayrı dosyalarda tutulur, tek dosyaya karıştırılmaz.

### 9.4 Review disiplini
- Her blok sonunda (Bölüm 8.2'deki subagent kuralı gereği) bir **code-reviewer subagent** diff'i şu kriterlere göre kontrol eder:
  - Yorum standartlarına uyuluyor mu?
  - Fonksiyon uzunluğu/karmaşıklığı makul mü?
  - İsimlendirme açık mı?
  - Hata yönetimi var mı?
- Bu kontrol geçmeden bir sonraki bloğa geçilmez.

---

## 10. Önerilen 1 Günlük Akış (Blok Bazlı)

Her blok = yeni context + sonunda compact + commit.

1. **Planlama (Fable 5, ~45dk):** mimari, dosya yapısı, `photo_manager` yaklaşımı, CLAUDE.md + PLAN.md üret.
2. **Tasarım yönü (Claude Design, ~20dk):** ana galeri + paywall mockup, Claude Code'a handoff.
3. **İskelet (Sonnet 5):** proje kurulumu, Riverpod, go_router, tema/renk, izinler.
4. **Galeri import + grid (Sonnet 5):** photo_manager, screenshot filtreleme, thumbnail.
5. **AI etiketleme (Sonnet 5 → Fable 5):** Firebase AI Logic + Gemini structured JSON, local DB'ye yazma.
6. **Board + arama (Sonnet 5):** kategori görünümü, local arama.
7. **Swipe + toplu silme (Sonnet 5):** slidable, kategori toplu sil (Pro).
8. **Paywall + IAP (Fable 5):** StoreKit 2, trial, restore — kritik.
9. **Lokalizasyon + cilalama (Sonnet 5):** TR/EN, empty state, hata durumları.
10. **App Store hazırlık (ios-release-check skill):** privacy formu, izin metinleri, restore testi.
11. **Buffer:** native izin/simulator sürprizleri için pay.

---

## 11. Açık Kararlar / Onay Bekleyenler

- [ ] Local DB: **Isar** mı **Drift** mi? (varsayılan öneri: Isar — hız + basitlik)
- [ ] Gemini kategori setinin final listesi (yukarıdaki 7 kategori başlangıç önerisi)
- [ ] Fiyatlandırma rakamları (App Store Connect'te ayarlanacak)
- [ ] IAP: StoreKit 2 kendi implementasyonu onaylandı — risk kabul edildi