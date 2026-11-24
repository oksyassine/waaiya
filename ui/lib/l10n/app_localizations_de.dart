// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Entfernt Musikinstrumente aus allen Apps und behält Sprache und Rezitation.';

  @override
  String get onboardTitle => 'Willkommen';

  @override
  String get onboardBody =>
      'Waaiya entfernt Musikinstrumente aus dem Ton aller Apps auf diesem Telefon. Sprache und Koranrezitation bleiben erhalten. Vorerst werden auch Gesangsstimmen entfernt.';

  @override
  String get onboardQuestion => 'Ich bin';

  @override
  String get genderMan => 'Ein Mann';

  @override
  String get genderWoman => 'Eine Frau';

  @override
  String get onboardWhy =>
      'Davon hängt nur ab, welche optionalen Einstellungen Sie sehen. Zum Beispiel wird „Frauengesang stummschalten“ nur Männern angeboten. Sie können es später ändern.';

  @override
  String get stateOnTitle => 'Der Filter ist an';

  @override
  String get stateOffTitle => 'Der Filter ist aus';

  @override
  String get stateStarting => 'Wird gestartet…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Instrumente werden aus allen Apps entfernt. Der Ton kommt etwa $delayMs ms später (1000 ms sind eine Sekunde).';
  }

  @override
  String get stateOffDetail => 'Tippen Sie zum Starten auf die Taste.';

  @override
  String get stateModelFailed =>
      'Das Tonmodell konnte nicht geladen werden, deshalb ist der Ton zur Sicherheit stummgeschaltet.';

  @override
  String get stateCaptureDenied =>
      'Die Mikrofonberechtigung wird benötigt, um den Ton anderer Apps zu empfangen.';

  @override
  String get stateStoppedBySystem =>
      'Android hat den Filter beendet. Tippen Sie auf die Taste, um ihn wieder zu starten.';

  @override
  String get stateSilencedTitle => 'Filter gestoppt';

  @override
  String get stateSilenced =>
      'Filter gestoppt: Andere Apps sind stummgeschaltet. Tippen Sie auf die Taste, um wieder zu starten, oder auf Stopp, um sie ungefiltert zu hören.';

  @override
  String get releaseSilence => 'Stopp: Apps ungefiltert hören';

  @override
  String get powerStartCd => 'Filter starten';

  @override
  String get powerStopCd => 'Filter stoppen';

  @override
  String get captureHint =>
      'Android fragt, ob Sie Ihren Bildschirm teilen möchten. Nur der Ton wird verwendet: Nichts wird aufgenommen oder gesendet.';

  @override
  String get needRecordAudio =>
      'Waaiya braucht die Mikrofonberechtigung, um den Ton anderer Apps zu empfangen. Es nimmt Sie nie auf.';

  @override
  String get setupBannerTitle => 'Noch ein Schritt';

  @override
  String get setupBannerBody =>
      'Ohne die einmalige Einrichtung unten hören Sie die Musik und den gefilterten Ton zusammen.';

  @override
  String get step1Title => 'Shizuku installieren';

  @override
  String get step1Body => 'Eine kostenlose Hilfs-App aus dem Play Store.';

  @override
  String get step1Action => 'Shizuku holen';

  @override
  String get step2Title => 'Shizuku starten';

  @override
  String get step2Body =>
      'Shizuku startet über WLAN mit „Debugging über WLAN“ von Android. Tippen Sie auf die Taste, um die Schritte zu sehen, und kommen Sie dann zurück.';

  @override
  String get step2Action => 'Shizuku öffnen';

  @override
  String get step2Update => 'Shizuku aktualisieren';

  @override
  String get step2TooOld =>
      'Ihre Shizuku-Version ist zu alt. Aktualisieren Sie sie im Play Store.';

  @override
  String get step2Denied =>
      'Shizuku ist so eingestellt, dass Waaiya immer abgelehnt wird. Erlauben Sie Waaiya in Shizuku in der Liste der Apps.';

  @override
  String get step3Title => 'Berechtigung erteilen';

  @override
  String get step3Body => 'Einmal tippen, dann „Zulassen“ wählen.';

  @override
  String get step3Action => 'Berechtigung erteilen';

  @override
  String get step3Busy => 'Wird eingerichtet…';

  @override
  String get setupDoneRestart =>
      'Fertig. Stoppen und starten Sie den Filter einmal, damit es wirkt.';

  @override
  String setupFailed(String details) {
    return 'Die Einrichtung wurde nicht abgeschlossen. Details:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Die Shizuku-Berechtigung wurde abgelehnt. Tippen Sie auf die Taste, um es erneut zu versuchen.';

  @override
  String get setupSlow =>
      'Shizuku braucht länger als sonst. Warten Sie noch: Auf manchen Telefonen braucht sein Helfer beim ersten Mal bis zu einer Minute zum Starten.';

  @override
  String get setupTimeout =>
      'Shizuku hat nicht innerhalb von 2 Minuten geantwortet. Öffnen Sie Shizuku, prüfen Sie, ob dort steht, dass es läuft, und tippen Sie dann erneut auf die Taste. Wenn die Einrichtung später fertig wird, aktualisiert sich dieser Bildschirm von selbst.';

  @override
  String get setupRefusedXiaomi =>
      'Dieses Telefon hat die Berechtigungen abgelehnt. Schalten Sie auf Xiaomi, Redmi und POCO in den Entwickleroptionen „USB-Debugging (Sicherheitseinstellungen)“ ein (dafür müssen Sie sich bei einem Xiaomi-Konto anmelden) und versuchen Sie es dann erneut.';

  @override
  String get setupRefusedColoros =>
      'Dieses Telefon hat die Berechtigungen abgelehnt. Schalten Sie auf OPPO, OnePlus und realme in den Entwickleroptionen „Disable permission monitoring“ (Berechtigungsüberwachung deaktivieren) ein. In den neuesten Versionen heißt es „Disable system optimization“ (Systemoptimierung deaktivieren) und wird eventuell nur angezeigt, wenn das Telefon auf Englisch eingestellt ist. Um es zu finden, suchen Sie in den Einstellungen nach „Berechtigung“ (oder „permission“). Versuchen Sie es dann erneut.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi und POCO: Wenn die Benachrichtigung kein Feld zum Eingeben des Codes hat, stellen Sie in den Benachrichtigungseinstellungen den Benachrichtigungsstil auf „Android“ oder geben Sie den Code mit geteiltem Bildschirm in Waaiya ein.';

  @override
  String get stepDoneCd => 'Erledigt';

  @override
  String stepTodoCd(int step) {
    return 'Schritt $step';
  }

  @override
  String get computerToggle => 'Stattdessen einen Computer verwenden';

  @override
  String get computerWeb =>
      'Am einfachsten: Öffnen Sie auf einem Computer waaiya.mssid.org/usb in Chrome oder Edge, schalten Sie USB-Debugging ein und verbinden Sie das Telefon per Kabel. Nichts zu installieren, funktioniert auch mit Android 10. Oder, wenn adb installiert ist:';

  @override
  String get computerBody =>
      'Schalten Sie USB-Debugging ein, verbinden Sie das Telefon und führen Sie Folgendes aus:';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get computerNote =>
      'Die zweite Zeile ist optional: Sie verhindert die Frage zur Bildschirmfreigabe bei jedem Start.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingSilenceTitle =>
      'Apps stummschalten, die das Filtern blockieren';

  @override
  String get settingSilenceBody =>
      'Empfohlen. Manche Apps erlauben nicht, dass ihr Ton gefiltert wird; dies schaltet sie stumm, statt Musik durchzulassen.';

  @override
  String get settingHoldSilenceTitle =>
      'Apps stumm lassen, wenn der Filter von selbst stoppt';

  @override
  String get settingHoldSilenceBody =>
      'Empfohlen. Wenn Android den Filter beendet (nicht Sie), bleiben andere Apps stumm, bis Sie wieder starten oder auf Stopp tippen, statt Musik ungefiltert abzuspielen. Erfordert die einmalige Einrichtung.';

  @override
  String get settingStereoTitle => 'Stereoton';

  @override
  String get settingStereoBody =>
      'Aus: Mono, das etwa halb so viel Akku braucht und auf mehr Telefonen mithält. An: Die linke und die rechte Seite bleiben getrennt. Wenn das Telefon für Stereo zu langsam ist, wechselt es trotzdem von selbst zu Mono.';

  @override
  String get settingSingingTitle => 'Frauengesang stummschalten';

  @override
  String get settingSingingBody =>
      'Zum Beispiel wird ein Lied, das eine Frau singt, stummgeschaltet, aber eine Frau, die einen Vortrag hält, ist weiter zu hören.';

  @override
  String get settingSingingNoModel =>
      'Diese Version hat keinen Gesangsdetektor, deshalb werden alle Stimmen stummgeschaltet, solange dies an ist.';

  @override
  String get settingRestart =>
      'Stoppen und starten Sie den Filter, damit die Änderungen wirken.';

  @override
  String get settingGenderTitle => 'Ich bin';

  @override
  String get change => 'Ändern';

  @override
  String get playerTitle => 'Videos perfekt synchron';

  @override
  String get playerBody =>
      'Teilen Sie ein Video mit Waaiya (oder nutzen Sie „Öffnen mit“), um es gefiltert und ohne Verzögerung anzusehen.';

  @override
  String get licences => 'Open-Source-Lizenzen';

  @override
  String get licencesIntro =>
      'Waaiya ist freie Software unter der GNU Affero General Public License v3 oder höher. Quellcode: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Namensnennung 4.0 (Trainingsdaten): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Vollständige Texte';

  @override
  String get back => 'Zurück';

  @override
  String get linkEntryTitle => 'Link öffnen';

  @override
  String get linkEntryBody =>
      'Fügen Sie einen YouTube-, TikTok- oder Instagram-Link ein, um das Video ohne Musik anzusehen oder zu speichern.';

  @override
  String get linkTitle => 'Link öffnen';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Video- oder Audiolink';

  @override
  String get linkPaste => 'Einfügen';

  @override
  String get linkOpen => 'Öffnen';

  @override
  String get linkResolving => 'Link wird geöffnet…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Ohne Musik ansehen';

  @override
  String get linkSave => 'Ohne Musik speichern';

  @override
  String get linkListen => 'Ohne Musik anhören';

  @override
  String get linkAudioOnly =>
      'Das Video dieses Links kann noch nicht geöffnet werden, nur sein Ton.';

  @override
  String get linkDownloading => 'Wird heruntergeladen…';

  @override
  String get linkFiltering => 'Musik wird entfernt…';

  @override
  String get linkCancel => 'Abbrechen';

  @override
  String get linkCancelled => 'Abgebrochen. Es wurde nichts gespeichert.';

  @override
  String get linkTimedOut =>
      'Android hat das Speichern beendet: Es erlaubt diese Art von Arbeit nur wenige Stunden am Tag. Es wurde nichts gespeichert; öffnen Sie Waaiya und versuchen Sie es erneut.';

  @override
  String get linkExportFailed =>
      'Das konnte nicht gespeichert werden. Es wurde nichts gespeichert.';

  @override
  String get linkSaved => 'Ohne Musik gespeichert';

  @override
  String get linkSavedVideo => 'In Ihrer Galerie: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'In Ihrer Musik: Music › Waaiya';

  @override
  String get linkPlay => 'Abspielen';

  @override
  String get linkShare => 'Teilen';

  @override
  String get linkShareNote => 'Teilen Sie nur Videos, die Sie teilen dürfen.';

  @override
  String get linkLive => 'Livestreams können nicht gespeichert werden.';

  @override
  String get linkBusy =>
      'Ein anderes Video wird gerade gespeichert. Bitte warten Sie, bis es fertig ist.';

  @override
  String get linkInvalid =>
      'Bitte fügen Sie einen Weblink ein (beginnend mit https://).';

  @override
  String get linkLogin =>
      'Die Website zeigt dieses Video nicht ohne Konto. Öffentliche Beiträge lassen sich meist öffnen: Versuchen Sie es in ein paar Minuten erneut. Private Beiträge können nicht geöffnet werden.';

  @override
  String get linkUnsupported => 'Diese Website wird nicht unterstützt.';

  @override
  String get linkPlaylist =>
      'Das ist eine Playlist. Bitte öffnen Sie ein einzelnes Video.';

  @override
  String get linkNoFormat =>
      'Dieses Video hat ein Format, das Waaiya noch nicht filtern kann.';

  @override
  String get linkFailed =>
      'Dieser Link konnte nicht geöffnet werden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get linkPlayFailed =>
      'Das konnte nicht abgespielt werden. Es wurde nichts ungefiltert abgespielt.';

  @override
  String get linkLimited =>
      'Die Website begrenzt gerade die Anfragen. Versuchen Sie es in ein paar Minuten erneut.';

  @override
  String get blurTitle => 'Bildschirm-Unschärfe';

  @override
  String get blurBody =>
      'Verdeckt Menschen und Bilder auf dem Bildschirm, in jeder App, solange der Filter an ist. Das läuft auf dem Telefon; nichts wird irgendwohin gesendet.';

  @override
  String get blurOnTitle => 'Die Unschärfe ist an';

  @override
  String get blurOffTitle => 'Die Unschärfe ist aus';

  @override
  String get blurStartCd => 'Unschärfe starten';

  @override
  String get blurStopCd => 'Unschärfe beenden';

  @override
  String get blurOffDetail =>
      'Tippen Sie auf die Taste, um zu starten. Das Filtern startet mit.';

  @override
  String get blurWhatTitle => 'Was unscharf wird';

  @override
  String get blurWomenTitle => 'Frauen unscharf machen';

  @override
  String get blurWomenBody =>
      'Verdeckt den ganzen Körper. Wenn die App nicht sicher ist, dass eine Person ein Mann ist, verdeckt sie diese Person auch.';

  @override
  String get blurNudityTitle => 'Freizügige Bilder unscharf machen';

  @override
  String get blurNudityBody =>
      'Nacktheit oder freizügige Kleidung, bei jedem Menschen: Der ganze Bildschirm wird verdeckt.';

  @override
  String get blurFailTitle =>
      'Bildschirm verdecken, wenn die Unschärfe nicht mithält';

  @override
  String get blurFailBody =>
      'An: Der ganze Bildschirm wird verdeckt, wenn das Telefon zu langsam ist oder die Unschärfe ausfällt. Aus: Der Bildschirm bleibt mit einer Warnung sichtbar.';

  @override
  String get blurSetupManual => 'In den Android-Einstellungen erlauben';

  @override
  String get blurStatusNeedsSetup =>
      'Zum Unscharfmachen muss Waaiya über anderen Apps angezeigt werden. Am besten: „Zur Einrichtung“, damit Ihre Berührungen weiter die App unter der Unschärfe erreichen. Oder „In den Android-Einstellungen erlauben“, aber dann bewirkt ein Tippen auf einen unscharfen Bereich nichts.';

  @override
  String get blurStatusNeedsOverlay =>
      'Zum Unscharfmachen muss Waaiya über anderen Apps angezeigt werden. Am besten: Erledigen Sie die einmalige Einrichtung, damit Ihre Berührungen weiter die App unter der Unschärfe erreichen. Oder erlauben Sie in den Android-Einstellungen „Über anderen Apps einblenden“, aber dann bewirkt ein Tippen auf einen unscharfen Bereich nichts.';

  @override
  String get blurFailUnavailable =>
      'Vorerst ausgegraut: Eine Abdeckung über den ganzen Bildschirm würde jedes Tippen blockieren und Sie könnten feststecken. Starten Sie den Waaiya-Helfer (Android 12 oder neuer), dann wird diese Option verfügbar: Die Abdeckungen werden dann so gezeichnet, dass Berührungen hindurchgehen. Bis dahin bleibt der Bildschirm mit einer Warnung sichtbar, wenn die Unschärfe nicht mithält.';

  @override
  String get blurFailNeedsA11y =>
      'Vorerst ausgegraut: Eine Abdeckung über den ganzen Bildschirm würde jedes Tippen blockieren und Sie könnten feststecken. Starten Sie den Waaiya-Helfer (Android 12 oder neuer) oder schalten Sie in den Android-Einstellungen die Bedienungshilfe „Waaiya-Unschärfe“ ein, dann wird diese Option verfügbar. Bis dahin bleibt der Bildschirm mit einer Warnung sichtbar.';

  @override
  String get languageTitle => 'Sprache';

  @override
  String settingLanguageTitle(String language) {
    return 'Sprache: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Stoppen und starten Sie den Filter, damit die Einstellungen der Unschärfe wirken.';

  @override
  String get blurStatusStarting => 'Unschärfe wird gestartet…';

  @override
  String get blurStatusOn => 'Unschärfe an.';

  @override
  String get blurStatusOnVisible =>
      'Unschärfe an, im vorsichtigen Modus: Dieses Telefon zeigt die Unschärfe in seiner eigenen Bildschirmaufnahme, deshalb bleibt ein unscharfer Bereich unscharf, bis sich die Szene ändert.';

  @override
  String get blurStatusModels =>
      'Dieser Version fehlt ein Unschärfe-Modell für die gewählte Option.';

  @override
  String get blurStatusFailing => 'Die Unschärfe hält gerade nicht mit.';

  @override
  String get blurStatusNoOverlay =>
      'Die Unschärfe kann nicht über anderen Apps angezeigt werden: Erlauben Sie es oben.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Die Unschärfe kann den Bildschirm nicht sehen. Details:\n$details';
  }

  @override
  String get step2Guide => 'So starten Sie Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Ausgegraut: Auf dieser Android-Version würde eine Abdeckung über den ganzen Bildschirm jedes Tippen blockieren und Sie könnten feststecken (Abdeckungen, durch die Berührungen hindurchgehen, erfordern Android 12 oder neuer). Wenn die Unschärfe nicht mithält, bleibt der Bildschirm mit einer Warnung sichtbar.';

  @override
  String get guideTitle => 'Shizuku Schritt für Schritt starten';

  @override
  String get guideOpenDev => 'Entwickleroptionen';

  @override
  String get guideOpenShizuku => 'Shizuku öffnen';

  @override
  String get guideClose => 'Schließen';

  @override
  String get guideBody =>
      'Sie brauchen WLAN und Android 11 oder neuer. Das Koppeln erfolgt nur einmal; nach einem Neustart des Telefons wiederholen Sie nur Schritt 7.\n\n1. Verbinden Sie das Telefon mit einem WLAN.\n\n2. Schalten Sie die Entwickleroptionen ein: Einstellungen › Telefoninfo › Softwareinformationen › 7-mal auf „Buildnummer“ tippen. (Auf anderen Telefonen: Einstellungen › Über das Telefon › Build-Nummer.)\n\n3. Öffnen Sie Shizuku. Wenn es fragt, ob es Benachrichtigungen anzeigen darf, erlauben Sie es: Der Kopplungscode wird in einer Benachrichtigung von Shizuku eingegeben.\n\n4. Tippen Sie in Shizuku unter „Start via Wireless debugging“ (Über Debugging über WLAN starten) auf „Pairing“ (Koppeln). Tippen Sie auf der Seite, die sich öffnet, auf „Developer options“ (Entwickleroptionen), schalten Sie „Debugging über WLAN“ ein und bestätigen Sie mit „Zulassen“.\n\n5. Tippen Sie auf die Worte „Debugging über WLAN“ (nicht auf den Schalter) und dann auf „Gerät mit Kopplungscode koppeln“. Ein 6-stelliger Code erscheint.\n\n6. Lassen Sie diesen Bildschirm offen und ziehen Sie die Benachrichtigungen herunter. Wenn in der Benachrichtigung von Shizuku „Pairing service found“ (Kopplungsdienst gefunden) steht, tippen Sie auf „Enter pairing code“ (Kopplungscode eingeben) und geben Sie den Code ein. Shizuku meldet, dass das Koppeln erfolgreich war.\n\n7. Gehen Sie zurück zu Shizuku und tippen Sie unter „Start via Wireless debugging“ auf „Start“ (Starten). Warten Sie, bis „Shizuku is running“ (Shizuku läuft) angezeigt wird.\n\n8. Kommen Sie zurück zu Waaiya und tippen Sie auf „Berechtigung erteilen“ und dann auf „Zulassen“.\n\nNach einem Neustart des Telefons stoppt Shizuku: Verbinden Sie sich mit dem WLAN, schalten Sie „Debugging über WLAN“ wieder ein, falls es aus ist, öffnen Sie Shizuku und tippen Sie auf „Start“. Kein neues Koppeln nötig.';

  @override
  String get wsetupRouteTitle => 'Auf diesem Telefon einrichten';

  @override
  String get wsetupRouteBody =>
      'Vier kurze Schritte, nur einmal. Keine zusätzliche App und kein Computer. Waaiya hakt jeden Schritt ab, sobald er erledigt ist.';

  @override
  String get wizDevTitle => 'Entwickleroptionen einschalten';

  @override
  String get wizDevBody =>
      'Tippen Sie unter „Über das Telefon“ 7-mal auf „Build-Nummer“ und kommen Sie dann hierher zurück. Wenn Sie es nicht finden, suchen Sie in den Einstellungen nach „Build-Nummer“.';

  @override
  String get wizDevBodySamsung =>
      'Tippen Sie unter „Telefoninfo“ › „Softwareinformationen“ 7-mal auf „Buildnummer“ und kommen Sie dann hierher zurück.';

  @override
  String get wizDevBodyXiaomi =>
      'Tippen Sie unter „Über das Telefon“ 7-mal auf „OS-Version“ (auf älteren Telefonen „MIUI-Version“; auf manchen steht es unter „Detaillierte Infos und Spezifikationen“) und kommen Sie dann hierher zurück.';

  @override
  String get wizDevBodyColoros =>
      'Tippen Sie unter „Über das Gerät“ (oder „Über das Telefon“) › „Version“ 7-mal auf „Build-Nummer“ und kommen Sie dann hierher zurück.';

  @override
  String get wizDevBodyVivo =>
      'Tippen Sie unter „Über das Telefon“ 7-mal auf „Softwareversion“ (auf manchen Telefonen: Softwareinformationen › „Build-Nummer“) und kommen Sie dann hierher zurück.';

  @override
  String get wizDevBodyHuawei =>
      'Tippen Sie unter „Über das Telefon“ 7-mal auf „Build-Nummer“ und kommen Sie dann hierher zurück.';

  @override
  String get wizDevBodyTranssion =>
      'Tippen Sie unter „Mein Telefon“ (oder „Über das Telefon“) 7-mal auf „Build-Nummer“ und kommen Sie dann hierher zurück.';

  @override
  String get setupNoteHuawei =>
      'Huawei: Viele Huawei-Telefone haben kein „Debugging über WLAN“. Wenn Sie es in den Entwickleroptionen nicht finden, verwenden Sie einen Computer („Andere Wege“ unten).';

  @override
  String get wsetupFilterOn =>
      'Der Filter ist an: Auf dieser Android-Version kann der Code nicht in einer Benachrichtigung eingegeben werden, solange er läuft. Stoppen Sie zuerst den Filter oder nutzen Sie den geteilten Bildschirm und „Code hier eingeben“.';

  @override
  String get wizDevSearch =>
      'Die Namen können je nach Sprache des Telefons anders sein: Wenn Sie es nicht finden, nutzen Sie die Suche oben in den Einstellungen.';

  @override
  String get wizDevAction => '„Über das Telefon“ öffnen';

  @override
  String get wizWifiTitle => 'Mit WLAN verbinden';

  @override
  String get wizWifiBody =>
      'Jedes WLAN-Netz reicht; Internet wird nicht benötigt.';

  @override
  String get wizWifiAction => 'WLAN-Einstellungen öffnen';

  @override
  String get wizWdTitle => 'Debugging über WLAN einschalten';

  @override
  String get wizWdBody =>
      'Waaiya öffnet die Entwickleroptionen bei „Debugging über WLAN“. Schalten Sie es ein und tippen Sie auf „Zulassen“.';

  @override
  String get wizWdAction => 'Entwickleroptionen öffnen';

  @override
  String get wizPairTitle => 'Kopplungscode eingeben';

  @override
  String get wizPairBody =>
      'Tippen Sie auf die Worte „Debugging über WLAN“ und dann auf „Gerät mit Kopplungscode koppeln“. Geben Sie die 6 Ziffern in der Benachrichtigung von Waaiya ein. Waaiya erledigt den Rest.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya ist bereits mit diesem Telefon gekoppelt: Es wird kein Code benötigt. Tippen Sie auf die Taste und Waaiya schließt von selbst ab.';

  @override
  String get wizPairAction => 'Weiter';

  @override
  String get wizAgain => 'Einrichtung erneut ausführen';

  @override
  String get setupShizukuReadyTitle => 'Mit Shizuku, das bereits läuft';

  @override
  String get setupOtherWaysPlain => 'Andere Wege zur Einrichtung';

  @override
  String get wizSkip => 'Weiter zu „Debugging über WLAN“';

  @override
  String get setupOtherWays => 'Andere Wege: Shizuku oder ein Computer';

  @override
  String get wsetupEnterHere => 'Code hier eingeben';

  @override
  String get wsetupCancel => 'Abbrechen';

  @override
  String get wsetupAndroid10 =>
      'Android 10 kann die Einrichtung nicht allein durchführen: Es braucht einen Computer, entweder direkt (unten) oder um Shizuku einmal zu starten.';

  @override
  String get wsetupShizukuHeading => 'Oder mit der App Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Mit Shizuku gehen Berührungen außerdem durch die Bildschirmabdeckungen hindurch.';

  @override
  String get wsetupChannel => 'Einmalige Einrichtung';

  @override
  String get wsetupNotifTitle =>
      'Waaiya-Einrichtung: Warten auf den Kopplungscode';

  @override
  String get wsetupFoundTitle => 'Kopplungsbildschirm gefunden';

  @override
  String get wsetupBusyTitle => 'Waaiya-Einrichtung';

  @override
  String get wsetupDoneTitle => 'Einrichtung abgeschlossen';

  @override
  String get wsetupDoneBody =>
      'Waaiya kann jetzt den Originalton stummschalten. Sie können „Debugging über WLAN“ ausschalten.';

  @override
  String get wsetupDoneHelperBody =>
      'Fertig. Dieses Telefon lässt Apps diese Berechtigungen nicht behalten, deshalb schaltet stattdessen der Waaiya-Helfer den Originalton stumm. Der Helfer stoppt, wenn das Telefon neu startet und wenn Waaiya aktualisiert wird. Wenn Sie Waaiya danach öffnen, startet es den Helfer von selbst wieder, falls „Debugging über WLAN“ an ist; falls nicht, zeigt es eine Taste dafür an.';

  @override
  String get helperMissingTitle => 'Der Waaiya-Helfer ist gestoppt';

  @override
  String get helperMissingBody =>
      'Dieses Telefon behält die Berechtigungen von Waaiya nicht, deshalb nutzt Waaiya seinen Helfer. Der Helfer stoppt, wenn das Telefon neu startet und wenn Waaiya aktualisiert wird. Verbinden Sie sich mit dem WLAN, schalten Sie in den Entwickleroptionen „Debugging über WLAN“ ein und tippen Sie dann auf „Waaiya-Helfer starten“.';

  @override
  String get helperChannel => 'Waaiya-Helfer';

  @override
  String get helperStarting => 'Helfer wird gestartet…';

  @override
  String get helperModeNote =>
      'Dieses Telefon lässt Apps diese Berechtigungen nicht behalten: Der Waaiya-Helfer übernimmt die Arbeit. Er stoppt, wenn das Telefon neu startet und wenn Waaiya aktualisiert wird. Wenn Sie Waaiya danach öffnen, startet es den Helfer von selbst wieder, falls „Debugging über WLAN“ an ist; falls nicht, zeigt es eine Taste dafür an.';

  @override
  String get helperTipXiaomi =>
      'Optional, um die Berechtigungen dauerhaft zu behalten (kein Helfer nach Neustarts): Schalten Sie in den Entwickleroptionen „USB-Debugging (Sicherheitseinstellungen)“ ein (dafür müssen Sie sich bei einem Xiaomi-Konto anmelden) und führen Sie die Einrichtung dann erneut durch.';

  @override
  String get helperTipColoros =>
      'Optional, um die Berechtigungen dauerhaft zu behalten (kein Helfer nach Neustarts): Schalten Sie in den Entwickleroptionen „Disable permission monitoring“ (Berechtigungsüberwachung deaktivieren) ein – in den neuesten Versionen „Disable system optimization“ (Systemoptimierung deaktivieren), eventuell nur sichtbar, wenn das Telefon auf Englisch eingestellt ist – und führen Sie die Einrichtung dann erneut durch.';

  @override
  String get stateOnHelperMissing =>
      'Der Originalton ist nicht stummgeschaltet, deshalb hören Sie die Musik zusammen mit dem gefilterten Ton: Der Waaiya-Helfer ist gestoppt. Verbinden Sie sich mit dem WLAN, schalten Sie „Debugging über WLAN“ ein und tippen Sie dann auf „Waaiya-Helfer starten“.';

  @override
  String get setupRefusedTryWireless =>
      'Oder nutzen Sie auf dieser Seite „Auf diesem Telefon einrichten“: Der Waaiya-Helfer funktioniert dann ohne diesen Schalter.';

  @override
  String get helperStartAnywayTitle => 'Der Waaiya-Helfer ist gestoppt';

  @override
  String get helperStartAnywayBody =>
      'Ohne ihn hören Sie die Musik zusammen mit dem gefilterten Ton. Starten Sie zuerst den Helfer („Debugging über WLAN“ muss an sein) oder starten Sie den Filter trotzdem.';

  @override
  String get wsetupFailedTitle => 'Einrichtung nicht abgeschlossen';

  @override
  String get wsetupPairing => 'Wird gekoppelt…';

  @override
  String get wsetupConnecting =>
      'Verbindung wird hergestellt und Berechtigungen werden erteilt…';

  @override
  String get wsetupNeedWifi =>
      'Verbinden Sie sich zuerst mit einem WLAN-Netz (Internet wird nicht benötigt): „Debugging über WLAN“ funktioniert nur im WLAN.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Schalten Sie in den Entwickleroptionen „Debugging über WLAN“ ein, tippen Sie dann auf den Namen und auf „Gerät mit Kopplungscode koppeln“.';

  @override
  String get wsetupOpenDialog =>
      'Tippen Sie unter „Debugging über WLAN“ auf „Gerät mit Kopplungscode koppeln“. Lassen Sie den Code auf dem Bildschirm und tippen Sie hier auf „Code eingeben“.';

  @override
  String get wsetupEnterCodeBody =>
      'Tippen Sie auf „Code eingeben“ und geben Sie den 6-stelligen Code ein, der in den Einstellungen angezeigt wird.';

  @override
  String get wsetupCodeWaiting =>
      'Code erhalten. Warten auf den Bildschirm „Gerät mit Kopplungscode koppeln“: Lassen Sie ihn offen.';

  @override
  String get wsetupWrongCode =>
      'Dieser Code wurde nicht akzeptiert. Prüfen Sie die 6 Ziffern auf dem Bildschirm und geben Sie sie erneut ein. Wenn der Kopplungsbildschirm geschlossen wurde, öffnen Sie ihn erneut: Der Code ändert sich.';

  @override
  String get wsetupPairingFailed =>
      'Das Koppeln hat nicht funktioniert. Schließen Sie den Kopplungsbildschirm, öffnen Sie „Gerät mit Kopplungscode koppeln“ erneut und geben Sie den neuen Code ein.';

  @override
  String get wsetupWaitingConnect =>
      'Gekoppelt. Lassen Sie „Debugging über WLAN“ an: Waaiya stellt die Verbindung her.';

  @override
  String get wsetupNotPaired =>
      'Dieses Telefon kennt Waaiya nicht mehr (die Kopplung wurde entfernt oder ist abgelaufen). Öffnen Sie „Gerät mit Kopplungscode koppeln“ und geben Sie den Code ein.';

  @override
  String get wsetupConnectFailed =>
      'Keine Verbindung zu „Debugging über WLAN“ möglich. Schalten Sie es aus und wieder ein: Waaiya versucht es von selbst erneut.';

  @override
  String get wsetupGrantFailed =>
      'Verbunden, aber die Berechtigungen fehlen noch. Verwenden Sie unten Shizuku oder einen Computer.';

  @override
  String get wsetupTimeout =>
      'Nach 10 Minuten ohne Abschluss gestoppt. Sie können es erneut versuchen.';

  @override
  String get wsetupCodeUnreadable =>
      'Geben Sie die 6 Ziffern des Kopplungscodes ein.';

  @override
  String get wsetupCodeHint => '6-stelliger Code';

  @override
  String get wsetupEnterCode => 'Code eingeben';

  @override
  String wsetupDetail(String details) {
    return 'Details: $details';
  }

  @override
  String get wsetupErrTimeout => 'keine rechtzeitige Antwort';

  @override
  String get wsetupErrRefused => 'Verbindung abgelehnt';

  @override
  String get wsetupDevOff =>
      'Die Entwickleroptionen sind aus. Tippen Sie unter „Über das Telefon“ 7-mal auf „Build-Nummer“ und kommen Sie dann zurück.';

  @override
  String get wsetupOpenAbout => 'Über das Telefon';

  @override
  String get wsetupNotifOff =>
      'Benachrichtigungen sind für Waaiya ausgeschaltet, deshalb kann der Code nicht in einer Benachrichtigung eingegeben werden. Nutzen Sie den geteilten Bildschirm (Einstellungen in einer Hälfte, Waaiya in der anderen) und tippen Sie auf „Code hier eingeben“.';

  @override
  String get wsetupCodeDialogTitle => 'Kopplungscode';

  @override
  String get wsetupCodeDialogBody =>
      'Nur mit geteiltem Bildschirm (Einstellungen in einer Hälfte, Waaiya in der anderen): Wenn Sie die Einstellungen verlassen, schließt sich der Kopplungsbildschirm und sein Code funktioniert nicht mehr. Geben Sie den 6-stelligen Code ein, der unter „Gerät mit Kopplungscode koppeln“ angezeigt wird.';

  @override
  String get wsetupCodeOk => 'Koppeln';

  @override
  String get blurStrictTitle => 'Wer unverdeckt bleibt';

  @override
  String blurStrictValue(String level) {
    return 'Wer unverdeckt bleibt: $level';
  }

  @override
  String get blurStrict0 =>
      'Streng: nur Menschen, bei denen die App fast sicher ist, dass es Männer sind';

  @override
  String get blurStrict1 =>
      'Ausgewogen: etwa doppelt so viele Männer bleiben unverdeckt';

  @override
  String get blurStrict2 => 'Locker: ein paar mehr Männer als bei Ausgewogen';

  @override
  String get blurStrict0Short => 'streng';

  @override
  String get blurStrict1Short => 'ausgewogen';

  @override
  String get blurStrict2Short => 'locker';

  @override
  String get blurStrictHelp =>
      'Wer nach Einschätzung der App nicht sicher ein Mann ist, wird verdeckt. Streng lässt etwa 7 von 100 Männern unverdeckt, Ausgewogen etwa 14, Locker etwa 16. Jede weniger strenge Stufe lässt außerdem etwa 1 von 100 Frauen mehr unverdeckt.';

  @override
  String get stateOnNotMuted =>
      'Der Originalton ist noch nicht stummgeschaltet, deshalb hören Sie die Musik zusammen mit dem gefilterten Ton. Schließen Sie unten die einmalige Einrichtung ab.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya kann den Originalton der App, die gerade spielt, nicht stummschalten, deshalb ist die Musik eventuell noch zu hören. Stoppen und starten Sie den Filter. Wenn es so bleibt, senden Sie den Diagnosebericht (unten auf diesem Bildschirm).';

  @override
  String get stateTooSlow =>
      'Dieses Telefon ist zu langsam, um Ton live zu filtern, deshalb setzt der Ton aus. „Link öffnen“ unten funktioniert trotzdem: Es filtert das Video, bevor es abgespielt wird.';

  @override
  String get stateMonoNote =>
      'Der Ton ist in Mono, damit dieses Telefon mithält.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Stummgeschaltet, weil es das Filtern nicht erlaubt: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Wird ungefiltert abgespielt, weil es das Filtern nicht erlaubt: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android hat Waaiya den Ton anderer Apps nicht gegeben. Tippen Sie auf die Taste, um wieder zu starten.';

  @override
  String get stateCaptureCancelled =>
      'Der Start wurde bei der Frage von Android zur Bildschirmfreigabe abgebrochen. Waaiya braucht dort „Starten“, um den Ton zu empfangen. Nichts wird aufgenommen oder gesendet.';

  @override
  String get startNoSetupTitle => 'Die Musik ist weiterhin zu hören';

  @override
  String get startNoSetupBody =>
      'Die einmalige Einrichtung ist noch nicht erledigt. Ohne sie kann Waaiya den Originalton nicht stummschalten: Sie hören die Musik und den gefilterten Ton zusammen.\n\n„Link öffnen“ funktioniert ohne Einrichtung.';

  @override
  String get startNoSetupSetup => 'Einrichtung durchführen';

  @override
  String get startNoSetupAnyway => 'Trotzdem starten';

  @override
  String get diagButton => 'Problem? Diagnosebericht';

  @override
  String get diagTitle => 'Diagnosebericht';

  @override
  String get diagNote =>
      'Was Waaiya auf diesem Telefon sieht. Kopieren Sie es oder teilen Sie es mit der Person, die Ihnen hilft. Die App selbst sendet nichts.';

  @override
  String get notifStoppedTitle => 'Waaiya gestoppt';

  @override
  String get notifStoppedText =>
      'Der Ton wird nicht mehr gefiltert. Tippen Sie, um wieder zu starten.';

  @override
  String get wsetupGuide => 'Schritte mit Bildern';

  @override
  String get navFilter => 'Filter';

  @override
  String get navScreen => 'Bildschirm';

  @override
  String get navLinks => 'Links';

  @override
  String get navSetup => 'Einrichtung';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get setupDoneTitle => 'Einrichtung abgeschlossen';

  @override
  String get setupDoneBody =>
      'Waaiya kann den Originalton anderer Apps stummschalten. Wiederholen Sie die Einrichtung nur, wenn sich etwas geändert hat (die Einrichtung wurde rückgängig gemacht oder Waaiya meldet, dass sie fehlt).';

  @override
  String get setupRedo => 'Einrichtung erneut anzeigen';

  @override
  String get setupGo => 'Zur Einrichtung';

  @override
  String get helperTitle => 'Berührungen durch die Abdeckungen';

  @override
  String get helperBodyOff =>
      'Ohne Hilfe blockiert eine Abdeckung die Berührungen darunter. Der Waaiya-Helfer zeichnet die Abdeckungen so, dass Berührungen hindurchgehen. Schalten Sie „Debugging über WLAN“ ein (WLAN wird benötigt) und tippen Sie auf die Taste; beim ersten Mal koppeln Sie einmal wie bei der Einrichtung. Tippen Sie nach einem Neustart des Telefons erneut darauf.';

  @override
  String get helperStart => 'Waaiya-Helfer starten';

  @override
  String get helperOn =>
      'Der Waaiya-Helfer zeichnet die Abdeckungen: Berührungen gehen hindurch. Er stoppt, wenn das Telefon neu startet oder wenn USB-Debugging ausgeschaltet wird; tippen Sie dann erneut auf die Taste.';

  @override
  String get helperShizukuOn =>
      'Shizuku zeichnet die Abdeckungen: Berührungen gehen hindurch.';

  @override
  String get helperOrShizuku => 'Oder mit Shizuku:';

  @override
  String get filterOptionsTitle => 'Filteroptionen';

  @override
  String get settingsGeneralTitle => 'Allgemein';

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
  String get worshipPrayerFajr => 'Fadschr';

  @override
  String get worshipPrayerSunrise => 'Sonnenaufgang';

  @override
  String get worshipPrayerDhuhr => 'Dhuhr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Ischa';

  @override
  String get worshipEndSilent => 'Stille jetzt beenden';

  @override
  String get worshipUnmute => 'Ton jetzt wieder an';

  @override
  String get worshipSmsDefault =>
      'Es ist Gebetszeit, ich kann gerade nicht rangehen. Ich rufe zurück.';

  @override
  String get updateTitle => 'App-Updates';

  @override
  String get updateAuto => 'Einmal am Tag nach einer neuen Version suchen';

  @override
  String get updateAutoBody =>
      'Waaiya fragt waaiya.mssid.org, ob es eine neuere Version gibt, und sendet sonst nichts. Heruntergeladen wird erst, wenn du auf Jetzt aktualisieren tippst.';

  @override
  String get updateCheck => 'Jetzt suchen';

  @override
  String get updateChecking => 'Wird gesucht…';

  @override
  String updateNone(String version) {
    return 'Du hast die neueste Version ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest ist verfügbar. Du hast $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Download: $size, nur die Änderungen (die ganze App hat $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Download: $size.';
  }

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String updateDownloading(String progress) {
    return 'Wird heruntergeladen: $progress';
  }

  @override
  String get updatePreparing => 'Update wird vorbereitet…';

  @override
  String get updateInstalling =>
      'Bestätige die Installation auf dem Bildschirm, den Android zeigt.';

  @override
  String get updateStopsFilter =>
      'Die Installation beendet das Filtern. Starte es nach dem Update wieder.';

  @override
  String get updatePermission =>
      'Erlaube Waaiya, seine Updates zu installieren, und tippe dann noch einmal auf Jetzt aktualisieren.';

  @override
  String get updateFailed =>
      'Das Update konnte nicht abgeschlossen werden. Versuche es später noch einmal oder lade es von der Website herunter.';

  @override
  String get updateOpenPage => 'Downloadseite öffnen';

  @override
  String get updateCheckFailed =>
      'Suchen ist gerade nicht möglich. Versuche es später noch einmal.';

  @override
  String get moveOldTitle => 'Waaiya ist umgezogen';

  @override
  String get moveOldBody =>
      'Waaiya kommt unter Android jetzt als neue App (dasselbe Waaiya unter neuem Namen), und diese hier erhält keine Updates mehr. Installieren Sie die neue: Ihre Einstellungen kommen mit. Richten Sie sie dann einmalig ein und entfernen Sie diese.';

  @override
  String get moveOldInstalled =>
      'Das neue Waaiya ist installiert. Öffnen Sie es: Es übernimmt Ihre Einstellungen. Richten Sie es einmalig ein und entfernen Sie dann dieses alte, damit nie beide gleichzeitig filtern.';

  @override
  String get moveInstall => 'Neues Waaiya installieren';

  @override
  String get moveOpenNew => 'Neues Waaiya öffnen';

  @override
  String get moveRemoveThis => 'Dieses alte Waaiya entfernen';

  @override
  String get moveNewTitle => 'Das alte Waaiya ist noch installiert';

  @override
  String get moveNewBody =>
      'Das alte Waaiya (von vor Version 0.2.15) ist noch auf diesem Telefon. Entfernen Sie es, damit nie beide gleichzeitig filtern.';

  @override
  String get moveNewImported => 'Ihre Einstellungen wurden daraus übernommen.';

  @override
  String get moveRemoveOld => 'Altes Waaiya entfernen';

  @override
  String get desktopPreview =>
      'Vorschau: Der Filter ist auf diesem Computer noch nicht eingebunden. Die Taste zeigt nur, wie die App funktionieren wird.';

  @override
  String actionFailed(String details) {
    return 'Das hat nicht funktioniert: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Instrumente werden aus allen Apps entfernt.';

  @override
  String get engineErrorNoPactl =>
      'Audiowerkzeuge nicht gefunden (pactl). Waaiya braucht PulseAudio oder PipeWire mit pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Der Soundserver läuft nicht (PulseAudio oder PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Dieses System hat keine systemd-Benutzersitzung, die den Filter im Hintergrund ausführt.';

  @override
  String get engineErrorNoOutput =>
      'Keine Lautsprecher oder Kopfhörer gefunden.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Der Filter konnte nicht installiert werden. Details:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Der Filter ist nicht gestartet. Details:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Der Filter wurde mit einem Fehler beendet. Details:\n$details';
  }

  @override
  String get autostartTitle => 'Bei der Anmeldung starten';

  @override
  String get autostartBody => 'Den Ton filtern, sobald Sie sich anmelden.';

  @override
  String get blurBodyDesktop =>
      'Verdeckt Menschen und Bilder auf dem Bildschirm, über jedem Fenster, solange Waaiya geöffnet ist (egal, ob der Tonfilter an oder aus ist). Das läuft auf diesem Computer; nichts wird irgendwohin gesendet. Wenn Sie das Waaiya-Fenster schließen, stoppt die Unschärfe.';

  @override
  String get blurFailBodyDesktop =>
      'An: Der ganze Bildschirm wird verdeckt, wenn der Computer zu langsam ist oder die Unschärfe ausfällt; Klicks erreichen trotzdem die Fenster darunter. Aus: Der Bildschirm bleibt sichtbar, mit einem roten Balken oben.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Unschärfe an. Dieser Desktop zeigt die Unschärfe in seiner eigenen Bildschirmaufnahme, deshalb bleibt ein unscharfer Bereich unscharf, bis sich die Szene ändert.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Die Unschärfe kann auf diesem Desktop nicht über anderen Fenstern angezeigt werden. Details:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Wählen Sie im Fenster zur Bildschirmfreigabe Ihren Bildschirm aus und erlauben Sie die Freigabe. Waaiya fragt nur einmal; das Bild bleibt auf diesem Computer.';

  @override
  String blurStatusExited(String details) {
    return 'Die Unschärfe wurde unerwartet beendet. Schalten Sie eine Unschärfe-Option aus und wieder ein, um es erneut zu versuchen. Details:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Der Detektor für Frauengesang wurde nicht geladen, deshalb werden Stimmen stummgeschaltet, solange diese Option an ist.';

  @override
  String get blurStatusUncovered =>
      'Ein Monitor wird nicht von der Unschärfe abgedeckt: Er wurde nicht für sie freigegeben oder erst später angeschlossen. Schalten Sie eine Unschärfe-Option aus und wieder ein und wählen Sie im Fenster zur Bildschirmfreigabe jeden Bildschirm aus.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Die Modelle der Unschärfe fehlen in dieser Installation, deshalb kann sie nichts verdecken; oben auf dem Bildschirm bleibt ein roter Balken. Installieren Sie Waaiya neu.';

  @override
  String get diagNoteDesktop =>
      'Was Waaiya auf diesem Computer sieht. Kopieren Sie es und geben Sie es der Person, die Ihnen hilft. Die App selbst sendet nichts.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Empfohlen. Wenn der Filter von selbst stoppt (durch einen Fehler, nicht durch Sie), bleiben andere Apps stumm, bis Sie wieder starten oder auf Stopp klicken, statt Musik ungefiltert abzuspielen.';

  @override
  String get settingStereoBodyDesktop =>
      'Aus: Mono, das den Computer weniger belastet. An: Die linke und die rechte Seite bleiben getrennt. Wenn der Computer für Stereo zu langsam ist, wechselt er von selbst zu Mono.';

  @override
  String get linkEntryBodyDesktop =>
      'Fügen Sie einen YouTube-, TikTok- oder Instagram-Link ein, um das Video mit eingeschaltetem Filter anzusehen oder ohne Musik zu speichern.';

  @override
  String get linkEntryBodyWatch =>
      'Fügen Sie einen YouTube-, TikTok- oder Instagram-Link ein, um das Video in Ihrem Browser mit eingeschaltetem Filter anzusehen.';

  @override
  String get linkWatchNoteDesktop =>
      'Wird in Ihrem Browser geöffnet. Waaiya startet zuerst den Filter, damit die Musik auch dort entfernt wird.';

  @override
  String get linkFilterFailed =>
      'Der Filter ist nicht gestartet, deshalb wurde der Link nicht geöffnet. Starten Sie ihn auf der Seite Filter und versuchen Sie es erneut.';

  @override
  String get linkSavedVideoDesktop => 'In Ihrem Ordner „Videos“: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'In Ihrem Ordner „Musik“: Waaiya';

  @override
  String get linkShowInFolder => 'Im Ordner anzeigen';

  @override
  String get linkSingingNote =>
      'Frauengesang wird ebenfalls stummgeschaltet, wie in Ihren Einstellungen.';

  @override
  String get singingKeepTitle => 'Gesang behalten (Test)';

  @override
  String get singingKeepBody =>
      'Instrumente werden entfernt, aber Singstimmen bleiben. Ein Vortrag mit einem Nasheed im Hintergrund behält also auch die Stimme des Nasheeds; ob das annehmbar ist, entscheiden Sie.';

  @override
  String get singingKeepNoModel =>
      'Dieser Version fehlt das Gesangsmodell, deshalb bleibt der Ton stumm, solange das an ist. Schalten Sie es aus.';

  @override
  String get fixFilterAppsTitle => 'Apps, die ungefiltert zu hören sind';

  @override
  String get fixFilterAppsBody =>
      'Apps, die Sie hier wählen, spielen so, wie sie sind: kein Filter und keine Stille. Zum Beispiel eine App für Videoanrufe, damit Anrufe keine Verzögerung haben.';

  @override
  String get fixAddApp => 'App hinzufügen';

  @override
  String fixRemoveApp(Object app) {
    return '$app entfernen';
  }

  @override
  String get fixNoApps => 'Keine App gewählt.';

  @override
  String get fixPickTitle => 'App wählen';

  @override
  String get fixPickEmpty => 'Keine andere App gefunden.';

  @override
  String get fixPickPlayingDesktop =>
      'Apps, die gerade Ton abspielen, und die bereits gewählten.';

  @override
  String get fixCancel => 'Abbrechen';

  @override
  String get fixBlurAppsTitle => 'Apps ohne Abdeckung';

  @override
  String get fixBlurAppsBody =>
      'Keine Abdeckungen, solange eine dieser Apps den Bildschirm füllt, zum Beispiel eine Karten-App oder die App Ihrer Bank. Die Abdeckungen kommen zurück, sobald Sie die App verlassen oder wenn Waaiya nicht sicher ist, welche App angezeigt wird.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Braucht die einmalige Einrichtung: Ohne sie kann Waaiya nicht erkennen, welche App auf dem Bildschirm ist, deshalb bleibt die Unschärfe überall an.';

  @override
  String get fixBlurAppsHelperMode =>
      'Der Waaiya-Helfer läuft nicht, deshalb kann die App auf dem Bildschirm nicht erkannt werden. Die Unschärfe bleibt überall an, bis der Helfer auf der Seite Einrichtung wieder gestartet wird.';

  @override
  String get fixHandTitle => 'Einen Bereich von Hand verdecken';

  @override
  String get fixHandBody =>
      'Während die Unschärfe läuft, können Sie selbst einen Teil des Bildschirms verdecken, zum Beispiel ein Bild, das die Unschärfe übersehen hat: Tippen Sie auf „Bereich verdecken“ und ziehen Sie den Finger darüber. Der Bereich bleibt verdeckt, bis Sie die Abdeckung entfernen oder die Unschärfe stoppt.';

  @override
  String get fixHandNotRunning =>
      'Verfügbar, während die Unschärfe läuft: Filter an und eine Unschärfe-Option an.';

  @override
  String get fixCoverArea => 'Bereich verdecken';

  @override
  String fixRemoveCovers(Object count) {
    return 'Eigene Abdeckungen entfernen ($count)';
  }

  @override
  String get fixNoteTitle => 'Einen Fehler notieren';

  @override
  String get fixNoteBody =>
      'Wenn Waaiya etwas falsch macht, tippen Sie auf das, was passiert ist, zum Beispiel „Musik kam durch“. Die Notiz speichert die Uhrzeit, die App und die Einstellungen, damit man die Ursache finden kann. Sie bleibt auf diesem Gerät und wird nie gesendet.';

  @override
  String get fixMissedSound => 'Musik kam durch';

  @override
  String get fixWrongSound => 'Stimme versehentlich entfernt';

  @override
  String get fixMissedScreen => 'Etwas wurde nicht verdeckt';

  @override
  String get fixWrongScreen => 'Versehentlich verdeckt';

  @override
  String fixNoted(Object count) {
    return 'Notiert ($count Notizen auf diesem Gerät).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Notizen auf diesem Gerät: $count';
  }

  @override
  String get fixNotesShow => 'Notizen anzeigen';

  @override
  String get fixNotesDelete => 'Notizen löschen';

  @override
  String get fixNotesDeleteAsk =>
      'Alle Notizen löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get fixNotesTitle => 'Notizen zu Fehlern';

  @override
  String get worshipTitle => 'Gebetszeiten';

  @override
  String get worshipBody =>
      'Optional. Auf diesem Telefon aus dem gewählten Ort berechnet. Nichts wird gesendet.';

  @override
  String worshipPlace(Object place) {
    return 'Ort: $place';
  }

  @override
  String get worshipPlaceNone => 'Ort: nicht gewählt';

  @override
  String get worshipChoose => 'Wählen';

  @override
  String get worshipPlaceSearch => 'Stadt suchen';

  @override
  String get worshipPlaceNoMatch =>
      'Keine Stadt gefunden. Sie können stattdessen Koordinaten eingeben.';

  @override
  String get worshipPlaceCustom => 'Koordinaten eingeben';

  @override
  String get worshipLat => 'Breitengrad (Nord +, Süd −)';

  @override
  String get worshipLon => 'Längengrad (Ost +, West −)';

  @override
  String get worshipZone => 'Zeitzone, zum Beispiel Europe/Berlin';

  @override
  String get worshipCustomInvalid => 'Prüfen Sie die Zahlen und die Zeitzone.';

  @override
  String get worshipPlaceInvalid =>
      'Dieser Ort kann nicht verwendet werden. Wählen Sie ihn erneut.';

  @override
  String worshipMethod(Object method) {
    return 'Berechnung: $method';
  }

  @override
  String get worshipMethodTitle => 'Berechnungsmethode';

  @override
  String get worshipMethodNote =>
      'Nach dem Land der Stadt gewählt. Nehmen Sie die Methode, der Ihre Moschee folgt.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Asr-Zeit';

  @override
  String get worshipAsrStandard =>
      'Standard (schafiitisch, malikitisch, hanbalitisch)';

  @override
  String get worshipAsrHanafi => 'Hanafitisch';

  @override
  String get worshipMethodMwl => 'Islamische Weltliga';

  @override
  String get worshipMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get worshipMethodEgypt =>
      'Ägyptische Generalbehörde für Landvermessung';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, Mekka';

  @override
  String get worshipMethodKarachi =>
      'Universität für Islamische Wissenschaften, Karatschi';

  @override
  String get worshipMethodTehran =>
      'Institut für Geophysik, Universität Teheran';

  @override
  String get worshipMethodGulf => 'Golfregion';

  @override
  String get worshipMethodKuwait => 'Kuwait';

  @override
  String get worshipMethodQatar => 'Katar';

  @override
  String get worshipMethodSingapore => 'Singapur (MUIS)';

  @override
  String get worshipMethodTurkey => 'Türkei (Diyanet)';

  @override
  String get worshipMethodFrance => 'Frankreich (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marokko (Habous-Ministerium)';

  @override
  String get worshipMethodIndonesia => 'Indonesien (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malaysia (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Heute';

  @override
  String get worshipNoTimes =>
      'Heute keine Gebetszeiten hier: Die Sonne geht nicht auf oder nicht unter.';

  @override
  String get worshipSilentTitle => 'Lautlos zu den Gebetszeiten';

  @override
  String get worshipSilentBody =>
      'Zu jeder Gebetszeit wird das Telefon für die Minuten unten lautlos („Bitte nicht stören“) und danach wieder so wie vorher. Zum Beispiel ab Dhuhr um 12:00 bis 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Lautlos für: $minutes Min.';
  }

  @override
  String get worshipMuteTitle => 'Medien beim Adhan stummschalten';

  @override
  String get worshipMuteBody =>
      'Zu jeder Gebetszeit wird der Medienton (Videos, Musik, Spiele) für die Minuten unten stummgeschaltet. Über die Benachrichtigung schalten Sie ihn sofort wieder ein.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Stumm für: $minutes Min.';
  }

  @override
  String get worshipMinutesTitle => 'Dauer';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes Min.';
  }

  @override
  String get worshipNeedPlace => 'Wählen Sie zuerst einen Ort.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Als Nächstes: $prayer um $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Lautlos bis $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Medien stumm bis $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Erlauben Sie Waaiya, „Bitte nicht stören“ zu ändern, sonst kann das Telefon nicht lautlos werden.';

  @override
  String get worshipAllow => 'Erlauben';

  @override
  String get worshipExactNeeded =>
      '„Wecker und Erinnerungen“ ist für Waaiya nicht erlaubt, deshalb kann jede Änderung bis zu 10 Minuten zu spät kommen, oder später, wenn das Telefon schläft.';

  @override
  String get worshipNotificationsNeeded =>
      'Benachrichtigungen sind aus: Sie sehen nicht, wann das Telefon lautlos wird oder wieder klingelt.';

  @override
  String get worshipTonesTitle =>
      'Schlichter Klingelton und Benachrichtigungston';

  @override
  String get worshipTonesBody =>
      'Waaiya kann den Klingelton und die Benachrichtigungstöne nicht filtern, nur ersetzen. Wählen Sie einen schlichten Ton ohne Musik:';

  @override
  String worshipToneRing(Object number) {
    return 'Schlichter Klingelton $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Schlichter Benachrichtigungston $number';
  }

  @override
  String get worshipTonePlay => 'Anhören';

  @override
  String get worshipToneSet => 'Verwenden';

  @override
  String get worshipToneInUse => 'In Verwendung';

  @override
  String get worshipToneDone => 'Fertig.';

  @override
  String get worshipTonePermission =>
      'Erlauben Sie Waaiya, Systemeinstellungen zu ändern, kommen Sie zurück und tippen Sie erneut.';

  @override
  String get worshipToneFailed =>
      'Dieses Telefon hat Waaiya die Änderung nicht erlaubt. Wählen Sie in den Toneinstellungen einen Ton namens „Waaiya plain“.';

  @override
  String get worshipOpenSound => 'Toneinstellungen öffnen';

  @override
  String get worshipSmsTitle => 'Anrufe während des Gebets per SMS beantworten';

  @override
  String get worshipSmsBody =>
      'In den stillen Minuten nach jeder Gebetszeit bekommt ein Anruf, der weiterklingelt, eine SMS. Einmal pro Nummer und Gebet; nie an unterdrückte Nummern oder Kurzwahlnummern.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Nach: $seconds s Klingeln';
  }

  @override
  String get worshipSmsDelayTitle => 'Sekunden Klingeln vor der SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Nachricht: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Ihre Nachricht';

  @override
  String get worshipSmsTextDefault => 'Standard verwenden';

  @override
  String get worshipSmsCost =>
      'Jede Antwort ist eine normale SMS von Ihrer SIM, zum Preis Ihres Tarifs. Beim Roaming wird nichts gesendet.';

  @override
  String get worshipSmsRoaming =>
      'Gerade im Roaming: Es wird keine SMS gesendet.';

  @override
  String get worshipSmsLogTitle =>
      'Gesendete Antworten (nur auf diesem Telefon gespeichert)';

  @override
  String get worshipContinue => 'Weiter';

  @override
  String get worshipWhyDnd =>
      'Damit das Telefon zu den Gebetszeiten lautlos wird, erlauben Sie Waaiya auf der nächsten Seite den Zugriff auf „Bitte nicht stören“.';

  @override
  String get worshipWhyExact =>
      'Damit Waaiya genau pünktlich handelt, erlauben Sie ihm auf der nächsten Seite, Wecker und Erinnerungen zu stellen. Ohne das können Änderungen bis zu 10 Minuten zu spät kommen.';

  @override
  String get worshipWhyNotifications =>
      'Erlauben Sie Benachrichtigungen, damit Sie jede Änderung sehen und rückgängig machen können.';

  @override
  String get worshipWhyWrite =>
      'Um Ihren Klingelton oder Benachrichtigungston zu ändern, erlauben Sie Waaiya auf der nächsten Seite, Systemeinstellungen zu ändern.';

  @override
  String get worshipWhyPhone =>
      'Um zu wissen, dass ein Anruf klingelt und von welcher Nummer, braucht Waaiya die Berechtigungen „Telefon“ und „Anruflisten“. Nichts verlässt das Telefon außer Ihrer Antwort.';

  @override
  String get worshipWhySms =>
      'Um Ihre Antwort zu senden, braucht Waaiya die Berechtigung zum Senden von SMS. Es sendet nur diese Antwort, höchstens einmal pro Nummer und Gebet.';

  @override
  String get worshipMissingDnd =>
      'Der Zugriff auf „Bitte nicht stören“ wurde nicht erlaubt, deshalb bleibt die Stille aus.';

  @override
  String get worshipMissingPhone =>
      'Die Berechtigungen „Telefon“ und „Anruflisten“ wurden nicht erlaubt, deshalb bleibt die SMS-Antwort aus.';

  @override
  String get worshipMissingSms =>
      'Die Berechtigung zum Senden von SMS wurde nicht erlaubt, deshalb bleibt die SMS-Antwort aus.';

  @override
  String get worshipTryAgain => 'Erneut versuchen';

  @override
  String get protectTitle => 'Schutz für schwache Momente';

  @override
  String get protectBody =>
      'Für einen schwachen Moment, in dem Sie den Filter vielleicht ausschalten möchten. Wählen Sie jetzt, in Ruhe, eine Wartezeit: Dann stoppt die Stopp-Taste den Filter nicht sofort, und Sie entscheiden neu, wenn die Wartezeit vorbei ist. Eltern können auch eine PIN festlegen.';

  @override
  String protectDelay(Object value) {
    return 'Warten vor dem Ausschalten: $value';
  }

  @override
  String get protectDelayTitle => 'Warten vor dem Ausschalten';

  @override
  String get protectDelayBody =>
      'Zum Beispiel mit 30 Minuten: Sie drücken die Taste zum Stoppen, aber der Filter arbeitet weiter. Nach 30 Minuten fragt diese Seite, ob Sie immer noch stoppen möchten. Drücken Sie innerhalb von 15 Minuten „Bestätigen“, dann stoppt er; sonst ändert sich nichts. Genauso beim Ausschalten einer Abdeckung oder eines anderen Schutzes. Etwas einschalten geht immer sofort.';

  @override
  String get protectDelayOff => 'Keine';

  @override
  String get protectDelay1m => '1 Minute';

  @override
  String get protectDelay5m => '5 Minuten';

  @override
  String get protectDelay15m => '15 Minuten';

  @override
  String get protectDelay30m => '30 Minuten';

  @override
  String get protectDelay1h => '1 Stunde';

  @override
  String get protectDelay4h => '4 Stunden';

  @override
  String get protectDelay24h => '24 Stunden';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes Minuten';
  }

  @override
  String get protectPinNone => 'PIN: nicht festgelegt';

  @override
  String get protectPinIsSet => 'PIN: festgelegt';

  @override
  String get protectPinSet => 'PIN festlegen';

  @override
  String get protectPinRemove => 'Entfernen';

  @override
  String get protectPinBody =>
      'Mit einer PIN wird beim Stoppen des Filters oder beim Ausschalten eines Schutzes zuerst nach der PIN gefragt. Zum Beispiel legt ein Elternteil eine fest, damit ein Kind den Filter nicht ausschalten kann. Auch beim Ändern der Wartezeit oder der PIN wird danach gefragt.';

  @override
  String get protectPinForgot =>
      'Schreiben Sie die PIN an einem sicheren Ort auf: Wenn sie vergessen wird, gibt es kein Zurücksetzen. Der einzige Ausweg ist, die Daten von Waaiya zu löschen oder Waaiya neu zu installieren, was auch alle Einstellungen löscht.';

  @override
  String get protectPinTitle => 'PIN eingeben';

  @override
  String get protectPinNewTitle => 'PIN wählen';

  @override
  String get protectPinChangeTitle => 'PIN ändern';

  @override
  String get protectPinCurrent => 'Aktuelle PIN';

  @override
  String get protectPinNew => 'Neue PIN (4 bis 8 Ziffern)';

  @override
  String get protectPinAgain => 'Neue PIN wiederholen';

  @override
  String get protectPinBad => 'Verwenden Sie 4 bis 8 Ziffern.';

  @override
  String get protectPinDiffer => 'Die beiden neuen PINs sind nicht gleich.';

  @override
  String protectPinWrong(Object count) {
    return 'Falsche PIN. Noch $count Versuche bis zu einer Pause.';
  }

  @override
  String protectLocked(Object time) {
    return 'Zu viele falsche Versuche. Versuchen Sie es ab $time erneut.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Abbrechen';

  @override
  String get protectCancelChange => 'Änderung abbrechen';

  @override
  String get protectConfirm => 'Bestätigen';

  @override
  String protectPending(Object time, Object what) {
    return '$what: wartet bis $time. Danach in „Einstellungen“ bestätigen.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: Die Wartezeit ist vorbei. Möchten Sie es noch? Drücken Sie vor $time „Bestätigen“; sonst ändert sich nichts.';
  }

  @override
  String get protectWaitTitle => 'Diese Änderung wartet';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what geschieht jetzt nicht. Um $time bestätigen Sie es innerhalb von 15 Minuten in „Einstellungen“, wenn Sie es dann noch möchten. Wenn Sie nichts tun, ändert sich nichts.';
  }

  @override
  String get protectWaitStart => 'Warten beginnen';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Wartet bereits bis $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Wartet bis $time. Danach in „Einstellungen“ bestätigen.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'morgen um $time';
  }

  @override
  String get protectHeldBack =>
      'Nicht jetzt: Ihre Schutzeinstellungen lassen diese Änderung warten oder fragen nach der PIN.';

  @override
  String get protectLimits =>
      'Was dies nicht verhindern kann: Beenden erzwingen, Deinstallieren, Löschen der Daten von Waaiya und die Einstellungen von Android selbst. Um das zu sperren, bräuchte es besondere Android-Berechtigungen, die Waaiya nicht nutzt. Das schützt vor einem schwachen Moment, nicht vor einem entschlossenen Menschen.';

  @override
  String get protectLimitsDesktop =>
      'Was dies nicht verhindern kann: den Befehl waaiya in einem Terminal, das Entfernen von Waaiya oder das Löschen seines Einstellungsordners. Das schützt vor einem schwachen Moment, nicht vor einem entschlossenen Menschen.';

  @override
  String get protectLimitsWindows =>
      'Was dies nicht verhindern kann: den Befehl waaiya-filter.exe in einem Terminal, das Entfernen von Waaiya oder das Löschen seines Einstellungsordners. Das schützt vor einem schwachen Moment, nicht vor einem entschlossenen Menschen.';

  @override
  String get protectWhatStop => 'Den Filter stoppen';

  @override
  String protectWhatOff(Object name) {
    return 'Ausschalten: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Einschalten: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'App hinzufügen zu: $name';
  }

  @override
  String get protectWhatStrictness => 'Unschärfe weniger streng machen';

  @override
  String get protectWhatGender => 'Ändern, wer Waaiya nutzt';

  @override
  String protectWhatDelay(Object value) {
    return 'Warten vor dem Ausschalten ändern auf: $value';
  }

  @override
  String get protectWhatPinChange => 'PIN ändern';

  @override
  String get protectWhatPinClear => 'PIN entfernen';

  @override
  String get protectWhatSetting => 'Eine Einstellung ändern';

  @override
  String get onboardBodyDesktop =>
      'Waaiya entfernt Musikinstrumente aus dem Ton aller Apps auf diesem Computer. Sprache und Koranrezitation bleiben erhalten. Vorerst werden auch Gesangsstimmen entfernt.';

  @override
  String get worshipUseLocation => 'Meinen Standort verwenden';

  @override
  String get worshipWhyLocation =>
      'Um die Gebetszeiten an Ihrem Ort zu finden, liest Waaiya jetzt einmalig den ungefähren Standort dieses Telefons. Er bleibt als Ihr Ort auf dem Telefon und wird nirgendwohin gesendet.';

  @override
  String get worshipLocating => 'Standort wird ermittelt…';

  @override
  String get worshipLocationDenied =>
      'Der Standort wurde nicht erlaubt. Sie können stattdessen nach Ihrer Stadt suchen.';

  @override
  String get worshipLocationOff =>
      'Die Standortermittlung ist auf diesem Telefon aus. Schalten Sie sie ein und versuchen Sie es erneut, oder suchen Sie nach Ihrer Stadt.';

  @override
  String get worshipLocationSettings => 'Standorteinstellungen';

  @override
  String get worshipLocationFailed =>
      'Ihr Standort konnte nicht ermittelt werden. Versuchen Sie es gleich noch einmal, oder suchen Sie nach Ihrer Stadt.';

  @override
  String worshipPlaceNear(Object city) {
    return 'nahe $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Die offiziellen Zeiten des Ministeriums für Habous und islamische Angelegenheiten für $city.';
  }

  @override
  String get trayOpen => 'Waaiya öffnen';

  @override
  String get trayQuit => 'Beenden';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows lässt Waaiya bei der Anmeldung nicht starten. Schalte Waaiya unter Einstellungen › Apps › Autostart ein und schalte diese Option dann erneut ein.';

  @override
  String get engineErrorAutostartPolicy =>
      'Die Einstellungen dieses Computers, von seinem Administrator festgelegt, erlauben keinen Start von Waaiya bei der Anmeldung.';
}
