---
name: ios-release-check
description: App Store gönderimi öncesi zorunlu checklist — release hazırlığı yapılırken veya "yayına hazır mıyız" sorulduğunda kullan.
---

# iOS Release Checklist

Her maddeyi kodda/konfigde DOĞRULA (varsayma), sonucu ✓/✗ raporla:

## Paywall & IAP (review'da bizzat test edilir — en riskli)
- [ ] Paywall'da **Restore Purchases** butonu var ve çalışıyor
- [ ] Abonelik şartları, otomatik yenileme açıklaması, iptal bilgisi paywall'da görünür
- [ ] Terms of Use (EULA) + Privacy Policy linkleri paywall VE ayarlarda tıklanabilir
- [ ] Ürün ID'leri App Store Connect tanımlarıyla eşleşiyor
- [ ] Trial (introductory offer) App Store Connect'te tanımlı — kullanıcıya not düş
- [ ] Satın alma başarısız/iptal durumları kullanıcıya düzgün gösteriliyor

## İzinler & Gizlilik
- [ ] `NSPhotoLibraryUsageDescription` net gerekçeli (TR+EN, `InfoPlist.strings`)
- [ ] `PrivacyInfo.xcprivacy` privacy manifest mevcut ve doğru
- [ ] App Privacy formu cevapları dokümante (APP_STORE_NOTES.md)
- [ ] Görsellerin cihazda kaldığı / AI'a geçici gönderildiği uygulama içinde beyan ediliyor

## Build & Meta
- [ ] `flutter analyze` temiz, `flutter test` geçiyor
- [ ] `flutter build ios --release --no-codesign` başarılı
- [ ] Versiyon/build number güncel (`pubspec.yaml`)
- [ ] App icon tüm boyutlarda, launch screen düzgün
- [ ] TR + EN lokalizasyon eksiksiz (hardcoded string taraması: `grep -rn "Text('" lib/ | grep -v l10n` benzeri kontrol)
- [ ] Placeholder uygulama adı finalize edildi mi? (app_constants + Info.plist CFBundleDisplayName)
- [ ] Review notu hazır (Apple reviewer'ın AI özelliğini test edebilmesi için)
