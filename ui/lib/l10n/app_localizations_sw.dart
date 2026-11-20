// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Huondoa ala za muziki kwenye kila programu na kubakiza mazungumzo na kisomo.';

  @override
  String get onboardTitle => 'Karibu';

  @override
  String get onboardBody =>
      'Waaiya huondoa ala za muziki kwenye sauti ya kila programu katika simu hii. Mazungumzo na kisomo cha Qur\'ani hubaki. Kwa sasa, sauti za uimbaji huondolewa pia.';

  @override
  String get onboardQuestion => 'Mimi ni';

  @override
  String get genderMan => 'Mwanamume';

  @override
  String get genderWoman => 'Mwanamke';

  @override
  String get onboardWhy =>
      'Hili huamua tu ni mipangilio gani ya hiari utakayoiona. Unaweza kulibadilisha baadaye.';

  @override
  String get stateOnTitle => 'Uchujaji umewashwa';

  @override
  String get stateOffTitle => 'Uchujaji umezimwa';

  @override
  String get stateStarting => 'Inaanza…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Ala za muziki zinaondolewa kwenye programu zote. Sauti inachelewa takriban ms $delayMs.';
  }

  @override
  String get stateOffDetail => 'Gusa kitufe ili kuanza.';

  @override
  String get stateModelFailed =>
      'Modeli ya sauti haikuweza kupakiwa, kwa hiyo sauti imenyamazishwa kwa usalama.';

  @override
  String get stateCaptureDenied =>
      'Ruhusa ya maikrofoni inahitajika ili kupokea sauti ya programu nyingine.';

  @override
  String get stateStoppedBySystem =>
      'Android imesimamisha uchujaji. Gusa kitufe ili kuanza tena.';

  @override
  String get stateSilencedTitle => 'Uchujaji umesimama';

  @override
  String get stateSilenced =>
      'Uchujaji umesimama: programu nyingine zimenyamazishwa. Gusa kitufe ili kuanza tena, au Simamisha ili kuzisikia bila kuchujwa.';

  @override
  String get releaseSilence => 'Simamisha: sikia programu bila kuchujwa';

  @override
  String get powerStartCd => 'Anza kuchuja';

  @override
  String get powerStopCd => 'Simamisha uchujaji';

  @override
  String get captureHint =>
      'Android itakuuliza ushiriki skrini yako. Sauti pekee ndiyo hutumika: hakuna kinachorekodiwa wala kutumwa.';

  @override
  String get needRecordAudio =>
      'Waaiya inahitaji ruhusa ya maikrofoni ili kupokea sauti ya programu nyingine. Haikurekodi kamwe.';

  @override
  String get setupBannerTitle => 'Hatua moja zaidi';

  @override
  String get setupBannerBody =>
      'Bila usanidi wa mara moja ulio hapa chini, utasikia muziki na sauti iliyochujwa kwa pamoja.';

  @override
  String get step1Title => 'Sakinisha Shizuku';

  @override
  String get step1Body => 'Programu saidizi ya bure kutoka Play Store.';

  @override
  String get step1Action => 'Pata Shizuku';

  @override
  String get step2Title => 'Washa Shizuku';

  @override
  String get step2Body =>
      'Shizuku huwashwa kupitia Wi-Fi kwa kutumia utatuzi usiotumia waya wa Android. Gusa kitufe uone hatua, kisha urudi.';

  @override
  String get step2Action => 'Fungua Shizuku';

  @override
  String get step2Update => 'Sasisha Shizuku';

  @override
  String get step2TooOld =>
      'Toleo lako la Shizuku ni la zamani mno. Lisasishe kutoka Play Store.';

  @override
  String get step2Denied =>
      'Shizuku imewekwa kuikatalia Waaiya kila mara. Ndani ya Shizuku, iruhusu kwenye orodha ya programu.';

  @override
  String get step3Title => 'Toa ruhusa';

  @override
  String get step3Body => 'Gusa mara moja, kisha uchague “Ruhusu”.';

  @override
  String get step3Action => 'Toa ruhusa';

  @override
  String get step3Busy => 'Inasanidi…';

  @override
  String get setupDoneRestart =>
      'Imekamilika. Simamisha uchujaji kisha uuanze tena mara moja ili ianze kutumika.';

  @override
  String setupFailed(String details) {
    return 'Usanidi haukukamilika. Maelezo:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Ruhusa ya Shizuku imekataliwa. Gusa kitufe ili ujaribu tena.';

  @override
  String get setupSlow =>
      'Shizuku inachukua muda zaidi kuliko kawaida. Endelea kusubiri: kwenye baadhi ya simu, msaidizi wake huchukua hadi dakika moja kuanza mara ya kwanza.';

  @override
  String get setupTimeout =>
      'Shizuku haikujibu ndani ya dakika 2. Fungua Shizuku, hakikisha inasema inafanya kazi, kisha gusa kitufe tena. Usanidi ukikamilika baadaye, skrini hii itajisasisha yenyewe.';

  @override
  String get setupRefusedXiaomi =>
      'Simu hii imekataa ruhusa. Kwenye Xiaomi, Redmi na POCO, washa “Utatuzi wa USB (Mipangilio ya usalama)” (USB debugging (Security settings)) katika Chaguo za wasanidi programu (Developer options) (itakuomba uingie kwenye akaunti ya Xiaomi), kisha ujaribu tena.';

  @override
  String get setupRefusedColoros =>
      'Simu hii imekataa ruhusa. Kwenye OPPO, OnePlus na realme, katika Chaguo za wasanidi programu, washa “Disable permission monitoring” (Zima ufuatiliaji wa ruhusa) (kwenye matoleo mapya zaidi inaitwa “Disable system optimization” (Zima uboreshaji wa mfumo), na huenda ikaonekana tu simu ikiwa imewekwa kwa Kiingereza). Ili kuipata, tafuta “permission” (au “ruhusa”) katika Mipangilio. Kisha ujaribu tena.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi na POCO: ikiwa arifa haina sehemu ya kuandika msimbo, weka mtindo wa arifa kuwa “Android” katika mipangilio ya arifa, au andika msimbo ndani ya Waaiya ukitumia skrini iliyogawanywa.';

  @override
  String get stepDoneCd => 'Imekamilika';

  @override
  String stepTodoCd(int step) {
    return 'Hatua ya $step';
  }

  @override
  String get computerToggle => 'Tumia kompyuta badala yake';

  @override
  String get computerBody =>
      'Washa Utatuzi wa USB, unganisha simu kisha uendeshe:';

  @override
  String get copy => 'Nakili';

  @override
  String get copied => 'Imenakiliwa';

  @override
  String get computerNote =>
      'Mstari wa pili ni wa hiari: unazuia swali la kushiriki skrini kila unapoanza.';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get settingSilenceTitle => 'Nyamazisha programu zinazozuia uchujaji';

  @override
  String get settingSilenceBody =>
      'Inapendekezwa. Baadhi ya programu haziruhusu sauti yao ichujwe; hii huzinyamazisha badala ya kuacha muziki upite.';

  @override
  String get settingHoldSilenceTitle =>
      'Acha programu kimya uchujaji ukisimama wenyewe';

  @override
  String get settingHoldSilenceBody =>
      'Inapendekezwa. Android ikisimamisha uchujaji (si wewe), programu nyingine hubaki kimya hadi uanze tena au uguse Simamisha, badala ya kucheza muziki bila kuchujwa. Inahitaji usanidi wa mara moja.';

  @override
  String get settingStereoTitle => 'Sauti ya stereo';

  @override
  String get settingStereoBody =>
      'Imezimwa: mono, inayotumia takriban nusu ya betri na huenda sambamba kwenye simu nyingi zaidi. Imewashwa: hutenganisha upande wa kushoto na wa kulia. Simu ikiwa ya polepole mno kwa stereo, bado hujibadilisha yenyewe kuwa mono.';

  @override
  String get settingSingingTitle => 'Nyamazisha uimbaji wa wanawake';

  @override
  String get settingSingingBody => 'Mazungumzo ya wanawake yanabaki.';

  @override
  String get settingSingingNoModel =>
      'Toleo hili halina kitambuzi cha uimbaji, kwa hiyo sauti zote za watu hunyamazishwa chaguo hili likiwa limewashwa.';

  @override
  String get settingRestart =>
      'Simamisha kisha uanze uchujaji tena ili mabadiliko yatumike.';

  @override
  String get settingGenderTitle => 'Mimi ni';

  @override
  String get change => 'Badilisha';

  @override
  String get playerTitle => 'Video zenye sauti inayolingana kikamilifu';

  @override
  String get playerBody =>
      'Shiriki video kwa Waaiya (au tumia “Fungua ukitumia”) ili uitazame ikiwa imechujwa bila kuchelewa.';

  @override
  String get licences => 'Leseni za programu huria';

  @override
  String get licencesIntro =>
      'Waaiya ni programu huria chini ya GNU Affero General Public License v3 au toleo jipya zaidi. Msimbo chanzo: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (data ya mafunzo): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Maandishi kamili';

  @override
  String get back => 'Rudi';

  @override
  String get linkEntryTitle => 'Fungua kiungo';

  @override
  String get linkEntryBody =>
      'Bandika kiungo cha YouTube, TikTok au Instagram ili ukitazame au ukihifadhi bila muziki.';

  @override
  String get linkTitle => 'Fungua kiungo';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Kiungo cha video au sauti';

  @override
  String get linkPaste => 'Bandika';

  @override
  String get linkOpen => 'Fungua';

  @override
  String get linkResolving => 'Inafungua kiungo…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Tazama bila muziki';

  @override
  String get linkSave => 'Hifadhi bila muziki';

  @override
  String get linkListen => 'Sikiliza bila muziki';

  @override
  String get linkAudioOnly =>
      'Video ya kiungo hiki haiwezi kufunguliwa bado: sauti yake pekee ndiyo inaweza.';

  @override
  String get linkDownloading => 'Inapakua…';

  @override
  String get linkFiltering => 'Inaondoa muziki…';

  @override
  String get linkCancel => 'Ghairi';

  @override
  String get linkCancelled => 'Imeghairiwa. Hakuna kilichohifadhiwa.';

  @override
  String get linkTimedOut =>
      'Android imesimamisha uhifadhi: inaruhusu kazi ya aina hii kwa saa chache tu kwa siku. Hakuna kilichohifadhiwa; fungua Waaiya kisha ujaribu tena.';

  @override
  String get linkExportFailed =>
      'Imeshindwa kuhifadhi hii. Hakuna kilichohifadhiwa.';

  @override
  String get linkSaved => 'Imehifadhiwa bila muziki';

  @override
  String get linkSavedVideo => 'Kwenye matunzio yako: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Kwenye muziki wako: Music › Waaiya';

  @override
  String get linkPlay => 'Cheza';

  @override
  String get linkShare => 'Shiriki';

  @override
  String get linkShareNote => 'Shiriki tu video unazoruhusiwa kushiriki.';

  @override
  String get linkLive => 'Matangazo ya moja kwa moja hayawezi kuhifadhiwa.';

  @override
  String get linkBusy =>
      'Video nyingine inahifadhiwa. Tafadhali subiri imalizike.';

  @override
  String get linkInvalid =>
      'Tafadhali bandika kiungo cha wavuti (kinachoanza na https://).';

  @override
  String get linkLogin =>
      'Tovuti haikuonyesha video hii bila akaunti. Machapisho ya umma kwa kawaida hufunguka: jaribu tena baada ya dakika chache. Machapisho ya faragha hayawezi kufunguliwa.';

  @override
  String get linkUnsupported => 'Tovuti hii haitumiki.';

  @override
  String get linkPlaylist =>
      'Hii ni orodha ya kucheza. Tafadhali fungua video moja.';

  @override
  String get linkNoFormat =>
      'Video hii haiko katika muundo ambao Waaiya inaweza kuuchuja bado.';

  @override
  String get linkFailed =>
      'Imeshindwa kufungua kiungo hiki. Angalia muunganisho wako kisha ujaribu tena.';

  @override
  String get linkPlayFailed =>
      'Imeshindwa kucheza hii. Hakuna kilichochezwa bila kuchujwa.';

  @override
  String get linkLimited =>
      'Tovuti inapunguza maombi kwa sasa. Jaribu tena baada ya dakika chache.';

  @override
  String get blurTitle => 'Kufifisha skrini';

  @override
  String get blurBody =>
      'Hufunika watu na picha kwenye skrini, katika kila programu, wakati uchujaji umewashwa. Hufanya kazi ndani ya simu; hakuna kinachotumwa popote.';

  @override
  String get blurWomenTitle => 'Fifisha wanawake';

  @override
  String get blurWomenBody =>
      'Mwili mzima. Watu ambao programu haiwezi kutambua wazi kuwa ni wanaume hufifishwa pia.';

  @override
  String get blurNudityTitle => 'Fifisha picha zisizo za staha';

  @override
  String get blurNudityBody =>
      'Uchi na mavazi yanayoacha mwili wazi, ya mtu yeyote: skrini nzima hufunikwa.';

  @override
  String get blurFailTitle =>
      'Funika skrini ikiwa ufifishaji hauwezi kwenda sambamba';

  @override
  String get blurFailBody =>
      'Imewashwa: skrini nzima hufunikwa simu ikiwa ya polepole mno au ufifishaji ukishindwa. Imezimwa: skrini hubaki ikionekana pamoja na onyo.';

  @override
  String get blurSetupShizuku => 'Ruhusu kwa Shizuku';

  @override
  String get blurSetupManual => 'Ruhusu katika mipangilio ya Android';

  @override
  String get blurStatusNeedsSetup =>
      'Ufifishaji unahitaji kuonyeshwa juu ya programu nyingine. Bora zaidi: uruhusu kwa Shizuku (huwasha huduma ya ufikivu ya Ufifishaji wa Waaiya, ili miguso iendelee kufika kwenye programu iliyo chini). Au ruhusu “Onyesha juu ya programu zingine” (Display over other apps) katika mipangilio ya Android (miguso kwenye eneo lililofifishwa hupotea hapo).';

  @override
  String get blurStatusNeedsOverlay =>
      'Ufifishaji unahitaji kuonyeshwa juu ya programu nyingine. Bora zaidi: washa Shizuku (na uiruhusu Waaiya ndani yake): ufifishaji kisha huchora tabaka lake lenyewe, ambalo miguso hupita ndani yake. La sivyo, ruhusu “Onyesha juu ya programu zingine” (Display over other apps) katika mipangilio ya Android; kugusa eneo lililofifishwa hapo hakufiki kwenye programu iliyo chini.';

  @override
  String get blurFailUnavailable =>
      'Halipatikani kwa sasa: kifuniko cha skrini nzima kingezuia kila mguso na ungeweza kukwama. Washa msaidizi wa Waaiya au Shizuku (Android 12 au mpya zaidi) na chaguo hili litawaka: vifuniko kisha huchorwa ili miguso ipite ndani yake. Hadi hapo, ufifishaji usipoweza kwenda sambamba, skrini hubaki ikionekana pamoja na onyo.';

  @override
  String get blurFailNeedsA11y =>
      'Halipatikani kwa sasa: kifuniko cha skrini nzima kingezuia kila mguso na ungeweza kukwama. Washa Shizuku (Android 12 au mpya zaidi) au washa huduma ya ufikivu ya Ufifishaji wa Waaiya (Ruhusu kwa Shizuku, hapo juu) na chaguo hili litawaka. Hadi hapo, skrini hubaki ikionekana pamoja na onyo.';

  @override
  String get languageTitle => 'Lugha';

  @override
  String settingLanguageTitle(String language) {
    return 'Lugha: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Simamisha kisha uanze uchujaji tena ili mipangilio ya ufifishaji itumike.';

  @override
  String get blurStatusStarting => 'Ufifishaji unaanza…';

  @override
  String get blurStatusOn => 'Ufifishaji umewashwa.';

  @override
  String get blurStatusOnVisible =>
      'Ufifishaji umewashwa, katika hali ya tahadhari: simu hii huonyesha ufifishaji katika picha yake ya skrini yenyewe, kwa hiyo eneo lililofifishwa hubaki limefifishwa hadi mandhari ibadilike.';

  @override
  String get blurStatusModels =>
      'Toleo hili halina modeli ya ufifishaji kwa chaguo ulilochagua.';

  @override
  String get blurStatusFailing =>
      'Ufifishaji hauwezi kwenda sambamba kwa sasa.';

  @override
  String get blurStatusNoOverlay =>
      'Ufifishaji hauwezi kuonyeshwa juu ya programu nyingine: uruhusu hapo juu.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Ufifishaji hauwezi kuona skrini. Maelezo:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku haikuweza kuuruhusu:\n$details';
  }

  @override
  String get step2Guide => 'Jinsi ya kuwasha Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Halipatikani: kwenye toleo hili la Android kifuniko cha skrini nzima kingezuia kila mguso na ungeweza kukwama (vifuniko vya Shizuku vinahitaji Android 12 au mpya zaidi). Ufifishaji usipoweza kwenda sambamba, skrini hubaki ikionekana pamoja na onyo.';

  @override
  String get guideTitle => 'Washa Shizuku, hatua kwa hatua';

  @override
  String get guideOpenDev => 'Chaguo za wasanidi programu';

  @override
  String get guideOpenShizuku => 'Fungua Shizuku';

  @override
  String get guideClose => 'Funga';

  @override
  String get guideBody =>
      'Unahitaji Wi-Fi na Android 11 au mpya zaidi. Kuoanisha hufanywa mara moja; simu ikiwashwa upya unarudia hatua ya 7 tu.\n\n1. Unganisha simu kwenye Wi-Fi.\n\n2. Washa Chaguo za wasanidi programu (Developer options): Mipangilio › Kuhusu simu (About phone) › Maelezo ya programu (Software information) › gusa “Nambari ya muundo” (Build number) mara 7. (Kwenye simu nyingine: Mipangilio › Kuhusu simu › Nambari ya muundo.)\n\n3. Fungua Shizuku. Ikiomba kuonyesha arifa, iruhusu: msimbo wa kuoanisha huandikwa kwenye arifa ya Shizuku.\n\n4. Ndani ya Shizuku, chini ya “Start via Wireless debugging”, gusa “Pairing”. Kwenye ukurasa utakaofunguka, gusa “Developer options”, washa “Utatuzi usiotumia waya” (Wireless debugging) na uthibitishe kwa “Ruhusu”.\n\n5. Gusa maneno “Utatuzi usiotumia waya” (si swichi), kisha “Oanisha kifaa ukitumia msimbo wa kuoanisha” (Pair device with pairing code). Msimbo wa tarakimu 6 utaonekana.\n\n6. Acha skrini hiyo wazi na uvute chini arifa. Arifa ya Shizuku ikisema “Pairing service found”, gusa “Enter pairing code” na uandike msimbo. Shizuku itasema kuoanisha kumefaulu.\n\n7. Rudi kwenye Shizuku na uguse “Start” chini ya “Start via Wireless debugging”. Subiri hadi iseme “Shizuku is running”.\n\n8. Rudi kwenye Waaiya na uguse “Toa ruhusa”, kisha “Ruhusu”.\n\nSimu ikiwashwa upya, Shizuku husimama: unganisha kwenye Wi-Fi, washa tena “Utatuzi usiotumia waya” ikiwa umezimwa, fungua Shizuku na uguse “Start”. Hakuna haja ya kuoanisha upya.';

  @override
  String get wsetupRouteTitle => 'Sanidi kwenye simu hii';

  @override
  String get wsetupRouteBody =>
      'Hatua nne fupi, zinazofanywa mara moja. Hakuna programu ya ziada wala kompyuta. Waaiya huweka alama kwenye kila hatua inapokamilika.';

  @override
  String get wizDevTitle => 'Washa Chaguo za wasanidi programu';

  @override
  String get wizDevBody =>
      'Katika Kuhusu simu (About phone), gusa “Nambari ya muundo” (Build number) mara 7, kisha urudi hapa. Ikiwa huipati, tafuta “Nambari ya muundo” katika Mipangilio.';

  @override
  String get wizDevBodySamsung =>
      'Katika Kuhusu simu › Maelezo ya programu (Software information), gusa “Nambari ya muundo” (Build number) mara 7, kisha urudi hapa.';

  @override
  String get wizDevBodyXiaomi =>
      'Katika Kuhusu simu, gusa “Toleo la OS” (OS version) mara 7 (kwenye simu za zamani “Toleo la MIUI” (MIUI version); kwenye baadhi iko chini ya “Maelezo ya kina na vipimo” (Detailed info and specs)), kisha urudi hapa.';

  @override
  String get wizDevBodyColoros =>
      'Katika Kuhusu kifaa (au Kuhusu simu) › Toleo (Version), gusa “Nambari ya muundo” (Build number) mara 7, kisha urudi hapa.';

  @override
  String get wizDevBodyVivo =>
      'Katika Kuhusu simu, gusa “Toleo la programu” (Software version) mara 7 (kwenye baadhi ya simu: Maelezo ya programu › “Nambari ya muundo”), kisha urudi hapa.';

  @override
  String get wizDevBodyHuawei =>
      'Katika Kuhusu simu (About phone), gusa “Nambari ya muundo” (Build number) mara 7, kisha urudi hapa.';

  @override
  String get wizDevBodyTranssion =>
      'Katika Simu yangu (My phone) (au Kuhusu simu), gusa “Nambari ya muundo” (Build number) mara 7, kisha urudi hapa.';

  @override
  String get setupNoteHuawei =>
      'Huawei: simu nyingi za Huawei hazina “Utatuzi usiotumia waya”. Ikiwa huupati katika Chaguo za wasanidi programu, tumia kompyuta (“Njia nyingine” hapa chini).';

  @override
  String get wsetupFilterOn =>
      'Uchujaji umewashwa: kwenye toleo hili la Android msimbo hauwezi kuandikwa kwenye arifa wakati uchujaji unaendelea. Simamisha uchujaji kwanza, au tumia skrini iliyogawanywa na “Andika msimbo hapa”.';

  @override
  String get wizDevSearch =>
      'Majina yanaweza kutofautiana kulingana na lugha ya simu: ikiwa huyapati, tumia utafutaji ulio juu ya Mipangilio.';

  @override
  String get wizDevAction => 'Fungua Kuhusu simu';

  @override
  String get wizWifiTitle => 'Unganisha kwenye Wi-Fi';

  @override
  String get wizWifiBody =>
      'Mtandao wowote wa Wi-Fi unafaa; intaneti haihitajiki.';

  @override
  String get wizWifiAction => 'Fungua mipangilio ya Wi-Fi';

  @override
  String get wizWdTitle => 'Washa Utatuzi usiotumia waya';

  @override
  String get wizWdBody =>
      'Waaiya hufungua Chaguo za wasanidi programu kwenye “Utatuzi usiotumia waya” (Wireless debugging). Uwashe kisha uguse “Ruhusu”.';

  @override
  String get wizWdAction => 'Fungua Chaguo za wasanidi programu';

  @override
  String get wizPairTitle => 'Andika msimbo wa kuoanisha';

  @override
  String get wizPairBody =>
      'Gusa maneno “Utatuzi usiotumia waya”, kisha “Oanisha kifaa ukitumia msimbo wa kuoanisha” (Pair device with pairing code). Andika tarakimu 6 kwenye arifa ya Waaiya. Waaiya itafanya yaliyobaki.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya tayari imeoanishwa na simu hii: hakuna msimbo unaohitajika. Gusa kitufe na Waaiya itamaliza yenyewe.';

  @override
  String get wizPairAction => 'Endelea';

  @override
  String get wizAgain => 'Fanya usanidi tena';

  @override
  String get setupShizukuReadyTitle =>
      'Kwa Shizuku, ambayo tayari inafanya kazi';

  @override
  String get setupOtherWaysPlain => 'Njia nyingine za kufanya usanidi';

  @override
  String get wizSkip => 'Ruka hadi Utatuzi usiotumia waya';

  @override
  String get setupOtherWays => 'Njia nyingine: Shizuku au kompyuta';

  @override
  String get wsetupEnterHere => 'Andika msimbo hapa';

  @override
  String get wsetupCancel => 'Ghairi';

  @override
  String get wsetupAndroid10 =>
      'Android 10 haiwezi kufanya usanidi yenyewe: inahitaji kompyuta, moja kwa moja (hapa chini) au ili kuwasha Shizuku mara moja.';

  @override
  String get wsetupShizukuHeading => 'Au kwa programu ya Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku pia huruhusu miguso ipite kwenye vifuniko vya skrini.';

  @override
  String get wsetupChannel => 'Usanidi wa mara moja';

  @override
  String get wsetupNotifTitle =>
      'Usanidi wa Waaiya: inasubiri msimbo wa kuoanisha';

  @override
  String get wsetupFoundTitle => 'Skrini ya kuoanisha imepatikana';

  @override
  String get wsetupBusyTitle => 'Usanidi wa Waaiya';

  @override
  String get wsetupDoneTitle => 'Usanidi umekamilika';

  @override
  String get wsetupDoneBody =>
      'Sasa Waaiya inaweza kunyamazisha sauti asili. Unaweza kuzima Utatuzi usiotumia waya.';

  @override
  String get wsetupDoneHelperBody =>
      'Imekamilika. Simu hii hairuhusu programu kubaki na ruhusa hizi, kwa hiyo msaidizi wa Waaiya ndiye anayenyamazisha sauti asili. Msaidizi husimama simu ikiwashwa upya na Waaiya ikisasishwa. Ukifungua Waaiya baada ya hapo, humwasha msaidizi tena yenyewe ikiwa Utatuzi usiotumia waya umewashwa; la sivyo, huonyesha kitufe cha kumwasha.';

  @override
  String get helperMissingTitle => 'Msaidizi wa Waaiya amesimama';

  @override
  String get helperMissingBody =>
      'Simu hii haihifadhi ruhusa za Waaiya, kwa hiyo Waaiya hutumia msaidizi wake. Msaidizi husimama simu ikiwashwa upya na Waaiya ikisasishwa. Unganisha kwenye Wi-Fi, washa “Utatuzi usiotumia waya” katika Chaguo za wasanidi programu, kisha uguse “Washa msaidizi wa Waaiya”.';

  @override
  String get helperChannel => 'Msaidizi wa Waaiya';

  @override
  String get helperStarting => 'Inamwasha msaidizi…';

  @override
  String get helperModeNote =>
      'Simu hii hairuhusu programu kubaki na ruhusa hizi: msaidizi wa Waaiya ndiye anayefanya kazi hiyo. Husimama simu ikiwashwa upya na Waaiya ikisasishwa. Ukifungua Waaiya baada ya hapo, humwasha msaidizi tena yenyewe ikiwa Utatuzi usiotumia waya umewashwa; la sivyo, huonyesha kitufe cha kumwasha.';

  @override
  String get helperTipXiaomi =>
      'Hiari, ili kubaki na ruhusa kwa kudumu (bila msaidizi baada ya kuwasha upya): katika Chaguo za wasanidi programu, washa “Utatuzi wa USB (Mipangilio ya usalama)” (itakuomba uingie kwenye akaunti ya Xiaomi), kisha ufanye usanidi tena.';

  @override
  String get helperTipColoros =>
      'Hiari, ili kubaki na ruhusa kwa kudumu (bila msaidizi baada ya kuwasha upya): katika Chaguo za wasanidi programu, washa “Disable permission monitoring” (kwenye matoleo mapya zaidi “Disable system optimization”; huenda ikaonekana tu simu ikiwa imewekwa kwa Kiingereza), kisha ufanye usanidi tena.';

  @override
  String get stateOnHelperMissing =>
      'Sauti asili haijanyamazishwa, kwa hiyo unasikia muziki pamoja na sauti iliyochujwa: msaidizi wa Waaiya amesimama. Unganisha kwenye Wi-Fi, washa Utatuzi usiotumia waya, kisha uguse “Washa msaidizi wa Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Au tumia “Sanidi kwenye simu hii” kwenye ukurasa huu: msaidizi wa Waaiya kisha hufanya kazi bila swichi hiyo.';

  @override
  String get helperStartAnywayTitle => 'Msaidizi wa Waaiya amesimama';

  @override
  String get helperStartAnywayBody =>
      'Bila yeye utasikia muziki pamoja na sauti iliyochujwa. Mwashe msaidizi kwanza (Utatuzi usiotumia waya lazima uwe umewashwa), au anza uchujaji hata hivyo.';

  @override
  String get wsetupFailedTitle => 'Usanidi haukukamilika';

  @override
  String get wsetupPairing => 'Inaoanisha…';

  @override
  String get wsetupConnecting => 'Inaunganisha na kutoa ruhusa…';

  @override
  String get wsetupNeedWifi =>
      'Unganisha kwenye mtandao wa Wi-Fi kwanza (intaneti haihitajiki): Utatuzi usiotumia waya hufanya kazi kwenye Wi-Fi pekee.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Katika Chaguo za wasanidi programu, washa “Utatuzi usiotumia waya”, kisha uguse jina lake na “Oanisha kifaa ukitumia msimbo wa kuoanisha”.';

  @override
  String get wsetupOpenDialog =>
      'Katika Utatuzi usiotumia waya, gusa “Oanisha kifaa ukitumia msimbo wa kuoanisha”. Acha msimbo uonekane kwenye skrini kisha uguse “Weka msimbo” hapa.';

  @override
  String get wsetupEnterCodeBody =>
      'Gusa “Weka msimbo” na uandike msimbo wa tarakimu 6 unaoonyeshwa katika Mipangilio.';

  @override
  String get wsetupCodeWaiting =>
      'Msimbo umepokelewa. Inasubiri skrini ya “Oanisha kifaa ukitumia msimbo wa kuoanisha”: iache wazi.';

  @override
  String get wsetupWrongCode =>
      'Msimbo huo haukukubaliwa. Angalia tarakimu 6 kwenye skrini na uziweke tena. Ikiwa skrini ya kuoanisha imefungwa, ifungue tena: msimbo hubadilika.';

  @override
  String get wsetupPairingFailed =>
      'Kuoanisha hakukufaulu. Funga skrini ya kuoanisha, fungua “Oanisha kifaa ukitumia msimbo wa kuoanisha” tena na uweke msimbo mpya.';

  @override
  String get wsetupWaitingConnect =>
      'Imeoanishwa. Acha “Utatuzi usiotumia waya” ukiwa umewashwa: Waaiya inaunganisha.';

  @override
  String get wsetupNotPaired =>
      'Simu hii haiitambui tena Waaiya (uoanishaji uliondolewa au muda wake uliisha). Fungua “Oanisha kifaa ukitumia msimbo wa kuoanisha” na uweke msimbo.';

  @override
  String get wsetupConnectFailed =>
      'Imeshindwa kuunganisha kwenye Utatuzi usiotumia waya. Uzime kisha uuwashe tena: Waaiya itajaribu tena yenyewe.';

  @override
  String get wsetupGrantFailed =>
      'Imeunganishwa, lakini ruhusa bado hazipo. Tumia Shizuku au kompyuta hapa chini.';

  @override
  String get wsetupTimeout =>
      'Imesimama baada ya dakika 10 bila kukamilika. Unaweza kujaribu tena.';

  @override
  String get wsetupCodeUnreadable =>
      'Andika tarakimu 6 za msimbo wa kuoanisha.';

  @override
  String get wsetupCodeHint => 'Msimbo wa tarakimu 6';

  @override
  String get wsetupEnterCode => 'Weka msimbo';

  @override
  String wsetupDetail(String details) {
    return 'Maelezo: $details';
  }

  @override
  String get wsetupErrTimeout => 'hakuna jibu kwa wakati';

  @override
  String get wsetupErrRefused => 'muunganisho umekataliwa';

  @override
  String get wsetupDevOff =>
      'Chaguo za wasanidi programu zimezimwa. Katika Kuhusu simu, gusa “Nambari ya muundo” mara 7, kisha urudi.';

  @override
  String get wsetupOpenAbout => 'Kuhusu simu';

  @override
  String get wsetupNotifOff =>
      'Arifa za Waaiya zimezimwa, kwa hiyo msimbo hauwezi kuandikwa kwenye arifa. Tumia skrini iliyogawanywa (Mipangilio upande mmoja, Waaiya upande mwingine) na uguse “Andika msimbo hapa”.';

  @override
  String get wsetupCodeDialogTitle => 'Msimbo wa kuoanisha';

  @override
  String get wsetupCodeDialogBody =>
      'Kwa skrini iliyogawanywa tu (Mipangilio upande mmoja, Waaiya upande mwingine): ukiondoka kwenye Mipangilio, skrini ya kuoanisha hufungwa na msimbo wake huacha kufanya kazi. Andika msimbo wa tarakimu 6 unaoonyeshwa chini ya “Oanisha kifaa ukitumia msimbo wa kuoanisha”.';

  @override
  String get wsetupCodeOk => 'Oanisha';

  @override
  String get blurStrictTitle => 'Nani anaachwa bila kufunikwa';

  @override
  String blurStrictValue(String level) {
    return 'Nani anaachwa bila kufunikwa: $level';
  }

  @override
  String get blurStrict0 =>
      'Kali: watu ambao programu ina uhakika karibu kamili kuwa ni wanaume pekee';

  @override
  String get blurStrict1 =>
      'Wastani: takriban mara mbili ya wanaume wanaachwa bila kufunikwa';

  @override
  String get blurStrict2 => 'Legevu: wanaume wachache zaidi kuliko wastani';

  @override
  String get blurStrict0Short => 'kali';

  @override
  String get blurStrict1Short => 'wastani';

  @override
  String get blurStrict2Short => 'legevu';

  @override
  String get blurStrictHelp =>
      'Mtu yeyote ambaye programu haina uhakika kuwa ni mwanamume hufunikwa. Kali huacha takriban wanaume 7 kati ya 100 bila kufunikwa; wastani takriban 14, legevu takriban 16. Kila hatua ya ukali mdogo pia huacha takriban mwanamke 1 zaidi kati ya 100 bila kufunikwa.';

  @override
  String get stateOnNotMuted =>
      'Sauti asili bado haijanyamazishwa, kwa hiyo unasikia muziki pamoja na sauti iliyochujwa. Kamilisha usanidi wa mara moja hapa chini.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya haiwezi kunyamazisha sauti asili ya programu inayocheza sasa, kwa hiyo huenda muziki bado ukasikika. Simamisha kisha uanze uchujaji tena. Tatizo likiendelea, tuma ripoti ya uchunguzi (chini kabisa ya skrini hii).';

  @override
  String get stateTooSlow =>
      'Simu hii ni ya polepole mno kuchuja sauti moja kwa moja, kwa hiyo sauti hukatika. “Fungua kiungo” hapa chini bado hufanya kazi: huchuja video kabla ya kuicheza.';

  @override
  String get stateMonoNote =>
      'Sauti iko katika mono ili simu hii iweze kwenda sambamba.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Imenyamazishwa, kwa sababu hairuhusu uchujaji: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Inacheza bila kuchujwa, kwa sababu hairuhusu uchujaji: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android haikuipa Waaiya sauti ya programu nyingine. Gusa kitufe ili kuanza tena.';

  @override
  String get stateCaptureCancelled =>
      'Kuanza kumeghairiwa kwenye swali la Android la kushiriki skrini. Waaiya inahitaji uchague “Anza” (Start) hapo ili kupokea sauti. Hakuna kinachorekodiwa wala kutumwa.';

  @override
  String get startNoSetupTitle => 'Muziki bado utasikika';

  @override
  String get startNoSetupBody =>
      'Usanidi wa mara moja bado haujafanywa. Bila huo Waaiya haiwezi kunyamazisha sauti asili: utasikia muziki na sauti iliyochujwa kwa pamoja.\n\n“Fungua kiungo” hufanya kazi bila usanidi wowote.';

  @override
  String get startNoSetupSetup => 'Fanya usanidi';

  @override
  String get startNoSetupAnyway => 'Anza hata hivyo';

  @override
  String get diagButton => 'Kuna tatizo? Ripoti ya uchunguzi';

  @override
  String get diagTitle => 'Ripoti ya uchunguzi';

  @override
  String get diagNote =>
      'Kile ambacho Waaiya inaona kwenye simu hii. Kinakili au ukishiriki na yeyote anayekusaidia. Programu yenyewe haitumi chochote.';

  @override
  String get notifStoppedTitle => 'Waaiya imesimama';

  @override
  String get notifStoppedText => 'Sauti haichujwi tena. Gusa ili kuanza tena.';

  @override
  String get wsetupGuide => 'Hatua zenye picha';

  @override
  String get navFilter => 'Kichujio';

  @override
  String get navScreen => 'Skrini';

  @override
  String get navLinks => 'Viungo';

  @override
  String get navSetup => 'Usanidi';

  @override
  String get navSettings => 'Mipangilio';

  @override
  String get setupDoneTitle => 'Usanidi umekamilika';

  @override
  String get setupDoneBody =>
      'Waaiya inaweza kunyamazisha sauti asili ya programu nyingine. Ufanye tena tu ikiwa kitu kimebadilika (usanidi ulitenduliwa, au Waaiya inasema haupo).';

  @override
  String get setupRedo => 'Onyesha usanidi tena';

  @override
  String get setupGo => 'Nenda kwenye usanidi';

  @override
  String get helperTitle => 'Miguso kupitia vifuniko';

  @override
  String get helperBodyOff =>
      'Bila msaada, kifuniko huzuia miguso iliyo chini yake. Msaidizi wa Waaiya huchora vifuniko ili miguso ipite ndani yake. Washa Utatuzi usiotumia waya (Wi-Fi inahitajika) na uguse kitufe; mara ya kwanza, oanisha mara moja kama katika usanidi. Simu ikiwashwa upya, kiguse tena.';

  @override
  String get helperStart => 'Washa msaidizi wa Waaiya';

  @override
  String get helperOn =>
      'Msaidizi wa Waaiya anachora vifuniko: miguso hupita ndani yake. Husimama simu ikiwashwa upya au Utatuzi wa USB ukizimwa; hapo gusa kitufe tena.';

  @override
  String get helperShizukuOn =>
      'Shizuku inachora vifuniko: miguso hupita ndani yake.';

  @override
  String get helperOrShizuku => 'Au kwa Shizuku:';

  @override
  String get filterOptionsTitle => 'Chaguo za kichujio';

  @override
  String get settingsGeneralTitle => 'Jumla';

  @override
  String get worshipPrayerFajr => 'Alfajiri';

  @override
  String get worshipPrayerSunrise => 'Macheo';

  @override
  String get worshipPrayerDhuhr => 'Adhuhuri';

  @override
  String get worshipPrayerAsr => 'Alasiri';

  @override
  String get worshipPrayerMaghrib => 'Magharibi';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'Maliza ukimya sasa';

  @override
  String get worshipUnmute => 'Rudisha sauti sasa';

  @override
  String get worshipSmsDefault =>
      'Ni wakati wa swala, siwezi kujibu sasa. Nitakupigia baadaye.';

  @override
  String get desktopPreview =>
      'Onyesho la majaribio: injini ya kichujio bado haijaunganishwa kwenye kompyuta hii. Kitufe kinaonyesha tu jinsi programu itakavyofanya kazi.';

  @override
  String actionFailed(String details) {
    return 'Hilo halikufaulu: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Ala za muziki zinaondolewa kwenye programu zote.';

  @override
  String get engineErrorNoPactl =>
      'Zana za sauti hazikupatikana (pactl). Waaiya inahitaji PulseAudio, au PipeWire pamoja na pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Seva ya sauti haifanyi kazi (PulseAudio au PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Mfumo huu hauna kipindi cha mtumiaji cha systemd, ambacho huendesha kichujio chinichini.';

  @override
  String get engineErrorNoOutput =>
      'Hakuna spika wala vipokea sauti vya masikioni vilivyopatikana.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Imeshindwa kusakinisha kichujio. Maelezo:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Kichujio hakikuanza. Maelezo:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Kichujio kimesimama kwa hitilafu. Maelezo:\n$details';
  }

  @override
  String get autostartTitle => 'Anza unapoingia';

  @override
  String get autostartBody => 'Chuja sauti mara tu unapoingia kwenye kompyuta.';

  @override
  String get blurBodyDesktop =>
      'Hufunika watu na picha kwenye skrini, juu ya kila dirisha, wakati Waaiya iko wazi (hufanya kazi iwe kichujio cha sauti kimewashwa au kimezimwa). Hufanya kazi ndani ya kompyuta hii; hakuna kinachotumwa popote. Ukifunga dirisha la Waaiya, ufifishaji husimama.';

  @override
  String get blurFailBodyDesktop =>
      'Imewashwa: skrini nzima hufunikwa kompyuta ikiwa ya polepole mno au ufifishaji ukishindwa; mibofyo bado hufika kwenye madirisha yaliyo chini. Imezimwa: skrini hubaki ikionekana pamoja na upau mwekundu juu.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Ufifishaji umewashwa. Eneo-kazi hili huonyesha ufifishaji katika picha yake ya skrini yenyewe, kwa hiyo eneo lililofifishwa hubaki limefifishwa hadi mandhari ibadilike.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Ufifishaji hauwezi kuonyeshwa juu ya madirisha mengine kwenye eneo-kazi hili. Maelezo:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Chagua skrini yako kwenye dirisha la kushiriki skrini na uiruhusu. Waaiya huuliza mara moja tu; picha hubaki kwenye kompyuta hii.';

  @override
  String blurStatusExited(String details) {
    return 'Ufifishaji umesimama bila kutarajiwa. Zima kisha uwashe chaguo la ufifishaji ili ujaribu tena. Maelezo:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Kitambuzi cha uimbaji wa wanawake hakikupakiwa, kwa hiyo sauti za watu hunyamazishwa chaguo hilo likiwa limewashwa.';

  @override
  String get blurStatusUncovered =>
      'Skrini moja haijafunikwa na ufifishaji: haikushirikiwa nao, au iliunganishwa baadaye. Zima kisha uwashe chaguo la ufifishaji, na uchague kila skrini kwenye dirisha la kushiriki skrini.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Modeli za ufifishaji hazipo kwenye usakinishaji huu, kwa hiyo hauwezi kufunika chochote; upau mwekundu hubaki juu ya skrini. Sakinisha Waaiya upya.';

  @override
  String get diagNoteDesktop =>
      'Kile ambacho Waaiya inaona kwenye kompyuta hii. Kinakili na umpe yeyote anayekusaidia. Programu yenyewe haitumi chochote.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Inapendekezwa. Uchujaji ukisimama wenyewe (kwa hitilafu, si wewe), programu nyingine hubaki kimya hadi uanze tena au ubonyeze Simamisha, badala ya kucheza muziki bila kuchujwa.';

  @override
  String get settingStereoBodyDesktop =>
      'Imezimwa: mono, inayotumia kompyuta kidogo zaidi. Imewashwa: hutenganisha upande wa kushoto na wa kulia. Kompyuta ikiwa ya polepole mno kwa stereo, hujibadilisha yenyewe kuwa mono.';

  @override
  String get linkEntryBodyDesktop =>
      'Bandika kiungo cha YouTube, TikTok au Instagram ili ukitazame kichujio kikiwa kimewashwa, au ukihifadhi bila muziki.';

  @override
  String get linkEntryBodyWatch =>
      'Bandika kiungo cha YouTube, TikTok au Instagram ili ukitazame kwenye kivinjari chako kichujio kikiwa kimewashwa.';

  @override
  String get linkWatchNoteDesktop =>
      'Hufunguka kwenye kivinjari chako. Waaiya huwasha kichujio kwanza, kwa hiyo muziki huondolewa huko pia.';

  @override
  String get linkFilterFailed =>
      'Kichujio hakikuanza, kwa hiyo kiungo hakikufunguliwa. Kiwashe kwenye ukurasa wa Kichujio kisha ujaribu tena.';

  @override
  String get linkSavedVideoDesktop =>
      'Kwenye folda yako ya Video (Videos): Waaiya';

  @override
  String get linkSavedAudioDesktop =>
      'Kwenye folda yako ya Muziki (Music): Waaiya';

  @override
  String get linkShowInFolder => 'Onyesha kwenye folda';

  @override
  String get linkSingingNote =>
      'Uimbaji wa wanawake pia hunyamazishwa, kama ilivyo kwenye mipangilio yako.';

  @override
  String get singingKeepTitle => 'Bakiza uimbaji (majaribio)';

  @override
  String get singingKeepBody =>
      'Ala za muziki zinaondolewa lakini sauti za uimbaji zinabaki, kwa hiyo mhadhara wenye nashidi chini yake unabakiza sauti ya nashidi pia; kama hilo linakubalika ni uamuzi wako.';

  @override
  String get singingKeepNoModel =>
      'Toleo hili halina modeli ya uimbaji, kwa hiyo sauti hubaki kimya chaguo hili likiwa limewashwa. Lizime.';

  @override
  String get fixFilterAppsTitle => 'Programu zinazosikika bila kuchujwa';

  @override
  String get fixFilterAppsBody =>
      'Programu hizi hucheza sauti yao asili: Waaiya haizichuji wala haizinyamazishi.';

  @override
  String get fixAddApp => 'Ongeza programu';

  @override
  String fixRemoveApp(Object app) {
    return 'Ondoa $app';
  }

  @override
  String get fixNoApps => 'Hakuna programu iliyochaguliwa.';

  @override
  String get fixPickTitle => 'Chagua programu';

  @override
  String get fixPickEmpty => 'Hakuna programu nyingine iliyopatikana.';

  @override
  String get fixPickPlayingDesktop =>
      'Programu zinazocheza sauti sasa, na zile zilizokwisha chaguliwa.';

  @override
  String get fixCancel => 'Ghairi';

  @override
  String get fixBlurAppsTitle => 'Programu zisizofunikwa';

  @override
  String get fixBlurAppsBody =>
      'Hakuna vifuniko wakati mojawapo ya programu hizi iko peke yake kwenye skrini. Vifuniko hurudi mara tu unapoiacha, au wakati wowote Waaiya haina uhakika ni programu gani inaonyeshwa.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Inahitaji usanidi wa mara moja: bila huo Waaiya haiwezi kujua ni programu gani iko kwenye skrini, kwa hiyo ufifishaji hubaki kila mahali.';

  @override
  String get fixBlurAppsHelperMode =>
      'Msaidizi wa Waaiya hafanyi kazi, kwa hiyo programu iliyo kwenye skrini haiwezi kusomwa. Ufifishaji hubaki kila mahali hadi msaidizi awashwe tena kutoka ukurasa wa Usanidi.';

  @override
  String get fixHandTitle => 'Funika eneo kwa mkono';

  @override
  String get fixHandBody =>
      'Ufifishaji ukiwa unafanya kazi, buruta juu ya sehemu yoyote ya skrini ili uifunike. Hubaki imefunikwa hadi uiondoe au ufifishaji usimame.';

  @override
  String get fixHandNotRunning =>
      'Inapatikana wakati ufifishaji unafanya kazi: uchujaji umewashwa na chaguo la ufifishaji limewashwa.';

  @override
  String get fixCoverArea => 'Funika eneo';

  @override
  String fixRemoveCovers(Object count) {
    return 'Ondoa vifuniko vya mkono ($count)';
  }

  @override
  String get fixNoteTitle => 'Andika kosa';

  @override
  String get fixNoteBody =>
      'Liwekee alama linapotokea. Dokezo huhifadhi saa, programu na mipangilio. Hubaki kwenye kifaa hiki na halitumwi kamwe.';

  @override
  String get fixMissedSound => 'Muziki ulipita';

  @override
  String get fixWrongSound => 'Sauti ya mtu iliondolewa kimakosa';

  @override
  String get fixMissedScreen => 'Kitu hakikufunikwa';

  @override
  String get fixWrongScreen => 'Kimefunikwa kimakosa';

  @override
  String fixNoted(Object count) {
    return 'Imeandikwa (madokezo $count kwenye kifaa hiki).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Madokezo kwenye kifaa hiki: $count';
  }

  @override
  String get fixNotesShow => 'Onyesha madokezo';

  @override
  String get fixNotesDelete => 'Futa madokezo';

  @override
  String get fixNotesDeleteAsk =>
      'Futa madokezo yote? Hili haliwezi kutenduliwa.';

  @override
  String get fixNotesTitle => 'Madokezo ya utambuzi usio sahihi';

  @override
  String get worshipTitle => 'Nyakati za swala';

  @override
  String get worshipBody =>
      'Si lazima. Huhesabiwa kwenye simu hii kutokana na mahali unapochagua. Hakuna kinachotumwa.';

  @override
  String worshipPlace(Object place) {
    return 'Mahali: $place';
  }

  @override
  String get worshipPlaceNone => 'Mahali: hapajachaguliwa';

  @override
  String get worshipChoose => 'Chagua';

  @override
  String get worshipPlaceSearch => 'Tafuta mji';

  @override
  String get worshipPlaceNoMatch =>
      'Hakuna mji uliopatikana. Unaweza kuweka viwianishi badala yake.';

  @override
  String get worshipPlaceCustom => 'Weka viwianishi';

  @override
  String get worshipLat => 'Latitudo (kaskazini +, kusini −)';

  @override
  String get worshipLon => 'Longitudo (mashariki +, magharibi −)';

  @override
  String get worshipZone => 'Saa za eneo, kwa mfano Africa/Nairobi';

  @override
  String get worshipCustomInvalid => 'Kagua namba na saa za eneo.';

  @override
  String get worshipPlaceInvalid =>
      'Mahali hapa hapawezi kutumika. Pachague tena.';

  @override
  String worshipMethod(Object method) {
    return 'Hesabu: $method';
  }

  @override
  String get worshipMethodTitle => 'Njia ya kuhesabu';

  @override
  String get worshipMethodNote =>
      'Imechaguliwa kutokana na nchi ya mji. Chagua ile inayofuatwa na msikiti wako.';

  @override
  String worshipAsr(Object rule) {
    return 'Alasiri: $rule';
  }

  @override
  String get worshipAsrTitle => 'Wakati wa Alasiri';

  @override
  String get worshipAsrStandard => 'Kawaida (Shafi\'i, Maliki, Hanbali)';

  @override
  String get worshipAsrHanafi => 'Hanafi';

  @override
  String get worshipMethodMwl =>
      'Muslim World League (Jumuiya ya Kiislamu ya Dunia)';

  @override
  String get worshipMethodIsna =>
      'Jumuiya ya Kiislamu ya Amerika Kaskazini (ISNA)';

  @override
  String get worshipMethodEgypt => 'Mamlaka Kuu ya Upimaji ya Misri';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, Makka';

  @override
  String get worshipMethodKarachi =>
      'Chuo Kikuu cha Sayansi za Kiislamu, Karachi';

  @override
  String get worshipMethodTehran =>
      'Taasisi ya Jiofizikia, Chuo Kikuu cha Tehran';

  @override
  String get worshipMethodGulf => 'Eneo la Ghuba';

  @override
  String get worshipMethodKuwait => 'Kuwait';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Uturuki (Diyanet)';

  @override
  String get worshipMethodFrance => 'Ufaransa (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Moroko (Wizara ya Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesia (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malaysia (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Leo';

  @override
  String get worshipNoTimes =>
      'Hakuna nyakati za swala hapa leo: jua halichomozi au halitui.';

  @override
  String get worshipSilentTitle => 'Kimya wakati wa swala';

  @override
  String get worshipSilentBody =>
      'Kuanzia kila wakati wa swala, Usisumbue huwashwa kwa dakika zilizo hapa chini, kisha simu hurudi jinsi ulivyoiweka.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Kimya kwa: dakika $minutes';
  }

  @override
  String get worshipMuteTitle => 'Nyamazisha maudhui wakati wa adhana';

  @override
  String get worshipMuteBody =>
      'Kila wakati wa swala, sauti ya maudhui (video, muziki, michezo) hunyamazishwa kwa dakika zilizo hapa chini. Arifa inaweza kurudisha sauti mara moja.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Imenyamazishwa kwa: dakika $minutes';
  }

  @override
  String get worshipMinutesTitle => 'Muda';

  @override
  String worshipMinutesOption(Object minutes) {
    return 'dakika $minutes';
  }

  @override
  String get worshipNeedPlace => 'Chagua mahali kwanza.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Inayofuata: $prayer saa $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Kimya hadi $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Maudhui yamenyamazishwa hadi $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Iruhusu Waaiya kubadilisha Usisumbue, la sivyo simu haiwezi kuwa kimya.';

  @override
  String get worshipAllow => 'Ruhusu';

  @override
  String get worshipExactNeeded =>
      'Kengele na vikumbusho haviruhusiwi kwa Waaiya, kwa hiyo kila badiliko linaweza kuchelewa hadi dakika 10, au zaidi simu ikiwa imelala.';

  @override
  String get worshipNotificationsNeeded =>
      'Arifa zimezimwa: hutaona simu inapokuwa kimya au inaporudi.';

  @override
  String get worshipTonesTitle =>
      'Mlio wa simu na sauti ya arifa isiyo na muziki';

  @override
  String get worshipTonesBody =>
      'Waaiya haiwezi kuchuja mlio wa simu wala sauti za arifa, inaweza tu kuzibadilisha. Chagua mlio rahisi usio na muziki:';

  @override
  String worshipToneRing(Object number) {
    return 'Mlio rahisi wa simu $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Sauti rahisi ya arifa $number';
  }

  @override
  String get worshipTonePlay => 'Cheza';

  @override
  String get worshipToneSet => 'Tumia';

  @override
  String get worshipToneInUse => 'Inatumika';

  @override
  String get worshipToneDone => 'Imekamilika.';

  @override
  String get worshipTonePermission =>
      'Iruhusu Waaiya kurekebisha mipangilio ya mfumo, rudi, kisha uguse tena.';

  @override
  String get worshipToneFailed =>
      'Simu hii haikuiruhusu Waaiya kuibadilisha. Kwenye mipangilio ya Sauti, chagua mlio unaoitwa “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Fungua mipangilio ya Sauti';

  @override
  String get worshipSmsTitle => 'Jibu simu kwa SMS wakati wa swala';

  @override
  String get worshipSmsBody =>
      'Katika dakika za kimya baada ya kila wakati wa swala, simu inayoachwa ikilia hupata SMS moja. Mara moja kwa kila namba kwa kila swala; kamwe si kwa namba zilizofichwa au namba fupi.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Baada ya: sekunde $seconds za kulia';
  }

  @override
  String get worshipSmsDelayTitle => 'Sekunde za kulia kabla ya SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return 'sekunde $seconds';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Ujumbe: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Ujumbe wako';

  @override
  String get worshipSmsTextDefault => 'Tumia ujumbe wa kawaida';

  @override
  String get worshipSmsCost =>
      'Kila jibu ni SMS ya kawaida kutoka kwa SIM yako, kwa bei ya kifurushi chako. Hakuna kinachotumwa ukiwa kwenye urandaji (roaming).';

  @override
  String get worshipSmsRoaming =>
      'Uko kwenye urandaji sasa: hakuna SMS inayotumwa.';

  @override
  String get worshipSmsLogTitle =>
      'Majibu yaliyotumwa (yanahifadhiwa kwenye simu hii tu)';

  @override
  String get worshipContinue => 'Endelea';

  @override
  String get worshipWhyDnd =>
      'Ili simu iwe kimya wakati wa swala, ruhusu ufikiaji wa Usisumbue kwa Waaiya kwenye ukurasa unaofuata.';

  @override
  String get worshipWhyExact =>
      'Ili kufanya kazi kwa wakati kamili, iruhusu Waaiya kuweka kengele na vikumbusho kwenye ukurasa unaofuata. Bila hivyo, mabadiliko yanaweza kuchelewa hadi dakika 10.';

  @override
  String get worshipWhyNotifications =>
      'Ruhusu arifa ili uone kila badiliko na uweze kulitendua.';

  @override
  String get worshipWhyWrite =>
      'Ili kubadilisha mlio wa simu au sauti ya arifa, iruhusu Waaiya kurekebisha mipangilio ya mfumo kwenye ukurasa unaofuata.';

  @override
  String get worshipWhyPhone =>
      'Ili kujua kwamba simu inalia na namba yake, Waaiya inahitaji ruhusa za Simu na Rekodi za simu. Hakuna kinachotoka kwenye simu isipokuwa jibu lako.';

  @override
  String get worshipWhySms =>
      'Ili kutuma jibu lako, Waaiya inahitaji ruhusa ya kutuma SMS. Hutuma jibu hilo tu, isizidi mara moja kwa kila namba kwa kila swala.';

  @override
  String get worshipMissingDnd =>
      'Ufikiaji wa Usisumbue haukuruhusiwa, kwa hiyo ukimya unabaki umezimwa.';

  @override
  String get worshipMissingPhone =>
      'Ruhusa za Simu na Rekodi za simu hazikuruhusiwa, kwa hiyo jibu la SMS linabaki limezimwa.';

  @override
  String get worshipMissingSms =>
      'Ruhusa ya kutuma SMS haikuruhusiwa, kwa hiyo jibu la SMS linabaki limezimwa.';

  @override
  String get worshipTryAgain => 'Jaribu tena';

  @override
  String get protectTitle => 'Ulinzi kwa nyakati za udhaifu';

  @override
  String get protectBody =>
      'Amua sasa, ukiwa mtulivu: badiliko linalopunguza ulinzi husubiri kabla ya kuanza kutumika. Mzazi pia anaweza kuweka PIN.';

  @override
  String protectDelay(Object value) {
    return 'Muda wa kusubiri: $value';
  }

  @override
  String get protectDelayTitle => 'Muda wa kusubiri';

  @override
  String get protectDelayBody =>
      'Kusimamisha kichujio, kuzima kifuniko au kitu kingine chochote kinachopunguza ulinzi husubiri muda huu. Kisha unakithibitisha ndani ya dakika 15, la sivyo hakuna kinachobadilika. Kuwasha vitu hufanya kazi mara moja kila wakati.';

  @override
  String get protectDelayOff => 'Hakuna';

  @override
  String get protectDelay1m => 'Dakika 1';

  @override
  String get protectDelay5m => 'Dakika 5';

  @override
  String get protectDelay15m => 'Dakika 15';

  @override
  String get protectDelay30m => 'Dakika 30';

  @override
  String get protectDelay1h => 'Saa 1';

  @override
  String get protectDelay4h => 'Saa 4';

  @override
  String get protectDelay24h => 'Saa 24';

  @override
  String protectDelayOther(Object minutes) {
    return 'Dakika $minutes';
  }

  @override
  String get protectPinNone => 'PIN: haijawekwa';

  @override
  String get protectPinIsSet => 'PIN: imewekwa';

  @override
  String get protectPinSet => 'Weka PIN';

  @override
  String get protectPinRemove => 'Ondoa';

  @override
  String get protectPinBody =>
      'Ukiwa na PIN, kila badiliko linalopunguza ulinzi huiomba kwanza. Kubadilisha muda wa kusubiri au PIN huiomba pia.';

  @override
  String get protectPinForgot =>
      'PIN ikisahauliwa, hakuna njia ya kuiweka upya: ni kufuta data ya Waaiya au kuisakinisha upya tu, jambo ambalo pia hufuta mipangilio yake yote.';

  @override
  String get protectPinTitle => 'Weka PIN';

  @override
  String get protectPinNewTitle => 'Chagua PIN';

  @override
  String get protectPinChangeTitle => 'Badilisha PIN';

  @override
  String get protectPinCurrent => 'PIN ya sasa';

  @override
  String get protectPinNew => 'PIN mpya (tarakimu 4 hadi 8)';

  @override
  String get protectPinAgain => 'PIN mpya tena';

  @override
  String get protectPinBad => 'Tumia tarakimu 4 hadi 8.';

  @override
  String get protectPinDiffer => 'PIN mbili mpya hazifanani.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN si sahihi. Majaribio $count yamebaki kabla ya kusubiri.';
  }

  @override
  String protectLocked(Object time) {
    return 'Majaribio mengi mno yasiyo sahihi. Jaribu tena ifikapo $time.';
  }

  @override
  String get protectOk => 'Sawa';

  @override
  String get protectCancel => 'Ghairi';

  @override
  String get protectCancelChange => 'Ghairi badiliko';

  @override
  String get protectConfirm => 'Thibitisha';

  @override
  String protectPending(Object time, Object what) {
    return '$what: itaanza kutumika ifikapo $time.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: kusubiri kumekwisha. Bado unaitaka? Thibitisha kabla ya $time, la sivyo hakuna kitakachobadilika.';
  }

  @override
  String get protectWaitTitle => 'Badiliko hili linasubiri';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what: itaanza kutumika ifikapo $time, ikiwa bado unaitaka wakati huo. Utaithibitisha hapa ndani ya dakika 15 baada ya hapo.';
  }

  @override
  String get protectWaitStart => 'Anza kusubiri';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Tayari inasubiri: itaanza kutumika ifikapo $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Itaanza kutumika ifikapo $time. Ithibitishe wakati huo.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'kesho saa $time';
  }

  @override
  String get protectHeldBack =>
      'Badiliko hili limezuiliwa na mipangilio ya ulinzi.';

  @override
  String get protectLimits =>
      'Kile ambacho hiki hakiwezi kuzuia: kulazimisha kusimama, kuondoa programu, kufuta data ya Waaiya na mipangilio ya Android yenyewe. Kuzuia hayo kunahitaji mamlaka ya msimamizi wa kifaa au ya ufikivu ambayo Waaiya haitumii. Hiki hulinda dhidi ya wakati wa udhaifu, si dhidi ya mtu aliyedhamiria.';

  @override
  String get protectLimitsDesktop =>
      'Kile ambacho hiki hakiwezi kuzuia: amri ya waaiya kwenye terminal, kuondoa Waaiya au kufuta folda yake ya mipangilio. Hiki hulinda dhidi ya wakati wa udhaifu, si dhidi ya mtu aliyedhamiria.';

  @override
  String get protectWhatStop => 'Kusimamisha kichujio';

  @override
  String protectWhatOff(Object name) {
    return 'Kuzima: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Kuwasha: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Kuongeza programu kwenye: $name';
  }

  @override
  String get protectWhatStrictness => 'Kupunguza ukali wa ufifishaji';

  @override
  String get protectWhatGender => 'Kubadilisha anayetumia simu';

  @override
  String protectWhatDelay(Object value) {
    return 'Kubadilisha muda wa kusubiri kuwa: $value';
  }

  @override
  String get protectWhatPinChange => 'Kubadilisha PIN';

  @override
  String get protectWhatPinClear => 'Kuondoa PIN';

  @override
  String get protectWhatSetting => 'Kubadilisha mpangilio';
}
