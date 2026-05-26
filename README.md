# JobAble Gesture Assist

JobAble Gesture Assist merupakan pengembangan fitur aksesibilitas pada aplikasi JobAble. Fitur ini memanfaatkan kamera real-time untuk mendeteksi gesture tangan pengguna dan menerjemahkannya menjadi aksi navigasi di dalam aplikasi.

Fitur ini ditujukan untuk membantu pengguna, khususnya pengguna dengan keterbatasan motorik, agar dapat melakukan navigasi aplikasi dengan lebih mudah tanpa harus selalu menggunakan interaksi sentuh secara langsung.

## Anggota Kelompok

- Azkha Nazzala Prasadha Dies (241511069)
- Rahma Attaya Tamimah (241511088)
- Zahra Aldila (241511094)

## Latar Belakang

Aplikasi JobAble sebelumnya telah memiliki fitur aksesibilitas dasar seperti pengaturan ukuran teks, mode kontras tinggi, dan dukungan aksesibilitas lainnya. Namun, pengguna dengan keterbatasan motorik masih dapat mengalami kesulitan saat harus melakukan navigasi menggunakan sentuhan secara presisi.

Oleh karena itu, dikembangkan fitur JobAble Gesture Assist sebagai alternatif navigasi berbasis gesture tangan menggunakan kamera real-time.

## Tujuan Proyek

- Mengembangkan fitur navigasi berbasis gesture tangan pada aplikasi JobAble.
- Mendeteksi gesture tangan secara real-time menggunakan kamera.
- Mengubah gesture menjadi aksi navigasi aplikasi.
- Meningkatkan aksesibilitas bagi pengguna dengan keterbatasan motorik.
- Mengintegrasikan fitur gesture ke dalam flow utama Job Seeker.

## Gesture yang Digunakan

| Gesture | Fungsi |
|---|---|
| Open Palm | Navigasi ke item/lowongan berikutnya |
| Thumbs Up | Konfirmasi atau membuka detail/submit |
| Fist | Kembali ke halaman sebelumnya |

## Fitur Utama

- Realtime camera stream
- Deteksi gesture tangan
- Klasifikasi gesture Open Palm, Thumbs Up, dan Fist
- Mini camera preview
- Hand landmark overlay
- Gesture navigation pada Home Page
- Gesture navigation pada Job Detail Page
- Gesture action pada Apply Job Page
- Gesture log menggunakan Hive
- Sinkronisasi gesture log ke MongoDB
- Toggle Gesture Mode dari Home Page
- Mode Kontras Tinggi untuk aksesibilitas

## Integrasi Gesture pada Aplikasi

### Home Page

- Open Palm: berpindah ke lowongan berikutnya
- Thumbs Up: membuka detail lowongan
- Fist: kembali atau keluar dari flow jika memungkinkan

### Job Detail Page

- Open Palm: scroll detail lowongan
- Thumbs Up: lanjut ke halaman apply job
- Fist: kembali ke halaman sebelumnya

### Apply Job Page

- Thumbs Up: submit lamaran
- Fist: kembali ke halaman sebelumnya

## Teknologi yang Digunakan

- Flutter
- Dart
- Camera Package
- MediaPipe / Hand Landmark Detection
- Hive Local Storage
- MongoDB
- Provider State Management
- CustomPainter untuk overlay landmark tangan

## Alur Sistem

```text
User mengaktifkan Gesture Mode
        ↓
Camera stream berjalan
        ↓
Sistem mendeteksi gesture tangan
        ↓
Gesture diklasifikasikan
        ↓
Gesture diubah menjadi aksi navigasi
        ↓
Aksi dijalankan pada halaman aktif
        ↓
Riwayat gesture disimpan ke Hive
        ↓
Data dapat disinkronkan ke MongoDB
