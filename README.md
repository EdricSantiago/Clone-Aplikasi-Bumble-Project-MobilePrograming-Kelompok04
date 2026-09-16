# Alur & Cara Kerja Sistem (Workflow)

Proyek ini dibangun menggunakan **Flutter** untuk sisi antarmuka (*frontend*) serta terintegrasi dengan **Firebase** sebagai layanan *backend* (autentikasi dan basis data). Secara arsitektur, aplikasi ini dibagi menjadi beberapa modul utama dengan alur kerja sebagai berikut:

---

### 1. Alur Autentikasi Pengguna (`auth_gate.dart`, `auth_service.dart`)
* **Pendaftaran & Masuk (`login_screen.dart`, `register_screen.dart`)**: Pengguna memasukkan kredensial (email dan kata sandi). Data ini diproses oleh `AuthService` untuk divalidasi atau didaftarkan melalui layanan *Firebase Authentication*.
* **Pengarah Otomatis (`auth_gate.dart`)**: Komponen ini bertindak sebagai penjaga rute (*navigation guard*):
  * Jika sesi aktif terdeteksi (**sudah login**), aplikasi otomatis mengarahkan pengguna ke halaman utama (`home_screen.dart`).
  * Jika belum ada sesi (**belum login**), aplikasi menampilkan halaman masuk/pendaftaran.

---

### 2. Mekanisme Pencocokan / Kartu Geser (`swipe_card_stack.dart`, `swipeable_card.dart`)
* Di halaman utama, pengguna disajikan tumpukan kartu profil pengguna lain yang dimuat berdasarkan model data (`user_model.dart` & `match_model.dart`).
* **Interaksi Geser (*Swipe*)**: Pengguna dapat memberikan respons dengan menggeser kartu ke kiri (lewati) atau ke kanan (sukai).
* Komponen ini mendeteksi gestur sentuh (*touch gestures*) secara dinamis dan mencatat keputusan pencocokan (*match*) ke dalam database.

---

### 3. Sistem Obrolan Real-time (`chat_service.dart`, `chat_list_screen.dart`, `chat_detail_screen.dart`)
* **Koneksi Pesan**: Ketika dua pengguna cocok, `ChatService` memfasilitasi pertukaran pesan secara instan (*real-time*) memanfaatkan layanan cloud database.
* **Daftar & Detail Percakapan**:
  * `chat_list_screen.dart` menampilkan rangkuman seluruh ruang obrolan aktif.
  * `chat_detail_screen.dart` memuat riwayat obrolan secara mendalam antara dua pengguna dalam bentuk antarmuka percakapan (*chat bubble*).

---

### 4. Pelacakan Keaktifan (*Presence Tracking*) (`presence_service.dart`)
* `PresenceService` berjalan di latar belakang untuk memantau status koneksi pengguna.
* Fitur ini mendeteksi apakah aplikasi sedang aktif digunakan (*online*) atau ditinggalkan (*offline*), sehingga status tersebut dapat diperbarui secara langsung untuk dilihat oleh pengguna lain.

---

### 5. Pengelolaan Profil & Pengaturan (`profile_screen.dart`, `settings_screen.dart`)
* Memungkinkan pengguna untuk melihat serta memperbarui informasi data diri dan preferensi akun.
* Perubahan yang dilakukan akan langsung disinkronkan dan disimpan secara aman ke server *backend*.

---

### 💡 Ringkasan Arsitektur Perangkat Lunak
1. **Presentation Layer (`screens/` & `widgets/`)**: Menangani seluruh tampilan visual antarmuka (*UI*) serta merespons interaksi tombol/sentuhan dari pengguna.
2. **Service / Business Logic Layer (`services/`)**: Menjadi jembatan komunikasi dengan layanan eksternal (Firebase) dan memproses aturan bisnis aplikasi.
3. **Data Layer (`models/`)**: Berfungsi sebagai struktur objek data yang konsisten (seperti format data pengguna, pesan, dan status *match*).