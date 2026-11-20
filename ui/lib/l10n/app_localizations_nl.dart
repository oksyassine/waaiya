// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Haalt muziekinstrumenten uit elke app en houdt spraak en recitatie.';

  @override
  String get onboardTitle => 'Welkom';

  @override
  String get onboardBody =>
      'Waaiya haalt muziekinstrumenten uit het geluid van elke app op deze telefoon. Spraak en Koranrecitatie blijven behouden. Voorlopig worden zangstemmen ook verwijderd.';

  @override
  String get onboardQuestion => 'Ik ben';

  @override
  String get genderMan => 'Een man';

  @override
  String get genderWoman => 'Een vrouw';

  @override
  String get onboardWhy =>
      'Dit bepaalt alleen welke extra instellingen je ziet. Je kunt het later wijzigen.';

  @override
  String get stateOnTitle => 'Filteren staat aan';

  @override
  String get stateOffTitle => 'Filteren staat uit';

  @override
  String get stateStarting => 'Starten…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Instrumenten worden uit alle apps verwijderd. Vertraging ongeveer $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Tik op de knop om te starten.';

  @override
  String get stateModelFailed =>
      'Het geluidsmodel kon niet laden, dus het geluid is voor de zekerheid gedempt.';

  @override
  String get stateCaptureDenied =>
      'De toestemming voor de microfoon is nodig om het geluid van andere apps te ontvangen.';

  @override
  String get stateStoppedBySystem =>
      'Android heeft het filteren gestopt. Tik op de knop om opnieuw te starten.';

  @override
  String get stateSilencedTitle => 'Filteren gestopt';

  @override
  String get stateSilenced =>
      'Filteren gestopt: andere apps zijn gedempt. Tik op de knop om opnieuw te starten, of op Stoppen om ze ongefilterd te horen.';

  @override
  String get releaseSilence => 'Stoppen: apps ongefilterd horen';

  @override
  String get powerStartCd => 'Filteren starten';

  @override
  String get powerStopCd => 'Filteren stoppen';

  @override
  String get captureHint =>
      'Android vraagt of je je scherm wilt delen. Alleen het geluid wordt gebruikt: er wordt niets opgenomen of verstuurd.';

  @override
  String get needRecordAudio =>
      'Waaiya heeft de toestemming voor de microfoon nodig om het geluid van andere apps te ontvangen. Het neemt jou nooit op.';

  @override
  String get setupBannerTitle => 'Nog één stap';

  @override
  String get setupBannerBody =>
      'Zonder de eenmalige installatie hieronder hoor je de muziek en het gefilterde geluid tegelijk.';

  @override
  String get step1Title => 'Shizuku installeren';

  @override
  String get step1Body => 'Een gratis hulpapp uit de Play Store.';

  @override
  String get step1Action => 'Shizuku downloaden';

  @override
  String get step2Title => 'Shizuku starten';

  @override
  String get step2Body =>
      'Shizuku start via wifi met de draadloze foutopsporing van Android. Tik op de knop voor de stappen en kom dan terug.';

  @override
  String get step2Action => 'Shizuku openen';

  @override
  String get step2Update => 'Shizuku updaten';

  @override
  String get step2TooOld =>
      'Je versie van Shizuku is te oud. Update hem via de Play Store.';

  @override
  String get step2Denied =>
      'Shizuku is ingesteld om Waaiya altijd te weigeren. Sta het toe in de lijst met apps in Shizuku.';

  @override
  String get step3Title => 'Toestemming geven';

  @override
  String get step3Body => 'Eén tik, kies dan “Toestaan”.';

  @override
  String get step3Action => 'Toestemming geven';

  @override
  String get step3Busy => 'Bezig met instellen…';

  @override
  String get setupDoneRestart =>
      'Klaar. Stop het filteren en start het één keer opnieuw om dit toe te passen.';

  @override
  String setupFailed(String details) {
    return 'De installatie is niet voltooid. Details:\n$details';
  }

  @override
  String get shizukuRefused =>
      'De toestemming voor Shizuku is geweigerd. Tik op de knop om het opnieuw te proberen.';

  @override
  String get setupSlow =>
      'Shizuku doet er langer over dan normaal. Even geduld: op sommige telefoons duurt het de eerste keer tot een minuut voordat de helper ervan start.';

  @override
  String get setupTimeout =>
      'Shizuku heeft binnen 2 minuten niet geantwoord. Open Shizuku, controleer of er staat dat het actief is en tik dan opnieuw op de knop. Als de installatie later klaar is, wordt dit scherm vanzelf bijgewerkt.';

  @override
  String get setupRefusedXiaomi =>
      'Deze telefoon heeft de toestemmingen geweigerd. Zet op Xiaomi, Redmi en POCO “USB-foutopsporing (Beveiligingsinstellingen)” aan in Ontwikkelaarsopties (je moet dan inloggen met een Xiaomi-account) en probeer het opnieuw.';

  @override
  String get setupRefusedColoros =>
      'Deze telefoon heeft de toestemmingen geweigerd. Zet op OPPO, OnePlus en realme in Ontwikkelaarsopties “Disable permission monitoring” (Machtigingscontrole uitschakelen) aan. In de nieuwste versies heet het “Disable system optimization” (Systeemoptimalisatie uitschakelen), en misschien is het alleen te zien als de telefoon op Engels staat. Zoek “permission” of “machtiging” in Instellingen om het te vinden. Probeer het dan opnieuw.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi en POCO: als de melding geen veld heeft om de code in te typen, zet dan de meldingsstijl op “Android” in de meldingsinstellingen, of typ de code in Waaiya met een gesplitst scherm.';

  @override
  String get stepDoneCd => 'Klaar';

  @override
  String stepTodoCd(int step) {
    return 'Stap $step';
  }

  @override
  String get computerToggle => 'Liever een computer gebruiken';

  @override
  String get computerBody =>
      'Zet USB-foutopsporing aan, sluit de telefoon aan en voer dit uit:';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get computerNote =>
      'De tweede regel is optioneel: daarmee komt de vraag over scherm delen niet meer bij elke start.';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingSilenceTitle => 'Apps dempen die filteren blokkeren';

  @override
  String get settingSilenceBody =>
      'Aanbevolen. Sommige apps staan niet toe dat hun geluid wordt gefilterd; dit dempt ze in plaats van muziek door te laten.';

  @override
  String get settingHoldSilenceTitle =>
      'Apps stil houden als het filteren vanzelf stopt';

  @override
  String get settingHoldSilenceBody =>
      'Aanbevolen. Als Android het filteren beëindigt (niet jij), blijven andere apps stil tot je opnieuw start of op Stoppen tikt, in plaats van ongefilterde muziek af te spelen. Hiervoor is de eenmalige installatie nodig.';

  @override
  String get settingStereoTitle => 'Stereogeluid';

  @override
  String get settingStereoBody =>
      'Uit: mono, dat ongeveer half zoveel batterij gebruikt en op meer telefoons bijblijft. Aan: houdt links en rechts gescheiden. Als de telefoon te traag is voor stereo, schakelt hij toch vanzelf over naar mono.';

  @override
  String get settingSingingTitle => 'Zang van vrouwen dempen';

  @override
  String get settingSingingBody => 'De spraak van vrouwen blijft behouden.';

  @override
  String get settingSingingNoModel =>
      'Deze versie heeft geen zangdetector, dus alle stemmen worden gedempt zolang dit aan staat.';

  @override
  String get settingRestart =>
      'Stop het filteren en start het opnieuw om wijzigingen toe te passen.';

  @override
  String get settingGenderTitle => 'Ik ben';

  @override
  String get change => 'Wijzigen';

  @override
  String get playerTitle => 'Video\'s perfect synchroon';

  @override
  String get playerBody =>
      'Deel een video met Waaiya (of gebruik “Openen met”) om hem zonder vertraging gefilterd te bekijken.';

  @override
  String get licences => 'Opensourcelicenties';

  @override
  String get licencesIntro =>
      'Waaiya is vrije software onder de GNU Affero General Public License v3 of later. Broncode: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Naamsvermelding 4.0 (trainingsdata): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Volledige teksten';

  @override
  String get back => 'Terug';

  @override
  String get linkEntryTitle => 'Een link openen';

  @override
  String get linkEntryBody =>
      'Plak een link van YouTube, TikTok of Instagram om hem zonder muziek te bekijken of op te slaan.';

  @override
  String get linkTitle => 'Een link openen';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Link naar video of audio';

  @override
  String get linkPaste => 'Plakken';

  @override
  String get linkOpen => 'Openen';

  @override
  String get linkResolving => 'Link openen…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Bekijken zonder muziek';

  @override
  String get linkSave => 'Opslaan zonder muziek';

  @override
  String get linkListen => 'Luisteren zonder muziek';

  @override
  String get linkAudioOnly =>
      'De video van deze link kan nog niet worden geopend: alleen het geluid.';

  @override
  String get linkDownloading => 'Downloaden…';

  @override
  String get linkFiltering => 'Muziek verwijderen…';

  @override
  String get linkCancel => 'Annuleren';

  @override
  String get linkCancelled => 'Geannuleerd. Er is niets opgeslagen.';

  @override
  String get linkTimedOut =>
      'Android heeft het opslaan gestopt: dit soort werk mag maar een paar uur per dag. Er is niets opgeslagen; open Waaiya en probeer het opnieuw.';

  @override
  String get linkExportFailed =>
      'Kon deze niet opslaan. Er is niets opgeslagen.';

  @override
  String get linkSaved => 'Opgeslagen zonder muziek';

  @override
  String get linkSavedVideo => 'In je galerij: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'In je muziek: Music › Waaiya';

  @override
  String get linkPlay => 'Afspelen';

  @override
  String get linkShare => 'Delen';

  @override
  String get linkShareNote => 'Deel alleen video\'s die je mag delen.';

  @override
  String get linkLive => 'Livestreams kunnen niet worden opgeslagen.';

  @override
  String get linkBusy =>
      'Er wordt al een andere video opgeslagen. Wacht tot die klaar is.';

  @override
  String get linkInvalid => 'Plak een weblink (die begint met https://).';

  @override
  String get linkLogin =>
      'De site wilde deze video niet laten zien zonder account. Openbare berichten gaan meestal wel open: probeer het over een paar minuten opnieuw. Privéberichten kunnen niet worden geopend.';

  @override
  String get linkUnsupported => 'Deze site wordt niet ondersteund.';

  @override
  String get linkPlaylist => 'Dit is een afspeellijst. Open één video.';

  @override
  String get linkNoFormat =>
      'Deze video heeft een formaat dat Waaiya nog niet kan filteren.';

  @override
  String get linkFailed =>
      'Kon deze link niet openen. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get linkPlayFailed =>
      'Kon dit niet afspelen. Er is niets ongefilterd afgespeeld.';

  @override
  String get linkLimited =>
      'De site beperkt op dit moment het aantal verzoeken. Probeer het over een paar minuten opnieuw.';

  @override
  String get blurTitle => 'Schermvervaging';

  @override
  String get blurBody =>
      'Bedekt mensen en afbeeldingen op het scherm, in elke app, terwijl het filteren aan staat. Het werkt op de telefoon zelf; er wordt niets verstuurd.';

  @override
  String get blurWomenTitle => 'Vrouwen vervagen';

  @override
  String get blurWomenBody =>
      'Het hele lichaam. Mensen van wie de app niet duidelijk ziet dat het mannen zijn, worden ook vervaagd.';

  @override
  String get blurNudityTitle => 'Onzedige beelden vervagen';

  @override
  String get blurNudityBody =>
      'Naaktheid en onthullende kleding, van wie dan ook: het hele scherm wordt bedekt.';

  @override
  String get blurFailTitle =>
      'Scherm bedekken als de vervaging het niet bijhoudt';

  @override
  String get blurFailBody =>
      'Aan: het hele scherm wordt bedekt als de telefoon te traag is of de vervaging mislukt. Uit: het scherm blijft zichtbaar met een waarschuwing.';

  @override
  String get blurSetupShizuku => 'Toestaan met Shizuku';

  @override
  String get blurSetupManual => 'Toestaan in Android-instellingen';

  @override
  String get blurStatusNeedsSetup =>
      'De vervaging moet over andere apps heen kunnen tekenen. Het beste: sta het toe met Shizuku (dat zet de toegankelijkheidsservice Waaiya-vervaging aan, zodat tikken nog steeds de app eronder bereiken). Of sta “Weergeven over andere apps” toe in de Android-instellingen (tikken op een vervaagd gebied gaan dan verloren).';

  @override
  String get blurStatusNeedsOverlay =>
      'De vervaging moet over andere apps heen kunnen tekenen. Het beste: start Shizuku (en sta Waaiya daarin toe): de vervaging tekent dan een eigen laag waar tikken doorheen gaan. Sta anders “Weergeven over andere apps” toe in de Android-instellingen; een tik op een vervaagd gebied bereikt dan niet de app eronder.';

  @override
  String get blurFailUnavailable =>
      'Voorlopig grijs: een afdekking over het hele scherm zou elke tik blokkeren en je zou vast kunnen komen te zitten. Start de helper van Waaiya of Shizuku (Android 12 of nieuwer) en deze optie wordt beschikbaar: de afdekkingen worden dan zo getekend dat tikken erdoorheen gaan. Tot die tijd blijft het scherm zichtbaar met een waarschuwing als de vervaging het niet bijhoudt.';

  @override
  String get blurFailNeedsA11y =>
      'Voorlopig grijs: een afdekking over het hele scherm zou elke tik blokkeren en je zou vast kunnen komen te zitten. Start Shizuku (Android 12 of nieuwer) of zet de toegankelijkheidsservice Waaiya-vervaging aan (Toestaan met Shizuku, hierboven), en deze optie wordt beschikbaar. Tot die tijd blijft het scherm zichtbaar met een waarschuwing.';

  @override
  String get languageTitle => 'Taal';

  @override
  String settingLanguageTitle(String language) {
    return 'Taal: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Stop het filteren en start het opnieuw om de instellingen voor vervaging toe te passen.';

  @override
  String get blurStatusStarting => 'Vervaging start…';

  @override
  String get blurStatusOn => 'Vervaging aan.';

  @override
  String get blurStatusOnVisible =>
      'Vervaging aan, in voorzichtige modus: deze telefoon toont de vervaging in zijn eigen schermopname, dus een vervaagd gebied blijft vervaagd tot het beeld verandert.';

  @override
  String get blurStatusModels =>
      'Deze versie heeft geen vervagingsmodel voor de gekozen optie.';

  @override
  String get blurStatusFailing => 'De vervaging kan het nu niet bijhouden.';

  @override
  String get blurStatusNoOverlay =>
      'De vervaging kan niet over andere apps tekenen: sta het hierboven toe.';

  @override
  String blurStatusNoCapture(String details) {
    return 'De vervaging kan het scherm niet zien. Details:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku kon het niet toestaan:\n$details';
  }

  @override
  String get step2Guide => 'Zo start je Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Grijs: op deze Android-versie zou een afdekking over het hele scherm elke tik blokkeren en je zou vast kunnen komen te zitten (afdekkingen via Shizuku hebben Android 12 of nieuwer nodig). Als de vervaging het niet bijhoudt, blijft het scherm zichtbaar met een waarschuwing.';

  @override
  String get guideTitle => 'Shizuku starten, stap voor stap';

  @override
  String get guideOpenDev => 'Ontwikkelaarsopties';

  @override
  String get guideOpenShizuku => 'Shizuku openen';

  @override
  String get guideClose => 'Sluiten';

  @override
  String get guideBody =>
      'Je hebt wifi en Android 11 of nieuwer nodig. Koppelen doe je één keer; na een herstart van de telefoon herhaal je alleen stap 7.\n\n1. Verbind de telefoon met wifi.\n\n2. Zet Ontwikkelaarsopties aan: Instellingen › Telefooninfo › Software-informatie › tik 7 keer op “Buildnummer”. (Op andere telefoons: Instellingen › Over de telefoon › Buildnummer.)\n\n3. Open Shizuku. Als het vraagt om meldingen te tonen, sta dat toe: de koppelingscode typ je in een melding van Shizuku.\n\n4. Tik in Shizuku onder “Start via Wireless debugging” (Starten via draadloze foutopsporing) op “Pairing” (Koppelen). Tik op de pagina die opent op “Developer options” (Ontwikkelaarsopties), zet “Draadloze foutopsporing” aan en bevestig met “Toestaan”.\n\n5. Tik op de woorden “Draadloze foutopsporing” (niet op de schakelaar) en dan op “Apparaat koppelen met koppelingscode”. Er verschijnt een code van 6 cijfers.\n\n6. Houd dat scherm open en trek de meldingen omlaag. Als in de melding van Shizuku “Pairing service found” (Koppelingsservice gevonden) staat, tik je op “Enter pairing code” (Koppelingscode invoeren) en typ je de code. Shizuku meldt dat het koppelen gelukt is.\n\n7. Ga terug naar Shizuku en tik op “Start” onder “Start via Wireless debugging”. Wacht tot er “Shizuku is running” (Shizuku is actief) staat.\n\n8. Ga terug naar Waaiya en tik op “Toestemming geven” en dan op “Toestaan”.\n\nNa een herstart van de telefoon stopt Shizuku: maak verbinding met wifi, zet “Draadloze foutopsporing” weer aan als het uit staat, open Shizuku en tik op “Start”. Opnieuw koppelen is niet nodig.';

  @override
  String get wsetupRouteTitle => 'Instellen op deze telefoon';

  @override
  String get wsetupRouteBody =>
      'Vier korte stappen, maar één keer. Geen extra app en geen computer. Waaiya vinkt elke stap af als die klaar is.';

  @override
  String get wizDevTitle => 'Ontwikkelaarsopties aanzetten';

  @override
  String get wizDevBody =>
      'Tik in Over de telefoon 7 keer op “Buildnummer” en kom dan hier terug. Kun je het niet vinden, zoek dan “Buildnummer” in Instellingen.';

  @override
  String get wizDevBodySamsung =>
      'Tik in Telefooninfo › Software-informatie 7 keer op “Buildnummer” en kom dan hier terug.';

  @override
  String get wizDevBodyXiaomi =>
      'Tik in Over de telefoon 7 keer op “OS-versie” (op oudere telefoons “MIUI-versie”; op sommige staat het onder “Gedetailleerde info en specificaties”) en kom dan hier terug.';

  @override
  String get wizDevBodyColoros =>
      'Tik in Over het apparaat (of Over de telefoon) › Versie 7 keer op “Buildnummer” en kom dan hier terug.';

  @override
  String get wizDevBodyVivo =>
      'Tik in Over de telefoon 7 keer op “Softwareversie” (op sommige telefoons: Software-informatie › “Buildnummer”) en kom dan hier terug.';

  @override
  String get wizDevBodyHuawei =>
      'Tik in Over de telefoon 7 keer op “Buildnummer” en kom dan hier terug.';

  @override
  String get wizDevBodyTranssion =>
      'Tik in Mijn telefoon (of Over de telefoon) 7 keer op “Buildnummer” en kom dan hier terug.';

  @override
  String get setupNoteHuawei =>
      'Huawei: veel Huawei-telefoons hebben geen “Draadloze foutopsporing”. Kun je het niet vinden in Ontwikkelaarsopties, gebruik dan een computer (“Andere manieren” hieronder).';

  @override
  String get wsetupFilterOn =>
      'Het filteren staat aan: op deze Android-versie kan de code niet in een melding worden getypt zolang het loopt. Stop eerst het filteren, of gebruik een gesplitst scherm en “Typ de code hier”.';

  @override
  String get wizDevSearch =>
      'De namen kunnen verschillen per taal van de telefoon: kun je het niet vinden, gebruik dan de zoekbalk bovenaan Instellingen.';

  @override
  String get wizDevAction => 'Over de telefoon openen';

  @override
  String get wizWifiTitle => 'Verbinden met wifi';

  @override
  String get wizWifiBody => 'Elk wifi-netwerk is goed; internet is niet nodig.';

  @override
  String get wizWifiAction => 'Wifi-instellingen openen';

  @override
  String get wizWdTitle => 'Draadloze foutopsporing aanzetten';

  @override
  String get wizWdBody =>
      'Waaiya opent Ontwikkelaarsopties bij “Draadloze foutopsporing”. Zet het aan en tik op “Toestaan”.';

  @override
  String get wizWdAction => 'Ontwikkelaarsopties openen';

  @override
  String get wizPairTitle => 'De koppelingscode typen';

  @override
  String get wizPairBody =>
      'Tik op de woorden “Draadloze foutopsporing” en dan op “Apparaat koppelen met koppelingscode”. Typ de 6 cijfers in de melding van Waaiya. Waaiya doet de rest.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya is al gekoppeld met deze telefoon: er is geen code nodig. Tik op de knop en Waaiya maakt het zelf af.';

  @override
  String get wizPairAction => 'Doorgaan';

  @override
  String get wizAgain => 'De installatie opnieuw doen';

  @override
  String get setupShizukuReadyTitle => 'Met Shizuku, dat al actief is';

  @override
  String get setupOtherWaysPlain => 'Andere manieren om te installeren';

  @override
  String get wizSkip => 'Direct naar Draadloze foutopsporing';

  @override
  String get setupOtherWays => 'Andere manieren: Shizuku of een computer';

  @override
  String get wsetupEnterHere => 'Typ de code hier';

  @override
  String get wsetupCancel => 'Annuleren';

  @override
  String get wsetupAndroid10 =>
      'Android 10 kan de installatie niet zelf doen: er is een computer nodig, rechtstreeks (hieronder) of om Shizuku één keer te starten.';

  @override
  String get wsetupShizukuHeading => 'Of met de app Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Met Shizuku gaan tikken ook door de schermafdekkingen heen.';

  @override
  String get wsetupChannel => 'Eenmalige installatie';

  @override
  String get wsetupNotifTitle =>
      'Installatie van Waaiya: wacht op de koppelingscode';

  @override
  String get wsetupFoundTitle => 'Koppelingsscherm gevonden';

  @override
  String get wsetupBusyTitle => 'Installatie van Waaiya';

  @override
  String get wsetupDoneTitle => 'Installatie klaar';

  @override
  String get wsetupDoneBody =>
      'Waaiya kan nu het originele geluid dempen. Je kunt Draadloze foutopsporing uitzetten.';

  @override
  String get wsetupDoneHelperBody =>
      'Klaar. Deze telefoon laat apps deze toestemmingen niet houden, dus de helper van Waaiya dempt in plaats daarvan het originele geluid. De helper stopt als de telefoon opnieuw opstart en als Waaiya wordt bijgewerkt. Als je Waaiya daarna opent, start het de helper vanzelf opnieuw als Draadloze foutopsporing aan staat; zo niet, dan toont het er een knop voor.';

  @override
  String get helperMissingTitle => 'De helper van Waaiya is gestopt';

  @override
  String get helperMissingBody =>
      'Deze telefoon houdt de toestemmingen van Waaiya niet vast, dus Waaiya gebruikt zijn helper. De helper stopt als de telefoon opnieuw opstart en als Waaiya wordt bijgewerkt. Maak verbinding met wifi, zet “Draadloze foutopsporing” aan in Ontwikkelaarsopties en tik dan op “Helper van Waaiya starten”.';

  @override
  String get helperChannel => 'Helper van Waaiya';

  @override
  String get helperStarting => 'Helper starten…';

  @override
  String get helperModeNote =>
      'Deze telefoon laat apps deze toestemmingen niet houden: de helper van Waaiya doet het werk. Hij stopt als de telefoon opnieuw opstart en als Waaiya wordt bijgewerkt. Als je Waaiya daarna opent, start het de helper vanzelf opnieuw als Draadloze foutopsporing aan staat; zo niet, dan toont het er een knop voor.';

  @override
  String get helperTipXiaomi =>
      'Optioneel, om de toestemmingen voorgoed te houden (geen helper na een herstart): zet in Ontwikkelaarsopties “USB-foutopsporing (Beveiligingsinstellingen)” aan (je moet dan inloggen met een Xiaomi-account) en doe de installatie opnieuw.';

  @override
  String get helperTipColoros =>
      'Optioneel, om de toestemmingen voorgoed te houden (geen helper na een herstart): zet in Ontwikkelaarsopties “Disable permission monitoring” (Machtigingscontrole uitschakelen) aan (in de nieuwste versies “Disable system optimization”; misschien alleen te zien als de telefoon op Engels staat) en doe de installatie opnieuw.';

  @override
  String get stateOnHelperMissing =>
      'Het originele geluid is niet gedempt, dus je hoort de muziek samen met het gefilterde geluid: de helper van Waaiya is gestopt. Maak verbinding met wifi, zet Draadloze foutopsporing aan en tik dan op “Helper van Waaiya starten”.';

  @override
  String get setupRefusedTryWireless =>
      'Of gebruik “Instellen op deze telefoon” op deze pagina: de helper van Waaiya werkt dan zonder die schakelaar.';

  @override
  String get helperStartAnywayTitle => 'De helper van Waaiya is gestopt';

  @override
  String get helperStartAnywayBody =>
      'Zonder de helper hoor je de muziek samen met het gefilterde geluid. Start eerst de helper (Draadloze foutopsporing moet aan staan), of start het filteren toch.';

  @override
  String get wsetupFailedTitle => 'Installatie niet voltooid';

  @override
  String get wsetupPairing => 'Koppelen…';

  @override
  String get wsetupConnecting => 'Verbinden en toestemmingen geven…';

  @override
  String get wsetupNeedWifi =>
      'Maak eerst verbinding met een wifi-netwerk (internet is niet nodig): Draadloze foutopsporing werkt alleen via wifi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Zet in Ontwikkelaarsopties “Draadloze foutopsporing” aan, tik dan op de naam en op “Apparaat koppelen met koppelingscode”.';

  @override
  String get wsetupOpenDialog =>
      'Tik in Draadloze foutopsporing op “Apparaat koppelen met koppelingscode”. Houd de code op het scherm en tik hier op “Code invoeren”.';

  @override
  String get wsetupEnterCodeBody =>
      'Tik op “Code invoeren” en typ de code van 6 cijfers die in Instellingen staat.';

  @override
  String get wsetupCodeWaiting =>
      'Code ontvangen. Wacht op het scherm “Apparaat koppelen met koppelingscode”: houd het open.';

  @override
  String get wsetupWrongCode =>
      'Die code werd niet geaccepteerd. Controleer de 6 cijfers op het scherm en voer ze opnieuw in. Is het koppelingsscherm gesloten, open het dan opnieuw: de code verandert.';

  @override
  String get wsetupPairingFailed =>
      'Koppelen is niet gelukt. Sluit het koppelingsscherm, open “Apparaat koppelen met koppelingscode” opnieuw en voer de nieuwe code in.';

  @override
  String get wsetupWaitingConnect =>
      'Gekoppeld. Laat “Draadloze foutopsporing” aan: Waaiya maakt verbinding.';

  @override
  String get wsetupNotPaired =>
      'Deze telefoon kent Waaiya niet meer (de koppeling is verwijderd of verlopen). Open “Apparaat koppelen met koppelingscode” en voer de code in.';

  @override
  String get wsetupConnectFailed =>
      'Kon geen verbinding maken met Draadloze foutopsporing. Zet het uit en weer aan: Waaiya probeert het vanzelf opnieuw.';

  @override
  String get wsetupGrantFailed =>
      'Verbonden, maar de toestemmingen ontbreken nog. Gebruik Shizuku of een computer hieronder.';

  @override
  String get wsetupTimeout =>
      'Gestopt na 10 minuten zonder klaar te zijn. Je kunt het opnieuw proberen.';

  @override
  String get wsetupCodeUnreadable => 'Typ de 6 cijfers van de koppelingscode.';

  @override
  String get wsetupCodeHint => 'Code van 6 cijfers';

  @override
  String get wsetupEnterCode => 'Code invoeren';

  @override
  String wsetupDetail(String details) {
    return 'Details: $details';
  }

  @override
  String get wsetupErrTimeout => 'geen antwoord op tijd';

  @override
  String get wsetupErrRefused => 'verbinding geweigerd';

  @override
  String get wsetupDevOff =>
      'Ontwikkelaarsopties staan uit. Tik in Over de telefoon 7 keer op “Buildnummer” en kom dan terug.';

  @override
  String get wsetupOpenAbout => 'Over de telefoon';

  @override
  String get wsetupNotifOff =>
      'Meldingen staan uit voor Waaiya, dus de code kan niet in een melding worden getypt. Gebruik een gesplitst scherm (Instellingen in de ene helft, Waaiya in de andere) en tik op “Typ de code hier”.';

  @override
  String get wsetupCodeDialogTitle => 'Koppelingscode';

  @override
  String get wsetupCodeDialogBody =>
      'Alleen met een gesplitst scherm (Instellingen in de ene helft, Waaiya in de andere): als je Instellingen verlaat, sluit het koppelingsscherm en werkt de code niet meer. Typ de code van 6 cijfers die onder “Apparaat koppelen met koppelingscode” staat.';

  @override
  String get wsetupCodeOk => 'Koppelen';

  @override
  String get blurStrictTitle => 'Wie onbedekt blijft';

  @override
  String blurStrictValue(String level) {
    return 'Wie onbedekt blijft: $level';
  }

  @override
  String get blurStrict0 =>
      'Streng: alleen mensen van wie de app bijna zeker weet dat het mannen zijn';

  @override
  String get blurStrict1 =>
      'Evenwichtig: ongeveer twee keer zoveel mannen onbedekt';

  @override
  String get blurStrict2 => 'Soepel: iets meer mannen dan evenwichtig';

  @override
  String get blurStrict0Short => 'streng';

  @override
  String get blurStrict1Short => 'evenwichtig';

  @override
  String get blurStrict2Short => 'soepel';

  @override
  String get blurStrictHelp =>
      'Iedereen van wie de app niet zeker weet dat het een man is, wordt bedekt. Streng laat ongeveer 7 op de 100 mannen onbedekt; evenwichtig ongeveer 14, soepel ongeveer 16. Elke stap minder streng laat ook ongeveer 1 vrouw op de 100 meer onbedekt.';

  @override
  String get stateOnNotMuted =>
      'Het originele geluid is nog niet gedempt, dus je hoort de muziek samen met het gefilterde geluid. Maak de eenmalige installatie hieronder af.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya kan het originele geluid van de app die nu speelt niet dempen, dus de muziek is misschien nog te horen. Stop het filteren en start het opnieuw. Blijft het zo, stuur dan het diagnoserapport (onderaan dit scherm).';

  @override
  String get stateTooSlow =>
      'Deze telefoon is te traag om live geluid te filteren, dus het geluid valt weg. “Een link openen” hieronder werkt nog wel: het filtert de video voordat die wordt afgespeeld.';

  @override
  String get stateMonoNote =>
      'Het geluid is in mono, zodat deze telefoon het bijhoudt.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Gedempt, omdat het geen filteren toestaat: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Speelt ongefilterd af, omdat het geen filteren toestaat: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android gaf Waaiya het geluid van andere apps niet. Tik op de knop om opnieuw te starten.';

  @override
  String get stateCaptureCancelled =>
      'Het starten is geannuleerd bij de vraag van Android over scherm delen. Waaiya heeft daar “Starten” nodig om het geluid te ontvangen. Er wordt niets opgenomen of verstuurd.';

  @override
  String get startNoSetupTitle => 'De muziek is nog steeds te horen';

  @override
  String get startNoSetupBody =>
      'De eenmalige installatie is nog niet gedaan. Zonder die installatie kan Waaiya het originele geluid niet dempen: je hoort de muziek en het gefilterde geluid tegelijk.\n\n“Een link openen” werkt zonder installatie.';

  @override
  String get startNoSetupSetup => 'Installatie doen';

  @override
  String get startNoSetupAnyway => 'Toch starten';

  @override
  String get diagButton => 'Probleem? Diagnoserapport';

  @override
  String get diagTitle => 'Diagnoserapport';

  @override
  String get diagNote =>
      'Wat Waaiya op deze telefoon ziet. Kopieer het of deel het met degene die je helpt. De app zelf verstuurt niets.';

  @override
  String get notifStoppedTitle => 'Waaiya is gestopt';

  @override
  String get notifStoppedText =>
      'Het geluid wordt niet meer gefilterd. Tik om opnieuw te starten.';

  @override
  String get wsetupGuide => 'Stappen met afbeeldingen';

  @override
  String get navFilter => 'Filter';

  @override
  String get navScreen => 'Scherm';

  @override
  String get navLinks => 'Links';

  @override
  String get navSetup => 'Installatie';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get setupDoneTitle => 'Installatie klaar';

  @override
  String get setupDoneBody =>
      'Waaiya kan het originele geluid van andere apps dempen. Doe het alleen opnieuw als er iets veranderd is (de installatie is ongedaan gemaakt, of Waaiya zegt dat ze ontbreekt).';

  @override
  String get setupRedo => 'Installatie opnieuw tonen';

  @override
  String get setupGo => 'Naar de installatie';

  @override
  String get helperTitle => 'Tikken door de afdekkingen';

  @override
  String get helperBodyOff =>
      'Zonder hulp blokkeert een afdekking de tikken eronder. De helper van Waaiya tekent de afdekkingen zo dat tikken erdoorheen gaan. Zet Draadloze foutopsporing aan (wifi is nodig) en tik op de knop; de eerste keer koppel je één keer, zoals bij de installatie. Tik er na een herstart van de telefoon opnieuw op.';

  @override
  String get helperStart => 'Helper van Waaiya starten';

  @override
  String get helperOn =>
      'De helper van Waaiya tekent de afdekkingen: tikken gaan erdoorheen. Hij stopt als de telefoon opnieuw opstart of als USB-foutopsporing wordt uitgezet; tik dan opnieuw op de knop.';

  @override
  String get helperShizukuOn =>
      'Shizuku tekent de afdekkingen: tikken gaan erdoorheen.';

  @override
  String get helperOrShizuku => 'Of met Shizuku:';

  @override
  String get filterOptionsTitle => 'Filteropties';

  @override
  String get settingsGeneralTitle => 'Algemeen';

  @override
  String get desktopPreview =>
      'Voorbeeld: de filtermotor is nog niet verbonden op deze computer. De knop laat alleen zien hoe de app gaat werken.';

  @override
  String actionFailed(String details) {
    return 'Dat is niet gelukt: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Instrumenten worden uit alle apps verwijderd.';

  @override
  String get engineErrorNoPactl =>
      'Geluidsprogramma\'s niet gevonden (pactl). Waaiya heeft PulseAudio nodig, of PipeWire met pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'De geluidsserver draait niet (PulseAudio of PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Dit systeem heeft geen systemd-gebruikerssessie, die het filter op de achtergrond laat draaien.';

  @override
  String get engineErrorNoOutput =>
      'Geen luidsprekers of koptelefoon gevonden.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Kon het filter niet installeren. Details:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Het filter is niet gestart. Details:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Het filter is gestopt met een fout. Details:\n$details';
  }

  @override
  String get autostartTitle => 'Starten bij inloggen';

  @override
  String get autostartBody => 'Filter het geluid zodra je inlogt.';

  @override
  String get blurBodyDesktop =>
      'Bedekt mensen en afbeeldingen op het scherm, over elk venster, zolang Waaiya open is (het werkt of het geluidsfilter nu aan of uit staat). Het werkt op deze computer zelf; er wordt niets verstuurd. Als je het venster van Waaiya sluit, stopt de vervaging.';

  @override
  String get blurFailBodyDesktop =>
      'Aan: het hele scherm wordt bedekt als de computer te traag is of de vervaging mislukt; klikken bereiken nog steeds de vensters eronder. Uit: het scherm blijft zichtbaar met een rode balk bovenaan.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Vervaging aan. Dit bureaublad toont de vervaging in zijn eigen schermopname, dus een vervaagd gebied blijft vervaagd tot het beeld verandert.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'De vervaging kan op dit bureaublad niet over andere vensters tekenen. Details:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Kies je scherm in het venster voor scherm delen en sta het toe. Waaiya vraagt dit maar één keer; het beeld blijft op deze computer.';

  @override
  String blurStatusExited(String details) {
    return 'De vervaging is onverwacht gestopt. Zet een vervagingsoptie uit en weer aan om het opnieuw te proberen. Details:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'De detector voor zang van vrouwen is niet geladen, dus stemmen worden gedempt zolang die optie aan staat.';

  @override
  String get blurStatusUncovered =>
      'Een beeldscherm wordt niet bedekt door de vervaging: het is er niet mee gedeeld, of het is later aangesloten. Zet een vervagingsoptie uit en weer aan, en kies elk scherm in het venster voor scherm delen.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'De modellen voor de vervaging ontbreken in deze installatie, dus ze kan niets bedekken; er blijft een rode balk bovenaan het scherm. Installeer Waaiya opnieuw.';

  @override
  String get diagNoteDesktop =>
      'Wat Waaiya op deze computer ziet. Kopieer het en geef het aan degene die je helpt. De app zelf verstuurt niets.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Aanbevolen. Als het filteren vanzelf stopt (door een fout, niet door jou), blijven andere apps stil tot je opnieuw start of op Stoppen drukt, in plaats van ongefilterde muziek af te spelen.';

  @override
  String get settingStereoBodyDesktop =>
      'Uit: mono, dat de computer minder belast. Aan: houdt links en rechts gescheiden. Als de computer te traag is voor stereo, schakelt hij vanzelf over naar mono.';

  @override
  String get linkEntryBodyDesktop =>
      'Plak een link van YouTube, TikTok of Instagram om hem te bekijken met het filter aan, of om hem zonder muziek op te slaan.';

  @override
  String get linkEntryBodyWatch =>
      'Plak een link van YouTube, TikTok of Instagram om hem in je browser te bekijken met het filter aan.';

  @override
  String get linkWatchNoteDesktop =>
      'Opent in je browser. Waaiya start eerst het filter, zodat de muziek daar ook wordt verwijderd.';

  @override
  String get linkFilterFailed =>
      'Het filter is niet gestart, dus de link is niet geopend. Start het op de pagina Filter en probeer het opnieuw.';

  @override
  String get linkSavedVideoDesktop => 'In je map Video\'s: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'In je map Muziek: Waaiya';

  @override
  String get linkShowInFolder => 'Weergeven in map';

  @override
  String get linkSingingNote =>
      'Zang van vrouwen wordt ook gedempt, zoals in je instellingen.';
}
