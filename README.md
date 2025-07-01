# ☀️ Dijital Enerji Üretim Takip Uygulaması

Bu proje, güneş enerjisi üretim sistemlerinde dijitalleşmenin yaygınlaştırılmasına yönelik geliştirilmiş Flutter tabanlı bir mobil uygulamadır. Uygulama, kullanıcıların konumlarına göre güneş paneli sistemleri oluşturmasına, bu sistemlerin üretim tahminlerini görüntülemesine ve geçmiş verilerini takip etmesine olanak tanır. Sistem, hem gerçek zamanlı API entegrasyonları hem de yerel veri depolama yöntemleri kullanılarak yapılandırılmıştır.

---

## 📱 Özellikler

- 🌍 Konum bazlı güneş enerjisi üretim tahmini
- ➕ Güneş paneli sistemi ekleme (kapasite, eğim, yön bilgisiyle)
- 📊 Günlük ve haftalık enerji üretim grafikleri
- 🗃️ SQLite ile yerel veri saklama
- 🔔 Bildirim sistemi (bakım hatırlatıcıları, hava durumu uyarıları)
- 🌤️ Forecast.Solar ve Open-Meteo API entegrasyonu
- 🇹🇷 Türkçe kullanıcı arayüzü desteği

---

## 🔧 Kullanılan Teknolojiler

- **Flutter** & **Dart** – Mobil uygulama geliştirme
- **SQLite** – Yerel veritabanı yönetimi
- **Forecast.Solar API** – Güneş paneli üretim tahmini
- **Open-Meteo API** – Hava durumu verisi sağlama
- **Flutter Local Notifications** – Bildirim yönetimi

---

## 🚀 Kurulum

Aşağıdaki adımları izleyerek projeyi yerel ortamınıza kurabilirsiniz:

1. Reponun klonlanması:
```bash
git clone https://github.com/kullaniciadi/enerji-uretimi-app.git
cd enerji-uretimi-app
```

2. Gerekli bağımlılıkların kurulması:
```bash
flutter pub get
```

3. Uygulamanın çalıştırılması:
```bash
flutter run
```

---

## 🔑 API Anahtarları

Uygulamanın çalışabilmesi için Forecast.Solar ve Open-Meteo servislerinden alınan API anahtarlarına ihtiyaç vardır:

1. [https://forecast.solar](https://forecast.solar) adresinden ücretsiz kayıt olun ve API anahtarınızı alın.
2. `lib/services/api_service.dart` dosyasına giderek aşağıdaki gibi anahtarı ekleyin:
```dart
final apiKey = 'YOUR_API_KEY_HERE';
```
---

## 🗂️ Proje Yapısı (Klasörler)

```
lib/
├── databese/     # Veritabanı
├── models/       # Veri modelleri
├── screens/      # Sayfa arayüzleri
├── services/     # API ve veritabanı servisleri
├── theme/        # Tema
├── utils/        # Yardımcı bileşenler
├── widgets/      # Tekrar kullanılabilir bileşenler
└── main.dart     # Uygulamanın başlangıç noktası
```

---


Geliştiren: **Ahmet Özalp**  
Danışman: **Prof. Dr. Zekeriya Tüfekçi**  
Çukurova Üniversitesi – Bilgisayar Mühendisliği (2025)


