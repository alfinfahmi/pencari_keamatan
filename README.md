# Pencari Kecamatan Indonesia

Aplikasi pencarian data kecamatan seluruh Indonesia (offline), dibangun dengan
Flutter untuk Android, iOS, macOS, Windows, dan Web — LF Ma'had 'Aly Lirboyo &
Madrasah Hidayatul Mubtadiin (MHM) Kediri.

## Cara Menjalankan di VS Code

> **Tidak mau install Flutter/Android SDK di laptop?** Lihat
> `PANDUAN_GITHUB_ACTIONS.md` — build APK otomatis di cloud lewat GitHub
> Actions, tanpa install apa pun secara lokal.


0. **WAJIB DIBACA** — folder ini HANYA berisi kode sumber (`lib/`,
   `pubspec.yaml`, `assets/`, `test/`). Folder platform native
   (`android/`, `ios/`, `macos/`, `windows/`, `web/`) BELUM ada, karena
   folder tersebut hanya bisa digenerate oleh Flutter SDK asli (tidak
   tersedia di lingkungan saya menulis kode ini). **Sebelum langkah apa pun
   di bawah**, jalankan di root folder project:
   ```bash
   flutter create --platforms=android,ios,macos,windows,web .
   ```
   Perintah ini aman dijalankan di folder yang sudah berisi `lib/` &
   `pubspec.yaml` — Flutter akan menambahkan folder platform tanpa menimpa
   kode yang sudah ada. Setelah ini folder `android/`, `ios/`, dst. akan
   muncul dan project baru bisa di-build.
1. Pastikan Flutter SDK sudah terpasang (`flutter doctor` harus hijau semua
   untuk platform yang ingin di-build).
2. Buka folder project ini di VS Code, install extension **Flutter** &
   **Dart** (biasanya otomatis muncul rekomendasinya).
3. Jalankan di terminal VS Code:
   ```bash
   flutter pub get
   ```
4. Regenerasi adapter Hive secara resmi (file
   `lib/models/custom_point_model.g.dart` sudah saya sertakan versi tulisan
   tangan yang seharusnya identik hasilnya, tapi disarankan regenerasi resmi
   sebagai verifikasi):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. **WAJIB** — enkripsi data sebelum menjalankan aplikasi (lihat bagian
   *Enkripsi Data* di bawah):
   ```bash
   python3 encrypt_data.py
   ```
