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
      'Uygulamalarınızın sesinden müzik aletlerini kaldırır; konuşmayı ve tilaveti korur.';

  @override
  String get onboardTitle => 'Hoş geldiniz';

  @override
  String get onboardBody =>
      'Waaiya, bu telefondaki uygulamaların sesinden müzik aletlerini kaldırır. Konuşma ve Kuran tilaveti korunur. Şarkı söyleyen sesler de kaldırılır.';

  @override
  String get onboardQuestion => 'Cinsiyetiniz';

  @override
  String get genderMan => 'Erkek';

  @override
  String get genderWoman => 'Kadın';

  @override
  String get onboardWhy =>
      'Bu yalnızca hangi isteğe bağlı ayarları göreceğinizi belirler. Örneğin “Kadınların şarkı sesini sustur” yalnızca erkeklere sunulur. Daha sonra değiştirebilirsiniz.';

  @override
  String get stateOnTitle => 'Filtreleme açık';

  @override
  String get stateOffTitle => 'Filtreleme kapalı';

  @override
  String get stateStarting => 'Başlatılıyor…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Uygulamalarınızın sesi filtreleniyor. Ses yaklaşık $delayMs ms geç gelir (1000 ms bir saniyedir).';
  }

  @override
  String get stateOffDetail => 'Başlatmak için düğmeye basın.';

  @override
  String get stateModelFailed =>
      'Filtre yüklenemedi, bu yüzden ses filtresiz çalmak yerine kapatıldı.';

  @override
  String get stateCaptureDenied =>
      'Diğer uygulamaların sesini almak için mikrofon izni gerekiyor.';

  @override
  String get stateStoppedBySystem =>
      'Android filtrelemeyi durdurdu. Yeniden başlatmak için düğmeye basın.';

  @override
  String get stateSilencedTitle => 'Filtreleme durdu';

  @override
  String get stateSilenced =>
      'Filtreleme durdu: diğer uygulamalar susturuldu. Yeniden başlatmak için düğmeye basın ya da onları filtresiz duymak için Durdur\'a basın.';

  @override
  String get releaseSilence => 'Durdur: uygulamaları filtresiz duy';

  @override
  String get powerStartCd => 'Filtrelemeyi başlat';

  @override
  String get powerStopCd => 'Filtrelemeyi durdur';

  @override
  String get captureHint =>
      'Android, ekranınızı paylaşmak için izin isteyecek. Hiçbir şey kaydedilmez veya gönderilmez.';

  @override
  String get needRecordAudio =>
      'Waaiya\'nın diğer uygulamaların sesini alabilmesi için mikrofon izni gerekir. Sizi asla kaydetmez.';

  @override
  String get setupBannerTitle => 'Bir adım daha';

  @override
  String get setupBannerBody =>
      'Tek seferlik kurulum yapılmazsa müziği ve filtrelenmiş sesi birlikte duyarsınız.';

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
  String get computerWeb =>
      'En kolayı: bir bilgisayarda Chrome veya Edge ile waaiya.mssid.org/usb adresini açın, USB hata ayıklamasını açın ve telefonu kabloyla bağlayın. Hiçbir şey kurmanız gerekmez, Android 10\'da da çalışır. Ya da adb kuruluysa:';

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
  String get settingSingingBody =>
      'Örneğin bir kadının söylediği şarkı susturulur, ama konuşma yapan bir kadın yine duyulur.';

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
  String get playerTitle => 'Sesi ve görüntüsü eşzamanlı videolar';

  @override
  String get playerBody =>
      'Bir videoyu filtrelenmiş, sesi ve görüntüsü eşzamanlı olarak ve canlı filtrenin gecikmesi olmadan izlemek için Waaiya ile paylaşın (veya “Şununla aç”ı kullanın).';

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
      'Filtreleme açıkken ekrandaki insanları ve görüntüleri örter. Telefonda çalışır; hiçbir yere bir şey gönderilmez.';

  @override
  String get blurOnTitle => 'Bulanıklaştırma açık';

  @override
  String get blurOffTitle => 'Bulanıklaştırma kapalı';

  @override
  String get blurStartCd => 'Bulanıklaştırmayı başlat';

  @override
  String get blurStopCd => 'Bulanıklaştırmayı durdur';

  @override
  String get blurOffDetail =>
      'Başlatmak için düğmeye basın. Filtreleme de onunla başlar.';

  @override
  String get blurWhatTitle => 'Neyin bulanıklaştırılacağı';

  @override
  String get blurWomenTitle => 'Kadın görüntülerini bulanıklaştır';

  @override
  String get blurWomenBody =>
      'Tüm vücudu örter. Uygulama bir kişinin erkek olduğundan emin değilse, onu da örter.';

  @override
  String get blurNudityTitle => 'Uygunsuz görüntüleri bulanıklaştır';

  @override
  String get blurNudityBody =>
      'Kim olursa olsun çıplaklık veya açık giyim: tüm ekran örtülür.';

  @override
  String get blurFailTitle => 'Bulanıklaştırma yetişemezse ekranı ört';

  @override
  String get blurFailBody =>
      'Açık: telefon çok yavaş kaldığında veya bulanıklaştırma başarısız olduğunda tüm ekran örtülür. Kapalı: ekran bir uyarıyla görünür kalır.';

  @override
  String get blurSetupManual => 'Android ayarlarında izin ver';

  @override
  String get blurStatusNeedsSetup =>
      'Bulanıklaştırmak için Waaiya\'nın diğer uygulamaların üzerine çizmesi gerekir. En iyisi: “Kuruluma git”; böylece dokunuşlarınız bulanıklığın altındaki uygulamaya yine ulaşır. Ya da “Android ayarlarında izin ver”; ama o zaman bulanık bir alana dokunmak hiçbir şey yapmaz.';

  @override
  String get blurStatusNeedsOverlay =>
      'Bulanıklaştırmak için Waaiya\'nın diğer uygulamaların üzerine çizmesi gerekir. En iyisi: tek seferlik kurulumu yapın; böylece dokunuşlarınız bulanıklığın altındaki uygulamaya yine ulaşır. Ya da Android ayarlarında “Diğer uygulamaların üzerinde göster” iznini verin; ama o zaman bulanık bir alana dokunmak hiçbir şey yapmaz.';

  @override
  String get blurFailUnavailable =>
      'Şimdilik kullanılamıyor: tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz. Waaiya yardımcısını (Android 12 veya daha yeni) başlatın, seçenek kullanılabilir olur: örtüler o zaman dokunuşlar içinden geçecek şekilde çizilir. O zamana kadar, bulanıklaştırma yetişemediğinde ekran bir uyarıyla görünür kalır.';

  @override
  String get blurFailNeedsA11y =>
      'Şimdilik kullanılamıyor: tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz. Waaiya yardımcısını başlatın (Android 12 veya daha yeni) ya da Android ayarlarında Waaiya Bulanıklaştırma erişilebilirlik hizmetini açın, seçenek kullanılabilir olur. O zamana kadar ekran bir uyarıyla görünür kalır.';

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
  String get step2Guide => 'Shizuku nasıl başlatılır';

  @override
  String get blurFailOldAndroid =>
      'Kullanılamıyor: bu Android sürümünde tam ekran bir örtü her dokunuşu engeller ve takılıp kalabilirsiniz (dokunuşların içinden geçtiği örtüler Android 12 veya daha yenisini gerektirir). Bulanıklaştırma yetişemediğinde ekran bir uyarıyla görünür kalır.';

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
  String get blurStrictTitle => 'Bir erkeği göstermek için gereken kesinlik';

  @override
  String blurStrictValue(String level) {
    return 'Bir erkeği göstermek için gereken kesinlik: $level';
  }

  @override
  String get blurStrict0 =>
      'Sıkı: yalnızca uygulamanın neredeyse kesin erkek dediği kişiler';

  @override
  String get blurStrict1 =>
      'Dengeli: yaklaşık iki kat daha fazla erkek gösterilir';

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
      'Bir kişi yalnızca uygulama onun erkek olduğundan emin olduğunda gösterilir; diğer herkes bulanıklaştırılır. Sıkı ayar 100 erkekten yaklaşık 7\'sini gösterir, dengeli yaklaşık 14\'ünü, rahat yaklaşık 16\'sını. Bazı kadınlar yine de gözden kaçar; daha gevşek her adım 100\'de yaklaşık 1 tane daha kaçırır.';

  @override
  String get stateOnNotMuted =>
      'Orijinal ses henüz susturulmadı, bu yüzden müziği filtrelenmiş sesle birlikte duyarsınız. “Kurulum” sayfasındaki tek seferlik kurulumu tamamlayın.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya şu anda çalan uygulamanın orijinal sesini susturamıyor, bu yüzden müzik hâlâ duyulabilir. Filtrelemeyi durdurup başlatın. Sorun sürerse tanılama raporunu gönderin (Ayarlar).';

  @override
  String get stateTooSlow =>
      'Bu telefon canlı sesi filtrelemek için çok yavaş, bu yüzden ses kesiliyor. “Bağlantılar” sayfasındaki “Bağlantı aç” yine çalışır: videoyu oynatmadan önce filtreler.';

  @override
  String get stateMonoNote => 'Bu telefon yetişebilsin diye ses mono.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Susturuldu, çünkü şunlar filtrelemeye izin vermiyor: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Filtresiz çalıyor, çünkü şunlar filtrelemeye izin vermiyor: $apps.';
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
      'Waaiya\'nın bu telefonda gördükleri. Kopyalayın veya size yardım eden kişiyle paylaşın. Waaiya bunu kendiliğinden göndermez: kimin alacağını siz seçersiniz.';

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
  String get helperTitle => 'Bulanık alanlardan geçen dokunuşlar';

  @override
  String get helperBodyOff =>
      'Yardım olmadan bir örtü, altındaki dokunuşları engeller. Waaiya yardımcısı örtüleri dokunuşlar içinden geçecek şekilde çizer. Kablosuz hata ayıklamayı açın (Wi-Fi gerekir) ve düğmeye dokunun; ilk seferde kurulumdaki gibi bir kez eşleyin. Telefon yeniden başladıktan sonra düğmeye yeniden dokunun.';

  @override
  String get helperStart => 'Waaiya yardımcısını başlat';

  @override
  String get helperOn =>
      'Waaiya yardımcısı bulanıklığı çiziyor: dokunuşlar içinden geçer. Telefon yeniden başladığında veya “USB hata ayıklaması” (Geliştirici seçeneklerinde ayrı bir anahtar) kapatıldığında durur; o zaman düğmeye yeniden dokunun.';

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
  String get simpleTitle =>
      'Basit mod (deneme): Geliştirici seçenekleri olmadan';

  @override
  String get simpleBody =>
      'Aşağıdaki kurulumun çok zor olduğu telefonlar için. Waaiya filtrelerken telefonun medya sesini kapatır ve filtrelenmiş sesi başka bir ses kanalında çalar. Ses düğmeleriniz Waaiya\'nın ses düzeyini ayarlar. Android her başlatmada ekranı paylaşmak için sorar. Filtreleme durduğunda medya sesi geri gelir.';

  @override
  String get simpleSwitch => 'Basit modu kullan';

  @override
  String simpleChannelTitle(String channel) {
    return 'Ses kanalı: $channel';
  }

  @override
  String get simpleChannelAlarm => 'Alarm';

  @override
  String get simpleChannelNotification => 'Bildirim';

  @override
  String get simpleChannelHelp =>
      'Hiçbir şey duymazsanız ya da kulaklık takılıyken ses telefonun hoparlöründen gelirse diğer kanalı deneyin. Telefon titreşimdeyken veya Rahatsız Etmeyin açıkken Bildirim sessizdir.';

  @override
  String get simpleTestNote =>
      'Bu bir denemedir. Denedikten sonra (hoparlör, kulaklık, Bluetooth) lütfen Ayarlar\'dan tanılama raporunu gönderin.';

  @override
  String get simpleOnDetail =>
      'Basit mod (deneme): Waaiya filtrelerken medya sesi kapalıdır.';

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
  String get updateTitle => 'Uygulama güncellemeleri';

  @override
  String get updateAuto => 'Yeni sürümü günde bir kez denetle';

  @override
  String get updateAutoBody =>
      'Waaiya, waaiya.mssid.org\'a daha yeni bir sürüm olup olmadığını sorar ve başka hiçbir şey göndermez. Şimdi güncelle\'ye dokunana kadar hiçbir şey indirilmez.';

  @override
  String get updateCheck => 'Şimdi denetle';

  @override
  String get updateChecking => 'Denetleniyor…';

  @override
  String updateNone(String version) {
    return 'En son sürüme sahipsiniz ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest yayımlandı. Sizdeki sürüm $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'İndirme: $size, yalnızca değişenler (uygulamanın tamamı $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'İndirme: $size.';
  }

  @override
  String get updateNow => 'Şimdi güncelle';

  @override
  String updateDownloading(String progress) {
    return 'İndiriliyor: $progress';
  }

  @override
  String get updatePreparing => 'Güncelleme hazırlanıyor…';

  @override
  String get updateInstalling =>
      'Kurulumu Android\'in gösterdiği ekranda onaylayın.';

  @override
  String get updateStopsFilter =>
      'Kurulum filtrelemeyi durdurur. Güncellemeden sonra yeniden başlatın.';

  @override
  String get updatePermission =>
      'Waaiya\'nın güncellemelerini kurmasına izin verin, sonra yeniden Şimdi güncelle\'ye dokunun.';

  @override
  String get updateFailed =>
      'Güncelleme tamamlanamadı. Daha sonra yeniden deneyin ya da web sitesinden indirin.';

  @override
  String get updateOpenPage => 'İndirme sayfasını aç';

  @override
  String get updateCheckFailed =>
      'Şu anda denetlenemedi. Daha sonra yeniden deneyin.';

  @override
  String get moveOldTitle => 'Waaiya taşındı';

  @override
  String get moveOldBody =>
      'Waaiya artık Android\'de yeni bir uygulama olarak geliyor (aynı Waaiya, yeni bir adla) ve bu uygulama artık güncelleme almayacak. Yenisini kurun: ayarlarınız da taşınır. Sonra onun tek seferlik kurulumunu yapın ve bunu kaldırın.';

  @override
  String get moveOldInstalled =>
      'Yeni Waaiya kuruldu. Açın: ayarlarınızı alır. Tek seferlik kurulumunu yapın, sonra ikisi asla aynı anda filtrelemesin diye bu eskisini kaldırın.';

  @override
  String get moveInstall => 'Yeni Waaiya\'yı kur';

  @override
  String get moveOpenNew => 'Yeni Waaiya\'yı aç';

  @override
  String get moveRemoveThis => 'Bu eski Waaiya\'yı kaldır';

  @override
  String get moveNewTitle => 'Eski Waaiya hâlâ yüklü';

  @override
  String get moveNewBody =>
      'Eski Waaiya (0.2.15 sürümünden önceki) hâlâ bu telefonda. İkisi asla aynı anda filtrelemesin diye kaldırın.';

  @override
  String get moveNewImported => 'Ayarlarınız ondan alındı.';

  @override
  String get moveRemoveOld => 'Eski Waaiya\'yı kaldır';

  @override
  String get desktopPreview =>
      'Önizleme: filtre motoru bu bilgisayara henüz bağlı değil. Düğme yalnızca uygulamanın nasıl çalışacağını gösterir.';

  @override
  String actionFailed(String details) {
    return 'Bu işe yaramadı: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Uygulamalarınızın sesi filtreleniyor.';

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
      'Waaiya\'nın bu bilgisayarda gördükleri. Kopyalayın ve size yardım eden kişiye verin. Waaiya bunu kendiliğinden göndermez: kimin alacağını siz seçersiniz.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Önerilir. Filtreleme kendiliğinden durursa (sizin yüzünüzden değil, bir hata nedeniyle), diğer uygulamalar müziği filtresiz çalmak yerine siz yeniden başlatana veya Durdur\'a basana kadar sessiz kalır.';

  @override
  String get settingStereoBodyDesktop =>
      'Kapalı: mono, bilgisayarı daha az yorar. Açık: sol ve sağ tarafları ayrı tutar. Bilgisayar stereo için fazla yavaşsa kendiliğinden monoya geçer.';

  @override
  String get linkEntryBodyDesktop =>
      'Filtre açıkken izlemek ya da müziksiz kaydetmek için bir YouTube, TikTok veya Instagram bağlantısı yapıştırın.';

  @override
  String get linkEntryBodyWatch =>
      'Tarayıcınızda filtre açıkken izlemek için bir YouTube, TikTok veya Instagram bağlantısı yapıştırın.';

  @override
  String get linkWatchNoteDesktop =>
      'Tarayıcınızda açılır. Waaiya önce filtreyi başlatır, böylece müzik orada da kaldırılır.';

  @override
  String get linkFilterFailed =>
      'Filtre başlamadı, bu yüzden bağlantı açılmadı. Filtre sayfasından başlatıp tekrar deneyin.';

  @override
  String get linkSavedVideoDesktop => 'Videolar klasörünüzde: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Müzik klasörünüzde: Waaiya';

  @override
  String get linkShowInFolder => 'Klasörde göster';

  @override
  String get linkSingingNote =>
      'Ayarlarınızdaki gibi kadınların şarkı sesi de susturulur.';

  @override
  String get singingKeepTitle => 'Şarkı seslerini koru (deneme)';

  @override
  String get singingKeepBody =>
      'Enstrümanlar kaldırılır ama şarkı sesleri kalır, bu yüzden arkasında neşid olan bir sohbette neşidin sesi de kalır; bunun kabul edilebilir olup olmadığı sizin seçiminizdir.';

  @override
  String get singingKeepNoModel =>
      'Bu sürümde şarkı modeli yok, bu yüzden bu seçenek açıkken ses sessiz kalır. Kapatın.';

  @override
  String get fixFilterAppsTitle => 'Filtresiz duyulan uygulamalar';

  @override
  String get fixFilterAppsBody =>
      'Burada seçtiğiniz uygulamalar olduğu gibi çalar: filtre yok, susturma yok. Örneğin görüntülü arama uygulaması; böylece aramalarda gecikme olmaz.';

  @override
  String get fixAddApp => 'Uygulama ekle';

  @override
  String fixRemoveApp(Object app) {
    return '$app kaldır';
  }

  @override
  String get fixNoApps => 'Seçili uygulama yok.';

  @override
  String get fixPickTitle => 'Bir uygulama seçin';

  @override
  String get fixPickEmpty => 'Başka uygulama bulunamadı.';

  @override
  String get fixPickPlayingDesktop =>
      'Şu anda ses çalan uygulamalar ve önceden seçilenler.';

  @override
  String get fixCancel => 'İptal';

  @override
  String get fixBlurAppsTitle => 'Bulanıklaştırılmayan uygulamalar';

  @override
  String get fixBlurAppsBody =>
      'Bu uygulamalardan biri ekranı kapladığı sürece örtü yok; örneğin bir harita uygulaması ya da bankanızın uygulaması. Ondan çıktığınız anda ya da Waaiya hangi uygulamanın gösterildiğinden emin olmadığında örtüler geri gelir.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Tek seferlik kurulum gerekir: o olmadan Waaiya ekranda hangi uygulamanın olduğunu bilemez, bu yüzden bulanıklık her yerde kalır.';

  @override
  String get fixBlurAppsHelperMode =>
      'Waaiya\'nın yardımcısı çalışmıyor, bu yüzden ekrandaki uygulama okunamıyor. Yardımcı Kurulum sayfasından yeniden başlatılana kadar bulanıklaştırma her yerde açık kalır.';

  @override
  String get fixHandTitle => 'Bir alanı elle örtün';

  @override
  String get fixHandBody =>
      'Bulanıklık çalışırken ekranın bir kısmını kendiniz örtebilirsiniz; örneğin bulanıklığın kaçırdığı bir resmi: “Bir alanı ört” düğmesine dokunun ve parmağınızı onun üzerinde sürükleyin. Siz kaldırana ya da bulanıklık durana kadar örtülü kalır.';

  @override
  String get fixHandNotRunning =>
      'Bulanıklık çalışırken kullanılabilir: filtreleme açık ve bir bulanıklık seçeneği açık.';

  @override
  String get fixCoverArea => 'Bir alanı ört';

  @override
  String fixRemoveCovers(Object count) {
    return 'Elle konan örtüleri kaldır ($count)';
  }

  @override
  String get fixNoteTitle => 'Bir hatayı not edin';

  @override
  String get fixNoteBody =>
      'Waaiya bir şeyi yanlış yaptığında, ne olduğuna dokunun; örneğin “Müzik geçti”. Not, nedeni bulmaya yardım etmek için saati, uygulamayı ve ayarları saklar. Bu cihazda kalır ve asla gönderilmez.';

  @override
  String get fixMissedSound => 'Müzik geçti';

  @override
  String get fixWrongSound => 'Ses yanlışlıkla silindi';

  @override
  String get fixMissedScreen => 'Bir şey örtülmedi';

  @override
  String get fixWrongScreen => 'Yanlışlıkla örtüldü';

  @override
  String fixNoted(Object count) {
    return 'Not edildi. Bu cihazdaki notlar: $count.';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Bu cihazdaki notlar: $count';
  }

  @override
  String get fixNotesShow => 'Notları göster';

  @override
  String get fixNotesDelete => 'Notları sil';

  @override
  String get fixNotesDeleteAsk => 'Tüm notlar silinsin mi? Bu geri alınamaz.';

  @override
  String get fixNotesTitle => 'Hatalarla ilgili notlar';

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
  String get worshipAsrStandard => 'Cumhur (Şâfiî, Mâlikî, Hanbelî)';

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
      'Her namaz vaktinde telefon aşağıdaki dakikalar boyunca sessize geçer (Rahatsız Etmeyin), sonra eski haline döner. Örneğin Öğle vaktinde 12:00\'den 12:20\'ye kadar.';

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

  @override
  String get protectTitle => 'Zayıf anlar için koruma';

  @override
  String get protectBody =>
      'Filtreyi kapatmak isteyebileceğiniz zayıf bir an için. Şimdi, sakinken bir bekleme süresi seçin: o zaman durdurma düğmesi filtreyi hemen durdurmaz ve süre bitince yeniden karar verirsiniz. Bir ebeveyn PIN de belirleyebilir.';

  @override
  String protectDelay(Object value) {
    return 'Kapatmadan önce bekleme: $value';
  }

  @override
  String get protectDelayTitle => 'Kapatmadan önce bekleme';

  @override
  String get protectDelayBody =>
      'Örneğin 30 dakika ile: durdurmak için düğmeye basarsınız ama filtre çalışmaya devam eder. 30 dakika sonra bu sayfa hâlâ durdurmak isteyip istemediğinizi sorar. 15 dakika içinde “Onayla” düğmesine basarsanız durur; basmazsanız hiçbir şey değişmez. Bir örtüyü ya da başka bir korumayı kapatmak da böyledir. Bir şeyi açmak her zaman hemen olur.';

  @override
  String get protectDelayOff => 'Yok';

  @override
  String get protectDelay1m => '1 dakika';

  @override
  String get protectDelay5m => '5 dakika';

  @override
  String get protectDelay15m => '15 dakika';

  @override
  String get protectDelay30m => '30 dakika';

  @override
  String get protectDelay1h => '1 saat';

  @override
  String get protectDelay4h => '4 saat';

  @override
  String get protectDelay24h => '24 saat';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes dakika';
  }

  @override
  String get protectPinNone => 'PIN: yok';

  @override
  String get protectPinIsSet => 'PIN: var';

  @override
  String get protectPinSet => 'PIN koy';

  @override
  String get protectPinRemove => 'Kaldır';

  @override
  String get protectPinBody =>
      'PIN varken filtreyi durdurmak veya herhangi bir korumayı kapatmak önce PIN\'i ister. Örneğin bir ebeveyn, çocuk Waaiya\'da filtreyi kapatamasın diye PIN koyar (bunun engelleyemedikleri aşağıda listelenmiştir). Bekleme süresini veya PIN\'i değiştirmek de PIN\'i ister.';

  @override
  String get protectPinForgot =>
      'PIN\'i bir yere yazıp güvenli bir yerde saklayın: unutulursa sıfırlama yoktur. Tek çıkış yolu Waaiya\'nın verilerini silmek veya onu yeniden yüklemektir; bu da tüm ayarlarını siler.';

  @override
  String get protectPinTitle => 'PIN\'i girin';

  @override
  String get protectPinNewTitle => 'Bir PIN seçin';

  @override
  String get protectPinChangeTitle => 'PIN\'i değiştir';

  @override
  String get protectPinCurrent => 'Mevcut PIN';

  @override
  String get protectPinNew => 'Yeni PIN (4 ile 8 rakam)';

  @override
  String get protectPinAgain => 'Yeni PIN tekrar';

  @override
  String get protectPinBad => '4 ile 8 rakam kullanın.';

  @override
  String get protectPinDiffer => 'İki yeni PIN aynı değil.';

  @override
  String protectPinWrong(Object count) {
    return 'Yanlış PIN. Bir aradan önce kalan deneme: $count.';
  }

  @override
  String protectLocked(Object time) {
    return 'Çok fazla yanlış deneme. $time saatinde tekrar deneyin.';
  }

  @override
  String get protectOk => 'Tamam';

  @override
  String get protectCancel => 'İptal';

  @override
  String get protectCancelChange => 'Değişikliği iptal et';

  @override
  String get protectConfirm => 'Onayla';

  @override
  String protectPending(Object time, Object what) {
    return '$what: $time saatine kadar bekliyor. Sonra “Ayarlar” sayfasında onaylayın.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: bekleme bitti. Hâlâ istiyor musunuz? $time saatinden önce “Onayla” düğmesine basın; yoksa hiçbir şey değişmez.';
  }

  @override
  String get protectWaitTitle => 'Bu değişiklik bekliyor';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what şimdi olmaz. $time saatinde hâlâ istiyorsanız, 15 dakika içinde “Ayarlar” sayfasında onaylayın. Hiçbir şey yapmazsanız hiçbir şey değişmez.';
  }

  @override
  String get protectWaitStart => 'Beklemeyi başlat';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Zaten $time saatine kadar bekliyor.';
  }

  @override
  String protectStarted(Object time) {
    return '$time saatine kadar bekliyor. Sonra “Ayarlar” sayfasında onaylayın.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'yarın $time';
  }

  @override
  String get protectHeldBack =>
      'Şimdi değil: koruma ayarlarınız bu değişikliği bekletiyor ya da PIN istiyor.';

  @override
  String get protectLimits =>
      'Bunun engelleyemedikleri: telefonu yeniden başlatma (filtreleme kendiliğinden yeniden başlamaz), zorla durdurma, kaldırma, Waaiya\'nın verilerini silme ve Android\'in kendi ayarları. Bunları engellemek, Waaiya\'nın kullanmadığı özel Android izinleri gerektirir. Bu, kararlı bir kişiye karşı değil, zayıf bir ana karşı korur.';

  @override
  String get protectLimitsDesktop =>
      'Bunun engelleyemedikleri: terminaldeki waaiya komutu, Waaiya\'yı kaldırmak veya ayar klasörünü silmek. Bu, kararlı bir kişiye karşı değil, zayıf bir ana karşı korur.';

  @override
  String get protectLimitsWindows =>
      'Bunun engelleyemedikleri: terminaldeki waaiya-filter.exe komutu, Waaiya\'yı kaldırmak veya ayar klasörünü silmek. Bu, kararlı bir kişiye karşı değil, zayıf bir ana karşı korur.';

  @override
  String get protectWhatStop => 'Filtreyi durdur';

  @override
  String protectWhatOff(Object name) {
    return 'Kapat: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Aç: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Şuraya uygulama ekle: $name';
  }

  @override
  String get protectWhatStrictness => 'Bulanıklığı daha az sıkı yap';

  @override
  String get protectWhatGender => 'Waaiya\'yı kimin kullandığını değiştir';

  @override
  String protectWhatDelay(Object value) {
    return 'Kapatmadan önceki beklemeyi şuna değiştir: $value';
  }

  @override
  String get protectWhatPinChange => 'PIN\'i değiştir';

  @override
  String get protectWhatPinClear => 'PIN\'i kaldır';

  @override
  String get protectWhatSetting => 'Bir ayarı değiştir';

  @override
  String get onboardBodyDesktop =>
      'Waaiya, bu bilgisayardaki uygulamaların sesinden müzik aletlerini kaldırır. Konuşma ve Kuran tilaveti korunur. Şarkı söyleyen sesler de kaldırılır.';

  @override
  String get worshipUseLocation => 'Konumumu kullan';

  @override
  String get worshipWhyLocation =>
      'Bulunduğunuz yerin namaz vakitlerini bulmak için Waaiya bu telefonun yaklaşık konumunu şimdi bir kez okur. Konum telefonda yeriniz olarak kalır ve hiçbir yere gönderilmez.';

  @override
  String get worshipLocating => 'Konumunuz bulunuyor…';

  @override
  String get worshipLocationDenied =>
      'Konum izni verilmedi. Bunun yerine şehrinizi arayabilirsiniz.';

  @override
  String get worshipLocationOff =>
      'Bu telefonda konum kapalı. Açıp yeniden deneyin ya da şehrinizi arayın.';

  @override
  String get worshipLocationSettings => 'Konum ayarları';

  @override
  String get worshipLocationFailed =>
      'Konumunuz bulunamadı. Birazdan yeniden deneyin ya da şehrinizi arayın.';

  @override
  String worshipPlaceNear(Object city) {
    return '$city yakını';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Habous ve İslami İşler Bakanlığı\'nın $city tablolarına göre hesaplanan vakitler.';
  }

  @override
  String get trayOpen => 'Waaiya uygulamasını aç';

  @override
  String get trayQuit => 'Çık';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows, Waaiya\'nın oturum açılırken başlamasına izin vermiyor. Ayarlar › Uygulamalar › Başlangıç bölümünde Waaiya\'yı açın, ardından bu seçeneği yeniden açın.';

  @override
  String get engineErrorAutostartPolicy =>
      'Bu bilgisayarın yöneticisi tarafından seçilen ayarlar, Waaiya\'nın oturum açılırken başlamasına izin vermiyor.';

  @override
  String get notifTextTitle => 'Filtrelerken bildirim metnini göster';

  @override
  String get notifTextBody =>
      'Android, bir uygulama tüm ekranı kaydederken bildirimlerin içeriğini gizler ve filtreleme de buna girer. Açık: Waaiya bu korumayı yalnızca filtrelerken kaldırır, böylece bildirimlerinizi okuyabilirsiniz. Koruma kaldırılmışken, aynı anda yapılan başka bir ekran paylaşımı da bildirimlerinizi ve kodlarınızı başkalarına gösterebilir.';

  @override
  String get notifTextNextStart =>
      'Bu değişikliğin geçerli olması için filtrelemeyi durdurup yeniden başlatın.';

  @override
  String get notifTextRefused =>
      'Bu telefon değişikliği reddetti. Geliştirici seçeneklerinde “Ekran paylaşımı korumalarını devre dışı bırak” ayarını kendiniz açın.';

  @override
  String get notifTextByHand =>
      'Gösteriliyor: Android\'in koruması Geliştirici seçeneklerinde kapalı (“Ekran paylaşımı korumalarını devre dışı bırak”). Siz orada yeniden açana kadar her ekran paylaşımında kapalı kalır.';

  @override
  String get notifTextHowTo =>
      'Android, Waaiya filtrelerken bildirimlerin içeriğini gizler. Tek seferlik kurulumdan sonra Waaiya bunları gösterir: bu korumayı yalnızca filtrelerken kaldırır.';

  @override
  String get notifTextOpenDev => 'Geliştirici seçeneklerini aç';

  @override
  String get notifTextLockNote =>
      'Bu telefonda Android ekran kilitlendiğinde filtrelemeyi de durdurur ve diğer uygulamalar siz Sürdür\'e dokunana kadar sessiz kalır. Kurulum bunu da önler.';

  @override
  String get notifTextHandOptional =>
      'İsteğe bağlı, kurulumsuz: Geliştirici seçeneklerinde “Ekran paylaşımı korumalarını devre dışı bırak” ayarını açın. Bu durumda her ekran paylaşımında kapalı kalır ve bazı telefonlarda yoktur.';

  @override
  String get notifTextForced =>
      'Açık: bu telefonda Android her başlatmadan önce sorar ve ardından her ekran kilidinde filtrelemeyi durdururdu. Waaiya filtrelerken bu korumayı kaldırır, böylece bildirim metni de görünür. Koruma kaldırılmışken, aynı anda yapılan başka bir ekran paylaşımı da bildirimlerinizi ve kodlarınızı başkalarına gösterebilir.';

  @override
  String get oneAppTitle => 'Başlatırken: “Tek uygulama paylaş”, sonra Waaiya';

  @override
  String get oneAppBody =>
      'Android neyi paylaşacağınızı sorduğunda “Tek uygulama paylaş”ı, sonra Waaiya\'yı seçin. Diğer uygulamalar filtrelenmeye devam eder, bildirimler okunabilir kalır ve ekran kilitlendiğinde filtreleme sürer. Tüm ekranla Android bildirim metnini gizler ve her kilitlemede filtrelemeyi durdurur.';

  @override
  String get oneAppPair =>
      'Waaiya\'nın tam çalışması için Kurulum sayfasında Kablosuz hata ayıklama ile bir kez eşleştirin: o zaman özgün müzik de susturulur ve Android her başlatmada sormayı bırakır.';

  @override
  String get notifTextOneApp =>
      'Başlatırken “Tek uygulama paylaş”ı, sonra Waaiya\'yı seçtiğinizde gösterilir. Tüm ekranla Android bunu gizler; tek seferlik kurulumdan sonra Waaiya bunu filtrelerken kaldırır.';

  @override
  String get blurNeedsRestart =>
      'Bulanıklaştırmayı kullanmak için filtrelemeyi durdurup yeniden başlatın: tüm ekrana ihtiyaç duyar ve bu filtreleme “Tek uygulama paylaş” sunularak başladı.';

  @override
  String get micOpenSettings =>
      'Mikrofona izin vermek için Waaiya ayarlarını aç';

  @override
  String get keepRunningTitle => 'Waaiya çalışmaya devam etsin';

  @override
  String get keepRunningBattery =>
      'Bu telefon pil tasarrufu için Waaiya\'yı bir süre sonra kapatabilir ve filtreleme durur. Waaiya ayarlarında, Pil altında “Kısıtlanmamış”ı seçin. Xiaomi, Redmi ve POCO\'da: “Kısıtlama yok”, ayrıca Otomatik başlatmayı da açın.';

  @override
  String get keepRunningNotifications =>
      'Waaiya\'nın bildirimleri kapalı, bu yüzden filtreleme durduğunda size haber veremez. Bunları Waaiya ayarlarından açın.';

  @override
  String get keepRunningOpen => 'Waaiya ayarlarını aç';

  @override
  String get lockAskTitle => 'Ekran kilitlendiğinde filtreleme sürsün mü?';

  @override
  String get lockTitle => 'Ekran kilitlendiğinde filtrelemeye devam et';

  @override
  String get lockBody =>
      'Bu telefonda Android her başlatmadan önce sorar ve ardından her ekran kilidinde filtrelemeyi durdurur. Waaiya, filtreleme sırasında Android\'in ekran paylaşımı korumasını kaldırarak bunu önleyebilir ve filtreleme durunca korumayı geri koyar. Koruma kaldırıldığı sürece aynı anda yapılan başka bir ekran paylaşımı (örneğin görüntülü arama) da bildirimlerinizi gösterebilir. Değişiklik bir sonraki başlatmada geçerli olur.';

  @override
  String get lockYes => 'Filtrelemeye devam et';

  @override
  String get lockNo => 'Her kilitte durdur';

  @override
  String get sendToSupport => 'Waaiya\'ya gönder';

  @override
  String get stateTooSlowNoLinks =>
      'Bu telefon canlı sesi filtrelemek için çok yavaş, bu yüzden ses kesiliyor.';

  @override
  String get startNoSetupBodyNoLinks =>
      'Tek seferlik kurulum henüz yapılmadı. Kurulum olmadan Waaiya orijinal sesi susturamaz: müziği ve filtrelenmiş sesi birlikte duyarsınız.';

  @override
  String protectDelayLongAsk(String value) {
    return '$value bekleme seçilsin mi? Bundan sonra filtreyi veya herhangi bir korumayı kapatmak $value bekler; bu beklemeyi kısaltmak da öyle.';
  }

  @override
  String get keepRunningKilled =>
      'Android, Waaiya filtreleme yaparken onu kapattı; bu yüzden ses artık filtrelenmedi.';
}
