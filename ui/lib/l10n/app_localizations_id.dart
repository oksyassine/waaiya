// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Menghapus alat musik dari semua aplikasi dan mempertahankan suara bicara serta tilawah.';

  @override
  String get onboardTitle => 'Selamat datang';

  @override
  String get onboardBody =>
      'Waaiya menghapus alat musik dari suara semua aplikasi di ponsel ini. Suara bicara dan tilawah Al-Quran tetap terdengar. Untuk saat ini, suara nyanyian juga dihapus.';

  @override
  String get onboardQuestion => 'Saya';

  @override
  String get genderMan => 'Laki-laki';

  @override
  String get genderWoman => 'Perempuan';

  @override
  String get onboardWhy =>
      'Ini hanya menentukan setelan tambahan yang Anda lihat. Anda bisa mengubahnya nanti.';

  @override
  String get stateOnTitle => 'Filter aktif';

  @override
  String get stateOffTitle => 'Filter nonaktif';

  @override
  String get stateStarting => 'Memulai…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Alat musik dihapus dari semua aplikasi. Jeda sekitar $delayMs md.';
  }

  @override
  String get stateOffDetail => 'Ketuk tombol untuk memulai.';

  @override
  String get stateModelFailed =>
      'Model suara tidak bisa dimuat, jadi suara dibisukan demi keamanan.';

  @override
  String get stateCaptureDenied =>
      'Izin mikrofon diperlukan untuk menerima suara aplikasi lain.';

  @override
  String get stateStoppedBySystem =>
      'Android menghentikan filter. Ketuk tombol untuk memulai lagi.';

  @override
  String get stateSilencedTitle => 'Filter berhenti';

  @override
  String get stateSilenced =>
      'Filter berhenti: aplikasi lain dibisukan. Ketuk tombol untuk memulai lagi, atau Berhenti untuk mendengarnya tanpa filter.';

  @override
  String get releaseSilence => 'Berhenti: dengar aplikasi tanpa filter';

  @override
  String get powerStartCd => 'Mulai filter';

  @override
  String get powerStopCd => 'Hentikan filter';

  @override
  String get captureHint =>
      'Android akan meminta untuk membagikan layar Anda. Hanya suaranya yang dipakai: tidak ada yang direkam atau dikirim.';

  @override
  String get needRecordAudio =>
      'Waaiya memerlukan izin mikrofon untuk menerima suara aplikasi lain. Waaiya tidak pernah merekam Anda.';

  @override
  String get setupBannerTitle => 'Satu langkah lagi';

  @override
  String get setupBannerBody =>
      'Tanpa penyiapan satu kali di bawah, Anda akan mendengar musik dan suara yang difilter secara bersamaan.';

  @override
  String get step1Title => 'Instal Shizuku';

  @override
  String get step1Body => 'Aplikasi bantu gratis dari Play Store.';

  @override
  String get step1Action => 'Dapatkan Shizuku';

  @override
  String get step2Title => 'Jalankan Shizuku';

  @override
  String get step2Body =>
      'Shizuku berjalan lewat Wi-Fi dengan proses debug nirkabel Android. Ketuk tombol untuk melihat langkahnya, lalu kembali ke sini.';

  @override
  String get step2Action => 'Buka Shizuku';

  @override
  String get step2Update => 'Perbarui Shizuku';

  @override
  String get step2TooOld =>
      'Versi Shizuku Anda terlalu lama. Perbarui dari Play Store.';

  @override
  String get step2Denied =>
      'Shizuku diatur untuk selalu menolak Waaiya. Di Shizuku, izinkan Waaiya di daftar aplikasi.';

  @override
  String get step3Title => 'Beri izin';

  @override
  String get step3Body => 'Sekali ketuk, lalu pilih “Izinkan”.';

  @override
  String get step3Action => 'Beri izin';

  @override
  String get step3Busy => 'Menyiapkan…';

  @override
  String get setupDoneRestart =>
      'Selesai. Hentikan lalu mulai filter sekali untuk menerapkannya.';

  @override
  String setupFailed(String details) {
    return 'Penyiapan tidak selesai. Detail:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Izin Shizuku ditolak. Ketuk tombol untuk mencoba lagi.';

  @override
  String get setupSlow =>
      'Shizuku butuh waktu lebih lama dari biasanya. Tunggu saja: di beberapa ponsel, aplikasi bantunya butuh hingga satu menit untuk berjalan pertama kali.';

  @override
  String get setupTimeout =>
      'Shizuku tidak menjawab dalam 2 menit. Buka Shizuku, pastikan tertulis bahwa Shizuku sedang berjalan, lalu ketuk tombol lagi. Jika penyiapan selesai nanti, layar ini akan diperbarui sendiri.';

  @override
  String get setupRefusedXiaomi =>
      'Ponsel ini menolak izinnya. Di Xiaomi, Redmi, dan POCO, aktifkan “USB debugging (Security settings)” (Proses debug USB (Setelan keamanan)) di Opsi developer (Anda akan diminta masuk ke akun Xiaomi), lalu coba lagi.';

  @override
  String get setupRefusedColoros =>
      'Ponsel ini menolak izinnya. Di OPPO, OnePlus, dan realme, di Opsi developer, aktifkan “Disable permission monitoring” (Nonaktifkan pemantauan izin) (di versi terbaru namanya “Disable system optimization” (Nonaktifkan pengoptimalan sistem), dan mungkin hanya muncul jika bahasa ponsel diatur ke Inggris). Untuk menemukannya, telusuri “permission” di Setelan. Lalu coba lagi.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi, dan POCO: jika notifikasi tidak punya kolom untuk mengetik kode, ubah gaya notifikasi menjadi “Android” di setelan notifikasi, atau ketik kode di Waaiya dengan layar terpisah.';

  @override
  String get stepDoneCd => 'Selesai';

  @override
  String stepTodoCd(int step) {
    return 'Langkah $step';
  }

  @override
  String get computerToggle => 'Gunakan komputer saja';

  @override
  String get computerBody =>
      'Aktifkan Proses debug USB, sambungkan ponsel, lalu jalankan:';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Disalin';

  @override
  String get computerNote =>
      'Baris kedua opsional: baris ini menghilangkan pertanyaan berbagi layar di setiap awal.';

  @override
  String get settingsTitle => 'Setelan';

  @override
  String get settingSilenceTitle => 'Bisukan aplikasi yang menghalangi filter';

  @override
  String get settingSilenceBody =>
      'Disarankan. Beberapa aplikasi tidak mengizinkan suaranya difilter; ini membisukannya agar musik tidak lolos.';

  @override
  String get settingHoldSilenceTitle =>
      'Tetap bisukan aplikasi jika filter berhenti sendiri';

  @override
  String get settingHoldSilenceBody =>
      'Disarankan. Jika Android yang menghentikan filter (bukan Anda), aplikasi lain tetap bisu sampai Anda memulai lagi atau mengetuk Berhenti, bukannya memutar musik tanpa filter. Memerlukan penyiapan satu kali.';

  @override
  String get settingStereoTitle => 'Suara stereo';

  @override
  String get settingStereoBody =>
      'Nonaktif: mono, yang memakai sekitar separuh baterai dan lancar di lebih banyak ponsel. Aktif: memisahkan sisi kiri dan kanan. Jika ponsel terlalu lambat untuk stereo, otomatis beralih ke mono.';

  @override
  String get settingSingingTitle => 'Bisukan nyanyian perempuan';

  @override
  String get settingSingingBody => 'Suara bicara perempuan tetap terdengar.';

  @override
  String get settingSingingNoModel =>
      'Versi ini tidak punya pendeteksi nyanyian, jadi semua suara orang dibisukan selama opsi ini aktif.';

  @override
  String get settingRestart =>
      'Hentikan lalu mulai filter untuk menerapkan perubahan.';

  @override
  String get settingGenderTitle => 'Saya';

  @override
  String get change => 'Ubah';

  @override
  String get playerTitle => 'Video dengan sinkron sempurna';

  @override
  String get playerBody =>
      'Bagikan video ke Waaiya (atau gunakan “Buka dengan”) untuk menontonnya dengan filter tanpa jeda.';

  @override
  String get licences => 'Lisensi sumber terbuka';

  @override
  String get licencesIntro =>
      'Waaiya adalah perangkat lunak bebas dengan lisensi GNU Affero General Public License v3 atau yang lebih baru. Kode sumber: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (data pelatihan): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Teks lengkap';

  @override
  String get back => 'Kembali';

  @override
  String get linkEntryTitle => 'Buka tautan';

  @override
  String get linkEntryBody =>
      'Tempel tautan YouTube, TikTok, atau Instagram untuk menontonnya atau menyimpannya tanpa musik.';

  @override
  String get linkTitle => 'Buka tautan';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Tautan video atau audio';

  @override
  String get linkPaste => 'Tempel';

  @override
  String get linkOpen => 'Buka';

  @override
  String get linkResolving => 'Membuka tautan…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Tonton tanpa musik';

  @override
  String get linkSave => 'Simpan tanpa musik';

  @override
  String get linkListen => 'Dengarkan tanpa musik';

  @override
  String get linkAudioOnly =>
      'Video dari tautan ini belum bisa dibuka: hanya suaranya.';

  @override
  String get linkDownloading => 'Mendownload…';

  @override
  String get linkFiltering => 'Menghapus musik…';

  @override
  String get linkCancel => 'Batal';

  @override
  String get linkCancelled => 'Dibatalkan. Tidak ada yang disimpan.';

  @override
  String get linkTimedOut =>
      'Android menghentikan penyimpanan: Android hanya mengizinkan pekerjaan seperti ini beberapa jam sehari. Tidak ada yang disimpan; buka Waaiya dan coba lagi.';

  @override
  String get linkExportFailed =>
      'Tidak bisa menyimpan yang ini. Tidak ada yang disimpan.';

  @override
  String get linkSaved => 'Disimpan tanpa musik';

  @override
  String get linkSavedVideo => 'Di galeri Anda: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Di musik Anda: Music › Waaiya';

  @override
  String get linkPlay => 'Putar';

  @override
  String get linkShare => 'Bagikan';

  @override
  String get linkShareNote => 'Hanya bagikan video yang boleh Anda bagikan.';

  @override
  String get linkLive => 'Siaran langsung tidak bisa disimpan.';

  @override
  String get linkBusy =>
      'Video lain sedang disimpan. Harap tunggu sampai selesai.';

  @override
  String get linkInvalid => 'Tempel tautan web (yang diawali https://).';

  @override
  String get linkLogin =>
      'Situs tidak mau menampilkan video ini tanpa akun. Postingan publik biasanya bisa dibuka: coba lagi beberapa menit lagi. Postingan pribadi tidak bisa dibuka.';

  @override
  String get linkUnsupported => 'Situs ini tidak didukung.';

  @override
  String get linkPlaylist => 'Ini adalah playlist. Buka satu video saja.';

  @override
  String get linkNoFormat =>
      'Video ini belum dalam format yang bisa difilter Waaiya.';

  @override
  String get linkFailed =>
      'Tidak bisa membuka tautan ini. Periksa koneksi Anda dan coba lagi.';

  @override
  String get linkPlayFailed =>
      'Tidak bisa memutar ini. Tidak ada yang diputar tanpa filter.';

  @override
  String get linkLimited =>
      'Situs sedang membatasi permintaan. Coba lagi beberapa menit lagi.';

  @override
  String get blurTitle => 'Buram layar';

  @override
  String get blurBody =>
      'Menutupi orang dan gambar di layar, di semua aplikasi, selama filter aktif. Berjalan di ponsel; tidak ada yang dikirim ke mana pun.';

  @override
  String get blurWomenTitle => 'Buramkan perempuan';

  @override
  String get blurWomenBody =>
      'Seluruh tubuh. Orang yang tidak bisa dipastikan aplikasi sebagai laki-laki juga diburamkan.';

  @override
  String get blurNudityTitle => 'Buramkan gambar yang membuka aurat';

  @override
  String get blurNudityBody =>
      'Ketelanjangan dan pakaian terbuka, siapa pun orangnya: seluruh layar ditutup.';

  @override
  String get blurFailTitle => 'Tutup layar jika buram tidak sanggup mengikuti';

  @override
  String get blurFailBody =>
      'Aktif: seluruh layar ditutup saat ponsel terlalu lambat atau buram gagal. Nonaktif: layar tetap terlihat dengan peringatan.';

  @override
  String get blurSetupShizuku => 'Izinkan dengan Shizuku';

  @override
  String get blurSetupManual => 'Izinkan di setelan Android';

  @override
  String get blurStatusNeedsSetup =>
      'Buram perlu tampil di atas aplikasi lain. Terbaik: izinkan dengan Shizuku (mengaktifkan layanan aksesibilitas Waaiya Blur, sehingga sentuhan tetap sampai ke aplikasi di bawahnya). Atau izinkan “Tampilkan di atas aplikasi lain” di setelan Android (sentuhan pada area yang diburamkan lalu hilang).';

  @override
  String get blurStatusNeedsOverlay =>
      'Buram perlu tampil di atas aplikasi lain. Terbaik: jalankan Shizuku (dan izinkan Waaiya di dalamnya): buram lalu menggambar lapisannya sendiri, yang bisa ditembus ketukan. Jika tidak, izinkan “Tampilkan di atas aplikasi lain” di setelan Android; ketukan pada area yang diburamkan lalu tidak sampai ke aplikasi di bawahnya.';

  @override
  String get blurFailUnavailable =>
      'Tidak tersedia untuk sementara: penutup layar penuh akan menghalangi setiap ketukan dan Anda bisa terjebak. Jalankan asisten Waaiya atau Shizuku (Android 12 atau yang lebih baru) dan opsi ini aktif: penutup lalu digambar sehingga ketukan bisa menembusnya. Sampai saat itu, jika buram tidak sanggup mengikuti, layar tetap terlihat dengan peringatan.';

  @override
  String get blurFailNeedsA11y =>
      'Tidak tersedia untuk sementara: penutup layar penuh akan menghalangi setiap ketukan dan Anda bisa terjebak. Jalankan Shizuku (Android 12 atau yang lebih baru) atau aktifkan layanan aksesibilitas Waaiya Blur (Izinkan dengan Shizuku di atas) dan opsi ini aktif. Sampai saat itu, layar tetap terlihat dengan peringatan.';

  @override
  String get languageTitle => 'Bahasa';

  @override
  String settingLanguageTitle(String language) {
    return 'Bahasa: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Hentikan lalu mulai filter untuk menerapkan setelan buram.';

  @override
  String get blurStatusStarting => 'Buram dimulai…';

  @override
  String get blurStatusOn => 'Buram aktif.';

  @override
  String get blurStatusOnVisible =>
      'Buram aktif, dalam mode hati-hati: ponsel ini menampilkan buram di tangkapan layarnya sendiri, jadi area yang diburamkan tetap buram sampai adegannya berubah.';

  @override
  String get blurStatusModels =>
      'Versi ini tidak punya model buram untuk opsi yang dipilih.';

  @override
  String get blurStatusFailing => 'Buram tidak sanggup mengikuti saat ini.';

  @override
  String get blurStatusNoOverlay =>
      'Buram tidak bisa tampil di atas aplikasi lain: izinkan di atas.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Buram tidak bisa melihat layar. Detail:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku tidak bisa mengizinkannya:\n$details';
  }

  @override
  String get step2Guide => 'Cara menjalankan Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Tidak tersedia: di versi Android ini, penutup layar penuh akan menghalangi setiap ketukan dan Anda bisa terjebak (penutup Shizuku memerlukan Android 12 atau yang lebih baru). Jika buram tidak sanggup mengikuti, layar tetap terlihat dengan peringatan.';

  @override
  String get guideTitle => 'Jalankan Shizuku, langkah demi langkah';

  @override
  String get guideOpenDev => 'Opsi developer';

  @override
  String get guideOpenShizuku => 'Buka Shizuku';

  @override
  String get guideClose => 'Tutup';

  @override
  String get guideBody =>
      'Anda memerlukan Wi-Fi dan Android 11 atau yang lebih baru. Penyambungan hanya dilakukan sekali; setelah ponsel dimulai ulang, Anda cukup mengulangi langkah 7.\n\n1. Sambungkan ponsel ke Wi-Fi.\n\n2. Aktifkan Opsi developer: Setelan › Tentang ponsel › “Software information” (Informasi perangkat lunak) › ketuk “Nomor build” 7 kali. (Di ponsel lain: Setelan › Tentang ponsel › Nomor build.)\n\n3. Buka Shizuku. Jika diminta menampilkan notifikasi, izinkan: kode penyambungan diketik di notifikasi Shizuku.\n\n4. Di Shizuku, di bagian “Start via Wireless debugging” (Mulai melalui proses debug nirkabel), ketuk “Pairing” (Penyambungan). Di halaman yang terbuka, ketuk “Opsi developer”, aktifkan “Proses debug nirkabel” dan konfirmasi dengan “Izinkan”.\n\n5. Ketuk tulisan “Proses debug nirkabel” (bukan tombol aktif/nonaktifnya), lalu “Sambungkan perangkat dengan kode penyambungan”. Kode 6 digit akan muncul.\n\n6. Biarkan layar itu terbuka dan tarik turun notifikasi. Saat notifikasi Shizuku menampilkan “Pairing service found” (Layanan penyambungan ditemukan), ketuk “Enter pairing code” (Masukkan kode penyambungan) dan ketik kodenya. Shizuku akan menyatakan penyambungan berhasil.\n\n7. Kembali ke Shizuku dan ketuk “Start” (Mulai) di bawah “Start via Wireless debugging”. Tunggu sampai tertulis “Shizuku is running” (Shizuku sedang berjalan).\n\n8. Kembali ke Waaiya dan ketuk “Beri izin”, lalu “Izinkan”.\n\nSetelah ponsel dimulai ulang, Shizuku berhenti: sambungkan ke Wi-Fi, aktifkan lagi “Proses debug nirkabel” jika nonaktif, buka Shizuku, dan ketuk “Start”. Tidak perlu menyambungkan ulang.';

  @override
  String get wsetupRouteTitle => 'Siapkan di ponsel ini';

  @override
  String get wsetupRouteBody =>
      'Empat langkah singkat, sekali saja. Tanpa aplikasi tambahan dan tanpa komputer. Waaiya mencentang setiap langkah yang sudah selesai.';

  @override
  String get wizDevTitle => 'Aktifkan Opsi developer';

  @override
  String get wizDevBody =>
      'Di Tentang ponsel, ketuk “Nomor build” 7 kali, lalu kembali ke sini. Jika tidak menemukannya, telusuri “Nomor build” di Setelan.';

  @override
  String get wizDevBodySamsung =>
      'Di Tentang ponsel › “Software information” (Informasi perangkat lunak), ketuk “Nomor build” 7 kali, lalu kembali ke sini.';

  @override
  String get wizDevBodyXiaomi =>
      'Di Tentang ponsel, ketuk “OS version” (Versi OS) 7 kali (di ponsel lama “MIUI version” (Versi MIUI); di beberapa ponsel ada di bawah “Detailed info and specs” (Info dan spesifikasi detail)), lalu kembali ke sini.';

  @override
  String get wizDevBodyColoros =>
      'Di “About device” (Tentang perangkat) (atau Tentang ponsel) › “Version” (Versi), ketuk “Nomor build” 7 kali, lalu kembali ke sini.';

  @override
  String get wizDevBodyVivo =>
      'Di Tentang ponsel, ketuk “Software version” (Versi perangkat lunak) 7 kali (di beberapa ponsel: “Software information” (Informasi perangkat lunak) › “Nomor build”), lalu kembali ke sini.';

  @override
  String get wizDevBodyHuawei =>
      'Di Tentang ponsel, ketuk “Nomor build” 7 kali, lalu kembali ke sini.';

  @override
  String get wizDevBodyTranssion =>
      'Di “My phone” (Ponsel saya) (atau Tentang ponsel), ketuk “Nomor build” 7 kali, lalu kembali ke sini.';

  @override
  String get setupNoteHuawei =>
      'Huawei: banyak ponsel Huawei tidak punya “Proses debug nirkabel”. Jika Anda tidak menemukannya di Opsi developer, gunakan komputer (“Cara lain” di bawah).';

  @override
  String get wsetupFilterOn =>
      'Filter sedang aktif: di versi Android ini, kode tidak bisa diketik di notifikasi selama filter berjalan. Hentikan filter dulu, atau gunakan layar terpisah dan “Ketik kode di sini”.';

  @override
  String get wizDevSearch =>
      'Nama menu bisa berbeda tergantung bahasa ponsel: jika tidak menemukannya, gunakan kolom penelusuran di bagian atas Setelan.';

  @override
  String get wizDevAction => 'Buka Tentang ponsel';

  @override
  String get wizWifiTitle => 'Sambungkan ke Wi-Fi';

  @override
  String get wizWifiBody =>
      'Jaringan Wi-Fi apa pun bisa; internet tidak diperlukan.';

  @override
  String get wizWifiAction => 'Buka setelan Wi-Fi';

  @override
  String get wizWdTitle => 'Aktifkan Proses debug nirkabel';

  @override
  String get wizWdBody =>
      'Waaiya membuka Opsi developer di “Proses debug nirkabel”. Aktifkan lalu ketuk “Izinkan”.';

  @override
  String get wizWdAction => 'Buka Opsi developer';

  @override
  String get wizPairTitle => 'Ketik kode penyambungan';

  @override
  String get wizPairBody =>
      'Ketuk tulisan “Proses debug nirkabel”, lalu “Sambungkan perangkat dengan kode penyambungan”. Ketik 6 digitnya di notifikasi Waaiya. Waaiya mengerjakan sisanya.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya sudah tersambung dengan ponsel ini: tidak perlu kode. Ketuk tombol dan Waaiya akan menyelesaikannya sendiri.';

  @override
  String get wizPairAction => 'Lanjutkan';

  @override
  String get wizAgain => 'Jalankan penyiapan lagi';

  @override
  String get setupShizukuReadyTitle => 'Dengan Shizuku, yang sudah berjalan';

  @override
  String get setupOtherWaysPlain => 'Cara lain untuk penyiapan';

  @override
  String get wizSkip => 'Langsung ke Proses debug nirkabel';

  @override
  String get setupOtherWays => 'Cara lain: Shizuku atau komputer';

  @override
  String get wsetupEnterHere => 'Ketik kode di sini';

  @override
  String get wsetupCancel => 'Batal';

  @override
  String get wsetupAndroid10 =>
      'Android 10 tidak bisa melakukan penyiapan sendiri: perlu komputer, secara langsung (di bawah) atau untuk menjalankan Shizuku sekali.';

  @override
  String get wsetupShizukuHeading => 'Atau dengan aplikasi Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku juga membuat sentuhan bisa menembus penutup layar.';

  @override
  String get wsetupChannel => 'Penyiapan satu kali';

  @override
  String get wsetupNotifTitle => 'Penyiapan Waaiya: menunggu kode penyambungan';

  @override
  String get wsetupFoundTitle => 'Layar penyambungan ditemukan';

  @override
  String get wsetupBusyTitle => 'Penyiapan Waaiya';

  @override
  String get wsetupDoneTitle => 'Penyiapan selesai';

  @override
  String get wsetupDoneBody =>
      'Waaiya kini bisa membisukan suara aslinya. Anda boleh menonaktifkan Proses debug nirkabel.';

  @override
  String get wsetupDoneHelperBody =>
      'Selesai. Ponsel ini tidak membiarkan aplikasi menyimpan izin ini, jadi asisten Waaiya yang membisukan suara aslinya. Asisten berhenti saat ponsel dimulai ulang dan saat Waaiya diperbarui. Saat Anda membuka Waaiya setelah itu, Waaiya menjalankan asisten lagi secara otomatis jika Proses debug nirkabel aktif; jika tidak, Waaiya menampilkan tombol untuk itu.';

  @override
  String get helperMissingTitle => 'Asisten Waaiya berhenti';

  @override
  String get helperMissingBody =>
      'Ponsel ini tidak menyimpan izin Waaiya, jadi Waaiya memakai asistennya. Asisten berhenti saat ponsel dimulai ulang dan saat Waaiya diperbarui. Sambungkan ke Wi-Fi, aktifkan “Proses debug nirkabel” di Opsi developer, lalu ketuk “Jalankan asisten Waaiya”.';

  @override
  String get helperChannel => 'Asisten Waaiya';

  @override
  String get helperStarting => 'Menjalankan asisten…';

  @override
  String get helperModeNote =>
      'Ponsel ini tidak membiarkan aplikasi menyimpan izin ini: asisten Waaiya yang mengerjakannya. Asisten berhenti saat ponsel dimulai ulang dan saat Waaiya diperbarui. Saat Anda membuka Waaiya setelah itu, Waaiya menjalankan asisten lagi secara otomatis jika Proses debug nirkabel aktif; jika tidak, Waaiya menampilkan tombol untuk itu.';

  @override
  String get helperTipXiaomi =>
      'Opsional, agar izin tersimpan permanen (tanpa asisten setelah dimulai ulang): di Opsi developer, aktifkan “USB debugging (Security settings)” (Proses debug USB (Setelan keamanan)) (Anda akan diminta masuk ke akun Xiaomi), lalu lakukan penyiapan lagi.';

  @override
  String get helperTipColoros =>
      'Opsional, agar izin tersimpan permanen (tanpa asisten setelah dimulai ulang): di Opsi developer, aktifkan “Disable permission monitoring” (Nonaktifkan pemantauan izin) (di versi terbaru “Disable system optimization” (Nonaktifkan pengoptimalan sistem); mungkin hanya muncul jika bahasa ponsel diatur ke Inggris), lalu lakukan penyiapan lagi.';

  @override
  String get stateOnHelperMissing =>
      'Suara aslinya belum dibisukan, jadi Anda mendengar musik bersama suara yang difilter: asisten Waaiya berhenti. Sambungkan ke Wi-Fi, aktifkan Proses debug nirkabel, lalu ketuk “Jalankan asisten Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Atau gunakan “Siapkan di ponsel ini” di halaman ini: asisten Waaiya lalu bekerja tanpa tombol tersebut.';

  @override
  String get helperStartAnywayTitle => 'Asisten Waaiya berhenti';

  @override
  String get helperStartAnywayBody =>
      'Tanpa asisten, Anda akan mendengar musik bersama suara yang difilter. Jalankan asisten dulu (Proses debug nirkabel harus aktif), atau tetap mulai filter.';

  @override
  String get wsetupFailedTitle => 'Penyiapan tidak selesai';

  @override
  String get wsetupPairing => 'Menyambungkan…';

  @override
  String get wsetupConnecting => 'Menghubungkan dan memberi izin…';

  @override
  String get wsetupNeedWifi =>
      'Sambungkan ke jaringan Wi-Fi dulu (internet tidak diperlukan): Proses debug nirkabel hanya bekerja lewat Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Di Opsi developer, aktifkan “Proses debug nirkabel”, lalu ketuk namanya dan “Sambungkan perangkat dengan kode penyambungan”.';

  @override
  String get wsetupOpenDialog =>
      'Di Proses debug nirkabel, ketuk “Sambungkan perangkat dengan kode penyambungan”. Biarkan kode tetap di layar dan ketuk “Masukkan kode” di sini.';

  @override
  String get wsetupEnterCodeBody =>
      'Ketuk “Masukkan kode” dan ketik kode 6 digit yang ditampilkan di Setelan.';

  @override
  String get wsetupCodeWaiting =>
      'Kode diterima. Menunggu layar “Sambungkan perangkat dengan kode penyambungan”: biarkan tetap terbuka.';

  @override
  String get wsetupWrongCode =>
      'Kode itu tidak diterima. Periksa 6 digit di layar dan masukkan lagi. Jika layar penyambungan tertutup, buka lagi: kodenya berubah.';

  @override
  String get wsetupPairingFailed =>
      'Penyambungan gagal. Tutup layar penyambungan, buka lagi “Sambungkan perangkat dengan kode penyambungan”, dan masukkan kode yang baru.';

  @override
  String get wsetupWaitingConnect =>
      'Tersambung. Biarkan “Proses debug nirkabel” tetap aktif: Waaiya sedang menghubungkan.';

  @override
  String get wsetupNotPaired =>
      'Ponsel ini tidak lagi mengenali Waaiya (penyambungan dihapus atau kedaluwarsa). Buka “Sambungkan perangkat dengan kode penyambungan” dan masukkan kodenya.';

  @override
  String get wsetupConnectFailed =>
      'Tidak bisa terhubung ke Proses debug nirkabel. Nonaktifkan lalu aktifkan lagi: Waaiya akan mencoba lagi secara otomatis.';

  @override
  String get wsetupGrantFailed =>
      'Terhubung, tetapi izinnya masih belum ada. Gunakan Shizuku atau komputer di bawah.';

  @override
  String get wsetupTimeout =>
      'Dihentikan setelah 10 menit tanpa selesai. Anda bisa mencoba lagi.';

  @override
  String get wsetupCodeUnreadable => 'Ketik 6 digit kode penyambungan.';

  @override
  String get wsetupCodeHint => 'Kode 6 digit';

  @override
  String get wsetupEnterCode => 'Masukkan kode';

  @override
  String wsetupDetail(String details) {
    return 'Detail: $details';
  }

  @override
  String get wsetupErrTimeout => 'tidak ada jawaban tepat waktu';

  @override
  String get wsetupErrRefused => 'koneksi ditolak';

  @override
  String get wsetupDevOff =>
      'Opsi developer nonaktif. Di Tentang ponsel, ketuk “Nomor build” 7 kali, lalu kembali.';

  @override
  String get wsetupOpenAbout => 'Tentang ponsel';

  @override
  String get wsetupNotifOff =>
      'Notifikasi nonaktif untuk Waaiya, jadi kode tidak bisa diketik di notifikasi. Gunakan layar terpisah (Setelan di satu sisi, Waaiya di sisi lain) dan ketuk “Ketik kode di sini”.';

  @override
  String get wsetupCodeDialogTitle => 'Kode penyambungan';

  @override
  String get wsetupCodeDialogBody =>
      'Hanya dengan layar terpisah (Setelan di satu sisi, Waaiya di sisi lain): keluar dari Setelan akan menutup layar penyambungan dan kodenya tidak berlaku lagi. Ketik kode 6 digit yang ditampilkan di bawah “Sambungkan perangkat dengan kode penyambungan”.';

  @override
  String get wsetupCodeOk => 'Sambungkan';

  @override
  String get blurStrictTitle => 'Siapa yang dibiarkan tidak ditutup';

  @override
  String blurStrictValue(String level) {
    return 'Siapa yang dibiarkan tidak ditutup: $level';
  }

  @override
  String get blurStrict0 =>
      'Ketat: hanya orang yang hampir pasti laki-laki menurut aplikasi';

  @override
  String get blurStrict1 =>
      'Seimbang: sekitar dua kali lebih banyak laki-laki tidak ditutup';

  @override
  String get blurStrict2 =>
      'Longgar: sedikit lebih banyak laki-laki daripada seimbang';

  @override
  String get blurStrict0Short => 'ketat';

  @override
  String get blurStrict1Short => 'seimbang';

  @override
  String get blurStrict2Short => 'longgar';

  @override
  String get blurStrictHelp =>
      'Siapa pun yang tidak dipastikan aplikasi sebagai laki-laki akan ditutup. Ketat membiarkan sekitar 7 dari 100 laki-laki tidak ditutup; seimbang sekitar 14, longgar sekitar 16. Setiap tingkat yang kurang ketat juga membiarkan sekitar 1 perempuan lagi dari 100 tidak ditutup.';

  @override
  String get stateOnNotMuted =>
      'Suara aslinya belum dibisukan, jadi Anda mendengar musik bersama suara yang difilter. Selesaikan penyiapan satu kali di bawah.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya tidak bisa membisukan suara asli dari aplikasi yang sedang diputar, jadi musik mungkin masih terdengar. Hentikan lalu mulai filter. Jika tetap terjadi, kirim laporan diagnostik (di bagian bawah layar ini).';

  @override
  String get stateTooSlow =>
      'Ponsel ini terlalu lambat untuk memfilter suara secara langsung, jadi suaranya terputus-putus. “Buka tautan” di bawah tetap berfungsi: video difilter dulu sebelum diputar.';

  @override
  String get stateMonoNote =>
      'Suara dalam mode mono agar ponsel ini sanggup mengikuti.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Dibisukan, karena tidak mengizinkan filter: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Diputar tanpa filter, karena tidak mengizinkan filter: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android tidak memberikan suara aplikasi lain ke Waaiya. Ketuk tombol untuk memulai lagi.';

  @override
  String get stateCaptureCancelled =>
      'Proses mulai dibatalkan di pertanyaan berbagi layar Android. Waaiya memerlukan “Mulai” di sana untuk menerima suaranya. Tidak ada yang direkam atau dikirim.';

  @override
  String get startNoSetupTitle => 'Musik masih akan terdengar';

  @override
  String get startNoSetupBody =>
      'Penyiapan satu kali belum dilakukan. Tanpanya Waaiya tidak bisa membisukan suara aslinya: Anda akan mendengar musik dan suara yang difilter secara bersamaan.\n\n“Buka tautan” berfungsi tanpa penyiapan apa pun.';

  @override
  String get startNoSetupSetup => 'Lakukan penyiapan';

  @override
  String get startNoSetupAnyway => 'Tetap mulai';

  @override
  String get diagButton => 'Ada masalah? Laporan diagnostik';

  @override
  String get diagTitle => 'Laporan diagnostik';

  @override
  String get diagNote =>
      'Apa yang dilihat Waaiya di ponsel ini. Salin atau bagikan kepada orang yang membantu Anda. Aplikasinya sendiri tidak mengirim apa pun.';

  @override
  String get notifStoppedTitle => 'Waaiya berhenti';

  @override
  String get notifStoppedText =>
      'Suara tidak lagi difilter. Ketuk untuk memulai lagi.';

  @override
  String get wsetupGuide => 'Langkah bergambar';

  @override
  String get navFilter => 'Filter';

  @override
  String get navScreen => 'Layar';

  @override
  String get navLinks => 'Tautan';

  @override
  String get navSetup => 'Penyiapan';

  @override
  String get navSettings => 'Setelan';

  @override
  String get setupDoneTitle => 'Penyiapan selesai';

  @override
  String get setupDoneBody =>
      'Waaiya bisa membisukan suara asli aplikasi lain. Ulangi hanya jika ada yang berubah (penyiapan dibatalkan, atau Waaiya menyatakan penyiapan belum ada).';

  @override
  String get setupRedo => 'Tampilkan penyiapan lagi';

  @override
  String get setupGo => 'Ke penyiapan';

  @override
  String get helperTitle => 'Sentuhan menembus penutup';

  @override
  String get helperBodyOff =>
      'Tanpa bantuan, penutup menghalangi sentuhan di bawahnya. Asisten Waaiya menggambar penutup agar sentuhan bisa menembusnya. Aktifkan Proses debug nirkabel (Wi-Fi diperlukan) dan ketuk tombolnya; pertama kali, sambungkan sekali seperti saat penyiapan. Setelah ponsel dimulai ulang, ketuk lagi.';

  @override
  String get helperStart => 'Jalankan asisten Waaiya';

  @override
  String get helperOn =>
      'Asisten Waaiya menggambar penutup: sentuhan bisa menembusnya. Asisten berhenti saat ponsel dimulai ulang atau saat Proses debug USB dinonaktifkan; ketuk tombolnya lagi saat itu.';

  @override
  String get helperShizukuOn =>
      'Shizuku menggambar penutup: sentuhan bisa menembusnya.';

  @override
  String get helperOrShizuku => 'Atau dengan Shizuku:';

  @override
  String get filterOptionsTitle => 'Opsi filter';

  @override
  String get settingsGeneralTitle => 'Umum';

  @override
  String get desktopPreview =>
      'Pratinjau: mesin filter belum terhubung di komputer ini. Tombol hanya menunjukkan cara kerja aplikasi.';

  @override
  String actionFailed(String details) {
    return 'Itu tidak berhasil: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Alat musik dihapus dari semua aplikasi.';

  @override
  String get engineErrorNoPactl =>
      'Alat suara tidak ditemukan (pactl). Waaiya memerlukan PulseAudio, atau PipeWire dengan pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Server suara tidak berjalan (PulseAudio atau PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Sistem ini tidak punya sesi pengguna systemd, yang menjalankan filter di latar belakang.';

  @override
  String get engineErrorNoOutput => 'Speaker atau headphone tidak ditemukan.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Tidak bisa menginstal filter. Detail:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Filter tidak berjalan. Detail:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Filter berhenti karena error. Detail:\n$details';
  }

  @override
  String get autostartTitle => 'Mulai saat login';

  @override
  String get autostartBody => 'Filter suara begitu Anda login.';

  @override
  String get blurBodyDesktop =>
      'Menutupi orang dan gambar di layar, di atas semua jendela, selama Waaiya terbuka (berfungsi baik filter suara aktif maupun nonaktif). Berjalan di komputer ini; tidak ada yang dikirim ke mana pun. Menutup jendela Waaiya akan menghentikan buram.';

  @override
  String get blurFailBodyDesktop =>
      'Aktif: seluruh layar ditutup saat komputer terlalu lambat atau buram gagal; klik tetap sampai ke jendela di bawahnya. Nonaktif: layar tetap terlihat dengan bilah merah di bagian atas.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Buram aktif. Desktop ini menampilkan buram di tangkapan layarnya sendiri, jadi area yang diburamkan tetap buram sampai adegannya berubah.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Buram tidak bisa tampil di atas jendela lain di desktop ini. Detail:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Pilih layar Anda di jendela berbagi layar dan izinkan. Waaiya hanya meminta sekali; gambarnya tetap di komputer ini.';

  @override
  String blurStatusExited(String details) {
    return 'Buram berhenti secara tak terduga. Nonaktifkan lalu aktifkan lagi salah satu opsi buram untuk mencoba lagi. Detail:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Pendeteksi nyanyian perempuan tidak termuat, jadi suara orang dibisukan selama opsi itu aktif.';

  @override
  String get blurStatusUncovered =>
      'Ada monitor yang tidak ditutupi buram: monitor itu tidak dibagikan, atau baru dicolokkan kemudian. Nonaktifkan lalu aktifkan lagi salah satu opsi buram, dan pilih semua layar di jendela berbagi layar.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Model buram tidak ada di instalasi ini, jadi buram tidak bisa menutupi apa pun; bilah merah tetap di bagian atas layar. Instal ulang Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Apa yang dilihat Waaiya di komputer ini. Salin dan berikan kepada orang yang membantu Anda. Aplikasinya sendiri tidak mengirim apa pun.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Disarankan. Jika pemfilteran berhenti sendiri (karena galat, bukan oleh Anda), aplikasi lain tetap senyap sampai Anda memulai lagi atau menekan Berhenti, alih-alih memutar musik tanpa filter.';

  @override
  String get settingStereoBodyDesktop =>
      'Nonaktif: mono, yang lebih ringan bagi komputer. Aktif: memisahkan sisi kiri dan kanan. Jika komputer terlalu lambat untuk stereo, otomatis beralih ke mono.';

  @override
  String get linkEntryBodyDesktop =>
      'Tempel tautan YouTube, TikTok, atau Instagram untuk menontonnya dengan filter aktif, atau untuk menyimpannya tanpa musik.';

  @override
  String get linkEntryBodyWatch =>
      'Tempel tautan YouTube, TikTok, atau Instagram untuk menontonnya di browser Anda dengan filter aktif.';

  @override
  String get linkWatchNoteDesktop =>
      'Terbuka di browser Anda. Waaiya menyalakan filter lebih dulu, jadi musiknya juga dihapus di sana.';

  @override
  String get linkFilterFailed =>
      'Filter tidak berjalan, jadi tautan tidak dibuka. Nyalakan di halaman Filter lalu coba lagi.';

  @override
  String get linkSavedVideoDesktop => 'Di folder Video Anda: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Di folder Musik Anda: Waaiya';

  @override
  String get linkShowInFolder => 'Tampilkan di folder';

  @override
  String get linkSingingNote =>
      'Nyanyian perempuan juga dibisukan, sesuai pengaturan Anda.';
}
