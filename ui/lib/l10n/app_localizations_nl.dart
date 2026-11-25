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
      'Dit bepaalt alleen welke extra instellingen je ziet. Bijvoorbeeld: “Zang van vrouwen dempen” krijgen alleen mannen te zien. Je kunt het later wijzigen.';

  @override
  String get stateOnTitle => 'Filteren staat aan';

  @override
  String get stateOffTitle => 'Filteren staat uit';

  @override
  String get stateStarting => 'Starten…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Instrumenten worden uit alle apps verwijderd. Het geluid komt ongeveer $delayMs ms later (1000 ms is één seconde).';
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
  String get micOpenSettings =>
      'Open de instellingen van Waaiya om de microfoon toe te staan';

  @override
  String get keepRunningTitle => 'Laat Waaiya draaien';

  @override
  String get keepRunningBattery =>
      'Deze telefoon kan Waaiya na een tijdje sluiten om batterij te sparen, en dan stopt het filteren. Kies in de instellingen van Waaiya bij Batterij „Onbeperkt”. Op Xiaomi, Redmi en POCO: „Geen beperkingen”, en zet ook Autostart aan.';

  @override
  String get keepRunningNotifications =>
      'De meldingen van Waaiya staan uit, dus het kan je niet laten weten wanneer het filteren stopt. Zet ze aan in de instellingen van Waaiya.';

  @override
  String get keepRunningOpen => 'Instellingen van Waaiya openen';

  @override
  String get lockAskTitle => 'Blijven filteren als het scherm vergrendelt?';

  @override
  String get lockTitle => 'Blijven filteren als het scherm vergrendelt';

  @override
  String get lockBody =>
      'Op deze telefoon vraagt Android voor elke start en stopt het filteren dan bij elke schermvergrendeling. Waaiya kan dat voorkomen door tijdens het filteren de bescherming voor scherm delen van Android op te heffen, en zet die terug als het filteren stopt. Zolang die is opgeheven, kan een ander scherm delen op hetzelfde moment (een videogesprek bijvoorbeeld) ook je meldingen tonen. Een wijziging geldt vanaf de volgende start.';

  @override
  String get lockYes => 'Blijven filteren';

  @override
  String get lockNo => 'Stoppen bij elke vergrendeling';

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
  String get computerWeb =>
      'Het eenvoudigst: open op een computer waaiya.mssid.org/usb in Chrome of Edge, zet USB-foutopsporing aan en sluit de telefoon aan met een kabel. Niets te installeren, en het werkt ook op Android 10. Of, als adb geïnstalleerd is:';

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
  String get settingSingingBody =>
      'Bijvoorbeeld: een lied dat een vrouw zingt, wordt gedempt, maar een vrouw die een lezing geeft, hoor je nog steeds.';

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
  String get blurOnTitle => 'De vervaging staat aan';

  @override
  String get blurOffTitle => 'De vervaging staat uit';

  @override
  String get blurStartCd => 'Vervaging starten';

  @override
  String get blurStopCd => 'Vervaging stoppen';

  @override
  String get blurOffDetail =>
      'Tik op de knop om te starten. Het filteren start mee.';

  @override
  String get blurWhatTitle => 'Wat wordt vervaagd';

  @override
  String get blurWomenTitle => 'Vrouwen vervagen';

  @override
  String get blurWomenBody =>
      'Bedekt het hele lichaam. Als de app niet zeker weet dat iemand een man is, wordt die persoon ook bedekt.';

  @override
  String get blurNudityTitle => 'Onzedige beelden vervagen';

  @override
  String get blurNudityBody =>
      'Naaktheid of onthullende kleding, bij wie dan ook: het hele scherm wordt bedekt.';

  @override
  String get blurFailTitle =>
      'Scherm bedekken als de vervaging het niet bijhoudt';

  @override
  String get blurFailBody =>
      'Aan: het hele scherm wordt bedekt als de telefoon te traag is of de vervaging mislukt. Uit: het scherm blijft zichtbaar met een waarschuwing.';

  @override
  String get blurSetupManual => 'Toestaan in Android-instellingen';

  @override
  String get blurStatusNeedsSetup =>
      'Om te vervagen moet Waaiya over andere apps heen tekenen. Het beste: “Naar de installatie”, dan komen je tikken nog steeds bij de app onder de vervaging. Of “Toestaan in Android-instellingen”, maar dan doet een tik op een vervaagd gebied niets.';

  @override
  String get blurStatusNeedsOverlay =>
      'Om te vervagen moet Waaiya over andere apps heen tekenen. Het beste: doe de eenmalige installatie, dan komen je tikken nog steeds bij de app onder de vervaging. Of sta “Weergeven over andere apps” toe in de Android-instellingen, maar dan doet een tik op een vervaagd gebied niets.';

  @override
  String get blurFailUnavailable =>
      'Voorlopig grijs: een afdekking over het hele scherm zou elke tik blokkeren en je zou vast kunnen komen te zitten. Start de helper van Waaiya (Android 12 of nieuwer) en deze optie wordt beschikbaar: de afdekkingen worden dan zo getekend dat tikken erdoorheen gaan. Tot die tijd blijft het scherm zichtbaar met een waarschuwing als de vervaging het niet bijhoudt.';

  @override
  String get blurFailNeedsA11y =>
      'Voorlopig grijs: een afdekking over het hele scherm zou elke tik blokkeren en je zou vast kunnen komen te zitten. Start de helper van Waaiya (Android 12 of nieuwer) of zet de toegankelijkheidsservice Waaiya-vervaging aan in de Android-instellingen, en deze optie wordt beschikbaar. Tot die tijd blijft het scherm zichtbaar met een waarschuwing.';

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
  String get step2Guide => 'Zo start je Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Grijs: op deze Android-versie zou een afdekking over het hele scherm elke tik blokkeren en je zou vast kunnen komen te zitten (afdekkingen waar tikken doorheen gaan hebben Android 12 of nieuwer nodig). Als de vervaging het niet bijhoudt, blijft het scherm zichtbaar met een waarschuwing.';

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
      'Waaiya kan het originele geluid van de app die nu speelt niet dempen, dus de muziek is misschien nog te horen. Stop het filteren en start het opnieuw. Blijft het zo, stuur dan het diagnoserapport (Instellingen).';

  @override
  String get stateTooSlow =>
      'Deze telefoon is te traag om live geluid te filteren, dus het geluid valt weg. “Een link openen” hieronder werkt nog wel: het filtert de video voordat die wordt afgespeeld.';

  @override
  String get stateTooSlowNoLinks =>
      'Deze telefoon is te traag om live geluid te filteren, dus het geluid valt weg.';

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
  String get startNoSetupBodyNoLinks =>
      'De eenmalige installatie is nog niet gedaan. Zonder die installatie kan Waaiya het originele geluid niet dempen: je hoort de muziek en het gefilterde geluid tegelijk.';

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
  String get worshipPrayerFajr => 'Fajr';

  @override
  String get worshipPrayerSunrise => 'Zonsopgang';

  @override
  String get worshipPrayerDhuhr => 'Dhuhr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'Stilte nu beëindigen';

  @override
  String get worshipUnmute => 'Geluid nu weer aan';

  @override
  String get worshipSmsDefault =>
      'Het is gebedstijd, ik kan nu niet opnemen. Ik bel je terug.';

  @override
  String get updateTitle => 'App-updates';

  @override
  String get updateAuto => 'Eén keer per dag naar een nieuwe versie zoeken';

  @override
  String get updateAutoBody =>
      'Waaiya vraagt waaiya.mssid.org of er een nieuwere versie is, en stuurt verder niets. Er wordt niets gedownload tot je op Nu bijwerken tikt.';

  @override
  String get updateCheck => 'Nu zoeken';

  @override
  String get updateChecking => 'Bezig met zoeken…';

  @override
  String updateNone(String version) {
    return 'Je hebt de nieuwste versie ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest is beschikbaar. Jij hebt $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Download: $size, alleen de wijzigingen (de volledige app is $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Download: $size.';
  }

  @override
  String get updateNow => 'Nu bijwerken';

  @override
  String updateDownloading(String progress) {
    return 'Downloaden: $progress';
  }

  @override
  String get updatePreparing => 'Update voorbereiden…';

  @override
  String get updateInstalling =>
      'Bevestig de installatie op het scherm dat Android toont.';

  @override
  String get updateStopsFilter =>
      'Installeren stopt het filteren. Start het opnieuw na de update.';

  @override
  String get updatePermission =>
      'Sta Waaiya toe zijn updates te installeren en tik daarna opnieuw op Nu bijwerken.';

  @override
  String get updateFailed =>
      'De update kon niet worden voltooid. Probeer het later opnieuw of download hem van de website.';

  @override
  String get updateOpenPage => 'Downloadpagina openen';

  @override
  String get updateCheckFailed =>
      'Zoeken lukt nu niet. Probeer het later opnieuw.';

  @override
  String get moveOldTitle => 'Waaiya is verhuisd';

  @override
  String get moveOldBody =>
      'Waaiya komt op Android nu als een nieuwe app (dezelfde Waaiya onder een nieuwe naam), en deze krijgt geen updates meer. Installeer de nieuwe: uw instellingen verhuizen mee. Doe daarna de eenmalige instelling en verwijder deze.';

  @override
  String get moveOldInstalled =>
      'De nieuwe Waaiya is geïnstalleerd. Open hem: hij neemt uw instellingen over. Doe de eenmalige instelling en verwijder daarna deze oude, zodat ze nooit allebei tegelijk filteren.';

  @override
  String get moveInstall => 'Nieuwe Waaiya installeren';

  @override
  String get moveOpenNew => 'Nieuwe Waaiya openen';

  @override
  String get moveRemoveThis => 'Deze oude Waaiya verwijderen';

  @override
  String get moveNewTitle => 'De oude Waaiya is nog geïnstalleerd';

  @override
  String get moveNewBody =>
      'De oude Waaiya (van vóór versie 0.2.15) staat nog op deze telefoon. Verwijder hem, zodat ze nooit allebei tegelijk filteren.';

  @override
  String get moveNewImported => 'Uw instellingen zijn eruit overgenomen.';

  @override
  String get moveRemoveOld => 'Oude Waaiya verwijderen';

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

  @override
  String get singingKeepTitle => 'Zang behouden (test)';

  @override
  String get singingKeepBody =>
      'Instrumenten worden verwijderd, maar zangstemmen blijven, dus bij een lezing met een nasheed eronder blijft ook de stem van de nasheed; of dat acceptabel is, bepaal je zelf.';

  @override
  String get singingKeepNoModel =>
      'Deze versie heeft geen zangmodel, dus het geluid blijft stil zolang dit aan staat. Zet het uit.';

  @override
  String get fixFilterAppsTitle => 'Apps die je ongefilterd hoort';

  @override
  String get fixFilterAppsBody =>
      'Apps die je hier kiest, spelen af zoals ze zijn: geen filter en geen stilte. Bijvoorbeeld een app voor videobellen, zodat gesprekken geen vertraging hebben.';

  @override
  String get fixAddApp => 'App toevoegen';

  @override
  String fixRemoveApp(Object app) {
    return '$app verwijderen';
  }

  @override
  String get fixNoApps => 'Geen app gekozen.';

  @override
  String get fixPickTitle => 'Kies een app';

  @override
  String get fixPickEmpty => 'Geen andere app gevonden.';

  @override
  String get fixPickPlayingDesktop =>
      'Apps die nu geluid afspelen, en de apps die al gekozen zijn.';

  @override
  String get fixCancel => 'Annuleren';

  @override
  String get fixBlurAppsTitle => 'Apps zonder afdekking';

  @override
  String get fixBlurAppsBody =>
      'Geen afdekkingen zolang een van deze apps het hele scherm vult, bijvoorbeeld een kaarten-app of de app van je bank. De afdekkingen komen terug zodra je de app verlaat, of als Waaiya niet zeker weet welke app er te zien is.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Hiervoor is de eenmalige installatie nodig: zonder die installatie kan Waaiya niet zien welke app op het scherm staat, dus blijft de vervaging overal aan.';

  @override
  String get fixBlurAppsHelperMode =>
      'De helper van Waaiya draait niet, dus de app op het scherm kan niet worden gelezen. De vervaging blijft overal aan tot de helper opnieuw is gestart vanaf de pagina Installatie.';

  @override
  String get fixHandTitle => 'Zelf een gebied bedekken';

  @override
  String get fixHandBody =>
      'Terwijl de vervaging draait, kun je zelf een deel van het scherm bedekken, bijvoorbeeld een plaatje dat de vervaging heeft gemist: tik op ‘Gebied bedekken’ en sleep je vinger eroverheen. Het blijft bedekt tot je het weghaalt of de vervaging stopt.';

  @override
  String get fixHandNotRunning =>
      'Beschikbaar terwijl de vervaging draait: filteren aan en een vervagingsoptie aan.';

  @override
  String get fixCoverArea => 'Gebied bedekken';

  @override
  String fixRemoveCovers(Object count) {
    return 'Eigen afdekkingen weghalen ($count)';
  }

  @override
  String get fixNoteTitle => 'Een fout noteren';

  @override
  String get fixNoteBody =>
      'Als Waaiya iets fout doet, tik dan op wat er gebeurde, bijvoorbeeld ‘Er kwam muziek door’. De notitie bewaart de tijd, de app en de instellingen, zodat de oorzaak makkelijker te vinden is. Ze blijft op dit apparaat en wordt nooit verstuurd.';

  @override
  String get fixMissedSound => 'Er kwam muziek door';

  @override
  String get fixWrongSound => 'Stem per ongeluk verwijderd';

  @override
  String get fixMissedScreen => 'Iets werd niet bedekt';

  @override
  String get fixWrongScreen => 'Per ongeluk bedekt';

  @override
  String fixNoted(Object count) {
    return 'Genoteerd ($count notities op dit apparaat).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Notities op dit apparaat: $count';
  }

  @override
  String get fixNotesShow => 'Notities tonen';

  @override
  String get fixNotesDelete => 'Notities verwijderen';

  @override
  String get fixNotesDeleteAsk =>
      'Alle notities verwijderen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get fixNotesTitle => 'Notities over fouten';

  @override
  String get worshipTitle => 'Gebedstijden';

  @override
  String get worshipBody =>
      'Optioneel. Berekend op deze telefoon op basis van de plaats die je kiest. Er wordt niets verstuurd.';

  @override
  String worshipPlace(Object place) {
    return 'Plaats: $place';
  }

  @override
  String get worshipPlaceNone => 'Plaats: niet gekozen';

  @override
  String get worshipChoose => 'Kiezen';

  @override
  String get worshipPlaceSearch => 'Zoek een stad';

  @override
  String get worshipPlaceNoMatch =>
      'Geen stad gevonden. Je kunt in plaats daarvan coördinaten invullen.';

  @override
  String get worshipPlaceCustom => 'Coördinaten invullen';

  @override
  String get worshipLat => 'Breedtegraad (noord +, zuid −)';

  @override
  String get worshipLon => 'Lengtegraad (oost +, west −)';

  @override
  String get worshipZone => 'Tijdzone, bijvoorbeeld Europe/Amsterdam';

  @override
  String get worshipCustomInvalid => 'Controleer de getallen en de tijdzone.';

  @override
  String get worshipPlaceInvalid =>
      'Deze plaats kan niet worden gebruikt. Kies hem opnieuw.';

  @override
  String worshipMethod(Object method) {
    return 'Berekening: $method';
  }

  @override
  String get worshipMethodTitle => 'Rekenmethode';

  @override
  String get worshipMethodNote =>
      'Gekozen op basis van het land van de stad. Kies de methode die je moskee volgt.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Tijd van Asr';

  @override
  String get worshipAsrStandard => 'Standaard (shafi\'i, maliki, hanbali)';

  @override
  String get worshipAsrHanafi => 'Hanafi';

  @override
  String get worshipMethodMwl => 'Islamitische Wereldliga';

  @override
  String get worshipMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get worshipMethodEgypt =>
      'Egyptische Algemene Autoriteit voor Landmeting';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, Mekka';

  @override
  String get worshipMethodKarachi =>
      'Universiteit voor Islamitische Wetenschappen, Karachi';

  @override
  String get worshipMethodTehran =>
      'Instituut voor Geofysica, Universiteit van Teheran';

  @override
  String get worshipMethodGulf => 'Golfregio';

  @override
  String get worshipMethodKuwait => 'Koeweit';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turkije (Diyanet)';

  @override
  String get worshipMethodFrance => 'Frankrijk (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marokko (Ministerie van Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesië (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Maleisië (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Vandaag';

  @override
  String get worshipNoTimes =>
      'Vandaag geen gebedstijden hier: de zon komt niet op of gaat niet onder.';

  @override
  String get worshipSilentTitle => 'Stil tijdens gebedstijden';

  @override
  String get worshipSilentBody =>
      'Op elke gebedstijd wordt de telefoon stil (Niet storen) voor de minuten hieronder, daarna is alles weer zoals het was. Bijvoorbeeld van Dhuhr om 12:00 tot 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Stil gedurende: $minutes min';
  }

  @override
  String get worshipMuteTitle => 'Media dempen bij de adhan';

  @override
  String get worshipMuteBody =>
      'Bij elke gebedstijd wordt het mediageluid (video\'s, muziek, games) gedempt voor de minuten hieronder. Via de melding zet je het meteen weer aan.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Gedempt gedurende: $minutes min';
  }

  @override
  String get worshipMinutesTitle => 'Duur';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get worshipNeedPlace => 'Kies eerst een plaats.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Volgende: $prayer om $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Stil tot $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Media gedempt tot $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Sta Waaiya toe om Niet storen aan te passen, anders kan de telefoon niet op stil.';

  @override
  String get worshipAllow => 'Toestaan';

  @override
  String get worshipExactNeeded =>
      'Wekkers en herinneringen zijn niet toegestaan voor Waaiya, dus elke wijziging kan tot 10 minuten te laat komen, of later als de telefoon slaapt.';

  @override
  String get worshipNotificationsNeeded =>
      'Meldingen staan uit: je ziet niet wanneer de telefoon op stil gaat of weer terugkomt.';

  @override
  String get worshipTonesTitle => 'Eenvoudige beltoon en meldingsgeluid';

  @override
  String get worshipTonesBody =>
      'Waaiya kan de beltoon en meldingsgeluiden niet filteren, alleen vervangen. Kies een eenvoudige toon zonder muziek:';

  @override
  String worshipToneRing(Object number) {
    return 'Eenvoudige beltoon $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Eenvoudig meldingsgeluid $number';
  }

  @override
  String get worshipTonePlay => 'Afspelen';

  @override
  String get worshipToneSet => 'Gebruiken';

  @override
  String get worshipToneInUse => 'In gebruik';

  @override
  String get worshipToneDone => 'Klaar.';

  @override
  String get worshipTonePermission =>
      'Sta Waaiya toe om systeeminstellingen aan te passen, kom terug en tik nog een keer.';

  @override
  String get worshipToneFailed =>
      'Deze telefoon liet Waaiya het niet wijzigen. Kies in de geluidsinstellingen een toon met de naam “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Geluidsinstellingen openen';

  @override
  String get worshipSmsTitle =>
      'Oproepen beantwoorden met sms tijdens het gebed';

  @override
  String get worshipSmsBody =>
      'In de stille minuten na elke gebedstijd krijgt een oproep die blijft overgaan één sms. Eén keer per nummer per gebed; nooit naar afgeschermde nummers of korte nummers.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Na: $seconds s overgaan';
  }

  @override
  String get worshipSmsDelayTitle => 'Seconden overgaan vóór de sms';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Bericht: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Je bericht';

  @override
  String get worshipSmsTextDefault => 'Standaardbericht gebruiken';

  @override
  String get worshipSmsCost =>
      'Elk antwoord is een gewone sms vanaf je simkaart, tegen de prijs van je abonnement. Bij roaming wordt niets verstuurd.';

  @override
  String get worshipSmsRoaming => 'Nu roaming: er wordt geen sms verstuurd.';

  @override
  String get worshipSmsLogTitle =>
      'Verstuurde antwoorden (alleen op deze telefoon bewaard)';

  @override
  String get worshipContinue => 'Doorgaan';

  @override
  String get worshipWhyDnd =>
      'Om de telefoon tijdens gebedstijden op stil te zetten, sta je op de volgende pagina toegang tot Niet storen toe voor Waaiya.';

  @override
  String get worshipWhyExact =>
      'Om precies op tijd te werken, sta je Waaiya op de volgende pagina toe om wekkers en herinneringen in te stellen. Zonder dit kunnen wijzigingen tot 10 minuten te laat komen.';

  @override
  String get worshipWhyNotifications =>
      'Sta meldingen toe, zodat je elke wijziging ziet en ongedaan kunt maken.';

  @override
  String get worshipWhyWrite =>
      'Om je beltoon of meldingsgeluid te wijzigen, sta je Waaiya op de volgende pagina toe om systeeminstellingen aan te passen.';

  @override
  String get worshipWhyPhone =>
      'Om te weten dat er een oproep binnenkomt en van welk nummer, heeft Waaiya de toestemmingen Telefoon en Gesprekslijsten nodig. Er verlaat niets de telefoon behalve je antwoord.';

  @override
  String get worshipWhySms =>
      'Om je antwoord te versturen, heeft Waaiya toestemming nodig om sms\'jes te versturen. Het verstuurt alleen dat antwoord, hoogstens één keer per nummer per gebed.';

  @override
  String get worshipMissingDnd =>
      'Toegang tot Niet storen is niet toegestaan, dus de stilte blijft uit.';

  @override
  String get worshipMissingPhone =>
      'De toestemmingen Telefoon en Gesprekslijsten zijn niet gegeven, dus het sms-antwoord blijft uit.';

  @override
  String get worshipMissingSms =>
      'Toestemming om sms\'jes te versturen is niet gegeven, dus het sms-antwoord blijft uit.';

  @override
  String get worshipTryAgain => 'Opnieuw proberen';

  @override
  String get protectTitle => 'Bescherming voor zwakke momenten';

  @override
  String get protectBody =>
      'Voor een zwak moment waarop je het filter misschien wilt uitzetten. Kies nu, terwijl je rustig bent, een wachttijd: dan stopt de stopknop het filter niet meteen, en je beslist opnieuw als de wachttijd voorbij is. Een ouder kan ook een pincode instellen.';

  @override
  String protectDelay(Object value) {
    return 'Wachten voor het uitzetten: $value';
  }

  @override
  String get protectDelayTitle => 'Wachten voor het uitzetten';

  @override
  String get protectDelayBody =>
      'Bijvoorbeeld met 30 minuten: je drukt op de knop om te stoppen, maar het filter blijft werken. Na 30 minuten vraagt deze pagina of je nog steeds wilt stoppen. Druk binnen 15 minuten op ‘Bevestigen’ en het stopt; anders verandert er niets. Hetzelfde geldt voor het uitzetten van een afdekking of een andere bescherming. Iets aanzetten werkt altijd meteen.';

  @override
  String get protectDelayOff => 'Geen';

  @override
  String get protectDelay1m => '1 minuut';

  @override
  String get protectDelay5m => '5 minuten';

  @override
  String get protectDelay15m => '15 minuten';

  @override
  String get protectDelay30m => '30 minuten';

  @override
  String get protectDelay1h => '1 uur';

  @override
  String get protectDelay4h => '4 uur';

  @override
  String get protectDelay24h => '24 uur';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes minuten';
  }

  @override
  String get protectPinNone => 'Pincode: niet ingesteld';

  @override
  String get protectPinIsSet => 'Pincode: ingesteld';

  @override
  String get protectPinSet => 'Pincode instellen';

  @override
  String get protectPinRemove => 'Verwijderen';

  @override
  String get protectPinBody =>
      'Met een pincode moet je eerst de pincode invoeren om het filteren te stoppen of een bescherming uit te zetten. Een ouder stelt er bijvoorbeeld een in, zodat een kind het filteren niet kan uitzetten. Ook voor het wijzigen van de wachttijd of de pincode is de pincode nodig.';

  @override
  String get protectPinForgot =>
      'Schrijf de pincode op en bewaar hem op een veilige plek: als je hem vergeet, kun je hem niet herstellen. De enige uitweg is de gegevens van Waaiya wissen of Waaiya opnieuw installeren, en daarmee worden ook alle instellingen gewist.';

  @override
  String get protectPinTitle => 'Voer de pincode in';

  @override
  String get protectPinNewTitle => 'Kies een pincode';

  @override
  String get protectPinChangeTitle => 'Pincode wijzigen';

  @override
  String get protectPinCurrent => 'Huidige pincode';

  @override
  String get protectPinNew => 'Nieuwe pincode (4 tot 8 cijfers)';

  @override
  String get protectPinAgain => 'Nieuwe pincode nog een keer';

  @override
  String get protectPinBad => 'Gebruik 4 tot 8 cijfers.';

  @override
  String get protectPinDiffer => 'De twee nieuwe pincodes zijn niet hetzelfde.';

  @override
  String protectPinWrong(Object count) {
    return 'Verkeerde pincode. Nog $count pogingen voor een pauze.';
  }

  @override
  String protectLocked(Object time) {
    return 'Te veel verkeerde pogingen. Probeer het opnieuw vanaf $time.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Annuleren';

  @override
  String get protectCancelChange => 'Wijziging annuleren';

  @override
  String get protectConfirm => 'Bevestigen';

  @override
  String protectPending(Object time, Object what) {
    return '$what: wacht tot $time. Bevestig het daarna in ‘Instellingen’.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: het wachten is voorbij. Wil je het nog steeds? Druk vóór $time op ‘Bevestigen’; anders verandert er niets.';
  }

  @override
  String get protectWaitTitle => 'Deze wijziging wacht';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what gebeurt nu niet. Om $time bevestig je het binnen 15 minuten in ‘Instellingen’, als je het dan nog wilt. Doe je niets, dan verandert er niets.';
  }

  @override
  String get protectWaitStart => 'Wachten starten';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Wacht al tot $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Wacht tot $time. Bevestig het daarna in ‘Instellingen’.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'morgen om $time';
  }

  @override
  String get protectHeldBack =>
      'Nu niet: door je beschermingsinstellingen moet deze wijziging wachten, of is de pincode nodig.';

  @override
  String get protectLimits =>
      'Wat dit niet kan tegenhouden: geforceerd stoppen, verwijderen, de gegevens van Waaiya wissen en de eigen instellingen van Android. Om dat te blokkeren zijn speciale Android-rechten nodig die Waaiya niet gebruikt. Dit beschermt tegen een zwak moment, niet tegen iemand die vastbesloten is.';

  @override
  String get protectLimitsDesktop =>
      'Wat dit niet kan tegenhouden: het commando waaiya in een terminal, Waaiya verwijderen of de map met instellingen ervan wissen. Dit beschermt tegen een zwak moment, niet tegen iemand die vastbesloten is.';

  @override
  String get protectLimitsWindows =>
      'Wat dit niet kan tegenhouden: het commando waaiya-filter.exe in een terminal, Waaiya verwijderen of de map met instellingen ervan wissen. Dit beschermt tegen een zwak moment, niet tegen iemand die vastbesloten is.';

  @override
  String get protectWhatStop => 'Filteren stoppen';

  @override
  String protectWhatOff(Object name) {
    return 'Uitzetten: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Aanzetten: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'App toevoegen aan: $name';
  }

  @override
  String get protectWhatStrictness => 'Vervaging minder streng maken';

  @override
  String get protectWhatGender => 'Wijzigen wie Waaiya gebruikt';

  @override
  String protectWhatDelay(Object value) {
    return 'Wachten voor het uitzetten wijzigen in: $value';
  }

  @override
  String get protectWhatPinChange => 'Pincode wijzigen';

  @override
  String get protectWhatPinClear => 'Pincode verwijderen';

  @override
  String get protectWhatSetting => 'Een instelling wijzigen';

  @override
  String get onboardBodyDesktop =>
      'Waaiya haalt muziekinstrumenten uit het geluid van elke app op deze computer. Spraak en Koranrecitatie blijven behouden. Voorlopig worden zangstemmen ook verwijderd.';

  @override
  String get worshipUseLocation => 'Mijn locatie gebruiken';

  @override
  String get worshipWhyLocation =>
      'Om de gebedstijden te vinden waar je bent, leest Waaiya nu één keer de geschatte locatie van deze telefoon. Die blijft op de telefoon als je plaats en wordt nergens heen gestuurd.';

  @override
  String get worshipLocating => 'Je locatie zoeken…';

  @override
  String get worshipLocationDenied =>
      'Locatie is niet toegestaan. Je kunt in plaats daarvan je stad zoeken.';

  @override
  String get worshipLocationOff =>
      'Locatie staat uit op deze telefoon. Zet die aan en probeer het opnieuw, of zoek je stad.';

  @override
  String get worshipLocationSettings => 'Locatie-instellingen';

  @override
  String get worshipLocationFailed =>
      'Je locatie kon niet worden gevonden. Probeer het zo opnieuw, of zoek je stad.';

  @override
  String worshipPlaceNear(Object city) {
    return 'bij $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'De officiële tijden van het ministerie van Habous en Islamitische Zaken voor $city.';
  }

  @override
  String get trayOpen => 'Waaiya openen';

  @override
  String get trayQuit => 'Afsluiten';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows laat Waaiya niet starten bij het aanmelden. Zet Waaiya aan in Instellingen › Apps › Opstarten en zet deze optie daarna weer aan.';

  @override
  String get engineErrorAutostartPolicy =>
      'De instellingen van deze computer, gekozen door de beheerder, laten Waaiya niet starten bij het aanmelden.';

  @override
  String get notifTextTitle => 'Meldingstekst tonen tijdens filteren';

  @override
  String get notifTextBody =>
      'Android verbergt de inhoud van meldingen zolang een app het hele scherm opneemt, en filteren telt daarvoor mee. Aan: Waaiya heft deze bescherming alleen tijdens het filteren op, zodat je je meldingen kunt lezen. Andere schermdelingen op hetzelfde moment zijn dan ook niet beschermd.';

  @override
  String get notifTextNextStart =>
      'Stop het filteren en start het opnieuw om deze wijziging toe te passen.';

  @override
  String get notifTextRefused =>
      'Deze telefoon weigerde de wijziging. Zet zelf ‘Beveiliging voor scherm delen uitzetten’ aan in de ontwikkelaarsopties.';

  @override
  String get notifTextByHand =>
      'Zichtbaar: de bescherming van Android staat uit in de ontwikkelaarsopties (‘Beveiliging voor scherm delen uitzetten’). Ze blijft uit voor elke schermdeling tot je haar daar weer aanzet.';

  @override
  String get notifTextHowTo =>
      'Android verbergt de inhoud van meldingen terwijl Waaiya filtert. Na de eenmalige installatie toont Waaiya ze: het heft deze bescherming alleen tijdens het filteren op.';

  @override
  String get notifTextOpenDev => 'Ontwikkelaarsopties openen';

  @override
  String get notifTextLockNote =>
      'Op deze telefoon stopt Android het filteren ook als het scherm vergrendelt, en andere apps blijven dan stil tot je op Hervatten tikt. De installatie voorkomt dat ook.';

  @override
  String get notifTextHandOptional =>
      'Optioneel, zonder installatie: zet ‘Beveiliging voor scherm delen uitzetten’ aan in de ontwikkelaarsopties. Ze blijft dan uit voor elke schermdeling, en sommige telefoons hebben haar niet.';

  @override
  String get notifTextForced =>
      'Aan: op deze telefoon vraagt Android voor elke start en zou het filteren dan bij elke schermvergrendeling stoppen. Waaiya heft deze bescherming tijdens het filteren op, waardoor ook de meldingstekst zichtbaar is. Andere schermdelingen op hetzelfde moment zijn dan ook niet beschermd.';

  @override
  String get oneAppTitle => 'Bij het starten: ‘Eén app delen’, dan Waaiya';

  @override
  String get oneAppBody =>
      'Als Android vraagt wat je wilt delen, kies ‘Eén app delen’ en dan Waaiya. Alle apps worden nog steeds gefilterd, meldingen blijven leesbaar en het filteren gaat door als het scherm vergrendelt. Met het hele scherm verbergt Android meldingstekst en stopt het filteren bij elke vergrendeling.';

  @override
  String get oneAppPair =>
      'Koppel Waaiya één keer met draadloze foutopsporing op de pagina Installatie zodat het volledig werkt: dan wordt ook de originele muziek gedempt en vraagt Android niet meer bij elke start.';

  @override
  String get notifTextOneApp =>
      'Zichtbaar als je bij het starten ‘Eén app delen’ en dan Waaiya kiest. Met het hele scherm verbergt Android het; na de eenmalige installatie heft Waaiya dat tijdens het filteren op.';

  @override
  String get blurNeedsRestart =>
      'Stop het filteren en start het opnieuw om de vervaging te gebruiken: die heeft het hele scherm nodig, en dit filteren begon met ‘Eén app delen’ aangeboden.';
}