6. (Opsional, hanya jika ingin regenerasi) generate ikon & splash native:
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```
   Ikon (`assets/images/app_icon.png`) dan splash logo
   (`assets/images/splash_logo.png`) sudah saya sertakan siap pakai, jadi
   langkah ini opsional kecuali Anda ingin mengganti desainnya.
7. Jalankan aplikasi:
   ```bash
   flutter run                # pilih device: Android/iOS/macOS/Windows/Chrome
   flutter run -d chrome      # khusus web
   flutter run -d macos       # khusus macOS
   ```
8. Jalankan unit test:
   ```bash
   flutter test
   ```

## Serial Number Aktivasi

Kata kunci aktivasi: **`falak`** (tidak peka huruf besar/kecil).
Disimpan sebagai hash SHA-256 di `lib/services/activation_service.dart`,
bukan teks polos.

Sebelum rilis produksi ke Android/iOS/Desktop, build dengan obfuscation agar
lebih sulit di-reverse-engineer:
```bash
flutter build apk --obfuscate --split-debug-info=build/symbols
flutter build ios --obfuscate --split-debug-info=build/symbols
```

**Catatan jujur soal Web:** proteksi serial number pada build web
(`flutter build web`) TIDAK benar-benar tersembunyi — semua kode JS dapat
dilihat lewat DevTools/View Source siapa pun. Untuk versi web, kalau
perlindungan dianggap penting, cara yang benar-benar efektif adalah
password-protect di level hosting (mis. Netlify/Firebase Hosting Access
Control atau .htaccess), bukan mengandalkan logic di dalam aplikasi.

## Enkripsi Data (Mobile & Desktop)

`data_koordinat.json` (2.5MB, sumber asli hasil konversi Excel) TIDAK lagi
disimpan di `assets/` — dipindah ke `data_source/` (di luar folder assets,
supaya tidak ikut ter-bundle ke build final). Yang dibundel ke aplikasi
adalah `assets/data/data_koordinat.enc`, hasil enkripsi AES-256-CBC.

Alur kerja saat data master diperbarui (Excel v8, v9, dst.):
```bash
python3 convert_to_json.py            # Excel -> data_source/data_koordinat.json
python3 encrypt_data.py               # -> assets/data/data_koordinat.enc (mobile/desktop)
python3 split_data_per_provinsi.py    # -> assets/data/web/... (web)
```

`lib/services/decryption_service.dart` mendekripsi file `.enc` ke memori
saat runtime (`DataRepository.load()` memanggilnya otomatis).

**Catatan jujur:** kunci AES tertanam di kode Dart (`_keyHex` di
`decryption_service.dart`) tetap bisa ditemukan lewat decompile APK/IPA oleh
pihak yang punya niat & keahlian teknis — sama seperti batasan hash serial
number. Ini menaikkan hambatan (data tidak bisa dibuka begitu saja di editor
teks/File Explorer), bukan proteksi kriptografi tingkat militer. Kombinasikan
dengan `--obfuscate --split-debug-info` saat build produksi.

Kunci di `encrypt_data.py` dan `decryption_service.dart` sudah saya
generate & tempatkan secara terprogram (bukan diketik ulang manual di dua
tempat) untuk menghindari salah salin — sudah saya verifikasi kedua sisi
identik.

## Kompas Kiblat Offline (pengganti Peta Mini)

Alih-alih peta bertile online (Google Maps/OSM, yang perlu internet — jadi
bertentangan dengan syarat 100% offline), halaman detail menampilkan
**kompas kiblat** hasil gambar manual (`lib/widgets/qibla_compass.dart`,
`CustomPainter`, tanpa dependensi jaringan/tile). Jarum emas menunjuk arah
bearing menuju Ka'bah dari titik yang dipilih.

**Mode LIVE (mengikuti orientasi perangkat):** memakai package
`flutter_compass` untuk membaca sensor magnetometer. Jika perangkat
mendukung dan izin diberikan, dial kompas berputar otomatis mengikuti arah
hadap perangkat sungguhan (mirip aplikasi kompas kiblat pada umumnya),
ditandai label "LIVE" kecil di bawah kompas.

**Fallback otomatis ke mode STATIS** (utara selalu di atas layar) jika
sensor tidak tersedia — umum terjadi di desktop/web/emulator tanpa
magnetometer, atau jika izin ditolak. Tidak ada error yang muncul ke
pengguna; tampilan hanya diam menunjukkan derajat bearing yang tetap benar.

**Perlu ditambahkan secara manual setelah `flutter create` (langkah 0):**
- **iOS** (`ios/Runner/Info.plist`): `flutter_compass` di iOS membaca
  heading lewat CoreLocation, sehingga WAJIB menambahkan izin lokasi, atau
  kompas akan selalu jatuh ke mode statis di iOS:
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Dipakai untuk kompas kiblat dan menambah titik koordinat dari lokasi Anda</string>
  ```
  (Key yang sama juga dipakai oleh fitur "Ambil dari GPS Perangkat" di
  `add_point_screen.dart` — jadi cukup ditambahkan sekali.)
- **Android**: umumnya tidak perlu permission tambahan di
  `AndroidManifest.xml` untuk sensor magnetometer/accelerometer (bukan
  "dangerous permission"), tapi untuk fitur GPS (`geolocator`) tetap perlu:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  ```

## Menghemat Ukuran APK/IPA (data web tidak ikut terbundel)

Folder `assets/data/web/` (~2MB, khusus dipakai target Web) secara bawaan
akan ikut ter-bundle ke SEMUA platform oleh Flutter — termasuk APK/IPA yang
sama sekali tidak memakainya (mobile pakai `data_koordinat.enc`, bukan data
per-provinsi). `prepare_build.py` menyediakan solusi praktis: memindahkan
folder itu keluar-masuk project sebelum build, tanpa perlu setup product
flavors Android/scheme iOS yang lebih rumit.

```bash
# Build rilis mobile (APK/IPA) tanpa data web ikut terbundel:
python3 prepare_build.py mobile
flutter build apk --obfuscate --split-debug-info=build/symbols
flutter build ios --obfuscate --split-debug-info=build/symbols

# Build rilis web (butuh data web ada):
python3 prepare_build.py web
flutter build web --release

