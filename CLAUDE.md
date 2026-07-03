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
flutter analyze            # her blok sonunda temiz olmalı
flutter test
flutter run -d "iPhone 17" # iOS 26.4 simülatörü
dart run build_runner build --delete-conflicting-outputs  # hive adapter codegen
```

## Yapı

Feature-first: `lib/core/` (theme, constants, services, router) + `lib/features/<feature>/` (her feature kendi widget/provider/repository dosyaları). UI, state ve veri erişimi ayrı dosyalarda.

## Kurallar

- **Az emoji:** UI'da emoji kullanma; ikon ve illüstrasyon kullan.
- Tema: açık default + koyu tam destekli. Renkler hep `Theme.of(context).colorScheme` üzerinden, hardcode renk yok.
- Sabitler `lib/core/constants/` altında; magic number/string yasak. Uygulama adı tek sabitten gelir (placeholder).
- Fonksiyon/widget ~50 satırı geçerse parçala. Hata sessiz yutulmaz (log ya da kullanıcıya durum).
- Yorumlar: dosya başına 1 satır amaç açıklaması; public API'ye `///` doc; non-obvious mantıkta "neden" yorumu. Yorumlar Türkçe, kod İngilizce.
- Her blok sonunda: `flutter analyze` temiz → Conventional Commit → push (checkpoint).

## Compact policy

Compact yaparken şunları mutlaka koru: değiştirilen dosya listesi, build/test komutları, verilmiş mimari kararlar (DB=hive_ce, IAP=in_app_purchase, tema stratejisi).
