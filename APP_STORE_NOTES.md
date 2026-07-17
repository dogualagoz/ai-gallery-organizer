# App Store Gönderim Notları — Snaply

Bu doküman App Store Connect kurulumu ve yayın için gereken tüm bilgileri içerir.
Kod tarafı hazır; buradaki adımlar App Store Connect / Apple Developer / Firebase
Console'da elle yapılır. **Sıralı yayın adımları için Bölüm 7'ye bak.**

Son güncelleme: 2026-07-05 (monetizasyon v2 sonrası — consumable pack'ler,
7 gün trial, Pro-only board/arama; Hive şifreleme eklendi).

## 1. Uygulama Kaydı

- **Bundle ID:** `com.dogualagoz.snaply` (Apple Developer > Identifiers'da açılacak)
- **Ad kesinleşti (2026-07-07):** İki ayrı alan var, karıştırma:
  - **Home screen etiketi / uygulama içi metinler:** "Snaply" — kod tarafında zaten
    bu (`lib/core/constants/app_constants.dart` `kAppName` + `ios/Runner/Info.plist`
    `CFBundleDisplayName`), değişiklik gerekmiyor.
  - **App Store Connect "Name" alanı (App Information, dashboard'da elle girilir,
    kodla ilgisi yok):** "Snaply | AI Gallery Organizer"
- **Kategori:** Productivity (ikincil: Utilities)
- **Yaş:** 4+ (kullanıcı içeriği yalnızca kendi galerisi; paylaşım/UGC yok)
- **Sürüm:** 1.0.0 (build 1) — `pubspec.yaml > version`

## 2. IAP Ürünleri (App Store Connect > Monetization)

Ürün ID'leri koddaki `ProductIds` sabitleriyle **birebir** aynı olmalı
(`lib/core/constants/app_constants.dart`). Fiyatlar `Products.storekit` test
değerleridir (TRY); gerçek fiyat kademeleri Connect'te seçilir.

**Abonelik grubu:** `Snaply Pro` (tek grup; aylık ve yıllık aynı grupta olmalı ki
kullanıcı planlar arasında upgrade/downgrade yapabilsin).

| Ürün ID | Tip | Süre | Test fiyatı (₺) | Not |
|---|---|---|---|---|
| `snaply_pro_monthly` | Auto-Renewable Subscription | 1 ay | 199,99 | — |
| `snaply_pro_yearly` | Auto-Renewable Subscription | 1 yıl | 1.299,99 | **Introductory Offer: 7 gün ücretsiz (Free Trial)** — Connect'te ürünün "Subscription Prices > Introductory Offers" bölümünden tanımlanır, kodda değil. Yalnız yıllıkta trial var |
| `snaply_pro_lifetime` | **Non-Consumable** | — | 2.999,99 | Tek seferlik. 2026-07-07'de Connect'te 3.499,99'dan 2.999,99'a düşürüldü |
| `snaply_pack_500` | **Consumable** | — | 99,99 | 500 AI analiz kredisi (Pro açmaz) |
| `snaply_pack_1000` | **Consumable** | — | 149,99 | 1000 AI analiz kredisi (Pro açmaz) |

Her ürün için Connect'te localized display name + description (TR+EN) girilmeli, ör:
- TR: "Snaply Pro Yıllık" / "Sınırsız AI analizi, arama ve board'lar"
- EN: "Snaply Pro Yearly" / "Unlimited AI analysis, search and boards"
- TR: "500 Analiz Paketi" / "500 ek AI analiz hakkı" — EN: "500 Analysis Pack" / "500 extra AI analyses"

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
güncellenmeli (`app_constants.dart`, `TODO(release)`). Politika metninde şunlar yer
almalı: görseller yalnız etiketleme için Google Gemini API'sine gönderilir ve sunucuda
saklanmaz; etiket/OCR sonuçları cihazda şifreli (AES) veritabanında tutulur.

**Export Compliance (2026-07-07, build 1.0.0(1) için cevaplandı):** Hive DB'nin AES
şifrelemesi nedeniyle "Standard encryption algorithms in addition to Apple's OS"
seçildi. **Fransa sorusuna "No" dendi** (ANSSI beyanından kaçınmak için) — bu yüzden
App Store yayınında **Pricing and Availability'den Fransa çıkarılmalı**. İleride Fransa
istenirse compliance cevabı güncellenip ANSSI beyanı yapılır.

## 4. Review Notu (App Review Information > Notes alanına, İngilizce)

```
Snaply organizes the user's screenshots on-device using AI labeling.

HOW TO TEST:
1. On first launch, complete onboarding and grant photo library access.
   The app only lists screenshots (PHAssetMediaSubtype.photoScreenshot).
2. Tap "Sync" on the home tab: screenshots are analyzed one by one via
   Google's Gemini API (Firebase AI Logic). Each image is transmitted solely
   to obtain a category/tags/OCR text and is NOT stored on any server.
   Results are stored only on the device, in an AES-encrypted local database.
3. The home tab shows system category boards; custom boards are a Pro feature.
4. The sorting flow (swipe left = delete, right = assign to board) and
   bulk delete use the standard iOS photo deletion confirmation.

IN-APP PURCHASES:
- Free tier: 100 AI analyses and 100 swipe sorts.
- Snaply Pro (monthly / yearly with 7-day free trial / lifetime) unlocks
  unlimited analysis, search, custom boards, bulk delete and auto-sort.
- Consumable packs (500 / 1000 analyses) add extra AI analysis credits
  without a subscription.
- Restore Purchases is available on both the paywall and Settings.

No account or login is required. The device needs an internet connection
for the AI analysis step only.

SUBMISSION 7b737aa9 FIXES (2026-07-17):
- 3.1.2(c): Added functional Terms of Use (EULA) and Privacy Policy links to
  the App Store Description (see Section 5 of this doc).
- 5.1.1(iv): Onboarding's final-page button now reads "Continue" (was "Allow
  and start") so it no longer implies granting the permission itself.
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
> • ÖZEL BOARD'LAR — Kendi koleksiyonlarını oluştur. (Pro)
> • GİZLİLİK ODAKLI — Görsellerin yalnızca etiketleme için analiz edilir, hiçbir sunucuda saklanmaz; sonuçlar cihazında şifreli tutulur. Hesap gerekmez.
>
> Snaply Pro ile sınırsız AI analizi, arama, özel board'lar ve otomatik sıralamanın kilidini aç. Yıllık planda 7 gün ücretsiz deneme. Abonelik istemeyenler için 500/1000'lik analiz paketleri de var.
>
> Kullanım Şartları: https://dogualagoz.github.io/ai-gallery-organizer/terms.html
> Gizlilik Politikası: https://dogualagoz.github.io/ai-gallery-organizer/privacy.html

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
> • CUSTOM BOARDS — Build your own collections. (Pro)
> • PRIVACY FIRST — Images are analyzed only to label them and are never stored on any server; results stay encrypted on your device. No account needed.
>
> Unlock unlimited AI analysis, search, custom boards and auto-sort with Snaply Pro. Yearly plan includes a 7-day free trial. Prefer no subscription? Grab a 500 or 1000 analysis pack.
>
> Terms of Use: https://dogualagoz.github.io/ai-gallery-organizer/terms.html
> Privacy Policy: https://dogualagoz.github.io/ai-gallery-organizer/privacy.html

## 6. Firebase: Free (Spark) plandan çıkmak GEREKİYOR

Gemini Developer API kotaları **proje başına** sayılır, kullanıcı başına değil.
Ücretsiz katmanda `gemini-2.5-flash-lite`: 15 istek/dk ve ~1000 istek/gün — bu kota
**tüm kullanıcı tabanıyla paylaşılır**. Free kullanıcıya 100 analiz hakkı verildiği
için günde ~10 yeni kullanıcı bile kotayı bitirir ve herkesin analizi durur.

- **Yapılacak:** Firebase Console > projeyi **Blaze** (pay-as-you-go) planına yükselt
  (Cloud Billing hesabı bağlanır; yeni billing hesaplarında ön ödeme istenebilir).
- Sonra kodda tek satır: `lib/core/constants/ai_constants.dart` içindeki profil
  `AiRateProfile.free` → `AiRateProfile.paid` (5 paralel istek, gap yok, günlük cap yok).
- **Maliyet düşük:** flash-lite ile ekran görüntüsü analizi başına ≈ $0.0001;
  100 analizlik bir free kullanıcı ≈ 1 cent. Yine de Cloud Billing'de **budget alert**
  kur (ör. $25/ay eşiği) — kota suistimaline karşı ikinci emniyet.

## 7. YAYIN ADIMLARI — Sırayla (kullanıcı yapılacaklar listesi)

1. **Firebase API anahtarı rotasyonu** (2026-07-04 sızıntısı sonrası hâlâ açık):
   Cloud Console > Credentials > iOS anahtarını regenerate et; anahtara **bundle ID
   kısıtı** (`com.dogualagoz.snaply`) ekle. Sonra `flutterfire configure
   --project=snaply-organizer` ile yeni config'i çek ve GitHub secret-scanning
   alert'ini "revoked" olarak kapat.
2. **Firebase Blaze planına geç** + budget alert kur (Bölüm 6). Kodda
   `AiRateProfile.paid`'e geç, commit'le.
3. **App Check enforcement:** Console > App Check — önce birkaç gün "Monitor"
   modunda doğrulanmış istek oranını izle, sonra Gemini API (AI Logic) için
   **Enforce** aç. Bu, IPA içindeki API anahtarının dışarıdan suistimaline karşı
   ASIL korumadır (bkz. Bölüm 8). Debug build token'ları Console'a ekli kalmalı.
4. **Xcode signing:** Team seç; **App Attest capability** ekle (Signing &
   Capabilities > + Capability > App Attest). Apple Developer'da bekleyen
   **Program License Agreement onayını** ver (developer.apple.com uyarısı) —
   onaylanmadan gerçek cihaz build/TestFlight çalışmaz.
5. **Gerçek Privacy Policy / Terms sayfalarını yayınla** ve `LegalUrls`'ü güncelle
   (`app_constants.dart`, `TODO(release)` işaretli — **koddaki tek yayın blokeri**).
6. **App Store Connect:** uygulama kaydı (Bölüm 1) + 5 IAP ürünü ve yıllıkta 7 gün
   trial (Bölüm 2) + App Privacy formu (Bölüm 3) + mağaza metinleri (Bölüm 5) +
   review notu (Bölüm 4).
7. **Uygulama adını kesinleştir** ("Snaply" placeholder — `kAppName` +
   `CFBundleDisplayName`, Connect'teki adla aynı olmalı).
8. **Gerçek cihazda uçtan uca test:** foto izni, senkron + AI analizi (App Check
   enforce açıkken!), paywall sandbox satın alma + restore, pack kredisi, auto-sort.
   Sonra TestFlight'a yükle → son kontrol → review'a gönder.

## 8. Bilinçli Kabul Edilen Riskler (v1)

Güvenlik incelemesi (2026-07-05) sonucu, v1 için bilinçli kabul edilenler:

- **Receipt validation yok:** Pro/kredi durumu cihazda tutuluyor, sunucu tarafı
  Apple makbuz doğrulaması yok. Jailbreak'li cihazda Pro bedavaya açılabilir.
  Suistimal görülürse v1.1'de server-side doğrulama (App Store Server API)
  eklenecek. Not: bu gelir riski, kullanıcı verisi riski değil.
- **Kota/limitler client-side:** Free 100 analiz limiti ve günlük tempo cihazda
  (SharedPreferences) tutuluyor; sil-yükle sıfırlar. Proje genel kotasını asıl
  koruyan şey App Check enforcement (adım 3) + budget alert (adım 2).
- Düzeltilenler (artık risk değil): OCR metinleri dahil yerel veritabanı **AES
  şifreli** (anahtar iOS Keychain'de); izin metni gerçeği yansıtıyor; loglara
  hassas veri yazılmıyor; debug araçları `kDebugMode` korumalı; ATS varsayılan.



1. Firebase API anahtarı rotasyonu — sızan anahtar hâlâ aktif (API kısıtlı ama rotasyon yapılmadı). Cloud Console'da regenerate + bundle ID kısıtı, sonra flutterfire configure, sonra GitHub alert'ini kapat.
2. Blaze planına geçiş + budget alert — yayında free kota (~1000 istek/gün, tüm kullanıcılar ortak) yetmez. Geçince bana söyle, kodda AiRateProfile.paid'e geçişi ben yaparım.
3. App Check enforcement — Console'da şu an "Unenforced"; birkaç gün Monitor'da izleyip Gemini API için Enforce aç. API anahtarının suistimaline karşı asıl koruma bu.
4. Xcode: Team signing + App Attest capability + bekleyen Apple PLA onayı (developer.apple.com).
5. Gerçek Privacy Policy / Terms sayfaları — koddaki tek yayın blokeri; URL'leri verirsen LegalUrls'ü ben güncellerim. İstersen sayfa metinlerini de hazırlayabilirim (GitHub Pages'e koymak yeterli).
6. App Store Connect: uygulama kaydı, 5 IAP ürünü (yıllıkta 7 gün trial tanımıyla), App Privacy formu, mağaza metinleri — hepsi dokümanda kopyala-yapıştır hazır.
7. Uygulama adının kesinleşmesi — "Snaply" placeholder; değişirse kAppName + CFBundleDisplayName iki noktadan güncellenir.
8. Gerçek cihazda uçtan uca test (özellikle App Check enforce açıkken analiz + sandbox satın alma), sonra TestFlight → review.

Benim yapabileceğim iki küçük şey bekliyor: legal sayfa metinlerini hazırlamak (istersen) ve commit-convention skill'indeki eski "firebase_options.dart commit'lenir" satırını düzeltmek. Onun dışında top sende — 1. ve 5. adımlar en kritik olanlar.
