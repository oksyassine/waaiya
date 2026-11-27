// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Yana cire kayan kiɗa daga sautin manhajojinku, kuma yana barin magana da karatun Alƙur\'ani.';

  @override
  String get onboardTitle => 'Barka da zuwa';

  @override
  String get onboardBody =>
      'Waaiya yana cire kayan kiɗa daga sautin manhajojin da ke wannan waya. Ana barin magana da karatun Alƙur\'ani. Ana cire muryoyin waƙa ma.';

  @override
  String get onboardQuestion => 'Ni ne';

  @override
  String get genderMan => 'Namiji';

  @override
  String get genderWoman => 'Mace';

  @override
  String get onboardWhy =>
      'Wannan yana zaɓar waɗanne ƙarin saituna za ku gani ne kawai. Misali, “Kashe waƙar mata” ana nuna shi ga maza kawai. Za ku iya canza shi daga baya.';

  @override
  String get stateOnTitle => 'Tacewa tana kunne';

  @override
  String get stateOffTitle => 'Tacewa a kashe take';

  @override
  String get stateStarting => 'Ana farawa…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Ana tace sautin manhajojinku. Yana zuwa a makare da kusan $delayMs ms (1000 ms daƙiƙa ɗaya ne).';
  }

  @override
  String get stateOffDetail => 'Danna maɓallin don farawa.';

  @override
  String get stateModelFailed =>
      'Tsarin tacewa bai iya buɗuwa ba, don haka an kashe sauti maimakon a kunna shi ba tare da tacewa ba.';

  @override
  String get stateCaptureDenied =>
      'Ana buƙatar izinin makirufo don karɓar sautin sauran manhajoji.';

  @override
  String get stateStoppedBySystem =>
      'Android ya dakatar da tacewa. Danna maɓallin don sake farawa.';

  @override
  String get stateSilencedTitle => 'Tacewa ta tsaya';

  @override
  String get stateSilenced =>
      'Tacewa ta tsaya: an yi wa sauran manhajoji shiru. Danna maɓallin don sake farawa, ko Dakatar don jin su ba tare da tacewa ba.';

  @override
  String get releaseSilence => 'Dakatar: ji manhajoji ba tare da tacewa ba';

  @override
  String get powerStartCd => 'Fara tacewa';

  @override
  String get powerStopCd => 'Dakatar da tacewa';

  @override
  String get captureHint =>
      'Android zai tambaya ko za a raba allonku. Ba a naɗar komai, ba a tura komai.';

  @override
  String get needRecordAudio =>
      'Waaiya yana buƙatar izinin makirufo don karɓar sautin sauran manhajoji. Ba ya taɓa naɗar muryarku.';

  @override
  String get setupBannerTitle => 'Saura mataki ɗaya';

  @override
  String get setupBannerBody =>
      'Ba tare da saitin sau ɗaya ba, za ku ji kiɗan da sautin da aka tace tare.';

  @override
  String get step1Title => 'Shigar da Shizuku';

  @override
  String get step1Body => 'Manhaja ce mai taimako, kyauta, daga Play Store.';

  @override
  String get step1Action => 'Samo Shizuku';

  @override
  String get step2Title => 'Kunna Shizuku';

  @override
  String get step2Body =>
      'Shizuku yana farawa ta Wi-Fi da zaɓin “Wireless debugging” na Android. Taɓa maɓallin don ganin matakai, sannan ku dawo.';

  @override
  String get step2Action => 'Buɗe Shizuku';

  @override
  String get step2Update => 'Sabunta Shizuku';

  @override
  String get step2TooOld =>
      'Sigar Shizuku ɗinku ta tsufa. Ku sabunta ta daga Play Store.';

  @override
  String get step2Denied =>
      'An saita Shizuku ya ƙi Waaiya koyaushe. A cikin Shizuku, ku ba shi izini a jerin manhajoji.';

  @override
  String get step3Title => 'Ba da izini';

  @override
  String get step3Body => 'Taɓawa ɗaya, sannan ku zaɓi “Allow” (Amince).';

  @override
  String get step3Action => 'Ba da izini';

  @override
  String get step3Busy => 'Ana saiti…';

  @override
  String get setupDoneRestart =>
      'An gama. Ku dakatar da tacewa sannan ku sake farawa sau ɗaya don ya fara aiki.';

  @override
  String setupFailed(String details) {
    return 'Saitin bai kammala ba. Bayani:\n$details';
  }

  @override
  String get shizukuRefused =>
      'An ƙi izinin Shizuku. Taɓa maɓallin don sake gwadawa.';

  @override
  String get setupSlow =>
      'Shizuku yana ɗaukar lokaci fiye da yadda aka saba. Ku ci gaba da jira: a wasu wayoyi mataimakinsa yana ɗaukar har minti ɗaya kafin ya fara a karon farko.';

  @override
  String get setupTimeout =>
      'Shizuku bai amsa ba cikin minti 2. Buɗe Shizuku, ku duba cewa yana nuna yana aiki (“running”), sannan ku sake taɓa maɓallin. Idan saitin ya kammala daga baya, wannan shafin zai sabunta da kansa.';

  @override
  String get setupRefusedXiaomi =>
      'Wannan waya ta ƙi izinin. A Xiaomi, Redmi da POCO, ku kunna zaɓin “USB debugging (Security settings)” a cikin saitunan “Developer options” (zai nemi ku shiga asusun Xiaomi), sannan ku sake gwadawa.';

  @override
  String get setupRefusedColoros =>
      'Wannan waya ta ƙi izinin. A OPPO, OnePlus da realme, a cikin saitunan “Developer options”, ku kunna zaɓin “Disable permission monitoring” (a sabbin sigogi ana kiransa “Disable system optimization”, kuma wataƙila yana bayyana ne kawai idan harshen wayar Turanci ne). Don nemo shi, ku bincika “permission” a cikin saitunan waya “Settings”. Sannan ku sake gwadawa.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi da POCO: idan sanarwar ba ta da wurin rubuta lambar, ku saita salon sanarwa zuwa “Android” a saitunan sanarwa, ko ku rubuta lambar a cikin Waaiya ta hanyar raba allo (“split screen”).';

  @override
  String get stepDoneCd => 'An gama';

  @override
  String stepTodoCd(int step) {
    return 'Mataki na $step';
  }

  @override
  String get computerToggle => 'Yi amfani da kwamfuta maimakon haka';

  @override
  String get computerWeb =>
      'Hanya mafi sauƙi: a kwamfuta, buɗe waaiya.mssid.org/usb a Chrome ko Edge, kunna “USB debugging” sannan ku haɗa wayar da waya (cable). Babu abin da za a saka, kuma yana aiki a Android 10 ma. Ko kuma, idan adb yana kan kwamfutar:';

  @override
  String get computerBody =>
      'Kunna zaɓin “USB debugging”, haɗa wayar da kwamfuta sannan ku gudanar da wannan umarni:';

  @override
  String get copy => 'Kwafa';

  @override
  String get copied => 'An kwafa';

  @override
  String get computerNote =>
      'Layi na biyu ba dole ba ne: yana hana tambayar raba allo a duk lokacin da aka fara.';

  @override
  String get settingsTitle => 'Saituna';

  @override
  String get settingSilenceTitle => 'Yi wa manhajojin da ke hana tacewa shiru';

  @override
  String get settingSilenceBody =>
      'Ana ba da shawara. Wasu manhajoji ba sa barin a tace sautinsu; wannan yana yi musu shiru maimakon barin kiɗa ya wuce.';

  @override
  String get settingHoldSilenceTitle =>
      'Bar manhajoji shiru idan tacewa ta tsaya da kanta';

  @override
  String get settingHoldSilenceBody =>
      'Ana ba da shawara. Idan Android ya dakatar da tacewa (ba ku ba), sauran manhajoji za su yi shiru har sai kun sake farawa ko kun taɓa Dakatar, maimakon kunna kiɗa ba tare da tacewa ba. Yana buƙatar saitin sau ɗaya.';

  @override
  String get settingStereoTitle => 'Sautin stereo';

  @override
  String get settingStereoBody =>
      'A kashe: mono, wanda ke amfani da kusan rabin batir kuma yana tafiya daidai a wayoyi da yawa. A kunne: yana raba gefen hagu da na dama. Idan wayar ta yi jinkiri sosai don stereo, za ta koma mono da kanta.';

  @override
  String get settingSingingTitle => 'Kashe waƙar mata';

  @override
  String get settingSingingBody =>
      'Misali, ana kashe waƙar da mace ke rerawa, amma ana ci gaba da jin mace da ke yin jawabi.';

  @override
  String get settingSingingNoModel =>
      'Wannan sigar ba ta da mai gane waƙa, don haka ana kashe dukkan muryoyi yayin da wannan ke kunne.';

  @override
  String get settingRestart =>
      'Ku dakatar da tacewa sannan ku sake farawa don canje-canjen su yi aiki.';

  @override
  String get settingGenderTitle => 'Ni ne';

  @override
  String get change => 'Canza';

  @override
  String get playerTitle => 'Bidiyo da sauti da hoto a daidaice';

  @override
  String get playerBody =>
      'Ku tura bidiyo zuwa Waaiya (ko ku yi amfani da “Open with”, wato Buɗe da) don kallonsa a tace, da sauti da hoto a daidaice, ba tare da jinkirin tacewa kai tsaye ba.';

  @override
  String get licences => 'Lasisoshin buɗaɗɗen tushe (open-source)';

  @override
  String get licencesIntro =>
      'Waaiya manhaja ce mai ʼyanci ƙarƙashin GNU Affero General Public License v3 ko sabuwar sigarta. Lambar tushe (source code): https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (bayanan horarwa): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Cikakkun rubutu';

  @override
  String get back => 'Koma baya';

  @override
  String get linkEntryTitle => 'Buɗe mahaɗa';

  @override
  String get linkEntryBody =>
      'Liƙa mahaɗar (link) YouTube, TikTok ko Instagram don kallo ko ajiye ta ba tare da kiɗa ba.';

  @override
  String get linkTitle => 'Buɗe mahaɗa';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Mahaɗar bidiyo ko sauti';

  @override
  String get linkPaste => 'Liƙa';

  @override
  String get linkOpen => 'Buɗe';

  @override
  String get linkResolving => 'Ana buɗe mahaɗar…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Kalla ba tare da kiɗa ba';

  @override
  String get linkSave => 'Ajiye ba tare da kiɗa ba';

  @override
  String get linkListen => 'Saurara ba tare da kiɗa ba';

  @override
  String get linkAudioOnly =>
      'Ba za a iya buɗe bidiyon wannan mahaɗa ba tukuna: sautinsa kaɗai.';

  @override
  String get linkDownloading => 'Ana saukewa…';

  @override
  String get linkFiltering => 'Ana cire kiɗa…';

  @override
  String get linkCancel => 'Soke';

  @override
  String get linkCancelled => 'An soke. Ba a ajiye komai ba.';

  @override
  String get linkTimedOut =>
      'Android ya dakatar da ajiyewa: yana barin irin wannan aiki na ʼyan awoyi kaɗan ne a rana. Ba a ajiye komai ba; buɗe Waaiya ku sake gwadawa.';

  @override
  String get linkExportFailed =>
      'Ba a iya ajiye wannan ba. Ba a ajiye komai ba.';

  @override
  String get linkSaved => 'An ajiye ba tare da kiɗa ba';

  @override
  String get linkSavedVideo => 'A cikin hotunanku (gallery): Movies › Waaiya';

  @override
  String get linkSavedAudio => 'A cikin sautukanku: Music › Waaiya';

  @override
  String get linkPlay => 'Kunna';

  @override
  String get linkShare => 'Raba';

  @override
  String get linkShareNote =>
      'Ku raba bidiyon da aka ba ku izinin rabawa kaɗai.';

  @override
  String get linkLive => 'Ba za a iya ajiye shirye-shiryen kai tsaye ba.';

  @override
  String get linkBusy => 'Ana ajiye wani bidiyo. Don Allah ku jira ya kammala.';

  @override
  String get linkInvalid =>
      'Don Allah ku liƙa mahaɗar yanar gizo (mai farawa da https://).';

  @override
  String get linkLogin =>
      'Shafin bai nuna wannan bidiyo ba tare da asusu ba. Rubuce-rubucen da kowa zai iya gani yawanci suna buɗuwa: ku sake gwadawa bayan ʼyan mintuna. Ba za a iya buɗe na sirri ba.';

  @override
  String get linkUnsupported => 'Ba a goyon bayan wannan shafi.';

  @override
  String get linkPlaylist =>
      'Wannan jerin bidiyoyi ne (playlist). Don Allah ku buɗe bidiyo ɗaya.';

  @override
  String get linkNoFormat =>
      'Wannan bidiyo ba ya cikin tsarin da Waaiya zai iya tacewa tukuna.';

  @override
  String get linkFailed =>
      'Ba a iya buɗe wannan mahaɗa ba. Ku duba intanet ɗinku sannan ku sake gwadawa.';

  @override
  String get linkPlayFailed =>
      'Ba a iya kunna wannan ba. Ba a kunna komai ba tare da tacewa ba.';

  @override
  String get linkLimited =>
      'Shafin yana taƙaita buƙatu a yanzu. Ku sake gwadawa bayan ʼyan mintuna.';

  @override
  String get blurTitle => 'Dusashe allo';

  @override
  String get blurBody =>
      'Yana rufe mutane da hotuna a allo yayin da tacewa ke kunne. Yana aiki a cikin wayar; ba a tura komai zuwa ko\'ina ba.';

  @override
  String get blurOnTitle => 'Dusashewa tana aiki';

  @override
  String get blurOffTitle => 'Dusashewa a kashe take';

  @override
  String get blurStartCd => 'Kunna dusashewa';

  @override
  String get blurStopCd => 'Kashe dusashewa';

  @override
  String get blurOffDetail =>
      'Ku danna maɓallin don farawa. Tacewa ma tana farawa tare da ita.';

  @override
  String get blurWhatTitle => 'Abin da za a dusashe';

  @override
  String get blurWomenTitle => 'Dusashe hotunan mata';

  @override
  String get blurWomenBody =>
      'Ana rufe dukkan jiki. Idan manhajar ba ta tabbata cewa mutum namiji ne ba, ana rufe shi shi ma.';

  @override
  String get blurNudityTitle => 'Dusashe hotunan tsiraici';

  @override
  String get blurNudityBody =>
      'Tsiraici ko tufafin da ke bayyana jiki, a jikin kowa: ana rufe dukkan allo.';

  @override
  String get blurFailTitle => 'Rufe allo idan dusashewa ta kasa tafiya daidai';

  @override
  String get blurFailBody =>
      'A kunne: ana rufe dukkan allo idan wayar ta yi jinkiri sosai ko dusashewa ta kasa. A kashe: allon yana bayyana tare da gargaɗi.';

  @override
  String get blurSetupManual => 'Ba da izini a saitunan Android';

  @override
  String get blurStatusNeedsSetup =>
      'Don dusashewa, Waaiya yana buƙatar nunawa a saman sauran manhajoji. Mafi kyau: “Je zuwa saitin”, don taɓawarku ta ci gaba da kaiwa manhajar da ke ƙarƙashin dusashewa. Ko kuma “Ba da izini a saitunan Android”, amma daga nan taɓa wurin da aka dusashe ba zai yi komai ba.';

  @override
  String get blurStatusNeedsOverlay =>
      'Don dusashewa, Waaiya yana buƙatar nunawa a saman sauran manhajoji. Mafi kyau: ku yi saitin na lokaci ɗaya, don taɓawarku ta ci gaba da kaiwa manhajar da ke ƙarƙashin dusashewa. Ko kuma ku ba da izinin “Display over other apps” a saitunan Android, amma daga nan taɓa wurin da aka dusashe ba zai yi komai ba.';

  @override
  String get blurFailUnavailable =>
      'Ba ya aiki a yanzu: murfin dukkan allo zai hana kowace taɓawa kuma za ku iya maƙalewa. Ku kunna mataimakin Waaiya (Android 12 ko sabo) sai ya kunnu: daga nan ana zana murfin ta yadda taɓawa ke ratsa su. Kafin nan, idan dusashewa ta kasa tafiya daidai, allon yana bayyana tare da gargaɗi.';

  @override
  String get blurFailNeedsA11y =>
      'Ba ya aiki a yanzu: murfin dukkan allo zai hana kowace taɓawa kuma za ku iya maƙalewa. Ku kunna mataimakin Waaiya (Android 12 ko sabo) ko ku kunna sabis ɗin sauƙaƙa amfani “Dusashewar Waaiya” a saitunan Android sai ya kunnu. Kafin nan, allon yana bayyana tare da gargaɗi.';

  @override
  String get languageTitle => 'Harshe';

  @override
  String settingLanguageTitle(String language) {
    return 'Harshe: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Ku dakatar da tacewa sannan ku sake farawa don saitunan dusashewa su yi aiki.';

  @override
  String get blurStatusStarting => 'Dusashewa tana farawa…';

  @override
  String get blurStatusOn => 'Dusashewa tana kunne.';

  @override
  String get blurStatusOnVisible =>
      'Dusashewa tana kunne, cikin yanayin taka-tsantsan: wannan waya tana nuna dusashewar a cikin ɗaukar allonta, don haka wurin da aka dusashe zai ci gaba da kasancewa a dusashe har sai abin da ke allo ya canza.';

  @override
  String get blurStatusModels =>
      'Wannan sigar ba ta da tsarin dusashewa don zaɓin da kuka yi.';

  @override
  String get blurStatusFailing => 'Dusashewa ta kasa tafiya daidai a yanzu.';

  @override
  String get blurStatusNoOverlay =>
      'Dusashewa ba za ta iya nunawa a saman sauran manhajoji ba: ku ba ta izini a sama.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Dusashewa ba ta iya ganin allo. Bayani:\n$details';
  }

  @override
  String get step2Guide => 'Yadda ake kunna Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Ba ya aiki: a wannan sigar Android, murfin dukkan allo zai hana kowace taɓawa kuma za ku iya maƙalewa (murfin da taɓawa ke ratsa su yana buƙatar Android 12 ko sabo). Idan dusashewa ta kasa tafiya daidai, allon yana bayyana tare da gargaɗi.';

  @override
  String get guideTitle => 'Kunna Shizuku, mataki-mataki';

  @override
  String get guideOpenDev => 'Buɗe “Developer options”';

  @override
  String get guideOpenShizuku => 'Buɗe Shizuku';

  @override
  String get guideClose => 'Rufe';

  @override
  String get guideBody =>
      'Kuna buƙatar Wi-Fi da Android 11 ko sabo. Ana haɗawa sau ɗaya ne kawai; bayan wayar ta sake kunnuwa, mataki na 7 kaɗai za ku maimaita.\n\n1. Haɗa wayar da Wi-Fi.\n\n2. Kunna saitunan “Developer options”: a saitunan waya, “Settings” › “About phone” › “Software information” › taɓa “Build number” sau 7. (A wasu wayoyi: “Settings” › “About phone” › “Build number”.)\n\n3. Buɗe Shizuku. Idan ya nemi izinin nuna sanarwa, ku amince: ana rubuta lambar haɗawa a cikin sanarwar Shizuku.\n\n4. A cikin Shizuku, ƙarƙashin “Start via Wireless debugging”, taɓa “Pairing”. A shafin da ya buɗe, taɓa “Developer options”, kunna “Wireless debugging” sannan ku tabbatar da “Allow”.\n\n5. Taɓa kalmomin “Wireless debugging” (ba makunnin ba), sannan “Pair device with pairing code” (haɗa waya da lamba). Lamba mai lambobi 6 za ta bayyana.\n\n6. Ku bar wannan shafin a buɗe sannan ku ja sanarwa ƙasa. Idan sanarwar Shizuku ta ce “Pairing service found”, taɓa “Enter pairing code” sannan ku rubuta lambar. Shizuku zai ce haɗawa ta yi nasara.\n\n7. Koma Shizuku sannan ku taɓa “Start” ƙarƙashin “Start via Wireless debugging”. Ku jira har sai ya ce “Shizuku is running”.\n\n8. Dawo Waaiya sannan ku taɓa “Ba da izini”, sannan “Allow”.\n\nBayan wayar ta sake kunnuwa Shizuku yana tsayawa: haɗa da Wi-Fi, sake kunna “Wireless debugging” idan a kashe yake, buɗe Shizuku sannan ku taɓa “Start”. Babu sabon haɗawa.';

  @override
  String get wsetupRouteTitle => 'Saiti a wannan waya';

  @override
  String get wsetupRouteBody =>
      'Gajerun matakai huɗu, sau ɗaya kawai. Babu ƙarin manhaja, babu kwamfuta. Waaiya yana yi wa kowane mataki alama idan an gama shi.';

  @override
  String get wizDevTitle => 'Kunna saitunan “Developer options”';

  @override
  String get wizDevBody =>
      'A shafin bayanin waya “About phone”, taɓa “Build number” sau 7, sannan ku dawo nan. Idan ba ku same shi ba, ku bincika “Build number” a cikin saitunan waya “Settings”.';

  @override
  String get wizDevBodySamsung =>
      'A shafin bayanin waya “About phone” › “Software information”, taɓa “Build number” sau 7, sannan ku dawo nan.';

  @override
  String get wizDevBodyXiaomi =>
      'A shafin bayanin waya “About phone”, taɓa “OS version” sau 7 (a tsofaffin wayoyi “MIUI version”; a wasu yana ƙarƙashin “Detailed info and specs”), sannan ku dawo nan.';

  @override
  String get wizDevBodyColoros =>
      'A shafin bayanin waya “About device” (ko “About phone”) › “Version”, taɓa “Build number” sau 7, sannan ku dawo nan.';

  @override
  String get wizDevBodyVivo =>
      'A shafin bayanin waya “About phone”, taɓa “Software version” sau 7 (a wasu wayoyi: “Software information” › “Build number”), sannan ku dawo nan.';

  @override
  String get wizDevBodyHuawei =>
      'A shafin bayanin waya “About phone”, taɓa “Build number” sau 7, sannan ku dawo nan.';

  @override
  String get wizDevBodyTranssion =>
      'A shafin bayanin waya “My phone” (ko “About phone”), taɓa “Build number” sau 7, sannan ku dawo nan.';

  @override
  String get setupNoteHuawei =>
      'Huawei: wayoyin Huawei da yawa ba su da zaɓin “Wireless debugging”. Idan ba ku same shi a cikin saitunan “Developer options” ba, ku yi amfani da kwamfuta (“Wasu hanyoyi” a ƙasa).';

  @override
  String get wsetupFilterOn =>
      'Tacewa tana kunne: a wannan sigar Android ba za a iya rubuta lambar a sanarwa ba yayin da take aiki. Ku fara dakatar da tacewa, ko ku yi amfani da raba allo da “Rubuta lambar a nan”.';

  @override
  String get wizDevSearch =>
      'Sunayen na iya bambanta da harshen wayar: idan ba ku same shi ba, ku yi amfani da wurin bincike da ke saman saitunan waya “Settings”.';

  @override
  String get wizDevAction => 'Buɗe bayanin waya “About phone”';

  @override
  String get wizWifiTitle => 'Haɗa da Wi-Fi';

  @override
  String get wizWifiBody => 'Kowace Wi-Fi ta isa; ba a buƙatar intanet.';

  @override
  String get wizWifiAction => 'Buɗe saitunan Wi-Fi';

  @override
  String get wizWdTitle => 'Kunna zaɓin “Wireless debugging”';

  @override
  String get wizWdBody =>
      'Waaiya yana buɗe saitunan “Developer options” a wurin “Wireless debugging”. Ku kunna shi sannan ku taɓa “Allow”.';

  @override
  String get wizWdAction => 'Buɗe saitunan “Developer options”';

  @override
  String get wizPairTitle => 'Rubuta lambar haɗawa';

  @override
  String get wizPairBody =>
      'Taɓa kalmomin “Wireless debugging”, sannan “Pair device with pairing code” (haɗa waya da lamba). Rubuta lambobin 6 a cikin sanarwar Waaiya. Waaiya zai yi sauran.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya ya riga ya haɗu da wannan waya: ba a buƙatar lamba. Taɓa maɓallin, Waaiya zai kammala da kansa.';

  @override
  String get wizPairAction => 'Ci gaba';

  @override
  String get wizAgain => 'Sake yin saitin';

  @override
  String get setupShizukuReadyTitle => 'Da Shizuku, wanda ke aiki tuni';

  @override
  String get setupOtherWaysPlain => 'Wasu hanyoyin yin saitin';

  @override
  String get wizSkip => 'Tsallaka zuwa “Wireless debugging”';

  @override
  String get setupOtherWays => 'Wasu hanyoyi: Shizuku ko kwamfuta';

  @override
  String get wsetupEnterHere => 'Rubuta lambar a nan';

  @override
  String get wsetupCancel => 'Soke';

  @override
  String get wsetupAndroid10 =>
      'Android 10 ba zai iya yin saitin da kansa ba: yana buƙatar kwamfuta, kai tsaye (a ƙasa) ko don kunna Shizuku sau ɗaya.';

  @override
  String get wsetupShizukuHeading => 'Ko da manhajar Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku kuma yana barin taɓawa ta ratsa murfin allo.';

  @override
  String get wsetupChannel => 'Saitin sau ɗaya';

  @override
  String get wsetupNotifTitle => 'Saitin Waaiya: ana jiran lambar haɗawa';

  @override
  String get wsetupFoundTitle => 'An sami shafin haɗawa';

  @override
  String get wsetupBusyTitle => 'Saitin Waaiya';

  @override
  String get wsetupDoneTitle => 'An gama saiti';

  @override
  String get wsetupDoneBody =>
      'Yanzu Waaiya zai iya yi wa ainihin sauti shiru. Kuna iya kashe “Wireless debugging”.';

  @override
  String get wsetupDoneHelperBody =>
      'An gama. Wannan waya ba ta barin manhajoji su riƙe waɗannan izini, don haka mataimakin Waaiya ne ke yi wa ainihin sauti shiru. Mataimakin yana tsayawa idan wayar ta sake kunnuwa da kuma idan an sabunta Waaiya. Idan kun buɗe Waaiya bayan haka, zai sake kunna mataimakin da kansa idan “Wireless debugging” yana kunne; idan ba haka ba, zai nuna maɓalli don yin hakan.';

  @override
  String get helperMissingTitle => 'Mataimakin Waaiya ya tsaya';

  @override
  String get helperMissingBody =>
      'Wannan waya ba ta riƙe izinin Waaiya, don haka Waaiya yana amfani da mataimakinsa. Mataimakin yana tsayawa idan wayar ta sake kunnuwa da kuma idan an sabunta Waaiya. Haɗa da Wi-Fi, kunna “Wireless debugging” a cikin saitunan “Developer options”, sannan ku taɓa “Kunna mataimakin Waaiya”.';

  @override
  String get helperChannel => 'Mataimakin Waaiya';

  @override
  String get helperStarting => 'Ana kunna mataimakin…';

  @override
  String get helperModeNote =>
      'Wannan waya ba ta barin manhajoji su riƙe waɗannan izini: mataimakin Waaiya ne ke yin aikin. Yana tsayawa idan wayar ta sake kunnuwa da kuma idan an sabunta Waaiya. Idan kun buɗe Waaiya bayan haka, zai sake kunna mataimakin da kansa idan “Wireless debugging” yana kunne; idan ba haka ba, zai nuna maɓalli don yin hakan.';

  @override
  String get helperTipXiaomi =>
      'Ba dole ba ne, don riƙe izinin har abada (babu mataimaki bayan sake kunna waya): a cikin saitunan “Developer options”, kunna “USB debugging (Security settings)” (zai nemi ku shiga asusun Xiaomi), sannan ku sake yin saitin.';

  @override
  String get helperTipColoros =>
      'Ba dole ba ne, don riƙe izinin har abada (babu mataimaki bayan sake kunna waya): a cikin saitunan “Developer options”, kunna “Disable permission monitoring” (a sabbin sigogi “Disable system optimization”; wataƙila yana bayyana ne kawai idan harshen wayar Turanci ne), sannan ku sake yin saitin.';

  @override
  String get stateOnHelperMissing =>
      'Ba a yi wa ainihin sauti shiru ba, don haka kuna jin kiɗan tare da sautin da aka tace: mataimakin Waaiya ya tsaya. Haɗa da Wi-Fi, kunna “Wireless debugging”, sannan ku taɓa “Kunna mataimakin Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Ko ku yi amfani da “Saiti a wannan waya” a wannan shafi: daga nan mataimakin Waaiya yana aiki ba tare da wannan zaɓin ba.';

  @override
  String get helperStartAnywayTitle => 'Mataimakin Waaiya ya tsaya';

  @override
  String get helperStartAnywayBody =>
      'Ba tare da shi ba za ku ji kiɗan tare da sautin da aka tace. Ku fara kunna mataimakin (dole “Wireless debugging” ya kasance a kunne), ko ku fara tacewa haka nan.';

  @override
  String get wsetupFailedTitle => 'Saitin bai kammala ba';

  @override
  String get wsetupPairing => 'Ana haɗawa…';

  @override
  String get wsetupConnecting => 'Ana haɗuwa da ba da izini…';

  @override
  String get wsetupNeedWifi =>
      'Ku fara haɗa da Wi-Fi (ba a buƙatar intanet): “Wireless debugging” yana aiki ne a Wi-Fi kaɗai.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'A cikin saitunan “Developer options”, kunna “Wireless debugging”, sannan ku taɓa sunansa da “Pair device with pairing code”.';

  @override
  String get wsetupOpenDialog =>
      'A cikin “Wireless debugging”, taɓa “Pair device with pairing code”. Ku bar lambar a allo sannan ku taɓa “Shigar da lamba” a nan.';

  @override
  String get wsetupEnterCodeBody =>
      'Taɓa “Shigar da lamba” sannan ku rubuta lamba mai lambobi 6 da ke nunawa a cikin saitunan waya “Settings”.';

  @override
  String get wsetupCodeWaiting =>
      'An karɓi lambar. Ana jiran shafin “Pair device with pairing code”: ku bar shi a buɗe.';

  @override
  String get wsetupWrongCode =>
      'Ba a karɓi wannan lamba ba. Ku duba lambobi 6 da ke allo sannan ku sake shigar da su. Idan shafin haɗawa ya rufe, ku sake buɗe shi: lambar tana canzawa.';

  @override
  String get wsetupPairingFailed =>
      'Haɗawa ba ta yi aiki ba. Rufe shafin haɗawa, sake buɗe “Pair device with pairing code” sannan ku shigar da sabuwar lambar.';

  @override
  String get wsetupWaitingConnect =>
      'An haɗa. Ku bar “Wireless debugging” a kunne: Waaiya yana haɗuwa.';

  @override
  String get wsetupNotPaired =>
      'Wannan waya ba ta san Waaiya ba kuma (an cire haɗin ko ya ƙare). Buɗe “Pair device with pairing code” sannan ku shigar da lambar.';

  @override
  String get wsetupConnectFailed =>
      'Ba a iya haɗuwa da “Wireless debugging” ba. Ku kashe shi sannan ku sake kunna shi: Waaiya zai sake gwadawa da kansa.';

  @override
  String get wsetupGrantFailed =>
      'An haɗu, amma har yanzu ba a sami izinin ba. Ku yi amfani da Shizuku ko kwamfuta a ƙasa.';

  @override
  String get wsetupTimeout =>
      'An tsaya bayan minti 10 ba tare da kammalawa ba. Kuna iya sake gwadawa.';

  @override
  String get wsetupCodeUnreadable => 'Rubuta lambobi 6 na lambar haɗawa.';

  @override
  String get wsetupCodeHint => 'Lamba mai lambobi 6';

  @override
  String get wsetupEnterCode => 'Shigar da lamba';

  @override
  String wsetupDetail(String details) {
    return 'Bayani: $details';
  }

  @override
  String get wsetupErrTimeout => 'ba a sami amsa a kan lokaci ba';

  @override
  String get wsetupErrRefused => 'an ƙi haɗi';

  @override
  String get wsetupDevOff =>
      'Saitunan “Developer options” a kashe suke. A shafin bayanin waya “About phone”, taɓa “Build number” sau 7, sannan ku dawo.';

  @override
  String get wsetupOpenAbout => 'Bayanin waya “About phone”';

  @override
  String get wsetupNotifOff =>
      'Sanarwar Waaiya a kashe take, don haka ba za a iya rubuta lambar a sanarwa ba. Ku yi amfani da raba allo (“Settings” a rabi ɗaya, Waaiya a ɗayan) sannan ku taɓa “Rubuta lambar a nan”.';

  @override
  String get wsetupCodeDialogTitle => 'Lambar haɗawa';

  @override
  String get wsetupCodeDialogBody =>
      'Sai da raba allo kawai (“Settings” a rabi ɗaya, Waaiya a ɗayan): barin “Settings” yana rufe shafin haɗawa kuma lambarsa ta daina aiki. Rubuta lamba mai lambobi 6 da ke ƙarƙashin “Pair device with pairing code”.';

  @override
  String get wsetupCodeOk => 'Haɗa';

  @override
  String get blurStrictTitle => 'Yawan tabbaci kafin a nuna namiji';

  @override
  String blurStrictValue(String level) {
    return 'Yawan tabbaci kafin a nuna namiji: $level';
  }

  @override
  String get blurStrict0 =>
      'Tsantsan: sai mutanen da manhajar ta kusan tabbatar maza ne kawai';

  @override
  String get blurStrict1 => 'Tsaka-tsaki: ana nuna kusan ninki biyu na maza';

  @override
  String get blurStrict2 => 'Sassauci: ƙarin maza kaɗan fiye da tsaka-tsaki';

  @override
  String get blurStrict0Short => 'tsantsan';

  @override
  String get blurStrict1Short => 'tsaka-tsaki';

  @override
  String get blurStrict2Short => 'sassauci';

  @override
  String get blurStrictHelp =>
      'Ana nuna mutum ne kawai idan manhajar ta tabbatar namiji ne; duk sauran ana dusashe su. Tsantsan yana nuna kusan maza 7 cikin 100; tsaka-tsaki kusan 14, sassauci kusan 16. Har yanzu wasu mata suna tsallakewa; kowane mataki na rage tsantsan yana barin kusan ƙarin 1 cikin 100 su tsallake.';

  @override
  String get stateOnNotMuted =>
      'Ba a yi wa ainihin sauti shiru ba tukuna, don haka kuna jin kiɗan tare da sautin da aka tace. Ku kammala saitin sau ɗaya a shafin “Saiti”.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya ba zai iya yi wa ainihin sautin manhajar da ke kunne yanzu shiru ba, don haka ana iya jin kiɗan har yanzu. Ku dakatar da tacewa sannan ku sake farawa. Idan ya ci gaba, ku tura rahoton bincike (Saituna).';

  @override
  String get stateTooSlow =>
      'Wannan waya tana da jinkiri sosai don tace sauti kai tsaye, don haka sautin yana yankewa. “Buɗe mahaɗa” da ke shafin “Mahaɗai” yana aiki duk da haka: yana tace bidiyon kafin ya kunna shi.';

  @override
  String get stateMonoNote =>
      'Sautin yana mono don wannan waya ta iya tafiya daidai.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'An yi shiru saboda waɗannan ba sa barin tacewa: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Yana kunne ba tare da tacewa ba saboda waɗannan ba sa barin tacewa: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android bai ba Waaiya sautin sauran manhajoji ba. Taɓa maɓallin don sake farawa.';

  @override
  String get stateCaptureCancelled =>
      'An soke farawa a tambayar raba allo ta Android. Waaiya yana buƙatar ku zaɓi “Start” (Fara) a can don karɓar sautin. Ba a naɗar komai, ba a tura komai.';

  @override
  String get startNoSetupTitle => 'Za a ci gaba da jin kiɗan';

  @override
  String get startNoSetupBody =>
      'Ba a yi saitin sau ɗaya ba tukuna. Ba tare da shi ba Waaiya ba zai iya yi wa ainihin sauti shiru ba: za ku ji kiɗan da sautin da aka tace tare.\n\n“Buɗe mahaɗa” yana aiki ba tare da wani saiti ba.';

  @override
  String get startNoSetupSetup => 'Yi saitin';

  @override
  String get startNoSetupAnyway => 'Fara haka nan';

  @override
  String get diagButton => 'Akwai matsala? Rahoton bincike';

  @override
  String get diagTitle => 'Rahoton bincike';

  @override
  String get diagNote =>
      'Abin da Waaiya ke gani a wannan waya. Ku kwafa shi ko ku raba shi da wanda ke taimaka muku. Waaiya ba ya tura shi da kansa: ku ne kuke zaɓar wanda zai karɓa.';

  @override
  String get notifStoppedTitle => 'Waaiya ya tsaya';

  @override
  String get notifStoppedText => 'Ba a tace sauti kuma. Taɓa don sake farawa.';

  @override
  String get wsetupGuide => 'Matakai da hotuna';

  @override
  String get navFilter => 'Tacewa';

  @override
  String get navScreen => 'Allo';

  @override
  String get navLinks => 'Mahaɗai';

  @override
  String get navSetup => 'Saiti';

  @override
  String get navSettings => 'Saituna';

  @override
  String get setupDoneTitle => 'An gama saiti';

  @override
  String get setupDoneBody =>
      'Waaiya zai iya yi wa ainihin sautin sauran manhajoji shiru. Ku sake yin sa ne kawai idan wani abu ya canza (an soke saitin, ko Waaiya ya ce babu shi).';

  @override
  String get setupRedo => 'Sake nuna saitin';

  @override
  String get setupGo => 'Je zuwa saitin';

  @override
  String get helperTitle => 'Taɓawa ta cikin wuraren da aka dusashe';

  @override
  String get helperBodyOff =>
      'Ba tare da taimako ba, murfi yana hana taɓawa da ke ƙarƙashinsa. Mataimakin Waaiya yana zana murfin ta yadda taɓawa ke ratsawa. Kunna “Wireless debugging” (ana buƙatar Wi-Fi) sannan ku taɓa maɓallin; a karon farko, ku yi haɗawa sau ɗaya kamar a saiti. Bayan wayar ta sake kunnuwa, ku sake taɓa shi.';

  @override
  String get helperStart => 'Kunna mataimakin Waaiya';

  @override
  String get helperOn =>
      'Mataimakin Waaiya yana zana dusashewar: taɓawa tana ratsa ta. Yana tsayawa idan wayar ta sake kunnuwa ko idan an kashe “USB debugging” (wani maɓalli dabam a cikin “Developer options”); sai ku sake taɓa maɓallin.';

  @override
  String get helperShizukuOn =>
      'Shizuku yana zana murfin: taɓawa tana ratsa su.';

  @override
  String get helperOrShizuku => 'Ko da Shizuku:';

  @override
  String get filterOptionsTitle => 'Zaɓuɓɓukan tacewa';

  @override
  String get settingsGeneralTitle => 'Gabaɗaya';

  @override
  String get simpleTitle =>
      'Yanayi mai sauƙi (gwaji): babu “Developer options”';

  @override
  String get simpleBody =>
      'Don wayoyin da saitin da ke ƙasa ya yi musu wuya sosai. Yayin da Waaiya ke tacewa, yana kashe sautin media na wayar kuma yana kunna sautin da aka tace a wata hanyar sauti dabam. Maɓallan ƙarar ku suna saita ƙarar Waaiya. Android tana neman izinin raba allo a kowace farawa. Sautin media yana dawowa idan tacewa ta tsaya.';

  @override
  String get simpleSwitch => 'Yi amfani da yanayi mai sauƙi';

  @override
  String simpleChannelTitle(String channel) {
    return 'Hanyar sauti: $channel';
  }

  @override
  String get simpleChannelAlarm => 'Ƙararrawa';

  @override
  String get simpleChannelNotification => 'Sanarwa';

  @override
  String get simpleChannelHelp =>
      'Idan ba ku jin komai, ko sauti yana fitowa daga lasifikar wayar alhali belun kunne na ciki, gwada ɗayan hanyar. “Sanarwa” ba ta da sauti idan wayar tana kan girgiza ko “Do Not Disturb”.';

  @override
  String get simpleTestNote =>
      'Wannan gwaji ne. Bayan kun gwada shi (lasifika, belun kunne, Bluetooth), don Allah ku tura rahoton bincike daga Saituna.';

  @override
  String get simpleOnDetail =>
      'Yanayi mai sauƙi (gwaji): an kashe sautin media yayin da Waaiya ke tacewa.';

  @override
  String get worshipPrayerFajr => 'Asuba';

  @override
  String get worshipPrayerSunrise => 'Fitowar rana';

  @override
  String get worshipPrayerDhuhr => 'Azahar';

  @override
  String get worshipPrayerAsr => 'La\'asar';

  @override
  String get worshipPrayerMaghrib => 'Magariba';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'Kawo ƙarshen shiru yanzu';

  @override
  String get worshipUnmute => 'Dawo da sauti yanzu';

  @override
  String get worshipSmsDefault =>
      'Lokacin salla ne, ba zan iya amsawa yanzu ba. Zan kira ka daga baya.';

  @override
  String get updateTitle => 'Sabunta manhaja';

  @override
  String get updateAuto => 'Duba sabon sigar sau ɗaya a rana';

  @override
  String get updateAutoBody =>
      'Waaiya tana tambayar waaiya.mssid.org ko akwai sabuwar siga, kuma ba ta aika komai ba. Ba a sauke komai har sai kun taɓa Sabunta yanzu.';

  @override
  String get updateCheck => 'Duba yanzu';

  @override
  String get updateChecking => 'Ana dubawa…';

  @override
  String updateNone(String version) {
    return 'Kuna da sabuwar siga ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest ta fito. Kuna da $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Saukewa: $size, abubuwan da suka canza kawai (manhajar gaba ɗaya $full ce).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Saukewa: $size.';
  }

  @override
  String get updateNow => 'Sabunta yanzu';

  @override
  String updateDownloading(String progress) {
    return 'Ana saukewa: $progress';
  }

  @override
  String get updatePreparing => 'Ana shirya sabuntawa…';

  @override
  String get updateInstalling =>
      'Tabbatar da girkawa a allon da Android ke nunawa.';

  @override
  String get updateStopsFilter =>
      'Girkawa tana tsayar da tacewa. Sake kunna ta bayan sabuntawa.';

  @override
  String get updatePermission =>
      'Ba wa Waaiya izinin girka sabuntawarta, sannan sake taɓa Sabunta yanzu.';

  @override
  String get updateFailed =>
      'Ba a iya kammala sabuntawa ba. Sake gwadawa daga baya, ko ku sauke ta daga shafin yanar gizo.';

  @override
  String get updateOpenPage => 'Buɗe shafin saukewa';

  @override
  String get updateCheckFailed =>
      'Ba a iya dubawa yanzu ba. Sake gwadawa daga baya.';

  @override
  String get moveOldTitle => 'Waaiya ta koma';

  @override
  String get moveOldBody =>
      'Yanzu Waaiya tana zuwa a matsayin sabuwar manhaja a Android (Waaiya ɗaya ce da sabon suna), kuma wannan ba za ta ƙara samun sabuntawa ba. Saka sabuwar: saitunanku za su bi ta. Sannan ku yi saitin farko na sau ɗaya a cikinta, ku cire wannan.';

  @override
  String get moveOldInstalled =>
      'An saka sabuwar Waaiya. Buɗe ta: za ta ɗauki saitunanku. Yi saitin farko na sau ɗaya, sannan ku cire wannan tsohuwar don kada su biyu su tace a lokaci ɗaya.';

  @override
  String get moveInstall => 'Saka sabuwar Waaiya';

  @override
  String get moveOpenNew => 'Buɗe sabuwar Waaiya';

  @override
  String get moveRemoveThis => 'Cire wannan tsohuwar Waaiya';

  @override
  String get moveNewTitle => 'Tsohuwar Waaiya tana nan a kan wayar';

  @override
  String get moveNewBody =>
      'Tsohuwar Waaiya (ta kafin siga 0.2.15) tana nan a wannan wayar. Cire ta don kada su biyu su tace a lokaci ɗaya.';

  @override
  String get moveNewImported => 'An kawo saitunanku daga gare ta.';

  @override
  String get moveRemoveOld => 'Cire tsohuwar Waaiya';

  @override
  String get captionsCardTitle => 'Rubutun magana kai tsaye';

  @override
  String get captionsCardBody =>
      'Yana rubuta abin da ake faɗa da Larabci a allo, a huɗuba ko darasi: don kurame da masu ƙarancin ji. Yana aiki a waya, ba tare da intanet ba.';

  @override
  String get captionsCardOpen => 'Buɗe rubutun magana';

  @override
  String get desktopPreview =>
      'Samfoti: injin tacewa bai haɗu a wannan kwamfuta ba tukuna. Maɓallin yana nuna yadda manhajar za ta yi aiki ne kawai.';

  @override
  String actionFailed(String details) {
    return 'Hakan bai yi aiki ba: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Ana tace sautin manhajojinku.';

  @override
  String get engineErrorNoPactl =>
      'Ba a sami kayan aikin sauti ba (pactl). Waaiya yana buƙatar PulseAudio, ko PipeWire tare da pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Sabar sauti ba ta aiki (PulseAudio ko PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Wannan tsari ba shi da zaman mai amfani na systemd, wanda ke gudanar da matatar sauti a bayan fage.';

  @override
  String get engineErrorNoOutput => 'Ba a sami lasifika ko belun kunne ba.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Ba a iya shigar da matatar sauti ba. Bayani:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Matatar sauti ba ta fara ba. Bayani:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Matatar sauti ta tsaya da kuskure. Bayani:\n$details';
  }

  @override
  String get autostartTitle => 'Fara lokacin shiga kwamfuta';

  @override
  String get autostartBody => 'Tace sauti da zarar kun shiga kwamfuta.';

  @override
  String get blurBodyDesktop =>
      'Yana rufe mutane da hotuna a allo, a saman kowace taga, yayin da Waaiya ke buɗe (yana aiki ko matatar sauti tana kunne ko a kashe). Yana aiki a wannan kwamfuta; ba a tura komai zuwa ko\'ina ba. Rufe tagar Waaiya yana dakatar da dusashewa.';

  @override
  String get blurFailBodyDesktop =>
      'A kunne: ana rufe dukkan allo idan kwamfutar ta yi jinkiri sosai ko dusashewa ta kasa; dannawa tana ci gaba da kaiwa tagogin da ke ƙasa. A kashe: allon yana bayyana tare da jan layi a sama.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Dusashewa tana kunne. Wannan kwamfuta tana nuna dusashewar a cikin ɗaukar allonta, don haka wurin da aka dusashe zai ci gaba da kasancewa a dusashe har sai abin da ke allo ya canza.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Dusashewa ba za ta iya nunawa a saman sauran tagogi a wannan kwamfuta ba. Bayani:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Zaɓi allonku a tagar raba allo sannan ku ba da izini. Waaiya yana tambaya sau ɗaya kawai; hoton yana zama a wannan kwamfuta.';

  @override
  String blurStatusExited(String details) {
    return 'Dusashewa ta tsaya ba zato ba tsammani. Ku kashe wani zaɓin dusashewa sannan ku sake kunna shi don sake gwadawa. Bayani:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Mai gane waƙar mata bai buɗu ba, don haka ana kashe muryoyi yayin da wannan zaɓi ke kunne.';

  @override
  String get blurStatusUncovered =>
      'Akwai allo (monitor) da dusashewa ba ta rufe ba: ba a raba shi da ita ba, ko an haɗa shi daga baya. Ku kashe wani zaɓin dusashewa sannan ku sake kunna shi, kuma ku zaɓi kowane allo a tagar raba allo.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Tsarin dusashewa ba su cikin wannan shigarwa, don haka ba za ta iya rufe komai ba; jan layi zai ci gaba da kasancewa a saman allo. Ku sake shigar da Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Abin da Waaiya ke gani a wannan kwamfuta. Ku kwafa shi ku ba wanda ke taimaka muku. Waaiya ba ya tura shi da kansa: ku ne kuke zaɓar wanda zai karɓa.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Ana ba da shawara. Idan tacewa ta tsaya da kanta (kuskure, ba ku ba), sauran manhajoji za su yi shiru har sai kun sake farawa ko kun danna Dakatar, maimakon kunna kiɗa ba tare da tacewa ba.';

  @override
  String get settingStereoBodyDesktop =>
      'A kashe: mono, wanda ke amfani da ƙarfin kwamfuta kaɗan. A kunne: yana raba gefen hagu da na dama. Idan kwamfutar ta yi jinkiri sosai don stereo, za ta koma mono da kanta.';

  @override
  String get linkEntryBodyDesktop =>
      'Liƙa mahaɗar (link) YouTube, TikTok ko Instagram don kallo da tacewa a kunne, ko don ajiye ta ba tare da kiɗa ba.';

  @override
  String get linkEntryBodyWatch =>
      'Liƙa mahaɗar (link) YouTube, TikTok ko Instagram don kallo a burauzarku da tacewa a kunne.';

  @override
  String get linkWatchNoteDesktop =>
      'Yana buɗewa a burauzarku. Waaiya yana fara kunna tacewa, don haka ana cire kiɗan a can ma.';

  @override
  String get linkFilterFailed =>
      'Tacewa ba ta fara ba, don haka ba a buɗe mahaɗar ba. Ku kunna ta a shafin Tacewa sannan ku sake gwadawa.';

  @override
  String get linkSavedVideoDesktop =>
      'A babban fayil ɗin bidiyo “Videos”: Waaiya';

  @override
  String get linkSavedAudioDesktop =>
      'A babban fayil ɗin sauti “Music”: Waaiya';

  @override
  String get linkShowInFolder => 'Nuna a babban fayil';

  @override
  String get linkSingingNote =>
      'Ana kashe waƙar mata ma, kamar yadda yake a saitunanku.';

  @override
  String get singingKeepTitle => 'Bar waƙa (gwaji)';

  @override
  String get singingKeepBody =>
      'Ana cire kayan kiɗa amma ana barin muryoyin waƙa, don haka lacca mai nashidi a ƙarƙashinta za ta riƙe muryar nashidin ma; ko hakan ya dace, zaɓinku ne.';

  @override
  String get singingKeepNoModel =>
      'Wannan sigar ba ta da tsarin waƙa, don haka sautin yana yin shiru yayin da wannan ke kunne. Ku kashe shi.';

  @override
  String get fixFilterAppsTitle => 'Manhajojin da ake ji ba tare da tacewa ba';

  @override
  String get fixFilterAppsBody =>
      'Manhajojin da kuka zaɓa a nan suna kunna sautinsu yadda yake: babu tacewa, babu shiru. Misali, manhajar kiran bidiyo, don kada kira ya yi jinkiri.';

  @override
  String get fixAddApp => 'Ƙara manhaja';

  @override
  String fixRemoveApp(Object app) {
    return 'Cire $app';
  }

  @override
  String get fixNoApps => 'Ba a zaɓi wata manhaja ba.';

  @override
  String get fixPickTitle => 'Zaɓi manhaja';

  @override
  String get fixPickEmpty => 'Ba a sami wata manhaja ba.';

  @override
  String get fixPickPlayingDesktop =>
      'Manhajojin da ke kunna sauti yanzu, da waɗanda aka riga aka zaɓa.';

  @override
  String get fixCancel => 'Soke';

  @override
  String get fixBlurAppsTitle => 'Manhajojin da babu dusashewa';

  @override
  String get fixBlurAppsBody =>
      'Babu murfi yayin da ɗaya daga cikin waɗannan manhajoji ta cika allo, misali manhajar taswira ko manhajar bankinku. Murfin suna dawowa da zarar kun bar ta, ko duk lokacin da Waaiya bai tabbata wace manhaja ake nunawa ba.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Yana buƙatar saitin sau ɗaya: ba tare da shi ba Waaiya ba zai iya gane wace manhaja ke kan allo ba, don haka dusashewa tana ci gaba a ko\'ina.';

  @override
  String get fixBlurAppsHelperMode =>
      'Mataimakin Waaiya ba ya aiki, don haka ba za a iya karanta manhajar da ke kan allo ba. Dusashewa tana ci gaba a ko\'ina har sai an sake kunna mataimakin daga shafin Saiti.';

  @override
  String get fixHandTitle => 'Rufe wuri da hannu';

  @override
  String get fixHandBody =>
      'Yayin da dusashewa ke aiki, za ku iya rufe wani ɓangare na allo da kanku, misali hoton da dusashewa ta tsallake: ku danna “Rufe wani wuri” sannan ku ja yatsanku a kansa. Zai kasance a rufe har sai kun cire shi ko dusashewa ta tsaya.';

  @override
  String get fixHandNotRunning =>
      'Ana samu yayin da dusashewa ke aiki: tacewa a kunne kuma wani zaɓin dusashewa a kunne.';

  @override
  String get fixCoverArea => 'Rufe wani wuri';

  @override
  String fixRemoveCovers(Object count) {
    return 'Cire murfin hannu ($count)';
  }

  @override
  String get fixNoteTitle => 'Rubuta kuskure';

  @override
  String get fixNoteBody =>
      'Idan Waaiya ya yi kuskure, ku danna abin da ya faru, misali “Kiɗa ya wuce”. Bayanin yana adana lokacin, manhajar da saitunan, don taimakawa a gano dalilin. Yana zama a wannan na\'ura kuma ba a taɓa aika shi ba.';

  @override
  String get fixMissedSound => 'Kiɗa ya wuce';

  @override
  String get fixWrongSound => 'An cire murya bisa kuskure';

  @override
  String get fixMissedScreen => 'Ba a rufe wani abu ba';

  @override
  String get fixWrongScreen => 'An rufe bisa kuskure';

  @override
  String fixNoted(Object count) {
    return 'An rubuta. Bayanai a wannan na\'ura: $count.';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Bayanai a wannan na\'ura: $count';
  }

  @override
  String get fixNotesShow => 'Nuna bayanan';

  @override
  String get fixNotesDelete => 'Share bayanan';

  @override
  String get fixNotesDeleteAsk =>
      'A share dukkan bayanan? Ba za a iya dawo da su ba.';

  @override
  String get fixNotesTitle => 'Bayanan kurakurai';

  @override
  String get worshipTitle => 'Lokutan salla';

  @override
  String get worshipBody =>
      'Na zaɓi ne. Ana lissafa su a wannan waya daga wurin da kuka zaɓa. Ba a aika komai.';

  @override
  String worshipPlace(Object place) {
    return 'Wuri: $place';
  }

  @override
  String get worshipPlaceNone => 'Wuri: ba a zaɓa ba';

  @override
  String get worshipChoose => 'Zaɓi';

  @override
  String get worshipPlaceSearch => 'Nemo birni';

  @override
  String get worshipPlaceNoMatch =>
      'Ba a sami birni ba. Kuna iya shigar da lambobin wuri (latitude da longitude) maimakon haka.';

  @override
  String get worshipPlaceCustom => 'Shigar da lambobin wuri';

  @override
  String get worshipLat => 'Latitude (arewa +, kudu −)';

  @override
  String get worshipLon => 'Longitude (gabas +, yamma −)';

  @override
  String get worshipZone => 'Yankin lokaci, misali Africa/Lagos';

  @override
  String get worshipCustomInvalid => 'Ku duba lambobin da yankin lokacin.';

  @override
  String get worshipPlaceInvalid =>
      'Ba za a iya amfani da wannan wurin ba. Ku sake zaɓar sa.';

  @override
  String worshipMethod(Object method) {
    return 'Lissafi: $method';
  }

  @override
  String get worshipMethodTitle => 'Hanyar lissafi';

  @override
  String get worshipMethodNote =>
      'An zaɓa daga ƙasar birnin. Ku zaɓi wadda masallacinku ke bi.';

  @override
  String worshipAsr(Object rule) {
    return 'La\'asar: $rule';
  }

  @override
  String get worshipAsrTitle => 'Lokacin La\'asar';

  @override
  String get worshipAsrStandard => 'Mafi rinjaye (Shafi\'i, Maliki, Hanbali)';

  @override
  String get worshipAsrHanafi => 'Hanafi';

  @override
  String get worshipMethodMwl =>
      'Ƙungiyar Musulmi ta Duniya (Muslim World League)';

  @override
  String get worshipMethodIsna =>
      'Ƙungiyar Musulunci ta Arewacin Amurka (ISNA)';

  @override
  String get worshipMethodEgypt => 'Babbar Hukumar Safiyo ta Masar';

  @override
  String get worshipMethodUmmAlQura => 'Ummul Qura, Makka';

  @override
  String get worshipMethodKarachi =>
      'Jami\'ar Ilimin Addinin Musulunci, Karachi';

  @override
  String get worshipMethodTehran => 'Cibiyar Geophysics, Jami\'ar Tehran';

  @override
  String get worshipMethodGulf => 'Yankin Gulf';

  @override
  String get worshipMethodKuwait => 'Kuwaiti';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turkiyya (Diyanet)';

  @override
  String get worshipMethodFrance => 'Faransa (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Maroko (Ma\'aikatar Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesiya (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malesiya (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Yau';

  @override
  String get worshipNoTimes =>
      'Babu lokutan salla a nan yau: rana ba ta fitowa ko ba ta faɗuwa.';

  @override
  String get worshipSilentTitle => 'Shiru a lokutan salla';

  @override
  String get worshipSilentBody =>
      'A kowane lokacin salla wayar tana yin shiru (“Do Not Disturb”) na mintunan da ke ƙasa, sannan ta koma yadda take. Misali, daga Azahar ƙarfe 12:00 zuwa 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Shiru na: minti $minutes';
  }

  @override
  String get worshipMuteTitle => 'Kashe sautin media a lokacin kiran salla';

  @override
  String get worshipMuteBody =>
      'A kowane lokacin salla, ana kashe sautin media (bidiyo, kiɗa, wasanni) na mintunan da ke ƙasa. Sanarwar za ta iya dawo da sautin nan take.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'An kashe na: minti $minutes';
  }

  @override
  String get worshipMinutesTitle => 'Tsawon lokaci';

  @override
  String worshipMinutesOption(Object minutes) {
    return 'minti $minutes';
  }

  @override
  String get worshipNeedPlace => 'Ku fara zaɓar wuri.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Na gaba: $prayer a $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Shiru har zuwa $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'An kashe media har zuwa $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Ku ba Waaiya izinin canza “Do Not Disturb”, in ba haka ba wayar ba za ta iya yin shiru ba.';

  @override
  String get worshipAllow => 'Ba da izini';

  @override
  String get worshipExactNeeded =>
      'Ba a ba Waaiya izinin ƙararrawa da tunatarwa ba, don haka kowane canji zai iya jinkiri har minti 10, ko fiye yayin da wayar ke barci.';

  @override
  String get worshipNotificationsNeeded =>
      'Sanarwa a kashe take: ba za ku ga lokacin da wayar ta yi shiru ko ta dawo ba.';

  @override
  String get worshipTonesTitle => 'Sautin kira da na sanarwa marasa kiɗa';

  @override
  String get worshipTonesBody =>
      'Waaiya ba zai iya tace sautin kira ko na sanarwa ba, sai dai ya maye gurbinsu. Zaɓi sauti mara kiɗa:';

  @override
  String worshipToneRing(Object number) {
    return 'Sautin kira mara kiɗa $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Sautin sanarwa mara kiɗa $number';
  }

  @override
  String get worshipTonePlay => 'Kunna';

  @override
  String get worshipToneSet => 'Yi amfani';

  @override
  String get worshipToneInUse => 'Ana amfani';

  @override
  String get worshipToneDone => 'An gama.';

  @override
  String get worshipTonePermission =>
      'Ku ba Waaiya izinin gyara saitunan tsarin, ku dawo, sannan ku sake taɓawa.';

  @override
  String get worshipToneFailed =>
      'Wannan waya ba ta bar Waaiya ya canza shi ba. A saitunan Sauti (Sound), zaɓi sautin mai suna “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Buɗe saitunan Sauti';

  @override
  String get worshipSmsTitle => 'Amsa kira ta SMS lokacin salla';

  @override
  String get worshipSmsBody =>
      'A mintunan shiru bayan kowane lokacin salla, kiran da aka bar shi yana ƙara yana samun SMS ɗaya. Sau ɗaya ga kowace lamba a kowace salla; ba a taɓa aikawa zuwa ɓoyayyun lambobi ko gajerun lambobi ba.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Bayan: daƙiƙa $seconds na ƙara';
  }

  @override
  String get worshipSmsDelayTitle => 'Daƙiƙun ƙara kafin SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return 'daƙiƙa $seconds';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Saƙo: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Saƙonku';

  @override
  String get worshipSmsTextDefault => 'Yi amfani da na asali';

  @override
  String get worshipSmsCost =>
      'Kowace amsa SMS ce ta yau da kullum daga SIM ɗinku, a farashin tsarinku. Ba a aika komai yayin yawo (roaming).';

  @override
  String get worshipSmsRoaming => 'Ana yawo (roaming) yanzu: ba a aika SMS.';

  @override
  String get worshipSmsLogTitle =>
      'Amsoshin da aka aika (ana adana su a wannan waya kawai)';

  @override
  String get worshipContinue => 'Ci gaba';

  @override
  String get worshipWhyDnd =>
      'Don wayar ta yi shiru a lokutan salla, ku ba Waaiya damar “Do Not Disturb” a shafi na gaba.';

  @override
  String get worshipWhyExact =>
      'Don yin aiki daidai a kan lokaci, ku ba Waaiya izinin saita ƙararrawa da tunatarwa a shafi na gaba. Ba tare da shi ba, canje-canje za su iya jinkiri har minti 10.';

  @override
  String get worshipWhyNotifications =>
      'Ku ba da izinin sanarwa don ku ga kowane canji kuma ku iya soke shi.';

  @override
  String get worshipWhyWrite =>
      'Don canza sautin kira ko na sanarwa, ku ba Waaiya izinin gyara saitunan tsarin a shafi na gaba.';

  @override
  String get worshipWhyPhone =>
      'Don sanin cewa kira yana ƙara da lambarsa, Waaiya yana buƙatar izinin Waya (Phone) da Bayanan kira (Call logs). Babu abin da ke barin wayar sai amsarku.';

  @override
  String get worshipWhySms =>
      'Don aika amsarku, Waaiya yana buƙatar izinin aika SMS. Yana aika wannan amsar kawai, ba fiye da sau ɗaya ga kowace lamba a kowace salla ba.';

  @override
  String get worshipMissingDnd =>
      'Ba a ba da damar “Do Not Disturb” ba, don haka shirun yana nan a kashe.';

  @override
  String get worshipMissingPhone =>
      'Ba a ba da izinin Waya da Bayanan kira ba, don haka amsar SMS tana nan a kashe.';

  @override
  String get worshipMissingSms =>
      'Ba a ba da izinin aika SMS ba, don haka amsar SMS tana nan a kashe.';

  @override
  String get worshipTryAgain => 'Sake gwadawa';

  @override
  String get protectTitle => 'Kariya don lokutan rauni';

  @override
  String get protectBody =>
      'Don lokacin rauni da za ku so kashe tacewa. Ku zaɓi lokacin jira yanzu, cikin natsuwa: sai maɓallin tsayawa ba zai dakatar da tacewa nan take ba, kuma za ku sake yanke shawara idan lokacin ya ƙare. Iyaye ma za su iya saka PIN.';

  @override
  String protectDelay(Object value) {
    return 'Jira kafin kashewa: $value';
  }

  @override
  String get protectDelayTitle => 'Jira kafin kashewa';

  @override
  String get protectDelayBody =>
      'Misali, da minti 30: kuna danna maɓallin tsayawa, amma tacewa tana ci gaba da aiki. Bayan minti 30, wannan shafi zai tambaye ku ko har yanzu kuna son dakatarwa. Ku danna “Tabbatar” cikin minti 15 sai ta tsaya; in ba haka ba babu abin da zai canza. Haka nan ma kashe murfi ko wata kariya. Kunna abubuwa koyaushe yana aiki nan take.';

  @override
  String get protectDelayOff => 'Babu';

  @override
  String get protectDelay1m => 'Minti 1';

  @override
  String get protectDelay5m => 'Minti 5';

  @override
  String get protectDelay15m => 'Minti 15';

  @override
  String get protectDelay30m => 'Minti 30';

  @override
  String get protectDelay1h => 'Awa 1';

  @override
  String get protectDelay4h => 'Awa 4';

  @override
  String get protectDelay24h => 'Awa 24';

  @override
  String protectDelayOther(Object minutes) {
    return 'Minti $minutes';
  }

  @override
  String get protectPinNone => 'PIN: ba a saita ba';

  @override
  String get protectPinIsSet => 'PIN: an saita';

  @override
  String get protectPinSet => 'Saita PIN';

  @override
  String get protectPinRemove => 'Cire';

  @override
  String get protectPinBody =>
      'Da PIN, dakatar da tacewa ko kashe kowace kariya yana neman PIN da farko. Misali, iyaye suna saka PIN don kada yaro ya iya kashe tacewa a Waaiya (abin da ba zai iya hanawa ba yana ƙasa). Canza lokacin jira ko PIN ma yana neman sa.';

  @override
  String get protectPinForgot =>
      'Ku rubuta PIN a wuri mai aminci: idan an manta shi, babu hanyar sake saita shi. Hanya ɗaya kawai ita ce a share bayanan Waaiya ko a sake shigar da shi, wanda kuma ke share dukkan saitunansa.';

  @override
  String get protectPinTitle => 'Shigar da PIN';

  @override
  String get protectPinNewTitle => 'Zaɓi PIN';

  @override
  String get protectPinChangeTitle => 'Canza PIN';

  @override
  String get protectPinCurrent => 'PIN na yanzu';

  @override
  String get protectPinNew => 'Sabon PIN (lambobi 4 zuwa 8)';

  @override
  String get protectPinAgain => 'Sake rubuta sabon PIN';

  @override
  String get protectPinBad => 'Yi amfani da lambobi 4 zuwa 8.';

  @override
  String get protectPinDiffer => 'Sababbin PIN ɗin biyu ba ɗaya suke ba.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN ba daidai ba ne. Sauran gwaji kafin a ɗan dakata: $count.';
  }

  @override
  String protectLocked(Object time) {
    return 'Kuskure ya yi yawa. Sake gwadawa a $time.';
  }

  @override
  String get protectOk => 'To';

  @override
  String get protectCancel => 'Soke';

  @override
  String get protectCancelChange => 'Soke canjin';

  @override
  String get protectConfirm => 'Tabbatar';

  @override
  String protectPending(Object time, Object what) {
    return '$what: ana jira har $time. Sannan ku tabbatar a “Saituna”.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: jira ya ƙare. Har yanzu kuna so? Ku danna “Tabbatar” kafin $time; in ba haka ba babu abin da zai canza.';
  }

  @override
  String get protectWaitTitle => 'Wannan canjin yana jira';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what ba zai faru yanzu ba. A $time, idan har yanzu kuna so, ku tabbatar a “Saituna” cikin minti 15. Idan ba ku yi komai ba, babu abin da zai canza.';
  }

  @override
  String get protectWaitStart => 'Fara jira';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Ana jira tuni har $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Ana jira har $time. Sannan ku tabbatar a “Saituna”.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'gobe da ƙarfe $time';
  }

  @override
  String get protectHeldBack =>
      'Ba yanzu ba: saitunan kariyarku suna sa wannan canjin ya jira, ko kuma suna neman PIN.';

  @override
  String get protectLimits =>
      'Abin da wannan ba zai iya hanawa ba: sake kunna waya (tacewa ba ta sake farawa da kanta ba), tilasta tsayawa (force stop), cire manhajar, share bayanan Waaiya da saitunan Android na kansa. Hana waɗannan zai buƙaci izini na musamman na Android waɗanda Waaiya ba ya amfani da su. Wannan yana kare ku daga lokacin rauni, ba daga mutumin da ya ƙudura ba.';

  @override
  String get protectLimitsDesktop =>
      'Abin da wannan ba zai iya hanawa ba: umarnin waaiya a terminal, cire Waaiya ko share babban fayil ɗin saitunansa. Wannan yana kare ku daga lokacin rauni, ba daga mutumin da ya ƙudura ba.';

  @override
  String get protectLimitsWindows =>
      'Abin da wannan ba zai iya hanawa ba: umarnin waaiya-filter.exe a terminal, cire Waaiya ko share babban fayil ɗin saitunansa. Wannan yana kare ku daga lokacin rauni, ba daga mutumin da ya ƙudura ba.';

  @override
  String get protectWhatStop => 'Dakatar da tacewa';

  @override
  String protectWhatOff(Object name) {
    return 'Kashe: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Kunna: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Ƙara manhaja zuwa: $name';
  }

  @override
  String get protectWhatStrictness => 'Sassauta dusashewa';

  @override
  String get protectWhatGender => 'Canza wanda ke amfani da Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'Canja jira kafin kashewa zuwa: $value';
  }

  @override
  String get protectWhatPinChange => 'Canza PIN';

  @override
  String get protectWhatPinClear => 'Cire PIN';

  @override
  String get protectWhatSetting => 'Canza saiti';

  @override
  String get onboardBodyDesktop =>
      'Waaiya yana cire kayan kiɗa daga sautin manhajojin da ke wannan kwamfuta. Ana barin magana da karatun Alƙur\'ani. Ana cire muryoyin waƙa ma.';

  @override
  String get worshipUseLocation => 'Yi amfani da wurina';

  @override
  String get worshipWhyLocation =>
      'Don gano lokutan sallah a inda kake, Waaiya na karanta kimanin wurin wannan waya sau ɗaya, yanzu. Ana ajiye shi a waya a matsayin wurinka, ba a aika shi ko\'ina.';

  @override
  String get worshipLocating => 'Ana neman inda kake…';

  @override
  String get worshipLocationDenied =>
      'Ba a ba da izinin wuri ba. Za ka iya neman garinka maimakon haka.';

  @override
  String get worshipLocationOff =>
      'An kashe wuri a wannan waya. Kunna shi ka sake gwadawa, ko ka nemi garinka.';

  @override
  String get worshipLocationSettings => 'Saitunan wuri';

  @override
  String get worshipLocationFailed =>
      'Ba a sami wurinka ba. Sake gwadawa nan ba da jimawa ba, ko ka nemi garinka.';

  @override
  String worshipPlaceNear(Object city) {
    return 'kusa da $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Lokutan da aka lissafa don su dace da jadawalin Ma\'aikatar Habous da Harkokin Musulunci na $city.';
  }

  @override
  String get trayOpen => 'Buɗe Waaiya';

  @override
  String get trayQuit => 'Fita';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows ba ya barin Waaiya ta fara lokacin shiga. Kunna Waaiya a Settings › Apps › Startup, sannan ka sake kunna wannan.';

  @override
  String get engineErrorAutostartPolicy =>
      'Saitunan wannan kwamfuta, waɗanda mai kula da ita ya zaɓa, ba sa barin Waaiya ta fara lokacin shiga.';

  @override
  String get notifTextTitle => 'Nuna rubutun sanarwa yayin tacewa';

  @override
  String get notifTextBody =>
      'Android tana ɓoye abin da sanarwa ke faɗi yayin da wata manhaja ke ɗaukar dukan allo, kuma tacewa tana cikin haka. A kunne: Waaiya tana cire wannan kariya ne kawai yayin tacewa, don ka karanta sanarwarka. Yayin da aka cire ta, wani raba allo da aka yi a lokaci guda ma zai iya nuna sanarwarka da lambobinka ga wasu.';

  @override
  String get notifTextNextStart =>
      'Dakatar da tacewa ka sake farawa domin wannan canji ya yi aiki.';

  @override
  String get notifTextRefused =>
      'Wannan waya ta ƙi canjin. Kunna “Kashe kariyar raba allo” da kanka a cikin Zaɓuɓɓukan masu haɓakawa.';

  @override
  String get notifTextByHand =>
      'Ana nunawa: kariyar Android a kashe take a cikin Zaɓuɓɓukan masu haɓakawa (“Kashe kariyar raba allo”). Za ta kasance a kashe ga kowane raba allo har sai ka sake kunna ta a can.';

  @override
  String get notifTextHowTo =>
      'Android tana ɓoye abin da sanarwa ke faɗi yayin da Waaiya ke tacewa. Bayan saitin sau ɗaya, Waaiya tana nuna su: tana cire wannan kariya yayin tacewa kawai.';

  @override
  String get notifTextOpenDev => 'Buɗe Zaɓuɓɓukan masu haɓakawa';

  @override
  String get notifTextLockNote =>
      'A wannan waya Android tana dakatar da tacewa idan an kulle allo, sauran manhajoji kuma su yi shiru har sai ka taɓa Ci gaba. Saitin yana hana hakan ma.';

  @override
  String get notifTextHandOptional =>
      'Na zaɓi, ba tare da saiti ba: kunna “Kashe kariyar raba allo” a cikin Zaɓuɓɓukan masu haɓakawa. Daga nan za ta kasance a kashe ga kowane raba allo, kuma wasu wayoyi ba su da ita.';

  @override
  String get notifTextForced =>
      'A kunne: a wannan waya Android tana tambaya kafin kowace farawa, kuma da za ta dakatar da tacewa duk lokacin da aka kulle allo. Waaiya tana cire wannan kariya yayin tacewa, don haka rubutun sanarwa ma yana bayyana. Yayin da aka cire ta, wani raba allo da aka yi a lokaci guda ma zai iya nuna sanarwarka da lambobinka ga wasu.';

  @override
  String get oneAppTitle => 'A farawa: “Raba manhaja ɗaya”, sannan Waaiya';

  @override
  String get oneAppBody =>
      'Idan Android ta tambayi abin da za a raba, zaɓi “Raba manhaja ɗaya”, sannan Waaiya. Sauran manhajoji za su ci gaba da tacewa, sanarwa za su kasance a karanta, kuma tacewa za ta ci gaba idan an kulle allo. Da dukan allo, Android tana ɓoye rubutun sanarwa kuma tana dakatar da tacewa a kowace kullewa.';

  @override
  String get oneAppPair =>
      'Domin Waaiya ta yi aiki gaba ɗaya, haɗa ta sau ɗaya da Wireless debugging a shafin Saiti: daga nan ana kashe kiɗan asali ma, kuma Android ta daina tambaya a kowace farawa.';

  @override
  String get notifTextOneApp =>
      'Ana nunawa idan ka zaɓi “Raba manhaja ɗaya”, sannan Waaiya, a farawa. Da dukan allo Android tana ɓoye shi; bayan saitin sau ɗaya Waaiya tana cire hakan yayin tacewa.';

  @override
  String get blurNeedsRestart =>
      'Dakatar da tacewa ka sake farawa don amfani da dushewa: tana buƙatar dukan allo, kuma wannan tacewa ta fara ne da zaɓin “Raba manhaja ɗaya”.';

  @override
  String get micOpenSettings =>
      'Buɗe saitunan Waaiya don ba da izinin makirufo';

  @override
  String get keepRunningTitle => 'Bar Waaiya yana aiki';

  @override
  String get keepRunningBattery =>
      'Wannan waya na iya rufe Waaiya bayan ɗan lokaci don adana baturi, sai tacewa ta tsaya. A saitunan Waaiya, ƙarƙashin Baturi, zaɓi “Babu iyaka”. A Xiaomi, Redmi da POCO: “Babu ƙuntatawa”, kuma kunna Farawa da kanta.';

  @override
  String get keepRunningNotifications =>
      'Sanarwar Waaiya a kashe take, don haka ba za ta iya gaya maka lokacin da tacewa ta tsaya ba. Kunna su a saitunan Waaiya.';

  @override
  String get keepRunningOpen => 'Buɗe saitunan Waaiya';

  @override
  String get lockAskTitle => 'A ci gaba da tacewa idan an kulle allo?';

  @override
  String get lockTitle => 'A ci gaba da tacewa idan an kulle allo';

  @override
  String get lockBody =>
      'A wannan waya Android tana tambaya kafin kowane farawa, sannan ta dakatar da tacewa a duk lokacin da aka kulle allo. Waaiya na iya hana hakan ta hanyar ɗage kariyar raba allo ta Android yayin tacewa, kuma ta mayar da ita idan tacewa ta tsaya. Muddin an ɗage ta, wani raba allo a lokaci guda (kiran bidiyo, misali) zai iya nuna sanarwarka. Canji zai fara aiki a farawa ta gaba.';

  @override
  String get lockYes => 'Ci gaba da tacewa';

  @override
  String get lockNo => 'Tsaya a kowane kulle';

  @override
  String get sendToSupport => 'Aika wa Waaiya';

  @override
  String get stateTooSlowNoLinks =>
      'Wannan waya tana da jinkiri sosai don tace sauti kai tsaye, don haka sautin yana yankewa.';

  @override
  String get startNoSetupBodyNoLinks =>
      'Ba a yi saitin sau ɗaya ba tukuna. Ba tare da shi ba Waaiya ba zai iya yi wa ainihin sauti shiru ba: za ku ji kiɗan da sautin da aka tace tare.';

  @override
  String protectDelayLongAsk(String value) {
    return 'Za ka zaɓi jira na $value? Daga yanzu, kashe tacewa ko kowace kariya zai jira $value, haka ma rage wannan jiran.';
  }

  @override
  String get keepRunningKilled =>
      'Android ta rufe Waaiya yayin da take tacewa, don haka ba a ƙara tace sautin ba.';
}
