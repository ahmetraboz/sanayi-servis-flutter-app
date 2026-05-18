# Sanayi Servis App

Servis sağlayıcılar için Flutter uygulaması.

## İlk Kurulum

### 1. `.env` dosyasını yerleştir

Ekipten aldığın `.env` dosyasını repo'nun **ana klasörüne** (pubspec.yaml'ın yanına) koy:

```
sanayi-servis-flutter-app/
├── .env              ← BURAYA KOY
├── pubspec.yaml
├── lib/
├── android/
├── ios/
└── scripts/
    └── setup.sh
```

`.env` dosyasının içeriği:
```
GOOGLE_MAPS_KEY=buraya_key_yaz
```

### 2. Setup script'ini çalıştır

```bash
./scripts/setup.sh
```

Bu script `.env` içindeki key'i okuyup şu dosyaları **otomatik üretir**:
- `android/local.properties` → Android build'ine enjekte edilir
- `ios/Flutter/Maps.xcconfig` → iOS build'ine enjekte edilir

### 3. Bağımlılıkları yükle ve çalıştır

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

> **Not:** `.env`, `android/local.properties` ve `ios/Flutter/Maps.xcconfig` dosyaları gitignore'dadır — commitleme, her geliştirici kendi makinasında oluşturur.
