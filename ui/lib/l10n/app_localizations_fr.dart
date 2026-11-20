// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Supprime les instruments de musique de toutes les applications et garde la parole et la récitation.';

  @override
  String get onboardTitle => 'Bienvenue';

  @override
  String get onboardBody =>
      'Waaiya supprime les instruments de musique du son de toutes les applications de ce téléphone. La parole et la récitation du Coran sont conservées. Pour l\'instant, les voix chantées sont aussi supprimées.';

  @override
  String get onboardQuestion => 'Je suis';

  @override
  String get genderMan => 'Un homme';

  @override
  String get genderWoman => 'Une femme';

  @override
  String get onboardWhy =>
      'Cela décide seulement des réglages facultatifs que vous voyez. Vous pourrez le changer plus tard.';

  @override
  String get stateOnTitle => 'Le filtrage est activé';

  @override
  String get stateOffTitle => 'Le filtrage est désactivé';

  @override
  String get stateStarting => 'Démarrage…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Les instruments sont supprimés de toutes les applications. Délai d\'environ $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Appuyez sur le bouton pour démarrer.';

  @override
  String get stateModelFailed =>
      'Le modèle audio n\'a pas pu se charger : le son est donc coupé par sécurité.';

  @override
  String get stateCaptureDenied =>
      'L\'autorisation du micro est nécessaire pour recevoir le son des autres applications.';

  @override
  String get stateStoppedBySystem =>
      'Android a arrêté le filtrage. Appuyez sur le bouton pour le relancer.';

  @override
  String get stateSilencedTitle => 'Filtrage arrêté';

  @override
  String get stateSilenced =>
      'Filtrage arrêté : les autres applications sont rendues muettes. Appuyez sur le bouton pour relancer, ou sur Arrêter pour les entendre sans filtre.';

  @override
  String get releaseSilence => 'Arrêter : entendre les applis sans filtre';

  @override
  String get powerStartCd => 'Démarrer le filtrage';

  @override
  String get powerStopCd => 'Arrêter le filtrage';

  @override
  String get captureHint =>
      'Android va demander de partager votre écran. Seul le son est utilisé : rien n\'est enregistré ni envoyé.';

  @override
  String get needRecordAudio =>
      'Waaiya a besoin de l\'autorisation du micro pour recevoir le son des autres applications. Il ne vous enregistre jamais.';

  @override
  String get setupBannerTitle => 'Encore une étape';

  @override
  String get setupBannerBody =>
      'Sans la configuration initiale ci-dessous, vous entendrez la musique et le son filtré en même temps.';

  @override
  String get step1Title => 'Installez Shizuku';

  @override
  String get step1Body => 'Une appli d\'aide gratuite, sur le Play Store.';

  @override
  String get step1Action => 'Obtenir Shizuku';

  @override
  String get step2Title => 'Démarrez Shizuku';

  @override
  String get step2Body =>
      'Shizuku démarre via le Wi-Fi avec le débogage sans fil d\'Android. Appuyez sur le bouton pour voir les étapes, puis revenez ici.';

  @override
  String get step2Action => 'Ouvrir Shizuku';

  @override
  String get step2Update => 'Mettre à jour Shizuku';

  @override
  String get step2TooOld =>
      'Votre version de Shizuku est trop ancienne. Mettez-la à jour depuis le Play Store.';

  @override
  String get step2Denied =>
      'Shizuku est réglé pour toujours refuser Waaiya. Dans Shizuku, autorisez-le dans la liste des applications.';

  @override
  String get step3Title => 'Donnez l\'autorisation';

  @override
  String get step3Body => 'Un appui, puis choisissez « Autoriser ».';

  @override
  String get step3Action => 'Donner l\'autorisation';

  @override
  String get step3Busy => 'Configuration…';

  @override
  String get setupDoneRestart =>
      'C\'est fait. Arrêtez puis relancez le filtrage une fois pour l\'appliquer.';

  @override
  String setupFailed(String details) {
    return 'La configuration n\'a pas abouti. Détails :\n$details';
  }

  @override
  String get shizukuRefused =>
      'L\'autorisation Shizuku a été refusée. Appuyez sur le bouton pour réessayer.';

  @override
  String get setupSlow =>
      'Shizuku prend plus de temps que d\'habitude. Patientez : sur certains téléphones, son assistant met jusqu\'à une minute à démarrer la première fois.';

  @override
  String get setupTimeout =>
      'Shizuku n\'a pas répondu en 2 minutes. Ouvrez Shizuku, vérifiez qu\'il indique être en cours d\'exécution, puis appuyez de nouveau sur le bouton. Si la configuration se termine plus tard, cet écran se met à jour tout seul.';

  @override
  String get setupRefusedXiaomi =>
      'Ce téléphone a refusé les autorisations. Sur Xiaomi, Redmi et POCO, activez « USB debugging (Security settings) » (Débogage USB – paramètres de sécurité) dans les Options pour les développeurs (il faut se connecter à un compte Xiaomi), puis réessayez.';

  @override
  String get setupRefusedColoros =>
      'Ce téléphone a refusé les autorisations. Sur OPPO, OnePlus et realme, dans les Options pour les développeurs, activez « Disable permission monitoring » (Désactiver la surveillance des autorisations). Sur les versions les plus récentes, il s\'appelle « Disable system optimization » (Désactiver l\'optimisation du système) et peut n\'apparaître que si le téléphone est en anglais. Pour le trouver, recherchez « permission » dans les Paramètres. Puis réessayez.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi et POCO : si la notification n\'a pas de champ pour taper le code, choisissez le style de notification « Android » dans les paramètres des notifications, ou tapez le code dans Waaiya en écran partagé.';

  @override
  String get stepDoneCd => 'Terminé';

  @override
  String stepTodoCd(int step) {
    return 'Étape $step';
  }

  @override
  String get computerToggle => 'Utiliser plutôt un ordinateur';

  @override
  String get computerBody =>
      'Activez le débogage USB, branchez le téléphone et lancez :';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get computerNote =>
      'La deuxième ligne est facultative : elle supprime la question du partage d\'écran à chaque démarrage.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingSilenceTitle =>
      'Rendre muettes les applis qui bloquent le filtrage';

  @override
  String get settingSilenceBody =>
      'Recommandé. Certaines applications ne laissent pas filtrer leur son ; cette option les rend muettes au lieu de laisser passer la musique.';

  @override
  String get settingHoldSilenceTitle =>
      'Garder les applis muettes si le filtrage s\'arrête tout seul';

  @override
  String get settingHoldSilenceBody =>
      'Recommandé. Si Android met fin au filtrage (pas vous), les autres applications restent muettes jusqu\'à ce que vous relanciez ou appuyiez sur Arrêter, au lieu de jouer la musique sans filtre. Nécessite la configuration initiale.';

  @override
  String get settingStereoTitle => 'Son stéréo';

  @override
  String get settingStereoBody =>
      'Désactivé : mono, qui consomme environ deux fois moins de batterie et suit le rythme sur plus de téléphones. Activé : garde la gauche et la droite séparées. Si le téléphone est trop lent pour la stéréo, il repasse quand même en mono tout seul.';

  @override
  String get settingSingingTitle => 'Couper le chant des femmes';

  @override
  String get settingSingingBody => 'La parole des femmes est conservée.';

  @override
  String get settingSingingNoModel =>
      'Cette version n\'a pas de détecteur de chant : toutes les voix sont donc coupées tant que cette option est activée.';

  @override
  String get settingRestart =>
      'Arrêtez puis relancez le filtrage pour appliquer les changements.';

  @override
  String get settingGenderTitle => 'Je suis';

  @override
  String get change => 'Modifier';

  @override
  String get playerTitle => 'Vidéos parfaitement synchronisées';

  @override
  String get playerBody =>
      'Partagez une vidéo avec Waaiya (ou utilisez « Ouvrir avec ») pour la regarder filtrée, sans aucun décalage.';

  @override
  String get licences => 'Licences open source';

  @override
  String get licencesIntro =>
      'Waaiya est un logiciel libre sous licence GNU Affero General Public License v3 ou ultérieure. Code source : https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (données d\'entraînement) : https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Textes complets';

  @override
  String get back => 'Retour';

  @override
  String get linkEntryTitle => 'Ouvrir un lien';

  @override
  String get linkEntryBody =>
      'Collez un lien YouTube, TikTok ou Instagram pour le regarder ou l\'enregistrer sans musique.';

  @override
  String get linkTitle => 'Ouvrir un lien';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Lien vidéo ou audio';

  @override
  String get linkPaste => 'Coller';

  @override
  String get linkOpen => 'Ouvrir';

  @override
  String get linkResolving => 'Ouverture du lien…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Regarder sans musique';

  @override
  String get linkSave => 'Enregistrer sans musique';

  @override
  String get linkListen => 'Écouter sans musique';

  @override
  String get linkAudioOnly =>
      'La vidéo de ce lien ne peut pas encore être ouverte, seulement le son.';

  @override
  String get linkDownloading => 'Téléchargement…';

  @override
  String get linkFiltering => 'Suppression de la musique…';

  @override
  String get linkCancel => 'Annuler';

  @override
  String get linkCancelled => 'Annulé. Rien n\'a été enregistré.';

  @override
  String get linkTimedOut =>
      'Android a arrêté l\'enregistrement : il n\'autorise ce type de travail que quelques heures par jour. Rien n\'a été enregistré ; ouvrez Waaiya et réessayez.';

  @override
  String get linkExportFailed =>
      'Impossible d\'enregistrer celle-ci. Rien n\'a été enregistré.';

  @override
  String get linkSaved => 'Enregistré sans musique';

  @override
  String get linkSavedVideo => 'Dans votre galerie : Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Dans votre musique : Music › Waaiya';

  @override
  String get linkPlay => 'Lire';

  @override
  String get linkShare => 'Partager';

  @override
  String get linkShareNote =>
      'Ne partagez que les vidéos que vous avez le droit de partager.';

  @override
  String get linkLive =>
      'Les diffusions en direct ne peuvent pas être enregistrées.';

  @override
  String get linkBusy =>
      'Une autre vidéo est en cours d\'enregistrement. Veuillez attendre qu\'elle se termine.';

  @override
  String get linkInvalid =>
      'Veuillez coller un lien web (commençant par https://).';

  @override
  String get linkLogin =>
      'Le site n\'a pas voulu afficher cette vidéo sans compte. Les publications publiques s\'ouvrent en général : réessayez dans quelques minutes. Les publications privées ne peuvent pas être ouvertes.';

  @override
  String get linkUnsupported => 'Ce site n\'est pas pris en charge.';

  @override
  String get linkPlaylist =>
      'Ceci est une playlist. Veuillez ouvrir une seule vidéo.';

  @override
  String get linkNoFormat =>
      'Cette vidéo n\'est pas encore dans un format que Waaiya peut filtrer.';

  @override
  String get linkFailed =>
      'Impossible d\'ouvrir ce lien. Vérifiez votre connexion et réessayez.';

  @override
  String get linkPlayFailed =>
      'Impossible de lire ceci. Rien n\'a été lu sans filtre.';

  @override
  String get linkLimited =>
      'Le site limite les requêtes en ce moment. Réessayez dans quelques minutes.';

  @override
  String get blurTitle => 'Floutage de l\'écran';

  @override
  String get blurBody =>
      'Couvre les personnes et les images à l\'écran, dans toutes les applications, tant que le filtrage est activé. Tout se fait sur le téléphone ; rien n\'est envoyé nulle part.';

  @override
  String get blurWomenTitle => 'Flouter les femmes';

  @override
  String get blurWomenBody =>
      'Le corps entier. Les personnes dont l\'appli ne voit pas clairement que ce sont des hommes sont floutées aussi.';

  @override
  String get blurNudityTitle => 'Flouter les images indécentes';

  @override
  String get blurNudityBody =>
      'Nudité et tenues révélatrices, de qui que ce soit : tout l\'écran est couvert.';

  @override
  String get blurFailTitle => 'Couvrir l\'écran si le flou ne suit pas';

  @override
  String get blurFailBody =>
      'Activé : tout l\'écran est couvert quand le téléphone est trop lent ou que le flou échoue. Désactivé : l\'écran reste visible avec un avertissement.';

  @override
  String get blurSetupShizuku => 'Autoriser avec Shizuku';

  @override
  String get blurSetupManual => 'Autoriser dans les paramètres Android';

  @override
  String get blurStatusNeedsSetup =>
      'Le flou doit s\'afficher par-dessus les autres applications. Le mieux : l\'autoriser avec Shizuku (cela active le service d\'accessibilité Flou Waaiya, pour que les appuis atteignent toujours l\'appli en dessous). Sinon, autorisez « Superposition sur d\'autres applis » dans les paramètres Android (les appuis sur une zone floutée sont alors perdus).';

  @override
  String get blurStatusNeedsOverlay =>
      'Le flou doit s\'afficher par-dessus les autres applications. Le mieux : démarrez Shizuku (et autorisez-y Waaiya) : le flou dessine alors son propre calque, que les appuis traversent. Sinon, autorisez « Superposition sur d\'autres applis » dans les paramètres Android ; un appui sur une zone floutée n\'atteint alors pas l\'appli en dessous.';

  @override
  String get blurFailUnavailable =>
      'Grisé pour l\'instant : un cache plein écran bloquerait tous les appuis et vous pourriez rester coincé. Démarrez l\'assistant de Waaiya ou Shizuku (Android 12 ou plus récent) et l\'option s\'active : les caches sont alors dessinés pour que les appuis les traversent. D\'ici là, quand le flou ne suit pas, l\'écran reste visible avec un avertissement.';

  @override
  String get blurFailNeedsA11y =>
      'Grisé pour l\'instant : un cache plein écran bloquerait tous les appuis et vous pourriez rester coincé. Démarrez Shizuku (Android 12 ou plus récent) ou activez le service d\'accessibilité Flou Waaiya (Autoriser avec Shizuku, ci-dessus) et l\'option s\'active. D\'ici là, l\'écran reste visible avec un avertissement.';

  @override
  String get languageTitle => 'Langue';

  @override
  String settingLanguageTitle(String language) {
    return 'Langue : $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Arrêtez puis relancez le filtrage pour appliquer les réglages du flou.';

  @override
  String get blurStatusStarting => 'Démarrage du flou…';

  @override
  String get blurStatusOn => 'Flou activé.';

  @override
  String get blurStatusOnVisible =>
      'Flou activé, en mode prudent : ce téléphone montre le flou dans sa propre capture d\'écran, donc une zone floutée reste floutée jusqu\'à ce que la scène change.';

  @override
  String get blurStatusModels =>
      'Il manque à cette version un modèle de flou pour l\'option choisie.';

  @override
  String get blurStatusFailing =>
      'Le flou n\'arrive pas à suivre pour le moment.';

  @override
  String get blurStatusNoOverlay =>
      'Le flou ne peut pas s\'afficher par-dessus les autres applications : autorisez-le ci-dessus.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Le flou ne peut pas voir l\'écran. Détails :\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku n\'a pas pu l\'autoriser :\n$details';
  }

  @override
  String get step2Guide => 'Comment démarrer Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Grisé : sur cette version d\'Android, un cache plein écran bloquerait tous les appuis et vous pourriez rester coincé (les caches de Shizuku nécessitent Android 12 ou plus récent). Quand le flou ne suit pas, l\'écran reste visible avec un avertissement.';

  @override
  String get guideTitle => 'Démarrer Shizuku, étape par étape';

  @override
  String get guideOpenDev => 'Options pour les développeurs';

  @override
  String get guideOpenShizuku => 'Ouvrir Shizuku';

  @override
  String get guideClose => 'Fermer';

  @override
  String get guideBody =>
      'Il vous faut le Wi-Fi et Android 11 ou plus récent. L\'association se fait une seule fois ; après un redémarrage du téléphone, vous ne refaites que l\'étape 7.\n\n1. Connectez le téléphone au Wi-Fi.\n\n2. Activez les Options pour les développeurs : Paramètres › À propos du téléphone › « Software information » (Informations sur le logiciel) › appuyez 7 fois sur « Numéro de build ». (Sur les autres téléphones : Paramètres › À propos du téléphone › Numéro de build.)\n\n3. Ouvrez Shizuku. S\'il demande à afficher des notifications, autorisez-le : le code d\'association se tape dans une notification de Shizuku.\n\n4. Dans Shizuku, sous « Start via Wireless debugging » (Démarrer via le débogage sans fil), appuyez sur « Pairing » (Association). Sur la page qui s\'ouvre, appuyez sur « Developer options » (Options pour les développeurs), activez « Débogage sans fil » et confirmez avec « Autoriser ».\n\n5. Appuyez sur les mots « Débogage sans fil » (pas sur l\'interrupteur), puis sur « Associer l\'appareil avec un code d\'association ». Un code à 6 chiffres apparaît.\n\n6. Gardez cet écran ouvert et déroulez les notifications. Quand la notification de Shizuku indique « Pairing service found » (Service d\'association trouvé), appuyez sur « Enter pairing code » (Saisir le code d\'association) et tapez le code. Shizuku indique que l\'association a réussi.\n\n7. Revenez dans Shizuku et appuyez sur « Start » (Démarrer) sous « Start via Wireless debugging ». Attendez qu\'il indique « Shizuku is running » (Shizuku est en cours d\'exécution).\n\n8. Revenez dans Waaiya et appuyez sur « Donner l\'autorisation », puis sur « Autoriser ».\n\nAprès un redémarrage du téléphone, Shizuku s\'arrête : connectez-vous au Wi-Fi, réactivez « Débogage sans fil » s\'il est désactivé, ouvrez Shizuku et appuyez sur « Start ». Pas de nouvelle association.';

  @override
  String get wsetupRouteTitle => 'Configurer sur ce téléphone';

  @override
  String get wsetupRouteBody =>
      'Quatre étapes courtes, à faire une seule fois. Sans appli supplémentaire ni ordinateur. Waaiya coche chaque étape une fois terminée.';

  @override
  String get wizDevTitle => 'Activez les Options pour les développeurs';

  @override
  String get wizDevBody =>
      'Dans « À propos du téléphone », appuyez 7 fois sur « Numéro de build », puis revenez ici. Si vous ne le trouvez pas, recherchez « Numéro de build » dans les Paramètres.';

  @override
  String get wizDevBodySamsung =>
      'Dans « À propos du téléphone » › « Software information » (Informations sur le logiciel), appuyez 7 fois sur « Numéro de build », puis revenez ici.';

  @override
  String get wizDevBodyXiaomi =>
      'Dans « À propos du téléphone », appuyez 7 fois sur « OS version » (Version de l\'OS) ; sur les téléphones plus anciens, « MIUI version » (Version de MIUI) ; sur certains, c\'est dans « Detailed info and specs » (Infos et caractéristiques détaillées). Puis revenez ici.';

  @override
  String get wizDevBodyColoros =>
      'Dans « About device » (À propos de l\'appareil) ou « À propos du téléphone » › « Version », appuyez 7 fois sur « Numéro de build », puis revenez ici.';

  @override
  String get wizDevBodyVivo =>
      'Dans « À propos du téléphone », appuyez 7 fois sur « Software version » (Version du logiciel) ; sur certains téléphones : « Software information » (Informations sur le logiciel) › « Numéro de build ». Puis revenez ici.';

  @override
  String get wizDevBodyHuawei =>
      'Dans « À propos du téléphone », appuyez 7 fois sur « Numéro de build », puis revenez ici.';

  @override
  String get wizDevBodyTranssion =>
      'Dans « My phone » (Mon téléphone) ou « À propos du téléphone », appuyez 7 fois sur « Numéro de build », puis revenez ici.';

  @override
  String get setupNoteHuawei =>
      'Huawei : beaucoup de téléphones Huawei n\'ont pas de « Débogage sans fil ». Si vous ne le trouvez pas dans les Options pour les développeurs, utilisez un ordinateur (« Autres méthodes » ci-dessous).';

  @override
  String get wsetupFilterOn =>
      'Le filtrage est activé : sur cette version d\'Android, le code ne peut pas être tapé dans une notification pendant qu\'il fonctionne. Arrêtez d\'abord le filtrage, ou utilisez l\'écran partagé et « Taper le code ici ».';

  @override
  String get wizDevSearch =>
      'Les noms peuvent varier selon la langue du téléphone : si vous ne le trouvez pas, utilisez la recherche en haut des Paramètres.';

  @override
  String get wizDevAction => 'Ouvrir À propos du téléphone';

  @override
  String get wizWifiTitle => 'Connectez-vous au Wi-Fi';

  @override
  String get wizWifiBody =>
      'N\'importe quel réseau Wi-Fi convient ; Internet n\'est pas nécessaire.';

  @override
  String get wizWifiAction => 'Ouvrir les paramètres Wi-Fi';

  @override
  String get wizWdTitle => 'Activez le débogage sans fil';

  @override
  String get wizWdBody =>
      'Waaiya ouvre les Options pour les développeurs sur « Débogage sans fil ». Activez-le et appuyez sur « Autoriser ».';

  @override
  String get wizWdAction => 'Ouvrir les Options pour les développeurs';

  @override
  String get wizPairTitle => 'Tapez le code d\'association';

  @override
  String get wizPairBody =>
      'Appuyez sur les mots « Débogage sans fil », puis sur « Associer l\'appareil avec un code d\'association ». Tapez les 6 chiffres dans la notification de Waaiya. Waaiya fait le reste.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya est déjà associé à ce téléphone : aucun code n\'est nécessaire. Appuyez sur le bouton et Waaiya termine tout seul.';

  @override
  String get wizPairAction => 'Continuer';

  @override
  String get wizAgain => 'Refaire la configuration';

  @override
  String get setupShizukuReadyTitle => 'Avec Shizuku, déjà démarré';

  @override
  String get setupOtherWaysPlain => 'Autres méthodes de configuration';

  @override
  String get wizSkip => 'Passer au débogage sans fil';

  @override
  String get setupOtherWays => 'Autres méthodes : Shizuku ou un ordinateur';

  @override
  String get wsetupEnterHere => 'Taper le code ici';

  @override
  String get wsetupCancel => 'Annuler';

  @override
  String get wsetupAndroid10 =>
      'Android 10 ne peut pas faire la configuration seul : il faut un ordinateur, directement (ci-dessous) ou pour démarrer Shizuku une fois.';

  @override
  String get wsetupShizukuHeading => 'Ou avec l\'appli Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku permet aussi aux appuis de traverser les caches de l\'écran.';

  @override
  String get wsetupChannel => 'Configuration initiale';

  @override
  String get wsetupNotifTitle =>
      'Configuration de Waaiya : en attente du code d\'association';

  @override
  String get wsetupFoundTitle => 'Écran d\'association trouvé';

  @override
  String get wsetupBusyTitle => 'Configuration de Waaiya';

  @override
  String get wsetupDoneTitle => 'Configuration terminée';

  @override
  String get wsetupDoneBody =>
      'Waaiya peut maintenant couper le son d\'origine. Vous pouvez désactiver le débogage sans fil.';

  @override
  String get wsetupDoneHelperBody =>
      'C\'est fait. Ce téléphone ne laisse pas les applications garder ces autorisations : c\'est donc l\'assistant de Waaiya qui coupe le son d\'origine. L\'assistant s\'arrête quand le téléphone redémarre et quand Waaiya est mis à jour. Quand vous ouvrez Waaiya ensuite, il relance l\'assistant tout seul si le débogage sans fil est activé ; sinon, il affiche un bouton pour le faire.';

  @override
  String get helperMissingTitle => 'L\'assistant de Waaiya est arrêté';

  @override
  String get helperMissingBody =>
      'Ce téléphone ne garde pas les autorisations de Waaiya, donc Waaiya utilise son assistant. L\'assistant s\'arrête quand le téléphone redémarre et quand Waaiya est mis à jour. Connectez-vous au Wi-Fi, activez « Débogage sans fil » dans les Options pour les développeurs, puis appuyez sur « Démarrer l\'assistant de Waaiya ».';

  @override
  String get helperChannel => 'Assistant de Waaiya';

  @override
  String get helperStarting => 'Démarrage de l\'assistant…';

  @override
  String get helperModeNote =>
      'Ce téléphone ne laisse pas les applications garder ces autorisations : l\'assistant de Waaiya fait le travail. Il s\'arrête quand le téléphone redémarre et quand Waaiya est mis à jour. Quand vous ouvrez Waaiya ensuite, il relance l\'assistant tout seul si le débogage sans fil est activé ; sinon, il affiche un bouton pour le faire.';

  @override
  String get helperTipXiaomi =>
      'Facultatif, pour garder les autorisations pour de bon (plus d\'assistant après les redémarrages) : dans les Options pour les développeurs, activez « USB debugging (Security settings) » (Débogage USB – paramètres de sécurité) (il faut se connecter à un compte Xiaomi), puis refaites la configuration.';

  @override
  String get helperTipColoros =>
      'Facultatif, pour garder les autorisations pour de bon (plus d\'assistant après les redémarrages) : dans les Options pour les développeurs, activez « Disable permission monitoring » (Désactiver la surveillance des autorisations) ; sur les versions les plus récentes, « Disable system optimization » (Désactiver l\'optimisation du système), qui peut n\'apparaître que si le téléphone est en anglais. Puis refaites la configuration.';

  @override
  String get stateOnHelperMissing =>
      'Le son d\'origine n\'est pas coupé, donc vous entendez la musique avec le son filtré : l\'assistant de Waaiya est arrêté. Connectez-vous au Wi-Fi, activez le débogage sans fil, puis appuyez sur « Démarrer l\'assistant de Waaiya ».';

  @override
  String get setupRefusedTryWireless =>
      'Ou utilisez « Configurer sur ce téléphone » sur cette page : l\'assistant de Waaiya fonctionne alors sans cette option.';

  @override
  String get helperStartAnywayTitle => 'L\'assistant de Waaiya est arrêté';

  @override
  String get helperStartAnywayBody =>
      'Sans lui, vous entendrez la musique avec le son filtré. Démarrez d\'abord l\'assistant (le débogage sans fil doit être activé), ou démarrez quand même le filtrage.';

  @override
  String get wsetupFailedTitle => 'La configuration n\'a pas abouti';

  @override
  String get wsetupPairing => 'Association…';

  @override
  String get wsetupConnecting => 'Connexion et attribution des autorisations…';

  @override
  String get wsetupNeedWifi =>
      'Connectez-vous d\'abord à un réseau Wi-Fi (Internet n\'est pas nécessaire) : le débogage sans fil ne fonctionne qu\'en Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'Dans les Options pour les développeurs, activez « Débogage sans fil », puis appuyez sur son nom et sur « Associer l\'appareil avec un code d\'association ».';

  @override
  String get wsetupOpenDialog =>
      'Dans Débogage sans fil, appuyez sur « Associer l\'appareil avec un code d\'association ». Gardez le code à l\'écran et appuyez ici sur « Saisir le code ».';

  @override
  String get wsetupEnterCodeBody =>
      'Appuyez sur « Saisir le code » et tapez le code à 6 chiffres affiché dans les Paramètres.';

  @override
  String get wsetupCodeWaiting =>
      'Code reçu. En attente de l\'écran « Associer l\'appareil avec un code d\'association » : gardez-le ouvert.';

  @override
  String get wsetupWrongCode =>
      'Ce code n\'a pas été accepté. Vérifiez les 6 chiffres à l\'écran et saisissez-les de nouveau. Si l\'écran d\'association s\'est fermé, rouvrez-le : le code change.';

  @override
  String get wsetupPairingFailed =>
      'L\'association n\'a pas fonctionné. Fermez l\'écran d\'association, rouvrez « Associer l\'appareil avec un code d\'association » et saisissez le nouveau code.';

  @override
  String get wsetupWaitingConnect =>
      'Associé. Laissez « Débogage sans fil » activé : Waaiya se connecte.';

  @override
  String get wsetupNotPaired =>
      'Ce téléphone ne connaît plus Waaiya (l\'association a été supprimée ou a expiré). Ouvrez « Associer l\'appareil avec un code d\'association » et saisissez le code.';

  @override
  String get wsetupConnectFailed =>
      'Impossible de se connecter au débogage sans fil. Désactivez-le puis réactivez-le : Waaiya réessaie tout seul.';

  @override
  String get wsetupGrantFailed =>
      'Connecté, mais les autorisations manquent toujours. Utilisez Shizuku ou un ordinateur ci-dessous.';

  @override
  String get wsetupTimeout =>
      'Arrêté après 10 minutes sans avoir terminé. Vous pouvez réessayer.';

  @override
  String get wsetupCodeUnreadable =>
      'Tapez les 6 chiffres du code d\'association.';

  @override
  String get wsetupCodeHint => 'Code à 6 chiffres';

  @override
  String get wsetupEnterCode => 'Saisir le code';

  @override
  String wsetupDetail(String details) {
    return 'Détails : $details';
  }

  @override
  String get wsetupErrTimeout => 'pas de réponse à temps';

  @override
  String get wsetupErrRefused => 'connexion refusée';

  @override
  String get wsetupDevOff =>
      'Les Options pour les développeurs sont désactivées. Dans « À propos du téléphone », appuyez 7 fois sur « Numéro de build », puis revenez.';

  @override
  String get wsetupOpenAbout => 'À propos du téléphone';

  @override
  String get wsetupNotifOff =>
      'Les notifications sont désactivées pour Waaiya : le code ne peut donc pas être tapé dans une notification. Utilisez l\'écran partagé (Paramètres d\'un côté, Waaiya de l\'autre) et appuyez sur « Taper le code ici ».';

  @override
  String get wsetupCodeDialogTitle => 'Code d\'association';

  @override
  String get wsetupCodeDialogBody =>
      'Uniquement en écran partagé (Paramètres d\'un côté, Waaiya de l\'autre) : quitter les Paramètres ferme l\'écran d\'association et son code ne marche plus. Tapez le code à 6 chiffres affiché sous « Associer l\'appareil avec un code d\'association ».';

  @override
  String get wsetupCodeOk => 'Associer';

  @override
  String get blurStrictTitle => 'Qui reste découvert';

  @override
  String blurStrictValue(String level) {
    return 'Qui reste découvert : $level';
  }

  @override
  String get blurStrict0 =>
      'Strict : seulement ceux que l\'appli juge presque sûrement des hommes';

  @override
  String get blurStrict1 =>
      'Équilibré : environ deux fois plus d\'hommes découverts';

  @override
  String get blurStrict2 => 'Souple : un peu plus d\'hommes qu\'en équilibré';

  @override
  String get blurStrict0Short => 'strict';

  @override
  String get blurStrict1Short => 'équilibré';

  @override
  String get blurStrict2Short => 'souple';

  @override
  String get blurStrictHelp =>
      'Toute personne dont l\'appli n\'est pas sûre que c\'est un homme est couverte. Strict laisse environ 7 hommes sur 100 découverts ; équilibré environ 14, souple environ 16. Chaque cran moins strict laisse aussi environ 1 femme de plus sur 100 découverte.';

  @override
  String get stateOnNotMuted =>
      'Le son d\'origine n\'est pas encore coupé, donc vous entendez la musique avec le son filtré. Terminez la configuration initiale ci-dessous.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya ne peut pas couper le son d\'origine de l\'appli en cours de lecture, donc la musique peut encore s\'entendre. Arrêtez puis relancez le filtrage. Si cela continue, envoyez le rapport de diagnostic (en bas de cet écran).';

  @override
  String get stateTooSlow =>
      'Ce téléphone est trop lent pour filtrer le son en direct, donc le son se coupe. « Ouvrir un lien » ci-dessous fonctionne quand même : il filtre la vidéo avant de la lire.';

  @override
  String get stateMonoNote => 'Le son est en mono pour que ce téléphone suive.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Rendu muet, car il n\'autorise pas le filtrage : $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Lu sans filtre, car il n\'autorise pas le filtrage : $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android n\'a pas donné à Waaiya le son des autres applications. Appuyez sur le bouton pour relancer.';

  @override
  String get stateCaptureCancelled =>
      'Le démarrage a été annulé à la question de partage d\'écran d\'Android. Waaiya a besoin que vous choisissiez « Démarrer » à cet endroit pour recevoir le son. Rien n\'est enregistré ni envoyé.';

  @override
  String get startNoSetupTitle => 'La musique s\'entendra encore';

  @override
  String get startNoSetupBody =>
      'La configuration initiale n\'est pas encore faite. Sans elle, Waaiya ne peut pas couper le son d\'origine : vous entendrez la musique et le son filtré en même temps.\n\n« Ouvrir un lien » fonctionne sans aucune configuration.';

  @override
  String get startNoSetupSetup => 'Faire la configuration';

  @override
  String get startNoSetupAnyway => 'Démarrer quand même';

  @override
  String get diagButton => 'Un problème ? Rapport de diagnostic';

  @override
  String get diagTitle => 'Rapport de diagnostic';

  @override
  String get diagNote =>
      'Ce que Waaiya voit sur ce téléphone. Copiez-le ou partagez-le avec la personne qui vous aide. L\'appli elle-même n\'envoie rien.';

  @override
  String get notifStoppedTitle => 'Waaiya s\'est arrêté';

  @override
  String get notifStoppedText =>
      'Le son n\'est plus filtré. Appuyez pour relancer.';

  @override
  String get wsetupGuide => 'Étapes en images';

  @override
  String get navFilter => 'Filtre';

  @override
  String get navScreen => 'Écran';

  @override
  String get navLinks => 'Liens';

  @override
  String get navSetup => 'Configurer';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get setupDoneTitle => 'Configuration terminée';

  @override
  String get setupDoneBody =>
      'Waaiya peut couper le son d\'origine des autres applications. Ne refaites la configuration que si quelque chose a changé (elle a été annulée, ou Waaiya indique qu\'elle manque).';

  @override
  String get setupRedo => 'Afficher de nouveau la configuration';

  @override
  String get setupGo => 'Aller à la configuration';

  @override
  String get helperTitle => 'Appuis à travers les caches';

  @override
  String get helperBodyOff =>
      'Sans aide, un cache bloque les appuis en dessous. L\'assistant de Waaiya dessine les caches pour que les appuis les traversent. Activez le débogage sans fil (le Wi-Fi est nécessaire) et appuyez sur le bouton ; la première fois, faites l\'association une fois comme dans la configuration. Après un redémarrage du téléphone, appuyez de nouveau dessus.';

  @override
  String get helperStart => 'Démarrer l\'assistant de Waaiya';

  @override
  String get helperOn =>
      'L\'assistant de Waaiya dessine les caches : les appuis les traversent. Il s\'arrête quand le téléphone redémarre ou quand le débogage USB est désactivé ; appuyez alors de nouveau sur le bouton.';

  @override
  String get helperShizukuOn =>
      'Shizuku dessine les caches : les appuis les traversent.';

  @override
  String get helperOrShizuku => 'Ou avec Shizuku :';

  @override
  String get filterOptionsTitle => 'Options du filtre';

  @override
  String get settingsGeneralTitle => 'Général';

  @override
  String get worshipPrayerFajr => 'Fajr';

  @override
  String get worshipPrayerSunrise => 'Lever du soleil';

  @override
  String get worshipPrayerDhuhr => 'Dhohr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Icha';

  @override
  String get worshipEndSilent => 'Arrêter le silence';

  @override
  String get worshipUnmute => 'Remettre le son';

  @override
  String get worshipSmsDefault =>
      'C\'est l\'heure de la prière, je ne peux pas répondre maintenant. Je vous rappelle.';

  @override
  String get desktopPreview =>
      'Aperçu : le moteur de filtrage n\'est pas encore connecté sur cet ordinateur. Le bouton montre seulement comment l\'application fonctionnera.';

  @override
  String actionFailed(String details) {
    return 'Cela n\'a pas fonctionné : $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Les instruments sont supprimés de toutes les applications.';

  @override
  String get engineErrorNoPactl =>
      'Outils audio introuvables (pactl). Waaiya a besoin de PulseAudio, ou de PipeWire avec pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Le serveur de son ne fonctionne pas (PulseAudio ou PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Ce système n\'a pas de session utilisateur systemd, qui fait tourner le filtre en arrière-plan.';

  @override
  String get engineErrorNoOutput => 'Aucun haut-parleur ni casque trouvé.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Impossible d\'installer le filtre. Détails :\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Le filtre n\'a pas démarré. Détails :\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Le filtre s\'est arrêté avec une erreur. Détails :\n$details';
  }

  @override
  String get autostartTitle => 'Démarrer à l\'ouverture de session';

  @override
  String get autostartBody =>
      'Filtrer le son dès que vous ouvrez votre session.';

  @override
  String get blurBodyDesktop =>
      'Couvre les personnes et les images à l\'écran, par-dessus toutes les fenêtres, tant que Waaiya est ouvert (que le filtre audio soit activé ou non). Tout se fait sur cet ordinateur ; rien n\'est envoyé nulle part. Fermer la fenêtre de Waaiya arrête le flou.';

  @override
  String get blurFailBodyDesktop =>
      'Activé : tout l\'écran est couvert quand l\'ordinateur est trop lent ou que le flou échoue ; les clics atteignent quand même les fenêtres en dessous. Désactivé : l\'écran reste visible avec une barre rouge en haut.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Flou activé. Ce bureau montre le flou dans sa propre capture d\'écran, donc une zone floutée reste floutée jusqu\'à ce que la scène change.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Le flou ne peut pas s\'afficher par-dessus les autres fenêtres sur ce bureau. Détails :\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Choisissez votre écran dans la fenêtre de partage d\'écran et autorisez-le. Waaiya ne le demande qu\'une fois ; l\'image reste sur cet ordinateur.';

  @override
  String blurStatusExited(String details) {
    return 'Le flou s\'est arrêté de façon inattendue. Désactivez puis réactivez une option de flou pour réessayer. Détails :\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Le détecteur de chant des femmes ne s\'est pas chargé : les voix sont donc coupées tant que cette option est activée.';

  @override
  String get blurStatusUncovered =>
      'Un écran n\'est pas couvert par le flou : il ne lui a pas été partagé, ou il a été branché plus tard. Désactivez puis réactivez une option de flou, et choisissez tous les écrans dans la fenêtre de partage d\'écran.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Les modèles du flou manquent dans cette installation : il ne peut donc rien couvrir, et une barre rouge reste en haut de l\'écran. Réinstallez Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Ce que Waaiya voit sur cet ordinateur. Copiez-le et donnez-le à la personne qui vous aide. L\'application elle-même n\'envoie rien.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Recommandé. Si le filtrage s\'arrête de lui-même (une erreur, pas vous), les autres applis restent muettes jusqu\'à ce que vous le relanciez ou appuyiez sur Arrêter, au lieu de jouer la musique sans filtre.';

  @override
  String get settingStereoBodyDesktop =>
      'Désactivé : mono, qui sollicite moins l\'ordinateur. Activé : garde la gauche et la droite séparées. Si l\'ordinateur est trop lent pour la stéréo, il repasse en mono de lui-même.';

  @override
  String get linkEntryBodyDesktop =>
      'Collez un lien YouTube, TikTok ou Instagram pour le regarder avec le filtre actif, ou pour l\'enregistrer sans musique.';

  @override
  String get linkEntryBodyWatch =>
      'Collez un lien YouTube, TikTok ou Instagram pour le regarder dans votre navigateur avec le filtre actif.';

  @override
  String get linkWatchNoteDesktop =>
      'S\'ouvre dans votre navigateur. Waaiya lance d\'abord le filtre : la musique y est donc retirée aussi.';

  @override
  String get linkFilterFailed =>
      'Le filtre n\'a pas démarré, le lien n\'a donc pas été ouvert. Lancez-le depuis la page Filtre et réessayez.';

  @override
  String get linkSavedVideoDesktop => 'Dans votre dossier Vidéos : Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Dans votre dossier Musique : Waaiya';

  @override
  String get linkShowInFolder => 'Afficher dans le dossier';

  @override
  String get linkSingingNote =>
      'Le chant des femmes est aussi coupé, comme dans vos réglages.';

  @override
  String get singingKeepTitle => 'Garder le chant (essai)';

  @override
  String get singingKeepBody =>
      'Les instruments sont retirés mais les voix chantées restent, donc une conférence avec un nasheed en fond garde aussi la voix du nasheed ; à vous de juger si c\'est acceptable.';

  @override
  String get singingKeepNoModel =>
      'Cette version n\'a pas le modèle du chant : le son reste silencieux tant que cette option est activée. Désactivez-la.';

  @override
  String get fixFilterAppsTitle => 'Applications entendues sans filtre';

  @override
  String get fixFilterAppsBody =>
      'Ces applications jouent leur son d\'origine : Waaiya ne les filtre pas et ne les coupe pas.';

  @override
  String get fixAddApp => 'Ajouter une application';

  @override
  String fixRemoveApp(Object app) {
    return 'Retirer $app';
  }

  @override
  String get fixNoApps => 'Aucune application choisie.';

  @override
  String get fixPickTitle => 'Choisir une application';

  @override
  String get fixPickEmpty => 'Aucune autre application trouvée.';

  @override
  String get fixPickPlayingDesktop =>
      'Les applications qui jouent du son maintenant, et celles déjà choisies.';

  @override
  String get fixCancel => 'Annuler';

  @override
  String get fixBlurAppsTitle => 'Applications sans flou';

  @override
  String get fixBlurAppsBody =>
      'Aucun cache tant qu\'une de ces applications est seule à l\'écran. Les caches reviennent dès que vous la quittez, ou dès que Waaiya n\'est pas sûre de l\'application affichée.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Nécessite la configuration unique : sans elle, Waaiya ne sait pas quelle application est à l\'écran, donc le flou reste partout.';

  @override
  String get fixBlurAppsHelperMode =>
      'L\'assistant de Waaiya ne tourne pas, donc l\'application à l\'écran ne peut pas être lue. Le floutage reste partout jusqu\'à ce que l\'assistant soit relancé depuis la page Configuration.';

  @override
  String get fixHandTitle => 'Couvrir une zone à la main';

  @override
  String get fixHandBody =>
      'Pendant que le flou fonctionne, faites glisser le doigt sur une partie de l\'écran pour la couvrir. Elle reste couverte jusqu\'à ce que vous la retiriez ou que le flou s\'arrête.';

  @override
  String get fixHandNotRunning =>
      'Disponible pendant que le flou fonctionne : filtrage activé et une option de flou activée.';

  @override
  String get fixCoverArea => 'Couvrir une zone';

  @override
  String fixRemoveCovers(Object count) {
    return 'Retirer les caches manuels ($count)';
  }

  @override
  String get fixNoteTitle => 'Noter une erreur';

  @override
  String get fixNoteBody =>
      'Notez-la au moment où elle arrive. Une note garde l\'heure, l\'application et les réglages. Elle reste sur cet appareil et n\'est jamais envoyée.';

  @override
  String get fixMissedSound => 'De la musique est passée';

  @override
  String get fixWrongSound => 'Voix retirée par erreur';

  @override
  String get fixMissedScreen => 'Quelque chose n\'a pas été couvert';

  @override
  String get fixWrongScreen => 'Couvert par erreur';

  @override
  String fixNoted(Object count) {
    return 'Noté ($count notes sur cet appareil).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Notes sur cet appareil : $count';
  }

  @override
  String get fixNotesShow => 'Afficher les notes';

  @override
  String get fixNotesDelete => 'Supprimer les notes';

  @override
  String get fixNotesDeleteAsk =>
      'Supprimer toutes les notes ? Impossible d\'annuler.';

  @override
  String get fixNotesTitle => 'Notes d\'erreurs de détection';

  @override
  String get worshipTitle => 'Heures de prière';

  @override
  String get worshipBody =>
      'Facultatif. Calculées sur ce téléphone à partir du lieu choisi. Rien n\'est envoyé.';

  @override
  String worshipPlace(Object place) {
    return 'Lieu : $place';
  }

  @override
  String get worshipPlaceNone => 'Lieu : non choisi';

  @override
  String get worshipChoose => 'Choisir';

  @override
  String get worshipPlaceSearch => 'Chercher une ville';

  @override
  String get worshipPlaceNoMatch =>
      'Aucune ville trouvée. Vous pouvez saisir des coordonnées à la place.';

  @override
  String get worshipPlaceCustom => 'Saisir des coordonnées';

  @override
  String get worshipLat => 'Latitude (nord +, sud −)';

  @override
  String get worshipLon => 'Longitude (est +, ouest −)';

  @override
  String get worshipZone => 'Fuseau horaire, par exemple Europe/Paris';

  @override
  String get worshipCustomInvalid =>
      'Vérifiez les nombres et le fuseau horaire.';

  @override
  String get worshipPlaceInvalid =>
      'Ce lieu ne peut pas être utilisé. Choisissez-le de nouveau.';

  @override
  String worshipMethod(Object method) {
    return 'Calcul : $method';
  }

  @override
  String get worshipMethodTitle => 'Méthode de calcul';

  @override
  String get worshipMethodNote =>
      'Choisie selon le pays de la ville. Prenez celle que suit votre mosquée.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr : $rule';
  }

  @override
  String get worshipAsrTitle => 'Heure de l\'Asr';

  @override
  String get worshipAsrStandard => 'Standard (chaféite, malékite, hanbalite)';

  @override
  String get worshipAsrHanafi => 'Hanafite';

  @override
  String get worshipMethodMwl => 'Ligue islamique mondiale';

  @override
  String get worshipMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get worshipMethodEgypt => 'Autorité générale égyptienne d\'arpentage';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, La Mecque';

  @override
  String get worshipMethodKarachi =>
      'Université des sciences islamiques, Karachi';

  @override
  String get worshipMethodTehran =>
      'Institut de géophysique, Université de Téhéran';

  @override
  String get worshipMethodGulf => 'Région du Golfe';

  @override
  String get worshipMethodKuwait => 'Koweït';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapour (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turquie (Diyanet)';

  @override
  String get worshipMethodFrance => 'France (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Maroc (ministère des Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonésie (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malaisie (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubaï';

  @override
  String get worshipToday => 'Aujourd\'hui';

  @override
  String get worshipNoTimes =>
      'Pas d\'heures de prière ici aujourd\'hui : le soleil ne se lève pas ou ne se couche pas.';

  @override
  String get worshipSilentTitle => 'Silencieux aux heures de prière';

  @override
  String get worshipSilentBody =>
      'À chaque heure de prière, Ne pas déranger pendant la durée ci-dessous, puis retour à votre réglage.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Silence pendant : $minutes min';
  }

  @override
  String get worshipMuteTitle => 'Couper les médias à l\'adhan';

  @override
  String get worshipMuteBody =>
      'À chaque heure de prière, le son des médias (vidéos, audio, jeux) est coupé pendant la durée ci-dessous. La notification permet de le remettre aussitôt.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Coupé pendant : $minutes min';
  }

  @override
  String get worshipMinutesTitle => 'Durée';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get worshipNeedPlace => 'Choisissez d\'abord un lieu.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Prochaine : $prayer à $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Silencieux jusqu\'à $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Médias coupés jusqu\'à $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Autorisez Waaiya à modifier Ne pas déranger, sinon le téléphone ne peut pas passer en silencieux.';

  @override
  String get worshipAllow => 'Autoriser';

  @override
  String get worshipExactNeeded =>
      'Alarmes et rappels ne sont pas autorisés pour Waaiya : chaque changement peut arriver jusqu\'à 10 minutes en retard, ou plus quand le téléphone est en veille.';

  @override
  String get worshipNotificationsNeeded =>
      'Les notifications sont désactivées : vous ne verrez pas quand le téléphone passe en silencieux ou revient.';

  @override
  String get worshipTonesTitle => 'Sonnerie et son de notification simples';

  @override
  String get worshipTonesBody =>
      'Waaiya ne peut pas filtrer la sonnerie ni les sons de notification, seulement les remplacer. Choisissez un son simple, sans musique :';

  @override
  String worshipToneRing(Object number) {
    return 'Sonnerie simple $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Son de notification simple $number';
  }

  @override
  String get worshipTonePlay => 'Écouter';

  @override
  String get worshipToneSet => 'Utiliser';

  @override
  String get worshipToneInUse => 'Utilisé';

  @override
  String get worshipToneDone => 'C\'est fait.';

  @override
  String get worshipTonePermission =>
      'Autorisez Waaiya à modifier les paramètres système, revenez et appuyez de nouveau.';

  @override
  String get worshipToneFailed =>
      'Ce téléphone n\'a pas laissé Waaiya le changer. Dans les paramètres Son, choisissez un son nommé « Waaiya plain ».';

  @override
  String get worshipOpenSound => 'Ouvrir les paramètres Son';

  @override
  String get worshipSmsTitle => 'Répondre aux appels par SMS pendant la prière';

  @override
  String get worshipSmsBody =>
      'Pendant les minutes de silence après chaque heure de prière, un appel laissé sans réponse reçoit un SMS. Une fois par numéro et par prière ; jamais aux numéros masqués ni aux numéros courts.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Après : $seconds s de sonnerie';
  }

  @override
  String get worshipSmsDelayTitle => 'Secondes de sonnerie avant le SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Message : $text';
  }

  @override
  String get worshipSmsTextTitle => 'Votre message';

  @override
  String get worshipSmsTextDefault => 'Message par défaut';

  @override
  String get worshipSmsCost =>
      'Chaque réponse est un SMS normal envoyé depuis votre SIM, au prix de votre forfait. Rien n\'est envoyé en itinérance.';

  @override
  String get worshipSmsRoaming => 'En itinérance : aucun SMS n\'est envoyé.';

  @override
  String get worshipSmsLogTitle =>
      'Réponses envoyées (gardées sur ce téléphone seulement)';

  @override
  String get worshipContinue => 'Continuer';

  @override
  String get worshipWhyDnd =>
      'Pour mettre le téléphone en silencieux aux heures de prière, autorisez l\'accès de Waaiya à Ne pas déranger sur la page suivante.';

  @override
  String get worshipWhyExact =>
      'Pour agir à l\'heure exacte, autorisez Waaiya à définir des alarmes et rappels sur la page suivante. Sinon, les changements peuvent arriver jusqu\'à 10 minutes en retard.';

  @override
  String get worshipWhyNotifications =>
      'Autorisez les notifications pour voir chaque changement et pouvoir l\'annuler.';

  @override
  String get worshipWhyWrite =>
      'Pour changer votre sonnerie ou son de notification, autorisez Waaiya à modifier les paramètres système sur la page suivante.';

  @override
  String get worshipWhyPhone =>
      'Pour savoir qu\'un appel sonne et connaître son numéro, Waaiya a besoin des autorisations Téléphone et Journaux d\'appels. Rien ne quitte le téléphone sauf votre réponse.';

  @override
  String get worshipWhySms =>
      'Pour envoyer votre réponse, Waaiya a besoin de l\'autorisation d\'envoyer des SMS. Il n\'envoie que cette réponse, au plus une fois par numéro et par prière.';

  @override
  String get worshipMissingDnd =>
      'L\'accès à Ne pas déranger n\'a pas été autorisé : le silence reste désactivé.';

  @override
  String get worshipMissingPhone =>
      'Les autorisations Téléphone et Journaux d\'appels n\'ont pas été accordées : la réponse par SMS reste désactivée.';

  @override
  String get worshipMissingSms =>
      'L\'autorisation d\'envoyer des SMS n\'a pas été accordée : la réponse par SMS reste désactivée.';

  @override
  String get worshipTryAgain => 'Réessayer';

  @override
  String get protectTitle => 'Protection pour les moments de faiblesse';

  @override
  String get protectBody =>
      'Pour un moment de faiblesse où vous pourriez vouloir arrêter le filtre. Choisissez maintenant, au calme, un délai : le bouton d\'arrêt n\'arrête alors pas le filtre tout de suite, et vous décidez à nouveau une fois le délai écoulé. Un parent peut aussi définir un code PIN.';

  @override
  String protectDelay(Object value) {
    return 'Délai avant l\'arrêt : $value';
  }

  @override
  String get protectDelayTitle => 'Délai avant l\'arrêt';

  @override
  String get protectDelayBody =>
      'Par exemple, avec 30 minutes : vous appuyez sur le bouton pour arrêter, mais le filtre continue. Après 30 minutes, cette page vous demande si vous voulez toujours arrêter. Appuyez sur « Confirmer » dans les 15 minutes et il s\'arrête ; sinon rien ne change. Il en va de même pour désactiver une couverture ou toute autre protection. Activer quelque chose fonctionne toujours tout de suite.';

  @override
  String get protectDelayOff => 'Aucun';

  @override
  String get protectDelay1m => '1 minute';

  @override
  String get protectDelay5m => '5 minutes';

  @override
  String get protectDelay15m => '15 minutes';

  @override
  String get protectDelay30m => '30 minutes';

  @override
  String get protectDelay1h => '1 heure';

  @override
  String get protectDelay4h => '4 heures';

  @override
  String get protectDelay24h => '24 heures';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get protectPinNone => 'Code : aucun';

  @override
  String get protectPinIsSet => 'Code : défini';

  @override
  String get protectPinSet => 'Définir un code';

  @override
  String get protectPinRemove => 'Supprimer';

  @override
  String get protectPinBody =>
      'Avec un code, chaque changement qui baisse la protection le demande d\'abord. Changer le délai ou le code le demande aussi.';

  @override
  String get protectPinForgot =>
      'Si le code est oublié, il n\'y a pas de réinitialisation : seulement effacer les données de Waaiya ou la réinstaller, ce qui efface aussi tous ses réglages.';

  @override
  String get protectPinTitle => 'Saisissez le code';

  @override
  String get protectPinNewTitle => 'Choisissez un code';

  @override
  String get protectPinChangeTitle => 'Changer le code';

  @override
  String get protectPinCurrent => 'Code actuel';

  @override
  String get protectPinNew => 'Nouveau code (4 à 8 chiffres)';

  @override
  String get protectPinAgain => 'Nouveau code, encore';

  @override
  String get protectPinBad => 'Utilisez 4 à 8 chiffres.';

  @override
  String get protectPinDiffer =>
      'Les deux nouveaux codes ne sont pas identiques.';

  @override
  String protectPinWrong(Object count) {
    return 'Code erroné. Encore $count essais avant une pause.';
  }

  @override
  String protectLocked(Object time) {
    return 'Trop d\'essais erronés. Réessayez à $time.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Annuler';

  @override
  String get protectCancelChange => 'Annuler le changement';

  @override
  String get protectConfirm => 'Confirmer';

  @override
  String protectPending(Object time, Object what) {
    return '$what : en attente jusqu\'à $time. Confirmez ensuite dans « Paramètres ».';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what : l\'attente est finie. Le voulez-vous toujours ? Appuyez sur « Confirmer » avant $time ; sinon rien ne change.';
  }

  @override
  String get protectWaitTitle => 'Ce changement attend';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what n\'a pas lieu maintenant. À $time, si vous le voulez toujours, confirmez-le dans « Paramètres » dans les 15 minutes. Si vous ne faites rien, rien ne change.';
  }

  @override
  String get protectWaitStart => 'Commencer l\'attente';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Déjà en attente jusqu\'à $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'En attente jusqu\'à $time. Confirmez ensuite dans « Paramètres ».';
  }

  @override
  String protectTomorrow(Object time) {
    return 'demain à $time';
  }

  @override
  String get protectHeldBack =>
      'Ce changement est retenu par les réglages de protection.';

  @override
  String get protectLimits =>
      'Ce que cela ne peut pas empêcher : l\'arrêt forcé, la désinstallation, l\'effacement des données de Waaiya et les réglages d\'Android eux-mêmes. Les bloquer demande des pouvoirs d\'administrateur de l\'appareil ou d\'accessibilité que Waaiya n\'utilise pas. Cela protège d\'un moment de faiblesse, pas d\'une personne déterminée.';

  @override
  String get protectLimitsDesktop =>
      'Ce que cela ne peut pas empêcher : la commande waaiya dans un terminal, la suppression de Waaiya ou de son dossier de réglages. Cela protège d\'un moment de faiblesse, pas d\'une personne déterminée.';

  @override
  String get protectLimitsWindows =>
      'Ce que cela ne peut pas empêcher : la commande waaiya-filter.exe dans un terminal, la suppression de Waaiya ou de son dossier de réglages. Cela protège d\'un moment de faiblesse, pas d\'une personne déterminée.';

  @override
  String get protectWhatStop => 'Arrêter le filtre';

  @override
  String protectWhatOff(Object name) {
    return 'Désactiver : $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Activer : $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Ajouter une application à : $name';
  }

  @override
  String get protectWhatStrictness => 'Rendre le flou moins strict';

  @override
  String get protectWhatGender => 'Changer qui utilise le téléphone';

  @override
  String protectWhatDelay(Object value) {
    return 'Changer le délai avant l\'arrêt : $value';
  }

  @override
  String get protectWhatPinChange => 'Changer le code';

  @override
  String get protectWhatPinClear => 'Supprimer le code';

  @override
  String get protectWhatSetting => 'Changer un réglage';
}
