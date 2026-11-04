# Panduan GitHub (belum dijalankan)

Dokumen ini hanya panduan. Tidak ada repositori yang dibuat dan tidak ada kode yang diunggah sampai Anda menyetujuinya.

## 1. Pilih privat atau publik

| | Privat (disarankan) | Publik |
|---|---|---|
| Siapa bisa melihat kode dan aset | Hanya Anda dan orang yang Anda undang | Siapa saja di internet |
| Gambar, kode, dan data game | Tidak terlihat orang lain | Bisa disalin orang lain |
| Build GitHub Actions (gratis) | Ada kuota gratis bulanan untuk akun gratis. Cek angka terbaru di halaman harga GitHub | Tidak dibatasi untuk repositori publik |
| Unduh APK | Harus login ke GitHub dengan akses ke repositori | Siapa saja bisa mengunduh |

Risiko repositori publik: kode dan aset Anda langsung terbaca publik. Tidak ada kunci penandatanganan atau data pribadi di proyek ini (keystore dan `.env` sudah dikecualikan di `.gitignore`), tetapi aset dan kode game akan terbuka. Jika ingin mulai dari privat dan kemudian mengubahnya, GitHub mengizinkan hal itu.

Rekomendasi: mulai dengan **privat**. Kuota gratis untuk build cukup untuk pengembangan awal. Ubah ke publik hanya jika Anda memang ingin game dibuka untuk umum.

## 2. Buat akun GitHub (jika belum punya)

1. Buka https://github.com dan pilih **Sign up**.
2. Ikuti langkah verifikasi email. Gunakan paket **Free**.

## 3. Pasang Git di komputer (sekali saja)

- Windows: unduh dan pasang **Git for Windows** dari https://git-scm.com. Pilih opsi default.
- macOS: buka Terminal lalu jalankan `git --version`. Jika diminta, ikuti pemasangan Xcode Command Line Tools.
- Alternatif yang lebih mudah: **GitHub Desktop** (https://desktop.github.com). Antarmukanya grafis dan tidak perlu mengetik perintah.

Catatan: unggah lewat situs (seret dan letakkan) tidak disarankan, karena proyek ini punya ratusan file dan situs membatasi jumlah file per unggahan. Gunakan Git atau GitHub Desktop.

## 4. Buat repositori kosong

1. Di GitHub, klik **+** (pojok kanan atas) lalu **New repository**.
2. Nama: `ladang-reinkarnasi`.
3. Pilih **Private** (atau Public jika sudah setuju dengan risikonya).
4. **Jangan** centang "Add a README", ".gitignore", atau "license". Proyek sudah punya file-file itu.
5. Klik **Create repository**. Simpan alamat yang muncul, misalnya `https://github.com/USERNAME/ladang-reinkarnasi.git`.

## 5. Unggah proyek (dengan Git)

Buka Terminal di folder proyek, lalu jalankan satu per satu:

```
cd /home/claude/ladang-reinkarnasi-project
git init -b main
git add .
git commit -m "Versi awal: sumber proyek, build browser, dan konfigurasi Android"
git remote add origin https://github.com/USERNAME/ladang-reinkarnasi.git
git push -u origin main
```

Ganti `USERNAME` dengan nama akun GitHub Anda. Saat diminta login, gunakan browser untuk masuk (GitHub Desktop juga bisa melakukan ini secara grafis).

Catatan untuk komputer Anda: folder proyek berada di server, jadi Anda perlu menyalin folder tersebut ke komputer Anda terlebih dahulu sebelum menjalankan perintah di atas. Saya bisa menyiapkan arsip (zip) untuk diunduh jika Anda memintanya.

## 6. Jalankan build APK

1. Buka repositori di GitHub, lalu pilih tab **Actions**.
2. Jika diminta, klik **I understand my workflows, go ahead and enable them**.
3. Pilih **Build APK** di sisi kiri, lalu klik **Run workflow** dan konfirmasi.
4. Tunggu sekitar 10–20 menit pada build pertama (lebih cepat untuk build berikutnya).
5. Jika berhasil, buka hasil build (klik nama run), lalu di bagian **Artifacts** unduh `ladang-reinkarnasi-debug-apk`.

Jika build gagal, buka langkah yang merah, salin pesan errornya, dan kirim kepada saya.

## 7. Pasang APK di HP Android

1. Pindahkan file `app-debug.apk` ke HP (dari komputer, lewat kabel, atau dikirim ke diri sendiri).
2. Buka file itu di HP. Jika diminta, izinkan **Pasang aplikasi dari sumber ini**.
3. Pasang, lalu buka **Ladang Reinkarnasi**.

APK debug hanya untuk pengujian pribadi. Untuk Google Play diperlukan build rilis dengan kunci penandatangan. Itu langkah terpisah dan belum disiapkan.

## Hal yang belum diuji

- Build GitHub Actions belum pernah dijalankan. Bisa saja ada kesalahan kecil pada langkah Gradle atau versi Capacitor. Itu wajar pada build pertama dan akan saya perbaiki dari log.
- Versi Capacitor (`^7.0.0`) belum saya verifikasi, karena registri npm tidak bisa dijangkau dari sesi ini.
