// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Rimuove gli strumenti musicali da tutte le app e mantiene la voce e la recitazione.';

  @override
  String get onboardTitle => 'Ti diamo il benvenuto';

  @override
  String get onboardBody =>
      'Waaiya rimuove gli strumenti musicali dal suono di tutte le app di questo telefono. La voce parlata e la recitazione del Corano vengono mantenute. Per ora vengono rimosse anche le voci che cantano.';

  @override
  String get onboardQuestion => 'Sono';

  @override
  String get genderMan => 'Un uomo';

  @override
  String get genderWoman => 'Una donna';

  @override
  String get onboardWhy =>
      'Serve solo a decidere quali impostazioni facoltative vedi. Per esempio, «Silenzia il canto femminile» viene proposto solo agli uomini. Puoi cambiarlo in seguito.';

  @override
  String get stateOnTitle => 'Il filtro è attivo';

  @override
  String get stateOffTitle => 'Il filtro è disattivato';

  @override
  String get stateStarting => 'Avvio…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Gli strumenti vengono rimossi da tutte le app. Il suono arriva circa $delayMs ms in ritardo (1000 ms sono un secondo).';
  }

  @override
  String get stateOffDetail => 'Tocca il pulsante per iniziare.';

  @override
  String get stateModelFailed =>
      'Non è stato possibile caricare il modello audio, quindi per sicurezza l\'audio è disattivato.';

  @override
  String get stateCaptureDenied =>
      'Serve l\'autorizzazione del microfono per ricevere l\'audio delle altre app.';

  @override
  String get stateStoppedBySystem =>
      'Android ha interrotto il filtro. Tocca il pulsante per avviarlo di nuovo.';

  @override
  String get stateSilencedTitle => 'Filtro interrotto';

  @override
  String get stateSilenced =>
      'Filtro interrotto: le altre app sono silenziate. Tocca il pulsante per avviarlo di nuovo, oppure Interrompi per sentirle senza filtro.';

  @override
  String get releaseSilence => 'Interrompi: senti le app senza filtro';

  @override
  String get powerStartCd => 'Avvia il filtro';

  @override
  String get powerStopCd => 'Interrompi il filtro';

  @override
  String get captureHint =>
      'Android chiederà di condividere lo schermo. Viene usato solo l\'audio: niente viene registrato o inviato.';

  @override
  String get needRecordAudio =>
      'Waaiya ha bisogno dell\'autorizzazione del microfono per ricevere l\'audio delle altre app. Non ti registra mai.';

  @override
  String get setupBannerTitle => 'Ancora un passaggio';

  @override
  String get setupBannerBody =>
      'Senza la configurazione iniziale qui sotto, sentirai la musica e l\'audio filtrato insieme.';

  @override
  String get step1Title => 'Installa Shizuku';

  @override
  String get step1Body => 'Un\'app di supporto gratuita dal Play Store.';

  @override
  String get step1Action => 'Scarica Shizuku';

  @override
  String get step2Title => 'Avvia Shizuku';

  @override
  String get step2Body =>
      'Shizuku si avvia tramite Wi-Fi con il Debug wireless di Android. Tocca il pulsante per vedere i passaggi, poi torna qui.';

  @override
  String get step2Action => 'Apri Shizuku';

  @override
  String get step2Update => 'Aggiorna Shizuku';

  @override
  String get step2TooOld =>
      'La tua versione di Shizuku è troppo vecchia. Aggiornala dal Play Store.';

  @override
  String get step2Denied =>
      'Shizuku è impostato per rifiutare sempre Waaiya. In Shizuku, consentilo nell\'elenco delle app.';

  @override
  String get step3Title => 'Concedi l\'autorizzazione';

  @override
  String get step3Body => 'Un tocco, poi scegli “Consenti”.';

  @override
  String get step3Action => 'Concedi l\'autorizzazione';

  @override
  String get step3Busy => 'Configurazione in corso…';

  @override
  String get setupDoneRestart =>
      'Fatto. Interrompi e riavvia il filtro una volta per applicarlo.';

  @override
  String setupFailed(String details) {
    return 'La configurazione non è stata completata. Dettagli:\n$details';
  }

  @override
  String get shizukuRefused =>
      'L\'autorizzazione di Shizuku è stata rifiutata. Tocca il pulsante per riprovare.';

  @override
  String get setupSlow =>
      'Shizuku ci sta mettendo più del solito. Continua ad aspettare: su alcuni telefoni il suo servizio impiega fino a un minuto ad avviarsi la prima volta.';

  @override
  String get setupTimeout =>
      'Shizuku non ha risposto entro 2 minuti. Apri Shizuku, controlla che indichi di essere in esecuzione, poi tocca di nuovo il pulsante. Se la configurazione termina più tardi, questa schermata si aggiorna da sola.';

  @override
  String get setupRefusedXiaomi =>
      'Questo telefono ha rifiutato le autorizzazioni. Su Xiaomi, Redmi e POCO, attiva “Debug USB (Impostazioni di sicurezza)” in Opzioni sviluppatore (ti chiede di accedere a un account Xiaomi), poi riprova.';

  @override
  String get setupRefusedColoros =>
      'Questo telefono ha rifiutato le autorizzazioni. Su OPPO, OnePlus e realme, in Opzioni sviluppatore, attiva “Disable permission monitoring” (Disattiva monitoraggio autorizzazioni). Nelle versioni più recenti si chiama “Disable system optimization” (Disattiva ottimizzazione di sistema) e potrebbe comparire solo con il telefono impostato in inglese. Per trovarlo, cerca “permission” nelle Impostazioni. Poi riprova.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi e POCO: se la notifica non ha un campo per digitare il codice, imposta lo stile delle notifiche su “Android” nelle impostazioni delle notifiche, oppure digita il codice in Waaiya usando lo schermo diviso.';

  @override
  String get stepDoneCd => 'Fatto';

  @override
  String stepTodoCd(int step) {
    return 'Passaggio $step';
  }

  @override
  String get computerToggle => 'Usa invece un computer';

  @override
  String get computerWeb =>
      'Il modo più semplice: su un computer apri waaiya.mssid.org/usb in Chrome o Edge, attiva il Debug USB e collega il telefono con un cavo. Niente da installare, e funziona anche con Android 10. Oppure, con adb installato:';

  @override
  String get computerBody =>
      'Attiva il Debug USB, collega il telefono ed esegui:';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get computerNote =>
      'La seconda riga è facoltativa: evita la domanda sulla condivisione dello schermo a ogni avvio.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingSilenceTitle => 'Silenzia le app che bloccano il filtro';

  @override
  String get settingSilenceBody =>
      'Consigliato. Alcune app non permettono di filtrare il loro audio; questa opzione le silenzia invece di lasciar passare la musica.';

  @override
  String get settingHoldSilenceTitle =>
      'Mantieni le app silenziate se il filtro si interrompe da solo';

  @override
  String get settingHoldSilenceBody =>
      'Consigliato. Se è Android a terminare il filtro (non tu), le altre app restano silenziate finché non lo riavvii o tocchi Interrompi, invece di riprodurre musica senza filtro. Richiede la configurazione iniziale.';

  @override
  String get settingStereoTitle => 'Audio stereo';

  @override
  String get settingStereoBody =>
      'Disattivato: mono, che consuma circa metà della batteria e funziona senza scatti su più telefoni. Attivato: mantiene separati i lati sinistro e destro. Se il telefono è troppo lento per lo stereo, passa comunque al mono da solo.';

  @override
  String get settingSingingTitle => 'Silenzia il canto femminile';

  @override
  String get settingSingingBody =>
      'Per esempio, una canzone cantata da una donna viene silenziata, ma una donna che fa un discorso si sente ancora.';

  @override
  String get settingSingingNoModel =>
      'Questa versione non ha un rilevatore di canto, quindi tutte le voci vengono silenziate finché questa opzione è attiva.';

  @override
  String get settingRestart =>
      'Interrompi e riavvia il filtro per applicare le modifiche.';

  @override
  String get settingGenderTitle => 'Sono';

  @override
  String get change => 'Cambia';

  @override
  String get playerTitle => 'Video perfettamente sincronizzati';

  @override
  String get playerBody =>
      'Condividi un video con Waaiya (o usa “Apri con”) per guardarlo filtrato senza ritardo.';

  @override
  String get licences => 'Licenze open source';

  @override
  String get licencesIntro =>
      'Waaiya è software libero con licenza GNU Affero General Public License v3 o successiva. Codice sorgente: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (dati di addestramento): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Testi completi';

  @override
  String get back => 'Indietro';

  @override
  String get linkEntryTitle => 'Apri un link';

  @override
  String get linkEntryBody =>
      'Incolla un link di YouTube, TikTok o Instagram per guardarlo o salvarlo senza musica.';

  @override
  String get linkTitle => 'Apri un link';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Link video o audio';

  @override
  String get linkPaste => 'Incolla';

  @override
  String get linkOpen => 'Apri';

  @override
  String get linkResolving => 'Apertura del link…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Guarda senza musica';

  @override
  String get linkSave => 'Salva senza musica';

  @override
  String get linkListen => 'Ascolta senza musica';

  @override
  String get linkAudioOnly =>
      'Il video di questo link non si può ancora aprire: solo il suo audio.';

  @override
  String get linkDownloading => 'Download in corso…';

  @override
  String get linkFiltering => 'Rimozione della musica…';

  @override
  String get linkCancel => 'Annulla';

  @override
  String get linkCancelled => 'Annullato. Non è stato salvato nulla.';

  @override
  String get linkTimedOut =>
      'Android ha interrotto il salvataggio: permette questo tipo di lavoro solo per poche ore al giorno. Non è stato salvato nulla; apri Waaiya e riprova.';

  @override
  String get linkExportFailed =>
      'Impossibile salvare questo contenuto. Non è stato salvato nulla.';

  @override
  String get linkSaved => 'Salvato senza musica';

  @override
  String get linkSavedVideo => 'Nella tua galleria: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Nella tua musica: Music › Waaiya';

  @override
  String get linkPlay => 'Riproduci';

  @override
  String get linkShare => 'Condividi';

  @override
  String get linkShareNote =>
      'Condividi solo i video che hai il permesso di condividere.';

  @override
  String get linkLive => 'Le dirette non possono essere salvate.';

  @override
  String get linkBusy =>
      'È in corso il salvataggio di un altro video. Attendi che finisca.';

  @override
  String get linkInvalid => 'Incolla un link web (che inizia con https://).';

  @override
  String get linkLogin =>
      'Il sito non ha voluto mostrare questo video senza un account. I post pubblici di solito si aprono: riprova tra qualche minuto. I post privati non si possono aprire.';

  @override
  String get linkUnsupported => 'Questo sito non è supportato.';

  @override
  String get linkPlaylist => 'Questa è una playlist. Apri un solo video.';

  @override
  String get linkNoFormat =>
      'Questo video non è ancora in un formato che Waaiya può filtrare.';

  @override
  String get linkFailed =>
      'Impossibile aprire questo link. Controlla la connessione e riprova.';

  @override
  String get linkPlayFailed =>
      'Impossibile riprodurlo. Non è stato riprodotto nulla senza filtro.';

  @override
  String get linkLimited =>
      'Il sito sta limitando le richieste in questo momento. Riprova tra qualche minuto.';

  @override
  String get blurTitle => 'Sfocatura dello schermo';

  @override
  String get blurBody =>
      'Copre le persone e le immagini sullo schermo, in tutte le app, mentre il filtro è attivo. Funziona sul telefono; niente viene inviato da nessuna parte.';

  @override
  String get blurOnTitle => 'La sfocatura è attiva';

  @override
  String get blurOffTitle => 'La sfocatura è spenta';

  @override
  String get blurStartCd => 'Avvia la sfocatura';

  @override
  String get blurStopCd => 'Ferma la sfocatura';

  @override
  String get blurOffDetail =>
      'Tocca il pulsante per avviare. Il filtraggio parte insieme.';

  @override
  String get blurWhatTitle => 'Cosa sfocare';

  @override
  String get blurWomenTitle => 'Sfoca le donne';

  @override
  String get blurWomenBody =>
      'Copre tutto il corpo. Se l\'app non è sicura che una persona sia un uomo, copre anche lei.';

  @override
  String get blurNudityTitle => 'Sfoca le immagini indecenti';

  @override
  String get blurNudityBody =>
      'Nudità o abiti succinti, su chiunque: viene coperto tutto lo schermo.';

  @override
  String get blurFailTitle =>
      'Copri lo schermo se la sfocatura non sta al passo';

  @override
  String get blurFailBody =>
      'Attivato: tutto lo schermo viene coperto quando il telefono è troppo lento o la sfocatura non funziona. Disattivato: lo schermo resta visibile con un avviso.';

  @override
  String get blurSetupManual => 'Consenti nelle impostazioni di Android';

  @override
  String get blurStatusNeedsSetup =>
      'Per sfocare, Waaiya deve mostrarsi sopra le altre app. Meglio: «Vai alla configurazione», così i tuoi tocchi arrivano comunque all\'app sotto la sfocatura. Oppure «Consenti nelle impostazioni di Android», ma allora un tocco su un\'area sfocata non fa nulla.';

  @override
  String get blurStatusNeedsOverlay =>
      'Per sfocare, Waaiya deve mostrarsi sopra le altre app. Meglio: fai la configurazione una tantum, così i tuoi tocchi arrivano comunque all\'app sotto la sfocatura. Oppure consenti «Mostra sopra altre app» nelle impostazioni di Android, ma allora un tocco su un\'area sfocata non fa nulla.';

  @override
  String get blurFailUnavailable =>
      'Non disponibile per ora: una copertura a schermo intero bloccherebbe ogni tocco e il telefono potrebbe restare bloccato. Avvia l\'assistente di Waaiya (Android 12 o versioni successive) e l\'opzione si attiva: le coperture vengono allora disegnate in modo che i tocchi le attraversino. Fino ad allora, quando la sfocatura non sta al passo, lo schermo resta visibile con un avviso.';

  @override
  String get blurFailNeedsA11y =>
      'Non disponibile per ora: una copertura a schermo intero bloccherebbe ogni tocco e il telefono potrebbe restare bloccato. Avvia l\'assistente di Waaiya (Android 12 o versioni successive) o attiva il servizio di accessibilità Sfocatura Waaiya nelle impostazioni di Android e l\'opzione si attiva. Fino ad allora, lo schermo resta visibile con un avviso.';

  @override
  String get languageTitle => 'Lingua';

  @override
  String settingLanguageTitle(String language) {
    return 'Lingua: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Interrompi e riavvia il filtro per applicare le impostazioni della sfocatura.';

  @override
  String get blurStatusStarting => 'Avvio della sfocatura…';

  @override
  String get blurStatusOn => 'Sfocatura attiva.';

  @override
  String get blurStatusOnVisible =>
      'Sfocatura attiva, in modalità prudente: questo telefono mostra la sfocatura nella propria acquisizione dello schermo, quindi un\'area sfocata resta sfocata finché la scena non cambia.';

  @override
  String get blurStatusModels =>
      'In questa versione manca un modello di sfocatura per l\'opzione scelta.';

  @override
  String get blurStatusFailing =>
      'La sfocatura non riesce a stare al passo in questo momento.';

  @override
  String get blurStatusNoOverlay =>
      'La sfocatura non può essere mostrata sopra le altre app: consentilo qui sopra.';

  @override
  String blurStatusNoCapture(String details) {
    return 'La sfocatura non riesce a vedere lo schermo. Dettagli:\n$details';
  }

  @override
  String get step2Guide => 'Come avviare Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Non disponibile: su questa versione di Android una copertura a schermo intero bloccherebbe ogni tocco e il telefono potrebbe restare bloccato (le coperture attraversate dai tocchi richiedono Android 12 o versioni successive). Quando la sfocatura non sta al passo, lo schermo resta visibile con un avviso.';

  @override
  String get guideTitle => 'Avviare Shizuku, passo dopo passo';

  @override
  String get guideOpenDev => 'Opzioni sviluppatore';

  @override
  String get guideOpenShizuku => 'Apri Shizuku';

  @override
  String get guideClose => 'Chiudi';

  @override
  String get guideBody =>
      'Servono il Wi-Fi e Android 11 o versioni successive. L\'accoppiamento si fa una sola volta; dopo un riavvio del telefono ripeti solo il passaggio 7.\n\n1. Connetti il telefono al Wi-Fi.\n\n2. Attiva le Opzioni sviluppatore: Impostazioni › Informazioni sul telefono › Informazioni software › tocca 7 volte “Numero build”. (Su altri telefoni: Impostazioni › Informazioni sul telefono › Numero build.)\n\n3. Apri Shizuku. Se chiede di mostrare notifiche, consentilo: il codice di accoppiamento si digita in una notifica di Shizuku.\n\n4. In Shizuku, sotto “Start via Wireless debugging” (Avvia tramite Debug wireless), tocca “Pairing” (Accoppiamento). Nella pagina che si apre, tocca “Developer options” (Opzioni sviluppatore), attiva “Debug wireless” e conferma con “Consenti”.\n\n5. Tocca le parole “Debug wireless” (non l\'interruttore), poi “Accoppia dispositivo con codice di accoppiamento”. Compare un codice di 6 cifre.\n\n6. Tieni aperta quella schermata e abbassa la tendina delle notifiche. Quando la notifica di Shizuku dice “Pairing service found” (Servizio di accoppiamento trovato), tocca “Enter pairing code” (Inserisci codice di accoppiamento) e digita il codice. Shizuku indica che l\'accoppiamento è riuscito.\n\n7. Torna in Shizuku e tocca “Start” (Avvia) sotto “Start via Wireless debugging”. Aspetta finché non dice “Shizuku is running” (Shizuku è in esecuzione).\n\n8. Torna in Waaiya e tocca “Concedi l\'autorizzazione”, poi “Consenti”.\n\nDopo un riavvio del telefono Shizuku si ferma: connettiti al Wi-Fi, riattiva “Debug wireless” se è disattivato, apri Shizuku e tocca “Start”. Non serve un nuovo accoppiamento.';

  @override
  String get wsetupRouteTitle => 'Configura su questo telefono';

  @override
  String get wsetupRouteBody =>
      'Quattro brevi passaggi, da fare una volta sola. Nessuna app in più e nessun computer. Waaiya spunta ogni passaggio quando è completato.';

  @override
  String get wizDevTitle => 'Attiva le Opzioni sviluppatore';

  @override
  String get wizDevBody =>
      'In Informazioni sul telefono, tocca 7 volte “Numero build”, poi torna qui. Se non lo trovi, cerca “Numero build” nelle Impostazioni.';

  @override
  String get wizDevBodySamsung =>
      'In Informazioni sul telefono › Informazioni software, tocca 7 volte “Numero build”, poi torna qui.';

  @override
  String get wizDevBodyXiaomi =>
      'In Informazioni sul telefono, tocca 7 volte “Versione SO” (sui telefoni più vecchi “Versione MIUI”; su alcuni si trova in “Specifiche e informazioni dettagliate”), poi torna qui.';

  @override
  String get wizDevBodyColoros =>
      'In Info dispositivo (o Informazioni sul telefono) › Versione, tocca 7 volte “Numero build”, poi torna qui.';

  @override
  String get wizDevBodyVivo =>
      'In Informazioni sul telefono, tocca 7 volte “Versione software” (su alcuni telefoni: Informazioni software › “Numero build”), poi torna qui.';

  @override
  String get wizDevBodyHuawei =>
      'In Informazioni sul telefono, tocca 7 volte “Numero build”, poi torna qui.';

  @override
  String get wizDevBodyTranssion =>
      'In Il mio telefono (o Informazioni sul telefono), tocca 7 volte “Numero build”, poi torna qui.';

  @override
  String get setupNoteHuawei =>
      'Huawei: molti telefoni Huawei non hanno il “Debug wireless”. Se non lo trovi in Opzioni sviluppatore, usa un computer (“Altri modi” qui sotto).';

  @override
  String get wsetupFilterOn =>
      'Il filtro è attivo: su questa versione di Android il codice non si può digitare in una notifica mentre il filtro è in funzione. Interrompi prima il filtro, oppure usa lo schermo diviso e “Digita il codice qui”.';

  @override
  String get wizDevSearch =>
      'I nomi possono cambiare in base alla lingua del telefono: se non lo trovi, usa la ricerca in alto nelle Impostazioni.';

  @override
  String get wizDevAction => 'Apri Informazioni sul telefono';

  @override
  String get wizWifiTitle => 'Connettiti al Wi-Fi';

  @override
  String get wizWifiBody =>
      'Va bene qualsiasi rete Wi-Fi; Internet non è necessario.';

  @override
  String get wizWifiAction => 'Apri le impostazioni Wi-Fi';

  @override
  String get wizWdTitle => 'Attiva il Debug wireless';

  @override
  String get wizWdBody =>
      'Waaiya apre le Opzioni sviluppatore su “Debug wireless”. Attivalo e tocca “Consenti”.';

  @override
  String get wizWdAction => 'Apri Opzioni sviluppatore';

  @override
  String get wizPairTitle => 'Digita il codice di accoppiamento';

  @override
  String get wizPairBody =>
      'Tocca le parole “Debug wireless”, poi “Accoppia dispositivo con codice di accoppiamento”. Digita le 6 cifre nella notifica di Waaiya. Al resto pensa Waaiya.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya è già accoppiato con questo telefono: non serve nessun codice. Tocca il pulsante e Waaiya finisce da solo.';

  @override
  String get wizPairAction => 'Continua';

  @override
  String get wizAgain => 'Esegui di nuovo la configurazione';

  @override
  String get setupShizukuReadyTitle => 'Con Shizuku, che è già in esecuzione';

  @override
  String get setupOtherWaysPlain => 'Altri modi per fare la configurazione';

  @override
  String get wizSkip => 'Vai al Debug wireless';

  @override
  String get setupOtherWays => 'Altri modi: Shizuku o un computer';

  @override
  String get wsetupEnterHere => 'Digita il codice qui';

  @override
  String get wsetupCancel => 'Annulla';

  @override
  String get wsetupAndroid10 =>
      'Android 10 non può fare la configurazione da solo: serve un computer, direttamente (qui sotto) o per avviare Shizuku una volta.';

  @override
  String get wsetupShizukuHeading => 'Oppure con l\'app Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku permette anche ai tocchi di attraversare le coperture dello schermo.';

  @override
  String get wsetupChannel => 'Configurazione iniziale';

  @override
  String get wsetupNotifTitle =>
      'Configurazione di Waaiya: in attesa del codice di accoppiamento';

  @override
  String get wsetupFoundTitle => 'Schermata di accoppiamento trovata';

  @override
  String get wsetupBusyTitle => 'Configurazione di Waaiya';

  @override
  String get wsetupDoneTitle => 'Configurazione completata';

  @override
  String get wsetupDoneBody =>
      'Ora Waaiya può silenziare l\'audio originale. Puoi disattivare il Debug wireless.';

  @override
  String get wsetupDoneHelperBody =>
      'Fatto. Questo telefono non lascia che le app mantengano queste autorizzazioni, quindi è l\'assistente di Waaiya a silenziare l\'audio originale. L\'assistente si ferma quando il telefono si riavvia e quando Waaiya viene aggiornato. Quando poi apri Waaiya, riavvia l\'assistente da solo se il Debug wireless è attivo; altrimenti mostra un pulsante per farlo.';

  @override
  String get helperMissingTitle => 'L\'assistente di Waaiya è fermo';

  @override
  String get helperMissingBody =>
      'Questo telefono non mantiene le autorizzazioni di Waaiya, quindi Waaiya usa il suo assistente. L\'assistente si ferma quando il telefono si riavvia e quando Waaiya viene aggiornato. Connettiti al Wi-Fi, attiva “Debug wireless” in Opzioni sviluppatore, poi tocca “Avvia l\'assistente di Waaiya”.';

  @override
  String get helperChannel => 'Assistente di Waaiya';

  @override
  String get helperStarting => 'Avvio dell\'assistente…';

  @override
  String get helperModeNote =>
      'Questo telefono non lascia che le app mantengano queste autorizzazioni: il lavoro lo fa l\'assistente di Waaiya. Si ferma quando il telefono si riavvia e quando Waaiya viene aggiornato. Quando poi apri Waaiya, riavvia l\'assistente da solo se il Debug wireless è attivo; altrimenti mostra un pulsante per farlo.';

  @override
  String get helperTipXiaomi =>
      'Facoltativo, per mantenere le autorizzazioni per sempre (niente assistente dopo i riavvii): in Opzioni sviluppatore, attiva “Debug USB (Impostazioni di sicurezza)” (ti chiede di accedere a un account Xiaomi), poi rifai la configurazione.';

  @override
  String get helperTipColoros =>
      'Facoltativo, per mantenere le autorizzazioni per sempre (niente assistente dopo i riavvii): in Opzioni sviluppatore, attiva “Disable permission monitoring” (Disattiva monitoraggio autorizzazioni); nelle versioni più recenti “Disable system optimization” (Disattiva ottimizzazione di sistema), che potrebbe comparire solo con il telefono impostato in inglese. Poi rifai la configurazione.';

  @override
  String get stateOnHelperMissing =>
      'L\'audio originale non è silenziato, quindi senti la musica insieme all\'audio filtrato: l\'assistente di Waaiya è fermo. Connettiti al Wi-Fi, attiva il Debug wireless, poi tocca “Avvia l\'assistente di Waaiya”.';

  @override
  String get setupRefusedTryWireless =>
      'Oppure usa “Configura su questo telefono” in questa pagina: in questo modo l\'assistente di Waaiya funziona senza quell\'opzione.';

  @override
  String get helperStartAnywayTitle => 'L\'assistente di Waaiya è fermo';

  @override
  String get helperStartAnywayBody =>
      'Senza l\'assistente sentirai la musica insieme all\'audio filtrato. Avvia prima l\'assistente (il Debug wireless deve essere attivo), oppure avvia comunque il filtro.';

  @override
  String get wsetupFailedTitle => 'La configurazione non è stata completata';

  @override
  String get wsetupPairing => 'Accoppiamento…';

  @override
  String get wsetupConnecting =>
      'Connessione e concessione delle autorizzazioni…';

  @override
  String get wsetupNeedWifi =>
      'Connettiti prima a una rete Wi-Fi (Internet non è necessario): il Debug wireless funziona solo con il Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'In Opzioni sviluppatore, attiva “Debug wireless”, poi tocca il suo nome e “Accoppia dispositivo con codice di accoppiamento”.';

  @override
  String get wsetupOpenDialog =>
      'In Debug wireless, tocca “Accoppia dispositivo con codice di accoppiamento”. Tieni il codice sullo schermo e tocca qui “Inserisci codice”.';

  @override
  String get wsetupEnterCodeBody =>
      'Tocca “Inserisci codice” e digita il codice di 6 cifre mostrato nelle Impostazioni.';

  @override
  String get wsetupCodeWaiting =>
      'Codice ricevuto. In attesa della schermata “Accoppia dispositivo con codice di accoppiamento”: tienila aperta.';

  @override
  String get wsetupWrongCode =>
      'Quel codice non è stato accettato. Controlla le 6 cifre sullo schermo e inseriscile di nuovo. Se la schermata di accoppiamento si è chiusa, riaprila: il codice cambia.';

  @override
  String get wsetupPairingFailed =>
      'L\'accoppiamento non ha funzionato. Chiudi la schermata di accoppiamento, apri di nuovo “Accoppia dispositivo con codice di accoppiamento” e inserisci il nuovo codice.';

  @override
  String get wsetupWaitingConnect =>
      'Accoppiato. Lascia attivo il “Debug wireless”: Waaiya si sta connettendo.';

  @override
  String get wsetupNotPaired =>
      'Questo telefono non riconosce più Waaiya (l\'accoppiamento è stato rimosso o è scaduto). Apri “Accoppia dispositivo con codice di accoppiamento” e inserisci il codice.';

  @override
  String get wsetupConnectFailed =>
      'Impossibile connettersi al Debug wireless. Disattivalo e riattivalo: Waaiya riprova da solo.';

  @override
  String get wsetupGrantFailed =>
      'Connesso, ma le autorizzazioni mancano ancora. Usa Shizuku o un computer qui sotto.';

  @override
  String get wsetupTimeout =>
      'Interrotto dopo 10 minuti senza finire. Puoi riprovare.';

  @override
  String get wsetupCodeUnreadable =>
      'Digita le 6 cifre del codice di accoppiamento.';

  @override
  String get wsetupCodeHint => 'Codice di 6 cifre';

  @override
  String get wsetupEnterCode => 'Inserisci codice';

  @override
  String wsetupDetail(String details) {
    return 'Dettagli: $details';
  }

  @override
  String get wsetupErrTimeout => 'nessuna risposta in tempo';

  @override
  String get wsetupErrRefused => 'connessione rifiutata';

  @override
  String get wsetupDevOff =>
      'Le Opzioni sviluppatore sono disattivate. In Informazioni sul telefono, tocca 7 volte “Numero build”, poi torna qui.';

  @override
  String get wsetupOpenAbout => 'Informazioni sul telefono';

  @override
  String get wsetupNotifOff =>
      'Le notifiche di Waaiya sono disattivate, quindi il codice non si può digitare in una notifica. Usa lo schermo diviso (Impostazioni in una metà, Waaiya nell\'altra) e tocca “Digita il codice qui”.';

  @override
  String get wsetupCodeDialogTitle => 'Codice di accoppiamento';

  @override
  String get wsetupCodeDialogBody =>
      'Solo con lo schermo diviso (Impostazioni in una metà, Waaiya nell\'altra): se esci dalle Impostazioni, la schermata di accoppiamento si chiude e il suo codice smette di funzionare. Digita il codice di 6 cifre mostrato sotto “Accoppia dispositivo con codice di accoppiamento”.';

  @override
  String get wsetupCodeOk => 'Accoppia';

  @override
  String get blurStrictTitle => 'Chi resta scoperto';

  @override
  String blurStrictValue(String level) {
    return 'Chi resta scoperto: $level';
  }

  @override
  String get blurStrict0 =>
      'Rigoroso: solo le persone che l\'app ritiene quasi certamente uomini';

  @override
  String get blurStrict1 =>
      'Equilibrato: circa il doppio degli uomini resta scoperto';

  @override
  String get blurStrict2 =>
      'Permissivo: qualche uomo in più rispetto a equilibrato';

  @override
  String get blurStrict0Short => 'rigoroso';

  @override
  String get blurStrict1Short => 'equilibrato';

  @override
  String get blurStrict2Short => 'permissivo';

  @override
  String get blurStrictHelp =>
      'Viene coperto chiunque l\'app non riconosca con certezza come uomo. Rigoroso lascia scoperti circa 7 uomini su 100; equilibrato circa 14, permissivo circa 16. Ogni livello meno rigoroso lascia scoperta anche circa 1 donna in più su 100.';

  @override
  String get stateOnNotMuted =>
      'L\'audio originale non è ancora silenziato, quindi senti la musica insieme all\'audio filtrato. Completa la configurazione iniziale qui sotto.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya non riesce a silenziare l\'audio originale dell\'app in riproduzione, quindi la musica potrebbe sentirsi ancora. Interrompi e riavvia il filtro. Se continua, invia il rapporto di diagnostica (in fondo a questa schermata).';

  @override
  String get stateTooSlow =>
      'Questo telefono è troppo lento per filtrare l\'audio in tempo reale, quindi l\'audio si interrompe. “Apri un link” qui sotto funziona comunque: filtra il video prima di riprodurlo.';

  @override
  String get stateMonoNote =>
      'L\'audio è in mono perché questo telefono riesca a stare al passo.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Silenziata, perché non permette il filtro: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'In riproduzione senza filtro, perché non permette il filtro: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android non ha dato a Waaiya l\'audio delle altre app. Tocca il pulsante per avviare di nuovo.';

  @override
  String get stateCaptureCancelled =>
      'L\'avvio è stato annullato alla domanda di Android sulla condivisione dello schermo. Lì Waaiya ha bisogno che tu scelga “Avvia” per ricevere l\'audio. Niente viene registrato o inviato.';

  @override
  String get startNoSetupTitle => 'La musica si sentirà ancora';

  @override
  String get startNoSetupBody =>
      'La configurazione iniziale non è ancora stata fatta. Senza di essa Waaiya non può silenziare l\'audio originale: sentirai la musica e l\'audio filtrato insieme.\n\n“Apri un link” funziona senza alcuna configurazione.';

  @override
  String get startNoSetupSetup => 'Fai la configurazione';

  @override
  String get startNoSetupAnyway => 'Avvia comunque';

  @override
  String get diagButton => 'Un problema? Rapporto di diagnostica';

  @override
  String get diagTitle => 'Rapporto di diagnostica';

  @override
  String get diagNote =>
      'Ciò che Waaiya vede su questo telefono. Copialo o condividilo con chi ti aiuta. L\'app di per sé non invia nulla.';

  @override
  String get notifStoppedTitle => 'Waaiya si è fermato';

  @override
  String get notifStoppedText =>
      'L\'audio non è più filtrato. Tocca per avviare di nuovo.';

  @override
  String get wsetupGuide => 'Passaggi con immagini';

  @override
  String get navFilter => 'Filtro';

  @override
  String get navScreen => 'Schermo';

  @override
  String get navLinks => 'Link';

  @override
  String get navSetup => 'Configura';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get setupDoneTitle => 'Configurazione completata';

  @override
  String get setupDoneBody =>
      'Waaiya può silenziare l\'audio originale delle altre app. Rifai la configurazione solo se qualcosa è cambiato (è stata annullata, o Waaiya dice che manca).';

  @override
  String get setupRedo => 'Mostra di nuovo la configurazione';

  @override
  String get setupGo => 'Vai alla configurazione';

  @override
  String get helperTitle => 'Tocchi attraverso le coperture';

  @override
  String get helperBodyOff =>
      'Senza aiuto, una copertura blocca i tocchi sotto di essa. L\'assistente di Waaiya disegna le coperture in modo che i tocchi le attraversino. Attiva il Debug wireless (serve il Wi-Fi) e tocca il pulsante; la prima volta, esegui l\'accoppiamento una volta come nella configurazione. Dopo un riavvio del telefono, toccalo di nuovo.';

  @override
  String get helperStart => 'Avvia l\'assistente di Waaiya';

  @override
  String get helperOn =>
      'L\'assistente di Waaiya disegna le coperture: i tocchi le attraversano. Si ferma quando il telefono si riavvia o quando il Debug USB viene disattivato; in quel caso tocca di nuovo il pulsante.';

  @override
  String get helperShizukuOn =>
      'Shizuku disegna le coperture: i tocchi le attraversano.';

  @override
  String get helperOrShizuku => 'Oppure con Shizuku:';

  @override
  String get filterOptionsTitle => 'Opzioni del filtro';

  @override
  String get settingsGeneralTitle => 'Generali';

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
  String get worshipPrayerSunrise => 'Alba';

  @override
  String get worshipPrayerDhuhr => 'Dhuhr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'Termina subito il silenzio';

  @override
  String get worshipUnmute => 'Riattiva subito l\'audio';

  @override
  String get worshipSmsDefault =>
      'È l\'ora della preghiera, ora non posso rispondere. Ti richiamo io.';

  @override
  String get updateTitle => 'Aggiornamenti';

  @override
  String get updateAuto => 'Cerca una nuova versione una volta al giorno';

  @override
  String get updateAutoBody =>
      'Waaiya chiede a waaiya.mssid.org se esiste una versione più recente e non invia nient\'altro. Non si scarica nulla finché non tocchi Aggiorna ora.';

  @override
  String get updateCheck => 'Cerca ora';

  @override
  String get updateChecking => 'Ricerca in corso…';

  @override
  String updateNone(String version) {
    return 'Hai l\'ultima versione ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest è disponibile. Tu hai la $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Download: $size, solo le modifiche (l\'app completa è $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Download: $size.';
  }

  @override
  String get updateNow => 'Aggiorna ora';

  @override
  String updateDownloading(String progress) {
    return 'Download in corso: $progress';
  }

  @override
  String get updatePreparing => 'Preparazione dell\'aggiornamento…';

  @override
  String get updateInstalling =>
      'Conferma l\'installazione nella schermata mostrata da Android.';

  @override
  String get updateStopsFilter =>
      'L\'installazione interrompe il filtro. Riavvialo dopo l\'aggiornamento.';

  @override
  String get updatePermission =>
      'Consenti a Waaiya di installare i suoi aggiornamenti, poi tocca di nuovo Aggiorna ora.';

  @override
  String get updateFailed =>
      'Non è stato possibile completare l\'aggiornamento. Riprova più tardi o scaricalo dal sito.';

  @override
  String get updateOpenPage => 'Apri la pagina di download';

  @override
  String get updateCheckFailed =>
      'Non è possibile controllare ora. Riprova più tardi.';

  @override
  String get moveOldTitle => 'Waaiya si è trasferita';

  @override
  String get moveOldBody =>
      'Su Android Waaiya ora arriva come una nuova app (la stessa Waaiya con un nuovo nome), e questa non riceverà più aggiornamenti. Installa la nuova: le tue impostazioni la seguono. Poi fai la sua configurazione iniziale e rimuovi questa.';

  @override
  String get moveOldInstalled =>
      'La nuova Waaiya è installata. Aprila: prende le tue impostazioni. Fai la sua configurazione iniziale, poi rimuovi questa vecchia così che le due non filtrino mai insieme.';

  @override
  String get moveInstall => 'Installa la nuova Waaiya';

  @override
  String get moveOpenNew => 'Apri la nuova Waaiya';

  @override
  String get moveRemoveThis => 'Rimuovi questa vecchia Waaiya';

  @override
  String get moveNewTitle => 'La vecchia Waaiya è ancora installata';

  @override
  String get moveNewBody =>
      'La vecchia Waaiya (precedente alla versione 0.2.15) è ancora su questo telefono. Rimuovila così che le due non filtrino mai insieme.';

  @override
  String get moveNewImported => 'Le tue impostazioni sono state prese da lì.';

  @override
  String get moveRemoveOld => 'Rimuovi la vecchia Waaiya';

  @override
  String get desktopPreview =>
      'Anteprima: il motore del filtro non è ancora collegato su questo computer. Il pulsante mostra solo come funzionerà l\'app.';

  @override
  String actionFailed(String details) {
    return 'Non ha funzionato: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Gli strumenti vengono rimossi da tutte le app.';

  @override
  String get engineErrorNoPactl =>
      'Strumenti audio non trovati (pactl). Waaiya ha bisogno di PulseAudio, oppure di PipeWire con pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Il server audio non è in esecuzione (PulseAudio o PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Questo sistema non ha una sessione utente systemd, che esegue il filtro in background.';

  @override
  String get engineErrorNoOutput => 'Nessun altoparlante o cuffia trovati.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Impossibile installare il filtro. Dettagli:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Il filtro non si è avviato. Dettagli:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Il filtro si è fermato con un errore. Dettagli:\n$details';
  }

  @override
  String get autostartTitle => 'Avvia all\'accesso';

  @override
  String get autostartBody => 'Filtra l\'audio appena accedi.';

  @override
  String get blurBodyDesktop =>
      'Copre le persone e le immagini sullo schermo, sopra ogni finestra, finché Waaiya è aperto (funziona sia con il filtro audio attivo sia disattivato). Funziona su questo computer; niente viene inviato da nessuna parte. Chiudere la finestra di Waaiya ferma la sfocatura.';

  @override
  String get blurFailBodyDesktop =>
      'Attivato: tutto lo schermo viene coperto quando il computer è troppo lento o la sfocatura non funziona; i clic arrivano comunque alle finestre sottostanti. Disattivato: lo schermo resta visibile con una barra rossa in alto.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Sfocatura attiva. Questo desktop mostra la sfocatura nella propria acquisizione dello schermo, quindi un\'area sfocata resta sfocata finché la scena non cambia.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'La sfocatura non può essere mostrata sopra le altre finestre su questo desktop. Dettagli:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Scegli il tuo schermo nella finestra di condivisione dello schermo e consentilo. Waaiya lo chiede solo una volta; l\'immagine resta su questo computer.';

  @override
  String blurStatusExited(String details) {
    return 'La sfocatura si è fermata inaspettatamente. Disattiva e riattiva un\'opzione di sfocatura per riprovare. Dettagli:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Il rilevatore del canto femminile non si è caricato, quindi le voci vengono silenziate finché quell\'opzione è attiva.';

  @override
  String get blurStatusUncovered =>
      'Un monitor non è coperto dalla sfocatura: non è stato condiviso con la sfocatura, oppure è stato collegato dopo. Disattiva e riattiva un\'opzione di sfocatura e scegli tutti gli schermi nella finestra di condivisione dello schermo.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'In questa installazione mancano i modelli della sfocatura, quindi non può coprire nulla; una barra rossa resta in alto sullo schermo. Reinstalla Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Ciò che Waaiya vede su questo computer. Copialo e dallo a chi ti aiuta. L\'app di per sé non invia nulla.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Consigliato. Se il filtro si interrompe da solo (per un errore, non per opera tua), le altre app restano silenziate finché non lo riavvii o premi Interrompi, invece di riprodurre musica senza filtro.';

  @override
  String get settingStereoBodyDesktop =>
      'Disattivato: mono, che usa meno risorse del computer. Attivato: mantiene separati i lati sinistro e destro. Se il computer è troppo lento per lo stereo, passa al mono da solo.';

  @override
  String get linkEntryBodyDesktop =>
      'Incolla un link di YouTube, TikTok o Instagram per guardarlo con il filtro attivo, oppure per salvarlo senza musica.';

  @override
  String get linkEntryBodyWatch =>
      'Incolla un link di YouTube, TikTok o Instagram per guardarlo nel browser con il filtro attivo.';

  @override
  String get linkWatchNoteDesktop =>
      'Si apre nel browser. Waaiya avvia prima il filtro, così la musica viene rimossa anche lì.';

  @override
  String get linkFilterFailed =>
      'Il filtro non si è avviato, quindi il link non è stato aperto. Avvialo dalla pagina Filtro e riprova.';

  @override
  String get linkSavedVideoDesktop => 'Nella tua cartella Video: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Nella tua cartella Musica: Waaiya';

  @override
  String get linkShowInFolder => 'Mostra nella cartella';

  @override
  String get linkSingingNote =>
      'Anche il canto femminile viene silenziato, come nelle tue impostazioni.';

  @override
  String get singingKeepTitle => 'Mantieni il canto (prova)';

  @override
  String get singingKeepBody =>
      'Gli strumenti vengono rimossi ma le voci che cantano restano, quindi una lezione con un nasheed di sottofondo mantiene anche la voce del nasheed; decidi tu se è accettabile.';

  @override
  String get singingKeepNoModel =>
      'Questa versione non ha un modello per il canto, quindi l\'audio resta muto finché questa opzione è attiva. Disattivala.';

  @override
  String get fixFilterAppsTitle => 'App ascoltate senza filtro';

  @override
  String get fixFilterAppsBody =>
      'Le app che scegli qui suonano così come sono: niente filtro e niente silenzio. Per esempio, un\'app per videochiamate, così le chiamate non hanno ritardo.';

  @override
  String get fixAddApp => 'Aggiungi un\'app';

  @override
  String fixRemoveApp(Object app) {
    return 'Rimuovi $app';
  }

  @override
  String get fixNoApps => 'Nessuna app scelta.';

  @override
  String get fixPickTitle => 'Scegli un\'app';

  @override
  String get fixPickEmpty => 'Nessun\'altra app trovata.';

  @override
  String get fixPickPlayingDesktop =>
      'Le app che ora riproducono audio e quelle già scelte.';

  @override
  String get fixCancel => 'Annulla';

  @override
  String get fixBlurAppsTitle => 'App lasciate scoperte';

  @override
  String get fixBlurAppsBody =>
      'Nessuna copertura mentre una di queste app riempie lo schermo, per esempio un\'app di mappe o l\'app della tua banca. Le coperture tornano appena la lasci, o ogni volta che Waaiya non è sicuro di quale app sia mostrata.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Richiede la configurazione iniziale: senza di essa Waaiya non può sapere quale app è sullo schermo, quindi la sfocatura resta attiva ovunque.';

  @override
  String get fixBlurAppsHelperMode =>
      'L\'assistente di Waaiya non è in funzione, quindi non si può sapere quale app è sullo schermo. La sfocatura resta attiva ovunque finché l\'assistente non viene riavviato dalla pagina Configura.';

  @override
  String get fixHandTitle => 'Copri un\'area a mano';

  @override
  String get fixHandBody =>
      'Mentre la sfocatura è attiva, puoi coprire a mano una parte dello schermo, per esempio un\'immagine che la sfocatura non ha coperto: tocca «Copri un\'area» e trascina il dito sopra. Resta coperta finché non togli la copertura o la sfocatura si ferma.';

  @override
  String get fixHandNotRunning =>
      'Disponibile mentre la sfocatura è attiva: filtro attivo e un\'opzione di sfocatura attiva.';

  @override
  String get fixCoverArea => 'Copri un\'area';

  @override
  String fixRemoveCovers(Object count) {
    return 'Rimuovi le coperture manuali ($count)';
  }

  @override
  String get fixNoteTitle => 'Annota un errore';

  @override
  String get fixNoteBody =>
      'Quando Waaiya sbaglia, tocca quello che è successo, per esempio «È passata la musica». La nota conserva l\'ora, l\'app e le impostazioni, per aiutare a trovare la causa. Resta su questo dispositivo e non viene mai inviata.';

  @override
  String get fixMissedSound => 'È passata la musica';

  @override
  String get fixWrongSound => 'Voce rimossa per errore';

  @override
  String get fixMissedScreen => 'Qualcosa non è stato coperto';

  @override
  String get fixWrongScreen => 'Coperto per errore';

  @override
  String fixNoted(Object count) {
    return 'Annotato ($count note su questo dispositivo).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Note su questo dispositivo: $count';
  }

  @override
  String get fixNotesShow => 'Mostra le note';

  @override
  String get fixNotesDelete => 'Elimina le note';

  @override
  String get fixNotesDeleteAsk =>
      'Eliminare tutte le note? Non si può annullare.';

  @override
  String get fixNotesTitle => 'Note sugli errori';

  @override
  String get worshipTitle => 'Orari di preghiera';

  @override
  String get worshipBody =>
      'Facoltativo. Calcolati su questo telefono in base al luogo che scegli. Non viene inviato nulla.';

  @override
  String worshipPlace(Object place) {
    return 'Luogo: $place';
  }

  @override
  String get worshipPlaceNone => 'Luogo: non scelto';

  @override
  String get worshipChoose => 'Scegli';

  @override
  String get worshipPlaceSearch => 'Cerca una città';

  @override
  String get worshipPlaceNoMatch =>
      'Nessuna città trovata. Puoi inserire invece le coordinate.';

  @override
  String get worshipPlaceCustom => 'Inserisci le coordinate';

  @override
  String get worshipLat => 'Latitudine (nord +, sud −)';

  @override
  String get worshipLon => 'Longitudine (est +, ovest −)';

  @override
  String get worshipZone => 'Fuso orario, per esempio Europe/Rome';

  @override
  String get worshipCustomInvalid => 'Controlla i numeri e il fuso orario.';

  @override
  String get worshipPlaceInvalid =>
      'Questo luogo non può essere usato. Sceglilo di nuovo.';

  @override
  String worshipMethod(Object method) {
    return 'Calcolo: $method';
  }

  @override
  String get worshipMethodTitle => 'Metodo di calcolo';

  @override
  String get worshipMethodNote =>
      'Scelto in base al paese della città. Scegli quello che segue la tua moschea.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Orario dell\'Asr';

  @override
  String get worshipAsrStandard => 'Standard (shafiita, malikita, hanbalita)';

  @override
  String get worshipAsrHanafi => 'Hanafita';

  @override
  String get worshipMethodMwl => 'Lega Musulmana Mondiale';

  @override
  String get worshipMethodIsna => 'Società Islamica del Nord America (ISNA)';

  @override
  String get worshipMethodEgypt => 'Autorità generale egiziana di topografia';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, La Mecca';

  @override
  String get worshipMethodKarachi => 'Università di Scienze Islamiche, Karachi';

  @override
  String get worshipMethodTehran =>
      'Istituto di Geofisica, Università di Teheran';

  @override
  String get worshipMethodGulf => 'Regione del Golfo';

  @override
  String get worshipMethodKuwait => 'Kuwait';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turchia (Diyanet)';

  @override
  String get worshipMethodFrance => 'Francia (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marocco (Ministero degli Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesia (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malesia (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Oggi';

  @override
  String get worshipNoTimes =>
      'Oggi qui non ci sono orari di preghiera: il sole non sorge o non tramonta.';

  @override
  String get worshipSilentTitle => 'Silenzioso agli orari di preghiera';

  @override
  String get worshipSilentBody =>
      'A ogni orario di preghiera il telefono va in silenzioso (Non disturbare) per i minuti indicati sotto, poi torna com\'era. Per esempio, dal Dhuhr alle 12:00 fino alle 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Silenzioso per: $minutes min';
  }

  @override
  String get worshipMuteTitle => 'Silenzia i contenuti multimediali all\'adhan';

  @override
  String get worshipMuteBody =>
      'A ogni orario di preghiera, l\'audio multimediale (video, musica, giochi) viene disattivato per i minuti indicati sotto. Dalla notifica puoi riattivarlo subito.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Disattivato per: $minutes min';
  }

  @override
  String get worshipMinutesTitle => 'Durata';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get worshipNeedPlace => 'Prima scegli un luogo.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Prossima: $prayer alle $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Silenzioso fino alle $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Audio multimediale disattivato fino alle $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Consenti a Waaiya di modificare Non disturbare, altrimenti il telefono non può andare in silenzioso.';

  @override
  String get worshipAllow => 'Consenti';

  @override
  String get worshipExactNeeded =>
      'Sveglie e promemoria non sono consentiti per Waaiya, quindi ogni cambio può arrivare fino a 10 minuti in ritardo, o anche di più mentre il telefono è in standby.';

  @override
  String get worshipNotificationsNeeded =>
      'Le notifiche sono disattivate: non vedrai quando il telefono va in silenzioso o quando il suono torna.';

  @override
  String get worshipTonesTitle => 'Suoneria e suono di notifica semplici';

  @override
  String get worshipTonesBody =>
      'Waaiya non può filtrare la suoneria o i suoni di notifica, solo sostituirli. Scegli un suono semplice, senza musica:';

  @override
  String worshipToneRing(Object number) {
    return 'Suoneria semplice $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Suono di notifica semplice $number';
  }

  @override
  String get worshipTonePlay => 'Riproduci';

  @override
  String get worshipToneSet => 'Usa';

  @override
  String get worshipToneInUse => 'In uso';

  @override
  String get worshipToneDone => 'Fatto.';

  @override
  String get worshipTonePermission =>
      'Consenti a Waaiya di modificare le impostazioni di sistema, torna qui e tocca di nuovo.';

  @override
  String get worshipToneFailed =>
      'Questo telefono non ha permesso a Waaiya di cambiarlo. Nelle impostazioni Suono, scegli un suono chiamato “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Apri le impostazioni Suono';

  @override
  String get worshipSmsTitle =>
      'Rispondi alle chiamate via SMS durante la preghiera';

  @override
  String get worshipSmsBody =>
      'Nei minuti di silenzio dopo ogni orario di preghiera, una chiamata lasciata squillare riceve un SMS. Una volta per numero per ogni preghiera; mai ai numeri nascosti o ai numeri brevi.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Dopo: $seconds s di squilli';
  }

  @override
  String get worshipSmsDelayTitle => 'Secondi di squilli prima dell\'SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Messaggio: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Il tuo messaggio';

  @override
  String get worshipSmsTextDefault => 'Usa quello predefinito';

  @override
  String get worshipSmsCost =>
      'Ogni risposta è un normale SMS dalla tua SIM, al prezzo del tuo piano. In roaming non viene inviato nulla.';

  @override
  String get worshipSmsRoaming =>
      'Ora sei in roaming: non viene inviato nessun SMS.';

  @override
  String get worshipSmsLogTitle =>
      'Risposte inviate (conservate solo su questo telefono)';

  @override
  String get worshipContinue => 'Continua';

  @override
  String get worshipWhyDnd =>
      'Per mettere il telefono in silenzioso agli orari di preghiera, consenti a Waaiya l\'accesso a Non disturbare nella pagina successiva.';

  @override
  String get worshipWhyExact =>
      'Per agire esattamente in orario, consenti a Waaiya di impostare sveglie e promemoria nella pagina successiva. Senza questo permesso, i cambi possono arrivare fino a 10 minuti in ritardo.';

  @override
  String get worshipWhyNotifications =>
      'Consenti le notifiche per vedere ogni cambio e poterlo annullare.';

  @override
  String get worshipWhyWrite =>
      'Per cambiare la suoneria o il suono di notifica, consenti a Waaiya di modificare le impostazioni di sistema nella pagina successiva.';

  @override
  String get worshipWhyPhone =>
      'Per sapere che una chiamata sta squillando e da quale numero, Waaiya ha bisogno delle autorizzazioni Telefono e Registri chiamate. Niente lascia il telefono tranne la tua risposta.';

  @override
  String get worshipWhySms =>
      'Per inviare la tua risposta, Waaiya ha bisogno dell\'autorizzazione a inviare SMS. Invia solo quella risposta, al massimo una volta per numero per ogni preghiera.';

  @override
  String get worshipMissingDnd =>
      'L\'accesso a Non disturbare non è stato consentito, quindi il silenzioso resta disattivato.';

  @override
  String get worshipMissingPhone =>
      'Le autorizzazioni Telefono e Registri chiamate non sono state concesse, quindi la risposta via SMS resta disattivata.';

  @override
  String get worshipMissingSms =>
      'L\'autorizzazione a inviare SMS non è stata concessa, quindi la risposta via SMS resta disattivata.';

  @override
  String get worshipTryAgain => 'Riprova';

  @override
  String get protectTitle => 'Protezione per i momenti di debolezza';

  @override
  String get protectBody =>
      'Per un momento di debolezza in cui potresti voler spegnere il filtro. Scegli ora, con calma, un\'attesa: così il pulsante di arresto non ferma subito il filtro, e decidi di nuovo quando l\'attesa è finita. Un genitore può anche impostare un PIN.';

  @override
  String protectDelay(Object value) {
    return 'Attesa prima di spegnere: $value';
  }

  @override
  String get protectDelayTitle => 'Attesa prima di spegnere';

  @override
  String get protectDelayBody =>
      'Per esempio, con 30 minuti: premi il pulsante per fermare, ma il filtro continua a funzionare. Dopo 30 minuti questa pagina ti chiede se vuoi ancora fermarlo. Premi «Conferma» entro 15 minuti e si ferma; altrimenti non cambia nulla. Lo stesso vale per disattivare una copertura o qualsiasi altra protezione. Attivare qualcosa funziona sempre subito.';

  @override
  String get protectDelayOff => 'Nessuno';

  @override
  String get protectDelay1m => '1 minuto';

  @override
  String get protectDelay5m => '5 minuti';

  @override
  String get protectDelay15m => '15 minuti';

  @override
  String get protectDelay30m => '30 minuti';

  @override
  String get protectDelay1h => '1 ora';

  @override
  String get protectDelay4h => '4 ore';

  @override
  String get protectDelay24h => '24 ore';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes minuti';
  }

  @override
  String get protectPinNone => 'PIN: non impostato';

  @override
  String get protectPinIsSet => 'PIN: impostato';

  @override
  String get protectPinSet => 'Imposta un PIN';

  @override
  String get protectPinRemove => 'Rimuovi';

  @override
  String get protectPinBody =>
      'Con un PIN, per fermare il filtro o spegnere qualsiasi protezione viene chiesto prima il PIN. Per esempio, un genitore ne imposta uno così un bambino non può spegnere il filtro. Anche cambiare il periodo di attesa o il PIN lo richiede.';

  @override
  String get protectPinForgot =>
      'Scrivi il PIN in un posto sicuro: se viene dimenticato, non c\'è modo di reimpostarlo. L\'unica via d\'uscita è cancellare i dati di Waaiya o reinstallarlo, il che cancella anche tutte le sue impostazioni.';

  @override
  String get protectPinTitle => 'Inserisci il PIN';

  @override
  String get protectPinNewTitle => 'Scegli un PIN';

  @override
  String get protectPinChangeTitle => 'Cambia il PIN';

  @override
  String get protectPinCurrent => 'PIN attuale';

  @override
  String get protectPinNew => 'Nuovo PIN (da 4 a 8 cifre)';

  @override
  String get protectPinAgain => 'Ripeti il nuovo PIN';

  @override
  String get protectPinBad => 'Usa da 4 a 8 cifre.';

  @override
  String get protectPinDiffer => 'I due nuovi PIN non sono uguali.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN errato. Restano $count tentativi prima di una pausa.';
  }

  @override
  String protectLocked(Object time) {
    return 'Troppi tentativi errati. Riprova alle $time.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Annulla';

  @override
  String get protectCancelChange => 'Annulla la modifica';

  @override
  String get protectConfirm => 'Conferma';

  @override
  String protectPending(Object time, Object what) {
    return '$what: in attesa fino alle $time. Poi confermalo in «Impostazioni».';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: l\'attesa è finita. Lo vuoi ancora? Premi «Conferma» prima delle $time; altrimenti non cambia nulla.';
  }

  @override
  String get protectWaitTitle => 'Questa modifica deve attendere';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what non avviene ora. Alle $time, se lo vuoi ancora, confermalo in «Impostazioni» entro 15 minuti. Se non fai nulla, non cambia nulla.';
  }

  @override
  String get protectWaitStart => 'Inizia l\'attesa';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Già in attesa fino alle $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'In attesa fino alle $time. Poi confermalo in «Impostazioni».';
  }

  @override
  String protectTomorrow(Object time) {
    return '$time di domani';
  }

  @override
  String get protectHeldBack =>
      'Non ora: le tue impostazioni di protezione fanno attendere questa modifica, o chiedono il PIN.';

  @override
  String get protectLimits =>
      'Cosa questo non può impedire: l\'arresto forzato, la disinstallazione, la cancellazione dei dati di Waaiya e le impostazioni di Android stesse. Per bloccarli servirebbero autorizzazioni speciali di Android che Waaiya non usa. Protegge da un momento di debolezza, non da una persona determinata.';

  @override
  String get protectLimitsDesktop =>
      'Cosa questo non può impedire: il comando waaiya in un terminale, la rimozione di Waaiya o l\'eliminazione della sua cartella delle impostazioni. Protegge da un momento di debolezza, non da una persona determinata.';

  @override
  String get protectLimitsWindows =>
      'Cosa questo non può impedire: il comando waaiya-filter.exe in un terminale, la rimozione di Waaiya o l\'eliminazione della sua cartella delle impostazioni. Protegge da un momento di debolezza, non da una persona determinata.';

  @override
  String get protectWhatStop => 'Interrompere il filtro';

  @override
  String protectWhatOff(Object name) {
    return 'Disattivare: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Attivare: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Aggiungere un\'app a: $name';
  }

  @override
  String get protectWhatStrictness => 'Rendere la sfocatura meno rigorosa';

  @override
  String get protectWhatGender => 'Cambiare chi usa Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'Cambia l\'attesa prima di spegnere in: $value';
  }

  @override
  String get protectWhatPinChange => 'Cambiare il PIN';

  @override
  String get protectWhatPinClear => 'Rimuovere il PIN';

  @override
  String get protectWhatSetting => 'Cambiare un\'impostazione';

  @override
  String get onboardBodyDesktop =>
      'Waaiya rimuove gli strumenti musicali dal suono di tutte le app di questo computer. La voce parlata e la recitazione del Corano vengono mantenute. Per ora vengono rimosse anche le voci che cantano.';

  @override
  String get worshipUseLocation => 'Usa la mia posizione';

  @override
  String get worshipWhyLocation =>
      'Per trovare gli orari di preghiera dove ti trovi, Waaiya legge una sola volta, ora, la posizione approssimativa di questo telefono. Resta sul telefono come tuo luogo e non viene inviata da nessuna parte.';

  @override
  String get worshipLocating => 'Ricerca della tua posizione…';

  @override
  String get worshipLocationDenied =>
      'La posizione non è stata consentita. Puoi cercare la tua città.';

  @override
  String get worshipLocationOff =>
      'La localizzazione è disattivata su questo telefono. Attivala e riprova, oppure cerca la tua città.';

  @override
  String get worshipLocationSettings => 'Impostazioni di localizzazione';

  @override
  String get worshipLocationFailed =>
      'Impossibile trovare la tua posizione. Riprova tra un momento, oppure cerca la tua città.';

  @override
  String worshipPlaceNear(Object city) {
    return 'vicino a $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Gli orari ufficiali del Ministero degli Habous e degli Affari islamici per $city.';
  }

  @override
  String get trayOpen => 'Apri Waaiya';

  @override
  String get trayQuit => 'Esci';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows non consente a Waaiya di avviarsi all\'accesso. Attiva Waaiya in Impostazioni › App › Avvio, poi riattiva questa opzione.';

  @override
  String get engineErrorAutostartPolicy =>
      'Le impostazioni di questo computer, scelte dal suo amministratore, non consentono a Waaiya di avviarsi all\'accesso.';
}