# Setelah selesai build, kembalikan ke kondisi normal untuk development:
python3 prepare_build.py restore
```

**Catatan jujur:** ini solusi pragmatis (memindah file sebelum build lewat
skrip manual), bukan konfigurasi asset-variant resmi Flutter. Cukup untuk
kebutuhan rilis manual seperti project ini. Jika nanti dipakai CI/CD
otomatis, sebaiknya diganti dengan product flavors yang lebih standar.

## Ikon & Splash Screen

`assets/images/app_icon.png` (1024×1024, siluet masjid hijau zamrud/emas di
atas lingkaran gradasi) dan `assets/images/splash_logo.png` (versi
transparan untuk splash native) sudah tersedia. Konfigurasi
`flutter_launcher_icons` & `flutter_native_splash` sudah ada di
`pubspec.yaml` — tinggal jalankan perintah generate di langkah 6 di atas
untuk menerapkannya ke setiap platform.

**Ikon adaptif Android** juga sudah dikonfigurasi:
`app_icon_background.png` (hijau zamrud solid) dan
`app_icon_foreground.png` (siluet masjid putih, digambar dalam radius "safe
zone" 66% sesuai spesifikasi
[Android Adaptive Icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive) —
sudah saya verifikasi lewat komposit test bahwa seluruh siluet berada di
dalam batas aman, tidak terpotong mask launcher apa pun (lingkaran, persegi
membulat, tetesan air, dst.).

## Struktur Folder

```
lib/
  main.dart                        # entry point, init Hive, theme controller
  theme/app_theme.dart             # palet Hijau Zamrud (#0D5C3A) & Warm Gold (#D4AF37)
  models/
    kecamatan_model.dart           # model data referensi & kecamatan (dari JSON)
    custom_point_model.dart        # model titik kustom (Hive)
    custom_point_model.g.dart      # Hive TypeAdapter (regenerasi via build_runner)
  services/
    app_data_service.dart          # facade tunggal: pilih DataRepository (mobile) / WebDataRepository (web)
    data_repository.dart           # load & index data terenkripsi (mobile/desktop)
    decryption_service.dart        # dekripsi AES-256-CBC saat runtime
    web_data_repository.dart       # lazy-load per provinsi (web)
    qibla_service.dart             # bearing arah kiblat & jarak great-circle
    activation_service.dart        # verifikasi serial number (hash SHA-256)
    favorite_service.dart          # favorit & riwayat pencarian (Hive)
    custom_point_service.dart      # CRUD + ekspor/impor titik kustom (Hive)
  screens/
    splash_screen.dart             # load data, cek status aktivasi
    activation_screen.dart         # input serial number
    home_screen.dart               # pencarian instan + tab favorit/riwayat
    detail_screen.dart             # detail lengkap + kiblat + jarak + kompas + salin data
    add_point_screen.dart          # form tambah titik kustom (desa/dusun/masjid)
  widgets/
    kecamatan_card.dart            # kartu hasil pencarian
    watermark_footer.dart          # watermark LF Ma'had 'Aly Lirboyo (semua layar)
    qibla_compass.dart             # kompas kiblat offline/live (CustomPainter + flutter_compass)
test/
  qibla_service_test.dart          # unit test bearing & jarak, diverifikasi silang dengan Python
  kecamatan_model_test.dart        # unit test parsing JSON, searchIndex, format salin data
  activation_service_test.dart     # unit test verifikasi hash serial number
  qibla_compass_widget_test.dart   # widget test render kompas (fallback mode statis)
data_source/
  data_koordinat.json              # sumber data PLAIN (tidak ter-bundle ke aplikasi)
assets/
  data/data_koordinat.enc          # data terenkripsi AES-256 (mobile/desktop)
  data/web/                        # data terpecah per-provinsi (web)
  images/
    app_icon.png, splash_logo.png            # ikon utama & splash native
    app_icon_background.png                  # background ikon adaptif Android (hijau solid)
    app_icon_foreground.png                  # foreground ikon adaptif Android (siluet putih, safe zone 66%)
encrypt_data.py                    # data_source/*.json -> assets/data/*.enc
split_data_per_provinsi.py         # data_source/*.json -> assets/data/web/...
convert_to_json.py                 # Excel master -> data_source/data_koordinat.json
prepare_build.py                   # pindah/kembalikan assets/data/web/ sebelum build mobile vs web
```

## Yang Masih Perlu Dikerjakan / Diputuskan

- **Cakupan unit test** mencakup `QiblaService` (bearing & jarak, diverifikasi
  silang dengan Python), `KecamatanModel` (parsing & format), hash serial
  number (`ActivationService.verifySerial`), dan widget test dasar untuk
  `QiblaCompass`. Belum ada test untuk `DataRepository`/`WebDataRepository`
  (perlu mock asset bundle) atau golden test tampilan penuh.
- Belum ada **CI/CD** (GitHub Actions dsb.) — build & test masih manual.

---
*LF Ma'had 'Aly Lirboyo — Madrasah Hidayatul Mubtadiin (MHM), Kediri*
