// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Her uygulamadan müzik aletlerini kaldırır; konuşmayı ve tilaveti korur.';

  @override
  String get onboardTitle => 'Hoş geldiniz';

  @override
  String get onboardBody =>
      'Waaiya, bu telefondaki her uygulamanın sesinden müzik aletlerini kaldırır. Konuşma ve Kuran tilaveti korunur. Şimdilik şarkı söyleyen sesler de kaldırılır.';

  @override
  String get onboardQuestion => 'Cinsiyetiniz';

  @override
  String get genderMan => 'Erkek';

  @override
  String get genderWoman => 'Kadın';

  @override
  String get onboardWhy =>
      'Bu yalnızca hangi isteğe bağlı ayarları göreceğinizi belirler. Daha sonra değiştirebilirsiniz.';

  @override
  String get stateOnTitle => 'Filtreleme açık';

  @override
  String get stateOffTitle => 'Filtreleme kapalı';

  @override
  String get stateStarting => 'Başlatılıyor…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Tüm uygulamalardan müzik aletleri kaldırılıyor. Gecikme yaklaşık $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Başlatmak için düğmeye dokunun.';

  @override
  String get stateModelFailed =>
      'Ses modeli yüklenemedi, bu yüzden güvenlik için ses kapatıldı.';

  @override
  String get stateCaptureDenied =>
      'Diğer uygulamaların sesini almak için mikrofon izni gerekiyor.';

  @override
  String get stateStoppedBySystem =>
      'Android filtrelemeyi durdurdu. Yeniden başlatmak için düğmeye dokunun.';

  @override
  String get stateSilencedTitle => 'Filtreleme durdu';

  @override
  String get stateSilenced =>
      'Filtreleme durdu: diğer uygulamalar susturuldu. Yeniden başlatmak için düğmeye dokunun ya da onları filtresiz duymak için Durdur\'a dokunun.';

  @override
  String get releaseSilence => 'Durdur: uygulamaları filtresiz duy';

  @override
  String get powerStartCd => 'Filtrelemeyi başlat';

  @override
  String get powerStopCd => 'Filtrelemeyi durdur';

  @override
  String get captureHint =>
      'Android, ekranınızı paylaşmak için izin isteyecek. Yalnızca ses kullanılır: hiçbir şey kaydedilmez veya gönderilmez.';

  @override
  String get needRecordAudio =>
      'Waaiya\'nın diğer uygulamaların sesini alabilmesi için mikrofon izni gerekir. Sizi asla kaydetmez.';

  @override
  String get setupBannerTitle => 'Bir adım daha';

  @override
  String get setupBannerBody =>
      'Aşağıdaki tek seferlik kurulum yapılmazsa müziği ve filtrelenmiş sesi birlikte duyarsınız.';

  @override
  String get step1Title => 'Shizuku\'yu yükleyin';

  @override
  String get step1Body => 'Play Store\'dan ücretsiz bir yardımcı uygulama.';

  @override
  String get step1Action => 'Shizuku\'yu indir';

  @override
  String get step2Title => 'Shizuku\'yu başlatın';

  @override
  String get step2Body =>
      'Shizuku, Android\'in kablosuz hata ayıklaması ile Wi-Fi üzerinden başlar. Adımlar için düğmeye dokunun, sonra geri dönün.';

  @override
  String get step2Action => 'Shizuku\'yu aç';

  @override
  String get step2Update => 'Shizuku\'yu güncelle';

  @override
  String get step2TooOld =>
      'Shizuku sürümünüz çok eski. Play Store\'dan güncelleyin.';

  @override
  String get step2Denied =>
      'Shizuku, Waaiya\'yı her zaman reddedecek şekilde ayarlı. Shizuku\'da, uygulama listesinden Waaiya\'ya izin verin.';

  @override
  String get step3Title => 'Yetki verin';

  @override
  String get step3Body => 'Tek dokunuş, ardından “İzin ver”i seçin.';

  @override
  String get step3Action => 'Yetki ver';

  @override
  String get step3Busy => 'Kuruluyor…';

  @override
  String get setupDoneRestart =>
      'Tamam. Uygulamak için filtrelemeyi bir kez durdurup başlatın.';

  @override
  String setupFailed(String details) {
    return 'Kurulum tamamlanmadı. Ayrıntılar:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Shizuku izni reddedildi. Yeniden denemek için düğmeye dokunun.';

  @override
  String get setupSlow =>
      'Shizuku her zamankinden uzun sürüyor. Beklemeye devam edin: bazı telefonlarda yardımcısının ilk kez başlaması bir dakikayı bulur.';

  @override
  String get setupTimeout =>
      'Shizuku 2 dakika içinde yanıt vermedi. Shizuku\'yu açın, çalıştığını yazdığını kontrol edin, sonra düğmeye yeniden dokunun. Kurulum daha sonra biterse bu ekran kendiliğinden güncellenir.';

  @override
  String get setupRefusedXiaomi =>
      'Bu telefon izinleri reddetti. Xiaomi, Redmi ve POCO\'da Geliştirici seçeneklerinde “USB debugging (Security settings)” (USB hata ayıklaması – Güvenlik ayarları) seçeneğini açın (bir Xiaomi hesabına giriş yapmanızı ister), sonra yeniden deneyin.';

  @override
  String get setupRefusedColoros =>
      'Bu telefon izinleri reddetti. OPPO, OnePlus ve realme\'de Geliştirici seçeneklerinde “Disable permission monitoring” (İzin izlemeyi devre dışı bırak) seçeneğini açın (en yeni sürümlerde adı “Disable system optimization” (Sistem optimizasyonunu devre dışı bırak) olur ve yalnızca telefon İngilizceye ayarlıyken görünebilir). Bulmak için Ayarlarda “permission” diye arayın. Sonra yeniden deneyin.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi ve POCO: bildirimde kodu yazacak bir alan yoksa, bildirim ayarlarında bildirim stilini “Android” yapın ya da bölünmüş ekranla kodu Waaiya\'ya yazın.';

  @override
  String get stepDoneCd => 'Tamamlandı';

  @override
  String stepTodoCd(int step) {
    return 'Adım $step';
  }

  @override
  String get computerToggle => 'Bunun yerine bilgisayar kullan';

  @override
  String get computerBody =>
      'USB hata ayıklamasını açın, telefonu bağlayın ve şunu çalıştırın:';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get computerNote =>
      'İkinci satır isteğe bağlıdır: her başlatmada çıkan ekran paylaşımı sorusunu kaldırır.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingSilenceTitle =>
      'Filtrelemeyi engelleyen uygulamaları sustur';

  @override
  String get settingSilenceBody =>
      'Önerilir. Bazı uygulamalar seslerinin filtrelenmesine izin vermez; bu seçenek müziğin geçmesine izin vermek yerine onları susturur.';

  @override
  String get settingHoldSilenceTitle =>
      'Filtreleme kendiliğinden durursa uygulamaları sessiz tut';

  @override
  String get settingHoldSilenceBody =>
      'Önerilir. Filtrelemeyi siz değil de Android sonlandırırsa, diğer uygulamalar filtresiz müzik çalmak yerine siz yeniden başlatana veya Durdur\'a dokunana kadar sessiz kalır. Tek seferlik kurulum gerekir.';

  @override
  String get settingStereoTitle => 'Stereo ses';

  @override
  String get settingStereoBody =>
      'Kapalı: mono; pilin yaklaşık yarısını kullanır ve daha çok telefonda yetişir. Açık: sol ve sağ tarafları ayrı tutar. Telefon stereo için fazla yavaşsa yine kendiliğinden monoya geçer.';

  @override
  String get settingSingingTitle => 'Kadınların şarkı sesini sustur';

  @override
  String get settingSingingBody => 'Kadınların konuşması ve tilaveti korunur.';

  @override
  String get settingSingingNoModel =>
      'Bu sürümde şarkı algılayıcı yok, bu yüzden bu seçenek açıkken tüm sesler susturulur.';

  @override
  String get settingRestart =>
      'Değişiklikleri uygulamak için filtrelemeyi durdurup başlatın.';

  @override
  String get settingGenderTitle => 'Cinsiyetiniz';

  @override
  String get change => 'Değiştir';

  @override
  String get playerTitle => 'Tam eşzamanlı videolar';

  @override
  String get playerBody =>
      'Bir videoyu hiç gecikme olmadan filtrelenmiş izlemek için Waaiya ile paylaşın (veya “Şununla aç”ı kullanın).';

  @override
  String get licences => 'Açık kaynak lisansları';

  @override
  String get licencesIntro =>
      'Waaiya, GNU Affero Genel Kamu Lisansı v3 veya sonraki sürümleri kapsamında özgür bir yazılımdır. Kaynak kodu: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Atıf 4.0 (eğitim verileri): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Tam metinler';

  @override
  String get back => 'Geri';

  @override
  String get linkEntryTitle => 'Bağlantı aç';

  @override
  String get linkEntryBody =>
      'Müziksiz izlemek veya kaydetmek için bir YouTube, TikTok ya da Instagram bağlantısı yapıştırın.';

  @override
  String get linkTitle => 'Bağlantı aç';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Video veya ses bağlantısı';

  @override
  String get linkPaste => 'Yapıştır';

  @override
  String get linkOpen => 'Aç';

  @override
  String get linkResolving => 'Bağlantı açılıyor…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Müziksiz izle';

  @override
  String get linkSave => 'Müziksiz kaydet';

  @override
  String get linkListen => 'Müziksiz dinle';

  @override
  String get linkAudioOnly =>
      'Bu bağlantının videosu henüz açılamıyor: yalnızca sesi açılabiliyor.';

  @override
  String get linkDownloading => 'İndiriliyor…';

  @override
  String get linkFiltering => 'Müzik kaldırılıyor…';

  @override
  String get linkCancel => 'İptal';

  @override
  String get linkCancelled => 'İptal edildi. Hiçbir şey kaydedilmedi.';

  @override
  String get linkTimedOut =>
      'Android kaydı durdurdu: bu tür işlere günde yalnızca birkaç saat izin veriyor. Hiçbir şey kaydedilmedi; Waaiya\'yı açıp yeniden deneyin.';

  @override
  String get linkExportFailed => 'Bu kaydedilemedi. Hiçbir şey kaydedilmedi.';

  @override
  String get linkSaved => 'Müziksiz kaydedildi';

  @override
  String get linkSavedVideo => 'Galerinizde: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Müzikleriniz arasında: Music › Waaiya';

  @override
  String get linkPlay => 'Oynat';

  @override
  String get linkShare => 'Paylaş';

  @override
  String get linkShareNote =>
      'Yalnızca paylaşmanıza izin verilen videoları paylaşın.';

  @override
  String get linkLive => 'Canlı yayınlar kaydedilemez.';

  @override
  String get linkBusy =>
      'Başka bir video kaydediliyor. Lütfen bitmesini bekleyin.';

  @override
  String get linkInvalid =>
      'Lütfen bir web bağlantısı yapıştırın (https:// ile başlayan).';

  @override
  String get linkLogin =>
      'Site bu videoyu hesap olmadan göstermedi. Herkese açık gönderiler genellikle açılır: birkaç dakika sonra yeniden deneyin. Gizli gönderiler açılamaz.';

  @override
  String get linkUnsupported => 'Bu site desteklenmiyor.';

  @override
  String get linkPlaylist =>
      'Bu bir oynatma listesi. Lütfen tek bir video açın.';

  @override
  String get linkNoFormat =>
      'Bu video, Waaiya\'nın henüz filtreleyebildiği bir biçimde değil.';

  @override
  String get linkFailed =>
      'Bu bağlantı açılamadı. İnternet bağlantınızı kontrol edip yeniden deneyin.';

  @override
  String get linkPlayFailed =>
      'Bu oynatılamadı. Filtresiz hiçbir şey oynatılmadı.';

  @override
  String get linkLimited =>
      'Site şu anda istekleri sınırlıyor. Birkaç dakika sonra yeniden deneyin.';

  @override
  String get blurTitle => 'Ekran bulanıklaştırma';

  @override
  String get blurBody =>
      'Filtreleme açıkken her uygulamada ekrandaki insanları ve görüntüleri örter. Telefonda çalışır; hiçbir yere bir şey gönderilmez.';

  @override
  String get blurWomenTitle => 'Kadınları bulanıklaştır';

  @override
  String get blurWomenBody =>
      'Tüm vücut. Uygulamanın erkek olduğundan net emin olamadığı kişiler de bulanıklaştırılır.';

  @override
  String get blurNudityTitle => 'Uygunsuz görüntüleri bulanıklaştır';

  @override
  String get blurNudityBody =>
      'Kim olursa olsun çıplaklık ve açık giyim: tüm ekran örtülür.';

  @override
  String get blurFailTitle => 'Bulanıklaştırma yetişemezse ekranı ört';

  @override
  String get blurFailBody =>
      'Açık: telefon çok yavaş kaldığında veya bulanıklaştırma başarısız olduğunda tüm ekran örtülür. Kapalı: ekran bir uyarıyla görünür kalır.';

  @override
  String get blurSetupShizuku => 'Shizuku ile izin ver';

  @override
  String get blurSetupManual => 'Android ayarlarında izin ver';

  @override
  String get blurStatusNeedsSetup =>
      'Bulanıklaştırmanın diğer uygulamaların üzerine çizmesi gerekiyor. En iyisi: Shizuku ile izin verin (Waaiya Bulanıklaştırma erişilebilirlik hizmetini açar, böylece dokunuşlar alttaki uygulamaya yine ulaşır). Ya da Android ayarlarında “Diğer uygulamaların üzerinde göster” iznini verin (bu durumda bulanık bir alana yapılan dokunuşlar kaybolur).';

  @override
  String get blurStatusNeedsOverlay =>
      'Bulanıklaştırmanın diğer uygulamaların üzerine çizmesi gerekiyor. En iyisi: Shizuku\'yu başlatın (ve içinde Waaiya\'ya izin verin): bulanıklaştırma o zaman dokunuşların içinden geçtiği kendi katmanını çizer. Aksi halde Android ayarlarında “Diğer uygulamaların üzerinde göster” iznini verin; bu durumda bulanık bir alana yapılan dokunuş alttaki uygulamaya ulaşmaz.';

  @override
  String get blurFailUnavailable =>
      'Şimdilik kullanılamıyor: tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz. Waaiya yardımcısını veya Shizuku\'yu (Android 12 veya daha yeni) başlatın, seçenek kullanılabilir olur: örtüler o zaman dokunuşlar içinden geçecek şekilde çizilir. O zamana kadar, bulanıklaştırma yetişemediğinde ekran bir uyarıyla görünür kalır.';

  @override
  String get blurFailNeedsA11y =>
      'Şimdilik kullanılamıyor: tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz. Shizuku\'yu başlatın (Android 12 veya daha yeni) ya da Waaiya Bulanıklaştırma erişilebilirlik hizmetini açın (yukarıdaki “Shizuku ile izin ver”), seçenek kullanılabilir olur. O zamana kadar ekran bir uyarıyla görünür kalır.';

  @override
  String get languageTitle => 'Dil';

  @override
  String settingLanguageTitle(String language) {
    return 'Dil: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Bulanıklaştırma ayarlarını uygulamak için filtrelemeyi durdurup başlatın.';

  @override
  String get blurStatusStarting => 'Bulanıklaştırma başlatılıyor…';

  @override
  String get blurStatusOn => 'Bulanıklaştırma açık.';

  @override
  String get blurStatusOnVisible =>
      'Bulanıklaştırma dikkatli modda açık: bu telefon bulanıklığı kendi ekran yakalamasında gösteriyor, bu yüzden bulanık bir alan sahne değişene kadar bulanık kalır.';

  @override
  String get blurStatusModels =>
      'Bu sürümde seçilen seçenek için bulanıklaştırma modeli yok.';

  @override
  String get blurStatusFailing => 'Bulanıklaştırma şu anda yetişemiyor.';

  @override
  String get blurStatusNoOverlay =>
      'Bulanıklaştırma diğer uygulamaların üzerine çizemiyor: yukarıdan izin verin.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Bulanıklaştırma ekranı göremiyor. Ayrıntılar:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku izin veremedi:\n$details';
  }

  @override
  String get step2Guide => 'Shizuku nasıl başlatılır';

  @override
  String get blurFailOldAndroid =>
      'Kullanılamıyor: bu Android sürümünde tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz (Shizuku örtüleri Android 12 veya daha yenisini gerektirir). Bulanıklaştırma yetişemediğinde ekran bir uyarıyla görünür kalır.';

  @override
  String get guideTitle => 'Shizuku\'yu adım adım başlatın';

  @override
  String get guideOpenDev => 'Geliştirici seçenekleri';

  @override
  String get guideOpenShizuku => 'Shizuku\'yu aç';

  @override
  String get guideClose => 'Kapat';

  @override
  String get guideBody =>
      'Wi-Fi ve Android 11 veya daha yenisi gerekir. Eşleme bir kez yapılır; telefon yeniden başladıktan sonra yalnızca 7. adımı tekrarlarsınız.\n\n1. Telefonu Wi-Fi\'a bağlayın.\n\n2. Geliştirici seçeneklerini açın: Ayarlar › Telefon hakkında › “Software information” (Yazılım bilgileri) › “Derleme numarası”na 7 kez dokunun. (Diğer telefonlarda: Ayarlar › Telefon hakkında › Derleme numarası.)\n\n3. Shizuku\'yu açın. Bildirim göstermek için izin isterse izin verin: eşleme kodu bir Shizuku bildirimine yazılır.\n\n4. Shizuku\'da, “Start via Wireless debugging” (Kablosuz hata ayıklama ile başlat) altında “Pairing” (Eşleme) seçeneğine dokunun. Açılan sayfada “Geliştirici seçenekleri”ne dokunun, “Kablosuz hata ayıklama”yı açın ve “İzin ver” ile onaylayın.\n\n5. “Kablosuz hata ayıklama” yazısına (anahtara değil), ardından “Eşleme kodu ile cihaz eşle”ye dokunun. 6 haneli bir kod görünür.\n\n6. O ekranı açık tutun ve bildirimleri aşağı çekin. Shizuku bildirimi “Pairing service found” (Eşleme hizmeti bulundu) dediğinde “Enter pairing code” (Eşleme kodunu girin) seçeneğine dokunun ve kodu yazın. Shizuku eşlemenin başarılı olduğunu söyler.\n\n7. Shizuku\'ya geri dönün ve “Start via Wireless debugging” altındaki “Start” (Başlat) düğmesine dokunun. “Shizuku is running” (Shizuku çalışıyor) yazana kadar bekleyin.\n\n8. Waaiya\'ya geri dönün ve “Yetki ver”e, ardından “İzin ver”e dokunun.\n\nTelefon yeniden başladıktan sonra Shizuku durur: Wi-Fi\'a bağlanın, kapalıysa “Kablosuz hata ayıklama”yı yeniden açın, Shizuku\'yu açın ve “Start” (Başlat) düğmesine dokunun. Yeni eşleme gerekmez.';

  @override
  String get wsetupRouteTitle => 'Bu telefonda kur';

  @override
  String get wsetupRouteBody =>
      'Bir kez yapılan dört kısa adım. Ek uygulama ve bilgisayar gerekmez. Waaiya her adımı tamamlandığında işaretler.';

  @override
  String get wizDevTitle => 'Geliştirici seçeneklerini açın';

  @override
  String get wizDevBody =>
      'Telefon hakkında bölümünde “Derleme numarası”na 7 kez dokunun, sonra buraya geri dönün. Bulamazsanız Ayarlarda “Derleme numarası” diye arayın.';

  @override
  String get wizDevBodySamsung =>
      'Telefon hakkında › “Software information” (Yazılım bilgileri) bölümünde “Derleme numarası”na 7 kez dokunun, sonra buraya geri dönün.';

  @override
  String get wizDevBodyXiaomi =>
      'Telefon hakkında bölümünde “OS version” (İşletim sistemi sürümü) öğesine 7 kez dokunun (eski telefonlarda “MIUI version” (MIUI sürümü); bazılarında “Detailed info and specs” (Ayrıntılı bilgi ve özellikler) altındadır), sonra buraya geri dönün.';

  @override
  String get wizDevBodyColoros =>
      '“About device” (Cihaz hakkında) (veya Telefon hakkında) › “Version” (Sürüm) bölümünde “Derleme numarası”na 7 kez dokunun, sonra buraya geri dönün.';

  @override
  String get wizDevBodyVivo =>
      'Telefon hakkında bölümünde “Software version” (Yazılım sürümü) öğesine 7 kez dokunun (bazı telefonlarda: “Software information” (Yazılım bilgileri) › “Derleme numarası”), sonra buraya geri dönün.';

  @override
  String get wizDevBodyHuawei =>
      'Telefon hakkında bölümünde “Derleme numarası”na 7 kez dokunun, sonra buraya geri dönün.';

  @override
  String get wizDevBodyTranssion =>
      '“My phone” (Telefonum) (veya Telefon hakkında) bölümünde “Derleme numarası”na 7 kez dokunun, sonra buraya geri dönün.';

  @override
  String get setupNoteHuawei =>
      'Huawei: birçok Huawei telefonunda “Kablosuz hata ayıklama” yoktur. Geliştirici seçeneklerinde bulamazsanız bilgisayar kullanın (aşağıdaki “Diğer yollar”).';

  @override
  String get wsetupFilterOn =>
      'Filtreleme açık: bu Android sürümünde filtreleme çalışırken kod bir bildirime yazılamaz. Önce filtrelemeyi durdurun ya da bölünmüş ekranı ve “Kodu buraya yazın” seçeneğini kullanın.';

  @override
  String get wizDevSearch =>
      'Adlar telefonun diline göre değişebilir: bulamazsanız Ayarlar\'ın üst kısmındaki aramayı kullanın.';

  @override
  String get wizDevAction => 'Telefon hakkında sayfasını aç';

  @override
  String get wizWifiTitle => 'Wi-Fi\'a bağlanın';

  @override
  String get wizWifiBody => 'Herhangi bir Wi-Fi ağı olur; internet gerekmez.';

  @override
  String get wizWifiAction => 'Kablosuz ayarlarını aç';

  @override
  String get wizWdTitle => 'Kablosuz hata ayıklamayı açın';

  @override
  String get wizWdBody =>
      'Waaiya, Geliştirici seçeneklerini “Kablosuz hata ayıklama” hizasında açar. Bunu açın ve “İzin ver”e dokunun.';

  @override
  String get wizWdAction => 'Geliştirici seçeneklerini aç';

  @override
  String get wizPairTitle => 'Eşleme kodunu yazın';

  @override
  String get wizPairBody =>
      '“Kablosuz hata ayıklama” yazısına, ardından “Eşleme kodu ile cihaz eşle”ye dokunun. 6 haneyi Waaiya bildirimine yazın. Gerisini Waaiya yapar.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya bu telefonla zaten eşlenmiş: kod gerekmez. Düğmeye dokunun, Waaiya işi kendisi bitirir.';

  @override
  String get wizPairAction => 'Devam';

  @override
  String get wizAgain => 'Kurulumu yeniden çalıştır';

  @override
  String get setupShizukuReadyTitle => 'Zaten çalışan Shizuku ile';

  @override
  String get setupOtherWaysPlain => 'Kurulumun diğer yolları';

  @override
  String get wizSkip => 'Kablosuz hata ayıklamaya geç';

  @override
  String get setupOtherWays => 'Diğer yollar: Shizuku veya bilgisayar';

  @override
  String get wsetupEnterHere => 'Kodu buraya yazın';

  @override
  String get wsetupCancel => 'İptal';

  @override
  String get wsetupAndroid10 =>
      'Android 10 kurulumu kendi başına yapamaz: bir bilgisayar gerekir; ya doğrudan (aşağıda) ya da Shizuku\'yu bir kez başlatmak için.';

  @override
  String get wsetupShizukuHeading => 'Ya da Shizuku uygulamasıyla';

  @override
  String get wsetupShizukuNote =>
      'Shizuku ayrıca dokunuşların ekran örtülerinden geçmesini sağlar.';

  @override
  String get wsetupChannel => 'Tek seferlik kurulum';

  @override
  String get wsetupNotifTitle => 'Waaiya kurulumu: eşleme kodu bekleniyor';

  @override
  String get wsetupFoundTitle => 'Eşleme ekranı bulundu';

  @override
  String get wsetupBusyTitle => 'Waaiya kurulumu';

  @override
  String get wsetupDoneTitle => 'Kurulum tamamlandı';

  @override
  String get wsetupDoneBody =>
      'Waaiya artık orijinal sesi susturabilir. Kablosuz hata ayıklamayı kapatabilirsiniz.';

  @override
  String get wsetupDoneHelperBody =>
      'Tamam. Bu telefon uygulamaların bu izinleri tutmasına izin vermiyor, bu yüzden orijinal sesi onun yerine Waaiya yardımcısı susturur. Yardımcı, telefon yeniden başladığında ve Waaiya güncellendiğinde durur. Bundan sonra Waaiya\'yı açtığınızda, Kablosuz hata ayıklama açıksa yardımcıyı kendiliğinden yeniden başlatır; değilse bunun için bir düğme gösterir.';

  @override
  String get helperMissingTitle => 'Waaiya yardımcısı durdu';

  @override
  String get helperMissingBody =>
      'Bu telefon Waaiya\'nın izinlerini tutmuyor, bu yüzden Waaiya yardımcısını kullanır. Yardımcı, telefon yeniden başladığında ve Waaiya güncellendiğinde durur. Wi-Fi\'a bağlanın, Geliştirici seçeneklerinde “Kablosuz hata ayıklama”yı açın, sonra “Waaiya yardımcısını başlat”a dokunun.';

  @override
  String get helperChannel => 'Waaiya yardımcısı';

  @override
  String get helperStarting => 'Yardımcı başlatılıyor…';

  @override
  String get helperModeNote =>
      'Bu telefon uygulamaların bu izinleri tutmasına izin vermiyor: işi Waaiya yardımcısı yapar. Telefon yeniden başladığında ve Waaiya güncellendiğinde durur. Bundan sonra Waaiya\'yı açtığınızda, Kablosuz hata ayıklama açıksa yardımcıyı kendiliğinden yeniden başlatır; değilse bunun için bir düğme gösterir.';

  @override
  String get helperTipXiaomi =>
      'İsteğe bağlı, izinleri kalıcı tutmak için (yeniden başlatmalardan sonra yardımcı gerekmez): Geliştirici seçeneklerinde “USB debugging (Security settings)” (USB hata ayıklaması – Güvenlik ayarları) seçeneğini açın (bir Xiaomi hesabına giriş yapmanızı ister), sonra kurulumu yeniden yapın.';

  @override
  String get helperTipColoros =>
      'İsteğe bağlı, izinleri kalıcı tutmak için (yeniden başlatmalardan sonra yardımcı gerekmez): Geliştirici seçeneklerinde “Disable permission monitoring” (İzin izlemeyi devre dışı bırak) seçeneğini açın (en yeni sürümlerde “Disable system optimization” (Sistem optimizasyonunu devre dışı bırak); yalnızca telefon İngilizceye ayarlıyken görünebilir), sonra kurulumu yeniden yapın.';

  @override
  String get stateOnHelperMissing =>
      'Orijinal ses susturulmadı, bu yüzden müziği filtrelenmiş sesle birlikte duyarsınız: Waaiya yardımcısı durdu. Wi-Fi\'a bağlanın, Kablosuz hata ayıklamayı açın, sonra “Waaiya yardımcısını başlat”a dokunun.';

  @override
  String get setupRefusedTryWireless =>
      'Ya da bu sayfadaki “Bu telefonda kur” seçeneğini kullanın: Waaiya yardımcısı o zaman bu anahtar olmadan çalışır.';

  @override
  String get helperStartAnywayTitle => 'Waaiya yardımcısı durdu';

  @override
  String get helperStartAnywayBody =>
      'Yardımcı olmadan müziği filtrelenmiş sesle birlikte duyarsınız. Önce yardımcıyı başlatın (Kablosuz hata ayıklama açık olmalı) ya da yine de filtrelemeyi başlatın.';

  @override
  String get wsetupFailedTitle => 'Kurulum tamamlanmadı';

  @override
  String get wsetupPairing => 'Eşleniyor…';

  @override
  String get wsetupConnecting => 'Bağlanılıyor ve izinler veriliyor…';

  @override
  String get wsetupNeedWifi =>
      'Önce bir Wi-Fi ağına bağlanın (internet gerekmez): Kablosuz hata ayıklama yalnızca Wi-Fi\'da çalışır.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Geliştirici seçeneklerinde “Kablosuz hata ayıklama”yı açın, sonra adına ve “Eşleme kodu ile cihaz eşle”ye dokunun.';

  @override
  String get wsetupOpenDialog =>
      'Kablosuz hata ayıklama ekranında “Eşleme kodu ile cihaz eşle”ye dokunun. Kodu ekranda tutun ve burada “Kodu gir”e dokunun.';

  @override
  String get wsetupEnterCodeBody =>
      '“Kodu gir”e dokunun ve Ayarlarda gösterilen 6 haneli kodu yazın.';

  @override
  String get wsetupCodeWaiting =>
      'Kod alındı. “Eşleme kodu ile cihaz eşle” ekranı bekleniyor: açık tutun.';

  @override
  String get wsetupWrongCode =>
      'Bu kod kabul edilmedi. Ekrandaki 6 haneyi kontrol edip yeniden girin. Eşleme ekranı kapandıysa yeniden açın: kod değişir.';

  @override
  String get wsetupPairingFailed =>
      'Eşleme olmadı. Eşleme ekranını kapatın, “Eşleme kodu ile cihaz eşle”yi yeniden açın ve yeni kodu girin.';

  @override
  String get wsetupWaitingConnect =>
      'Eşlendi. “Kablosuz hata ayıklama”yı açık tutun: Waaiya bağlanıyor.';

  @override
  String get wsetupNotPaired =>
      'Bu telefon artık Waaiya\'yı tanımıyor (eşleme kaldırıldı veya süresi doldu). “Eşleme kodu ile cihaz eşle”yi açın ve kodu girin.';

  @override
  String get wsetupConnectFailed =>
      'Kablosuz hata ayıklamaya bağlanılamadı. Kapatıp yeniden açın: Waaiya kendiliğinden yeniden dener.';

  @override
  String get wsetupGrantFailed =>
      'Bağlandı, ama izinler hâlâ eksik. Aşağıdan Shizuku\'yu veya bilgisayarı kullanın.';

  @override
  String get wsetupTimeout =>
      '10 dakika içinde tamamlanamadığı için durduruldu. Yeniden deneyebilirsiniz.';

  @override
  String get wsetupCodeUnreadable => 'Eşleme kodunun 6 hanesini yazın.';

  @override
  String get wsetupCodeHint => '6 haneli kod';

  @override
  String get wsetupEnterCode => 'Kodu gir';

  @override
  String wsetupDetail(String details) {
    return 'Ayrıntılar: $details';
  }

  @override
  String get wsetupErrTimeout => 'zamanında yanıt gelmedi';

  @override
  String get wsetupErrRefused => 'bağlantı reddedildi';

  @override
  String get wsetupDevOff =>
      'Geliştirici seçenekleri kapalı. Telefon hakkında bölümünde “Derleme numarası”na 7 kez dokunun, sonra geri dönün.';

  @override
  String get wsetupOpenAbout => 'Telefon hakkında';

  @override
  String get wsetupNotifOff =>
      'Waaiya için bildirimler kapalı, bu yüzden kod bir bildirime yazılamaz. Bölünmüş ekranı kullanın (bir yarıda Ayarlar, diğerinde Waaiya) ve “Kodu buraya yazın”a dokunun.';

  @override
  String get wsetupCodeDialogTitle => 'Eşleme kodu';

  @override
  String get wsetupCodeDialogBody =>
      'Yalnızca bölünmüş ekranla (bir yarıda Ayarlar, diğerinde Waaiya): Ayarlardan çıkmak eşleme ekranını kapatır ve kodu artık çalışmaz. “Eşleme kodu ile cihaz eşle” altında gösterilen 6 haneli kodu yazın.';

  @override
  String get wsetupCodeOk => 'Eşle';

  @override
  String get blurStrictTitle => 'Kimler örtülmez';

  @override
  String blurStrictValue(String level) {
    return 'Kimler örtülmez: $level';
  }

  @override
  String get blurStrict0 =>
      'Sıkı: yalnızca uygulamanın neredeyse kesin erkek dediği kişiler';

  @override
  String get blurStrict1 =>
      'Dengeli: yaklaşık iki kat daha fazla erkek örtülmez';

  @override
  String get blurStrict2 => 'Rahat: dengeliden birkaç erkek daha fazla';

  @override
  String get blurStrict0Short => 'sıkı';

  @override
  String get blurStrict1Short => 'dengeli';

  @override
  String get blurStrict2Short => 'rahat';

  @override
  String get blurStrictHelp =>
      'Uygulamanın erkek olduğundan emin olmadığı herkes örtülür. Sıkı ayar 100 erkekten yaklaşık 7\'sini örtmeden bırakır; dengeli yaklaşık 14\'ünü, rahat yaklaşık 16\'sını. Daha gevşek her adım, 100 kadından yaklaşık 1 kadını daha örtmeden bırakır.';

  @override
  String get stateOnNotMuted =>
      'Orijinal ses henüz susturulmadı, bu yüzden müziği filtrelenmiş sesle birlikte duyarsınız. Aşağıdaki tek seferlik kurulumu tamamlayın.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya şu anda çalan uygulamanın orijinal sesini susturamıyor, bu yüzden müzik hâlâ duyulabilir. Filtrelemeyi durdurup başlatın. Sorun sürerse tanılama raporunu gönderin (bu ekranın en altında).';

  @override
  String get stateTooSlow =>
      'Bu telefon canlı sesi filtrelemek için çok yavaş, bu yüzden ses kesiliyor. Aşağıdaki “Bağlantı aç” yine çalışır: videoyu oynatmadan önce filtreler.';

  @override
  String get stateMonoNote => 'Bu telefon yetişebilsin diye ses mono.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Filtrelemeye izin vermediği için susturuldu: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Filtrelemeye izin vermediği için filtresiz çalıyor: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android, diğer uygulamaların sesini Waaiya\'ya vermedi. Yeniden başlatmak için düğmeye dokunun.';

  @override
  String get stateCaptureCancelled =>
      'Başlatma, Android\'in ekran paylaşımı sorusunda iptal edildi. Waaiya\'nın sesi alabilmesi için orada “Başlat” seçilmelidir. Hiçbir şey kaydedilmez veya gönderilmez.';

  @override
  String get startNoSetupTitle => 'Müzik yine duyulacak';

  @override
  String get startNoSetupBody =>
      'Tek seferlik kurulum henüz yapılmadı. Kurulum olmadan Waaiya orijinal sesi susturamaz: müziği ve filtrelenmiş sesi birlikte duyarsınız.\n\n“Bağlantı aç” hiçbir kurulum olmadan çalışır.';

  @override
  String get startNoSetupSetup => 'Kurulumu yap';

  @override
  String get startNoSetupAnyway => 'Yine de başlat';

  @override
  String get diagButton => 'Sorun mu var? Tanılama raporu';

  @override
  String get diagTitle => 'Tanılama raporu';

  @override
  String get diagNote =>
      'Waaiya\'nın bu telefonda gördükleri. Kopyalayın veya size yardım eden kişiyle paylaşın. Uygulamanın kendisi hiçbir şey göndermez.';

  @override
  String get notifStoppedTitle => 'Waaiya durdu';

  @override
  String get notifStoppedText =>
      'Ses artık filtrelenmiyor. Yeniden başlatmak için dokunun.';

  @override
  String get wsetupGuide => 'Resimli adımlar';

  @override
  String get navFilter => 'Filtre';

  @override
  String get navScreen => 'Ekran';

  @override
  String get navLinks => 'Bağlantılar';

  @override
  String get navSetup => 'Kurulum';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get setupDoneTitle => 'Kurulum tamamlandı';

  @override
  String get setupDoneBody =>
      'Waaiya diğer uygulamaların orijinal sesini susturabilir. Yalnızca bir şey değiştiyse yeniden yapın (kurulum geri alındıysa veya Waaiya eksik olduğunu söylüyorsa).';

  @override
  String get setupRedo => 'Kurulumu yeniden göster';

  @override
  String get setupGo => 'Kuruluma git';

  @override
  String get helperTitle => 'Örtülerden geçen dokunuşlar';

  @override
  String get helperBodyOff =>
      'Yardım olmadan bir örtü, altındaki dokunuşları engeller. Waaiya yardımcısı örtüleri dokunuşlar içinden geçecek şekilde çizer. Kablosuz hata ayıklamayı açın (Wi-Fi gerekir) ve düğmeye dokunun; ilk seferde kurulumdaki gibi bir kez eşleyin. Telefon yeniden başladıktan sonra düğmeye yeniden dokunun.';

  @override
  String get helperStart => 'Waaiya yardımcısını başlat';

  @override
  String get helperOn =>
      'Waaiya yardımcısı örtüleri çiziyor: dokunuşlar içlerinden geçer. Telefon yeniden başladığında veya USB hata ayıklaması kapatıldığında durur; o zaman düğmeye yeniden dokunun.';

  @override
  String get helperShizukuOn =>
      'Örtüleri Shizuku çiziyor: dokunuşlar içlerinden geçer.';

  @override
  String get helperOrShizuku => 'Ya da Shizuku ile:';

  @override
  String get filterOptionsTitle => 'Filtre seçenekleri';

  @override
  String get settingsGeneralTitle => 'Genel';

  @override
  String get worshipPrayerFajr => 'İmsak';

  @override
  String get worshipPrayerSunrise => 'Güneş';

  @override
  String get worshipPrayerDhuhr => 'Öğle';

  @override
  String get worshipPrayerAsr => 'İkindi';

  @override
  String get worshipPrayerMaghrib => 'Akşam';

  @override
  String get worshipPrayerIsha => 'Yatsı';

  @override
  String get worshipEndSilent => 'Sessizliği şimdi bitir';

  @override
  String get worshipUnmute => 'Sesi şimdi aç';

  @override
  String get worshipSmsDefault =>
      'Namaz vakti, şu an cevap veremiyorum. Sizi geri arayacağım.';

  @override
  String get desktopPreview =>
      'Önizleme: filtre motoru bu bilgisayara henüz bağlı değil. Düğme yalnızca uygulamanın nasıl çalışacağını gösterir.';

  @override
  String actionFailed(String details) {
    return 'Bu işe yaramadı: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Tüm uygulamalardan müzik aletleri kaldırılıyor.';

  @override
  String get engineErrorNoPactl =>
      'Ses araçları bulunamadı (pactl). Waaiya için PulseAudio ya da pipewire-pulse ile PipeWire gerekir.';

  @override
  String get engineErrorNoSoundServer =>
      'Ses sunucusu çalışmıyor (PulseAudio veya PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Bu sistemde, filtreyi arka planda çalıştıran systemd kullanıcı oturumu yok.';

  @override
  String get engineErrorNoOutput => 'Hoparlör veya kulaklık bulunamadı.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Filtre kurulamadı. Ayrıntılar:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Filtre başlamadı. Ayrıntılar:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Filtre bir hatayla durdu. Ayrıntılar:\n$details';
  }

  @override
  String get autostartTitle => 'Oturum açılınca başlat';

  @override
  String get autostartBody => 'Oturum açar açmaz sesi filtrele.';

  @override
  String get blurBodyDesktop =>
      'Waaiya açıkken her pencerenin üzerinde ekrandaki insanları ve görüntüleri örter (ses filtresi açık da olsa kapalı da olsa çalışır). Bu bilgisayarda çalışır; hiçbir yere bir şey gönderilmez. Waaiya penceresini kapatmak bulanıklaştırmayı durdurur.';

  @override
  String get blurFailBodyDesktop =>
      'Açık: bilgisayar çok yavaş kaldığında veya bulanıklaştırma başarısız olduğunda tüm ekran örtülür; tıklamalar alttaki pencerelere yine ulaşır. Kapalı: ekran, üstte kırmızı bir çubukla görünür kalır.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Bulanıklaştırma açık. Bu masaüstü bulanıklığı kendi ekran yakalamasında gösteriyor, bu yüzden bulanık bir alan sahne değişene kadar bulanık kalır.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Bulanıklaştırma bu masaüstünde diğer pencerelerin üzerine çizemiyor. Ayrıntılar:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Ekran paylaşımı penceresinde ekranınızı seçin ve izin verin. Waaiya yalnızca bir kez sorar; görüntü bu bilgisayarda kalır.';

  @override
  String blurStatusExited(String details) {
    return 'Bulanıklaştırma beklenmedik şekilde durdu. Yeniden denemek için bir bulanıklaştırma seçeneğini kapatıp açın. Ayrıntılar:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Kadınların şarkı sesi algılayıcısı yüklenemedi, bu yüzden o seçenek açıkken sesler susturulur.';

  @override
  String get blurStatusUncovered =>
      'Bir ekran bulanıklaştırma tarafından örtülmüyor: onunla paylaşılmadı ya da sonradan takıldı. Bir bulanıklaştırma seçeneğini kapatıp açın ve ekran paylaşımı penceresinde her ekranı seçin.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Bulanıklaştırma modelleri bu kurulumda eksik, bu yüzden hiçbir şeyi örtemiyor; ekranın üstünde kırmızı bir çubuk kalır. Waaiya\'yı yeniden kurun.';

  @override
  String get diagNoteDesktop =>
      'Waaiya\'nın bu bilgisayarda gördükleri. Kopyalayın ve size yardım eden kişiye verin. Uygulamanın kendisi hiçbir şey göndermez.';

  @override
  String get worshipTitle => 'Namaz vakitleri';

  @override
  String get worshipBody =>
      'İsteğe bağlı. Seçtiğiniz yere göre bu telefonda hesaplanır. Hiçbir şey gönderilmez.';

  @override
  String worshipPlace(Object place) {
    return 'Yer: $place';
  }

  @override
  String get worshipPlaceNone => 'Yer: seçilmedi';

  @override
  String get worshipChoose => 'Seç';

  @override
  String get worshipPlaceSearch => 'Şehir ara';

  @override
  String get worshipPlaceNoMatch =>
      'Şehir bulunamadı. Bunun yerine koordinat girebilirsiniz.';

  @override
  String get worshipPlaceCustom => 'Koordinat gir';

  @override
  String get worshipLat => 'Enlem (kuzey +, güney −)';

  @override
  String get worshipLon => 'Boylam (doğu +, batı −)';

  @override
  String get worshipZone => 'Saat dilimi, örneğin Europe/Istanbul';

  @override
  String get worshipCustomInvalid => 'Sayıları ve saat dilimini kontrol edin.';

  @override
  String get worshipPlaceInvalid => 'Bu yer kullanılamıyor. Yeniden seçin.';

  @override
  String worshipMethod(Object method) {
    return 'Hesaplama: $method';
  }

  @override
  String get worshipMethodTitle => 'Hesaplama yöntemi';

  @override
  String get worshipMethodNote =>
      'Şehrin ülkesine göre seçildi. Camiinizin uyduğu yöntemi seçin.';

  @override
  String worshipAsr(Object rule) {
    return 'İkindi: $rule';
  }

  @override
  String get worshipAsrTitle => 'İkindi vakti';

  @override
  String get worshipAsrStandard => 'Standart (Şâfiî, Mâlikî, Hanbelî)';

  @override
  String get worshipAsrHanafi => 'Hanefî';

  @override
  String get worshipMethodMwl => 'Dünya İslam Birliği';

  @override
  String get worshipMethodIsna => 'Kuzey Amerika İslam Cemiyeti (ISNA)';

  @override
  String get worshipMethodEgypt => 'Mısır Genel Harita Kurumu';

  @override
  String get worshipMethodUmmAlQura => 'Ümmü\'l-Kurâ, Mekke';

  @override
  String get worshipMethodKarachi => 'İslami İlimler Üniversitesi, Karaçi';

  @override
  String get worshipMethodTehran => 'Jeofizik Enstitüsü, Tahran Üniversitesi';

  @override
  String get worshipMethodGulf => 'Körfez bölgesi';

  @override
  String get worshipMethodKuwait => 'Kuveyt';

  @override
  String get worshipMethodQatar => 'Katar';

  @override
  String get worshipMethodSingapore => 'Singapur (MUIS)';

  @override
  String get worshipMethodTurkey => 'Türkiye (Diyanet)';

  @override
  String get worshipMethodFrance => 'Fransa (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Fas (Vakıflar Bakanlığı)';

  @override
  String get worshipMethodIndonesia => 'Endonezya (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malezya (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Bugün';

  @override
  String get worshipNoTimes =>
      'Bugün burada namaz vakti yok: güneş doğmuyor ya da batmıyor.';

  @override
  String get worshipSilentTitle => 'Namaz vakitlerinde sessiz';

  @override
  String get worshipSilentBody =>
      'Her namaz vaktinden itibaren aşağıdaki süre boyunca Rahatsız Etmeyin açılır, sonra eski haline döner.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Sessiz süre: $minutes dk';
  }

  @override
  String get worshipMuteTitle => 'Ezanda medyayı sessize al';

  @override
  String get worshipMuteBody =>
      'Her namaz vaktinde medya sesi (video, ses, oyun) aşağıdaki süre boyunca kapatılır. Bildirimden hemen açabilirsiniz.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Sessiz süre: $minutes dk';
  }

  @override
  String get worshipMinutesTitle => 'Süre';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes dk';
  }

  @override
  String get worshipNeedPlace => 'Önce bir yer seçin.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Sıradaki: $prayer, saat $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return '$time saatine kadar sessiz.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Medya $time saatine kadar sessiz.';
  }

  @override
  String get worshipDndNeeded =>
      'Waaiya\'nın Rahatsız Etmeyin\'i değiştirmesine izin verin, yoksa telefon sessize alınamaz.';

  @override
  String get worshipAllow => 'İzin ver';

  @override
  String get worshipExactNeeded =>
      'Waaiya için Alarmlar ve hatırlatıcılar izni yok; her değişiklik 10 dakikaya kadar, telefon uykudayken daha da geç gelebilir.';

  @override
  String get worshipNotificationsNeeded =>
      'Bildirimler kapalı: telefonun ne zaman sessize alındığını ya da geri döndüğünü görmeyeceksiniz.';

  @override
  String get worshipTonesTitle => 'Sade zil sesi ve bildirim sesi';

  @override
  String get worshipTonesBody =>
      'Waaiya zil sesini ve bildirim seslerini süzemez, yalnızca değiştirebilir. Müziksiz sade bir ses seçin:';

  @override
  String worshipToneRing(Object number) {
    return 'Sade zil sesi $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Sade bildirim sesi $number';
  }

  @override
  String get worshipTonePlay => 'Dinle';

  @override
  String get worshipToneSet => 'Kullan';

  @override
  String get worshipToneInUse => 'Kullanılıyor';

  @override
  String get worshipToneDone => 'Tamam.';

  @override
  String get worshipTonePermission =>
      'Waaiya\'nın sistem ayarlarını değiştirmesine izin verin, geri dönün ve yeniden dokunun.';

  @override
  String get worshipToneFailed =>
      'Bu telefon Waaiya\'nın değiştirmesine izin vermedi. Ses ayarlarında “Waaiya plain” adlı bir ses seçin.';

  @override
  String get worshipOpenSound => 'Ses ayarlarını aç';

  @override
  String get worshipSmsTitle => 'Namaz sırasında aramalara SMS ile yanıt ver';

  @override
  String get worshipSmsBody =>
      'Her namaz vaktinden sonraki sessiz dakikalarda, yanıtlanmadan çalan aramaya bir SMS gider. Her numaraya her namazda bir kez; gizli numaralara ve kısa numaralara asla.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Şu kadar çaldıktan sonra: $seconds sn';
  }

  @override
  String get worshipSmsDelayTitle => 'SMS\'ten önce çalma süresi (sn)';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds sn';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Mesaj: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Mesajınız';

  @override
  String get worshipSmsTextDefault => 'Varsayılanı kullan';

  @override
  String get worshipSmsCost =>
      'Her yanıt, SIM kartınızdan tarifenizin fiyatıyla gönderilen normal bir SMS\'tir. Dolaşımdayken hiçbir şey gönderilmez.';

  @override
  String get worshipSmsRoaming => 'Şu an dolaşımdasınız: SMS gönderilmez.';

  @override
  String get worshipSmsLogTitle =>
      'Gönderilen yanıtlar (yalnızca bu telefonda tutulur)';

  @override
  String get worshipContinue => 'Devam';

  @override
  String get worshipWhyDnd =>
      'Telefonu namaz vakitlerinde sessize almak için sonraki sayfada Waaiya\'ya Rahatsız Etmeyin erişimi verin.';

  @override
  String get worshipWhyExact =>
      'Tam zamanında çalışması için sonraki sayfada Waaiya\'nın alarm ve hatırlatıcı kurmasına izin verin. İzin olmadan değişiklikler 10 dakikaya kadar gecikebilir.';

  @override
  String get worshipWhyNotifications =>
      'Her değişikliği görmek ve geri alabilmek için bildirimlere izin verin.';

  @override
  String get worshipWhyWrite =>
      'Zil sesinizi veya bildirim sesinizi değiştirmek için sonraki sayfada Waaiya\'nın sistem ayarlarını değiştirmesine izin verin.';

  @override
  String get worshipWhyPhone =>
      'Bir aramanın çaldığını ve numarasını bilmek için Waaiya\'nın Telefon ve Arama kayıtları izinlerine ihtiyacı var. Yanıtınız dışında hiçbir şey telefondan çıkmaz.';

  @override
  String get worshipWhySms =>
      'Yanıtınızı göndermek için Waaiya\'nın SMS gönderme iznine ihtiyacı var. Yalnızca bu yanıtı, her numaraya her namazda en fazla bir kez gönderir.';

  @override
  String get worshipMissingDnd =>
      'Rahatsız Etmeyin erişimine izin verilmedi, bu yüzden sessizlik kapalı kalıyor.';

  @override
  String get worshipMissingPhone =>
      'Telefon ve Arama kayıtları izinleri verilmedi, bu yüzden SMS yanıtı kapalı kalıyor.';

  @override
  String get worshipMissingSms =>
      'SMS gönderme izni verilmedi, bu yüzden SMS yanıtı kapalı kalıyor.';

  @override
  String get worshipTryAgain => 'Yeniden dene';
}
