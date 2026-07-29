---
name: commit-convention
description: Blok sonu checkpoint commit'i atarken kullan — Conventional Commits formatı ve push akışı.
---

# Commit Konvansiyonu

Her ana blok sonunda checkpoint: analyze temiz → commit → push.

## Akış

1. `flutter analyze` — hata varsa commit ATMA, önce düzelt.
2. `git add -A` ve `git status` ile ne girdiğini kontrol et (istenmeyen dosya varsa `.gitignore`'a ekle).
3. Commit mesajı Conventional Commits:
   - `feat: ...` yeni özellik bloğu
   - `fix: ...` hata düzeltme
   - `chore: ...` altyapı/konfig
   - `refactor:`, `docs:`, `test:` gerektiğinde
4. Mesaj İngilizce, emirsel kip, küçük harfle başlar, 72 karakteri geçmez. Gövdeye gerekiyorsa madde madde ne değişti yazılır.
5. `git push origin main`.

## Not

- `firebase_options.dart` ve `GoogleService-Info.plist` commit'lenir (client config, gizli değil) — ama API key kısıtlamaları Firebase konsolunda yapılmalı.
- Üretilmiş dosyalar (`*.g.dart`) commit'lenir (CI yok, build tekrarlanabilirliği için).
