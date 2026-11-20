// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Membuang alat muzik daripada setiap apl dan mengekalkan percakapan serta bacaan.';

  @override
  String get onboardTitle => 'Selamat datang';

  @override
  String get onboardBody =>
      'Waaiya membuang alat muzik daripada bunyi setiap apl pada telefon ini. Percakapan dan bacaan al-Quran dikekalkan. Buat masa ini, suara nyanyian turut dibuang.';

  @override
  String get onboardQuestion => 'Saya seorang';

  @override
  String get genderMan => 'Lelaki';

  @override
  String get genderWoman => 'Wanita';

  @override
  String get onboardWhy =>
      'Ini hanya menentukan tetapan pilihan yang anda lihat. Anda boleh mengubahnya kemudian.';

  @override
  String get stateOnTitle => 'Penapisan dihidupkan';

  @override
  String get stateOffTitle => 'Penapisan dimatikan';

  @override
  String get stateStarting => 'Memulakan…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Alat muzik dibuang daripada semua apl. Kelewatan kira-kira $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Ketik butang untuk bermula.';

  @override
  String get stateModelFailed =>
      'Model bunyi tidak dapat dimuatkan, jadi bunyi disenyapkan demi keselamatan.';

  @override
  String get stateCaptureDenied =>
      'Kebenaran mikrofon diperlukan untuk menerima bunyi apl lain.';

  @override
  String get stateStoppedBySystem =>
      'Android menghentikan penapisan. Ketik butang untuk bermula semula.';

  @override
  String get stateSilencedTitle => 'Penapisan berhenti';

  @override
  String get stateSilenced =>
      'Penapisan berhenti: apl lain disenyapkan. Ketik butang untuk bermula semula, atau Henti untuk mendengarnya tanpa penapisan.';

  @override
  String get releaseSilence => 'Henti: dengar apl tanpa penapisan';

  @override
  String get powerStartCd => 'Mulakan penapisan';

  @override
  String get powerStopCd => 'Hentikan penapisan';

  @override
  String get captureHint =>
      'Android akan meminta untuk berkongsi skrin anda. Hanya bunyi yang digunakan: tiada apa-apa dirakam atau dihantar.';

  @override
  String get needRecordAudio =>
      'Waaiya memerlukan kebenaran mikrofon untuk menerima bunyi apl lain. Ia tidak sekali-kali merakam anda.';

  @override
  String get setupBannerTitle => 'Satu langkah lagi';

  @override
  String get setupBannerBody =>
      'Tanpa persediaan sekali sahaja di bawah, anda akan mendengar muzik dan bunyi yang ditapis serentak.';

  @override
  String get step1Title => 'Pasang Shizuku';

  @override
  String get step1Body => 'Apl pembantu percuma daripada Play Store.';

  @override
  String get step1Action => 'Dapatkan Shizuku';

  @override
  String get step2Title => 'Mulakan Shizuku';

  @override
  String get step2Body =>
      'Shizuku dimulakan melalui Wi-Fi dengan penyahpepijatan wayarles Android. Ketik butang untuk melihat langkah-langkahnya, kemudian kembali ke sini.';

  @override
  String get step2Action => 'Buka Shizuku';

  @override
  String get step2Update => 'Kemas kini Shizuku';

  @override
  String get step2TooOld =>
      'Versi Shizuku anda terlalu lama. Kemas kininya daripada Play Store.';

  @override
  String get step2Denied =>
      'Shizuku ditetapkan untuk sentiasa menolak Waaiya. Dalam Shizuku, benarkannya dalam senarai apl.';

  @override
  String get step3Title => 'Beri kebenaran';

  @override
  String get step3Body => 'Satu ketikan, kemudian pilih “Benarkan”.';

  @override
  String get step3Action => 'Beri kebenaran';

  @override
  String get step3Busy => 'Menyediakan…';

  @override
  String get setupDoneRestart =>
      'Selesai. Hentikan dan mulakan penapisan sekali untuk menggunakannya.';

  @override
  String setupFailed(String details) {
    return 'Persediaan tidak selesai. Butiran:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Kebenaran Shizuku ditolak. Ketik butang untuk mencuba lagi.';

  @override
  String get setupSlow =>
      'Shizuku mengambil masa lebih lama daripada biasa. Teruskan menunggu: pada sesetengah telefon, pembantunya mengambil masa sehingga seminit untuk bermula kali pertama.';

  @override
  String get setupTimeout =>
      'Shizuku tidak menjawab dalam masa 2 minit. Buka Shizuku, pastikan ia menyatakan bahawa ia sedang berjalan, kemudian ketik butang sekali lagi. Jika persediaan selesai kemudian, skrin ini dikemas kini dengan sendirinya.';

  @override
  String get setupRefusedXiaomi =>
      'Telefon ini menolak kebenaran. Pada Xiaomi, Redmi dan POCO, hidupkan “USB debugging (Security settings)” (Penyahpepijatan USB (Tetapan keselamatan)) dalam Pilihan pembangun (ia meminta anda log masuk ke akaun Xiaomi), kemudian cuba lagi.';

  @override
  String get setupRefusedColoros =>
      'Telefon ini menolak kebenaran. Pada OPPO, OnePlus dan realme, dalam Pilihan pembangun, hidupkan “Disable permission monitoring” (Lumpuhkan pemantauan kebenaran) (pada versi terbaharu ia dipanggil “Disable system optimization” (Lumpuhkan pengoptimuman sistem), dan mungkin hanya muncul apabila bahasa telefon ditetapkan kepada Bahasa Inggeris). Untuk mencarinya, cari “permission” (atau “kebenaran”) dalam Tetapan. Kemudian cuba lagi.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi dan POCO: jika pemberitahuan tiada ruang untuk menaip kod, tetapkan gaya pemberitahuan kepada “Android” dalam tetapan pemberitahuan, atau taip kod dalam Waaiya menggunakan skrin pisah.';

  @override
  String get stepDoneCd => 'Selesai';

  @override
  String stepTodoCd(int step) {
    return 'Langkah $step';
  }

  @override
  String get computerToggle => 'Gunakan komputer sebaliknya';

  @override
  String get computerBody =>
      'Hidupkan Penyahpepijatan USB, sambungkan telefon dan jalankan:';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Disalin';

  @override
  String get computerNote =>
      'Baris kedua adalah pilihan: ia menghentikan soalan perkongsian skrin pada setiap kali bermula.';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingSilenceTitle => 'Senyapkan apl yang menyekat penapisan';

  @override
  String get settingSilenceBody =>
      'Disyorkan. Sesetengah apl tidak membenarkan bunyinya ditapis; ini menyenyapkannya dan bukannya membiarkan muzik kedengaran.';

  @override
  String get settingHoldSilenceTitle =>
      'Kekalkan apl senyap jika penapisan berhenti sendiri';

  @override
  String get settingHoldSilenceBody =>
      'Disyorkan. Jika Android menamatkan penapisan (bukan anda), apl lain kekal senyap sehingga anda bermula semula atau ketik Henti, dan bukannya memainkan muzik tanpa penapisan. Memerlukan persediaan sekali sahaja.';

  @override
  String get settingStereoTitle => 'Bunyi stereo';

  @override
  String get settingStereoBody =>
      'Mati: mono, yang menggunakan kira-kira separuh bateri dan lancar pada lebih banyak telefon. Hidup: mengekalkan sisi kiri dan kanan berasingan. Jika telefon terlalu perlahan untuk stereo, ia tetap beralih kepada mono dengan sendirinya.';

  @override
  String get settingSingingTitle => 'Senyapkan nyanyian wanita';

  @override
  String get settingSingingBody => 'Percakapan dan bacaan wanita dikekalkan.';

  @override
  String get settingSingingNoModel =>
      'Versi ini tiada pengesan nyanyian, jadi semua suara disenyapkan selagi ini dihidupkan.';

  @override
  String get settingRestart =>
      'Hentikan dan mulakan penapisan untuk menggunakan perubahan.';

  @override
  String get settingGenderTitle => 'Saya seorang';

  @override
  String get change => 'Tukar';

  @override
  String get playerTitle => 'Video dalam penyegerakan sempurna';

  @override
  String get playerBody =>
      'Kongsi video kepada Waaiya (atau gunakan “Buka dengan”) untuk menontonnya dengan penapisan tanpa kelewatan.';

  @override
  String get licences => 'Lesen sumber terbuka';

  @override
  String get licencesIntro =>
      'Waaiya ialah perisian bebas di bawah GNU Affero General Public License v3 atau lebih baharu. Kod sumber: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (data latihan): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Teks penuh';

  @override
  String get back => 'Kembali';

  @override
  String get linkEntryTitle => 'Buka pautan';

  @override
  String get linkEntryBody =>
      'Tampal pautan YouTube, TikTok atau Instagram untuk menontonnya atau menyimpannya tanpa muzik.';

  @override
  String get linkTitle => 'Buka pautan';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Pautan video atau audio';

  @override
  String get linkPaste => 'Tampal';

  @override
  String get linkOpen => 'Buka';

  @override
  String get linkResolving => 'Membuka pautan…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Tonton tanpa muzik';

  @override
  String get linkSave => 'Simpan tanpa muzik';

  @override
  String get linkListen => 'Dengar tanpa muzik';

  @override
  String get linkAudioOnly =>
      'Video pautan ini belum boleh dibuka: hanya bunyinya.';

  @override
  String get linkDownloading => 'Memuat turun…';

  @override
  String get linkFiltering => 'Membuang muzik…';

  @override
  String get linkCancel => 'Batal';

  @override
  String get linkCancelled => 'Dibatalkan. Tiada apa-apa disimpan.';

  @override
  String get linkTimedOut =>
      'Android menghentikan penyimpanan: ia hanya membenarkan kerja jenis ini beberapa jam sehari. Tiada apa-apa disimpan; buka Waaiya dan cuba lagi.';

  @override
  String get linkExportFailed =>
      'Tidak dapat menyimpan yang ini. Tiada apa-apa disimpan.';

  @override
  String get linkSaved => 'Disimpan tanpa muzik';

  @override
  String get linkSavedVideo => 'Dalam galeri anda: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Dalam muzik anda: Music › Waaiya';

  @override
  String get linkPlay => 'Main';

  @override
  String get linkShare => 'Kongsi';

  @override
  String get linkShareNote =>
      'Kongsi hanya video yang anda dibenarkan untuk dikongsi.';

  @override
  String get linkLive => 'Strim langsung tidak boleh disimpan.';

  @override
  String get linkBusy =>
      'Video lain sedang disimpan. Sila tunggu sehingga ia selesai.';

  @override
  String get linkInvalid => 'Sila tampal pautan web (bermula dengan https://).';

  @override
  String get linkLogin =>
      'Laman ini tidak akan menunjukkan video ini tanpa akaun. Siaran awam biasanya boleh dibuka: cuba lagi dalam beberapa minit. Siaran peribadi tidak boleh dibuka.';

  @override
  String get linkUnsupported => 'Laman ini tidak disokong.';

  @override
  String get linkPlaylist => 'Ini ialah senarai main. Sila buka satu video.';

  @override
  String get linkNoFormat =>
      'Video ini belum dalam format yang boleh ditapis oleh Waaiya.';

  @override
  String get linkFailed =>
      'Tidak dapat membuka pautan ini. Semak sambungan anda dan cuba lagi.';

  @override
  String get linkPlayFailed =>
      'Tidak dapat memainkan ini. Tiada apa-apa yang tidak ditapis dimainkan.';

  @override
  String get linkLimited =>
      'Laman ini sedang mengehadkan permintaan. Cuba lagi dalam beberapa minit.';

  @override
  String get blurTitle => 'Pengaburan skrin';

  @override
  String get blurBody =>
      'Menutup orang dan imej pada skrin, dalam setiap apl, semasa penapisan dihidupkan. Ia berjalan pada telefon; tiada apa-apa dihantar ke mana-mana.';

  @override
  String get blurWomenTitle => 'Kaburkan wanita';

  @override
  String get blurWomenBody =>
      'Seluruh badan. Orang yang tidak dapat dipastikan dengan jelas oleh apl sebagai lelaki juga dikaburkan.';

  @override
  String get blurNudityTitle => 'Kaburkan imej tidak sopan';

  @override
  String get blurNudityBody =>
      'Kebogelan dan pakaian yang mendedahkan aurat, sesiapa pun: seluruh skrin ditutup.';

  @override
  String get blurFailTitle => 'Tutup skrin jika pengaburan tidak sempat';

  @override
  String get blurFailBody =>
      'Hidup: seluruh skrin ditutup apabila telefon terlalu perlahan atau pengaburan gagal. Mati: skrin kekal kelihatan dengan amaran.';

  @override
  String get blurSetupShizuku => 'Benarkan dengan Shizuku';

  @override
  String get blurSetupManual => 'Benarkan dalam tetapan Android';

  @override
  String get blurStatusNeedsSetup =>
      'Pengaburan perlu dipaparkan di atas apl lain. Terbaik: benarkannya dengan Shizuku (menghidupkan perkhidmatan kebolehaksesan Pengaburan Waaiya, supaya sentuhan masih sampai ke apl di bawahnya). Atau benarkan “Paparkan di atas apl lain” dalam tetapan Android (sentuhan pada kawasan yang dikaburkan kemudiannya hilang).';

  @override
  String get blurStatusNeedsOverlay =>
      'Pengaburan perlu dipaparkan di atas apl lain. Terbaik: mulakan Shizuku (dan benarkan Waaiya di dalamnya): pengaburan kemudian melukis lapisannya sendiri, yang dapat dilalui oleh ketikan. Jika tidak, benarkan “Paparkan di atas apl lain” dalam tetapan Android; ketikan pada kawasan yang dikaburkan kemudiannya tidak sampai ke apl di bawahnya.';

  @override
  String get blurFailUnavailable =>
      'Dikelabukan buat masa ini: penutup skrin penuh akan menyekat setiap ketikan dan anda mungkin tersekat. Mulakan pembantu Waaiya atau Shizuku (Android 12 atau lebih baharu) dan ia akan dihidupkan: penutup kemudian dilukis supaya ketikan dapat melaluinya. Sehingga itu, apabila pengaburan tidak sempat, skrin kekal kelihatan dengan amaran.';

  @override
  String get blurFailNeedsA11y =>
      'Dikelabukan buat masa ini: penutup skrin penuh akan menyekat setiap ketikan dan anda mungkin tersekat. Mulakan Shizuku (Android 12 atau lebih baharu) atau hidupkan perkhidmatan kebolehaksesan Pengaburan Waaiya (Benarkan dengan Shizuku di atas) dan ia akan dihidupkan. Sehingga itu, skrin kekal kelihatan dengan amaran.';

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
      'Hentikan dan mulakan penapisan untuk menggunakan tetapan pengaburan.';

  @override
  String get blurStatusStarting => 'Pengaburan bermula…';

  @override
  String get blurStatusOn => 'Pengaburan dihidupkan.';

  @override
  String get blurStatusOnVisible =>
      'Pengaburan dihidupkan, dalam mod berhati-hati: telefon ini menunjukkan pengaburan dalam tangkapan skrinnya sendiri, jadi kawasan yang dikaburkan kekal kabur sehingga adegan berubah.';

  @override
  String get blurStatusModels =>
      'Versi ini tiada model pengaburan untuk pilihan yang dipilih.';

  @override
  String get blurStatusFailing => 'Pengaburan tidak sempat buat masa ini.';

  @override
  String get blurStatusNoOverlay =>
      'Pengaburan tidak dapat dipaparkan di atas apl lain: benarkannya di atas.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Pengaburan tidak dapat melihat skrin. Butiran:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku tidak dapat membenarkannya:\n$details';
  }

  @override
  String get step2Guide => 'Cara memulakan Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Dikelabukan: pada versi Android ini, penutup skrin penuh akan menyekat setiap ketikan dan anda mungkin tersekat (penutup Shizuku memerlukan Android 12 atau lebih baharu). Apabila pengaburan tidak sempat, skrin kekal kelihatan dengan amaran.';

  @override
  String get guideTitle => 'Mulakan Shizuku, langkah demi langkah';

  @override
  String get guideOpenDev => 'Pilihan pembangun';

  @override
  String get guideOpenShizuku => 'Buka Shizuku';

  @override
  String get guideClose => 'Tutup';

  @override
  String get guideBody =>
      'Anda memerlukan Wi-Fi dan Android 11 atau lebih baharu. Gandingan dibuat sekali sahaja; selepas telefon dimulakan semula, anda hanya mengulangi langkah 7.\n\n1. Sambungkan telefon ke Wi-Fi.\n\n2. Hidupkan Pilihan pembangun: Tetapan › Perihal telefon › “Software information” (Maklumat perisian) › ketik “Nombor binaan” 7 kali. (Pada telefon lain: Tetapan › Perihal telefon › Nombor binaan.)\n\n3. Buka Shizuku. Jika ia meminta untuk menunjukkan pemberitahuan, benarkannya: kod gandingan ditaip dalam pemberitahuan Shizuku.\n\n4. Dalam Shizuku, di bawah “Start via Wireless debugging” (Mula melalui Penyahpepijatan wayarles), ketik “Pairing” (Gandingan). Pada halaman yang dibuka, ketik “Pilihan pembangun”, hidupkan “Penyahpepijatan wayarles” dan sahkan “Benarkan”.\n\n5. Ketik perkataan “Penyahpepijatan wayarles” (bukan suisnya), kemudian “Gandingkan peranti dengan kod gandingan”. Kod 6 digit dipaparkan.\n\n6. Biarkan skrin itu terbuka dan tarik turun pemberitahuan. Apabila pemberitahuan Shizuku menyatakan “Pairing service found” (Perkhidmatan gandingan ditemui), ketik “Enter pairing code” (Masukkan kod gandingan) dan taip kod itu. Shizuku menyatakan gandingan berjaya.\n\n7. Kembali ke Shizuku dan ketik “Start” (Mula) di bawah “Start via Wireless debugging”. Tunggu sehingga ia menyatakan “Shizuku is running” (Shizuku sedang berjalan).\n\n8. Kembali ke Waaiya dan ketik “Beri kebenaran”, kemudian “Benarkan”.\n\nSelepas telefon dimulakan semula, Shizuku berhenti: sambung ke Wi-Fi, hidupkan semula “Penyahpepijatan wayarles” jika ia dimatikan, buka Shizuku dan ketik “Start”. Tiada gandingan baharu.';

  @override
  String get wsetupRouteTitle => 'Sediakan pada telefon ini';

  @override
  String get wsetupRouteBody =>
      'Empat langkah ringkas, dibuat sekali sahaja. Tiada apl tambahan dan tiada komputer. Waaiya menandakan setiap langkah apabila ia selesai.';

  @override
  String get wizDevTitle => 'Hidupkan Pilihan pembangun';

  @override
  String get wizDevBody =>
      'Dalam Perihal telefon, ketik “Nombor binaan” 7 kali, kemudian kembali ke sini. Jika anda tidak dapat menemuinya, cari “Nombor binaan” dalam Tetapan.';

  @override
  String get wizDevBodySamsung =>
      'Dalam Perihal telefon › “Software information” (Maklumat perisian), ketik “Nombor binaan” 7 kali, kemudian kembali ke sini.';

  @override
  String get wizDevBodyXiaomi =>
      'Dalam Perihal telefon, ketik “OS version” (Versi OS) 7 kali (pada telefon lama, “MIUI version” (Versi MIUI); pada sesetengahnya ia berada di bawah “Detailed info and specs” (Maklumat terperinci dan spesifikasi)), kemudian kembali ke sini.';

  @override
  String get wizDevBodyColoros =>
      'Dalam “About device” (Perihal peranti) (atau Perihal telefon) › “Version” (Versi), ketik “Nombor binaan” 7 kali, kemudian kembali ke sini.';

  @override
  String get wizDevBodyVivo =>
      'Dalam Perihal telefon, ketik “Software version” (Versi perisian) 7 kali (pada sesetengah telefon: “Software information” (Maklumat perisian) › “Nombor binaan”), kemudian kembali ke sini.';

  @override
  String get wizDevBodyHuawei =>
      'Dalam Perihal telefon, ketik “Nombor binaan” 7 kali, kemudian kembali ke sini.';

  @override
  String get wizDevBodyTranssion =>
      'Dalam “My phone” (Telefon saya) (atau Perihal telefon), ketik “Nombor binaan” 7 kali, kemudian kembali ke sini.';

  @override
  String get setupNoteHuawei =>
      'Huawei: banyak telefon Huawei tiada “Penyahpepijatan wayarles”. Jika anda tidak dapat menemuinya dalam Pilihan pembangun, gunakan komputer (“Cara lain” di bawah).';

  @override
  String get wsetupFilterOn =>
      'Penapisan dihidupkan: pada versi Android ini, kod tidak boleh ditaip dalam pemberitahuan semasa ia berjalan. Hentikan penapisan dahulu, atau gunakan skrin pisah dan “Taip kod di sini”.';

  @override
  String get wizDevSearch =>
      'Nama boleh berbeza mengikut bahasa telefon: jika anda tidak dapat menemuinya, gunakan carian di bahagian atas Tetapan.';

  @override
  String get wizDevAction => 'Buka Perihal telefon';

  @override
  String get wizWifiTitle => 'Sambung ke Wi-Fi';

  @override
  String get wizWifiBody =>
      'Mana-mana rangkaian Wi-Fi boleh digunakan; internet tidak diperlukan.';

  @override
  String get wizWifiAction => 'Buka tetapan Wi-Fi';

  @override
  String get wizWdTitle => 'Hidupkan Penyahpepijatan wayarles';

  @override
  String get wizWdBody =>
      'Waaiya membuka Pilihan pembangun pada “Penyahpepijatan wayarles”. Hidupkannya dan ketik “Benarkan”.';

  @override
  String get wizWdAction => 'Buka Pilihan pembangun';

  @override
  String get wizPairTitle => 'Taip kod gandingan';

  @override
  String get wizPairBody =>
      'Ketik perkataan “Penyahpepijatan wayarles”, kemudian “Gandingkan peranti dengan kod gandingan”. Taip 6 digit itu dalam pemberitahuan Waaiya. Waaiya melakukan selebihnya.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya sudah digandingkan dengan telefon ini: kod tidak diperlukan. Ketik butang dan Waaiya menyelesaikannya dengan sendiri.';

  @override
  String get wizPairAction => 'Teruskan';

  @override
  String get wizAgain => 'Jalankan persediaan sekali lagi';

  @override
  String get setupShizukuReadyTitle => 'Dengan Shizuku, yang sudah berjalan';

  @override
  String get setupOtherWaysPlain => 'Cara lain untuk membuat persediaan';

  @override
  String get wizSkip => 'Langkau ke Penyahpepijatan wayarles';

  @override
  String get setupOtherWays => 'Cara lain: Shizuku atau komputer';

  @override
  String get wsetupEnterHere => 'Taip kod di sini';

  @override
  String get wsetupCancel => 'Batal';

  @override
  String get wsetupAndroid10 =>
      'Android 10 tidak dapat membuat persediaan sendiri: ia memerlukan komputer, secara terus (di bawah) atau untuk memulakan Shizuku sekali.';

  @override
  String get wsetupShizukuHeading => 'Atau dengan apl Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku juga membenarkan sentuhan melalui penutup skrin.';

  @override
  String get wsetupChannel => 'Persediaan sekali sahaja';

  @override
  String get wsetupNotifTitle => 'Persediaan Waaiya: menunggu kod gandingan';

  @override
  String get wsetupFoundTitle => 'Skrin gandingan ditemui';

  @override
  String get wsetupBusyTitle => 'Persediaan Waaiya';

  @override
  String get wsetupDoneTitle => 'Persediaan selesai';

  @override
  String get wsetupDoneBody =>
      'Waaiya kini boleh menyenyapkan bunyi asal. Anda boleh mematikan Penyahpepijatan wayarles.';

  @override
  String get wsetupDoneHelperBody =>
      'Selesai. Telefon ini tidak membenarkan apl mengekalkan kebenaran ini, jadi pembantu Waaiya menyenyapkan bunyi asal sebagai gantinya. Pembantu berhenti apabila telefon dimulakan semula dan apabila Waaiya dikemas kini. Apabila anda membuka Waaiya selepas itu, ia memulakan semula pembantu dengan sendirinya jika Penyahpepijatan wayarles dihidupkan; jika tidak, ia menunjukkan butang untuknya.';

  @override
  String get helperMissingTitle => 'Pembantu Waaiya dihentikan';

  @override
  String get helperMissingBody =>
      'Telefon ini tidak mengekalkan kebenaran Waaiya, jadi Waaiya menggunakan pembantunya. Pembantu berhenti apabila telefon dimulakan semula dan apabila Waaiya dikemas kini. Sambung ke Wi-Fi, hidupkan “Penyahpepijatan wayarles” dalam Pilihan pembangun, kemudian ketik “Mulakan pembantu Waaiya”.';

  @override
  String get helperChannel => 'Pembantu Waaiya';

  @override
  String get helperStarting => 'Memulakan pembantu…';

  @override
  String get helperModeNote =>
      'Telefon ini tidak membenarkan apl mengekalkan kebenaran ini: pembantu Waaiya melakukan kerja itu. Ia berhenti apabila telefon dimulakan semula dan apabila Waaiya dikemas kini. Apabila anda membuka Waaiya selepas itu, ia memulakan semula pembantu dengan sendirinya jika Penyahpepijatan wayarles dihidupkan; jika tidak, ia menunjukkan butang untuknya.';

  @override
  String get helperTipXiaomi =>
      'Pilihan, untuk mengekalkan kebenaran secara kekal (tiada pembantu selepas dimulakan semula): dalam Pilihan pembangun, hidupkan “USB debugging (Security settings)” (Penyahpepijatan USB (Tetapan keselamatan)) (ia meminta anda log masuk ke akaun Xiaomi), kemudian buat persediaan sekali lagi.';

  @override
  String get helperTipColoros =>
      'Pilihan, untuk mengekalkan kebenaran secara kekal (tiada pembantu selepas dimulakan semula): dalam Pilihan pembangun, hidupkan “Disable permission monitoring” (Lumpuhkan pemantauan kebenaran) (pada versi terbaharu, “Disable system optimization” (Lumpuhkan pengoptimuman sistem); ia mungkin hanya muncul apabila bahasa telefon ditetapkan kepada Bahasa Inggeris), kemudian buat persediaan sekali lagi.';

  @override
  String get stateOnHelperMissing =>
      'Bunyi asal tidak disenyapkan, jadi anda mendengar muzik bersama bunyi yang ditapis: pembantu Waaiya dihentikan. Sambung ke Wi-Fi, hidupkan Penyahpepijatan wayarles, kemudian ketik “Mulakan pembantu Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Atau gunakan “Sediakan pada telefon ini” pada halaman ini: pembantu Waaiya kemudian berfungsi tanpa suis itu.';

  @override
  String get helperStartAnywayTitle => 'Pembantu Waaiya dihentikan';

  @override
  String get helperStartAnywayBody =>
      'Tanpanya anda akan mendengar muzik bersama bunyi yang ditapis. Mulakan pembantu dahulu (Penyahpepijatan wayarles mesti dihidupkan), atau tetap mulakan penapisan.';

  @override
  String get wsetupFailedTitle => 'Persediaan tidak selesai';

  @override
  String get wsetupPairing => 'Menggandingkan…';

  @override
  String get wsetupConnecting => 'Menyambung dan memberikan kebenaran…';

  @override
  String get wsetupNeedWifi =>
      'Sambung ke rangkaian Wi-Fi dahulu (internet tidak diperlukan): Penyahpepijatan wayarles hanya berfungsi pada Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Dalam Pilihan pembangun, hidupkan “Penyahpepijatan wayarles”, kemudian ketik namanya dan “Gandingkan peranti dengan kod gandingan”.';

  @override
  String get wsetupOpenDialog =>
      'Dalam Penyahpepijatan wayarles, ketik “Gandingkan peranti dengan kod gandingan”. Biarkan kod pada skrin dan ketik “Masukkan kod” di sini.';

  @override
  String get wsetupEnterCodeBody =>
      'Ketik “Masukkan kod” dan taip kod 6 digit yang ditunjukkan dalam Tetapan.';

  @override
  String get wsetupCodeWaiting =>
      'Kod diterima. Menunggu skrin “Gandingkan peranti dengan kod gandingan”: biarkan ia terbuka.';

  @override
  String get wsetupWrongCode =>
      'Kod itu tidak diterima. Semak 6 digit pada skrin dan masukkannya sekali lagi. Jika skrin gandingan tertutup, bukanya semula: kodnya berubah.';

  @override
  String get wsetupPairingFailed =>
      'Gandingan tidak berjaya. Tutup skrin gandingan, buka “Gandingkan peranti dengan kod gandingan” sekali lagi dan masukkan kod baharu.';

  @override
  String get wsetupWaitingConnect =>
      'Digandingkan. Biarkan “Penyahpepijatan wayarles” dihidupkan: Waaiya sedang menyambung.';

  @override
  String get wsetupNotPaired =>
      'Telefon ini tidak lagi mengenali Waaiya (gandingan telah dialih keluar atau tamat tempoh). Buka “Gandingkan peranti dengan kod gandingan” dan masukkan kod.';

  @override
  String get wsetupConnectFailed =>
      'Tidak dapat menyambung ke Penyahpepijatan wayarles. Matikan dan hidupkannya semula: Waaiya mencuba lagi dengan sendirinya.';

  @override
  String get wsetupGrantFailed =>
      'Disambungkan, tetapi kebenaran masih tiada. Gunakan Shizuku atau komputer di bawah.';

  @override
  String get wsetupTimeout =>
      'Dihentikan selepas 10 minit tanpa selesai. Anda boleh mencuba lagi.';

  @override
  String get wsetupCodeUnreadable => 'Taip 6 digit kod gandingan.';

  @override
  String get wsetupCodeHint => 'Kod 6 digit';

  @override
  String get wsetupEnterCode => 'Masukkan kod';

  @override
  String wsetupDetail(String details) {
    return 'Butiran: $details';
  }

  @override
  String get wsetupErrTimeout => 'tiada jawapan dalam masa';

  @override
  String get wsetupErrRefused => 'sambungan ditolak';

  @override
  String get wsetupDevOff =>
      'Pilihan pembangun dimatikan. Dalam Perihal telefon, ketik “Nombor binaan” 7 kali, kemudian kembali.';

  @override
  String get wsetupOpenAbout => 'Perihal telefon';

  @override
  String get wsetupNotifOff =>
      'Pemberitahuan dimatikan untuk Waaiya, jadi kod tidak boleh ditaip dalam pemberitahuan. Gunakan skrin pisah (Tetapan di satu bahagian, Waaiya di bahagian lain) dan ketik “Taip kod di sini”.';

  @override
  String get wsetupCodeDialogTitle => 'Kod gandingan';

  @override
  String get wsetupCodeDialogBody =>
      'Hanya dengan skrin pisah (Tetapan di satu bahagian, Waaiya di bahagian lain): meninggalkan Tetapan akan menutup skrin gandingan dan kodnya tidak lagi berfungsi. Taip kod 6 digit yang ditunjukkan di bawah “Gandingkan peranti dengan kod gandingan”.';

  @override
  String get wsetupCodeOk => 'Gandingkan';

  @override
  String get blurStrictTitle => 'Siapa yang dibiarkan tidak ditutup';

  @override
  String blurStrictValue(String level) {
    return 'Siapa yang dibiarkan tidak ditutup: $level';
  }

  @override
  String get blurStrict0 => 'Ketat: hanya orang yang apl hampir pasti lelaki';

  @override
  String get blurStrict1 =>
      'Seimbang: kira-kira dua kali ganda lelaki dibiarkan tidak ditutup';

  @override
  String get blurStrict2 =>
      'Longgar: sedikit lebih ramai lelaki berbanding seimbang';

  @override
  String get blurStrict0Short => 'ketat';

  @override
  String get blurStrict1Short => 'seimbang';

  @override
  String get blurStrict2Short => 'longgar';

  @override
  String get blurStrictHelp =>
      'Sesiapa yang apl tidak pasti lelaki akan ditutup. Ketat membiarkan kira-kira 7 daripada 100 lelaki tidak ditutup; seimbang kira-kira 14, longgar kira-kira 16. Setiap langkah yang kurang ketat juga membiarkan kira-kira 1 lagi daripada 100 wanita tidak ditutup.';

  @override
  String get stateOnNotMuted =>
      'Bunyi asal belum disenyapkan, jadi anda mendengar muzik bersama bunyi yang ditapis. Selesaikan persediaan sekali sahaja di bawah.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya tidak dapat menyenyapkan bunyi asal apl yang sedang dimainkan, jadi muzik mungkin masih kedengaran. Hentikan dan mulakan penapisan. Jika masih berlaku, hantar laporan diagnostik (di bahagian bawah skrin ini).';

  @override
  String get stateTooSlow =>
      'Telefon ini terlalu perlahan untuk menapis bunyi secara langsung, jadi bunyi terputus-putus. “Buka pautan” di bawah masih berfungsi: ia menapis video sebelum memainkannya.';

  @override
  String get stateMonoNote =>
      'Bunyi dalam mono supaya telefon ini tidak ketinggalan.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Disenyapkan, kerana ia tidak membenarkan penapisan: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Dimainkan tanpa penapisan, kerana ia tidak membenarkan penapisan: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android tidak memberikan bunyi apl lain kepada Waaiya. Ketik butang untuk bermula semula.';

  @override
  String get stateCaptureCancelled =>
      'Permulaan dibatalkan pada soalan perkongsian skrin Android. Waaiya memerlukan “Mula” di situ untuk menerima bunyi. Tiada apa-apa dirakam atau dihantar.';

  @override
  String get startNoSetupTitle => 'Muzik masih akan kedengaran';

  @override
  String get startNoSetupBody =>
      'Persediaan sekali sahaja belum dibuat. Tanpanya Waaiya tidak dapat menyenyapkan bunyi asal: anda akan mendengar muzik dan bunyi yang ditapis serentak.\n\n“Buka pautan” berfungsi tanpa sebarang persediaan.';

  @override
  String get startNoSetupSetup => 'Buat persediaan';

  @override
  String get startNoSetupAnyway => 'Tetap mulakan';

  @override
  String get diagButton => 'Ada masalah? Laporan diagnostik';

  @override
  String get diagTitle => 'Laporan diagnostik';

  @override
  String get diagNote =>
      'Apa yang Waaiya lihat pada telefon ini. Salin atau kongsikannya dengan sesiapa yang membantu anda. Apl ini sendiri tidak menghantar apa-apa.';

  @override
  String get notifStoppedTitle => 'Waaiya berhenti';

  @override
  String get notifStoppedText =>
      'Bunyi tidak ditapis lagi. Ketik untuk bermula semula.';

  @override
  String get wsetupGuide => 'Langkah dengan gambar';

  @override
  String get navFilter => 'Penapis';

  @override
  String get navScreen => 'Skrin';

  @override
  String get navLinks => 'Pautan';

  @override
  String get navSetup => 'Persediaan';

  @override
  String get navSettings => 'Tetapan';

  @override
  String get setupDoneTitle => 'Persediaan selesai';

  @override
  String get setupDoneBody =>
      'Waaiya boleh menyenyapkan bunyi asal apl lain. Buat semula hanya jika sesuatu berubah (persediaan telah dibatalkan, atau Waaiya menyatakan ia tiada).';

  @override
  String get setupRedo => 'Tunjukkan persediaan sekali lagi';

  @override
  String get setupGo => 'Pergi ke persediaan';

  @override
  String get helperTitle => 'Sentuhan melalui penutup';

  @override
  String get helperBodyOff =>
      'Tanpa bantuan, penutup menyekat sentuhan di bawahnya. Pembantu Waaiya melukis penutup supaya sentuhan dapat melaluinya. Hidupkan Penyahpepijatan wayarles (Wi-Fi diperlukan) dan ketik butang; kali pertama, gandingkan sekali seperti dalam persediaan. Selepas telefon dimulakan semula, ketiknya sekali lagi.';

  @override
  String get helperStart => 'Mulakan pembantu Waaiya';

  @override
  String get helperOn =>
      'Pembantu Waaiya melukis penutup: sentuhan dapat melaluinya. Ia berhenti apabila telefon dimulakan semula atau apabila Penyahpepijatan USB dimatikan; ketik butang sekali lagi pada masa itu.';

  @override
  String get helperShizukuOn =>
      'Shizuku melukis penutup: sentuhan dapat melaluinya.';

  @override
  String get helperOrShizuku => 'Atau dengan Shizuku:';

  @override
  String get filterOptionsTitle => 'Pilihan penapis';

  @override
  String get settingsGeneralTitle => 'Umum';

  @override
  String get desktopPreview =>
      'Pratonton: enjin penapis belum disambungkan pada komputer ini. Butang ini hanya menunjukkan cara apl akan berfungsi.';

  @override
  String actionFailed(String details) {
    return 'Itu tidak berjaya: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Alat muzik dibuang daripada semua apl.';

  @override
  String get engineErrorNoPactl =>
      'Alat bunyi tidak ditemui (pactl). Waaiya memerlukan PulseAudio, atau PipeWire dengan pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Pelayan bunyi tidak berjalan (PulseAudio atau PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Sistem ini tiada sesi pengguna systemd, yang menjalankan penapis di latar belakang.';

  @override
  String get engineErrorNoOutput =>
      'Tiada pembesar suara atau fon kepala ditemui.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Tidak dapat memasang penapis. Butiran:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Penapis tidak bermula. Butiran:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Penapis berhenti dengan ralat. Butiran:\n$details';
  }

  @override
  String get autostartTitle => 'Mula semasa log masuk';

  @override
  String get autostartBody => 'Tapis bunyi sebaik sahaja anda log masuk.';

  @override
  String get blurBodyDesktop =>
      'Menutup orang dan imej pada skrin, di atas setiap tetingkap, selagi Waaiya dibuka (ia berfungsi sama ada penapis bunyi dihidupkan atau dimatikan). Ia berjalan pada komputer ini; tiada apa-apa dihantar ke mana-mana. Menutup tetingkap Waaiya akan menghentikan pengaburan.';

  @override
  String get blurFailBodyDesktop =>
      'Hidup: seluruh skrin ditutup apabila komputer terlalu perlahan atau pengaburan gagal; klik masih sampai ke tetingkap di bawahnya. Mati: skrin kekal kelihatan dengan bar merah di bahagian atas.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Pengaburan dihidupkan. Desktop ini menunjukkan pengaburan dalam tangkapan skrinnya sendiri, jadi kawasan yang dikaburkan kekal kabur sehingga adegan berubah.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Pengaburan tidak dapat dipaparkan di atas tetingkap lain pada desktop ini. Butiran:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Pilih skrin anda dalam tetingkap perkongsian skrin dan benarkannya. Waaiya hanya meminta sekali; gambar kekal pada komputer ini.';

  @override
  String blurStatusExited(String details) {
    return 'Pengaburan berhenti secara tiba-tiba. Matikan dan hidupkan semula satu pilihan pengaburan untuk mencuba lagi. Butiran:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Pengesan nyanyian wanita tidak dimuatkan, jadi suara disenyapkan selagi pilihan itu dihidupkan.';

  @override
  String get blurStatusUncovered =>
      'Satu monitor tidak ditutup oleh pengaburan: ia tidak dikongsi dengannya, atau ia dipasang kemudian. Matikan dan hidupkan semula satu pilihan pengaburan, dan pilih setiap skrin dalam tetingkap perkongsian skrin.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Model pengaburan tiada dalam pemasangan ini, jadi ia tidak dapat menutup apa-apa; bar merah kekal di bahagian atas skrin. Pasang semula Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Apa yang Waaiya lihat pada komputer ini. Salin dan berikannya kepada sesiapa yang membantu anda. Apl ini sendiri tidak menghantar apa-apa.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Disyorkan. Jika penapisan berhenti dengan sendirinya (kerana ralat, bukan oleh anda), apl lain kekal senyap sehingga anda memulakan semula atau menekan Berhenti, daripada memainkan muzik tanpa tapisan.';

  @override
  String get settingStereoBodyDesktop =>
      'Mati: mono, yang kurang membebankan komputer. Hidup: memisahkan bahagian kiri dan kanan. Jika komputer terlalu perlahan untuk stereo, ia bertukar kepada mono dengan sendirinya.';

  @override
  String get linkEntryBodyDesktop =>
      'Tampal pautan YouTube, TikTok atau Instagram untuk menontonnya dengan penapis aktif, atau untuk menyimpannya tanpa muzik.';

  @override
  String get linkEntryBodyWatch =>
      'Tampal pautan YouTube, TikTok atau Instagram untuk menontonnya dalam pelayar anda dengan penapis aktif.';

  @override
  String get linkWatchNoteDesktop =>
      'Dibuka dalam pelayar anda. Waaiya memulakan penapis dahulu, jadi muzik juga dibuang di sana.';

  @override
  String get linkFilterFailed =>
      'Penapis tidak bermula, jadi pautan tidak dibuka. Mulakannya di halaman Penapis dan cuba lagi.';

  @override
  String get linkSavedVideoDesktop => 'Dalam folder Video anda: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Dalam folder Muzik anda: Waaiya';

  @override
  String get linkShowInFolder => 'Tunjuk dalam folder';

  @override
  String get linkSingingNote =>
      'Nyanyian wanita juga disenyapkan, seperti dalam tetapan anda.';
}
