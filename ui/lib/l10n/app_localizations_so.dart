// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppLocalizationsSo extends AppLocalizations {
  AppLocalizationsSo([String locale = 'so']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Waxay ka saartaa qalabka muusigga barnaamij kasta, waxayna ka tagtaa hadalka iyo akhriska Qur\'aanka.';

  @override
  String get onboardTitle => 'Soo dhawoow';

  @override
  String get onboardBody =>
      'Waaiya waxay ka saartaa qalabka muusigga codka barnaamij kasta oo taleefankan ku jira. Hadalka iyo akhriska Qur\'aanka waa la hayaa. Hadda, codadka heesaha sidoo kale waa la saaraa.';

  @override
  String get onboardQuestion => 'Waxaan ahay';

  @override
  String get genderMan => 'Nin';

  @override
  String get genderWoman => 'Haweeney';

  @override
  String get onboardWhy =>
      'Tani waxay go\'aamisaa oo kaliya dejinta ikhtiyaariga ah ee aad aragto. Tusaale ahaan, “Aamusii heesaha haweenka” waxaa la siiyaa ragga oo kaliya. Hadhow waad beddeli kartaa.';

  @override
  String get stateOnTitle => 'Shaandhayntu way daaran tahay';

  @override
  String get stateOffTitle => 'Shaandhayntu way damsan tahay';

  @override
  String get stateStarting => 'Waa la bilaabayaa…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Qalabka muusigga waa laga saaray dhammaan barnaamijyada. Codku wuxuu daahaa qiyaastii $delayMs ms (1000 ms waa hal ilbiriqsi).';
  }

  @override
  String get stateOffDetail => 'Taabo badhanka si aad u bilowdo.';

  @override
  String get stateModelFailed =>
      'Moodeelka codka lama soo shubi karin, sidaas darteed codka waa la aamusiiyay badbaado awgeed.';

  @override
  String get stateCaptureDenied =>
      'Ogolaanshaha makarafoonka ayaa loo baahan yahay si loo helo codka barnaamijyada kale.';

  @override
  String get stateStoppedBySystem =>
      'Android ayaa joojisay shaandhaynta. Taabo badhanka si aad dib ugu bilowdo.';

  @override
  String get stateSilencedTitle => 'Shaandhayntu way joogsatay';

  @override
  String get stateSilenced =>
      'Shaandhayntu way joogsatay: barnaamijyada kale waa la aamusiiyay. Taabo badhanka si aad dib ugu bilowdo, ama Jooji si aad u maqasho iyagoo aan la shaandheyn.';

  @override
  String get releaseSilence =>
      'Jooji: maqal barnaamijyada iyagoo aan la shaandheyn';

  @override
  String get powerStartCd => 'Bilow shaandhaynta';

  @override
  String get powerStopCd => 'Jooji shaandhaynta';

  @override
  String get captureHint =>
      'Android waxay ku weydiin doontaa inaad wadaagto shaashaddaada. Codka oo kaliya ayaa la isticmaalaa: waxba lama duubo, waxna lama diro.';

  @override
  String get needRecordAudio =>
      'Waaiya waxay u baahan tahay ogolaanshaha makarafoonka si ay u hesho codka barnaamijyada kale. Marnaba ma duubto codkaaga.';

  @override
  String get setupBannerTitle => 'Hal tallaabo oo kale';

  @override
  String get setupBannerBody =>
      'Haddii aadan samayn habaynta hal mar ah ee hoose, waxaad wada maqli doontaa muusigga iyo codka la shaandheeyay.';

  @override
  String get step1Title => 'Rakib Shizuku';

  @override
  String get step1Body =>
      'Barnaamij caawiye ah oo bilaash ah, oo ku jira Play Store.';

  @override
  String get step1Action => 'Soo deji Shizuku';

  @override
  String get step2Title => 'Bilow Shizuku';

  @override
  String get step2Body =>
      'Shizuku waxay ku bilaabataa Wi-Fi iyadoo adeegsanaysa cilad-baadhista bilaa-siligga ah ee Android (“Wireless debugging”). Taabo badhanka si aad u aragto tallaabooyinka, kadibna halkan ku soo noqo.';

  @override
  String get step2Action => 'Fur Shizuku';

  @override
  String get step2Update => 'Cusbooneysii Shizuku';

  @override
  String get step2TooOld =>
      'Nuqulka Shizuku ee kuu yaal waa duug. Ka cusbooneysii Play Store.';

  @override
  String get step2Denied =>
      'Shizuku waxaa loo dejiyay inay mar walba diido Waaiya. Shizuku gudaheeda, ku ogolow Waaiya liiska barnaamijyada.';

  @override
  String get step3Title => 'Bixi ogolaansho';

  @override
  String get step3Body => 'Hal taabasho, kadibna dooro Ogolow (“Allow”).';

  @override
  String get step3Action => 'Bixi ogolaansho';

  @override
  String get step3Busy => 'Waa la habaynayaa…';

  @override
  String get setupDoneRestart =>
      'Waa la dhammeeyay. Jooji oo dib u bilow shaandhaynta hal mar si ay u shaqeyso.';

  @override
  String setupFailed(String details) {
    return 'Habayntu ma dhammaan. Faahfaahin:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Ogolaanshaha Shizuku waa la diiday. Taabo badhanka si aad mar kale isku daydo.';

  @override
  String get setupSlow =>
      'Shizuku waxay qaadanaysaa waqti ka badan sidii caadiga ahayd. Sug: taleefannada qaarkood, caawiyaheedu wuxuu qaataa ilaa hal daqiiqo si uu u bilaabmo markii ugu horreysay.';

  @override
  String get setupTimeout =>
      'Shizuku kama jawaabin 2 daqiiqo gudahood. Fur Shizuku, hubi inay leedahay way shaqaynaysaa, kadibna mar kale taabo badhanka. Haddii habayntu goor dambe dhammaato, shaashaddan iskeed ayay isu cusbooneysiinaysaa.';

  @override
  String get setupRefusedXiaomi =>
      'Taleefankani wuu diiday ogolaanshaha. Xiaomi, Redmi iyo POCO, daar “USB debugging (Security settings)” gudaha doorashooyinka horumariyaha (“Developer options”) (waxay kaa codsanaysaa inaad gasho akoon Xiaomi), kadibna mar kale isku day.';

  @override
  String get setupRefusedColoros =>
      'Taleefankani wuu diiday ogolaanshaha. OPPO, OnePlus iyo realme, gudaha doorashooyinka horumariyaha (“Developer options”), daar “Disable permission monitoring” (noocyada ugu cusub waxaa la yiraahdaa “Disable system optimization”, waxaana laga yaabaa inay muuqato oo kaliya marka luqadda taleefanku tahay Ingiriis). Si aad u hesho, ka raadi “permission” gudaha dejinta taleefanka (“Settings”). Kadibna mar kale isku day.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi iyo POCO: haddii ogeysiisku aanu lahayn meel lagu qoro koodhka, qaabka ogeysiisyada u beddel “Android” gudaha dejinta ogeysiisyada, ama koodhka ku qor Waaiya adigoo isticmaalaya shaashad qaybsan (split screen).';

  @override
  String get stepDoneCd => 'Waa la dhammeeyay';

  @override
  String stepTodoCd(int step) {
    return 'Tallaabada $step';
  }

  @override
  String get computerToggle => 'Isticmaal kombiyuutar beddelkeeda';

  @override
  String get computerWeb =>
      'Habka ugu fudud: kombiyuutar ka fur waaiya.mssid.org/usb adigoo isticmaalaya Chrome ama Edge, daar “USB debugging”, kadibna taleefanka ku xir xadhig (cable). Wax lama rakibayo, waxayna ku shaqaysaa Android 10 sidoo kale. Ama, haddii adb ku rakiban yahay:';

  @override
  String get computerBody =>
      'Daar “USB debugging”, taleefanka ku xir kombiyuutarka oo socodsii:';

  @override
  String get copy => 'Koobiyee';

  @override
  String get copied => 'Waa la koobiyeeyay';

  @override
  String get computerNote =>
      'Sadarka labaad waa ikhtiyaari: wuxuu joojiyaa su\'aasha wadaagista shaashadda ee bilow kasta.';

  @override
  String get settingsTitle => 'Dejinta';

  @override
  String get settingSilenceTitle => 'Aamusii barnaamijyada diida shaandhaynta';

  @override
  String get settingSilenceBody =>
      'Waa lagu talinayaa. Barnaamijyada qaarkood ma oggola in codkooda la shaandheeyo; tani way aamusiisaa halkii muusiggu ka gudbi lahaa.';

  @override
  String get settingHoldSilenceTitle =>
      'Barnaamijyada aamusan ku hay haddii shaandhayntu iskeed u joogsato';

  @override
  String get settingHoldSilenceBody =>
      'Waa lagu talinayaa. Haddii Android ay joojiso shaandhaynta (adiga ma aha), barnaamijyada kale way aamusnaanayaan ilaa aad dib u bilowdo ama aad taabato Jooji, halkii ay muusig aan la shaandheyn daari lahaayeen. Waxay u baahan tahay habaynta hal mar ah.';

  @override
  String get settingStereoTitle => 'Cod stereo ah';

  @override
  String get settingStereoBody =>
      'Damsan: mono, oo isticmaala qiyaastii kala badh batariga, kuna socda taleefanno badan. Daaran: wuxuu kala ilaaliyaa dhinaca bidix iyo midig. Haddii taleefanku aad ugu gaabis yahay stereo, iskiis ayuu ugu wareegaa mono.';

  @override
  String get settingSingingTitle => 'Aamusii heesaha haweenka';

  @override
  String get settingSingingBody =>
      'Tusaale ahaan, hees ay haweeney qaadayso waa la aamusiyaa, laakiin haweeney hadal jeedinaysa weli waa la maqlaa.';

  @override
  String get settingSingingNoModel =>
      'Noocan ma laha aaladda garata heesaha, sidaas darteed dhammaan codadka waa la aamusiiyaa inta tani daaran tahay.';

  @override
  String get settingRestart =>
      'Jooji oo dib u bilow shaandhaynta si isbeddelladu u shaqeeyaan.';

  @override
  String get settingGenderTitle => 'Waxaan ahay';

  @override
  String get change => 'Beddel';

  @override
  String get playerTitle => 'Muuqaallo cod iyo sawir isku dhigma';

  @override
  String get playerBody =>
      'Muuqaal la wadaag Waaiya (ama isticmaal ku fur “Open with”) si aad u daawato isagoo la shaandheeyay, dib u dhac la\'aan.';

  @override
  String get licences => 'Shatiyada isha furan';

  @override
  String get licencesIntro =>
      'Waaiya waa barnaamij xor ah oo hoos yimaada GNU Affero General Public License v3 ama mid ka dambeeya. Koodhka isha: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (xogta tababarka): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Qoraallada oo dhammaystiran';

  @override
  String get back => 'Dib u noqo';

  @override
  String get linkEntryTitle => 'Fur link';

  @override
  String get linkEntryBody =>
      'Dhaji link YouTube, TikTok ama Instagram si aad u daawato ama aad u kaydiso muusig la\'aan.';

  @override
  String get linkTitle => 'Fur link';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Link muuqaal ama cod';

  @override
  String get linkPaste => 'Dhaji';

  @override
  String get linkOpen => 'Fur';

  @override
  String get linkResolving => 'Link-ga waa la furayaa…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Daawo muusig la\'aan';

  @override
  String get linkSave => 'Kaydi muusig la\'aan';

  @override
  String get linkListen => 'Dhageyso muusig la\'aan';

  @override
  String get linkAudioOnly =>
      'Muuqaalka link-gan weli lama furi karo: codkiisa oo kaliya.';

  @override
  String get linkDownloading => 'Waa la soo dejinayaa…';

  @override
  String get linkFiltering => 'Muusigga waa la saarayaa…';

  @override
  String get linkCancel => 'Ka noqo';

  @override
  String get linkCancelled => 'Waa laga noqday. Waxba lama kaydin.';

  @override
  String get linkTimedOut =>
      'Android ayaa joojisay kaydinta: shaqadan noocan ah waxay ogolaataa oo kaliya dhowr saacadood maalintii. Waxba lama kaydin; fur Waaiya oo mar kale isku day.';

  @override
  String get linkExportFailed => 'Kan lama kaydin karin. Waxba lama kaydin.';

  @override
  String get linkSaved => 'Waa la kaydiyay iyadoo muusig la\'aan ah';

  @override
  String get linkSavedVideo => 'Gallery-gaaga: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Muusiggaaga: Music › Waaiya';

  @override
  String get linkPlay => 'Daar';

  @override
  String get linkShare => 'Wadaag';

  @override
  String get linkShareNote =>
      'Wadaag oo kaliya muuqaallada laguu ogol yahay inaad wadaagto.';

  @override
  String get linkLive => 'Baahinta tooska ah lama kaydin karo.';

  @override
  String get linkBusy =>
      'Muuqaal kale ayaa la kaydinayaa. Fadlan sug inta uu dhammaanayo.';

  @override
  String get linkInvalid =>
      'Fadlan dhaji link websaydh (oo ka bilaabma https://).';

  @override
  String get linkLogin =>
      'Websaydhku ma muujin muuqaalkan akoon la\'aan. Qoraallada dadweynaha badanaa way furmaan: mar kale isku day dhowr daqiiqo kadib. Qoraallada gaarka ah lama furi karo.';

  @override
  String get linkUnsupported => 'Websaydhkan lama taageero.';

  @override
  String get linkPlaylist =>
      'Kani waa liis muuqaallo (playlist). Fadlan fur hal muuqaal.';

  @override
  String get linkNoFormat =>
      'Muuqaalkan kuma jiro qaab ay Waaiya weli shaandheyn karto.';

  @override
  String get linkFailed =>
      'Link-gan lama furi karin. Hubi internetkaaga oo mar kale isku day.';

  @override
  String get linkPlayFailed =>
      'Tan lama daari karin. Waxba lama daarin iyadoo aan la shaandheyn.';

  @override
  String get linkLimited =>
      'Websaydhku hadda wuu xaddidayaa codsiyada. Mar kale isku day dhowr daqiiqo kadib.';

  @override
  String get blurTitle => 'Qarinta shaashadda';

  @override
  String get blurBody =>
      'Waxay daboolaysaa dadka iyo sawirrada shaashadda, barnaamij kasta, inta shaandhayntu daaran tahay. Taleefanka ayay ka shaqaysaa; meelna waxba looma diro.';

  @override
  String get blurWomenTitle => 'Qari haweenka';

  @override
  String get blurWomenBody =>
      'Jirka oo dhan waa la daboolaa. Haddii barnaamijku uusan hubin in qofku nin yahay, isna waa la daboolaa.';

  @override
  String get blurNudityTitle => 'Qari sawirrada aan asturnayn';

  @override
  String get blurNudityBody =>
      'Qaawanaan ama dhar jirka muujiya, qof kasta ha ahaadee: shaashadda oo dhan waa la daboolaa.';

  @override
  String get blurFailTitle =>
      'Dabool shaashadda haddii qarintu aanay la jaanqaadi karin';

  @override
  String get blurFailBody =>
      'Daaran: shaashadda oo dhan waa la daboolaa marka taleefanku aad u gaabis yahay ama qarintu fashilanto. Damsan: shaashaddu way muuqanaysaa iyadoo digniin leh.';

  @override
  String get blurSetupShizuku => 'Ku ogolow Shizuku';

  @override
  String get blurSetupManual => 'Ku ogolow dejinta Android';

  @override
  String get blurStatusNeedsSetup =>
      'Si ay u qariso, Waaiya waa inay ka muuqataa barnaamijyada kale dushooda. Midda ugu fiican: “Ku ogolow Shizuku”, si taabashadaadu weli u gaarto barnaamijka ka hooseeya qarinta. Ama “Ku ogolow dejinta Android”, laakiin markaas taabashada meel la qariyay waxba ma qabato.';

  @override
  String get blurStatusNeedsOverlay =>
      'Si ay u qariso, Waaiya waa inay ka muuqataa barnaamijyada kale dushooda. Midda ugu fiican: bilow Shizuku oo Waaiya ku ogolow gudaheeda, si taabashadaadu weli u gaarto barnaamijka ka hooseeya qarinta. Ama ka ogolow “Display over other apps” dejinta Android, laakiin markaas taabashada meel la qariyay waxba ma qabato.';

  @override
  String get blurFailUnavailable =>
      'Hadda lama isticmaali karo: dabool shaashadda oo dhan ah wuxuu xannibi lahaa taabasho kasta, waadna ku xanibmi kartaa. Bilow caawiyaha Waaiya ama Shizuku (Android 12 ama ka cusub), doorashadanina way furmaysaa: daboollada markaas waxaa loo sawiraa si taabashadu uga gudubto. Ilaa markaas, marka qarintu aanay la jaanqaadi karin, shaashaddu way muuqanaysaa iyadoo digniin leh.';

  @override
  String get blurFailNeedsA11y =>
      'Hadda lama isticmaali karo: dabool shaashadda oo dhan ah wuxuu xannibi lahaa taabasho kasta, waadna ku xanibmi kartaa. Bilow Shizuku (Android 12 ama ka cusub) ama daar adeegga helitaanka (accessibility) ee “Qarinta Waaiya” (Ku ogolow Shizuku, kor), doorashadanina way furmaysaa. Ilaa markaas, shaashaddu way muuqanaysaa iyadoo digniin leh.';

  @override
  String get languageTitle => 'Luqadda';

  @override
  String settingLanguageTitle(String language) {
    return 'Luqadda: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Jooji oo dib u bilow shaandhaynta si dejinta qarintu u shaqeyso.';

  @override
  String get blurStatusStarting => 'Qarinta waa la bilaabayaa…';

  @override
  String get blurStatusOn => 'Qarintu way daaran tahay.';

  @override
  String get blurStatusOnVisible =>
      'Qarintu way daaran tahay, qaab taxaddar leh: taleefankani qarinta wuxuu ku muujiyaa sawir-qaadista shaashaddiisa, sidaas darteed meel la qariyay way qarsoonaanaysaa ilaa muuqaalku isbeddelo.';

  @override
  String get blurStatusModels =>
      'Noocan kuma jiro moodeelka qarinta ee doorashada aad dooratay.';

  @override
  String get blurStatusFailing => 'Qarintu hadda ma la jaanqaadi karto.';

  @override
  String get blurStatusNoOverlay =>
      'Qarintu kama muuqan karto barnaamijyada kale dushooda: kor ka ogolow.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Qarintu ma arki karto shaashadda. Faahfaahin:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku ma ogolaan karin:\n$details';
  }

  @override
  String get step2Guide => 'Sida loo bilaabo Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Lama isticmaali karo: noocan Android, dabool shaashadda oo dhan ah wuxuu xannibi lahaa taabasho kasta, waadna ku xanibmi kartaa (daboollada Shizuku waxay u baahan yihiin Android 12 ama ka cusub). Marka qarintu aanay la jaanqaadi karin, shaashaddu way muuqanaysaa iyadoo digniin leh.';

  @override
  String get guideTitle => 'Bilow Shizuku, tallaabo tallaabo';

  @override
  String get guideOpenDev => 'Fur “Developer options”';

  @override
  String get guideOpenShizuku => 'Fur Shizuku';

  @override
  String get guideClose => 'Xir';

  @override
  String get guideBody =>
      'Waxaad u baahan tahay Wi-Fi iyo Android 11 ama ka cusub. Isku xirka (pairing) hal mar ayaa la sameeyaa; marka taleefanka dib loo shido waxaad ku celinaysaa oo kaliya tallaabada 7.\n\n1. Taleefanka ku xir Wi-Fi.\n\n2. Daar doorashooyinka horumariyaha (“Developer options”): dejinta taleefanka (“Settings”) › “About phone” › “Software information” › taabo “Build number” 7 jeer. (Taleefannada kale: “Settings” › “About phone” › “Build number”.)\n\n3. Fur Shizuku. Haddii ay weydiiso inay muujiso ogeysiisyo, u ogolow: koodhka isku xirka waxaa lagu qoraa ogeysiis Shizuku.\n\n4. Shizuku gudaheeda, hoosta “Start via Wireless debugging”, taabo “Pairing”. Bogga furmaya, taabo “Developer options”, daar cilad-baadhista bilaa-siligga ah (“Wireless debugging”) oo ku xaqiiji “Allow”.\n\n5. Taabo erayada “Wireless debugging” (ma aha furaha daarista), kadibna “Pair device with pairing code”. Koodh 6 lambar ah ayaa soo baxaya.\n\n6. Shaashaddaas furan ku hay oo hoos u soo jiid ogeysiisyada. Marka ogeysiiska Shizuku uu yiraahdo “Pairing service found”, taabo “Enter pairing code” oo qor koodhka. Shizuku waxay sheegaysaa in isku xirku guuleystay.\n\n7. Ku noqo Shizuku oo taabo “Start” hoosta “Start via Wireless debugging”. Sug ilaa ay tiraahdo “Shizuku is running”.\n\n8. Ku soo noqo Waaiya oo taabo “Bixi ogolaansho”, kadibna “Allow”.\n\nMarka taleefanka dib loo shido, Shizuku way joogsataa: ku xir Wi-Fi, dib u daar “Wireless debugging” haddii uu damsan yahay, fur Shizuku oo taabo “Start”. Isku xir cusub looma baahna.';

  @override
  String get wsetupRouteTitle => 'Ku habee taleefankan';

  @override
  String get wsetupRouteBody =>
      'Afar tallaabo oo gaagaaban, hal mar la sameeyo. Barnaamij dheeraad ah iyo kombiyuutar midna looma baahna. Waaiya waxay calaamadisaa tallaabo kasta marka la dhammeeyo.';

  @override
  String get wizDevTitle =>
      'Daar doorashooyinka horumariyaha (“Developer options”)';

  @override
  String get wizDevBody =>
      'Gudaha macluumaadka taleefanka (“About phone”), taabo “Build number” 7 jeer, kadibna halkan ku soo noqo. Haddii aadan helin, ka raadi “Build number” gudaha dejinta taleefanka (“Settings”).';

  @override
  String get wizDevBodySamsung =>
      'Gudaha macluumaadka taleefanka (“About phone”) › “Software information”, taabo “Build number” 7 jeer, kadibna halkan ku soo noqo.';

  @override
  String get wizDevBodyXiaomi =>
      'Gudaha macluumaadka taleefanka (“About phone”), taabo “OS version” 7 jeer (taleefannada duqowga ah: “MIUI version”; qaarkood waxay ku hoos jirtaa “Detailed info and specs”), kadibna halkan ku soo noqo.';

  @override
  String get wizDevBodyColoros =>
      'Gudaha “About device” (ama “About phone”) › “Version”, taabo “Build number” 7 jeer, kadibna halkan ku soo noqo.';

  @override
  String get wizDevBodyVivo =>
      'Gudaha macluumaadka taleefanka (“About phone”), taabo “Software version” 7 jeer (taleefannada qaarkood: “Software information” › “Build number”), kadibna halkan ku soo noqo.';

  @override
  String get wizDevBodyHuawei =>
      'Gudaha macluumaadka taleefanka (“About phone”), taabo “Build number” 7 jeer, kadibna halkan ku soo noqo.';

  @override
  String get wizDevBodyTranssion =>
      'Gudaha “My phone” (ama “About phone”), taabo “Build number” 7 jeer, kadibna halkan ku soo noqo.';

  @override
  String get setupNoteHuawei =>
      'Huawei: taleefanno badan oo Huawei ah ma laha “Wireless debugging”. Haddii aadan ka helin “Developer options”, isticmaal kombiyuutar (“Habab kale” ee hoose).';

  @override
  String get wsetupFilterOn =>
      'Shaandhayntu way daaran tahay: noocan Android, koodhka laguma qori karo ogeysiis inta ay shaqaynayso. Marka hore jooji shaandhaynta, ama isticmaal shaashad qaybsan iyo “Koodhka halkan ku qor”.';

  @override
  String get wizDevSearch =>
      'Magacyadu way kala duwanaan karaan iyadoo ku xiran luqadda taleefanka: haddii aadan helin, isticmaal raadinta ku taal korka dejinta taleefanka (“Settings”).';

  @override
  String get wizDevAction => 'Fur “About phone”';

  @override
  String get wizWifiTitle => 'Ku xir Wi-Fi';

  @override
  String get wizWifiBody =>
      'Shabakad kasta oo Wi-Fi ah way ku filan tahay; internet looma baahna.';

  @override
  String get wizWifiAction => 'Fur dejinta Wi-Fi';

  @override
  String get wizWdTitle =>
      'Daar cilad-baadhista bilaa-siligga (“Wireless debugging”)';

  @override
  String get wizWdBody =>
      'Waaiya waxay ku furaysaa doorashooyinka horumariyaha (“Developer options”) meesha “Wireless debugging”. Daar oo taabo Ogolow (“Allow”).';

  @override
  String get wizWdAction => 'Fur “Developer options”';

  @override
  String get wizPairTitle => 'Qor koodhka isku xirka';

  @override
  String get wizPairBody =>
      'Taabo erayada “Wireless debugging”, kadibna “Pair device with pairing code”. 6-da lambar ku qor ogeysiiska Waaiya. Waaiya ayaa inta kale qabanaysa.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya horeyba waa loogu xiray taleefankan: koodh looma baahna. Taabo badhanka, Waaiya-na iskeed ayay u dhammaystiraysaa.';

  @override
  String get wizPairAction => 'Sii wad';

  @override
  String get wizAgain => 'Mar kale samee habaynta';

  @override
  String get setupShizukuReadyTitle =>
      'Adigoo isticmaalaya Shizuku, oo hadda shaqaynaysa';

  @override
  String get setupOtherWaysPlain => 'Habab kale oo habaynta loo sameeyo';

  @override
  String get wizSkip => 'U gudub “Wireless debugging”';

  @override
  String get setupOtherWays => 'Habab kale: Shizuku ama kombiyuutar';

  @override
  String get wsetupEnterHere => 'Koodhka halkan ku qor';

  @override
  String get wsetupCancel => 'Ka noqo';

  @override
  String get wsetupAndroid10 =>
      'Android 10 keligeed ma samayn karto habaynta: waxay u baahan tahay kombiyuutar, si toos ah (hoos) ama si Shizuku hal mar loogu bilaabo.';

  @override
  String get wsetupShizukuHeading =>
      'Ama adigoo isticmaalaya barnaamijka Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku sidoo kale waxay u oggolaataa taabashada inay ka gudubto daboollada shaashadda.';

  @override
  String get wsetupChannel => 'Habaynta hal mar ah';

  @override
  String get wsetupNotifTitle =>
      'Habaynta Waaiya: waxay sugaysaa koodhka isku xirka';

  @override
  String get wsetupFoundTitle => 'Shaashadda isku xirka waa la helay';

  @override
  String get wsetupBusyTitle => 'Habaynta Waaiya';

  @override
  String get wsetupDoneTitle => 'Habayntu way dhammaatay';

  @override
  String get wsetupDoneBody =>
      'Waaiya hadda way aamusiin kartaa codka asalka ah. Waad demin kartaa “Wireless debugging”.';

  @override
  String get wsetupDoneHelperBody =>
      'Waa la dhammeeyay. Taleefankani uma oggola barnaamijyada inay haystaan ogolaanshahan, sidaas darteed caawiyaha Waaiya ayaa aamusiya codka asalka ah. Caawiyuhu wuu joogsadaa marka taleefanka dib loo shido iyo marka Waaiya la cusbooneysiiyo. Marka aad intaas kadib furto Waaiya, iskeed ayay dib u bilaabaysaa caawiyaha haddii “Wireless debugging” daaran yahay; haddii kale, waxay muujinaysaa badhan loogu talagalay.';

  @override
  String get helperMissingTitle => 'Caawiyaha Waaiya wuu joogsaday';

  @override
  String get helperMissingBody =>
      'Taleefankani ma hayo ogolaanshaha Waaiya, sidaas darteed Waaiya waxay isticmaashaa caawiyaheeda. Caawiyuhu wuu joogsadaa marka taleefanka dib loo shido iyo marka Waaiya la cusbooneysiiyo. Ku xir Wi-Fi, daar “Wireless debugging” gudaha doorashooyinka horumariyaha (“Developer options”), kadibna taabo “Bilow caawiyaha Waaiya”.';

  @override
  String get helperChannel => 'Caawiyaha Waaiya';

  @override
  String get helperStarting => 'Caawiyaha waa la bilaabayaa…';

  @override
  String get helperModeNote =>
      'Taleefankani uma oggola barnaamijyada inay haystaan ogolaanshahan: caawiyaha Waaiya ayaa shaqada qabta. Wuu joogsadaa marka taleefanka dib loo shido iyo marka Waaiya la cusbooneysiiyo. Marka aad intaas kadib furto Waaiya, iskeed ayay dib u bilaabaysaa caawiyaha haddii “Wireless debugging” daaran yahay; haddii kale, waxay muujinaysaa badhan loogu talagalay.';

  @override
  String get helperTipXiaomi =>
      'Ikhtiyaari, si ogolaanshaha weligood loo haysto (caawiye looma baahna marka dib loo shido): gudaha doorashooyinka horumariyaha (“Developer options”), daar “USB debugging (Security settings)” (waxay kaa codsanaysaa inaad gasho akoon Xiaomi), kadibna mar kale samee habaynta.';

  @override
  String get helperTipColoros =>
      'Ikhtiyaari, si ogolaanshaha weligood loo haysto (caawiye looma baahna marka dib loo shido): gudaha doorashooyinka horumariyaha (“Developer options”), daar “Disable permission monitoring” (noocyada ugu cusub: “Disable system optimization”; waxaa laga yaabaa inay muuqato oo kaliya marka luqadda taleefanku tahay Ingiriis), kadibna mar kale samee habaynta.';

  @override
  String get stateOnHelperMissing =>
      'Codka asalka ah lama aamusiin, sidaas darteed waxaad maqlaysaa muusigga oo la socda codka la shaandheeyay: caawiyaha Waaiya wuu joogsaday. Ku xir Wi-Fi, daar “Wireless debugging”, kadibna taabo “Bilow caawiyaha Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Ama isticmaal “Ku habee taleefankan” ee boggan: caawiyaha Waaiya markaas wuu shaqeeyaa iyadoo aan furahaas loo baahnayn.';

  @override
  String get helperStartAnywayTitle => 'Caawiyaha Waaiya wuu joogsaday';

  @override
  String get helperStartAnywayBody =>
      'La\'aantiis waxaad maqli doontaa muusigga oo la socda codka la shaandheeyay. Marka hore bilow caawiyaha (“Wireless debugging” waa inuu daaran yahay), ama si kastaba u bilow shaandhaynta.';

  @override
  String get wsetupFailedTitle => 'Habayntu ma dhammaan';

  @override
  String get wsetupPairing => 'Waa la isku xirayaa…';

  @override
  String get wsetupConnecting =>
      'Waa la xirayaa, ogolaanshahana waa la bixinayaa…';

  @override
  String get wsetupNeedWifi =>
      'Marka hore ku xir shabakad Wi-Fi ah (internet looma baahna): “Wireless debugging” wuxuu ku shaqeeyaa oo kaliya Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Gudaha doorashooyinka horumariyaha (“Developer options”), daar “Wireless debugging”, kadibna taabo magaciisa iyo “Pair device with pairing code”.';

  @override
  String get wsetupOpenDialog =>
      'Gudaha “Wireless debugging”, taabo “Pair device with pairing code”. Koodhka shaashadda ku hay oo halkan ka taabo “Geli koodhka”.';

  @override
  String get wsetupEnterCodeBody =>
      'Taabo “Geli koodhka” oo qor koodhka 6 lambar ah ee ka muuqda dejinta taleefanka (“Settings”).';

  @override
  String get wsetupCodeWaiting =>
      'Koodhka waa la helay. Waxaa la sugayaa shaashadda “Pair device with pairing code”: furan ku hay.';

  @override
  String get wsetupWrongCode =>
      'Koodhkaas lama aqbalin. Hubi 6-da lambar ee shaashadda oo mar kale geli. Haddii shaashadda isku xirku xirantay, mar kale fur: koodhku wuu isbeddelaa.';

  @override
  String get wsetupPairingFailed =>
      'Isku xirku ma shaqayn. Xir shaashadda isku xirka, mar kale fur “Pair device with pairing code” oo geli koodhka cusub.';

  @override
  String get wsetupWaitingConnect =>
      'Waa la isku xiray. “Wireless debugging” daaran ku hay: Waaiya waa ku xirmaysaa.';

  @override
  String get wsetupNotPaired =>
      'Taleefankani mar dambe ma yaqaan Waaiya (isku xirka waa la tirtiray ama wakhtigiisii wuu dhacay). Fur “Pair device with pairing code” oo geli koodhka.';

  @override
  String get wsetupConnectFailed =>
      'Laguma xirmi karin “Wireless debugging”. Dami oo dib u daar: Waaiya iskeed ayay mar kale isku dayaysaa.';

  @override
  String get wsetupGrantFailed =>
      'Waa la xiray, laakiin ogolaanshaha weli way maqan yihiin. Isticmaal Shizuku ama kombiyuutar, hoos.';

  @override
  String get wsetupTimeout =>
      'Waa la joojiyay 10 daqiiqo kadib iyadoo aan la dhammayn. Mar kale ayaad isku dayi kartaa.';

  @override
  String get wsetupCodeUnreadable => 'Qor 6-da lambar ee koodhka isku xirka.';

  @override
  String get wsetupCodeHint => 'Koodh 6 lambar ah';

  @override
  String get wsetupEnterCode => 'Geli koodhka';

  @override
  String wsetupDetail(String details) {
    return 'Faahfaahin: $details';
  }

  @override
  String get wsetupErrTimeout => 'jawaab lama helin waqtigii loogu talagalay';

  @override
  String get wsetupErrRefused => 'xiriirka waa la diiday';

  @override
  String get wsetupDevOff =>
      'Doorashooyinka horumariyaha (“Developer options”) way damsan yihiin. Gudaha “About phone”, taabo “Build number” 7 jeer, kadibna soo noqo.';

  @override
  String get wsetupOpenAbout => 'Fur “About phone”';

  @override
  String get wsetupNotifOff =>
      'Ogeysiisyada waa u damsan yihiin Waaiya, sidaas darteed koodhka laguma qori karo ogeysiis. Isticmaal shaashad qaybsan (“Settings” hal dhinac, Waaiya dhinaca kale) oo taabo “Koodhka halkan ku qor”.';

  @override
  String get wsetupCodeDialogTitle => 'Koodhka isku xirka';

  @override
  String get wsetupCodeDialogBody =>
      'Kaliya marka shaashaddu qaybsan tahay (“Settings” hal dhinac, Waaiya dhinaca kale): haddii aad ka baxdo “Settings” shaashadda isku xirka way xirantaa, koodhkeeduna ma shaqeeyo. Qor koodhka 6 lambar ah ee ka muuqda hoosta “Pair device with pairing code”.';

  @override
  String get wsetupCodeOk => 'Isku xir';

  @override
  String get blurStrictTitle => 'Yaa aan la daboolin';

  @override
  String blurStrictValue(String level) {
    return 'Yaa aan la daboolin: $level';
  }

  @override
  String get blurStrict0 =>
      'Adag: kaliya dadka barnaamijku ku dhow yahay inuu hubo inay rag yihiin';

  @override
  String get blurStrict1 =>
      'Dhexdhexaad: qiyaastii laba jeer rag ka badan oo aan la daboolin';

  @override
  String get blurStrict2 => 'Fudud: rag yar oo ka badan dhexdhexaadka';

  @override
  String get blurStrict0Short => 'adag';

  @override
  String get blurStrict1Short => 'dhexdhexaad';

  @override
  String get blurStrict2Short => 'fudud';

  @override
  String get blurStrictHelp =>
      'Qof kasta oo barnaamijku aanu hubin inuu nin yahay waa la daboolaa. Adag wuxuu ka tagaa qiyaastii 7 nin 100-kii iyagoo aan la daboolin; dhexdhexaad qiyaastii 14, fudud qiyaastii 16. Heer kasta oo ka adkaan yar wuxuu sidoo kale ka tagaa qiyaastii 1 haweeney oo dheeraad ah 100-kii iyadoo aan la daboolin.';

  @override
  String get stateOnNotMuted =>
      'Codka asalka ah weli lama aamusiin, sidaas darteed waxaad maqlaysaa muusigga oo la socda codka la shaandheeyay. Dhammaystir habaynta hal mar ah ee hoose.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya ma aamusiin karto codka asalka ah ee barnaamijka hadda shaqaynaya, sidaas darteed muusigga weli waa la maqli karaa. Jooji oo dib u bilow shaandhaynta. Haddii ay sii jirto, dir warbixinta baaritaanka (hoosta shaashaddan).';

  @override
  String get stateTooSlow =>
      'Taleefankani aad buu ugu gaabis yahay inuu shaandheeyo codka tooska ah, sidaas darteed codku wuu go\'aa. “Fur link” ee hoose weli wuu shaqeeyaa: wuxuu shaandheeyaa muuqaalka ka hor inta aan la daarin.';

  @override
  String get stateMonoNote => 'Codku waa mono si taleefankani ula jaanqaado.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Waa la aamusiiyay, maxaa yeelay ma oggola shaandhaynta: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Waxaa la daarayaa iyadoo aan la shaandheyn, maxaa yeelay ma oggola shaandhaynta: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android ma siin Waaiya codka barnaamijyada kale. Taabo badhanka si aad dib ugu bilowdo.';

  @override
  String get stateCaptureCancelled =>
      'Bilowga waa laga noqday markii Android ay weydiisay wadaagista shaashadda. Waaiya waxay u baahan tahay in halkaas la doorto Bilow (“Start”) si ay u hesho codka. Waxba lama duubo, waxna lama diro.';

  @override
  String get startNoSetupTitle => 'Muusigga weli waa la maqli doonaa';

  @override
  String get startNoSetupBody =>
      'Habaynta hal mar ah weli lama samayn. La\'aanteed Waaiya ma aamusiin karto codka asalka ah: waxaad wada maqli doontaa muusigga iyo codka la shaandheeyay.\n\n“Fur link” wuu shaqeeyaa habayn la\'aan.';

  @override
  String get startNoSetupSetup => 'Samee habaynta';

  @override
  String get startNoSetupAnyway => 'Si kastaba u bilow';

  @override
  String get diagButton => 'Dhibaato? Warbixinta baaritaanka';

  @override
  String get diagTitle => 'Warbixinta baaritaanka';

  @override
  String get diagNote =>
      'Waxa Waaiya ku aragto taleefankan. Koobiyee ama la wadaag qofka ku caawinaya. Barnaamijka laftiisu waxba ma diro.';

  @override
  String get notifStoppedTitle => 'Waaiya way joogsatay';

  @override
  String get notifStoppedText =>
      'Codka mar dambe lama shaandheynayo. Taabo si aad dib ugu bilowdo.';

  @override
  String get wsetupGuide => 'Tallaabooyin sawirro leh';

  @override
  String get navFilter => 'Shaandho';

  @override
  String get navScreen => 'Shaashadda';

  @override
  String get navLinks => 'Linkiyada';

  @override
  String get navSetup => 'Habaynta';

  @override
  String get navSettings => 'Dejinta';

  @override
  String get setupDoneTitle => 'Habayntu way dhammaatay';

  @override
  String get setupDoneBody =>
      'Waaiya way aamusiin kartaa codka asalka ah ee barnaamijyada kale. Mar kale samee oo kaliya haddii wax isbeddeleen (habaynta waa laga noqday, ama Waaiya waxay sheegtay inay maqan tahay).';

  @override
  String get setupRedo => 'Mar kale muuji habaynta';

  @override
  String get setupGo => 'U gudub habaynta';

  @override
  String get helperTitle => 'Taabasho ka gudubta daboollada';

  @override
  String get helperBodyOff =>
      'Caawin la\'aan, daboolku wuxuu xannibaa taabashada ka hoosaysa. Caawiyaha Waaiya wuxuu u sawiraa daboollada si taabashadu uga gudubto. Daar “Wireless debugging” (Wi-Fi ayaa loo baahan yahay) oo taabo badhanka; markii ugu horreysay, hal mar isku xir sidii habaynta. Marka taleefanka dib loo shido, mar kale taabo.';

  @override
  String get helperStart => 'Bilow caawiyaha Waaiya';

  @override
  String get helperOn =>
      'Caawiyaha Waaiya ayaa sawira daboollada: taabashadu way ka gudubtaa. Wuu joogsadaa marka taleefanka dib loo shido ama marka “USB debugging” la damiyo; markaas mar kale taabo badhanka.';

  @override
  String get helperShizukuOn =>
      'Shizuku ayaa sawira daboollada: taabashadu way ka gudubtaa.';

  @override
  String get helperOrShizuku => 'Ama adigoo isticmaalaya Shizuku:';

  @override
  String get filterOptionsTitle => 'Doorashooyinka shaandhada';

  @override
  String get settingsGeneralTitle => 'Guud';

  @override
  String get simpleTitle => 'Simple mode (test): no Developer options';

  @override
  String get simpleBody =>
      'For phones where the setup below is too hard. While Waaiya filters, it mutes the phone\'s media sound and plays the filtered sound on another sound channel. Your volume buttons set Waaiya\'s volume. Android asks to share the screen at each start. The media sound comes back when filtering stops.';

  @override
  String get simpleSwitch => 'Use simple mode';

  @override
  String simpleChannelTitle(String channel) {
    return 'Sound channel: $channel';
  }

  @override
  String get simpleChannelAlarm => 'Alarm';

  @override
  String get simpleChannelNotification => 'Notification';

  @override
  String get simpleChannelHelp =>
      'If you hear nothing, or the sound comes from the phone\'s speaker while earphones are in, try the other channel. Notification is silent while the phone is on vibrate or Do Not Disturb.';

  @override
  String get simpleTestNote =>
      'This is a test. After trying it (speaker, earphones, Bluetooth), please send the diagnostics report from Settings.';

  @override
  String get simpleOnDetail =>
      'Simple mode (test): media sound is muted while Waaiya filters.';

  @override
  String get worshipPrayerFajr => 'Subax';

  @override
  String get worshipPrayerSunrise => 'Qorrax ka soo bax';

  @override
  String get worshipPrayerDhuhr => 'Duhur';

  @override
  String get worshipPrayerAsr => 'Casar';

  @override
  String get worshipPrayerMaghrib => 'Maqrib';

  @override
  String get worshipPrayerIsha => 'Cishe';

  @override
  String get worshipEndSilent => 'Hadda jooji aamusnaanta';

  @override
  String get worshipUnmute => 'Hadda soo celi codka';

  @override
  String get worshipSmsDefault =>
      'Waa waqtigii salaadda, hadda ma jawaabi karo. Dib ayaan kuu soo wici doonaa.';

  @override
  String get updateTitle => 'Cusboonaysiinta abka';

  @override
  String get updateAuto => 'Hubi nooc cusub hal mar maalintii';

  @override
  String get updateAutoBody =>
      'Waaiya waxay weydiisaa waaiya.mssid.org in nooc ka cusub jiro iyo in kale, waxna kale uma dirto. Waxba lama soo dejiyo ilaa aad taabato Hadda cusboonaysii.';

  @override
  String get updateCheck => 'Hadda hubi';

  @override
  String get updateChecking => 'Waa la hubinayaa…';

  @override
  String updateNone(String version) {
    return 'Waxaad haysaa noocii ugu dambeeyay ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest waa la heli karaa. Adiga waxaad haysaa $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Soo dejin: $size, kaliya waxa isbeddelay (abka oo dhan waa $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Soo dejin: $size.';
  }

  @override
  String get updateNow => 'Hadda cusboonaysii';

  @override
  String updateDownloading(String progress) {
    return 'Waa la soo dejinayaa: $progress';
  }

  @override
  String get updatePreparing => 'Cusboonaysiinta waa la diyaarinayaa…';

  @override
  String get updateInstalling =>
      'Ku xaqiiji rakibidda shaashadda uu Android muujiyo.';

  @override
  String get updateStopsFilter =>
      'Rakibiddu waxay joojisaa sifeynta. Dib u bilow cusboonaysiinta kadib.';

  @override
  String get updatePermission =>
      'U oggolow Waaiya inay rakibto cusboonaysiinteeda, kadibna mar kale taabo Hadda cusboonaysii.';

  @override
  String get updateFailed =>
      'Cusboonaysiinta lama dhammaystiri karin. Mar dambe isku day, ama ka soo dejiso shabakadda.';

  @override
  String get updateOpenPage => 'Fur bogga soo dejinta';

  @override
  String get updateCheckFailed => 'Hadda lama hubin karo. Mar dambe isku day.';

  @override
  String get moveOldTitle => 'Waaiya way guurtay';

  @override
  String get moveOldBody =>
      'Waaiya hadda waxay Android ku timaaddaa ab cusub (isla Waaiya, magac cusub), tanna wax cusboonaysiin ah ma helayso mar dambe. Rakib midda cusub: dejimahaagu way u guurayaan. Kadib samee diyaarinteeda hal mar ah oo ka saar tan.';

  @override
  String get moveOldInstalled =>
      'Waaiya cusub waa la rakibay. Fur: waxay qaadanaysaa dejimahaaga. Samee diyaarinteeda hal mar ah, kadib ka saar tan duugga ah si aanay labaduba marna isku mar u shaandhayn.';

  @override
  String get moveInstall => 'Rakib Waaiya cusub';

  @override
  String get moveOpenNew => 'Fur Waaiya cusub';

  @override
  String get moveRemoveThis => 'Ka saar Waaiya duugga ah ee tan';

  @override
  String get moveNewTitle => 'Waaiya duugga ah weli waa rakiban tahay';

  @override
  String get moveNewBody =>
      'Waaiya duugga ah (ka hor nooca 0.2.15) weli waxay ku jirtaa taleefankan. Ka saar si aanay labaduba marna isku mar u shaandhayn.';

  @override
  String get moveNewImported => 'Dejimahaaga waa laga soo qaaday.';

  @override
  String get moveRemoveOld => 'Ka saar Waaiya duugga ah';

  @override
  String get desktopPreview =>
      'Muuqaal hordhac ah: matoorka shaandhaynta weli lagama xirin kombiyuutarkan. Badhanku wuxuu kaliya muujinayaa sida barnaamijku u shaqayn doono.';

  @override
  String actionFailed(String details) {
    return 'Taasi ma shaqayn: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Qalabka muusigga waa laga saaray dhammaan barnaamijyada.';

  @override
  String get engineErrorNoPactl =>
      'Qalabka codka lama helin (pactl). Waaiya waxay u baahan tahay PulseAudio, ama PipeWire oo leh pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Server-ka codku ma shaqaynayo (PulseAudio ama PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Nidaamkan ma laha fadhi isticmaale oo systemd ah, kaas oo shaandhada ka wada gadaal.';

  @override
  String get engineErrorNoOutput =>
      'Lama helin af-hayeen (speakers) ama sameecado dhegaha.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Shaandhada lama rakibi karin. Faahfaahin:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Shaandhadu ma bilaabmin. Faahfaahin:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Shaandhadu waxay ku joogsatay khalad. Faahfaahin:\n$details';
  }

  @override
  String get autostartTitle => 'Bilow marka aad soo gasho';

  @override
  String get autostartBody =>
      'Shaandhee codka isla marka aad soo gasho kombiyuutarka.';

  @override
  String get blurBodyDesktop =>
      'Waxay daboolaysaa dadka iyo sawirrada shaashadda, daaqad kasta dusheeda, inta Waaiya furan tahay (way shaqaysaa haddii shaandhada codku daaran tahay iyo haddii kaleba). Kombiyuutarkan ayay ka shaqaysaa; meelna waxba looma diro. Xiridda daaqadda Waaiya waxay joojisaa qarinta.';

  @override
  String get blurFailBodyDesktop =>
      'Daaran: shaashadda oo dhan waa la daboolaa marka kombiyuutarku aad u gaabis yahay ama qarintu fashilanto; gujintu weli way gaartaa daaqadaha hoose. Damsan: shaashaddu way muuqanaysaa iyadoo xariiq casaan ahi ku jiro korka.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Qarintu way daaran tahay. Desktop-kani qarinta wuxuu ku muujiyaa sawir-qaadista shaashaddiisa, sidaas darteed meel la qariyay way qarsoonaanaysaa ilaa muuqaalku isbeddelo.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Qarintu kama muuqan karto daaqadaha kale dushooda desktop-kan. Faahfaahin:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Ka dooro shaashaddaada daaqadda wadaagista shaashadda oo ogolow. Waaiya hal mar oo kaliya ayay weydiisaa; sawirku kombiyuutarkan ayuu ku jiraa.';

  @override
  String blurStatusExited(String details) {
    return 'Qarintu si lama filaan ah ayay u joogsatay. Dami oo dib u daar doorasho qarin si aad mar kale isku daydo. Faahfaahin:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Aaladda garata heesaha haweenka lama soo shubin, sidaas darteed codadka waa la aamusiiyaa inta doorashadaas daaran tahay.';

  @override
  String get blurStatusUncovered =>
      'Shaashad (monitor) kama daboolna qarinta: lalama wadaagin, ama goor dambe ayaa la galiyay. Dami oo dib u daar doorasho qarin, oo ka dooro shaashad kasta daaqadda wadaagista shaashadda.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Moodeelada qarintu kuma jiraan rakibaaddan, sidaas darteed waxba ma dabooli karto; xariiq casaan ah ayaa ku hadhaya korka shaashadda. Dib u rakib Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Waxa Waaiya ku aragto kombiyuutarkan. Koobiyee oo sii qofka ku caawinaya. Barnaamijka laftiisu waxba ma diro.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Waa lagu talinayaa. Haddii shaandhayntu iskeed u joogsato (khalad, adiga ma aha), barnaamijyada kale way aamusnaanayaan ilaa aad dib u bilowdo ama aad riixdo Jooji, halkii ay muusig aan la shaandheyn daari lahaayeen.';

  @override
  String get settingStereoBodyDesktop =>
      'Damsan: mono, oo kombiyuutarka ka qaata awood yar. Daaran: wuxuu kala ilaaliyaa dhinaca bidix iyo midig. Haddii kombiyuutarku aad ugu gaabis yahay stereo, iskiis ayuu ugu wareegaa mono.';

  @override
  String get linkEntryBodyDesktop =>
      'Dhaji link YouTube, TikTok ama Instagram si aad u daawato adigoo shaandhadu daaran tahay, ama si aad u kaydiso muusig la\'aan.';

  @override
  String get linkEntryBodyWatch =>
      'Dhaji link YouTube, TikTok ama Instagram si aad ugu daawato browser-kaaga adigoo shaandhadu daaran tahay.';

  @override
  String get linkWatchNoteDesktop =>
      'Wuxuu ka furmaa browser-kaaga. Waaiya marka hore ayay bilaabaysaa shaandhada, sidaas darteed muusigga halkaasna waa laga saarayaa.';

  @override
  String get linkFilterFailed =>
      'Shaandhadu ma bilaabmin, sidaas darteed link-ga lama furin. Ka bilow bogga Shaandho oo mar kale isku day.';

  @override
  String get linkSavedVideoDesktop => 'Galkaaga muuqaallada (“Videos”): Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Galkaaga muusigga (“Music”): Waaiya';

  @override
  String get linkShowInFolder => 'Ku muuji galka';

  @override
  String get linkSingingNote =>
      'Heesaha haweenka sidoo kale waa la aamusiiyaa, sida dejintaada.';

  @override
  String get singingKeepTitle => 'Hay heesaha (tijaabo)';

  @override
  String get singingKeepBody =>
      'Qalabka muusigga waa la saarayaa laakiin codadka heesaha waa la hayaa, sidaas darteed muxaadaro uu hoos ku jiro nashiid waxay sidoo kale haysaa codka nashiidka; in taasi ay ansax tahay iyo in kale adiga ayay kuu taal.';

  @override
  String get singingKeepNoModel =>
      'Noocan ma laha moodeelka heesaha, sidaas darteed codku wuu aamusnaanayaa inta tani daaran tahay. Dami.';

  @override
  String get fixFilterAppsTitle =>
      'Barnaamijyada la maqlo iyagoo aan la shaandheyn';

  @override
  String get fixFilterAppsBody =>
      'Barnaamijyada aad halkan ka doorato codkooda sidiisa ayaa loo maqlaa: shaandhayn ma jirto, aamusinna ma jirto. Tusaale ahaan, barnaamijka wicitaannada fiidiyowga, si wicitaannadu aysan u daahin.';

  @override
  String get fixAddApp => 'Ku dar barnaamij';

  @override
  String fixRemoveApp(Object app) {
    return 'Ka saar $app';
  }

  @override
  String get fixNoApps => 'Barnaamij lama dooran.';

  @override
  String get fixPickTitle => 'Dooro barnaamij';

  @override
  String get fixPickEmpty => 'Barnaamij kale lama helin.';

  @override
  String get fixPickPlayingDesktop =>
      'Barnaamijyada hadda cod daaraya, iyo kuwa horay loo doortay.';

  @override
  String get fixCancel => 'Ka noqo';

  @override
  String get fixBlurAppsTitle => 'Barnaamijyada aan la daboolin';

  @override
  String get fixBlurAppsBody =>
      'Dabool ma jiro marka mid ka mid ah barnaamijyadan uu buuxiyo shaashadda, tusaale ahaan barnaamijka khariidadaha ama barnaamijka bangigaaga. Daboolladu way soo laabtaan isla marka aad ka baxdo, ama mar kasta oo Waaiya aysan hubin barnaamijka la muujinayo.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Waxay u baahan tahay habaynta hal mar ah: la\'aanteed Waaiya ma garan karto barnaamijka shaashadda ku jira, sidaas darteed qarintu meel walba way ku sii jirtaa.';

  @override
  String get fixBlurAppsHelperMode =>
      'Caawiyaha Waaiya ma shaqaynayo, sidaas darteed barnaamijka shaashadda ku jira lama akhrin karo. Qarintu meel walba way ku sii jirtaa ilaa caawiyaha dib looga bilaabo bogga Habaynta.';

  @override
  String get fixHandTitle => 'Gacanta ku dabool meel';

  @override
  String get fixHandBody =>
      'Inta qarintu shaqaynayso, adigu waxaad dabooli kartaa qayb ka mid ah shaashadda, tusaale ahaan sawir ay qarintu seegtay: riix “Dabool meel” oo farta ku jiid dushiisa. Way daboolnaanaysaa ilaa aad ka saarto ama qarintu joogsato.';

  @override
  String get fixHandNotRunning =>
      'Waxaa la heli karaa inta qarintu shaqaynayso: shaandhayntu daaran tahay, ikhtiyaar qarin ahna daaran yahay.';

  @override
  String get fixCoverArea => 'Dabool meel';

  @override
  String fixRemoveCovers(Object count) {
    return 'Ka saar daboollada gacanta ($count)';
  }

  @override
  String get fixNoteTitle => 'Qor khalad';

  @override
  String get fixNoteBody =>
      'Marka Waaiya ay wax khaldo, riix waxa dhacay, tusaale ahaan “Muusig ayaa soo dhaafay”. Qoraalku wuxuu hayaa waqtiga, barnaamijka iyo dejinta, si uu u caawiyo helidda sababta. Wuxuu ku jiraa qalabkan, waligiisna lama diro.';

  @override
  String get fixMissedSound => 'Muusig ayaa soo dhaafay';

  @override
  String get fixWrongSound => 'Cod si khalad ah ayaa looga saaray';

  @override
  String get fixMissedScreen => 'Wax lama daboolin';

  @override
  String get fixWrongScreen => 'Si khalad ah ayaa loo daboolay';

  @override
  String fixNoted(Object count) {
    return 'Waa la qoray ($count qoraal oo ku jira qalabkan).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Qoraallada qalabkan: $count';
  }

  @override
  String get fixNotesShow => 'Muuji qoraallada';

  @override
  String get fixNotesDelete => 'Tirtir qoraallada';

  @override
  String get fixNotesDeleteAsk =>
      'Ma la tirtiraa dhammaan qoraallada? Tan dib looma celin karo.';

  @override
  String get fixNotesTitle => 'Qoraallada khaladaadka';

  @override
  String get worshipTitle => 'Waqtiyada salaadda';

  @override
  String get worshipBody =>
      'Ikhtiyaari. Waxaa lagu xisaabiyaa taleefankan iyadoo laga eegayo meesha aad doorato. Waxba lama diro.';

  @override
  String worshipPlace(Object place) {
    return 'Meesha: $place';
  }

  @override
  String get worshipPlaceNone => 'Meesha: lama dooran';

  @override
  String get worshipChoose => 'Dooro';

  @override
  String get worshipPlaceSearch => 'Raadi magaalo';

  @override
  String get worshipPlaceNoMatch =>
      'Magaalo lama helin. Waxaad gelin kartaa isku-duwayaasha (coordinates) beddelkeeda.';

  @override
  String get worshipPlaceCustom => 'Geli isku-duwayaasha';

  @override
  String get worshipLat => 'Loolka – latitude (waqooyi +, koonfur −)';

  @override
  String get worshipLon => 'Dhigga – longitude (bari +, galbeed −)';

  @override
  String get worshipZone => 'Aagga waqtiga, tusaale ahaan Africa/Mogadishu';

  @override
  String get worshipCustomInvalid => 'Hubi tirooyinka iyo aagga waqtiga.';

  @override
  String get worshipPlaceInvalid =>
      'Meeshan lama isticmaali karo. Mar kale dooro.';

  @override
  String worshipMethod(Object method) {
    return 'Xisaabinta: $method';
  }

  @override
  String get worshipMethodTitle => 'Habka xisaabinta';

  @override
  String get worshipMethodNote =>
      'Waxaa loo doortay dalka magaalada. Dooro midka masjidkaagu raaco.';

  @override
  String worshipAsr(Object rule) {
    return 'Casar: $rule';
  }

  @override
  String get worshipAsrTitle => 'Waqtiga Casarka';

  @override
  String get worshipAsrStandard => 'Caadi (Shaafici, Maaliki, Xanbali)';

  @override
  String get worshipAsrHanafi => 'Xanafi';

  @override
  String get worshipMethodMwl =>
      'Ururka Caalamka Islaamka (Muslim World League)';

  @override
  String get worshipMethodIsna =>
      'Ururka Islaamka ee Waqooyiga Ameerika (ISNA)';

  @override
  String get worshipMethodEgypt => 'Hay\'adda Guud ee Sahanka Masar';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, Makka';

  @override
  String get worshipMethodKarachi => 'Jaamacadda Cilmiga Islaamka, Karachi';

  @override
  String get worshipMethodTehran => 'Machadka Geophysics, Jaamacadda Tehran';

  @override
  String get worshipMethodGulf => 'Gobolka Khaliijka';

  @override
  String get worshipMethodKuwait => 'Kuwayt';

  @override
  String get worshipMethodQatar => 'Qadar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turkiga (Diyanet)';

  @override
  String get worshipMethodFrance => 'Faransiiska (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marooko (Wasaaradda Habous)';

  @override
  String get worshipMethodIndonesia => 'Indoneesiya (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malaysiya (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubay';

  @override
  String get worshipToday => 'Maanta';

  @override
  String get worshipNoTimes =>
      'Halkan maanta ma jiraan waqtiyo salaadeed: qorraxdu ma soo baxdo ama ma dhacdo.';

  @override
  String get worshipSilentTitle => 'Aamusnaan waqtiyada salaadda';

  @override
  String get worshipSilentBody =>
      'Waqti kasta oo salaad, taleefanku wuu aamusaa (“Do Not Disturb”) daqiiqadaha hoose, kadibna sidii uu ahaa ayuu ku noqdaa. Tusaale ahaan, laga bilaabo Duhurka 12:00 ilaa 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Aamusnaan: $minutes daqiiqo';
  }

  @override
  String get worshipMuteTitle => 'Aamusii warbaahinta marka la aadaamo';

  @override
  String get worshipMuteBody =>
      'Waqti kasta oo salaad, codka warbaahinta (muuqaallada, muusigga, ciyaaraha) waa la aamusiiyaa daqiiqadaha hoose. Ogeysiisku isla markiiba wuu soo celin karaa codka.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Waa la aamusiiyaa: $minutes daqiiqo';
  }

  @override
  String get worshipMinutesTitle => 'Muddada';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes daqiiqo';
  }

  @override
  String get worshipNeedPlace => 'Marka hore dooro meel.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Xigta: $prayer saacadda $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Aamusan ilaa $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Warbaahinta waa la aamusiiyay ilaa $time.';
  }

  @override
  String get worshipDndNeeded =>
      'U oggolow Waaiya inay beddesho “Do Not Disturb”, haddii kale taleefanku ma aamusi karo.';

  @override
  String get worshipAllow => 'Oggolow';

  @override
  String get worshipExactNeeded =>
      'Waaiya looma oggola alaarmiyada iyo xusuusinta, sidaas darteed isbeddel kastaa wuu dib u dhici karaa ilaa 10 daqiiqo, ama ka badan marka taleefanku hurdo.';

  @override
  String get worshipNotificationsNeeded =>
      'Ogeysiisyadu waa damsan yihiin: ma arki doontid marka taleefanku aamuso ama uu soo noqdo.';

  @override
  String get worshipTonesTitle => 'Cod garaac iyo cod ogeysiis oo fudud';

  @override
  String get worshipTonesBody =>
      'Waaiya ma shaandheyn karto codka garaaca ama ogeysiisyada, kaliya way beddeli kartaa. Dooro cod fudud oo aan muusig lahayn:';

  @override
  String worshipToneRing(Object number) {
    return 'Cod garaac fudud $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Cod ogeysiis fudud $number';
  }

  @override
  String get worshipTonePlay => 'Daar';

  @override
  String get worshipToneSet => 'Isticmaal';

  @override
  String get worshipToneInUse => 'Waa la isticmaalayaa';

  @override
  String get worshipToneDone => 'Waa la dhammeeyay.';

  @override
  String get worshipTonePermission =>
      'U oggolow Waaiya inay wax ka beddesho dejinta nidaamka, soo noqo, oo mar kale taabo.';

  @override
  String get worshipToneFailed =>
      'Taleefankani uma oggolaan Waaiya inay beddesho. Dejinta Codka (Sound), dooro cod la yiraahdo “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Fur dejinta Codka';

  @override
  String get worshipSmsTitle => 'SMS ugu jawaab wicitaannada inta salaadda';

  @override
  String get worshipSmsBody =>
      'Daqiiqadaha aamusnaanta ee ka dambeeya waqti kasta oo salaad, wicitaan la daayay isagoo garaacaya wuxuu helaa hal SMS. Hal mar lambar kasta salaad kasta; waligeed looma diro lambarro qarsoon ama lambarro gaagaaban.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Kadib: $seconds ilbiriqsi oo garaac ah';
  }

  @override
  String get worshipSmsDelayTitle => 'Ilbiriqsiyada garaaca ka hor SMS-ka';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds ilbiriqsi';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Fariinta: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Fariintaada';

  @override
  String get worshipSmsTextDefault => 'Isticmaal tan caadiga ah';

  @override
  String get worshipSmsCost =>
      'Jawaab kastaa waa SMS caadi ah oo ka baxda SIM-kaaga, qiimaha qorshahaaga. Waxba lama diro marka aad roaming ku jirto.';

  @override
  String get worshipSmsRoaming =>
      'Hadda roaming ayaad ku jirtaa: SMS lama dirayo.';

  @override
  String get worshipSmsLogTitle =>
      'Jawaabaha la diray (taleefankan oo keliya ayay ku jiraan)';

  @override
  String get worshipContinue => 'Sii wad';

  @override
  String get worshipWhyDnd =>
      'Si taleefanku u aamuso waqtiyada salaadda, bogga xiga ku oggolow gelitaanka “Do Not Disturb” ee Waaiya.';

  @override
  String get worshipWhyExact =>
      'Si ay waqtiga saxda ah wax u qabato, bogga xiga ku oggolow Waaiya inay dejiso alaarmiyo iyo xusuusin. La\'aanteed, isbeddelladu waxay dib u dhici karaan ilaa 10 daqiiqo.';

  @override
  String get worshipWhyNotifications =>
      'Oggolow ogeysiisyada si aad u aragto isbeddel kasta oo aad uga noqon karto.';

  @override
  String get worshipWhyWrite =>
      'Si aad u beddesho codka garaaca ama ogeysiiska, bogga xiga ku oggolow Waaiya inay wax ka beddesho dejinta nidaamka.';

  @override
  String get worshipWhyPhone =>
      'Si ay u ogaato in wicitaan garaacayo iyo lambarkiisa, Waaiya waxay u baahan tahay ogolaanshaha Taleefanka (Phone) iyo Diiwaanka wicitaannada (Call logs). Waxba kama baxaan taleefanka marka laga reebo jawaabtaada.';

  @override
  String get worshipWhySms =>
      'Si ay u dirto jawaabtaada, Waaiya waxay u baahan tahay ogolaansho ay SMS ku dirto. Waxay dirtaa oo keliya jawaabtaas, ugu badnaan hal mar lambar kasta salaad kasta.';

  @override
  String get worshipMissingDnd =>
      'Gelitaanka “Do Not Disturb” lama oggolaan, sidaas darteed aamusnaantu way damsan tahay.';

  @override
  String get worshipMissingPhone =>
      'Ogolaanshaha Taleefanka iyo Diiwaanka wicitaannada lama bixin, sidaas darteed jawaabta SMS-ku way damsan tahay.';

  @override
  String get worshipMissingSms =>
      'Ogolaanshaha dirista SMS lama bixin, sidaas darteed jawaabta SMS-ku way damsan tahay.';

  @override
  String get worshipTryAgain => 'Isku day mar kale';

  @override
  String get protectTitle => 'Ilaalin waqtiyada daciifnimada';

  @override
  String get protectBody =>
      'Waqtiga daciifnimada marka laga yaabo inaad rabto inaad damiso shaandhaynta. Hadda, adigoo deggan, dooro muddo sugid ah: markaas badhanka joojinta isla markiiba ma joojiyo shaandhaynta, waxaadna mar kale go\'aansanaysaa marka muddadu dhammaato. Waalidku sidoo kale wuu dhigi karaa PIN.';

  @override
  String protectDelay(Object value) {
    return 'Sugid ka hor damin: $value';
  }

  @override
  String get protectDelayTitle => 'Sugid ka hor damin';

  @override
  String get protectDelayBody =>
      'Tusaale ahaan, 30 daqiiqo: waxaad riixdaa badhanka joojinta, laakiin shaandhayntu way sii shaqaynaysaa. 30 daqiiqo kadib, boggani wuxuu ku weydiinayaa inaad weli rabto inaad joojiso. Riix “Xaqiiji” 15 daqiiqo gudahood waana istaagaysaa; haddii kale waxba isma beddelaan. Sidaas oo kale ayay tahay demista dabool ama ilaalin kale. Daarista waxyaabaha had iyo jeer isla markiiba way shaqaysaa.';

  @override
  String get protectDelayOff => 'Midna';

  @override
  String get protectDelay1m => '1 daqiiqo';

  @override
  String get protectDelay5m => '5 daqiiqo';

  @override
  String get protectDelay15m => '15 daqiiqo';

  @override
  String get protectDelay30m => '30 daqiiqo';

  @override
  String get protectDelay1h => '1 saac';

  @override
  String get protectDelay4h => '4 saacadood';

  @override
  String get protectDelay24h => '24 saacadood';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes daqiiqo';
  }

  @override
  String get protectPinNone => 'PIN: lama dejin';

  @override
  String get protectPinIsSet => 'PIN: waa la dejiyay';

  @override
  String get protectPinSet => 'Deji PIN';

  @override
  String get protectPinRemove => 'Ka saar';

  @override
  String get protectPinBody =>
      'Marka PIN jiro, joojinta shaandhaynta ama demista ilaalin kasta marka hore waxay weydiisaa PIN-ka. Tusaale ahaan, waalidku wuxuu dhigaa PIN si ilmuhu uusan u demin shaandhaynta. Beddelka muddada sugitaanka ama PIN-ka sidoo kale wuu weydiiyaa.';

  @override
  String get protectPinForgot =>
      'PIN-ka ku qor meel ammaan ah: haddii la illaawo, dib u dejin ma jirto. Waddada kaliya waa tirtirista xogta Waaiya ama dib u rakibisteeda, taas oo sidoo kale tirtirta dhammaan dejinteeda.';

  @override
  String get protectPinTitle => 'Geli PIN-ka';

  @override
  String get protectPinNewTitle => 'Dooro PIN';

  @override
  String get protectPinChangeTitle => 'Beddel PIN-ka';

  @override
  String get protectPinCurrent => 'PIN-ka hadda';

  @override
  String get protectPinNew => 'PIN cusub (4 ilaa 8 lambar)';

  @override
  String get protectPinAgain => 'PIN-ka cusub mar kale';

  @override
  String get protectPinBad => 'Isticmaal 4 ilaa 8 lambar.';

  @override
  String get protectPinDiffer => 'Labada PIN ee cusub isku mid ma aha.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN khaldan. $count isku day ayaa kaa harsan ka hor hakad.';
  }

  @override
  String protectLocked(Object time) {
    return 'Isku dayo khaldan oo aad u badan. Mar kale isku day $time.';
  }

  @override
  String get protectOk => 'Hagaag';

  @override
  String get protectCancel => 'Ka noqo';

  @override
  String get protectCancelChange => 'Ka noqo isbeddelka';

  @override
  String get protectConfirm => 'Xaqiiji';

  @override
  String protectPending(Object time, Object what) {
    return '$what: waa la sugayaa ilaa $time. Kadib ku xaqiiji “Dejinta”.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: sugiddii way dhammaatay. Weli ma rabtaa? Riix “Xaqiiji” ka hor $time; haddii kale waxba isma beddelaan.';
  }

  @override
  String get protectWaitTitle => 'Isbeddelkan wuu sugayaa';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what hadda ma dhacayo. Saacadda $time, haddii aad weli rabto, ku xaqiiji “Dejinta” 15 daqiiqo gudahood. Haddii aadan waxba samayn, waxba isma beddelaan.';
  }

  @override
  String get protectWaitStart => 'Bilow sugitaanka';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Horeba waa la sugayaa ilaa $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Waa la sugayaa ilaa $time. Kadib ku xaqiiji “Dejinta”.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'berri saacadda $time';
  }

  @override
  String get protectHeldBack =>
      'Hadda ma aha: dejinta ilaalintaadu waxay ka dhigaysaa isbeddelkan mid sugaya, ama waxay weydiinaysaa PIN-ka.';

  @override
  String get protectLimits =>
      'Waxa aysan tani joojin karin: ku-qasab joojinta (force stop), ka saarista barnaamijka, tirtirista xogta Waaiya iyo dejinta Android lafteeda. Xannibaaddooda waxay u baahan lahayd oggolaansho gaar ah oo Android ah, oo Waaiya aysan isticmaalin. Tani waxay kaa ilaalisaa waqti daciifnimo, ma aha qof go\'aansaday.';

  @override
  String get protectLimitsDesktop =>
      'Waxa aysan tani joojin karin: amarka waaiya ee terminal-ka, ka saarista Waaiya ama tirtirista galka dejinteeda. Tani waxay kaa ilaalisaa waqti daciifnimo, ma aha qof go\'aansaday.';

  @override
  String get protectLimitsWindows =>
      'Waxa aysan tani joojin karin: amarka waaiya-filter.exe ee terminal-ka, ka saarista Waaiya ama tirtirista galka dejinteeda. Tani waxay kaa ilaalisaa waqti daciifnimo, ma aha qof go\'aansaday.';

  @override
  String get protectWhatStop => 'Jooji shaandhaynta';

  @override
  String protectWhatOff(Object name) {
    return 'Dami: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Daar: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Barnaamij ku dar: $name';
  }

  @override
  String get protectWhatStrictness => 'Ka dhig qarinta mid ka adkaan yar';

  @override
  String get protectWhatGender => 'Beddel cidda isticmaasha Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'U beddel sugidda ka hor damin: $value';
  }

  @override
  String get protectWhatPinChange => 'Beddel PIN-ka';

  @override
  String get protectWhatPinClear => 'Ka saar PIN-ka';

  @override
  String get protectWhatSetting => 'Beddel dejin';

  @override
  String get onboardBodyDesktop =>
      'Waaiya waxay ka saartaa qalabka muusigga codka barnaamij kasta oo kombiyuutarkan ku jira. Hadalka iyo akhriska Qur\'aanka waa la hayaa. Hadda, codadka heesaha sidoo kale waa la saaraa.';

  @override
  String get worshipUseLocation => 'Isticmaal goobtayda';

  @override
  String get worshipWhyLocation =>
      'Si loo helo waqtiyada salaadda meesha aad joogto, Waaiya waxay hal mar, hadda, akhrisaa goobta qiyaasta ah ee taleefankan. Waxay ku jirtaa taleefanka sida goobtaada, meelna looma diro.';

  @override
  String get worshipLocating => 'Waxaa la raadinayaa meesha aad joogto…';

  @override
  String get worshipLocationDenied =>
      'Goobta looma oggolaan. Waxaad raadin kartaa magaaladaada beddelkeeda.';

  @override
  String get worshipLocationOff =>
      'Goobta waa ka dansan tahay taleefankan. Shid oo isku day mar kale, ama raadi magaaladaada.';

  @override
  String get worshipLocationSettings => 'Dejinta goobta';

  @override
  String get worshipLocationFailed =>
      'Goobtaada lama helin. Isku day mar kale wax yar kadib, ama raadi magaaladaada.';

  @override
  String worshipPlaceNear(Object city) {
    return 'u dhow $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Waqtiyada rasmiga ah ee Wasaaradda Habous iyo Arrimaha Islaamka ee $city.';
  }
}
