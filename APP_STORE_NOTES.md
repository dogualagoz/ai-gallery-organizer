# App Store Gönderim Notları — Snaply

Bu doküman App Store Connect kurulumu için gereken tüm bilgileri içerir.
Kod tarafı hazır; buradaki adımlar App Store Connect / Apple Developer hesabında elle yapılır.

## 1. Uygulama Kaydı

- **Bundle ID:** `com.dogualagoz.snaply` (Apple Developer > Identifiers'da açılacak)
- **Ad:** "Snaply" placeholder — yayın öncesi kesinleşirse tek noktadan değişir:
  `lib/core/constants/app_constants.dart` (`kAppName`) + `ios/Runner/Info.plist` (`CFBundleDisplayName`)
- **Kategori:** Productivity (ikincil: Utilities)
- **Yaş:** 4+ (kullanıcı içeriği yalnızca kendi galerisi; paylaşım/UGC yok)
- **Sürüm:** 1.0.0 (build 1) — `pubspec.yaml > version`

## 2. IAP Ürünleri (App Store Connect > Monetization)

Ürün ID'leri koddaki `ProductIds` sabitleriyle **birebir** aynı olmalı
(`lib/core/constants/app_constants.dart`). Fiyatlar StoreKit test değerleridir; gerçek
fiyat kademeleri Connect'te seçilir.

**Abonelik grubu:** `Snaply Pro` (tek grup; aylık ve yıllık aynı grupta olmalı ki
kullanıcı planlar arasında upgrade/downgrade yapabilsin).

| Ürün ID | Tip | Süre | Test fiyatı | Not |
|---|---|---|---|---|
| `snaply_pro_monthly` | Auto-Renewable Subscription | 1 ay | 39,99 | — |
| `snaply_pro_yearly` | Auto-Renewable Subscription | 1 yıl | 299,99 | **Introductory Offer: 2 hafta ücretsiz (Free Trial)** — Connect'te ürünün "Subscription Prices > Introductory Offers" bölümünden tanımlanır, kodda değil |
| `snaply_pro_lifetime` | **Non-Consumable** | — | 199,99 | Tek seferlik |

Her ürün için Connect'te localized display name + description (TR+EN) girilmeli, ör:
- TR: "Snaply Pro Yıllık" / "Sınırsız AI analizi, arama ve board'lar"
- EN: "Snaply Pro Yearly" / "Unlimited AI analysis, search and boards"

> Ürünler "Ready to Submit" durumuna gelmeden uygulama review'a gönderilirse
> reviewer paywall'ı test edemez ve reddeder. İlk sürümde IAP'ler uygulamayla
> **birlikte** gönderilir (version page > In-App Purchases bölümünden eklenir).

## 3. App Privacy Formu Cevapları

**Data Collection: Yes** — tek veri türü:

| Soru | Cevap |
|---|---|
| Data type | **Photos or Videos** (User Content) |
| Usage | App Functionality (AI ile kategori/etiket/OCR çıkarımı) |
| Linked to user? | **No** (hesap sistemi yok, kimlik toplanmıyor) |
| Used for tracking? | **No** |

Diğer tüm veri türleri: **Not collected.** Analytics/ads SDK'sı yok; Firebase yalnızca
AI Logic için kullanılıyor. Satın alma Apple üzerinden — Purchases beyanı gerekmez
(uygulama satın alma geçmişini kendisi toplamıyor).

Bu cevaplar `ios/Runner/PrivacyInfo.xcprivacy` manifest'iyle tutarlıdır
(PhotosorVideos / AppFunctionality / linked=No / tracking=No).

**Privacy Policy URL:** yayın öncesi gerçek URL girilecek — `LegalUrls` sabitleri de
güncellenmeli (`app_constants.dart`, `TODO(release)`).

## 4. Review Notu (App Review Information > Notes alanına, İngilizce)

```
Snaply organizes the user's screenshots on-device using AI labeling.

HOW TO TEST:
1. On first launch, complete onboarding and grant photo library access.
   The app only lists screenshots (PHAssetMediaSubtype.photoScreenshot).
2. Tap "Sync" on the gallery tab: screenshots are analyzed one by one via
   Google's Gemini API (Firebase AI Logic). Each image is transmitted solely
   to obtain a category/tags/OCR text and is NOT stored on any server.
   Results are stored locally on the device only.
3. Boards tab shows system categories and custom boards.
4. The sorting flow (swipe left = delete, right = assign to board) and
   bulk delete use the standard iOS photo deletion confirmation.

IN-APP PURCHASES:
- Free tier: 100 AI analyses, 100 swipe sorts, 3 custom boards.
- Snaply Pro (monthly / yearly with 14-day free trial / lifetime) unlocks
  unlimited analysis, search and boards.
- Restore Purchases is available on both the paywall and Settings.

No account or login is required. The device needs an internet connection
for the AI analysis step only.
```

## 5. Mağaza Metinleri

### TR
- **Ad:** Snaply — Ekran Görüntüsü Düzenleyici
- **Alt başlık (30 kr.):** Screenshot'ları AI ile düzenle
- **Anahtar kelimeler:** ekran görüntüsü,screenshot,galeri,düzenleme,ai,temizlik,albüm,arama,ocr,not
- **Açıklama:**

> Galerin ekran görüntüsüyle dolu ama aradığını asla bulamıyor musun? Snaply, screenshot'larını yapay zekâ ile otomatik kategorilere ayırır: alışveriş, sosyal medya, notlar ve şifreler, mesajlar, fişler ve daha fazlası.
>
> • OTOMATİK DÜZEN — Screenshot'ların AI ile etiketlenir ve board'lara ayrılır.
> • AKILLI ARAMA — Görsellerdeki metin (OCR) dahil her şeyde ara. (Pro)
> • HIZLI TEMİZLİK — Kaydırarak sırala: sola at sil, sağa at board'a ekle.
> • ÖZEL BOARD'LAR — Kendi koleksiyonlarını oluştur.
> • GİZLİLİK ODAKLI — Görsellerin yalnızca etiketleme için analiz edilir, hiçbir sunucuda saklanmaz. Hesap gerekmez.
>
> Snaply Pro ile sınırsız AI analizi, sınırsız board ve arama özelliğinin kilidini aç. Yıllık planda 14 gün ücretsiz deneme.

### EN
- **Name:** Snaply — Screenshot Organizer
- **Subtitle (30 ch.):** Organize screenshots with AI
- **Keywords:** screenshot,organizer,gallery,cleaner,ai,albums,search,ocr,notes,declutter
- **Description:**

> Is your gallery drowning in screenshots you can never find again? Snaply automatically sorts your screenshots into categories with AI: shopping, social media, notes & passwords, messages, receipts and more.
>
> • AUTO ORGANIZE — Screenshots are labeled by AI and sorted into boards.
> • SMART SEARCH — Search everything, including text inside images (OCR). (Pro)
> • QUICK CLEANUP — Sort with swipes: left to delete, right to file into a board.
> • CUSTOM BOARDS — Build your own collections.
> • PRIVACY FIRST — Images are analyzed only to label them and are never stored on any server. No account needed.
>
> Unlock unlimited AI analysis, unlimited boards and search with Snaply Pro. Yearly plan includes a 14-day free trial.

## 6. Yayın Öncesi Kullanıcı Adımları (kod dışı)

1. **Firebase API anahtarı rotasyonu** (güvenlik olayı sonrası hâlâ açık) →
   sonrasında `flutterfire configure --project=snaply-organizer` yeniden çalıştırılır.
2. **App Check'i Firebase Console'da etkinleştir:** Console > App Check > iOS app >
   App Attest kaydet; önce "Monitor" modunda izle, sonra Gemini API (AI Logic) için
   **Enforce** aç. Debug build'lerde konsola yazılan debug token'ı Console'a ekle.
3. **Xcode signing:** Team seç; **App Attest capability** ekle
   (Signing & Capabilities > + Capability > App Attest — release'de App Check bunu kullanır).
4. **Gerçek Privacy Policy / Terms URL'lerini yayınla** ve `LegalUrls`'ü güncelle.
5. App Store Connect'te uygulama kaydı + IAP ürünleri (Bölüm 2) + App Privacy (Bölüm 3).
6. Uygulama adı kesinleşsin (Bölüm 1'deki iki nokta).
7. Gerçek cihazda son test (özellikle foto izni, AI analizi, satın alma sandbox'ı).
