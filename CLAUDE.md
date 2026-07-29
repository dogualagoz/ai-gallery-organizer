# AI Screenshot Organizer

iOS-only Flutter uygulaması: galerideki screenshot'ları Gemini ile kategorize eder, aratır, temizletir. Detaylı ürün dökümanı: `PROJECT_DOCUMENTATION.md` (gerektiğinde oku, her turn değil).

## Stack

- Flutter (master channel, Dart 3.13) — sadece iOS hedefi
- State: Riverpod (`flutter_riverpod`) • Navigasyon: `go_router`
- Local DB: `hive_ce` (Isar/klasik hive KULLANMA — bakımsız)
- Galeri: `photo_manager` (screenshot subtype filtresi)
- AI: `firebase_ai` (Gemini Developer API, structured output)
- IAP: `in_app_purchase` (StoreKit 2)
- L10n: `flutter gen-l10n`, TR + EN — kullanıcıya görünen string hardcode edilmez

## Komutlar

```
flutter analyze                          # her blok sonunda temiz olmalı
flutter test                             # tüm testler
flutter test test/retry_policy_test.dart # tek dosya
flutter run -d "iPhone 17"               # iOS 26.4 simülatörü
dart run build_runner build --delete-conflicting-outputs  # hive adapter codegen
```

`build_runner`'ı yalnızca Hive model dosyaları (`lib/core/models/`) değişince çalıştır — `.g.dart` adapter'ları elle düzenlenmez.

## Yapı

Feature-first: `lib/core/` (theme, constants, services, router) + `lib/features/<feature>/` (her feature kendi widget/provider/repository dosyaları). UI, state ve veri erişimi ayrı dosyalarda.

### Big picture (birden fazla dosya okumadan görünmeyen akış)

- **Açılış (`main.dart`):** SharedPreferences → Hive → Firebase → App Check sırayla `await` edilir, sonra `ProviderScope`. Router redirect'i prefs'i **senkron** okur, o yüzden prefs açılışta yüklenmiş olmalı. Kök widget `purchaseFlowProvider`'ı `listen` eder — paywall kapalıyken tamamlanan/restore satın almalar yakalanır.
- **Navigasyon (`core/router/app_router.dart`):** `StatefulShellRoute.indexedStack` ile 3 sekmeli kabuk + tam ekran rotalar. Yollar `AppRoutes` sabitlerinden gelir. Onboarding tamamlanınca redirect otomatik yönlendirir. Detay rotasında iOS asset ID'leri slash içerdiği için `Uri.encodeComponent` şart.
- **AI pipeline (`features/analysis/`):** `analysis_queue_provider` bekleyen screenshot'ları `ai_rate_profile`'a göre (seri ya da paralel worker havuzu) `screenshot_analyzer`'a verir; analyzer `firebase_ai` ile **structured output** (kategori enum + etiketler + OCR metni) alır, `retry_policy` ile backoff yapar. Sonuç `screenshot_entry` olarak Hive'a yazılır. Tüm AI ayarları `core/constants/ai_constants.dart` + `ai_rate_profile.dart`'ta — ücretli katmana geçiş tek satır (`AiConfig.activeProfile`).
- **Freemium (`core/services/entitlement_service.dart` + `features/paywall/`):** haftalık AI analiz kotası, swipe sayacı, trial penceresi ve paket kredileri burada tutulur; `daily_quota_tracker` günlük API tavanını ayrı izler. IAP (`in_app_purchase`, StoreKit 2) `purchase_repository`/`purchase_provider` üzerinden `isPro` ve `analysisCredits`'i günceller.
- **Kategoriler & board'lar:** `ScreenshotCategory` enum sistem kategorileri; kullanıcı board'ları `features/boards/`. Sıralama ve isimlendirme `category_order_service` / `category_names_service` ile kalıcı.

Uygulama adı tek sabitten: `kAppName` (`core/constants/app_constants.dart`, şu an `Snaply`).

## Kurallar

- **Az emoji:** UI'da emoji kullanma; ikon ve illüstrasyon kullan.
- Tema: açık default + koyu tam destekli. Renkler hep `Theme.of(context).colorScheme` üzerinden, hardcode renk yok.
- Sabitler `lib/core/constants/` altında; magic number/string yasak.
- Fonksiyon/widget ~50 satırı geçerse parçala. Hata sessiz yutulmaz (log ya da kullanıcıya durum).
- Yorumlar: dosya başına 1 satır amaç açıklaması; public API'ye `///` doc; non-obvious mantıkta "neden" yorumu. Yorumlar Türkçe, kod İngilizce.
- Her blok sonunda: `flutter analyze` temiz → Conventional Commit → push (checkpoint).

## Compact policy

Compact yaparken şunları mutlaka koru: değiştirilen dosya listesi, build/test komutları, verilmiş mimari kararlar (DB=hive_ce, IAP=in_app_purchase, tema stratejisi).
