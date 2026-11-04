# Ladang Reinkarnasi

Satu sumber proyek, dua target:
- **Browser** (untuk pengembangan dan pengujian): `dist/web/`
- **Android APK** (Capacitor): dibangun dari `dist/web/` menjadi aplikasi offline.

## Struktur

```
src/game.html          kode dan markup game (satu file, dipecah nanti)
assets/
  registry.json        pemetaan nama lama (hash) ke nama baru untuk setiap gambar
  images/              gambar game per kategori: terrain, efek, sprite, item, dekorasi, bangunan, hud, lainnya
  ui/                  ikon, panel, tombol, dan aset UI (nama deskriptif)
  audio/               efek suara (.wav)
  pancing/             gambar pemancingan
build/
  build.py             build browser: dist/web/ (pack + indeks otomatis)
  android_patch.py     penyesuaian proyek Android (minSdk 26, orientasi)
backup/                salinan versi 718 (jangan dihapus)
capacitor.config.json  konfigurasi Capacitor (appId, nama, webDir)
.github/workflows/     build APK otomatis di GitHub Actions
```

## Menambah aset

1. Letakkan file di folder kategorinya (`assets/ui/`, `assets/audio/`, dan seterusnya).
2. Rujuk aset di kode dengan path lengkap dari `assets/`, misalnya `assets/ui/tombol_baru.png`.
3. Jalankan `python3 build/build.py`.

Build akan:
- memeriksa bahwa setiap path yang dirujuk ada (gagal jika tidak ada),
- membuat indeks (`dist/web/assets/index.json`) dan pack otomatis,
- memberi tahu aset yang ada tapi tidak dirujuk.

Jangan mengedit `dist/` secara manual. Folder itu dibuat ulang setiap build.

Nama gambar baru dicatat di `assets/registry.json` oleh proses penamaan. Saat menambah gambar sendiri, letakkan di folder kategori yang sesuai dan beri nama deskriptif. Build akan memberi peringatan jika ada gambar yang belum tercatat di registry.

## Build browser

```
python3 build/build.py
cd dist/web && python3 -m http.server 8080
```

Buka `http://127.0.0.1:8080/` di browser. Semua aset dimuat dari folder yang sama, tanpa internet.

## Build Android (APK)

Build APK membutuhkan Node.js, JDK 17 atau lebih baru, dan Android SDK. Di komputer tanpa Android Studio, gunakan GitHub Actions:

1. Push proyek ini ke repositori GitHub (repositori pribadi atau publik).
2. Buka tab **Actions**, pilih **Build APK**, lalu klik **Run workflow**.
3. Setelah selesai, unduh artefak `ladang-reinkarnasi-apk`, lalu pasang `ladang-reinkarnasi.apk` di HP. Aktifkan "Pasang aplikasi tidak dikenal" di pengaturan HP saat pertama kali memasang.

Atau secara lokal dengan Android Studio:

```
npm install
npm run build:android
```

### Penyesuaian Android

- `minSdkVersion` = 26 (Android 8.0), diatur oleh `build/android_patch.py`.
- Orientasi tidak dikunci: portrait dan landscape didukung. Saat rotasi, aktivitas tidak dimulai ulang.
- Semua aset ikut terpasang di APK. Game berjalan offline setelah dipasang.
- Save game tersimpan di penyimpanan WebView (localStorage) dan bertahan setelah aplikasi ditutup.

### Penandatanganan (kunci tetap)

APK selalu ditandatangani dengan kunci tetap. Kunci tidak pernah ada di repositori. Isinya disimpan sebagai GitHub Secrets:

- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

Kunci yang sama harus dipakai untuk setiap build. Jika kunci berubah, pembaruan tidak bisa dipasang di atas versi lama dan data save ikut hilang. Cadangan kunci disimpan di luar repositori.

Pemulihan kunci: jika secret hilang, isi ulang empat secret di atas dari cadangan. Jangan membuat kunci baru kecuali benar-benar terpaksa.

## Batas ukuran

- Publikasi artefak browser memiliki batas (HTML 16 MB, file 15 MB, total versi 256 MB). Batas ini tidak berlaku untuk APK.
- Pack sudah dipecah per kategori dengan ukuran di bawah 8 MB per file.

## Orientasi layar

- HP (layar sentuh): layout mengikuti arah layar secara otomatis (portrait atau landscape). Orientasi perangkat tidak dikunci.
- PC: tetap seperti sebelumnya. Pengaturan Vertikal/Horizontal di menu masih tersedia.

## Memasang pembaruan di HP

1. Buka tautan rilis terbaru: https://github.com/hadydaw/ladang-reinkarnasi/releases/latest/download/ladang-reinkarnasi.apk
2. Unduh dan pasang di atas aplikasi yang sudah ada. Jangan hapus aplikasi lama, karena data save ikut tersimpan.

Setiap rilis baru memiliki nomor versi yang lebih tinggi, sehingga bisa dipasang di atas versi sebelumnya.

## Panduan GitHub

Lihat `GITHUB-PANDUAN.md`. Proyek ini belum diunggah ke GitHub.

## Riwayat

- `backup/ladang-reinkarnasi-v718.html`: versi browser yang dipublikasikan sebagai versi 718. Hasil build saat ini sudah diuji identik untuk layar Tas, Bangun, dan menu PC.
