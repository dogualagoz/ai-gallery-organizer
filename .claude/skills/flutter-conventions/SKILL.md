---
name: flutter-conventions
description: Bu projenin Flutter/Riverpod konvansiyonları — yeni feature, provider, repository veya widget eklerken kullan.
---

# Flutter Konvansiyonları (bu proje)

## Klasör düzeni

```
lib/core/
  constants/app_constants.dart      # app adı, free limitleri, kategori seti
  theme/app_theme.dart              # açık+koyu ColorScheme, tipografi
  router/app_router.dart            # go_router tanımı
  services/                         # hive init, entitlement servisi
  widgets/                          # 2+ feature'da kullanılan ortak widget'lar
lib/features/<feature>/
  <feature>_screen.dart             # ekran (UI)
  widgets/                          # feature'a özel parça widget'lar
  providers/<feature>_provider.dart # Riverpod state
  data/<feature>_repository.dart    # veri erişimi (Hive / photo_manager / API)
```

## Riverpod pattern

- `flutter_riverpod` klasik API (codegen YOK — `riverpod_generator` kullanılmaz).
- Değişmez state sınıfı + `Notifier`/`AsyncNotifier`; provider'lar `final xProvider = NotifierProvider<...>(...)` şeklinde dosya sonunda.
- Repository'ler `Provider` ile expose edilir; Notifier içinden `ref.read(repoProvider)` ile erişilir.
- Widget'ta `ConsumerWidget` / `ConsumerStatefulWidget`; `ref.watch` build içinde, `ref.read` callback'lerde.

## İsimlendirme

- Dosya: `snake_case.dart`, sınıf: `PascalCase`, provider: `camelCaseProvider`.
- Ekranlar `XxxScreen`, kart/parça widget'lar açıklayıcı (`ScreenshotGridTile`, `PlanCard`).
- Hive box isimleri ve ürün ID'leri `app_constants.dart`'ta sabit.

## Widget kuralları

- 50+ satır build metodu → alt widget'lara böl (metoda değil, ayrı `class`'a — rebuild performansı).
- Renk/spacing hardcode etme: `Theme.of(context)` + `AppSpacing` sabitleri.
- Kullanıcıya görünen her string `context.l10n.xxx` üzerinden (Blok 8 öncesi geçici sabitler `// TODO(l10n)` işaretli olabilir).
- Animasyonlar: önce implicit (`AnimatedX`, `TweenAnimationBuilder`), gerekirse explicit `AnimationController`; süreler `AppDurations` sabitlerinden.
