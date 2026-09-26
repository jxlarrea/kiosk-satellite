// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class UiStringsFr extends UiStrings {
  UiStringsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutApp => 'Application';

  @override
  String get aboutVersion => 'Version de l\'application';

  @override
  String get aboutBuild => 'Build';

  @override
  String get aboutPackage => 'Package';

  @override
  String get aboutAttribution => 'Attribution';

  @override
  String get aboutAuthor => 'Auteur';

  @override
  String get aboutWebsite => 'Site web';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get aboutLicense => 'Licence';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite est gratuit pour un usage personnel et non commercial. Il est distribué sous licence CC BY-NC-ND 4.0 : vous pouvez l\'utiliser et le partager, mais l\'usage commercial de l\'application et la redistribution de versions modifiées ne sont pas autorisés. Les plugins indépendants bénéficient d\'une autorisation supplémentaire selon PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Crédits de traduction';

  @override
  String get aboutLocalizationCreditsHint => 'Contributeurs par langue';

  @override
  String get aboutCheckNow => 'Vérifier les mises à jour maintenant';

  @override
  String get aboutChecking => 'Vérification…';

  @override
  String get aboutCheckFailed =>
      'Échec de la vérification des mises à jour. L\'appareil peut-il joindre GitHub ?';

  @override
  String get aboutOverlayMissing =>
      'Autorisation « Affichage par-dessus d\'autres applications » manquante';

  @override
  String get aboutOverlayHelp =>
      'Sans elle, l\'application ne peut pas se rouvrir après une mise à jour. L\'écran d\'autorisation apparaît sur la tablette.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Déjà à jour';

  @override
  String get aboutInstallHelp =>
      'Le téléchargement s\'exécute sur la tablette ; l\'installation doit être confirmée sur l\'écran de la tablette.';

  @override
  String get androidAccessibilityHelp =>
      'Ferme le panneau de notifications et l\'écran des applications récentes chaque fois qu\'ils s\'ouvrent tant que le mode Kiosque ou le mode Verrouillage protège l\'écran. Kiosk Satellite ne lit aucun contenu d\'écran.';

  @override
  String get androidServiceChannelHelp =>
      'Affiché tant que le Kiosk Satellite Service maintient l\'application active lorsque l\'écran est éteint ou qu\'une autre application est au premier plan.';

  @override
  String get androidServiceListening => 'écoute d\'un mot de réveil';

  @override
  String get androidServiceRtspAudio => 'audio microphone RTSP activé';

  @override
  String get androidServiceEsphome => 'service ESPHome actif';

  @override
  String get androidServiceBluetooth => 'relais des appareils Bluetooth';

  @override
  String get androidServiceCamera => 'surveillance de la caméra';

  @override
  String get androidServiceLocation => 'signalement de la position';

  @override
  String get androidServiceRemote =>
      'service d\'administration à distance actif';

  @override
  String get androidServiceKiosk => 'protection du mode kiosque';

  @override
  String get androidServiceSessions =>
      'maintien de la connexion à Home Assistant';

  @override
  String get launcherErrorAndroidOnly =>
      'la liste des applications n\'est disponible que sous Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'impossible de lister les applications : $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'Impossible d\'ouvrir $name';
  }

  @override
  String get launcherUninstalled => 'Elle a peut-être été désinstallée.';

  @override
  String get launcherNoneHelp =>
      'Aucune pour l\'instant. Choisissez les applications que le lanceur propose.';

  @override
  String get launcherNone => 'Aucune pour l\'instant';

  @override
  String get launcherListFailed => 'Impossible de lister les applications';

  @override
  String launcherListError(String error) {
    return 'Impossible de lister les applications : $error';
  }

  @override
  String get launcherListingFailed => 'échec de la récupération de la liste';

  @override
  String get launcherEmpty =>
      'Aucune application pouvant être lancée n\'a été trouvée.';

  @override
  String get cameraViewerTitle => 'Vue caméra';

  @override
  String get cameraViewerConnecting => 'Connexion...';

  @override
  String get cameraViewerReconnecting => 'Reconnexion...';

  @override
  String cameraViewerTrying(String transport) {
    return 'Tentative via $transport...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Cet appareil ne peut pas décoder le $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Cet appareil ne peut pas lire les flux $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Cet appareil ne peut pas décoder ce flux';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'Impossible de joindre Home Assistant. Nouvel essai dans $seconds s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'Impossible de joindre le serveur de caméra. Nouvel essai dans $seconds s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'Échec de la connexion. Nouvel essai dans $seconds s';
  }

  @override
  String get cameraViewerStartRetry =>
      'Le serveur de caméra n\'a pas pu démarrer ce flux. Nouvel essai...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'Le serveur de caméra n\'a pas pu démarrer ce flux. Nouvel essai dans $seconds s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'Flux introuvable sur le serveur de caméra. Nouvel essai dans $seconds s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'Le serveur de caméra a rejeté l\'authentification. Nouvel essai dans $seconds s';
  }

  @override
  String get cameraViewerMissing => 'Flux absent de Go2RTC';

  @override
  String get commonImport => 'Importer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonFinish => 'Terminer';

  @override
  String get commonWorking => 'Traitement en cours…';

  @override
  String get commonSettings => 'Paramètres';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGrant => 'Autoriser';

  @override
  String get commonEnable => 'Activer';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonTest => 'Tester';

  @override
  String get commonInstall => 'Installer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonBrowse => 'Parcourir';

  @override
  String get commonSet => 'Définir';

  @override
  String get commonHour => 'Heure';

  @override
  String get commonMinute => 'Minute';

  @override
  String get commonUp => 'Haut';

  @override
  String get commonDown => 'Bas';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSaveFailed => 'Échec de l\'enregistrement';

  @override
  String get commonColorWhite => 'Blanc';

  @override
  String get commonColorWarm => 'Chaud';

  @override
  String get commonColorAmber => 'Ambre';

  @override
  String get commonColorRed => 'Rouge';

  @override
  String get commonColorGreen => 'Vert';

  @override
  String get commonColorBlue => 'Bleu';

  @override
  String get commonColorCyan => 'Cyan';

  @override
  String get commonColorDim => 'Tamisé';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonMoveUp => 'Monter';

  @override
  String get commonMoveDown => 'Descendre';

  @override
  String get commonPreviousMonth => 'Mois précédent';

  @override
  String get commonNextMonth => 'Mois suivant';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonChoose => 'Choisir';

  @override
  String get dlnaPortInvalid =>
      'Saisissez un port entre 1024 et 65535, ou laissez ce champ vide';

  @override
  String get commonSelectAll => 'Tout sélectionner';

  @override
  String get dlnaCannotDecode =>
      'Cet appareil ne peut pas décoder cette vidéo.';

  @override
  String get dlnaCannotRead => 'Ce fichier n\'a pas pu être lu.';

  @override
  String get dlnaCannotPlay => 'Ce média n\'a pas pu être lu.';

  @override
  String get dlnaSeeLogs =>
      'Consultez les journaux de l\'application pour plus de détails';

  @override
  String get dlnaLoading => 'Chargement du média';

  @override
  String get dlnaImageFailed => 'Cette image n\'a pas pu être affichée.';

  @override
  String get dlnaStop => 'Arrêter la lecture';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName : $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Action du plugin';

  @override
  String get drawerPluginActionError => 'Impossible d\'exécuter cette action.';

  @override
  String get drawerDashboard => 'Tableau de bord';

  @override
  String get drawerHaKiosk => 'Mode kiosque HA';

  @override
  String get drawerCameraView => 'Vue caméra';

  @override
  String get drawerIntercom => 'Interphone';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Masquer le lecteur flottant';

  @override
  String get drawerShowPlayer => 'Afficher le lecteur flottant';

  @override
  String get drawerNowPlaying => 'Lecture en cours';

  @override
  String get drawerScreensaver => 'Démarrer l\'économiseur d\'écran';

  @override
  String get drawerLockdown => 'Mode verrouillage';

  @override
  String get drawerHoldOff => 'Désactiver le mode maintien';

  @override
  String get drawerHoldOn => 'Activer le mode maintien';

  @override
  String get drawerApps => 'Applications';

  @override
  String get drawerClearCache => 'Vider le cache web';

  @override
  String get drawerRestartDevice => 'Redémarrer l\'appareil';

  @override
  String get drawerRestartConfirm =>
      'Redémarrer cet appareil ? Kiosk Satellite revient automatiquement au démarrage.';

  @override
  String get drawerRestart => 'Redémarrer';

  @override
  String get drawerExitApplication => 'Quitter l\'application';

  @override
  String get drawerExitConfirm => 'Fermer Kiosk Satellite ?';

  @override
  String get drawerExit => 'Quitter';

  @override
  String get drawerHoldActive => 'Le mode maintien est activé';

  @override
  String get drawerHoldHelp =>
      'L\'économiseur d\'écran et les minuteries sont en pause · appuyez pour désactiver';

  @override
  String get drawerThemeDark => 'Sombre';

  @override
  String get drawerThemeLight => 'Clair';

  @override
  String get drawerThemeAndroid => 'Suivre Android';

  @override
  String drawerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get drawerUpdateAvailable => 'Mise à jour disponible';

  @override
  String drawerUpdateInstall(String version) {
    return 'Version $version · appuyez pour installer';
  }

  @override
  String get drawerUpdateChecking => 'Vérification des mises à jour…';

  @override
  String get drawerUpdateCurrent => 'À jour';

  @override
  String get drawerUpdateCurrentHelp => 'Vous êtes sur la dernière version.';

  @override
  String get drawerUpdateCheckFailed =>
      'Échec de la vérification des mises à jour';

  @override
  String get drawerUpdateOffline => 'L\'appareil est-il en ligne ?';

  @override
  String drawerUpdateTo(String version) {
    return 'Mettre à jour vers $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'Le téléchargement démarre quand vous appuyez sur Mettre à jour. Android vous demande de confirmer l\'installation.';

  @override
  String get drawerUpdateRelaunch =>
      'Sans l\'autorisation « Affichage par-dessus d\'autres applications », l\'application ne peut pas se rouvrir après une mise à jour.';

  @override
  String get drawerUpdate => 'Mettre à jour';

  @override
  String get drawerUpdateDownloading => 'Téléchargement de la mise à jour';

  @override
  String get drawerUpdateStarting => 'Démarrage…';

  @override
  String get drawerUpdateFailed => 'Échec de la mise à jour';

  @override
  String get drawerUpdates => 'Mises à jour';

  @override
  String get drawerNoReleaseNotes => 'Aucune note de version.';

  @override
  String get esphomeAllExposed =>
      'Toutes les entités disponibles sont exposées';

  @override
  String esphomeExcludedCount(String count) {
    return '$count exclues';
  }

  @override
  String get esphomeEntitySearch => 'Rechercher des entités';

  @override
  String get esphomeEntityLoading => 'Chargement des entités…';

  @override
  String get esphomeEntityUnavailable => 'Actuellement indisponible';

  @override
  String get esphomeEntityNoMatch => 'Aucune entité correspondante';

  @override
  String get esphomeEntityLoadFailed =>
      'Impossible de charger les entités. Fermez le sélecteur et réessayez.';

  @override
  String get esphomeEntitySaveFailed =>
      'Impossible d\'enregistrer les exclusions. Réessayez.';

  @override
  String get esphomeTypeConfig => 'Configuration';

  @override
  String get esphomeTypeDiagnostics => 'Diagnostics';

  @override
  String get esphomeTypeSensorGroup => 'Capteur';

  @override
  String get esphomeTypeControl => 'Contrôle';

  @override
  String get esphomeTypeSensor => 'capteur';

  @override
  String get esphomeTypeTextSensor => 'capteur de texte';

  @override
  String get esphomeTypeBinarySensor => 'capteur binaire';

  @override
  String get esphomeTypeCamera => 'caméra';

  @override
  String get esphomeTypeSwitch => 'interrupteur';

  @override
  String get esphomeTypeButton => 'bouton';

  @override
  String get esphomeTypeNumber => 'nombre';

  @override
  String get esphomeTypeSelect => 'sélecteur';

  @override
  String get esphomeTypeLight => 'lumière';

  @override
  String get esphomeTypeUpdate => 'mise à jour';

  @override
  String get esphomeTypeText => 'texte';

  @override
  String get filesUpload => 'Envoyer un fichier';

  @override
  String get filesUploading => 'Envoi…';

  @override
  String get filesUploadFailed => 'Échec de l\'envoi';

  @override
  String get filesUploaded => 'Envoyé';

  @override
  String get filesPermissionMissing =>
      'Autorisation « Accès à tous les fichiers » manquante';

  @override
  String get filesPermissionHelp =>
      'Sans elle, seul le dossier de l\'application peut être parcouru. L\'écran d\'autorisation s\'ouvre sur la tablette.';

  @override
  String get filesGrant => 'Autoriser sur l\'appareil';

  @override
  String get filesUp => 'Remonter d\'un dossier';

  @override
  String get filesShared => 'Stockage partagé';

  @override
  String get filesApp => 'Dossier de l\'application';

  @override
  String get filesReadFailed => 'Impossible de lire le dossier';

  @override
  String get filesEmpty => 'Dossier vide';

  @override
  String get filesEmptyHelp => 'Rien ici pour l\'instant.';

  @override
  String get filesFolder => 'Dossier';

  @override
  String get filesDownload => 'Télécharger';

  @override
  String get filesDownloadFailed => 'Échec du téléchargement';

  @override
  String filesDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get filesDeleteHelp => 'Le fichier est retiré de l\'appareil.';

  @override
  String get filesInvalidPath => 'Chemin invalide';

  @override
  String get filesNoFolder => 'Ce dossier n\'existe pas';

  @override
  String get filesNoFile => 'Ce fichier n\'existe pas';

  @override
  String filesReadError(String error) {
    return 'Impossible de lire le dossier : $error';
  }

  @override
  String filesWriteError(String error) {
    return 'Échec de l\'écriture : $error';
  }

  @override
  String get filesDeleteFailed => 'Impossible de supprimer le fichier';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'La gestion de flotte nécessite l\'administration à distance';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Les kiosques se trouvent entre eux grâce à elle. Activez Gestion à distance et Trouver d\'autres kiosques dans Appareil, puis revenez ici.';

  @override
  String get fleetLeadThisFleet => 'Diriger cette flotte';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Synchroniser les paramètres de ce kiosque avec ses suiveurs. Nécessite que tous les kiosques exécutent la même version.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Un kiosque qui suit un leader ne peut pas diriger.';

  @override
  String get fleetFollowers => 'Suiveurs';

  @override
  String get fleetProfiles => 'Profils';

  @override
  String get fleetLeader => 'Leader';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Découvrez quels paramètres se synchronisent et lesquels ne le font pas dans la ';

  @override
  String get fleetFleetManagementDocumentation =>
      'documentation de la gestion de flotte';

  @override
  String get fleetMore => 'Plus';

  @override
  String get fleetSearchFollowers =>
      'Les kiosques que celui-ci dirige, leur état et un moyen d\'en ajouter un.';

  @override
  String get fleetAddAKiosk => 'Ajouter un kiosque';

  @override
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm =>
      'Ajoutez un kiosque détecté ou saisissez son adresse IP. Le suiveur doit accepter l\'invitation sur son écran.';

  @override
  String get fleetSendInvitation => 'Envoyer l\'invitation';

  @override
  String get fleetInviteAgain => 'Inviter à nouveau';

  @override
  String fleetRemoveName(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Il arrête de suivre ce kiosque et conserve ses paramètres.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name souhaite diriger ce kiosque';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'Ses paramètres remplacent ceux de ce kiosque dans les catégories qu\'il synchronise, à partir de maintenant. Ce kiosque conserve son nom et son identité.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'Ses paramètres remplacent ceux de ce kiosque dans les catégories qu\'il synchronise, à partir de maintenant. Ce kiosque conserve son nom, ses identités Home Assistant, Music Assistant et ESPHome ainsi que ses choix matériels. Vous pouvez quitter la flotte à tout moment dans Paramètres, Gestion de flotte.';

  @override
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting =>
      'Confirmez directement sur le kiosque. L\'invitation attend sur son écran et dans Paramètres, Gestion de flotte.';

  @override
  String get fleetAccept => 'Accepter';

  @override
  String get fleetLookingForOtherKiosks => 'Recherche d\'autres kiosques…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'Aucun kiosque détecté. Utilisez Ajouter par IP pour en trouver un à une adresse connue.';

  @override
  String fleetFollowsName(String name) {
    return 'Suit $name';
  }

  @override
  String get fleetLeadsAFleet => 'Dirige une flotte';

  @override
  String get fleetNoFleetManagement => 'Pas de gestion de flotte';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kiosques de ce réseau qui ne suivent pas celui-ci. Choisissez-en un et définissez ce qu\'il recevra pour lui envoyer l\'invitation. Si sa version n\'inclut pas la gestion de flotte, il pourra rejoindre la flotte lorsqu\'il sera mis à jour.';

  @override
  String get fleetJoinedTheFleet => 'A rejoint la flotte';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'Les paramètres du leader arrivent sous peu.';

  @override
  String get fleetAddByIp => 'Ajouter par IP';

  @override
  String get fleetFindKiosk => 'Trouver le kiosque';

  @override
  String get fleetFindingKiosk => 'Recherche du kiosque…';

  @override
  String get fleetIpAddress => 'Adresse IP';

  @override
  String get fleetRemoteAdminPort => 'Port de l\'administration à distance';

  @override
  String get fleetAddressHelp =>
      'Saisissez l\'adresse IP du kiosque et le port de l\'administration à distance.';

  @override
  String get fleetAddAProfile => 'Ajouter un profil';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'L\'ensemble des paramètres, identifiants et exclusions à synchroniser.';

  @override
  String get fleetNewProfile => 'Nouveau profil';

  @override
  String get fleetProfile => 'Profil';

  @override
  String get fleetUpdatesOnly => 'Mises à jour uniquement';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'Rien ne se synchronise. Seules les mises à jour sont envoyées.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Catégories : $selected sur $total. Identifiants : $credentials sur $credentialTotal. Exclus : $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Ce profil n\'existe plus';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Il a été supprimé depuis une autre page.';

  @override
  String get fleetName => 'Nom';

  @override
  String get fleetRename => 'Renommer';

  @override
  String get fleetRenameProfile => 'Renommer le profil';

  @override
  String get fleetWhatItSyncs => 'Ce qu\'il synchronise';

  @override
  String get fleetNothing => 'Rien';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Les kiosques sur ce profil conservent tous leurs propres paramètres. Le leader se contente de leur envoyer les mises à jour.';

  @override
  String get fleetCategories => 'Catégories';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected sur $total : $names';
  }

  @override
  String get fleetCredentials => 'Identifiants';

  @override
  String get fleetNoneTravel => 'Aucun identifiant synchronisé';

  @override
  String get fleetIncludeTheDashboard => 'Inclure le tableau de bord';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'La page de démarrage et le tableau de bord par défaut.';

  @override
  String get fleetExcludedSettings => 'Paramètres exclus';

  @override
  String get fleetOneSettingLeftOut => 'Un paramètre exclu';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count paramètres exclus';
  }

  @override
  String get fleetNoKiosksAssigned => 'Aucun kiosque assigné';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Assignez ce profil à un kiosque sur la page Gestion de flotte.';

  @override
  String get fleetDuplicate => 'Dupliquer';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Cloner ce profil dans un nouveau.';

  @override
  String get fleetDuplicateProfile => 'Dupliquer le profil';

  @override
  String fleetNameCopy(String name) {
    return 'Copie de $name';
  }

  @override
  String get fleetDeleteProfile => 'Supprimer le profil';

  @override
  String get fleetNoKioskIsOnIt => 'Aucun kiosque ne l\'utilise.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Les kiosques qui l\'utilisent reçoivent le profil par défaut.';

  @override
  String fleetDeleteName(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get fleetBlackScreens => 'Écrans noirs';

  @override
  String fleetSyncToName(String name) {
    return 'Synchroniser avec $name';
  }

  @override
  String get fleetDefault => 'Par défaut';

  @override
  String get fleetNone => 'Aucun';

  @override
  String get fleetSearchProfiles =>
      'Les listes nommées qu\'un suiveur peut recevoir : catégories, identifiants, le tableau de bord et les paramètres exclus.';

  @override
  String get fleetSyncNow => 'Synchroniser maintenant';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Modifié ici, en attente du leader';

  @override
  String fleetSyncedTime(String time) {
    return 'Synchronisé $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'En attente de la première synchronisation';

  @override
  String get fleetNothingYet => 'Rien pour l\'instant';

  @override
  String get fleetNoCredentials => 'Aucun identifiant';

  @override
  String fleetWithTheNames(String names) {
    return 'Avec $names';
  }

  @override
  String get fleetTheDashboard => 'le tableau de bord';

  @override
  String get fleetNoDashboard => 'aucun tableau de bord';

  @override
  String get fleetTheDashboardDetail => 'Le tableau de bord';

  @override
  String get fleetNoDashboardDetail => 'Aucun tableau de bord';

  @override
  String get fleetSyncedFromTheLeader => 'Synchronisé depuis le leader';

  @override
  String get fleetLeaveTheFleet => 'Quitter la flotte';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Arrête la synchronisation. Les paramètres restent tels quels.';

  @override
  String get fleetLeaveTheFleetDetail => 'Quitter la flotte ?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name cesse d\'envoyer des paramètres ici. Tout reste tel quel pour l\'instant.';
  }

  @override
  String get fleetLeave => 'Quitter';

  @override
  String get fleetJustNow => 'à l\'instant';

  @override
  String fleetCountMinAgo(String count) {
    return 'il y a $count min';
  }

  @override
  String fleetCountHAgo(String count) {
    return 'il y a $count h';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return 'il y a $count jours';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name dirige ces paramètres. Un changement ici est remplacé à la prochaine synchronisation.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Refusé sur le kiosque';

  @override
  String get fleetWaitingForItsOk => 'En attente de son accord';

  @override
  String get fleetLeftTheFleet => 'A quitté la flotte';

  @override
  String fleetSendingPercent(String percent) {
    return 'Envoi $percent %';
  }

  @override
  String get fleetInstalling => 'Installation';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Exécute $version, ce kiosque a besoin d\'une mise à jour';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Nécessite $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Téléchargement $percent %';
  }

  @override
  String get fleetSyncing => 'Synchronisation…';

  @override
  String get fleetErrorUnreachable => 'Injoignable';

  @override
  String get fleetErrorBadAnswer => 'Réponse invalide';

  @override
  String get fleetErrorThePushFailed => 'L\'envoi a échoué';

  @override
  String get fleetErrorLeadThisFleetIsOff =>
      'Diriger cette flotte est désactivé';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'L\'administration à distance et Trouver d\'autres kiosques doivent être activés';

  @override
  String get fleetErrorPickAnotherKiosk => 'Choisissez un autre kiosque';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Ce kiosque n\'est pas sur le réseau actuellement';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Ce kiosque n\'a pas répondu';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Ce kiosque a refusé l\'invitation';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'Le profil Par défaut est conservé';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'Le profil Mises à jour uniquement est conservé';

  @override
  String get fleetErrorNoSuchProfile => 'Ce profil n\'existe pas';

  @override
  String get fleetErrorNoSuchFollower => 'Ce suiveur n\'existe pas';

  @override
  String get fleetErrorNoInvitationIsWaiting => 'Aucune invitation en attente';

  @override
  String get fleetErrorMalformedInvitation => 'Invitation malformée';

  @override
  String get fleetErrorCouldNotMintAToken => 'Impossible de générer un jeton';

  @override
  String get fleetErrorNotAFollowerYet => 'pas encore un suiveur';

  @override
  String get fleetErrorOffline => 'hors ligne';

  @override
  String get fleetErrorUpToDate => 'à jour';

  @override
  String get fleetErrorAlreadyDownloading => 'téléchargement déjà en cours';

  @override
  String get fleetErrorDidNotAnswer => 'n\'a pas répondu';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'n\'a pas accepté l\'envoi';

  @override
  String fleetProfileNameExists(String name) {
    return 'Un profil nommé $name existe déjà';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'déjà en version $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Ce kiosque utilise une version sans gestion de flotte. Il pourra rejoindre la flotte lorsqu\'il sera mis à jour.';

  @override
  String get fleetErrorAddressMismatch =>
      'Cette adresse appartient à un autre kiosque ou à une autre flotte';

  @override
  String get fleetErrorInvalidIp => 'Saisissez une adresse IP valide.';

  @override
  String get fleetErrorInvalidPort => 'Saisissez un port entre 1 et 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'L\'identité de ce kiosque n\'est pas encore prête. Réessayez.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Cette adresse n\'a pas renvoyé d\'identité de kiosque valide.';

  @override
  String get fleetErrorAlreadyMember =>
      'Ce kiosque appartient déjà à cette flotte.';

  @override
  String get fleetErrorIsLeader => 'Ce kiosque dirige une flotte.';

  @override
  String get fleetErrorOtherLeader => 'Ce kiosque suit déjà un autre leader.';

  @override
  String get fleetSwitchKiosk => 'Changer de kiosque';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Kiosques détectés et membres de flotte enregistrés. En choisir un ouvre son administration à distance ici, sur cette même page.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'Aucun autre kiosque trouvé. Les kiosques apparaissent via la découverte réseau ou l\'appartenance enregistrée à une flotte.';

  @override
  String get fleetSyncedCredentials => 'Identifiants synchronisés';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Les paramètres de cette liste ne seront pas synchronisés avec les suiveurs.';

  @override
  String get fleetNothingLeftOut => 'Rien n\'est exclu';

  @override
  String get fleetSyncItAgain => 'Le resynchroniser';

  @override
  String get fleetAddASetting => 'Ajouter un paramètre';

  @override
  String get fleetExcludeASetting => 'Exclure un paramètre';

  @override
  String get fleetSearchSettings => 'Rechercher des paramètres';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '$count de plus. Tapez pour affiner la liste.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'Non synchronisé : $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'le satellite assigné';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'périphériques microphone et haut-parleur, gain du micro';

  @override
  String get fleetTheDeviceCamera => 'la caméra de l\'appareil';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'le lecteur suivi, l\'identifiant du lecteur Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'nom du nœud, MAC, clé de chiffrement';

  @override
  String get fleetThePinIsAlsoSynced => 'le code PIN est également synchronisé';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'la clé, sauf si synchronisée comme identifiant';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'nom, administration à distance, contournements de rendu, échelle';

  @override
  String get fleetHomeAssistantToken => 'Jeton Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'Jeton Music Assistant';

  @override
  String get fleetImmichApiKey => 'Clé API Immich';

  @override
  String get fleetUpdateTheFleet => 'Mettre à jour la flotte';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Mettre à jour toute la flotte vers la version de Kiosk Satellite exécutée sur le leader.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Garder les suiveurs sur cette version';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Mettre automatiquement à jour tous les suiveurs vers la version de Kiosk Satellite exécutée sur le leader.';

  @override
  String get fleetNothingToUpdate => 'Rien à mettre à jour';

  @override
  String get fleetUpdating => 'Mise à jour en cours';

  @override
  String fleetNamesInstalling(String names) {
    return '$names en cours d\'installation.';
  }

  @override
  String get fleetSearchUpdates =>
      'Installer la version proposée à chaque suiveur, puis sur ce kiosque.';

  @override
  String get gestureAction => 'Action';

  @override
  String get gestureNavigate => 'Aller à une vue du tableau de bord';

  @override
  String get gestureUrl => 'Ouvrir une page web';

  @override
  String get gestureCameraView => 'Afficher une vue caméra';

  @override
  String get gestureLauncher => 'Ouvrir le lanceur d\'applications';

  @override
  String get gestureIntercomOpen => 'Ouvrir Appeler un kiosque';

  @override
  String get gestureIntercomCall => 'Appeler un kiosque';

  @override
  String get gestureScreensaver => 'Démarrer l\'économiseur d\'écran';

  @override
  String get gestureScreensaverStop => 'Arrêter l\'économiseur d\'écran';

  @override
  String get gestureHoldMode => 'Basculer le mode maintien';

  @override
  String get gestureHaKiosk => 'Basculer le mode kiosque HA';

  @override
  String get gesturePluginRun => 'Exécuter une action de plugin';

  @override
  String get gestureLaunchApp => 'Ouvrir une autre application';

  @override
  String get gestureDeepLink => 'Ouvrir un lien profond';

  @override
  String get gestureAndroidSettings => 'Ouvrir les paramètres Android';

  @override
  String get gestureService => 'Appeler un service';

  @override
  String get gestureScript => 'Exécuter un script';

  @override
  String get gestureAutomation => 'Déclencher une automatisation';

  @override
  String get gestureEvent => 'Déclencher un événement';

  @override
  String get gesturePluginAction => 'Action de plugin';

  @override
  String get gesturePluginActions => 'Actions de plugin';

  @override
  String get gesturePluginHelp =>
      'Activez d\'abord un plugin proposant des actions dans le Gestionnaire de plugins.';

  @override
  String get gesturePluginFailed =>
      'Impossible de charger les actions de plugin.';

  @override
  String get gestureUrlError => 'Saisissez une URL http(s) complète.';

  @override
  String get gesturePackage => 'Nom du package';

  @override
  String get gesturePackageError => 'Saisissez un nom de package.';

  @override
  String get gestureUriError => 'Saisissez un URI complet.';

  @override
  String get gestureNoDashboards => 'Aucun tableau de bord';

  @override
  String get gestureDashboardsFailed =>
      'Impossible de lister les tableaux de bord';

  @override
  String get gestureHaConnected => 'Home Assistant est-il connecté ?';

  @override
  String get gestureDashboardsHelp =>
      'Impossible de lister les tableaux de bord. Home Assistant est-il connecté ?';

  @override
  String get gestureCameraTitle => 'Vue caméra';

  @override
  String gestureCameraShow(String name) {
    return 'Afficher $name';
  }

  @override
  String get gestureCameraClose => 'Fermer la vue caméra';

  @override
  String get gestureCameraEmpty =>
      'Aucune vue caméra configurée pour l\'instant.';

  @override
  String get gestureIntercomEmpty =>
      'Aucun kiosque trouvé sur le réseau pour l\'instant.';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count appuis dans le coin $corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Maintenir le coin $corner pendant $seconds s';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Double appui à $count doigts';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Appui à $count doigts';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Maintien à $count doigts pendant $seconds s';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Séquence de coins : $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count claquements de mains';
  }

  @override
  String get gestureDescribeOpenHand => 'Montrer une main ouverte';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Montrer $count doigt';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Montrer $count doigts';
  }

  @override
  String get gestureTopLeft => 'en haut à gauche';

  @override
  String get gestureTopRight => 'en haut à droite';

  @override
  String get gestureBottomLeft => 'en bas à gauche';

  @override
  String get gestureBottomRight => 'en bas à droite';

  @override
  String gestureGoTo(String value) {
    return 'Aller à $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Ouvrir $value';
  }

  @override
  String get gestureCameraToggle => 'Basculer la vue caméra';

  @override
  String gestureCameraToggleName(String name) {
    return 'Basculer la vue caméra $name';
  }

  @override
  String gestureCall(String value) {
    return 'Appeler $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Ouvrir l\'application $package';
  }

  @override
  String gestureRun(String value) {
    return 'Exécuter $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Déclencher $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Déclencher l\'événement $value';
  }

  @override
  String get gestureValid => 'Tout semble correct.';

  @override
  String get gestureValidationFailed => 'Impossible de valider.';

  @override
  String gestureDomainMissing(String value) {
    return 'Domaine $value introuvable.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'Service $value introuvable.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'Entité $value introuvable.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Saisissez une entité $domain.*.';
  }

  @override
  String get gestureScriptEntity => 'Entité de script';

  @override
  String get gestureAutomationEntity => 'Entité d\'automatisation';

  @override
  String get gestureDomain => 'Domaine';

  @override
  String get gestureEntityOptional => 'Entité (facultative)';

  @override
  String get gestureServiceData => 'Données du service (facultatives)';

  @override
  String get gestureServiceTitle => 'Appeler un service Home Assistant';

  @override
  String get gestureServiceRequired => 'Le domaine et le service sont requis.';

  @override
  String get gestureServiceJson =>
      'Les données du service doivent être un objet JSON.';

  @override
  String get gestureEventType => 'Type d\'événement';

  @override
  String get gestureEventData => 'Données de l\'événement (facultatives)';

  @override
  String get gestureEventTitle => 'Déclencher un événement Home Assistant';

  @override
  String get gestureEventRequired => 'Le type d\'événement est requis.';

  @override
  String get gestureEventJson =>
      'Les données de l\'événement doivent être un objet JSON.';

  @override
  String get gestureTester => 'Testeur de gestes de la main';

  @override
  String get gestureOpenTester => 'Ouvrir le testeur';

  @override
  String get gestureCameraFirst =>
      'Activez d\'abord la caméra dans les paramètres Caméra.';

  @override
  String get gestureTesterHelp =>
      'Observez quels doigts la caméra détecte, pour apprendre à positionner votre main.';

  @override
  String get gestureHandHelp =>
      'Levez la main à hauteur d\'épaule, paume face à la caméra, doigts écartés. Repliez complètement un doigt pour le retirer du décompte. Repliez le pouce contre la paume pour afficher quatre : le pouce ne compte que main ouverte.';

  @override
  String get gestureTesterPaused =>
      'Les gestes ne se déclenchent pas tant que le testeur est ouvert.';

  @override
  String get gestureShowHand => 'Montrez une main à la caméra.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Déclenche : $action';
  }

  @override
  String get gestureNoCount => 'Aucun geste n\'utilise ce nombre.';

  @override
  String get gestureNoHand => 'Aucune main visible';

  @override
  String get gestureReadingHand => 'Lecture de la main';

  @override
  String get gestureNoFingers => 'Aucun doigt levé';

  @override
  String gestureHandsCount(String count) {
    return '$count mains visibles, lecture de la plus grande.';
  }

  @override
  String get gestureTesterSearch =>
      'Un aperçu en direct des doigts que la caméra détecte.';

  @override
  String get gestureHoldConfirmed => 'Maintien confirmé';

  @override
  String gestureHoldProgress(String progress) {
    return 'Progression du maintien : $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Durée de maintien : $duration';
  }

  @override
  String get gestureHaServiceKind => 'Service Home Assistant';

  @override
  String get gestureHaScriptKind => 'Script Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Automatisation Home Assistant';

  @override
  String get gestureHaEventKind => 'Événement Home Assistant';

  @override
  String gestureRan(String value) {
    return '$value exécuté';
  }

  @override
  String gestureRunFailed(String value) {
    return 'Impossible d\'exécuter $value';
  }

  @override
  String gestureCalled(String value) {
    return '$value appelé';
  }

  @override
  String gestureCallFailed(String value) {
    return 'Impossible d\'appeler $value';
  }

  @override
  String gestureTriggered(String value) {
    return '$value déclenché';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'Impossible de déclencher $value';
  }

  @override
  String gestureFired(String value) {
    return 'Événement $value déclenché';
  }

  @override
  String gestureFireFailed(String value) {
    return 'Impossible de déclencher l\'événement $value';
  }

  @override
  String get gestureDone => 'Terminé';

  @override
  String get gestureFailed => 'Échec';

  @override
  String get gestureEdit => 'Modifier le geste';

  @override
  String get gestureTrigger => 'Geste';

  @override
  String get gestureCornerTaps => 'Appuis dans un coin';

  @override
  String get gestureCornerHold => 'Maintenir un coin';

  @override
  String get gestureFingerTaps => 'Appui à plusieurs doigts';

  @override
  String get gestureFingerHold => 'Maintien à plusieurs doigts';

  @override
  String get gestureSequence => 'Séquence de coins';

  @override
  String get gestureClaps => 'Claquements de mains';

  @override
  String get gestureShowFingers => 'Montrer des doigts';

  @override
  String get gestureCorner => 'Coin';

  @override
  String get gestureCornerTl => 'Coin supérieur gauche';

  @override
  String get gestureCornerTr => 'Coin supérieur droit';

  @override
  String get gestureCornerBl => 'Coin inférieur gauche';

  @override
  String get gestureCornerBr => 'Coin inférieur droit';

  @override
  String get gestureTaps => 'Appuis';

  @override
  String get gestureTaps2 => '2 appuis';

  @override
  String get gestureTaps3 => '3 appuis';

  @override
  String get gestureTaps4 => '4 appuis';

  @override
  String get gestureFingers => 'Doigts';

  @override
  String get gestureFinger1 => '1 doigt';

  @override
  String get gestureFinger2 => '2 doigts';

  @override
  String get gestureFinger3 => '3 doigts';

  @override
  String get gestureFinger4 => '4 doigts';

  @override
  String get gestureOpenHand5 => 'Main ouverte (5)';

  @override
  String get gestureSingleTap => 'Appui simple';

  @override
  String get gestureDoubleTap => 'Double appui';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Maintenir $seconds s';
  }

  @override
  String get gestureCameraHelp =>
      'Nécessite la caméra activée et un environnement bien éclairé.';

  @override
  String get gestureUnavailable => 'Non disponible sur cet appareil.';

  @override
  String get gestureClaps2 => '2 claquements de mains';

  @override
  String get gestureClaps3 => '3 claquements de mains';

  @override
  String get gestureClaps4 => '4 claquements de mains';

  @override
  String get gestureClapHelp =>
      'Les claquements sont entendus via le microphone, avec ou sans détection du mot de réveil.';

  @override
  String get gestureSequenceHelp =>
      'Appuyez sur les coins dans l\'ordre (2 à 8 étapes).';

  @override
  String get gestureRemoveStep => 'Supprimer la dernière étape';

  @override
  String get gestureUndo => 'Annuler';

  @override
  String get gestureChooseAction => 'Choisir une action';

  @override
  String get gestureActionHelp => 'Ce que ce geste déclenche.';

  @override
  String get gestureChangeHelp => 'Appuyez pour changer.';

  @override
  String get gestureChooseError => 'Choisissez une action.';

  @override
  String get gestureSequenceError => 'Ajoutez au moins deux coins.';

  @override
  String get intercomCall => 'Appeler';

  @override
  String get intercomNoReady => 'Aucun kiosque n\'est prêt.';

  @override
  String get intercomOneReady => '1 kiosque est prêt.';

  @override
  String intercomManyReady(String count) {
    return '$count kiosques sont prêts.';
  }

  @override
  String get intercomCallKiosk => 'Appeler un kiosque';

  @override
  String get intercomAnnounceAll => 'Annoncer à tous';

  @override
  String get intercomAnnounceHelp =>
      'Parler à tous les kiosques. Dans un seul sens.';

  @override
  String intercomMissedFrom(String name) {
    return 'Appel manqué de $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'A sonné pendant $seconds secondes.';
  }

  @override
  String get intercomCallBack => 'Rappeler';

  @override
  String get intercomDeclined => 'Refusé';

  @override
  String get intercomBusy => 'Occupé';

  @override
  String get intercomPeerOff => 'Son interphone est désactivé';

  @override
  String get intercomPeerKey => 'Clé d\'interphone différente';

  @override
  String get intercomNoAnswer => 'Pas de réponse';

  @override
  String get intercomDidNotAnswer => 'N\'a pas répondu';

  @override
  String get intercomVoiceFailed => 'La liaison vocale a échoué';

  @override
  String get intercomCancelled => 'Annulé';

  @override
  String get intercomPageMic => 'La page a pris le microphone';

  @override
  String get intercomNobody => 'Personne n\'a pu répondre';

  @override
  String get intercomDone => 'Terminé';

  @override
  String get intercomEnded => 'Appel terminé';

  @override
  String get intercomAnnouncement => 'Annonce';

  @override
  String get intercomAnnouncingOne => 'Annonce à 1 kiosque';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Annonce à $count kiosques';
  }

  @override
  String get intercomIsCalling => 'appelle';

  @override
  String get intercomIsAnnouncing => 'fait une annonce';

  @override
  String get intercomCalling => 'Appel en cours…';

  @override
  String intercomAnswersIn(String seconds) {
    return 'Réponse dans $seconds s';
  }

  @override
  String get intercomRinging => 'Sonnerie en cours';

  @override
  String get intercomConnecting => 'Connexion…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Terminé, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Appel terminé, $duration';
  }

  @override
  String get intercomDecline => 'Refuser';

  @override
  String get intercomAnswer => 'Répondre';

  @override
  String get intercomEveryKiosk => 'Tous les kiosques';

  @override
  String get intercomStop => 'Arrêter';

  @override
  String intercomHearsYou(String name) {
    return '$name vous entend';
  }

  @override
  String get intercomAllHearYou => 'Tous les kiosques vous entendent';

  @override
  String get intercomHoldHelp => 'Maintenez pour parler, relâchez pour écouter';

  @override
  String get intercomMuted => 'Coupé';

  @override
  String get intercomMute => 'Couper';

  @override
  String get intercomEnd => 'Terminer';

  @override
  String get intercomReply => 'Répondre';

  @override
  String get intercomDismiss => 'Ignorer';

  @override
  String get intercomCallAgain => 'Rappeler';

  @override
  String get intercomDashboardMic =>
      'Le tableau de bord occupe le microphone, écoute uniquement.';

  @override
  String get intercomMicDenied => 'Microphone non accordé, écoute uniquement.';

  @override
  String get intercomHoldTalk => 'Maintenez pour parler';

  @override
  String get intercomPlaying => 'Lecture en cours';

  @override
  String get intercomAKiosk => 'un kiosque';

  @override
  String intercomCallingName(String name) {
    return 'Appel vers $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name appelle';
  }

  @override
  String intercomInCallName(String name) {
    return 'En communication avec $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name fait une annonce';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant : $message';
  }

  @override
  String get intercomEndCall => 'Terminer l\'appel';

  @override
  String get intercomCallFailed => 'Impossible d\'appeler';

  @override
  String get intercomKeyFailed => 'Impossible de changer la clé';

  @override
  String get intercomBroadcastFailed => 'Impossible de parler à tout le monde';

  @override
  String get intercomDeviceNoAnswer => 'L\'appareil n\'a pas répondu.';

  @override
  String get intercomUnknownKiosk => 'kiosque inconnu';

  @override
  String get intercomNothingRinging => 'rien ne sonne';

  @override
  String get intercomNoCall => 'aucun appel';

  @override
  String get intercomDisabled => 'l\'interphone est désactivé';

  @override
  String get intercomNeedsRemote => 'nécessite l\'administration à distance';

  @override
  String get intercomNeedsDiscovery =>
      'l\'interphone nécessite l\'administration à distance et Trouver d\'autres kiosques';

  @override
  String get intercomAlreadyCalling => 'déjà en communication';

  @override
  String get intercomNoReadyError => 'aucun kiosque n\'est prêt';

  @override
  String get intercomKeyLength =>
      'une clé doit comporter au moins 16 caractères';

  @override
  String get intercomMicHeld => 'la page occupe le microphone';

  @override
  String get intercomMicPermission => 'microphone non accordé';

  @override
  String get intercomCallerNoAnswer => 'l\'appelant n\'a pas répondu';

  @override
  String get intercomMissedcall => 'Appel manqué';

  @override
  String get intercomListening => 'En écoute';

  @override
  String get intercomAnnouncementsoff => 'Annonces désactivées';

  @override
  String get intercomEncryptionMismatch => 'Chiffrement incompatible';

  @override
  String get intercomEncryptionMismatchHelp =>
      'Les paramètres de chiffrement ne correspondent pas. Activez Chiffrer les communications sur tous les kiosques participant à l’appel.';

  @override
  String get kioskBackClose =>
      'Appuyez à nouveau sur retour pour fermer l\'application';

  @override
  String get kioskBackAgain =>
      'Appuyez à nouveau sur retour pour revenir en arrière';

  @override
  String get kioskHoldOn => 'Mode maintien activé';

  @override
  String get kioskHoldOff => 'Mode maintien désactivé';

  @override
  String get kioskHoldNotice =>
      'La vue actuelle reste affichée jusqu\'à la désactivation du mode.';

  @override
  String get kioskDownloadComplete => 'Téléchargement terminé';

  @override
  String get kioskDownloadFailed => 'Échec du téléchargement';

  @override
  String get kioskDownload => 'Télécharger';

  @override
  String get kioskDownloading => 'Téléchargement en cours';

  @override
  String get kioskOpen => 'Ouvrir';

  @override
  String get kioskTip => 'Astuce';

  @override
  String get kioskMenuHint =>
      'Balayez depuis le bord gauche pour ouvrir le menu.';

  @override
  String get kioskUnknownLink => 'Lien de kiosque inconnu';

  @override
  String get kioskOpenAppFailed => 'Impossible d\'ouvrir l\'application';

  @override
  String get kioskWebViewMissing =>
      'Android System WebView n\'est pas installé';

  @override
  String get kioskWebViewMissingHelp =>
      'Cet appareil n\'a pas de fournisseur WebView, Home Assistant ne peut donc pas être affiché. Installez Android System WebView ou Chrome, puis redémarrez Kiosk Satellite.';

  @override
  String get kioskPinTitle => 'Code PIN du kiosque';

  @override
  String get kioskPinHint => 'Code PIN';

  @override
  String get kioskWrongPin => 'Code PIN incorrect';

  @override
  String get kioskUnlock => 'Déverrouiller';

  @override
  String get lockdownScreenLocked => 'L\'écran est verrouillé';

  @override
  String get logsWebConsole => 'Console web';

  @override
  String get logsDock => 'Ancrer par-dessus la page en direct';

  @override
  String get logsNoOutput => 'Aucune sortie console pour l\'instant';

  @override
  String get logsShareSubject => 'Journal de la console Kiosk Satellite';

  @override
  String get logsInput => 'Exécuter du JavaScript dans la page';

  @override
  String get logsInputHistory =>
      'Exécuter du JavaScript dans la page (Entrée pour exécuter, Haut/Bas pour l\'historique)';

  @override
  String get logsRun => 'Exécuter';

  @override
  String get logsEvaluationFailed => 'échec de l\'évaluation';

  @override
  String get logsDeviceUnreachable => 'appareil injoignable';

  @override
  String logsEntries(String count) {
    return '$count entrées';
  }

  @override
  String get logsCopyLog => 'Copier le journal';

  @override
  String get logsShareLog => 'Partager le journal';

  @override
  String get logsCopied => 'Copié';

  @override
  String get logsCopyFailed => 'Impossible de copier';

  @override
  String get logsOnClipboard => 'Le journal est dans le presse-papiers.';

  @override
  String get logsConsoleOnClipboard =>
      'Le journal de la console est dans le presse-papiers.';

  @override
  String get logsSystemLog =>
      'Journal système Android pour cette application (les plantages s\'y trouvent)';

  @override
  String get logsErrors => 'Erreurs et plantages';

  @override
  String get logsWarnings => 'Avertissements';

  @override
  String get logsInfo => 'Info et débogage';

  @override
  String get logsNoMatches =>
      'Aucune ligne correspondante. Activez plus de types ci-dessus pour voir le journal complet.';

  @override
  String get logsUnavailable => 'logcat indisponible';

  @override
  String logsReadFailed(String error) {
    return 'Impossible de lire logcat : $error';
  }

  @override
  String get logsUnknown => 'inconnu';

  @override
  String get offlineDashboard => 'Tableau de bord indisponible';

  @override
  String get offlineNetwork => 'Aucune connexion réseau';

  @override
  String get offlinePageHelp => 'La page n\'a pas pu être chargée.';

  @override
  String get offlineNetworkHelp =>
      'Le tableau de bord reviendra dès que le réseau sera de retour.';

  @override
  String get offlineLost => 'Connexion réseau perdue';

  @override
  String get offlineRestored => 'Connexion réseau rétablie';

  @override
  String get mediaPlay => 'Lecture';

  @override
  String get mediaPause => 'Pause';

  @override
  String get mediaPreviousTrack => 'Morceau précédent';

  @override
  String get mediaNextTrack => 'Morceau suivant';

  @override
  String get mediaPlaying => 'En cours de lecture';

  @override
  String get mediaPaused => 'En pause';

  @override
  String get mediaIdle => 'Inactif';

  @override
  String get mediaStatusUnavailable => 'État indisponible';

  @override
  String get mediaUnknownTrack => 'Morceau inconnu';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Afficher le volume';

  @override
  String get mediaHideVolume => 'Masquer le volume';

  @override
  String get mediaMute => 'Couper le son';

  @override
  String get mediaUnmute => 'Rétablir le son';

  @override
  String get mediaFavoriteAdd => 'Ajouter aux favoris';

  @override
  String get mediaFavoriteRemove => 'Retirer des favoris';

  @override
  String get mediaShuffleOn => 'Activer la lecture aléatoire';

  @override
  String get mediaShuffleOff => 'Désactiver la lecture aléatoire';

  @override
  String get mediaRepeatAll => 'Tout répéter';

  @override
  String get mediaRepeatOne => 'Répéter un morceau';

  @override
  String get mediaRepeatOff => 'Désactiver la répétition';

  @override
  String get mediaShowLyrics => 'Afficher les paroles';

  @override
  String get mediaHideLyrics => 'Masquer les paroles';

  @override
  String get mediaShowQueue => 'Afficher la file d\'attente';

  @override
  String get mediaHideQueue => 'Masquer la file d\'attente';

  @override
  String get mediaVolume => 'Volume';

  @override
  String get mediaPlaybackPosition => 'Position de lecture';

  @override
  String get mediaShowNowPlaying => 'Afficher Lecture en cours';

  @override
  String get mediaShowFloatingPlayer => 'Afficher le lecteur flottant';

  @override
  String get mediaOpenMusicAssistant => 'Ouvrir Music Assistant';

  @override
  String get mediaCannotControl =>
      'commande non prise en charge ou non envoyée';

  @override
  String get mediaNothingQueued => 'Rien dans la file d\'attente';

  @override
  String get mediaChapters => 'Chapitres';

  @override
  String get mediaNowPlaying => 'Lecture en cours';

  @override
  String get mediaUpNext => 'À suivre';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Chapitre $number';
  }

  @override
  String get mediaGroupLead => 'Dirige le groupe';

  @override
  String get mediaGroupReadFailed => 'Le groupe n\'a pas pu être lu.';

  @override
  String get mediaGroupEmpty =>
      'Aucun autre lecteur avec lequel former un groupe.';

  @override
  String get mediaSpeakerSelection => 'Sélection des enceintes';

  @override
  String pluginCloseWindow(String name) {
    return 'Fermer $name';
  }

  @override
  String get pluginActions => 'Actions';

  @override
  String get pluginKioskDrawer => 'Tiroir du kiosque';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Pour assigner un geste, ouvrez Gestes et choisissez Exécuter une action de plugin.';

  @override
  String get pluginShowInKioskDrawer => 'Afficher dans le tiroir du kiosque';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'Également disponible en mode verrouillé si le tiroir du kiosque est autorisé.';

  @override
  String get pluginExposeToHomeAssistant => 'Exposer à Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Ajoute un bouton à l\'appareil ESPHome du kiosque. Nécessite ESPHome et les entités natives.';

  @override
  String get pluginSelectAnEntity => 'Sélectionner une entité';

  @override
  String pluginChooseName(String name) {
    return 'Choisir $name';
  }

  @override
  String pluginConfigureName(String name) {
    return 'Configurer $name';
  }

  @override
  String get pluginPlugin => 'Plugin';

  @override
  String get pluginEnablePlugins => 'Activer les plugins';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Les plugins ajoutent des fonctionnalités supplémentaires développées par la communauté à Kiosk Satellite.';

  @override
  String get pluginInstalledPlugins => 'Plugins installés';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'Aucun plugin installé. Ajoutez un dépôt pour commencer.';

  @override
  String get pluginDeveloperTools => 'Outils de développement';

  @override
  String get pluginCreateAPlugin => 'Créer un plugin';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Apprenez à créer des plugins avec le modèle Hello World et la documentation.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Ce plugin n\'est plus installé.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Activez Plugins pour exécuter ce plugin.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Activez ce plugin depuis sa ligne pour l\'exécuter.';

  @override
  String pluginUninstallName(String name) {
    return 'Désinstaller $name ?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Désinstaller $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Vérifier les mises à jour pour $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'À propos de $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Ceci supprime le plugin et ses paramètres.';

  @override
  String get pluginUninstall => 'Désinstaller';

  @override
  String get pluginNoUpdatesAvailable => 'Aucune mise à jour disponible.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Ce plugin a été installé depuis un ZIP et n\'a pas de README de dépôt.';

  @override
  String get pluginImageUnavailable => 'Image indisponible';

  @override
  String get pluginCouldNotOpenThisLink => 'Impossible d\'ouvrir ce lien.';

  @override
  String pluginEnableName(String name) {
    return 'Activer $name';
  }

  @override
  String get pluginAddPlugin => 'Ajouter un plugin';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Installer depuis un dépôt GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Assurez-vous de faire confiance à l\'auteur du plugin et à son code avant de l\'installer.';

  @override
  String get pluginPreview => 'Aperçu';

  @override
  String get pluginInstalledVersion => 'Version installée';

  @override
  String get pluginAuthor => 'Auteur';

  @override
  String get pluginLicense => 'Licence';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Les plugins exécutent du code à l\'intérieur de Kiosk Satellite et peuvent accéder aux données de l\'application et aux autorisations Android accordées. Un plugin défectueux ou malveillant peut exposer des informations privées ou empêcher l\'application de fonctionner. N\'installez que des plugins d\'auteurs auxquels vous faites confiance.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Les nouveaux plugins démarrent désactivés. Les mises à jour préservent l\'état d\'activation et redémarrent automatiquement les plugins en cours d\'exécution.';

  @override
  String get pluginTrustAndUpdate => 'Faire confiance et mettre à jour';

  @override
  String get pluginTrustAndInstall => 'Faire confiance et installer';

  @override
  String get pluginInstallFromZip => 'Installer depuis un ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Pour les développeurs uniquement : tester un build local';

  @override
  String get pluginPluginZip => 'ZIP du plugin';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'Le ZIP du plugin doit faire 4 Mo maximum';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'Impossible de lire le ZIP sélectionné';

  @override
  String get pluginCharts => 'Graphiques';

  @override
  String get pluginReadings => 'Relevés';

  @override
  String get pluginWaitingForSamples => 'En attente d\'échantillons';

  @override
  String get pluginLatest => 'Dernier';

  @override
  String get pluginSelected => 'Sélectionné';

  @override
  String get pluginNoDataYet => 'Pas encore de données';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Appuyez ou faites glisser pour inspecter les échantillons. Appuyez deux fois pour suivre le plus récent.';

  @override
  String get pluginNoData => 'Aucune donnée';

  @override
  String get pluginOn => 'Activé';

  @override
  String get pluginEmpty => 'Vide';

  @override
  String get pluginChartKeyboardHelp =>
      'Utilisez les touches fléchées pour inspecter les échantillons et Fin pour le plus récent.';

  @override
  String get pluginErrorAssetPath => 'Chemin de ressource invalide';

  @override
  String get pluginErrorAssetMissing =>
      'La ressource est manquante ou hors de son paquet';

  @override
  String get pluginErrorAssetSymlink =>
      'Le dossier de ressource ne peut pas être un lien symbolique';

  @override
  String get pluginErrorAssetSymlinks =>
      'Les dossiers de ressources ne peuvent pas être des liens symboliques';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Les ressources installées ont échoué à leur vérification d\'intégrité';

  @override
  String get pluginErrorAssetIntegrity =>
      'La ressource installée a échoué à sa vérification d\'intégrité';

  @override
  String get pluginErrorManifestMismatch =>
      'Le manifeste du paquet ne correspond pas au manifeste de la version examinée';

  @override
  String get pluginErrorStagingExists =>
      'Le dossier de préparation existe déjà';

  @override
  String get pluginErrorCreateDirectory =>
      'Impossible de créer le dossier du plugin';

  @override
  String get pluginErrorFileCount =>
      '512 fichiers de paquet maximum sont pris en charge';

  @override
  String get pluginErrorProtectFile =>
      'Impossible de protéger le fichier du plugin';

  @override
  String get pluginErrorExpandedSize => 'Le plugin décompressé dépasse 4 Mo';

  @override
  String get pluginErrorManifestSize => 'Le manifeste dépasse 32 Ko';

  @override
  String get pluginErrorRequiredFiles =>
      'Le paquet nécessite kiosk-satellite-plugin.json, plugin.jar et LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Les bibliothèques natives nécessitent la fonctionnalité native';

  @override
  String get pluginErrorNativeElf => 'Bibliothèque native ELF invalide';

  @override
  String get pluginErrorNativeAbi =>
      'L\'ABI de la bibliothèque native ne correspond pas à son dossier';

  @override
  String get pluginErrorDexOnly =>
      'plugin.jar ne doit contenir que des fichiers DEX';

  @override
  String get pluginErrorDexHeader => 'En-tête DEX invalide';

  @override
  String get pluginErrorDexSize => 'Le fichier DEX décompressé dépasse 4 Mo';

  @override
  String get pluginErrorDexEmpty => 'Fichier DEX vide';

  @override
  String get pluginErrorDexMissing =>
      'plugin.jar ne contient pas de classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Entrée ZIP inattendue ou en double : $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'La version du dépôt appartient à un plugin différent.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Saisissez une URL publique https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Utilisez l\'URL du dépôt sans chemin de fichier ou de branche';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'Le téléchargement du plugin a été redirigé hors de GitHub';

  @override
  String get pluginErrorInvalidRedirect => 'Redirection GitHub invalide';

  @override
  String get pluginErrorRepositoryNotFound =>
      'Dépôt public, version stable, kiosk-satellite-plugin.json, README.md ou ressource de version introuvable.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub a refusé la requête ou sa limite de requêtes a été atteinte. Réessayez plus tard.';

  @override
  String get pluginErrorRepositorySize =>
      'Le fichier du dépôt dépasse la limite de taille';

  @override
  String get pluginErrorTooManyRedirects => 'Trop de redirections GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub n\'a pas renvoyé de version stable publiée';

  @override
  String get pluginErrorReleaseTag => 'Étiquette de version invalide';

  @override
  String get pluginErrorManifestFile =>
      'Manifeste kiosk-satellite-plugin.json invalide';

  @override
  String get pluginErrorIdVersion =>
      'Identifiant ou version de plugin invalide';

  @override
  String get pluginErrorChecksumFilename =>
      'Somme de contrôle ou nom de fichier de version invalide';

  @override
  String get pluginErrorGithubDigest =>
      'La somme de contrôle de la version doit correspondre à l\'empreinte SHA-256 de la ressource GitHub';

  @override
  String get pluginErrorTagRevision =>
      'GitHub n\'a pas renvoyé la révision de l\'étiquette de version';

  @override
  String get pluginErrorTrustAuthor =>
      'Confirmez que vous faites confiance à l\'auteur du plugin';

  @override
  String get pluginErrorPreviewExpired =>
      'Cet aperçu a expiré. Prévisualisez à nouveau le dépôt avant d\'installer.';

  @override
  String get pluginErrorReviewedChecksum =>
      'Le SHA-256 du paquet ne correspond pas à la version examinée';

  @override
  String get pluginErrorNotInstalled => 'Le plugin n\'est pas installé';

  @override
  String get pluginErrorUpdateZip =>
      'Ce plugin a été installé depuis un ZIP. Utilisez Installer depuis ZIP pour le mettre à jour.';

  @override
  String get pluginErrorAndroidOnly =>
      'Les plugins sont disponibles sous Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'La requête GitHub a échoué ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'La version doit avoir exactement une ressource $name envoyée';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'La ressource de version $name doit être publiée par GitHub Actions. Les fichiers envoyés manuellement ne sont pas pris en charge.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'La ressource de version $name dépasse la limite de taille ou est vide';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'URL de version invalide pour $name';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'Le plugin n\'a pas de bibliothèque native pour l\'ABI de cet appareil';

  @override
  String get pluginErrorCallbackTimeout =>
      'Le rappel du plugin a expiré. Redémarrez Kiosk si le plugin a laissé un travail en cours.';

  @override
  String get pluginErrorEnableFirst => 'Activez d\'abord le plugin';

  @override
  String get pluginErrorSaveState =>
      'Impossible d\'enregistrer l\'état du plugin';

  @override
  String get pluginErrorPackageHash => 'Empreinte du paquet installé invalide';

  @override
  String get pluginErrorChecksum => 'Le SHA-256 du paquet ne correspond pas';

  @override
  String get pluginErrorDifferentRepository =>
      'Cet identifiant de plugin appartient à un autre dépôt. Désinstallez-le avant de changer de source.';

  @override
  String get pluginErrorRestartReplace =>
      'Ce plugin ne s\'est pas arrêté proprement. Redémarrez Kiosk Satellite avant de le remplacer.';

  @override
  String get pluginErrorPluginLimit =>
      '8 plugins maximum peuvent être installés';

  @override
  String get pluginErrorAlreadyInstalled => 'Ce paquet est déjà installé';

  @override
  String get pluginErrorLoadedIntegrity =>
      'Le paquet précédemment chargé a échoué à sa vérification d\'intégrité. Redémarrez Kiosk Satellite avant de le réinstaller.';

  @override
  String get pluginErrorRemovePackage =>
      'Impossible de supprimer le paquet inutilisé';

  @override
  String get pluginErrorInstallPackage =>
      'Impossible d\'installer le paquet du plugin';

  @override
  String get pluginErrorUpdateCanceled =>
      'Mise à jour annulée car le plugin ne s\'est pas arrêté proprement. Redémarrez Kiosk Satellite avant de réessayer.';

  @override
  String get pluginErrorVersionRetained =>
      'La version précédente a été conservée.';

  @override
  String get pluginErrorRetainedDisabled =>
      'La version précédente a été conservée mais est désactivée. Redémarrez Kiosk Satellite avant de l\'activer.';

  @override
  String get pluginErrorVersionRunning =>
      'La version précédente est de nouveau en cours d\'exécution.';

  @override
  String get pluginErrorEnablePlugins => 'Activez d\'abord Plugins';

  @override
  String get pluginErrorRestartEnable =>
      'Ce plugin ne s\'est pas arrêté proprement. Redémarrez Kiosk Satellite avant de l\'activer.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'Le plugin installé a échoué à sa vérification d\'intégrité. Réinstallez-le.';

  @override
  String get pluginErrorAndroidOld => 'La version d\'Android est trop ancienne';

  @override
  String get pluginErrorNativeIntegrity =>
      'Les bibliothèques natives installées ont échoué à leur vérification d\'intégrité';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'La bibliothèque native installée a échoué à sa vérification d\'intégrité';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'Impossible de lire le plugin installé : $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'La version précédente n\'a pas pu redémarrer : $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'Échec de la mise à jour du plugin : $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Shizuku 13 ou une version ultérieure est requis. Appuyez pour les instructions de configuration.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Démarrez Shizuku sur cet appareil. Appuyez pour les instructions de configuration.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku accorde à Kiosk Satellite un accès shell ou root. Les plugins installés s\'exécutent à l\'intérieur de KS, n\'accordez donc l\'accès que si vous leur faites confiance.';

  @override
  String get pluginSetUp => 'Configurer';

  @override
  String get pluginGrantAccess => 'Accorder l\'accès';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Approuvez la demande d\'autorisation sur le kiosque.';

  @override
  String get pluginErrorInvalidId => 'Identifiant de plugin invalide';

  @override
  String get pluginErrorInvalidVersion => 'Version invalide';

  @override
  String get pluginErrorEntryClass => 'Classe d\'entrée invalide';

  @override
  String get pluginErrorManifestSchema =>
      'Schéma de manifeste non pris en charge';

  @override
  String get pluginErrorSdkVersion =>
      'Ce plugin nécessite une version de SDK différente';

  @override
  String get pluginErrorMinimumSdk =>
      'Le SDK Android minimal doit être d\'au moins 24';

  @override
  String get pluginErrorCapability =>
      'Fonctionnalité de plugin non prise en charge';

  @override
  String get pluginErrorTooManySettings => 'Trop de paramètres ou de commandes';

  @override
  String get pluginErrorSettingKey => 'Clé de paramètre invalide ou en double';

  @override
  String get pluginErrorGroupsArray =>
      'Les groupes d\'affichage doivent être un tableau';

  @override
  String get pluginErrorTooManyGroups => 'Trop de groupes d\'affichage';

  @override
  String get pluginErrorUniqueGroups =>
      'Les groupes d\'affichage doivent nommer des groupes de paramètres uniques';

  @override
  String get pluginErrorGroupReferences => 'Trop de références de groupe';

  @override
  String get pluginErrorDuplicateReference =>
      'Référence de groupe invalide ou en double';

  @override
  String get pluginErrorCommandId =>
      'Identifiant de commande invalide ou en double';

  @override
  String get pluginErrorUnknownSetting => 'Paramètre de plugin inconnu';

  @override
  String get pluginErrorTextLength =>
      'Les paramètres de texte ne doivent pas dépasser 512 caractères';

  @override
  String get pluginErrorEntityId =>
      'Un identifiant d\'entité Home Assistant était attendu';

  @override
  String get pluginErrorBoolean => 'Un paramètre booléen était attendu';

  @override
  String get pluginErrorColor => 'Une couleur hexadécimale RVB était attendue';

  @override
  String get pluginErrorNumber => 'Un paramètre numérique était attendu';

  @override
  String get pluginErrorRange => 'Le paramètre numérique est hors de sa plage';

  @override
  String get pluginErrorStep =>
      'Le paramètre numérique ne correspond pas à son incrément';

  @override
  String get pluginErrorSelection => 'Paramètre de sélection invalide';

  @override
  String get pluginErrorSelectionOption => 'Option de sélection inconnue';

  @override
  String get pluginErrorSettingType => 'Type de paramètre non pris en charge';

  @override
  String get pluginErrorInvalidManifest => 'Manifeste de plugin invalide';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'Le plugin nécessite l\'API Android $version';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return '$field invalide';
  }

  @override
  String get remoteDisableTitle => 'Désactiver la gestion à distance ?';

  @override
  String get remoteDisableHelp =>
      'ATTENTION : vous ne pourrez plus accéder à cette page. Pour la réactiver, utilisez l\'appareil ou l\'interrupteur Gestion à distance dans Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Désactiver';

  @override
  String get remoteCopyHelp => 'Sélectionnez la clé et copiez-la manuellement.';

  @override
  String get remoteSaveSettingFailed =>
      'Impossible d\'enregistrer ce paramètre. Réessayez.';

  @override
  String get remoteReconnecting => 'Reconnexion…';

  @override
  String remoteConnectionLost(String name) {
    return 'La connexion à $name a été perdue. Cette page reprend d\'elle-même une fois la connexion rétablie.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'La connexion au kiosque a été perdue. Cette page reprend d\'elle-même une fois la connexion rétablie.';

  @override
  String get remoteReloadPage => 'Recharger la page';

  @override
  String get remoteUpdated => 'Kiosk Satellite a été mis à jour';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'L\'appareil exécute maintenant la version $version$build. Cette page appartient à la version précédente et se rechargera dans $seconds s.';
  }

  @override
  String remoteBuild(String build) {
    return ' (build $build)';
  }

  @override
  String get remoteReloadNow => 'Recharger maintenant';

  @override
  String get remoteLogin => 'Se connecter';

  @override
  String get remoteInvalidPassword => 'Mot de passe invalide';

  @override
  String get remoteLoginThrottled =>
      'Trop de tentatives. Attendez 5 minutes et réessayez.';

  @override
  String get deviceScreenOffPermission =>
      'Éteindre l\'écran nécessite une autorisation unique. La tablette affiche maintenant l\'écran d\'autorisation « administrateur de l\'appareil ». Accordez-la depuis la tablette, puis réessayez.';

  @override
  String get deviceAdminInactive =>
      'L\'autorisation administrateur de l\'appareil n\'est pas active.';

  @override
  String get deviceRestartOverlay =>
      'Redémarrer nécessite l\'autorisation « Affichage par-dessus d\'autres applications », sinon l\'application ne peut pas revenir d\'elle-même. L\'écran d\'autorisation s\'ouvre sur l\'appareil ; accordez l\'autorisation là-bas et réessayez.';

  @override
  String get deviceRebootPermission =>
      'Redémarrer l\'appareil nécessite que Kiosk Satellite soit provisionné comme propriétaire de l\'appareil ou dispose d\'une connexion Shizuku accordée.';

  @override
  String get deviceRestartAndroidOnly =>
      'Le redémarrage n\'est disponible que sous Android.';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku a refusé le redémarrage';

  @override
  String deviceRestartFailed(String error) {
    return 'Échec du redémarrage : $error';
  }

  @override
  String get overviewAttention => 'Nécessite votre attention';

  @override
  String get overviewOpen => 'Ouvrir';

  @override
  String get overviewUpdate => 'Mettre à jour';

  @override
  String overviewInvitation(String name) {
    return '$name souhaite diriger ce kiosque';
  }

  @override
  String get overviewInvitationHelp =>
      'Confirmez sur l\'écran du kiosque ou dans Gestion de flotte sur le kiosque.';

  @override
  String get overviewOutdatedOne => '1 suiveur exécute une autre version';

  @override
  String overviewOutdatedMany(String count) {
    return '$count suiveurs exécutent une autre version';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. La synchronisation attend la version $version.';
  }

  @override
  String get overviewThisRelease => 'cette version';

  @override
  String get overviewUpdateAvailable => 'Mise à jour disponible';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version est prêt à être installé. L\'installation est confirmée sur l\'écran de la tablette.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant non configuré';

  @override
  String get overviewHaSetupHelp =>
      'Connectez le kiosque à Home Assistant pour charger un tableau de bord.';

  @override
  String get overviewSetUp => 'Configurer';

  @override
  String get overviewHaNotValidated => 'Home Assistant non validé';

  @override
  String get overviewHaNotValidatedHelp =>
      'L\'URL et le jeton n\'ont pas passé de vérification de connexion lors de cette exécution. Le kiosque réessaie toutes les 30 secondes.';

  @override
  String get overviewOpenSetup => 'Ouvrir la configuration';

  @override
  String get overviewWakeStopped =>
      'La détection du mot de réveil s\'est arrêtée';

  @override
  String get overviewWakeReleased => 'Le moteur a été libéré.';

  @override
  String get overviewOpenVoice => 'Ouvrir Voice Satellite';

  @override
  String get overviewOpenService => 'Ouvrir le service';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Autorisation manquante : $permission';
  }

  @override
  String get overviewQuick => 'Contrôles rapides';

  @override
  String get overviewReload => 'Recharger la page';

  @override
  String get overviewScreenOn => 'Écran allumé';

  @override
  String get overviewScreenOff => 'Écran éteint';

  @override
  String get overviewSaverStart => 'Démarrer l\'économiseur d\'écran';

  @override
  String get overviewSaverStop => 'Fermer l\'économiseur d\'écran';

  @override
  String get overviewCameraShow => 'Afficher la vue caméra';

  @override
  String get overviewCameraHide => 'Fermer la vue caméra';

  @override
  String get overviewSaverPostpone => 'Reporter l\'économiseur d\'écran';

  @override
  String get overviewDnd => 'Ne pas déranger';

  @override
  String get overviewDndOn => 'Ne pas déranger activé';

  @override
  String get overviewSnapshot => 'Prendre un instantané';

  @override
  String get overviewCheckUpdates => 'Vérifier les mises à jour';

  @override
  String get overviewRestartApp => 'Redémarrer l\'application';

  @override
  String get overviewRestartDevice => 'Redémarrer l\'appareil';

  @override
  String get overviewExit => 'Quitter l\'application';

  @override
  String get overviewBrightness => 'Luminosité';

  @override
  String get overviewVolume => 'Volume principal';

  @override
  String get overviewBrightnessGrant =>
      'La luminosité utilise une solution de secours au niveau de l\'application. Accordez « Modifier les paramètres système » pour que le curseur contrôle la luminosité réelle de l\'écran.';

  @override
  String get overviewRestartQuestion =>
      'Redémarrer cet appareil ? Kiosk Satellite revient automatiquement au démarrage.';

  @override
  String get overviewRestart => 'Redémarrer';

  @override
  String get overviewNoSnapshot => 'Aucun instantané reçu.';

  @override
  String get overviewSnapshotTitle => 'Instantané caméra';

  @override
  String get overviewUpdateCheckFailed =>
      'Échec de la vérification des mises à jour. L\'appareil peut-il joindre GitHub ?';

  @override
  String get overviewLatest => 'Vous êtes sur la dernière version.';

  @override
  String overviewVersionAvailable(String version) {
    return 'La version $version est disponible';
  }

  @override
  String get overviewInstallAttention =>
      'Installez-la depuis Nécessite votre attention.';

  @override
  String get overviewNoViewsWithCameras =>
      'Aucune vue caméra n\'a encore de caméras. Ajoutez d\'abord des caméras à une vue dans Caméras.';

  @override
  String get overviewShowViewFailed => 'Impossible d\'afficher la vue';

  @override
  String get overviewAppVersion => 'Version de l\'application';

  @override
  String get overviewNotSetup => 'Non configuré';

  @override
  String get overviewNotValidated => 'Non validé';

  @override
  String get overviewCheckingFilter => 'Vérification du filtre...';

  @override
  String get overviewValidated => 'Validé';

  @override
  String get overviewFilterUnavailable => 'État du filtre indisponible';

  @override
  String get overviewUnfiltered => 'Mises à jour non filtrées';

  @override
  String get overviewWatchingOne => 'Surveille 1 entité';

  @override
  String overviewWatchingMany(String count) {
    return 'Surveille $count entités';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filtrage désactivé, la vue utilise $count entités';
  }

  @override
  String get overviewWakeOff => 'Détection du mot de réveil désactivée';

  @override
  String overviewListeningFor(String words) {
    return 'À l\'écoute de $words';
  }

  @override
  String get overviewListening => 'En écoute';

  @override
  String get overviewNotListening => 'N\'écoute pas';

  @override
  String get overviewEntitiesProxy => 'Entités et proxy BT';

  @override
  String get overviewEntitiesOnly => 'Entités uniquement';

  @override
  String get overviewProxyOnly => 'Proxy BT uniquement';

  @override
  String get overviewWaitingHA => 'En attente de Home Assistant';

  @override
  String get overviewNotRunning => 'À l\'arrêt';

  @override
  String get overviewRunningOne => 'En fonctionnement - 1 fonctionnalité';

  @override
  String overviewRunningMany(String count) {
    return 'En fonctionnement - $count fonctionnalités';
  }

  @override
  String overviewDownloading(String version) {
    return 'Téléchargement : $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Nouvelle version : $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'À jour : $version';
  }

  @override
  String get overviewCurrent => 'À jour';

  @override
  String overviewPluginAttribution(String name) {
    return 'plugin $name';
  }

  @override
  String get overviewMuted => 'coupé';

  @override
  String get overviewBrowser => 'navigateur';

  @override
  String get overviewWakeWaiting =>
      'En attente de Voice Satellite. Le moteur et les mots de réveil sont configurés par l\'intégration une fois que cet appareil ouvre son tableau de bord.';

  @override
  String get overviewWakeDisabled =>
      'La détection du mot de réveil est désactivée. Activez-la pour hériter des modèles de Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Microphone bloqué. Android ne redemandera pas l\'autorisation : autorisez-le dans les paramètres de l\'application, puis réessayez.';

  @override
  String get overviewMicDeclined =>
      'Microphone refusé. La détection du mot de réveil en a besoin ; réessayez pour qu\'il soit redemandé.';

  @override
  String get overviewMicLost =>
      'Le microphone a cessé de fonctionner. Réessayez, ou rechargez la page.';

  @override
  String get overviewModelsUnavailable =>
      'Impossible de télécharger les modèles depuis Home Assistant. Réessayez une fois qu\'il est joignable.';

  @override
  String get overviewCrashed =>
      'Le détecteur a planté à répétition sur cet appareil, il a donc été arrêté. Voice Satellite écoute désormais dans le navigateur. Réessayez, ou redémarrez l\'application.';

  @override
  String get overviewWakeFailed =>
      'Le moteur de mot de réveil n\'a pas pu démarrer. Réessayez, ou rechargez la page.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'Aucun moteur d\'exécution natif pour $engine. Voice Satellite conserve la détection dans le navigateur.';
  }

  @override
  String get overviewNativeListening => 'Écoute native';

  @override
  String get overviewSuspended => 'Prêt (suspendu pendant une session vocale)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp.';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount Go libres';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value %';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value °C';
  }

  @override
  String get overviewNoScreenshot => 'Aucune capture d\'écran';

  @override
  String get overviewStill => 'Fixe';

  @override
  String get overviewLive => 'En direct';

  @override
  String get overviewFullSize => 'Taille réelle';

  @override
  String get overviewLiveInterval => 'En direct, toutes les 5 secondes';

  @override
  String overviewTaken(String age) {
    return 'Prise $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Vue caméra : $name';
  }

  @override
  String get overviewCameraView => 'Vue caméra';

  @override
  String get overviewScreenOffState => 'L\'écran est éteint';

  @override
  String get overviewGoView => 'Aller à la vue';

  @override
  String get overviewLoadingViews => 'Chargement des vues…';

  @override
  String get overviewPickView => 'Choisir une vue du tableau de bord…';

  @override
  String get overviewDefaultView => 'Vue par défaut';

  @override
  String get overviewNoDashboards => 'Aucun tableau de bord trouvé';

  @override
  String get overviewViewsUnavailable => 'Vues indisponibles';

  @override
  String get screensaverNoPhotos =>
      'Aucune photo sélectionnée. Choisissez-en dans les Paramètres.';

  @override
  String get screensaverNoFolder =>
      'Aucun dossier sélectionné. Choisissez-en un dans les Paramètres.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'Aucune photo ni vidéo dans $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'Impossible de lire $folder. L\'autorisation d\'accès aux médias est-elle accordée ?';
  }

  @override
  String get screensaverReadPhotosFailed => 'Impossible de lire les photos.';

  @override
  String get screensaverImmichNotReady =>
      'Immich n\'est pas connecté. Validez-le dans les Paramètres.';

  @override
  String get screensaverNoMediaMatch =>
      'Aucun média ne correspond à la source et aux filtres.';

  @override
  String get screensaverNoMediaSource =>
      'Aucun média dans la source sélectionnée.';

  @override
  String get screensaverImmichUnreachable =>
      'Impossible de joindre le serveur Immich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Nouvelle tentative automatique.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Toutes les vidéos de cette liste de lecture sont trop volumineuses pour être lues sur cet appareil.';

  @override
  String get settingLauncherEnabledTitle =>
      'Activer le lanceur d\'applications';

  @override
  String get settingLauncherEnabledDescription =>
      'Ouvrir un ensemble choisi d\'applications installées depuis le kiosque.';

  @override
  String get settingLauncherAppsDescription =>
      'Les applications que le lanceur propose.';

  @override
  String get settingLauncherAutoReturnTitle => 'Retour automatique';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Revenir au kiosque une fois que l\'autre application est restée inutilisée un moment.';

  @override
  String get settingLauncherAutoReturnSecondsTitle => 'Retour après (secondes)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Durée sans interaction dans l\'autre application avant que le kiosque revienne.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite peut se remettre lui-même au premier plan et détecter les appuis dans l\'autre application.';

  @override
  String get launcherOverlayMissing =>
      'Sans cela, le kiosque ne peut pas revenir de lui-même, et les appuis dans l\'autre application passent inaperçus.';

  @override
  String get launcherOverlayRemote =>
      'Sans cela, le kiosque ne peut pas revenir de lui-même, et les appuis dans l\'autre application passent inaperçus. L\'écran d\'autorisation apparaît sur la tablette.';

  @override
  String get launcherBatteryMissing =>
      'Android peut mettre l\'application en pause derrière l\'autre, et une minuterie en pause ne ramène jamais le kiosque.';

  @override
  String get launcherBatteryRemote =>
      'Android peut mettre l\'application en pause derrière l\'autre, et une minuterie en pause ne ramène jamais le kiosque. La boîte de dialogue d\'autorisation apparaît sur la tablette.';

  @override
  String get launcherPermissionsSearch =>
      'Les autorisations dont Retour automatique a besoin.';

  @override
  String get settingCameraEnabledTitle => 'Activer la caméra';

  @override
  String get settingCameraEnabledDescription =>
      'L\'utilisation de la caméra augmente la charge du CPU et la chaleur, ce qui peut réduire la durée de vie de la batterie et de l\'appareil.';

  @override
  String get settingCameraDeviceTitle => 'Caméra';

  @override
  String get settingCameraDeviceDescription => 'Quelle caméra utiliser.';

  @override
  String get settingCameraSnapshotResolutionTitle =>
      'Résolution des instantanés';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Une valeur plus élevée donne une image plus nette mais consomme davantage de CPU et de bande passante.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Désactiver les instantanés lors d\'une détection';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Empêcher les instantanés automatiques déclenchés par la détection. La détection de mouvement, de visage, de présence et de gestes continue de fonctionner. Les demandes manuelles et les instantanés continus peuvent toujours capturer des images.';

  @override
  String get settingCameraSnapshotsTitle => 'Instantanés continus';

  @override
  String get settingCameraSnapshotsDescription =>
      'Publier régulièrement un nouvel instantané de la caméra dans Home Assistant, à intervalle fixe.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Intervalle des instantanés';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Secondes entre les instantanés.';

  @override
  String get cameraFront => 'Avant';

  @override
  String get cameraBack => 'Arrière';

  @override
  String get cameraOnlyCamera => 'La seule caméra que possède cet appareil.';

  @override
  String get settingMotionSensorTitle => 'Capteur de mouvement';

  @override
  String get settingMotionSensorDescription =>
      'Exposer le mouvement comme capteur Home Assistant. ATTENTION : garde la caméra en fonctionnement en permanence, même lorsque l\'écran est éteint.';

  @override
  String get settingMotionSensorOffDelayTitle =>
      'Retour à l\'état inactif après';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Secondes sans mouvement avant que le capteur repasse à l\'état inactif.';

  @override
  String get settingMotionFpsTitle =>
      'Fréquence d\'images pour la détection de mouvement';

  @override
  String get settingMotionFpsDescription =>
      'Nombre d\'images par seconde analysées pour détecter un mouvement. Une valeur plus basse ménage le CPU ; 2 suffit largement pour remarquer quelqu\'un qui approche.';

  @override
  String get settingMotionStartDelayTitle => 'Délai de démarrage';

  @override
  String get settingMotionStartDelayDescription =>
      'Ignorer le mouvement pendant cette durée après le démarrage de la caméra, pour les appareils dont la caméra bouge physiquement à l\'ouverture.';

  @override
  String get settingMotionSensitivityTitle => 'Sensibilité au mouvement';

  @override
  String get settingMotionSensitivityDescription =>
      'Une valeur plus élevée se déclenche pour des mouvements plus petits. 1 exige un grand changement dans l\'image ; 100 réagit au moindre mouvement.';

  @override
  String get cameraMotionPage => 'Capteur de mouvement';

  @override
  String get cameraMotionHint =>
      'Capteur de mouvement Home Assistant et paramètres de détection partagés';

  @override
  String get cameraNoCamera => 'Aucune caméra détectée';

  @override
  String get cameraNoCameraHelp =>
      'Cet appareil ne signale aucune caméra utilisable.';

  @override
  String get cameraCameraPermission => 'Autorisation de caméra manquante';

  @override
  String get cameraCameraPermissionHelp =>
      'Sans elle, la caméra ne peut pas être utilisée. La boîte de dialogue d\'autorisation apparaît sur l\'écran de la tablette.';

  @override
  String get cameraGrantOnDevice => 'Autoriser sur l\'appareil';

  @override
  String get cameraCameraBlocked =>
      'Bloqué. Android ne redemandera pas l\'autorisation : autorisez la caméra dans les paramètres de l\'application.';

  @override
  String get cameraCameraNeeded =>
      'Sans cela, la caméra ne peut pas être utilisée.';

  @override
  String get cameraAppSettings => 'Paramètres de l\'application';

  @override
  String get cameraLatest => 'Dernier instantané';

  @override
  String get cameraNoSnapshot => 'Aucun instantané pour l\'instant.';

  @override
  String get cameraImageAlt => 'Dernier instantané de la caméra';

  @override
  String get cameraTakeSnapshot => 'Prendre un instantané';

  @override
  String get cameraSnapshotFailed => 'Échec de l\'instantané.';

  @override
  String cameraSnapshotError(String error) {
    return 'Échec de l\'instantané : $error';
  }

  @override
  String get cameraCameraDisabled =>
      'La caméra est désactivée dans les paramètres Caméra.';

  @override
  String get cameraSnapshotBusy => 'Un instantané est déjà en cours.';

  @override
  String get cameraPermissionDenied => 'Autorisation de caméra non accordée.';

  @override
  String get cameraDetectionDisabled =>
      'Les instantanés de détection sont désactivés.';

  @override
  String get cameraNoImage => 'La caméra n\'a renvoyé aucune image.';

  @override
  String get cameraTimedOut => 'La caméra n\'a pas répondu à temps.';

  @override
  String get cameraBackground =>
      'La caméra est indisponible tant que l\'application est en arrière-plan.';

  @override
  String get cameraJustNow => 'à l\'instant';

  @override
  String cameraSecondsAgo(String count) {
    return 'il y a $count secondes';
  }

  @override
  String get cameraMinuteAgo => 'il y a 1 minute';

  @override
  String cameraMinutesAgo(String count) {
    return 'il y a $count minutes';
  }

  @override
  String get cameraHourAgo => 'il y a 1 heure';

  @override
  String cameraHoursAgo(String count) {
    return 'il y a $count heures';
  }

  @override
  String get cameraDayAgo => 'il y a 1 jour';

  @override
  String cameraDaysAgo(String count) {
    return 'il y a $count jours';
  }

  @override
  String get cameraStatusHeading => 'État du flux';

  @override
  String get cameraClientsHeading => 'Clients connectés';

  @override
  String get cameraUnavailable => 'Indisponible';

  @override
  String get cameraStopped => 'Arrêté';

  @override
  String get cameraStreaming => 'En diffusion';

  @override
  String get cameraIdle => 'Inactif';

  @override
  String get cameraConnected => 'Connecté';

  @override
  String get cameraChecking => 'Vérification...';

  @override
  String get cameraCheckingStatus => 'Vérification de l\'état du flux...';

  @override
  String get cameraStatusUnavailable => 'État du flux indisponible.';

  @override
  String get cameraListenerStopped => 'L\'écouteur est arrêté.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count spectateur connecté. Vidéo réelle : $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count spectateurs connectés. Vidéo réelle : $resolution.';
  }

  @override
  String get cameraReady =>
      'Prêt. L\'encodeur démarre lorsqu\'un spectateur se connecte.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Demandé : $requested. Fourni par la caméra : $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio : $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio en pause tant que le navigateur utilise le microphone.';

  @override
  String get cameraAudioStreaming => 'Diffusion audio du microphone.';

  @override
  String get cameraAudioIdle => 'Audio du microphone inactif.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Découverte ONVIF : $error';
  }

  @override
  String get cameraOnvifUrl => 'URL ONVIF';

  @override
  String get cameraStreamUrl => 'URL du flux';

  @override
  String get cameraWaitingAddress => 'En attente d\'une adresse réseau';

  @override
  String get cameraClientsUnavailable =>
      'Informations sur les clients indisponibles.';

  @override
  String get cameraNoClients => 'Aucun client connecté.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Port $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Connecté depuis $duration';
  }

  @override
  String cameraDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String cameraDurationMinutes(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String cameraDurationHours(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get cameraCredentialsMissing =>
      'Définissez un nom d\'utilisateur et un mot de passe de diffusion pour activer l\'authentification.';

  @override
  String get cameraPortWaiting => 'En attente de la libération du port RTSP.';

  @override
  String get cameraListenerFailed => 'Impossible de démarrer l\'écouteur RTSP.';

  @override
  String get settingCameraRtspEnabledTitle => 'Activer la diffusion caméra';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Partager la vidéo H.264 avec des clients RTSP ou ONVIF. L\'encodage vidéo ne fonctionne que lorsqu\'un spectateur est connecté. L\'encodage matériel est préféré, avec repli logiciel si nécessaire. Utilise la caméra sélectionnée dans les paramètres Caméra.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Protocole de diffusion';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF permet aux clients compatibles de découvrir la caméra et de se connecter à son flux.';

  @override
  String get settingCameraRtspPortTitle => 'Port';

  @override
  String get settingCameraRtspPortDescription => 'Port du serveur RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Port';

  @override
  String get settingCameraOnvifPortDescription => 'Port du serveur ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Résolution';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Tailles de diffusion prises en charge pour la caméra et l\'encodeur sélectionnés. La vidéo suit l\'orientation de l\'appareil.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Analyse de mouvement pendant la diffusion';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Garder la détection de mouvement, de visage et les gestes de la main disponibles tant que des spectateurs sont connectés. Désactiver ceci peut permettre des résolutions plus élevées. Les instantanés utilisent alors des images vidéo à la résolution de diffusion.';

  @override
  String get settingCameraRtspFpsTitle => 'Fréquence d\'images';

  @override
  String get settingCameraRtspFpsDescription =>
      'Fréquence d\'images vidéo cible par seconde. Le mouvement conserve sa propre fréquence d\'analyse. La diffusion réelle dépend de la caméra.';

  @override
  String get settingCameraRtspBitrateTitle => 'Débit binaire';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Débit vidéo cible. Une valeur plus élevée améliore le niveau de détail mais consomme davantage de bande passante réseau.';

  @override
  String get settingCameraRtspAudioTitle => 'Inclure l\'audio du microphone';

  @override
  String get settingCameraRtspAudioDescription =>
      'Inclure l\'audio du microphone dans le flux caméra. Partage vos paramètres de microphone. ATTENTION : utilisation accrue du CPU.';

  @override
  String get settingCameraRtspAuthTitle => 'Exiger une authentification';

  @override
  String get settingCameraRtspAuthDescription =>
      'Exige un nom d’utilisateur et un mot de passe pour regarder le flux. L’authentification n’active pas le chiffrement.';

  @override
  String get settingCameraRtspUsernameTitle => 'Nom d\'utilisateur';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Nom d\'utilisateur pour les clients de diffusion.';

  @override
  String get settingCameraRtspPasswordTitle => 'Mot de passe';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Définir un mot de passe pour démarrer le flux authentifié.';

  @override
  String get cameraStreamingPage => 'Diffusion RTSP et ONVIF';

  @override
  String get cameraStreamingHint =>
      'Partager la caméra de l\'appareil via RTSP ou ONVIF';

  @override
  String get cameraPortError =>
      'Saisissez un numéro de port entier entre 1024 et 65535.';

  @override
  String get cameraUsernameError =>
      'Utilisez 1 à 64 caractères sans espaces, guillemets, deux-points ni barres obliques inverses.';

  @override
  String get cameraNoSizes => 'Aucune taille prise en charge disponible';

  @override
  String get cameraNoSizesHelp =>
      'Aucune taille prise en charge disponible. Vérifiez la connexion de la caméra.';

  @override
  String get cameraResolutionSupport => 'Prise en charge de la résolution';

  @override
  String get cameraCheckingSizes =>
      'Vérification de la prise en charge de la caméra et de l\'encodeur H.264...';

  @override
  String get cameraSupportedSizes =>
      'Seules les tailles prises en charge par la caméra et l\'encodeur H.264 avec les paramètres de diffusion actuels sont listées.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Désactivez l\'analyse de mouvement pendant la diffusion pour aussi utiliser $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'La détection de mouvement, de visage et les gestes de la main sont suspendus tant que des spectateurs sont connectés. Les instantanés utilisent des images vidéo à la résolution de diffusion.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'L\'encodeur ne peut pas utiliser $sizes avec ces paramètres.';
  }

  @override
  String cameraRejectedCount(String count) {
    return '$count tailles de caméra sont exclues car l\'encodeur ne peut pas les utiliser avec ces paramètres.';
  }

  @override
  String get cameraCaptureRejected =>
      'D\'autres tailles de caméra sont indisponibles dans la configuration de capture actuelle.';

  @override
  String get cameraOverlaysHeading => 'Superpositions';

  @override
  String get settingCameraRtspDateTimeTitle => 'Afficher la date et l\'heure';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Afficher la date et l\'heure de l\'appareil dans le coin supérieur gauche de la vidéo, selon son format de date et son réglage 12/24 heures.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Fond noir';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Ajouter un fond noir derrière la date et l\'heure pour une meilleure visibilité.';

  @override
  String get settingCameraRtspTlsTitle => 'Chiffrer le flux';

  @override
  String get settingCameraRtspTlsDescription =>
      'Utilise TLS pour chiffrer la vidéo et l’audio. Nécessite un lecteur compatible.';

  @override
  String get cameraStreamsNameRequired => 'nom requis';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'une valeur baseUrl HTTP ou HTTPS valide est requise';

  @override
  String get cameraStreamsServerNotFound => 'serveur introuvable';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC a renvoyé une liste de flux invalide';

  @override
  String get cameraStreamsKindRequired => 'kind doit être go2rtc, whep ou ha';

  @override
  String get cameraStreamsProtocolRequired =>
      'preferredProtocol doit être auto, webrtc, hls ou mjpeg';

  @override
  String get cameraStreamsServerRequired => 'un serverId valide est requis';

  @override
  String get cameraStreamsStreamRequired => 'streamName requis';

  @override
  String get cameraStreamsEntityRequired => 'un entityId camera.* est requis';

  @override
  String get cameraStreamsWhepRequired => 'une URL WHEP valide est requise';

  @override
  String get cameraStreamsCameraNotFound => 'caméra introuvable';

  @override
  String get cameraStreamsListRequired => 'cameraIds doit être une liste';

  @override
  String get cameraStreamsViewCount =>
      'une vue doit contenir de 1 à 12 caméras';

  @override
  String get cameraStreamsRepeatedCamera =>
      'une caméra ne peut apparaître qu\'une fois par vue';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'la vue contient une caméra inconnue';

  @override
  String get cameraStreamsUniqueViewName => 'le nom de la vue doit être unique';

  @override
  String get cameraStreamsGridRange =>
      'la grille doit être comprise entre 1 et 12';

  @override
  String get cameraStreamsGridTooSmall =>
      'la grille est plus petite que le nombre de caméras';

  @override
  String get cameraStreamsViewNotFound => 'vue introuvable';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'la vue par défaut ne peut pas être supprimée ; videz-la à la place';

  @override
  String get cameraStreamsViewEmpty => 'la vue ne contient aucune caméra';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'impossible de lire Home Assistant : $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'impossible de se connecter à $server : $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant n\'est pas configuré ou est injoignable';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC a renvoyé HTTP $status';
  }

  @override
  String get cameraStreamsImportHa =>
      'Importer des caméras depuis Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Ajouter toutes les caméras du Home Assistant connecté, en lecture via WebRTC, HLS ou MJPEG. Réimporter fusionne les nouvelles caméras.';

  @override
  String get cameraStreamsImportFailed => 'Échec de l\'importation';

  @override
  String get cameraStreamsImportComplete => 'Importation terminée';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added ajoutées, $missing manquantes.';
  }

  @override
  String get settingCameraAllowH265Title => 'Autoriser les flux H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Lire les flux caméra H.265 tels quels. Un appareil incapable de décoder le H.265 affiche une image vide à la place.';

  @override
  String get settingCameraPreferMseTitle => 'Préférer MSE à WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Diffuser d\'abord les caméras Go2RTC via MSE. Pour les appareils incapables de lire le WebRTC ; ajoute une ou deux secondes de délai.';

  @override
  String get settingCameraPreferHlsTitle => 'Préférer HLS à WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Diffuser d\'abord les caméras Home Assistant via HLS. Pour les appareils incapables de lire le WebRTC ; ajoute quelques secondes de délai.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Jouer le son pour une seule caméra';

  @override
  String get settingCameraSingleAudioDescription =>
      'Jouer le son de la caméra quand une seule caméra est à l\'écran. Les grilles avec plusieurs caméras restent silencieuses.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Pincer pour zoomer sur une seule caméra';

  @override
  String get settingCameraPinchZoomDescription =>
      'Zoomer dans l\'image avec deux doigts quand une seule caméra est à l\'écran. Faites glisser pour vous déplacer, appuyez deux fois pour réinitialiser.';

  @override
  String get settingCameraAutoDismissSecondsTitle =>
      'Fermer automatiquement après';

  @override
  String get settingCameraAutoDismissSecondsDescription =>
      'Fermer automatiquement une vue caméra ouverte ; 0 la laisse affichée. L\'économiseur d\'écran caméra n\'est pas affecté.';

  @override
  String get cameraStreamsPlayback => 'Lecture';

  @override
  String get cameraStreamsOff => 'Désactivé';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Les grilles avec plusieurs caméras sont vidéo uniquement. Pour les appareils peu puissants, utilisez des flux Go2RTC en résolution réduite dans les vues et définissez éventuellement un flux plein écran distinct.';

  @override
  String get cameraStreamsServers => 'Serveurs Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Importer les flux';

  @override
  String get cameraStreamsDeleteServer => 'Supprimer le serveur';

  @override
  String get cameraStreamsAddServer => 'Ajouter un serveur Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Se connecter à un serveur et importer ses flux.';

  @override
  String get cameraStreamsEditServer => 'Modifier le serveur';

  @override
  String get cameraStreamsName => 'Nom';

  @override
  String get cameraStreamsBaseUrl => 'URL de base';

  @override
  String get cameraStreamsUsername => 'Nom d\'utilisateur (facultatif)';

  @override
  String get cameraStreamsNewPassword =>
      'Nouveau mot de passe (laisser vide pour conserver)';

  @override
  String get cameraStreamsPassword => 'Mot de passe (facultatif)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Autoriser un certificat TLS invalide';

  @override
  String get cameraStreamsSaveServerFailed =>
      'Impossible d\'enregistrer le serveur';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Ses caméras seront retirées de toutes les vues.';

  @override
  String get cameraStreamsCameras => 'Caméras';

  @override
  String get cameraStreamsNoCameras => 'Aucune caméra configurée';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Importez des caméras depuis Home Assistant ou Go2RTC, ou ajoutez-en une manuellement.';

  @override
  String get cameraStreamsDeleteCamera => 'Supprimer la caméra';

  @override
  String get cameraStreamsAddManually => 'Ajouter une caméra manuellement';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Utilisez un nom de flux Go2RTC, une URL WHEP ou une entité caméra Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Caméra inconnue';

  @override
  String get cameraStreamsUnknownServer => 'Serveur inconnu';

  @override
  String get cameraStreamsMissing => ' (manquant)';

  @override
  String get cameraStreamsAddCamera => 'Ajouter une caméra';

  @override
  String get cameraStreamsEditCamera => 'Modifier la caméra';

  @override
  String get cameraStreamsType => 'Type';

  @override
  String get cameraStreamsGo2RtcStream => 'Flux Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'URL WHEP directe';

  @override
  String get cameraStreamsHaCamera => 'Caméra Home Assistant';

  @override
  String get cameraStreamsEntity => 'Entité caméra';

  @override
  String get cameraStreamsProtocol => 'Protocole préféré';

  @override
  String get cameraStreamsAuto => 'Auto';

  @override
  String get cameraStreamsServer => 'Serveur';

  @override
  String get cameraStreamsStreamName => 'Nom du flux';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Nom du flux Go2RTC';

  @override
  String get cameraStreamsFullscreen => 'Flux plein écran (facultatif)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed =>
      'Impossible d\'enregistrer la caméra';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Elle sera retirée de toutes les vues.';

  @override
  String get cameraStreamsLoadFailed => 'Impossible de charger les caméras.';

  @override
  String get cameraStreamsViews => 'Vues';

  @override
  String get cameraStreamsEmptyView => 'Aucune caméra pour l\'instant';

  @override
  String get cameraStreamsNamesShown => 'Noms affichés';

  @override
  String get cameraStreamsNamesHidden => 'Noms masqués';

  @override
  String get cameraStreamsShowView => 'Afficher la vue';

  @override
  String get cameraStreamsDeleteView => 'Supprimer la vue';

  @override
  String get cameraStreamsCreateView => 'Créer une vue caméra';

  @override
  String get cameraStreamsAddFirst => 'Ajoutez d\'abord une caméra.';

  @override
  String get cameraStreamsChooseCameras =>
      'Choisissez jusqu\'à 12 caméras et classez-les dans l\'ordre voulu.';

  @override
  String get cameraStreamsShowFailed => 'Impossible d\'afficher la vue';

  @override
  String get cameraStreamsShowFailedRemote => 'Impossible d\'afficher la vue';

  @override
  String get cameraStreamsEditView => 'Modifier la vue';

  @override
  String get cameraStreamsShowNames => 'Afficher les noms des caméras';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Afficher une étiquette au-dessus de chaque caméra.';

  @override
  String get cameraStreamsGrid => 'Grille';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count caméra';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count caméras';
  }

  @override
  String get cameraStreamsInView => 'Dans cette vue';

  @override
  String get cameraStreamsAvailable => 'Disponible';

  @override
  String cameraStreamsPosition(String position) {
    return 'Position $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'Absent de Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'Impossible d\'enregistrer la vue';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Cette action est irréversible.';

  @override
  String get cameraStreamsShow => 'Afficher';

  @override
  String get cameraStreamsStop => 'Arrêter';

  @override
  String get settingAnalyticsBasicTitle => 'Statistiques de base';

  @override
  String get settingAnalyticsBasicDescription =>
      'Informations sur votre appareil, telles que le modèle, la version d\'Android, la version de l\'application, la taille de l\'écran et la langue.';

  @override
  String get settingAnalyticsUsageTitle => 'Utilisation';

  @override
  String get settingAnalyticsUsageDescription =>
      'Détails de votre utilisation de Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnostics';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Partager les rapports de plantage en cas d\'erreurs inattendues.';

  @override
  String get deviceAnalyticsPage => 'Kiosk Satellite Analytics';

  @override
  String get deviceAnalyticsIntro =>
      'Partagez des informations anonymisées de votre installation pour aider à améliorer Kiosk Satellite et orienter l\'attention portée aux appareils et fonctionnalités.';

  @override
  String get deviceAnalyticsLearn =>
      'Découvrez comment nous traitons vos données';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Ce que Kiosk Satellite Analytics envoie, et ce qui n\'est jamais envoyé.';

  @override
  String get deviceExportConfig => 'Exporter la configuration';

  @override
  String get deviceExportConfigHelp =>
      'Enregistrer tous les paramètres et le stockage local de la page dans un fichier.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Télécharger tous les paramètres et le stockage local de la page.';

  @override
  String get deviceImportConfig => 'Importer une configuration';

  @override
  String get deviceImportConfigHelp =>
      'Remplacer les paramètres de cet appareil à partir d\'un fichier exporté.';

  @override
  String get deviceExportFailed => 'Échec de l\'exportation';

  @override
  String get deviceExported => 'Configuration exportée';

  @override
  String get deviceImportFailed => 'Échec de l\'importation';

  @override
  String get deviceInvalidJson => 'Ce fichier n\'est pas un JSON valide.';

  @override
  String get deviceImportComplete => 'Importation terminée';

  @override
  String deviceAppliedSettings(String count) {
    return '$count paramètres appliqués.';
  }

  @override
  String deviceAppliedReload(String count) {
    return '$count paramètres appliqués. La page va peut-être se recharger.';
  }

  @override
  String get deviceReplaceOriginal => 'Remplacer l\'appareil d\'origine';

  @override
  String get deviceReplaceQuestion =>
      'Remplacer les paramètres de cet appareil par ceux du fichier ? La page va peut-être se recharger.';

  @override
  String get deviceNewDevice => 'Configurer comme nouvel appareil';

  @override
  String get deviceReplaceIdentity =>
      'Conserve le nom et l\'identité ESPHome de la sauvegarde ; l\'appareil d\'origine doit rester hors ligne.';

  @override
  String get deviceNewIdentity =>
      'Attribue son propre nom et sa propre identité ESPHome, afin que les deux appareils soient uniques.';

  @override
  String get deviceRestoreStorage =>
      'Restaurer le stockage local de la Webview';

  @override
  String get deviceRestoreStorageHelp =>
      'Inclut la session Home Assistant connectée et la sélection assist_satellite de Voice Satellite : deux appareils ne doivent pas partager le même satellite.';

  @override
  String get deviceDownload => 'Télécharger';

  @override
  String get deviceChooseFile => 'Choisir un fichier…';

  @override
  String get deviceImportFailedSentence => 'Échec de l\'importation.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Remplacer « $name »';
  }

  @override
  String get settingDeviceNameTitle => 'Nom de l\'appareil';

  @override
  String get settingDeviceNameDescription =>
      'Nom d\'affichage indiqué dans la gestion à distance et utilisé comme nom d\'appareil publié dans Home Assistant.';

  @override
  String get settingDeviceHostnameTitle => 'Nom mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Accédez à l\'administration à distance avec ce nom et le port configuré sur le réseau local. Effacez-le pour reprendre le nom de l\'appareil.';

  @override
  String get settingDisableImpellerTitle => 'Moteur de rendu historique';

  @override
  String get settingDisableImpellerDescription =>
      'Utiliser l\'ancien moteur de rendu Skia, pour les anciens GPU qui plantent au démarrage. S\'active automatiquement après deux plantages de ce type ; prend effet au prochain démarrage de l\'application.';

  @override
  String get settingLegacyWebViewTitle => 'Moteur de rendu WebView historique';

  @override
  String get settingLegacyWebViewDescription =>
      'Dessiner le tableau de bord dans une texture, pour les anciens GPU qui plantent à son apparition. S\'active automatiquement quand l\'appareil en a besoin ; prend effet au prochain démarrage de l\'application.';

  @override
  String get deviceHostnamePlaceholder =>
      'Défini à partir du nom de l\'appareil';

  @override
  String get deviceConfiguration => 'Configuration';

  @override
  String get devicePermissionsManager => 'Gestionnaire d\'autorisations';

  @override
  String get deviceOptions => 'Options';

  @override
  String get deviceStatus => 'État';

  @override
  String get deviceConnection => 'Connexion';

  @override
  String get devicePermissions => 'Autorisations';

  @override
  String get deviceHelp => 'Aide';

  @override
  String get deviceAccess => 'Accès';

  @override
  String get deviceReading => 'Lecture…';

  @override
  String get deviceChecking => 'Vérification...';

  @override
  String get deviceUnavailable => 'État indisponible.';

  @override
  String get deviceGrantOnDevice => 'Autoriser sur l\'appareil';

  @override
  String get deviceAppSettings => 'Paramètres de l\'application';

  @override
  String get deviceCopyCommand => 'Copier la commande';

  @override
  String get deviceOpenGuide => 'Ouvrir le guide';

  @override
  String get deviceNotSet => 'Non défini';

  @override
  String get deviceGranted => 'Autorisé';

  @override
  String get deviceNotGranted => 'Non autorisé';

  @override
  String get deviceMissing => 'Manquant';

  @override
  String get deviceNotOffered => 'Non proposé';

  @override
  String get deviceOn => 'activé';

  @override
  String get deviceOff => 'désactivé';

  @override
  String get deviceServiceHint =>
      'État, ce qui le maintient actif, autorisations requises';

  @override
  String get deviceRemoteHintActual =>
      'Gérer ce kiosque depuis un navigateur sur votre réseau';

  @override
  String get deviceUpdatesHint =>
      'Où l\'application recherche les nouvelles versions';

  @override
  String get deviceShizukuHint =>
      'Connexion, autorisations Android et configuration';

  @override
  String get deviceHelperHint =>
      'État des mises à jour silencieuses, configuration et instructions ADB';

  @override
  String get deviceAnalyticsHint =>
      'Partager des informations anonymisées pour aider à améliorer Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Modèle, version d\'Android, adresses, mémoire, temps de fonctionnement';

  @override
  String get deviceHaHint => 'Connexion, version et ce que le kiosque affiche';

  @override
  String get deviceWebViewHint =>
      'Version du moteur, rendu et agent utilisateur';

  @override
  String get devicePasswordSet => '•••••• (défini)';

  @override
  String get deviceSaveFailed =>
      'Impossible d\'enregistrer ce paramètre. Réessayez.';

  @override
  String get deviceOpenSettingsDevice =>
      'Ouvrir les paramètres sur l\'appareil';

  @override
  String get deviceHardwarePage => 'Matériel';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Modèle de l\'appareil';

  @override
  String get deviceAndroidVersion => 'Version d\'Android';

  @override
  String get deviceAndroidBuild => 'Build Android';

  @override
  String get deviceIpv4 => 'Adresse IPv4';

  @override
  String get deviceIpv6 => 'Adresses IPv6';

  @override
  String get deviceAppUptime => 'Temps de fonctionnement de l\'application';

  @override
  String get deviceNetworkUptime => 'Temps de fonctionnement réseau';

  @override
  String get deviceCpuUsage => 'Utilisation du CPU';

  @override
  String get deviceCpuTemp => 'Température du CPU';

  @override
  String get deviceBatteryLevel => 'Niveau de batterie';

  @override
  String get deviceScreenBrightness => 'Luminosité de l\'écran';

  @override
  String get deviceScreenStatus => 'État de l\'écran';

  @override
  String get deviceScreenSize => 'Taille de l\'écran';

  @override
  String get deviceRam => 'RAM (libre/totale)';

  @override
  String get deviceStorage => 'Stockage interne (libre/total)';

  @override
  String get deviceHaUrl => 'URL Home Assistant';

  @override
  String get deviceWakeDetection => 'Détection du mot de réveil';

  @override
  String get deviceWakeStatus => 'État du mot de réveil';

  @override
  String get deviceEngine => 'Moteur';

  @override
  String get deviceWakeWords => 'Mots de réveil';

  @override
  String get deviceStopWord => 'Mot d\'arrêt';

  @override
  String get deviceMotionDetection => 'Détection de mouvement';

  @override
  String get deviceFaceDetection => 'Détection de visage';

  @override
  String get deviceProvider => 'Fournisseur';

  @override
  String get deviceVersion => 'Version';

  @override
  String get deviceUserAgent => 'Agent utilisateur';

  @override
  String get devicePlugged => 'branché';

  @override
  String get deviceLowMemory => 'faible';

  @override
  String get deviceRequiredPermissions => 'Autorisations système requises';

  @override
  String get devicePermissionIntro =>
      'Les autorisations sont accordées sur cet appareil : chaque bouton ouvre donc ici une boîte de dialogue Android ou un écran de paramètres. Certaines marques ajoutent leur propre gestionnaire de batterie ou de démarrage automatique, qu\'Android ne peut pas signaler.';

  @override
  String get devicePermissionIntroRemote =>
      'Les autorisations sont accordées sur l\'appareil : chaque bouton ouvre donc là-bas une boîte de dialogue Android ou un écran de paramètres. Certaines marques ajoutent leur propre gestionnaire de batterie ou de démarrage automatique, qu\'Android ne peut pas signaler.';

  @override
  String get deviceMicrophone => 'Microphone';

  @override
  String get deviceMicrophoneHeld =>
      'Autorise l\'utilisation du microphone pour la détection du mot de réveil, la reconnaissance vocale et les appels d\'interphone.';

  @override
  String get deviceBattery => 'Batterie sans restriction';

  @override
  String get deviceBatteryHeld =>
      'Autorise le processus à s\'exécuter en arrière-plan sans être mis en pause ou arrêté.';

  @override
  String get deviceCamera => 'Caméra';

  @override
  String get deviceCameraHeld =>
      'La détection de mouvement et les instantanés peuvent utiliser la caméra.';

  @override
  String get deviceBluetooth => 'Appareils à proximité';

  @override
  String get deviceBluetoothHeld =>
      'Le proxy Bluetooth peut rechercher les appareils à proximité.';

  @override
  String get deviceNotifications => 'Notifications';

  @override
  String get deviceNotificationsHeld =>
      'Autorise la notification permanente du Kiosk Satellite Service, qui indique ce que le service maintient actif.';

  @override
  String get deviceOverlay => 'Affichage par-dessus d\'autres applications';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite peut se remettre lui-même au premier plan.';

  @override
  String get deviceWriteSettings => 'Modifier les paramètres système';

  @override
  String get deviceWriteSettingsHeld =>
      'Les changements de luminosité règlent la luminosité réelle de l\'écran.';

  @override
  String get deviceUiGuard => 'Protection de l\'interface système';

  @override
  String get deviceUiGuardHeld =>
      'Le panneau de notifications et l\'écran des applications récentes se ferment d\'eux-mêmes tant que l\'écran est protégé.';

  @override
  String get deviceDeviceAdmin => 'Administrateur de l\'appareil';

  @override
  String get deviceDeviceAdminHeld =>
      'Autorise l\'application à éteindre l\'écran.';

  @override
  String get deviceAllFiles => 'Accès à tous les fichiers';

  @override
  String get deviceAllFilesHeld =>
      'Le gestionnaire de fichiers peut parcourir le stockage partagé.';

  @override
  String get deviceUsageAccess => 'Accès à l\'utilisation';

  @override
  String get deviceUsageAccessHeld =>
      'Le capteur d\'application au premier plan peut nommer l\'application actuellement à l\'écran.';

  @override
  String get deviceLocation => 'Localisation';

  @override
  String get deviceLocationHeld =>
      'Les pages, la recherche Bluetooth et les capteurs de localisation peuvent utiliser la position de l\'appareil.';

  @override
  String get deviceMicBlocked =>
      'Bloqué. Android ne redemandera pas l\'autorisation : autorisez-la dans les paramètres de l\'application.';

  @override
  String get deviceMicMissing =>
      'La détection du mot de réveil est activée et rien n\'écoute.';

  @override
  String get deviceMicIdle =>
      'Nécessaire pour la détection du mot de réveil, l\'interphone et les pages qui demandent le microphone.';

  @override
  String get deviceBatteryMissing =>
      'Android peut mettre l\'application en pause lorsque l\'écran est éteint, ce qui coupe du même coup la connexion Home Assistant et les entités ESPHome.';

  @override
  String get deviceCameraMissing =>
      'La caméra est activée et ne peut pas être ouverte.';

  @override
  String get deviceCameraIdle =>
      'Nécessaire pour la détection de mouvement, les instantanés de caméra et les pages qui demandent la caméra.';

  @override
  String get deviceBluetoothMissing =>
      'Le proxy Bluetooth est activé et ne peut pas effectuer de recherche.';

  @override
  String get deviceBluetoothLocation =>
      'La recherche Bluetooth nécessite l\'autorisation de localisation.';

  @override
  String get deviceBluetoothLocationOff =>
      'La localisation est désactivée dans les paramètres de l\'appareil, la recherche Bluetooth ne trouve donc rien.';

  @override
  String get deviceBluetoothIdle =>
      'Nécessaire au proxy Bluetooth pour rechercher des appareils.';

  @override
  String get deviceNotificationMissing =>
      'Nécessaire pour afficher la notification permanente du Kiosk Satellite Service.';

  @override
  String get deviceOverlayMissing =>
      'Sans cela, l\'application ne peut pas se rouvrir après un plantage, une mise à jour ou un mot de réveil détecté derrière une autre application.';

  @override
  String get deviceOverlayIdle =>
      'Permet à l\'application de se remettre au premier plan, et au bouclier de verrouillage de couvrir tout l\'écran.';

  @override
  String get deviceBrightnessMissing =>
      'La luminosité n\'assombrit que la fenêtre de l\'application : le changement n\'est jamais répercuté sur l\'écran ni dans Home Assistant.';

  @override
  String get deviceBrightnessIdle =>
      'Nécessaire pour régler la luminosité réelle de l\'écran plutôt que d\'assombrir la fenêtre de l\'application.';

  @override
  String get deviceGuardMissing =>
      'Le panneau de notifications et l\'écran des applications récentes restent accessibles. Activez Kiosk Satellite dans Accessibilité.';

  @override
  String get deviceGuardIdle =>
      'Ferme le panneau de notifications et l\'écran des applications récentes tant que le mode kiosque protège l\'écran.';

  @override
  String get deviceAdminIdle =>
      'Permet d\'éteindre réellement l\'écran (coupure de l\'alimentation du panneau) au lieu de simplement l\'afficher en noir.';

  @override
  String get deviceFilesIdle =>
      'Permet au gestionnaire de fichiers de parcourir le stockage partagé plutôt que le seul dossier de l\'application.';

  @override
  String get deviceUsageIdle =>
      'Permet au capteur d\'application au premier plan de nommer des applications autres que Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Android ne transmettra pas les résultats de recherche Bluetooth sans la localisation, et les capteurs de localisation ne peuvent pas lire le récepteur GPS.';

  @override
  String get deviceLocationIdle =>
      'Utilisé par les pages qui demandent votre position, par la recherche Bluetooth et par les capteurs de localisation ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Sans cela, le service ne peut pas relancer le kiosque après un plantage ou une fermeture depuis les applications récentes.';

  @override
  String get deviceServiceOverlayIdle =>
      'Nécessaire pour relancer le kiosque après un plantage.';

  @override
  String get deviceListeningMissing =>
      'L\'écoute en arrière-plan est activée et rien n\'écoute.';

  @override
  String get deviceListeningIdle => 'Nécessaire à l\'écoute en arrière-plan.';

  @override
  String get deviceMotionIdle => 'Nécessaire à la détection de mouvement.';

  @override
  String get deviceBatteryAdb =>
      'Cet appareil n\'a pas d\'écran de paramètres pour cela. Accordez-la via adb : adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Cet appareil n\'a pas d\'écran de paramètres pour cela. Accordez-la via adb : adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get settingRemoteEnabledTitle => 'Gestion à distance';

  @override
  String get settingRemoteEnabledDescription =>
      'Exécuter le serveur web d\'administration intégré.';

  @override
  String get settingRemotePortTitle => 'Port du serveur';

  @override
  String get settingRemotePortDescription =>
      'Port de l\'interface d\'administration à distance.';

  @override
  String get settingRemotePasswordTitle => 'Mot de passe d\'administration';

  @override
  String get settingRemotePasswordDescription =>
      'Requis pour se connecter à l\'interface à distance.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Trouver d\'autres kiosques';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Annoncer cet appareil sur le réseau et lister les autres kiosques dans l\'administration à distance, pour basculer entre eux.';

  @override
  String get deviceRemotePage => 'Administration à distance';

  @override
  String get deviceAdminAddress => 'Adresse d\'administration';

  @override
  String get deviceAdminAddressHelp =>
      'Ouvrez cette adresse dans un navigateur sur votre ordinateur.';

  @override
  String get deviceByName => 'Par nom';

  @override
  String get deviceByNameHelp =>
      'La même adresse par nom d\'hôte, sur les réseaux qui résolvent les noms .local.';

  @override
  String get devicePasswordNeeded =>
      'Définissez un mot de passe d\'administration ci-dessous pour démarrer le serveur.';

  @override
  String get deviceServerStopped =>
      'Le serveur n\'est pas en cours d\'exécution.';

  @override
  String devicePortError(String port, String error) {
    return 'Impossible d\'écouter sur le port $port : $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Utiliser HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Chiffre l’administration à distance, l’API et les connexions WebSocket. Votre navigateur pourra vous demander d’accepter le certificat de l’appareil.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Maintenir le CPU actif lorsque l\'écran est éteint';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Maintient un verrou de réveil lorsque l\'écran est éteint afin que les connexions et les minuteries continuent de fonctionner à l\'heure. Consomme de la batterie sur une tablette débranchée.';

  @override
  String get deviceServicePage => 'Kiosk Satellite Service';

  @override
  String get deviceKeepingRunning => 'Ce qui le maintient actif';

  @override
  String get deviceService => 'Service';

  @override
  String get deviceStopped => 'Arrêté';

  @override
  String get deviceStoppedSentence => 'Arrêté.';

  @override
  String get deviceRunning => 'En cours d\'exécution';

  @override
  String get deviceRunningSentence => 'En cours d\'exécution.';

  @override
  String get deviceRunningBackground =>
      'En cours d\'exécution sans l\'exemption de premier plan.';

  @override
  String get deviceServiceTypes => 'Types de service au premier plan';

  @override
  String get deviceServiceTypesHelp =>
      'Ce que le service déclare à Android pour les fonctionnalités qu\'il maintient.';

  @override
  String get deviceNoneDeclared => 'Aucun type déclaré.';

  @override
  String get deviceNone => 'aucun';

  @override
  String get deviceCpuLock => 'Verrou de réveil du CPU';

  @override
  String get deviceCpuOff =>
      'Désactivé : le paramètre ci-dessous est désactivé.';

  @override
  String get deviceCpuHeld => 'Maintenu : l\'écran est éteint.';

  @override
  String get deviceCpuReleased => 'Libéré tant que l\'écran est allumé.';

  @override
  String get deviceNotHeld => 'Non maintenu.';

  @override
  String get deviceHeld => 'Maintenu';

  @override
  String get deviceReleased => 'Libéré';

  @override
  String get deviceWifiLock => 'Verrou Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Maintenu : la radio reste hors mode économie d\'énergie.';

  @override
  String get deviceWifiHelp =>
      'Maintient la radio hors mode économie d\'énergie pendant l\'extinction de l\'écran.';

  @override
  String get deviceNotification => 'Notification';

  @override
  String get deviceNotificationHidden =>
      'Masquée : les notifications sont désactivées pour l\'application. Le service s\'exécute malgré tout.';

  @override
  String get deviceNotificationShown =>
      'Affichée dans le panneau de notifications tant que le service s\'exécute.';

  @override
  String get deviceHidden => 'Masquée';

  @override
  String get deviceShown => 'Affichée';

  @override
  String get deviceReasonHa => 'Connexion Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Maintient ouverte la session du tableau de bord et son websocket tant que l\'écran est éteint.';

  @override
  String get deviceReasonListening => 'Écoute en arrière-plan';

  @override
  String get deviceReasonListeningHelp =>
      'Maintient le moteur de mot de réveil et son microphone actifs derrière d\'autres applications.';

  @override
  String get deviceReasonRtsp => 'Audio microphone RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Maintient le flux du microphone disponible pour les spectateurs RTSP connectés.';

  @override
  String get deviceReasonEspHome => 'Serveur ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Maintient le serveur API ESPHome disponible pour Home Assistant.';

  @override
  String get deviceReasonRemote => 'Administration à distance';

  @override
  String get deviceReasonRemoteHelp =>
      'Maintient le serveur web d\'administration disponible.';

  @override
  String get deviceReasonProtections => 'Protections du kiosque';

  @override
  String get deviceReasonProtectionsHelp =>
      'Relance le kiosque lorsqu\'il est fermé depuis les applications récentes ou qu\'il plante.';

  @override
  String get deviceReasonBluetooth => 'Proxy Bluetooth';

  @override
  String get deviceReasonBluetoothHelp =>
      'Maintient la recherche Bluetooth active pendant que l\'application n\'est pas à l\'écran.';

  @override
  String get deviceReasonLocation => 'Capteurs de localisation';

  @override
  String get deviceReasonLocationHelp =>
      'Maintient l\'arrivée des positions GPS tant que l\'écran est éteint ou qu\'une autre application est au premier plan.';

  @override
  String get deviceReasonPerson => 'Détection de présence';

  @override
  String get deviceReasonPersonHelp =>
      'Continue de lire le capteur de présence de l\'appareil pendant qu\'une autre application est au premier plan.';

  @override
  String get deviceReasonCameraHelp =>
      'Maintient la caméra utilisable après l\'extinction de l\'écran, pour la détection de mouvement et de visage.';

  @override
  String deviceServiceStopped(String error) {
    return 'Arrêté : $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'En cours d\'exécution depuis $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Installer les mises à jour via Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Installer les mises à jour de Kiosk Satellite sans confirmation sur l\'appareil. Shizuku doit être en cours d\'exécution et autorisé.';

  @override
  String get deviceShizukuAccess => 'Accès Shizuku';

  @override
  String get deviceShizukuCheck => 'Vérification de la disponibilité';

  @override
  String get deviceShizukuRoot => 'Connecté avec un accès root';

  @override
  String get deviceShizukuShell => 'Connecté avec un accès shell';

  @override
  String get deviceShizukuGrant =>
      'Appuyez pour autoriser l\'accès. Approuvez la demande sur ce kiosque.';

  @override
  String get deviceShizukuGrantRemote =>
      'Autorisez l\'accès et approuvez la demande sur ce kiosque.';

  @override
  String get deviceShizukuDenied =>
      'Autorisez Kiosk Satellite dans l\'application Shizuku.';

  @override
  String get deviceShizukuUnsupported =>
      'Shizuku 13 ou une version ultérieure est requis.';

  @override
  String get deviceShizukuStart => 'Démarrez Shizuku sur cet appareil.';

  @override
  String get deviceShizukuTest => 'Tester la connexion';

  @override
  String get deviceShizukuTestHelp =>
      'Lire l\'identité du processus sans modifier l\'appareil.';

  @override
  String get deviceShizukuTestTitle => 'Test de connexion';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku n\'a pas pu terminer le test de connexion.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Toutes les autorisations sont déjà accordées.';

  @override
  String get deviceShizukuConfirmed =>
      'Android a confirmé les autorisations demandées.';

  @override
  String get deviceShizukuResults => 'Résultats des autorisations';

  @override
  String get deviceShizukuGrantAll => 'Accorder toutes les autorisations';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Accorde toutes les autorisations utilisées par KS, y compris pour les fonctionnalités actuellement désactivées.';

  @override
  String get deviceShizukuSetup => 'Configurer Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Lire les instructions d\'installation et de démarrage.';

  @override
  String get deviceShizukuLifetime =>
      'Shizuku démarré via ADB doit être relancé après chaque redémarrage de l\'appareil. L\'accès shell ne fournit pas les autorisations root.';

  @override
  String get deviceShizukuFailed => 'Échec de la demande Shizuku';

  @override
  String get deviceShizukuApprove => 'Approuvez la demande sur le kiosque.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku a exécuté avec succès une commande avec un accès $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android n\'a pas confirmé cette autorisation. Vérifiez le Gestionnaire d\'autorisations sur l\'appareil.';

  @override
  String get shizukuPermissionReadFailed =>
      'Impossible de lire les autorisations actuelles. Réessayez.';

  @override
  String get shizukuRestartTimedOut => 'La commande de redémarrage a expiré';

  @override
  String get shizukuRestartRefused => 'Android a refusé le redémarrage';

  @override
  String get shizukuCommandTimedOut => 'La commande a expiré';

  @override
  String get shizukuRequestRejected => 'Android a rejeté la demande';

  @override
  String get deviceDisconnectedError => 'Appareil déconnecté';

  @override
  String get deviceResponseTimedOut => 'La réponse de l\'appareil a expiré';

  @override
  String get deviceRequestAborted => 'Demande interrompue';

  @override
  String get shizukuActionBusy =>
      'Une action Shizuku sur l\'appareil est déjà en cours';

  @override
  String get shizukuGrantFirst => 'Autorisez d\'abord l\'accès à Shizuku';

  @override
  String get shizukuNoResponse => 'La commande Shizuku n\'a pas répondu';

  @override
  String get shizukuCommandFailed => 'Échec de la commande Shizuku';

  @override
  String get shizukuStartRequired =>
      'Démarrez Shizuku 13 ou une version ultérieure et autorisez Kiosk Satellite dans Shizuku';

  @override
  String get shizukuConnectionFailed => 'Échec de la connexion Shizuku';

  @override
  String get shizukuHelperNotConnected =>
      'L\'assistant Shizuku ne s\'est pas connecté';

  @override
  String get shizukuHelperUnavailable =>
      'L\'assistant Shizuku n\'est pas disponible';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Chiffrement des connexions et certificats';

  @override
  String get tlsCertificateType => 'Type de certificat';

  @override
  String get tlsImported => 'Importé';

  @override
  String get tlsSelfSigned => 'Autosigné';

  @override
  String get tlsExpires => 'Expire le';

  @override
  String get tlsSHA256Fingerprint => 'Empreinte SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'Le certificat a expiré. Renouvelez-le ou importez-en un nouveau.';

  @override
  String get tlsCopyPublicCertificate => 'Copier le certificat public';

  @override
  String get tlsDownloadPublicCertificate => 'Télécharger le certificat public';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Utilisez ce certificat dans les navigateurs et les clients de streaming.';

  @override
  String get tlsRenewCertificate => 'Renouveler le certificat';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Conserve la clé privée actuelle et met à jour les dates de validité du certificat.';

  @override
  String get tlsImportCertificate => 'Importer un certificat';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Utilisez un certificat émis pour cet appareil.';

  @override
  String get tlsReplaceCertificate => 'Remplacer le certificat';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Génère une nouvelle clé privée et un certificat autosigné.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      'Générer une nouvelle clé privée et un nouveau certificat ? Les connexions chiffrées actives seront fermées. Les navigateurs pourront vous demander d’accepter le nouveau certificat.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Collez la chaîne de certificats PEM et sa clé privée non chiffrée. Elles seront vérifiées avant de remplacer le certificat actuel.';

  @override
  String get tlsCertificateChainPEM => 'Chaîne de certificats (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Clé privée (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Ce champ est obligatoire.';

  @override
  String get tlsReplace => 'Remplacer';

  @override
  String get tlsRenew => 'Renouveler';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Activez HTTPS avant d’importer une clé privée à distance.';

  @override
  String get tlsCertificateOperationFailed =>
      'L’opération sur le certificat a échoué.';

  @override
  String get tlsChangeConnectionProtocol => 'Changer le protocole de connexion';

  @override
  String get tlsConnectionProtocolHelp =>
      'La connexion à distance actuelle sera fermée. Reconnectez-vous avec l’adresse ci-dessous. Vous devrez peut-être vous identifier à nouveau.';

  @override
  String get tlsConfirm => 'Confirmer';

  @override
  String get tlsCertificateManagement => 'Gestion des certificats';

  @override
  String get tlsServerCertificateRequired =>
      'Utilisez un certificat de serveur, pas un certificat d’autorité de certification.';

  @override
  String get tlsServerAuthenticationRequired =>
      'Le certificat n’autorise pas l’authentification du serveur.';

  @override
  String get tlsKeyAlgorithmRequired => 'Utilisez une clé privée EC ou RSA.';

  @override
  String get tlsKeyMismatch =>
      'Le certificat et la clé privée ne correspondent pas.';

  @override
  String get tlsMaterialTooLarge =>
      'Le certificat ou la clé est trop volumineux.';

  @override
  String get tlsPemCertificatesRequired => 'Des certificats PEM sont attendus.';

  @override
  String get tlsCertificateMissing => 'Aucun certificat trouvé.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Utilisez une clé privée PEM non chiffrée.';

  @override
  String get tlsHostnameRequired =>
      'Un nom d’hôte ou une adresse IP est nécessaire.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Importez un certificat renouvelé par son émetteur.';

  @override
  String get tlsStoredIdentityDamaged =>
      'L’identité TLS enregistrée est endommagée.';

  @override
  String get tlsExpiredCertificate =>
      'Le certificat TLS a expiré. Renouvelez-le ou importez-en un nouveau.';

  @override
  String get deviceHelperPage => 'Assistant de mise à jour optionnel';

  @override
  String get deviceHelperStatus => 'État de l\'assistant';

  @override
  String get deviceHelperError =>
      'Impossible de vérifier l\'assistant de mise à jour.';

  @override
  String get deviceHelperUnneeded =>
      'Android peut désormais installer les mises à jour silencieusement. L\'assistant n\'est pas nécessaire.';

  @override
  String get deviceHelperIntro =>
      'Cet appareil nécessite actuellement une confirmation à l\'écran pour installer les mises à jour via Android. L\'assistant optionnel permet à Kiosk Satellite d\'installer les mises à jour sans confirmation.';

  @override
  String get deviceHelperBusy => 'Installation d\'une mise à jour en cours.';

  @override
  String get deviceHelperReady =>
      'Prêt. Les mises à jour s\'installent sans confirmation.';

  @override
  String get deviceHelperUnavailable =>
      'Indisponible. Démarrez l\'assistant via ADB pour activer les mises à jour sans confirmation.';

  @override
  String get deviceHelperLifetime =>
      'L\'assistant survit aux redémarrages et mises à jour de l\'application, mais s\'arrête après un redémarrage de l\'appareil. Exécutez la commande depuis un ordinateur avec ADB pour le redémarrer. L\'ordinateur peut ensuite être déconnecté.';

  @override
  String get deviceHelperStart => 'Démarrer via ADB';

  @override
  String get deviceHelperGuide => 'Guide de configuration';

  @override
  String get deviceHelperGuideHelp =>
      'Lisez les instructions et prérequis de l\'assistant de mise à jour.';

  @override
  String get settingUpdateSourceTitle => 'Source des mises à jour';

  @override
  String get settingUpdateSourceDescription =>
      'Où l\'application recherche les nouvelles versions.';

  @override
  String get settingUpdateSourceUrlTitle => 'URL du dépôt';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Un dossier sur un serveur web accessible par le kiosque, contenant releases.json et les APK des versions.';

  @override
  String get deviceUpdatesPage => 'Mises à jour';

  @override
  String get deviceUpdateGithub => 'Dépôt GitHub';

  @override
  String get deviceUpdateCustom => 'Dépôt personnalisé';

  @override
  String get deviceUpdateGuide => 'Guide du dépôt personnalisé';

  @override
  String get deviceUpdateGuideHelp =>
      'Comment héberger le fichier des versions et les APK sur votre propre réseau.';

  @override
  String get deviceInstallFile => 'Installer depuis un fichier';

  @override
  String get deviceInstallFileHelp =>
      'Envoyez un APK de Kiosk Satellite depuis un ordinateur via l\'administration à distance, sur cette même page. Pour un kiosque qui ne peut pas atteindre GitHub ou un dépôt personnalisé.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Envoyez un APK de Kiosk Satellite depuis cet ordinateur et installez-le. Pour un kiosque qui ne peut pas atteindre GitHub ou un dépôt personnalisé.';

  @override
  String get deviceUploadedApk => 'APK envoyé';

  @override
  String get deviceInstalling => 'Installation…';

  @override
  String get deviceDeviceNoAnswer => 'L\'appareil n\'a pas répondu.';

  @override
  String get deviceInstallFailed =>
      'Échec de la mise à jour. Consultez les journaux de l\'appareil.';

  @override
  String get deviceConfirmTablet => 'Confirmer sur l\'écran de la tablette';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'La version $version (build $build, $size Mo) est sur l\'appareil, en attente d\'installation.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Installer la version $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'L\'appareil a répondu HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'L\'envoi a échoué.';

  @override
  String get deviceInstallFleet => 'Installer sur la flotte';

  @override
  String get deviceSendingFleet => 'Envoi à la flotte…';

  @override
  String get deviceSameBuild => 'Le kiosque exécute déjà ce build.';

  @override
  String get deviceInstallConfirmation =>
      'L\'installation doit être confirmée sur l\'écran de la tablette, sauf si le kiosque installe silencieusement.';

  @override
  String get deviceSelfLast => 'Ce kiosque s\'installe en dernier.';

  @override
  String get deviceUpdatingFleet => 'Mise à jour de la flotte';

  @override
  String deviceUploading(String percent) {
    return 'Envoi… $percent %';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'L\'APK envoyé est la version $version (build $build, $size Mo).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'Le kiosque exécute $version (build $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Envoi à $name… $percent %';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Installation sur $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return '$names en cours d\'installation.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Saisissez l\'URL du dossier, par exemple http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Saisissez uniquement l\'URL du dossier, sans rien après le chemin. Exemple : http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Un téléchargement est en cours. Attendez qu\'il se termine.';

  @override
  String get updateInstallBusy =>
      'Une installation est en cours. Attendez qu\'elle se termine.';

  @override
  String get updateNoAvailable => 'Aucune mise à jour disponible.';

  @override
  String get updateNoUploaded => 'Aucun APK envoyé n\'est en attente.';

  @override
  String get updateUploadEmpty => 'L\'envoi était vide.';

  @override
  String get updateInvalidApk => 'Ce fichier n\'est pas un APK Android.';

  @override
  String get updateUploadedGone =>
      'L\'APK envoyé a disparu. Envoyez-le à nouveau.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku n\'a pas pu installer la mise à jour. Le programme d\'installation avec confirmation n\'a pas été ouvert.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'Espace libre insuffisant : l\'APK fait $size Mo et l\'installation nécessite environ $required Mo, mais l\'appareil dispose de $free Mo libres.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'L\'envoi a été interrompu après $size Mo : $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'L\'envoi s\'est terminé prématurément : $received sur $expected Mo reçus.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'L\'APK est $package, pas Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'L\'APK est la version $version (build $build), antérieure à la version en cours d\'exécution $currentVersion (build $currentBuild). Les installations d\'une version antérieure sont refusées : Android ne les accepterait pas non plus.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'Échec du téléchargement (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'Le téléchargement s\'est bloqué : aucune donnée reçue depuis $seconds secondes.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get updateAnotherPackage => 'un autre package';

  @override
  String get settingUiLanguageTitle => 'Langue';

  @override
  String get settingUiLanguageDescription =>
      'Langue de Kiosk Satellite et de l\'administration à distance. Home Assistant conserve sa propre langue.';

  @override
  String get settingUiThemeTitle => 'Thème de l\'application';

  @override
  String get settingUiThemeDescription =>
      'Clair ou sombre pour les écrans propres de l\'application : menu, paramètres, boîtes de dialogue. « Système » suit le paramètre Android.';

  @override
  String get settingUiScaleTitle => 'Mise à l\'échelle de l\'interface';

  @override
  String get settingUiScaleDescription =>
      'Taille des écrans propres de l\'application : menu, paramètres, boîtes de dialogue. Pour les écrans à haute densité. Le contenu web conserve sa taille.';

  @override
  String get deviceUserInterface => 'Interface utilisateur';

  @override
  String get deviceThemeDark => 'Sombre';

  @override
  String get deviceThemeLight => 'Clair';

  @override
  String get deviceThemeSystem => 'Système';

  @override
  String get settingDlnaEnabledTitle => 'Activer le récepteur DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Afficher des images et lire des médias envoyés depuis Home Assistant ou toute application DLNA. L\'appareil apparaît comme un lecteur multimédia nommé d\'après le nom de l\'appareil.';

  @override
  String get settingDlnaAudioBackgroundTitle =>
      'Garder l\'audio en arrière-plan';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'L\'audio envoyé est lu sans prendre le contrôle de l\'écran.';

  @override
  String get settingDlnaPortTitle => 'Port du serveur';

  @override
  String get settingDlnaPortDescription =>
      'Le port sur lequel le récepteur fonctionne, renseigné à son démarrage. Modifiez-le pour déplacer le récepteur, ou effacez-le pour le laisser en choisir un autre.';

  @override
  String get settingDlnaPortPlaceholder => 'Défini au démarrage du récepteur';

  @override
  String get settingEsphomeRealMacTitle =>
      'Utiliser l\'adresse MAC Wi-Fi réelle';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant relie ce kiosque au même appareil que vos intégrations réseau suivent déjà. Modifier ceci crée un nouvel appareil ESPHome dans Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle =>
      'Utiliser une adresse MAC Wi-Fi personnalisée';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Comme l\'adresse MAC ne peut pas être déterminée, vous pouvez utiliser ce champ pour saisir la vôtre. Modifier ceci crée un nouvel appareil ESPHome dans Home Assistant.';

  @override
  String get esphomeAdvanced => 'Paramètres avancés';

  @override
  String get esphomeAdvancedHelp => 'Adresse MAC Wi-Fi réelle ou personnalisée';

  @override
  String get esphomeMacInvalid => 'Saisissez une adresse MAC valide.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Adresse signalée : $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Adresse signalée : $mac, saisie ci-dessous.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android ne révélera pas l\'adresse matérielle de cet appareil.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Activer les annonces';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Lire les annonces que Home Assistant envoie avec l\'action announce.';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Moteur de synthèse vocale';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'L\'entité de synthèse vocale de Home Assistant qui prononce les annonces.';

  @override
  String get esphomeTtsFirst => 'Premier disponible';

  @override
  String get settingAnnouncementsChimeTitle => 'Carillon en premier';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Jouer un carillon avant l\'annonce.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Son du carillon';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Joué au volume des notifications.';

  @override
  String get esphomeAnnouncements => 'Annonces';

  @override
  String get esphomeAnnouncementsHelp =>
      'Annonces vocales depuis Home Assistant';

  @override
  String get esphomeChime => 'Carillon';

  @override
  String get esphomeTtsUnavailable => 'Impossible de joindre Home Assistant';

  @override
  String get settingBtproxyEnabledTitle => 'Activer le proxy Bluetooth';

  @override
  String get settingBtproxyEnabledDescription =>
      'Relayer les appareils Bluetooth à proximité vers Home Assistant.';

  @override
  String get settingBtproxyScanDutyTitle => 'Intensité de recherche';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Part du temps pendant laquelle la radio écoute. Une valeur plus basse réduit l\'usage du CPU ; les appareils qui s\'annoncent rarement mettent plus de temps à apparaître.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Autoriser les connexions d\'appareils';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant peut se connecter aux appareils Bluetooth via ce proxy.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Rechercher les fabricants d\'appareils en ligne';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Identifie les appareils à proximité inconnus grâce au préfixe de leur adresse matérielle, via api.macvendors.com. Seul le préfixe fabricant de 3 octets est envoyé, une fois par fabricant ; rien d\'autre ne quitte l\'appareil.';

  @override
  String get settingBtproxyNearbySortTitle => 'Trier par';

  @override
  String get settingBtproxyNearbySortDescription =>
      'L\'ordre de la liste des appareils à proximité ci-dessous.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Signal minimum pour les connexions';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Refuser les connexions d\'appareils dont le signal est plus faible que cette valeur, afin qu\'un proxy plus proche s\'en charge.';

  @override
  String get esphomeOptionContinuous => 'Continu';

  @override
  String get esphomeOptionBalanced => 'Équilibré';

  @override
  String get esphomeOptionLowPower => 'Faible consommation';

  @override
  String get esphomeOptionLastSeen => 'Dernière détection';

  @override
  String get esphomeOptionName => 'Nom';

  @override
  String get esphomeOptionMacAddress => 'Adresse MAC';

  @override
  String get esphomeOptionSignalStrength => 'Force du signal';

  @override
  String get esphomeOptionNoLimit => 'Aucune limite';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (même pièce)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (limite de portée)';

  @override
  String get esphomeBluetooth => 'Proxy Bluetooth';

  @override
  String get esphomeBluetoothHelp =>
      'Relayer les appareils Bluetooth à proximité vers Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Le Bluetooth est désactivé. Activez-le pour utiliser le proxy.';

  @override
  String get esphomeBluetoothUnsupported =>
      'Non disponible sur cet appareil : il n\'a pas de Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'Non disponible sur cet appareil : son build Android ne prend pas en charge le Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Capteur BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Capteur Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Capteur Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Appareil Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Balise Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Appareil Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Appareil Apple Localiser';

  @override
  String get esphomeIdentityExposure =>
      'Notification d\'exposition (téléphone)';

  @override
  String get esphomeIdentityAugustYale => 'Serrure August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Appareil Amazon';

  @override
  String get esphomeIdentityTile => 'Traceur Tile';

  @override
  String get esphomeIdentityInput =>
      'Périphérique d\'entrée (télécommande/clavier)';

  @override
  String get esphomeIdentityHeartRate => 'Capteur de fréquence cardiaque';

  @override
  String get esphomeIdentityEnvironmental => 'Capteur environnemental';

  @override
  String get esphomeIdentityApple => 'Appareil Apple';

  @override
  String get esphomeIdentityWindows => 'PC Windows';

  @override
  String get esphomeIdentitySamsung => 'Appareil Samsung';

  @override
  String get esphomeIdentityGoogle => 'Appareil Google';

  @override
  String get esphomeIdentityUnknown => 'Appareil inconnu';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Appareil $vendor';
  }

  @override
  String get esphomeNearby => 'Appareils à proximité';

  @override
  String get esphomeNearbySearch =>
      'Les appareils Bluetooth que ce kiosque détecte, avec leur nom quand il est connu.';

  @override
  String get esphomeNearbyEmpty => 'Rien détecté pour l\'instant.';

  @override
  String get esphomeNearbyWaiting =>
      'Rien détecté pour l\'instant. Les appareils apparaissent ici une fois que le proxy a commencé sa recherche.';

  @override
  String get esphomeRotating => '(adresse changeante)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Affichage des $count premiers sur $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Jusqu\'à $count appareils peuvent être connectés simultanément via ce proxy. Home Assistant achemine les appareils supplémentaires via d\'autres proxys.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return 'il y a $count s';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return 'il y a $count min';
  }

  @override
  String esphomeHoursAgo(String count) {
    return 'il y a $count h';
  }

  @override
  String get settingLocationEnabledTitle => 'Signaler la position';

  @override
  String get settingLocationEnabledDescription =>
      'Lire la position GPS et la fournir à Home Assistant sous forme de capteurs latitude, longitude, précision, altitude et vitesse. Activer ou désactiver ceci réenregistre l\'appareil ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Intervalle de mise à jour';

  @override
  String get settingLocationIntervalDescription =>
      'Secondes entre les relevés de position.';

  @override
  String get esphomeGps => 'Capteur GPS';

  @override
  String get esphomeGpsHelp =>
      'Exposer les données du capteur GPS à Home Assistant';

  @override
  String get esphomeLocationOff => 'Désactivé.';

  @override
  String get esphomeLocationWaiting =>
      'En attente de la première position GPS. Un démarrage à froid à ciel ouvert peut prendre quelques minutes.';

  @override
  String get esphomeCoordinates => 'Dernières coordonnées';

  @override
  String get esphomeLocationDenied =>
      'Autorisation de localisation non accordée.';

  @override
  String get esphomeLocationAbsent => 'Aucun récepteur GPS.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS indisponible : $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'Non disponible sur cet appareil : il n\'a pas de récepteur GPS.';

  @override
  String get settingNotificationsTransparencyTitle => 'Transparence';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Laisse apparaître l\'écran derrière les cartes de notification. Le texte et les icônes restent opaques.';

  @override
  String get settingNotificationsBlurTitle => 'Flou d\'arrière-plan';

  @override
  String get settingNotificationsBlurDescription =>
      'Floute ce qui apparaît à travers une carte de notification transparente. Remarque : le flou ne peut pas être appliqué par-dessus la surface du tableau de bord Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Son de notification';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Les fichiers audio sont lus depuis Android/data/me.jxl.kiosk_satellite/files/sounds sur l\'appareil, également accessible depuis le gestionnaire de fichiers.';

  @override
  String get settingNotificationsVolumeTitle => 'Volume des notifications';

  @override
  String get settingNotificationsVolumeDescription =>
      'Le volume auquel le son de notification est joué, indépendamment des volumes multimédia et assistant.';

  @override
  String get esphomeNotifications => 'Notifications';

  @override
  String get esphomeNotificationsHelp =>
      'Transparence, flou, son de notification, notification de test';

  @override
  String get esphomeAppearance => 'Apparence';

  @override
  String get esphomeSound => 'Son';

  @override
  String get esphomeNotificationTest => 'Notification de test';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Les notifications sont envoyées depuis Home Assistant avec l\'action $action. Le test en affiche une par-dessus le tableau de bord.';
  }

  @override
  String get esphomeNotificationBody =>
      'Voici l\'aspect et le son d\'une notification de Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'L\'action Home Assistant qui envoie les notifications, et un bouton pour en afficher une.';

  @override
  String get esphomeLocation => 'Localisation';

  @override
  String get esphomeLocationSearch =>
      'L\'autorisation de localisation dont les capteurs de localisation ont besoin.';

  @override
  String get esphomeBluetoothSearch =>
      'L\'autorisation Appareils à proximité dont le proxy Bluetooth a besoin pour rechercher.';

  @override
  String get esphomeLocationMissing =>
      'Sans cela, le récepteur GPS ne peut pas être lu et les capteurs de localisation restent inconnus.';

  @override
  String get esphomeLocationServicesOff =>
      'La localisation est désactivée dans les paramètres de l\'appareil, le récepteur ne fournit donc rien.';

  @override
  String get esphomeLocationGranted =>
      'Les capteurs de localisation peuvent lire le récepteur GPS.';

  @override
  String get esphomeBluetoothGranted =>
      'Le proxy peut rechercher les appareils Bluetooth à proximité.';

  @override
  String get esphomeBluetoothMissing =>
      'Sans cela, le proxy ne peut pas rechercher d\'appareils.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android ne transmet les résultats de recherche Bluetooth, balises comprises, que si la localisation est accordée. Le proxy ne lit jamais la position de l\'appareil.';

  @override
  String get esphomeBluetoothLocationOff =>
      'La localisation est désactivée dans les paramètres de l\'appareil, la recherche Bluetooth ne trouve donc rien.';

  @override
  String get esphomeBluetoothBeacons =>
      'La recherche Bluetooth peut détecter les balises.';

  @override
  String get esphomeSent => 'Envoyé';

  @override
  String get esphomeNotsaved => 'Non enregistré';

  @override
  String get settingEsphomeEnabledTitle => 'Activer ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Présenter ce kiosque à Home Assistant comme un appareil ESPHome : ses capteurs et contrôles en tant qu\'entités natives. Détecté automatiquement.';

  @override
  String get settingEsphomeEntitiesTitle => 'Exposer les entités du kiosque';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Fournir les capteurs et contrôles de cet appareil comme entités ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Entités exclues';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Choisissez les entités à exclure de Home Assistant. Toutes les autres entités disponibles sont exposées. L\'enregistrement reconnecte ESPHome.';

  @override
  String get settingEsphomeNodeNameTitle => 'Nom du nœud';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Identifie ce kiosque sur le réseau. Home Assistant s\'en sert pour former les noms de ses actions ; le renommer renomme donc ces actions.';

  @override
  String get settingEsphomeNodeNamePlaceholder => 'Défini au premier démarrage';

  @override
  String get settingBtproxyKeyTitle => 'Clé de chiffrement';

  @override
  String get settingBtproxyKeyDescription =>
      'Collez cette clé dans Home Assistant lorsqu\'il demande la clé de chiffrement. Générée automatiquement au premier démarrage.';

  @override
  String get settingBtproxyKeyPlaceholder => 'Générée au premier démarrage';

  @override
  String get settingBtproxyPortTitle => 'Port API';

  @override
  String get settingBtproxyPortDescription =>
      'Le port auquel Home Assistant se connecte. Laissez vide pour le port standard ESPHome, 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'Le démarrage du serveur ESPHome a échoué : $error';
  }

  @override
  String get esphomeExcludedInvalid =>
      'Choisissez une liste d\'identifiants d\'entités.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Fait avec $heart par $author';
  }

  @override
  String get settingsBuyCoffee => 'M\'offrir un café';

  @override
  String get settingClapStrictnessTitle => 'Détection des claquements';

  @override
  String get settingClapStrictnessDescription =>
      'Le mode Strict exige des claquements plus forts et régulièrement espacés ; essayez-le si le bruit ambiant provoque de faux déclenchements.';

  @override
  String get gestureStrictnessStandard => 'Standard';

  @override
  String get gestureStrictnessStrict => 'Strict';

  @override
  String get gestureOff => 'Les gestes sont désactivés';

  @override
  String get gestureOffHelp =>
      'L\'option « Désactiver les gestes » est activée dans les paramètres du Mode kiosque.';

  @override
  String get gestureEmpty => 'Aucun geste configuré';

  @override
  String get gestureEmptyHelp =>
      'Un geste déclenche son action sans aucun contrôle visible.';

  @override
  String get gestureDeleteTooltip => 'Supprimer le geste';

  @override
  String get gestureDeleteTitle => 'Supprimer le geste ?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return 'Retirer ce geste ? Déclencheur : $trigger. Action : $action.';
  }

  @override
  String get gestureAdd => 'Ajouter un geste';

  @override
  String get gestureAddHelp =>
      'Choisissez un geste et l\'action qu\'il déclenche.';

  @override
  String get gestureTouchHelp =>
      'Les gestes sont observés, pas bloqués : les appuis atteignent aussi le tableau de bord. Les coins et les gestes à plusieurs doigts évitent donc d\'y déclencher quoi que ce soit.';

  @override
  String get gestureClapper => 'Détecteur de claquements';

  @override
  String get gestureReadFailed => 'Impossible de lire les paramètres.';

  @override
  String get gestureHandGestures => 'Gestes de la main';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Durée de maintien';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Maintenez le même geste des doigts pendant cette durée avant de lancer son action. Augmentez-la pour réduire les déclenchements accidentels.';

  @override
  String get gestureHoldInstant => 'Immédiat';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get settingHaHoldModeTitle => 'Mode maintien';

  @override
  String get settingHaHoldModeDescription =>
      'Garder la vue actuelle à l\'écran : l\'économiseur d\'écran, la rotation des vues du tableau de bord et la minuterie de retour à l\'accueil sont suspendus jusqu\'à sa désactivation.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Terminer le maintien automatiquement après';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Désactive automatiquement le mode maintien après la durée définie. Réglez sur 0 pour maintenir jusqu\'à une désactivation manuelle.';

  @override
  String get settingHaHoldMenuTitle => 'Afficher dans le menu du kiosque';

  @override
  String get settingHaHoldMenuDescription =>
      'Ajoute une entrée de menu pour activer et désactiver le mode maintien.';

  @override
  String get haHoldHint =>
      'Épingler la vue actuelle, fin automatique, entrée de menu';

  @override
  String get haNever => 'Jamais';

  @override
  String haMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String haHours(String hours) {
    return '$hours h';
  }

  @override
  String haHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get settingDisableSuspendTitle => 'Rester connecté en arrière-plan';

  @override
  String get settingDisableSuspendDescription =>
      'Désactive le paramètre « Suspendre les connexions en arrière-plan » de Home Assistant, qui couperait sinon la connexion quelques minutes après l\'extinction de l\'écran.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Suspendre le tableau de bord pendant l\'économiseur d\'écran';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Arrête de dessiner le tableau de bord tant que l\'économiseur d\'écran le recouvre, ce qui réduit l\'usage du CPU et du GPU ; la connexion reste active. Ne s\'applique pas à l\'économiseur d\'écran Tamisé.';

  @override
  String get settingWsFilterTitle =>
      'Filtrer les mises à jour du tableau de bord';

  @override
  String get settingWsFilterDescription =>
      'Ne traiter que les mises à jour des entités présentes sur la vue actuelle, réduisant les saccades sur les tablettes peu puissantes. Les vues qui ne peuvent pas être analysées restent non filtrées.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Suspendre les flux caméra du tableau de bord HA pendant l\'économiseur d\'écran';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Suspend les flux caméra pris en charge dont le son est coupé, sur le tableau de bord Home Assistant, tant que l\'économiseur d\'écran le recouvre. Les flux se reconnectent à sa fermeture. N\'affecte pas la caméra de l\'appareil ni la fonctionnalité Flux de caméras.';

  @override
  String get haOptimizations => 'Optimisations';

  @override
  String get haOptimizationsHint =>
      'Connexion en arrière-plan, pause du tableau de bord et des caméras, filtre de mise à jour';

  @override
  String get haScanUnavailable =>
      'Les détails d\'analyse ne sont pas disponibles pour la vue actuelle.';

  @override
  String get haScanDetails => 'Détails de l\'analyse du tableau de bord';

  @override
  String haWatchedTitle(String count) {
    return 'Entités surveillées ($count)';
  }

  @override
  String get haWatched => 'Entités surveillées';

  @override
  String get haEntityListUnavailable =>
      'La liste des entités n\'est pas disponible pour le moment.';

  @override
  String haWatching(String count) {
    return '$count entités surveillées sur cette vue.';
  }

  @override
  String get haNoUpdates =>
      'Aucune mise à jour au cours de la dernière minute.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return '$percent % des mises à jour filtrées au cours de la dernière minute ($dropped sur $total).';
  }

  @override
  String get haRawUpdates =>
      'Un élément de cette page reçoit de toute façon chaque mise à jour d\'entité : le filtrage apporte donc moins de gain ici.';

  @override
  String get haAllStates =>
      'Cette vue lit tous les états d\'entités : ses mises à jour ne sont donc pas filtrées.';

  @override
  String get haUnknownEntities =>
      'Les entités de cette vue ne peuvent pas être déterminées : ses mises à jour ne sont donc pas filtrées.';

  @override
  String get haWaiting => 'En attente du chargement du tableau de bord…';

  @override
  String get haShowScan => 'Afficher les détails de l\'analyse.';

  @override
  String haThreshold(String count) {
    return 'Cette vue utilise $count entités, ce qui dépasse le seuil de filtrage. Le filtrage est désactivé.';
  }

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Revenir à la vue d\'accueil du tableau de bord';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Revenir au tableau de bord configuré ci-dessus après une période d\'inactivité.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Revenir après (secondes)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Période d\'inactivité avant que le kiosque revienne à l\'accueil.';

  @override
  String get haReturnHint => 'Revenir à la vue d\'accueil en cas d\'inactivité';

  @override
  String get haReturnDisabled =>
      'Désactivé tant que la rotation des vues du tableau de bord est activée.';

  @override
  String get haReturnNoPath =>
      'Le tableau de bord configuré n\'a pas de chemin de vue vers lequel revenir.';

  @override
  String haReturnPath(String path) {
    return 'Revient à « $path » après le délai.';
  }

  @override
  String get settingHaRotationEnabledTitle =>
      'Activer la rotation des vues du tableau de bord';

  @override
  String get settingHaRotationEnabledDescription =>
      'Parcourir les vues sélectionnées du tableau de bord en boucle infinie, en affichant chacune pendant le nombre de secondes choisi.';

  @override
  String get settingHaRotationSecondsTitle => 'Secondes par vue';

  @override
  String get settingHaRotationSecondsDescription =>
      'Durée d\'affichage de chaque vue à l\'écran.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Suspendre la rotation lors d\'une interaction (secondes)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Un appui sur l\'écran suspend la rotation pendant cette durée ; chaque nouvel appui relance le décompte. Les interactions vocales suspendent la rotation jusqu\'à leur fin. 0 laisse la rotation continuer malgré les appuis.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Fondu entre les vues';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Fondu vers l\'arrière-plan puis vers la vue suivante au lieu d\'un changement instantané. Passer à un autre tableau de bord ou à une page externe reste instantané.';

  @override
  String get settingHaRotationFadeSecondsTitle => 'Durée du fondu (secondes)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Durée combinée du fondu sortant et entrant. Le chargement de la vue suivante peut ajouter du temps, surtout lors de sa première visite.';

  @override
  String get haRotation => 'Rotation des vues du tableau de bord';

  @override
  String get haRotationHint => 'Parcours des vues, temps d\'affichage, fondu';

  @override
  String get haDefaultView => 'Vue par défaut';

  @override
  String get haExternalPages => 'Pages externes';

  @override
  String get haFadeError =>
      'Choisissez une durée de fondu entre 0,2 et 5 secondes.';

  @override
  String get haPauseRemoteHelp =>
      'Un appui suspend la rotation pendant cette durée ; chaque nouvel appui relance le décompte. Les interactions vocales suspendent toujours la rotation jusqu\'à leur fin. 0 laisse la rotation continuer.';

  @override
  String get settingHaUrlTitle => 'URL de base de Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'ex. https://homeassistant.local:8123, sans chemin de tableau de bord.';

  @override
  String get settingHaTokenTitle => 'Jeton d\'accès de longue durée';

  @override
  String get settingHaTokenDescription =>
      'Créé dans votre profil HA → Sécurité.';

  @override
  String get settingHaAutoLoginTitle => 'Se connecter automatiquement';

  @override
  String get settingHaAutoLoginDescription =>
      'Se connecte au tableau de bord avec le jeton d\'accès ci-dessus au lieu d\'afficher la page de connexion Home Assistant.';

  @override
  String get haValidate => 'Valider';

  @override
  String get haValidateConnection => 'Valider la connexion';

  @override
  String get haChecking => 'Vérification…';

  @override
  String get haConnected => 'Connecté';

  @override
  String get haConnectedRemote => 'Connecté.';

  @override
  String get haNotValidated =>
      'Pas encore validée. Les paramètres ci-dessous se débloquent une fois la connexion vérifiée.';

  @override
  String get haConnectFailed => 'Connexion impossible.';

  @override
  String get haNotConfigured => 'URL et jeton Home Assistant non configurés';

  @override
  String get haInvalidToken => 'jeton invalide';

  @override
  String haUnreachable(String error) {
    return 'Impossible de joindre Home Assistant : $error';
  }

  @override
  String get haProxy => 'Proxy de contexte sécurisé';

  @override
  String get haProxyHelp =>
      'Fait passer un Home Assistant en http simple par un proxy intégré à l\'application, pour que le navigateur active le microphone et les autres fonctionnalités réservées au https. Uniquement pour les URL http.';

  @override
  String get haProxyRemoteHelp =>
      'Fait passer un Home Assistant en http simple par un proxy intégré à l\'application, pour que le navigateur active le microphone et les autres fonctionnalités réservées au https. Disponible uniquement pour les URL http.';

  @override
  String get haProxyNotice =>
      'Cette URL Home Assistant utilise le http simple, et les navigateurs bloquent le microphone et d\'autres fonctionnalités sur les pages http. Kiosk Satellite va acheminer le tableau de bord via un proxy sécurisé intégré à l\'application pour que tout fonctionne. Il se peut que vous deviez vous reconnecter à Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Cette URL Home Assistant utilise le http simple, et les navigateurs bloquent le microphone et d\'autres fonctionnalités sur les pages http. Kiosk Satellite va acheminer le tableau de bord via un proxy sécurisé intégré à l\'application pour que tout fonctionne. Il se peut que vous deviez vous reconnecter à Home Assistant sur la tablette.';

  @override
  String get haDashboard => 'Tableau de bord';

  @override
  String get haChooseView => 'Choisir une vue';

  @override
  String get haLoadingDashboards => 'Chargement des tableaux de bord…';

  @override
  String get haListFailed => 'Impossible de lister les tableaux de bord';

  @override
  String get haRetryHint => 'Appuyez pour réessayer.';

  @override
  String get haChangeView => 'Changer de vue';

  @override
  String get haNoViews => 'Aucune sous-vue';

  @override
  String get haNoViewsHelp =>
      'Ce tableau de bord n\'a pas de sous-vue sélectionnable.';

  @override
  String get haNoDashboards => 'Aucun tableau de bord trouvé';

  @override
  String get settingHaThemeTitle => 'Thème';

  @override
  String get settingHaThemeDescription =>
      'Clair ou sombre pour le tableau de bord Home Assistant, également réglable via l\'entité Thème dans Home Assistant. « Auto » suit les paramètres ci-dessous.';

  @override
  String get settingThemeMatchAppTitle =>
      'Synchroniser les thèmes Home Assistant avec Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Faire correspondre automatiquement votre thème Home Assistant à celui de l\'interface Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle =>
      'Adapter le thème à l\'heure de la journée';

  @override
  String get settingThemeAutoDescription =>
      'Basculer Home Assistant entre clair et sombre selon un horaire. Conserve le thème sélectionné, en basculant uniquement sa variante claire/sombre.';

  @override
  String get settingThemeDarkAtTitle => 'Thème sombre à';

  @override
  String get settingThemeDarkAtDescription =>
      'Heure locale de passage au thème sombre.';

  @override
  String get settingThemeLightAtTitle => 'Thème clair à';

  @override
  String get settingThemeLightAtDescription =>
      'Heure locale de retour au thème clair.';

  @override
  String get settingThemeAutoAppTitle =>
      'Changer aussi le thème de l\'application';

  @override
  String get settingThemeAutoAppDescription =>
      'Basculer le thème propre de Kiosk Satellite (menu, paramètres) en même temps que le changement programmé de Home Assistant.';

  @override
  String get haThemeHint =>
      'Correspondre à l\'application, ou basculer entre clair et sombre selon un horaire';

  @override
  String get haThemeAuto => 'Auto';

  @override
  String get settingHaKioskModeTitle => 'Mode kiosque HA';

  @override
  String get settingHaKioskModeDescription =>
      'Masquer l\'en-tête et la barre latérale de Home Assistant. S\'applique immédiatement.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Masquer l\'en-tête';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Masquer la barre d\'outils du tableau de bord et les onglets de vue tant que le mode kiosque HA est activé. Laissez désactivé si vous changez de vue depuis l\'en-tête.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Masquer la barre latérale';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Masquer la barre de navigation latérale tant que le mode kiosque HA est activé.';

  @override
  String get settingHaKioskMenuTitle => 'Afficher dans le menu du kiosque';

  @override
  String get settingHaKioskMenuDescription =>
      'Ajouter une entrée Mode kiosque HA au menu du kiosque pour l\'activer et le désactiver.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Activer le carrousel de tableau de bord';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Balayez vers la gauche ou la droite sur le tableau de bord pour passer d\'une vue à l\'autre. Les balayages sur les curseurs, cartes et éléments défilants ne sont pas concernés.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Capturer les balayages sur les cartes';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Changer de vue même si le balayage commence sur une carte qui réagit aux balayages. Les curseurs continuent de fonctionner normalement.';

  @override
  String get settingHaHapticsTitle => 'Activer les vibrations';

  @override
  String get settingHaHapticsDescription =>
      'Vibrer lors de l\'utilisation des boutons, interrupteurs, cartes, curseurs et cadrans de thermostat. Nécessite un moteur de vibration.';

  @override
  String get settingHaHapticsStrengthTitle => 'Intensité des vibrations';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Intensité de la vibration ressentie.';

  @override
  String get settingHaTapSoundTitle => 'Émettre un son à chaque appui';

  @override
  String get settingHaTapSoundDescription =>
      'Émettre le son d\'appui standard lors de l\'utilisation des boutons, interrupteurs, cartes, curseurs et cadrans de thermostat.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Volume du son d\'appui';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Volume auquel le son d\'appui est joué.';

  @override
  String get haUserInterface => 'Interface utilisateur';

  @override
  String get haInterfaceHint =>
      'Mode kiosque, carrousel de tableau de bord, vibrations, sons d\'appui';

  @override
  String get haHaptics => 'Vibrations';

  @override
  String get haVibrationLight => 'Légère';

  @override
  String get haVibrationMedium => 'Moyenne';

  @override
  String get haVibrationStrong => 'Forte';

  @override
  String get settingHomeLauncherEnabledTitle => 'Agir comme écran d\'accueil';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Enregistrer Kiosk Satellite comme écran d\'accueil de l\'appareil : le kiosque se lance au démarrage de l\'appareil et chaque appui sur Accueil y ramène. Se désactive automatiquement et restaure le lanceur précédent si l\'application échoue à démarrer de manière répétée.';

  @override
  String get settingHomeKeepPinningTitle => 'Conserver l\'épinglage d\'écran';

  @override
  String get settingHomeKeepPinningDescription =>
      'Épingler l\'écran même lorsque Kiosk Satellite est l\'écran d\'accueil. Bloque nativement les boutons Applications récentes et Retour, mais rétablit la boîte de dialogue de confirmation d\'épinglage sur les appareils dont l\'application n\'est pas propriétaire (device owner).';

  @override
  String get kioskHomeScreen => 'Écran d\'accueil';

  @override
  String get kioskCheckingDevice => 'Vérification de l\'appareil...';

  @override
  String get kioskFireOs => 'Fire OS ne permet pas de remplacer son lanceur.';

  @override
  String get kioskUnsupported =>
      'Cet appareil ne permet pas de changer l\'écran d\'accueil.';

  @override
  String get kioskRecovered =>
      'Désactivé automatiquement après des échecs de démarrage répétés ; le lanceur précédent a été restauré. Réactivez l\'interrupteur pour réessayer.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite est l\'écran d\'accueil. Le kiosque se lance au démarrage de l\'appareil et chaque appui sur Accueil y ramène.';

  @override
  String get kioskDisabled =>
      'Ce n\'est pas l\'écran d\'accueil. Activez Agir comme écran d\'accueil ci-dessus.';

  @override
  String get kioskWaiting =>
      'Pas encore l\'écran d\'accueil actuel : l\'appareil attend une confirmation.';

  @override
  String get kioskOpenHomeSettings => 'Ouvrir les paramètres d\'accueil';

  @override
  String get kioskSetDefault => 'Définir par défaut';

  @override
  String get kioskActive => 'Actif';

  @override
  String get kioskNotHome => 'Ce n\'est pas l\'écran d\'accueil.';

  @override
  String get kioskWaitingRemote =>
      'En attente d\'une confirmation sur l\'appareil : la boîte de dialogue système ou les paramètres d\'accueil s\'y ouvrent.';

  @override
  String get kioskSetDevice => 'Définir sur l\'appareil';

  @override
  String get settingIntercomAnswerModeTitle => 'Mode de réponse';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Le mode « Sonner » vous demande d\'accepter l\'appel à l\'écran. Le mode « Répondre automatiquement » ouvre l\'appel après un carillon.';

  @override
  String get settingIntercomRingSecondsTitle => 'Sonner pendant';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Durée de sonnerie d\'un appel avant qu\'il ne soit considéré comme manqué.';

  @override
  String get settingIntercomRingSoundTitle => 'Sonnerie';

  @override
  String get settingIntercomRingSoundDescription =>
      'Joué au volume des notifications.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Accepter les annonces';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Lire les annonces « Annoncer à tous » envoyées par les autres kiosques.';

  @override
  String get intercomOptionAnswerRing => 'Sonner';

  @override
  String get intercomOptionAnswerAuto => 'Répondre automatiquement';

  @override
  String get intercomOptionAnswerDnd => 'Ne pas déranger';

  @override
  String get intercomOptionAnswer15 => '15 secondes';

  @override
  String get intercomOptionAnswer30 => '30 secondes';

  @override
  String get intercomOptionAnswer45 => '45 secondes';

  @override
  String get intercomOptionAnswer60 => '60 secondes';

  @override
  String get intercomAnswerSection => 'Réponse';

  @override
  String get settingIntercomEnabledTitle => 'Activer l\'interphone';

  @override
  String get settingIntercomEnabledDescription =>
      'Appeler les autres kiosques sur ce réseau et recevoir leurs appels.';

  @override
  String get settingIntercomKeyTitle => 'Clé de l\'interphone';

  @override
  String get settingIntercomKeyDescription =>
      'Les kiosques ayant la même clé peuvent s\'appeler entre eux. La Gestion de flotte peut la synchroniser.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Créée lors de l\'activation de l\'interphone';

  @override
  String get settingIntercomMenuTitle => 'Afficher dans le menu du kiosque';

  @override
  String get settingIntercomMenuDescription =>
      'Ajoute une entrée Interphone au menu du kiosque.';

  @override
  String get intercomNeedsAdmin =>
      'L\'interphone nécessite l\'administration à distance';

  @override
  String get intercomAdminHelp =>
      'Les kiosques se trouvent et se joignent entre eux grâce à elle. Activez Gestion à distance et Trouver d\'autres kiosques dans Appareil, puis revenez ici.';

  @override
  String get intercomChangeKey => 'Changer la clé';

  @override
  String get intercomChangeKeyHelp =>
      'Collez la clé d\'un autre kiosque, ou créez-en une nouvelle.';

  @override
  String get intercomChange => 'Changer';

  @override
  String get intercomKeyWarning =>
      'Les kiosques ayant cette clé peuvent s\'appeler entre eux. Une nouvelle clé coupe ce kiosque des autres jusqu\'à ce qu\'ils l\'obtiennent aussi.';

  @override
  String get intercomRegenerate => 'Régénérer';

  @override
  String get intercomKeyChanged => 'Clé modifiée';

  @override
  String get intercomNotSet => 'Non définie';

  @override
  String get intercomOpen => 'Ouvrir';

  @override
  String get settingIntercomTlsTitle => 'Chiffrer les communications';

  @override
  String get settingIntercomTlsDescription =>
      'Utilise TLS pour chiffrer les appels intercom entre kiosques. Cette option doit être activée sur tous les kiosques participant à l’appel.';

  @override
  String get intercomKiosks => 'Kiosques';

  @override
  String get intercomRosterHelp =>
      'Kiosques détectés et membres enregistrés de la flotte. Un kiosque est prêt lorsqu’il est joignable, que l’intercom est activé et qu’il utilise la même clé et les mêmes paramètres de chiffrement.';

  @override
  String get intercomNoOther => 'Aucun autre kiosque trouvé';

  @override
  String get intercomRosterDeviceHelp =>
      'Les kiosques avec Gestion à distance et Trouver d\'autres kiosques activés apparaissent ici.';

  @override
  String get intercomNoneHeard => 'Aucun kiosque trouvé';

  @override
  String get intercomRosterRemoteHelp =>
      'Les kiosques apparaissent via la découverte réseau ou l\'appartenance enregistrée à une flotte. Gestion à distance et Trouver d\'autres kiosques doivent être activés.';

  @override
  String get intercomReady => 'Prêt';

  @override
  String get intercomOff => 'Interphone désactivé';

  @override
  String get intercomDifferentKey => 'Clé différente';

  @override
  String get intercomUnreachable => 'Injoignable';

  @override
  String get intercomOffline => 'Hors ligne';

  @override
  String get intercomChecking => 'Vérification…';

  @override
  String get settingIntercomTalkModeTitle => 'Mode de conversation';

  @override
  String get settingIntercomTalkModeDescription =>
      'Avec « Appuyer pour parler », la voix est transmise tant que le bouton est maintenu. Avec « Mains libres », le microphone reste ouvert pendant tout l\'appel.';

  @override
  String get intercomOptionTalkPtt => 'Appuyer pour parler';

  @override
  String get intercomOptionTalkHandsfree => 'Mains libres';

  @override
  String get intercomTalkSection => 'Conversation';

  @override
  String get settingKioskAllowDrawerTitle =>
      'Autoriser le menu avec actions rapides';

  @override
  String get settingKioskAllowDrawerDescription =>
      'Un balayage depuis le bord ouvre le menu sans le geste de sortie ni le code PIN, limité aux actions sélectionnées ci-dessous.';

  @override
  String get settingKioskAllowDashboardTitle => 'Tableau de bord';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Recharger la page de démarrage.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Mode kiosque HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Afficher ou masquer l\'en-tête et la barre latérale de Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Vue caméra';

  @override
  String get settingKioskAllowCameraDescription =>
      'Ouvrir la vue caméra par défaut.';

  @override
  String get settingKioskAllowIntercomTitle => 'Interphone';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Appeler d\'autres kiosques depuis le menu du kiosque.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Ouvrir l\'interface web de Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Lecteur flottant';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Afficher ou masquer le lecteur flottant et ouvrir Lecture en cours.';

  @override
  String get settingKioskAllowScreensaverTitle =>
      'Démarrer l\'économiseur d\'écran';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Démarrer l\'économiseur d\'écran immédiatement.';

  @override
  String get settingKioskAllowHoldTitle => 'Mode maintien';

  @override
  String get settingKioskAllowHoldDescription =>
      'Activer ou désactiver le mode maintien.';

  @override
  String get settingKioskAllowLockdownTitle => 'Mode verrouillage';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Verrouiller l\'écran jusqu\'au geste de sortie ou à un déverrouillage à distance.';

  @override
  String get settingKioskAllowThemeTitle => 'Sélecteur de thème';

  @override
  String get settingKioskAllowThemeDescription =>
      'Basculer entre les thèmes clair et sombre.';

  @override
  String get settingKioskAllowAppsTitle => 'Applications';

  @override
  String get settingKioskAllowAppsDescription =>
      'Ouvrir le lanceur d\'applications. Lorsque « Désactiver le bouton d\'accueil » est activé, le lancement d\'une application désépingle le kiosque jusqu\'à son retour.';

  @override
  String get kioskAllowedActions => 'Actions autorisées';

  @override
  String get kioskAllowedHelp =>
      'Quelles actions rapides le menu du kiosque propose';

  @override
  String get settingKioskEnabledTitle => 'Activer le mode kiosque';

  @override
  String get settingKioskEnabledDescription =>
      'Verrouiller la tablette sur Kiosk Satellite. Le balayage du menu est remplacé par le geste de sortie, le bouton retour reste à l\'intérieur du kiosque, et les protections ci-dessous s\'arment.';

  @override
  String get settingKioskStartOnBootTitle =>
      'Lancer au démarrage de l\'appareil';

  @override
  String get settingKioskStartOnBootDescription =>
      'Lancer Kiosk Satellite lorsque l\'appareil s\'allume. Sur Android 10+, cela nécessite l\'autorisation d\'affichage par-dessus d\'autres applications ; Android la demande à la première activation.';

  @override
  String get settingKioskExitGestureTitle => 'Geste de sortie du kiosque';

  @override
  String get settingKioskExitGestureDescription =>
      'Des appuis rapides n\'importe où ouvrent le menu, après le code PIN s\'il en existe un. Les variantes avec maintien nécessitent de maintenir le dernier appui. Si le geste est désactivé, seule l\'administration à distance permet d\'accéder aux paramètres.';

  @override
  String get settingKioskPinTitle => 'Code PIN du mode kiosque';

  @override
  String get settingKioskPinDescription =>
      'Demandé après le geste de sortie avant l\'ouverture du menu. Laissez vide pour n\'avoir aucun code PIN.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Désactiver la barre d\'état';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Empêcher d\'abaisser la barre d\'état grâce à un bouclier sur le bord supérieur de l\'écran. Nécessite l\'autorisation d\'affichage par-dessus d\'autres applications ; Android la demande à la première activation.';

  @override
  String get settingKioskDisableVolumeTitle =>
      'Désactiver les boutons de volume';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Intercepter les touches de volume physiques.';

  @override
  String get settingKioskDisablePowerTitle =>
      'Désactiver le bouton d\'alimentation';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android ne peut pas bloquer le bouton d\'alimentation : l\'écran se rallume donc aussitôt qu\'on appuie dessus. Éteindre l\'écran à distance fonctionne toujours.';

  @override
  String get settingKioskDisableHomeTitle => 'Désactiver le bouton d\'accueil';

  @override
  String get settingKioskDisableHomeDescription =>
      'Épingler l\'application avec l\'épinglage d\'écran Android, ce qui bloque les boutons Accueil et Applications récentes. Android demande une confirmation la première fois.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Désactiver les menus contextuels';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Supprimer les menus d\'appui long et la sélection de texte dans la vue web.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Désactiver l\'actualisation par glissement';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignorer le geste « tirer pour actualiser » tant que le mode kiosque est activé.';

  @override
  String get settingKioskDisableGesturesTitle => 'Désactiver les gestes';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignorer les gestes de la page Gestes tant que le mode kiosque est activé.';

  @override
  String get kioskGestureTaps5 => '5 appuis rapides';

  @override
  String get kioskGestureTaps7 => '7 appuis rapides';

  @override
  String get kioskGestureTaps5Hold =>
      '5 appuis rapides, en maintenant le dernier';

  @override
  String get kioskGestureTaps7Hold =>
      '7 appuis rapides, en maintenant le dernier';

  @override
  String get kioskGestureNone =>
      'Désactivé (administration à distance uniquement)';

  @override
  String get kioskForeground =>
      'Kiosk Satellite peut se remettre lui-même au premier plan.';

  @override
  String get kioskOverlayMissing =>
      'Sans cela, le kiosque ne peut pas revenir au premier plan et le bouclier de verrouillage ne couvre que l\'application.';

  @override
  String get kioskGuardHeld =>
      'Le panneau de notifications et l\'écran des applications récentes se ferment d\'eux-mêmes tant que l\'écran est protégé.';

  @override
  String get kioskGuardMissing =>
      'Sans cela, le panneau de notifications et l\'écran des applications récentes restent accessibles. Activez Kiosk Satellite dans Accessibilité.';

  @override
  String get kioskOverlayRemote =>
      'Sans cela, le kiosque ne peut pas revenir au premier plan. L\'écran d\'autorisation apparaît sur la tablette.';

  @override
  String get kioskGuardRemote =>
      'Sans cela, le panneau de notifications et l\'écran des applications récentes restent accessibles. Activez Kiosk Satellite dans Accessibilité sur la tablette.';

  @override
  String get kioskGrantDevice => 'Autoriser sur l\'appareil';

  @override
  String get kioskOpenSettingsDevice => 'Ouvrir les paramètres sur l\'appareil';

  @override
  String get settingLockdownEnabledTitle => 'Activer le mode verrouillage';

  @override
  String get settingLockdownEnabledDescription =>
      'Désactive les interactions à l\'écran jusqu\'à ce que le mode soit désactivé depuis Home Assistant ou via le geste de sortie.';

  @override
  String get settingLockdownMenuTitle => 'Afficher dans le menu du kiosque';

  @override
  String get settingLockdownMenuDescription =>
      'Ajoute une entrée Mode verrouillage au menu du kiosque qui verrouille l\'écran. Utilisez le geste de sortie, l\'administration à distance ou Home Assistant pour le déverrouiller.';

  @override
  String get settingLockdownBlackoutTitle => 'Écran noir';

  @override
  String get settingLockdownBlackoutDescription =>
      'Rend l\'écran noir tant qu\'il est verrouillé.';

  @override
  String get settingLockdownAllowScreensaverTitle =>
      'Autoriser l\'économiseur d\'écran';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Permet à l\'économiseur d\'écran de fonctionner pendant le verrouillage. L\'option « Fermer sur mouvement » reste désactivée tant que le verrouillage n\'est pas levé.';

  @override
  String get settingLockdownExitGestureTitle =>
      'Geste de sortie du verrouillage';

  @override
  String get settingLockdownExitGestureDescription =>
      'Des appuis rapides n\'importe où désactivent le mode verrouillage, après le code PIN du kiosque s\'il en existe un. Les variantes avec maintien nécessitent de maintenir le dernier appui. Si le geste est désactivé, le verrouillage ne peut être levé que depuis l\'administration à distance ou Home Assistant.';

  @override
  String get lockdownGestureNone => 'Désactivé (à distance uniquement)';

  @override
  String get lockdownExplanation =>
      'Le mode verrouillage rend le tableau de bord non interactif, arme toutes les protections du mode kiosque sans modifier vos paramètres de mode kiosque, et coupe la détection du mot de réveil tant qu\'il est activé. Avec la protection de l\'interface système activée (ci-dessus), le panneau de notifications et l\'écran des applications récentes sont également bloqués. Home Assistant reçoit un interrupteur Mode verrouillage via ESPHome.';

  @override
  String get lockdownSearch =>
      'Bouclier tactile configurable depuis l\'administration à distance. Ses autorisations se trouvent sous Autorisations système requises.';

  @override
  String get lockdownOverlayHeld =>
      'Le bouclier de verrouillage peut couvrir tout l\'écran.';

  @override
  String get lockdownOverlayMissing =>
      'Sans cela, le bouclier ne couvre que l\'application. L\'écran d\'autorisation apparaît sur la tablette.';

  @override
  String get lockdownPermissionsSearch =>
      'Les autorisations dont les protections du verrouillage ont besoin.';

  @override
  String get mediaCacheTitle => 'Cache des pochettes d\'album';

  @override
  String get mediaCacheReadFailed => 'Impossible de lire la taille du cache.';

  @override
  String get mediaCacheClearFailed => 'Impossible de vider le cache.';

  @override
  String get mediaCacheChecking => 'Vérification de la taille du cache...';

  @override
  String get mediaCacheClearing => 'Suppression...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used utilisés sur $limit. Les miniatures de la file d\'attente sont mises en cache automatiquement.';
  }

  @override
  String get settingSendspinShowPlayerTitle => 'Afficher le lecteur flottant';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Pendant la lecture, afficher une petite fenêtre de lecture en cours par-dessus le tableau de bord avec la pochette, les infos du morceau et la progression. Déplacez-la où vous voulez ; sa position est mémorisée.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Taille du lecteur';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Compact : petite fenêtre de lecture en cours, discrète. Grand : ajoute des boutons précédent, lecture/pause et suivant adaptés à une utilisation tactile, pour contrôler tout le groupe de lecture.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Masquer le lecteur en pause après';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Durée d\'affichage à l\'écran d\'un lecteur en pause. S\'applique au lecteur flottant comme à la vue Lecture en cours.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Continuer la lecture une fois fermé';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Écarter le lecteur flottant d\'un geste le masque sans arrêter la musique.';

  @override
  String get settingSendspinPlayerShortcutTitle =>
      'Afficher dans le menu du kiosque';

  @override
  String get settingSendspinPlayerShortcutDescription =>
      'Ajoute une entrée dans le menu du kiosque qui affiche ou masque le lecteur flottant. ATTENTION : si rien n\'est en cours de lecture ou qu\'il n\'y a pas de file d\'attente pour ce lecteur, elle n\'apparaîtra pas.';

  @override
  String get mediaFloatingPage => 'Lecteur flottant';

  @override
  String get mediaFloatingHint =>
      'La petite carte par-dessus le tableau de bord';

  @override
  String get mediaCompact => 'Compact';

  @override
  String get mediaLargeControls => 'Grand avec contrôles';

  @override
  String get settingSendspinPlayerSourceTitle => 'Source du lecteur';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Ce que le lecteur flottant et Lecture en cours affichent et contrôlent : cet appareil ou un lecteur ailleurs.';

  @override
  String get settingSendspinPlayerTitle => 'Lecteur';

  @override
  String get settingSendspinPlayerDescription =>
      'Le lecteur de cette source à afficher et contrôler.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Baisser le volume pendant les interactions vocales';

  @override
  String get settingSendspinDuckPercentDescription =>
      'La musique descend à cette proportion de son volume pendant les interactions vocales et les appels d\'interphone, puis remonte.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Les boutons de volume contrôlent le lecteur';

  @override
  String get settingSendspinVolumeKeysDescription =>
      'Les boutons de volume de cet appareil modifient le volume du lecteur suivi plutôt que le sien. Uniquement tant que la vue Lecture en cours est à l\'écran, ou tant que le lecteur joue.';

  @override
  String get settingSendspinVolumeKeyStepTitle => 'Pas des boutons de volume';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Variation de volume produite par un appui sur un bouton de volume.';

  @override
  String get mediaIntro =>
      'Le lecteur flottant et Lecture en cours ne s\'affichent que lorsque le lecteur choisi lit un morceau ou a une file d\'attente chargée. Sans lecture ni file d\'attente, aucun des deux n\'apparaît.';

  @override
  String get mediaThisDevice => 'Cet appareil';

  @override
  String get mediaOff => 'Désactivé';

  @override
  String get mediaKeysNowPlaying => 'Tant que Lecture en cours est affichée';

  @override
  String get mediaKeysPlaying => 'Tant que le lecteur joue';

  @override
  String get mediaAnotherPlayer => 'un autre lecteur';

  @override
  String mediaLocalOffline(String player) {
    return 'Le propre lecteur Sendspin de cet appareil reste hors ligne tant que $player est contrôlé.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Activer les paroles';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Paroles synchronisées sur la vue Lecture en cours, pour toutes les sources de lecture.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Source des paroles';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'D\'où proviennent les paroles. Music Assistant nécessite l\'adresse du serveur et le jeton sur sa page.';

  @override
  String get settingSendspinLyricsFallbackTitle => 'Repli sur Music Assistant';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Si LRCLIB est injoignable, Music Assistant est interrogé à la place. Nécessite la connexion à Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Synchronisation des paroles';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Décaler les paroles par rapport à la musique. Une valeur positive affiche chaque ligne plus tôt, une valeur négative plus tard. Utile pour corriger les morceaux dont les paroles sont systématiquement décalées.';

  @override
  String get mediaLyricsPage => 'Paroles';

  @override
  String get mediaLyricsHint =>
      'Paroles synchronisées, leur source et leur synchronisation';

  @override
  String get settingSendspinMaUrlTitle => 'Adresse du serveur';

  @override
  String get settingSendspinMaUrlDescription =>
      'L\'adresse du serveur Music Assistant, telle qu\'affichée par son interface web. Généralement https et port 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Jeton d\'authentification';

  @override
  String get settingSendspinMaTokenDescription =>
      'Un jeton de longue durée provenant de Music Assistant (Paramètres, puis Utilisateurs). Un accès en lecture suffit pour les paroles ; le raccourci du menu du kiosque ouvre l\'interface web avec l\'identité du titulaire du jeton.';

  @override
  String get settingSendspinMaShortcutTitle =>
      'Afficher dans le menu du kiosque';

  @override
  String get settingSendspinMaShortcutDescription =>
      'Ajoute une entrée Music Assistant au menu du kiosque, ouvrant l\'interface web du serveur par-dessus le tableau de bord. Nécessite l\'adresse du serveur ci-dessus.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Ouvrir directement sur Lecture en cours';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Ouvrir le lecteur plein écran de Music Assistant depuis le menu du kiosque ou le geste Ouvrir Music Assistant.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Fermer après inactivité';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Revenir au tableau de bord quand personne n\'a touché la page Music Assistant pendant cette durée. Zéro la laisse ouverte jusqu\'à sa fermeture.';

  @override
  String get settingSendspinMaHideCloseTitle =>
      'Masquer le bouton de fermeture';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'Le bouton de fermeture flottant peut se superposer aux propres contrôles de Music Assistant, comme le menu Lecture en cours. Sans lui, fermez avec le bouton retour ou via le menu tiroir du kiosque.';

  @override
  String get mediaMaHint => 'Serveur, jeton, raccourci du menu du kiosque';

  @override
  String get mediaKioskMenu => 'Menu du kiosque';

  @override
  String get mediaValidateConnection => 'Valider la connexion';

  @override
  String get mediaValidate => 'Valider';

  @override
  String get mediaChecking => 'Vérification…';

  @override
  String get mediaConnected => 'Connecté';

  @override
  String mediaConnectedVersion(String version) {
    return 'Connecté à Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Vérifiez l\'adresse et le jeton avant d\'activer le raccourci ou les paroles.';

  @override
  String get mediaDeviceNoAnswer => 'L\'appareil n\'a pas répondu.';

  @override
  String get mediaValidationFailed => 'Échec de la validation.';

  @override
  String get mediaNoAddress => 'Aucune adresse de serveur définie.';

  @override
  String get mediaNoToken => 'Aucun jeton d\'authentification défini.';

  @override
  String get mediaTimeout => 'Music Assistant n\'a pas répondu à temps.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'Impossible de joindre $host : $error';
  }

  @override
  String get mediaServerClosed => 'le serveur a fermé la connexion';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Afficher les contrôles multimédias';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Boutons précédent, lecture/pause et suivant ainsi qu\'une barre de progression sur la vue Lecture en cours. Lorsque les contrôles sont affichés, un bouton de fermeture remplace l\'appui n\'importe où pour fermer la vue.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Échelle du texte';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Taille du titre du morceau, de l\'artiste, de l\'album, des paroles et du texte de la file d\'attente. S\'applique aux deux dispositions, y compris lorsque la vue est affichée à côté de l\'économiseur d\'écran. La pochette s\'ajuste pour laisser de la place au texte.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle => 'Échelle des boutons';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Taille des boutons de lecture et de la barre de progression, indépendante de la taille du texte. S\'applique aux deux dispositions, y compris lorsque la vue est affichée à côté de l\'économiseur d\'écran. Les contrôles s\'adaptent à l\'espace disponible dans le lecteur.';

  @override
  String get settingSendspinFullscreenHorizontalTitle => 'Mode horizontal';

  @override
  String get settingSendspinFullscreenHorizontalDescription =>
      'Diviser la pochette et les contrôles en deux moitiés égales, gauche et droite. Avec les paroles ou la file d\'attente ouvertes, les détails du morceau passent sous la pochette. Ignoré tant que Lecture en cours est affichée aux côtés d\'un économiseur d\'écran.';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Double appui pour fermer';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Un double appui n\'importe où sur la vue Lecture en cours la ferme. Le bouton de fermeture ne sera pas affiché. Ignoré tant que Lecture en cours est affichée aux côtés d\'un économiseur d\'écran.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Lancer Lecture en cours quand la musique démarre';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Ouvrir la vue Lecture en cours dès le début de la lecture au lieu d\'attendre le délai de l\'économiseur d\'écran.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Fermer « Lecture en cours » sur mouvement';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Permettre au mouvement de fermer Lecture en cours comme un économiseur d\'écran classique. Si l\'option est désactivée, seul un appui sur l\'écran la ferme, afin qu\'un simple passage n\'interrompe pas l\'affichage de la musique. Ignoré tant que Lecture en cours est affichée aux côtés d\'un économiseur d\'écran.';

  @override
  String get settingSendspinFullscreenShortcutTitle =>
      'Afficher dans le menu du kiosque';

  @override
  String get settingSendspinFullscreenShortcutDescription =>
      'Ajoute une entrée dans le menu du kiosque qui affiche la vue Lecture en cours. ATTENTION : si rien n\'est en cours de lecture ou qu\'il n\'y a pas de file d\'attente pour ce lecteur, elle n\'apparaîtra pas.';

  @override
  String get settingSendspinSpeakerPillTitle =>
      'Afficher la pastille de sélection des enceintes';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Affiche la sélection des enceintes pendant 5 secondes après une interaction avec l\'écran. Ajoutez ou retirez des enceintes du groupe actuel.';

  @override
  String get settingSendspinQueueArtTitle =>
      'Afficher la pochette dans la file d\'attente';

  @override
  String get settingSendspinQueueArtDescription =>
      'Une pochette sur chaque ligne du panneau de file d\'attente.';

  @override
  String get mediaNowPlayingHint => 'Vue plein écran pendant la lecture';

  @override
  String get mediaInterfaceHeading => 'Interface utilisateur';

  @override
  String get settingSendspinFullscreenTitle =>
      '« Lecture en cours » au lieu de l\'économiseur d\'écran';

  @override
  String get settingSendspinFullscreenDescription =>
      'Pendant la lecture, l\'économiseur d\'écran devient une vue Lecture en cours plein écran avec la pochette de l\'album. Sans lecture en cours, l\'économiseur d\'écran habituel s\'exécute.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Afficher aux côtés de l\'économiseur d\'écran';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Garder l\'économiseur d\'écran visible à côté de Lecture en cours. Les écrans en portrait empilent l\'économiseur d\'écran au-dessus du lecteur. Les petits écrans conservent le lecteur plein écran.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Remplir l\'écran';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Remplacer le remplissage des photos tant que l\'économiseur d\'écran partage l\'affichage avec Lecture en cours. « Par défaut » utilise le paramètre propre à chaque économiseur d\'écran. « Désactivé » garde la photo entière entre des bandes noires. « Intelligent » agrandit les photos dont la forme est proche de celle de l\'écran et encadre les autres sur un arrière-plan flouté. « Toujours » agrandit chaque photo en coupant ce qui dépasse.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Remplacer la luminosité de l\'économiseur d\'écran';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Utiliser la luminosité normale de l\'écran au lieu de celle de l\'économiseur d\'écran lorsque Lecture en cours s\'affiche aux côtés d\'un économiseur d\'écran. Ceci remplace aussi la luminosité programmée de l\'économiseur d\'écran.';

  @override
  String get mediaScreensaverHeading => 'Économiseur d\'écran';

  @override
  String get mediaDefaultFill => 'Par défaut';

  @override
  String get mediaFillOff => 'Désactivé';

  @override
  String get mediaFillSmart => 'Intelligent';

  @override
  String get mediaFillAlways => 'Toujours';

  @override
  String get mediaPickPlayer => 'Choisir un lecteur';

  @override
  String get mediaMaPlayer => 'Lecteur Music Assistant';

  @override
  String get mediaHaPlayer => 'Lecteur multimédia Home Assistant';

  @override
  String get mediaSonosRoom => 'Pièce Sonos';

  @override
  String get mediaSearchPlayers => 'Rechercher des lecteurs';

  @override
  String get mediaOffline => 'Hors ligne';

  @override
  String mediaOfflineName(String name) {
    return '$name (hors ligne)';
  }

  @override
  String get mediaSetUpMa =>
      'Configurez Music Assistant pour lister ses lecteurs.';

  @override
  String get mediaSetUpHa =>
      'Connectez Home Assistant pour lister ses lecteurs multimédias.';

  @override
  String get mediaSetUpSonos =>
      'Aucune enceinte Sonos connue pour l\'instant. Trouvez-en une ou ajoutez-en une sur la page Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant n\'a pas répondu : $error';
  }

  @override
  String get mediaSaveFailed => 'Impossible d\'enregistrer le lecteur.';

  @override
  String get mediaSelectFailed => 'Impossible de sélectionner le lecteur';

  @override
  String get settingSendspinEnabledTitle => 'Activer le lecteur Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Transformer cet appareil en lecteur Sendspin synchronisé. Il apparaît dans Music Assistant sous le nom de l\'appareil, synchronisé avec chaque autre enceinte Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Serveur';

  @override
  String get settingSendspinServerDescription =>
      'Adresse du serveur Sendspin, par exemple 192.168.1.10:8927. Laissez vide pour trouver automatiquement le serveur sur le réseau.';

  @override
  String get settingSendspinCodecTitle => 'Codec audio préféré';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC est sans perte et idéal sur Wi-Fi ou Ethernet. Le serveur fait le choix final parmi ce que cet appareil propose.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Décalage de synchronisation audio (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Une valeur négative fait jouer cet appareil plus tôt, pour les enceintes en retard sur le groupe (Bluetooth). Réglez à l\'oreille ; s\'applique en direct.';

  @override
  String get mediaSendspinPage => 'Lecteur Sendspin';

  @override
  String get mediaSendspinHint =>
      'Faire de cet appareil un lecteur Music Assistant synchronisé';

  @override
  String get mediaFlac => 'FLAC (sans perte)';

  @override
  String get mediaOpus => 'Opus (efficace)';

  @override
  String get mediaPcm => 'PCM (non compressé)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Ajuster le volume du groupe';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Tant que la pièce suivie joue au sein d\'un groupe, le curseur de volume règle le volume de tout le groupe. Si l\'option est désactivée, seul le volume de cette pièce est modifié.';

  @override
  String get settingSendspinSonosInputsTitle => 'Afficher TV et entrée ligne';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Afficher l\'activité dans le lecteur multimédia quand les entrées eARC ou ligne sont actives.';

  @override
  String get mediaSonosHint =>
      'Enceintes sur le réseau, en ajouter une par adresse';

  @override
  String get mediaSonosSpeakers => 'Enceintes';

  @override
  String get mediaSonosNoneFound => 'Aucun Sonos trouvé';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Aucune enceinte n\'a répondu sur ce réseau. Ajoutez-en une par adresse.';

  @override
  String get mediaSonosAddTitle => 'Ajouter un Sonos par adresse';

  @override
  String get mediaSonosLooking => 'Recherche…';

  @override
  String get mediaSonosEmpty => 'Aucune enceinte pour l\'instant';

  @override
  String get mediaSonosEmptyHelp =>
      'Recherchez sur ce réseau ou ajoutez une enceinte par son adresse.';

  @override
  String get mediaSonosForget => 'Oublier';

  @override
  String get mediaSonosSearchTitle => 'Rechercher sur le réseau';

  @override
  String get mediaSonosSearchHelp =>
      'Trouve les enceintes Sonos sur ce réseau. Les enceintes doivent être sur le même VLAN que cet appareil pour être détectées automatiquement.';

  @override
  String get mediaSonosSearch => 'Rechercher';

  @override
  String get mediaSonosSearching => 'Recherche…';

  @override
  String get mediaSonosAddAddress => 'Ajouter par adresse';

  @override
  String get mediaSonosAddressHelp =>
      'L\'adresse de l\'enceinte sur le réseau. Toutes les enceintes du foyer Sonos sont ajoutées à partir de celle-ci.';

  @override
  String get mediaSonosPickRoom =>
      'Choisissez une pièce dans Source du lecteur, Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos ajouté';

  @override
  String get mediaSonosNoRooms => 'L\'enceinte n\'a signalé aucune pièce.';

  @override
  String get mediaSonosNoAddress => 'aucune adresse';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Aucun Sonos n\'a répondu à $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Configuration Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Connexion, tableau de bord, mode kiosque';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Mot de réveil, écoute en arrière-plan';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary => 'Entités natives et proxy Bluetooth';

  @override
  String get settingsMenuScreenAudio => 'Écran et audio';

  @override
  String get settingsMenuScreenAudioSummary => 'Luminosité, volume, microphone';

  @override
  String get settingsMenuScreensaver => 'Économiseur d\'écran';

  @override
  String get settingsMenuScreensaverSummary =>
      'Délai d\'inactivité, modes, réveil au mouvement';

  @override
  String get settingsMenuBrowser => 'Navigation web';

  @override
  String get settingsMenuBrowserSummary => 'Cache, SSL, niveau de zoom';

  @override
  String get settingsMenuMediaPlayer => 'Lecteur multimédia';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'Récepteur DLNA';

  @override
  String get settingsMenuDlnaSummary =>
      'Lire des images, vidéos et fichiers audio à distance';

  @override
  String get settingsMenuIntercom => 'Interphone';

  @override
  String get settingsMenuIntercomSummary => 'Communiquer entre kiosques';

  @override
  String get settingsMenuCamera => 'Caméra';

  @override
  String get settingsMenuCameraSummary =>
      'Caméra de l\'appareil, mouvement, diffusion';

  @override
  String get settingsMenuCameraStreams => 'Flux de caméras';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Caméras Go2RTC et Home Assistant';

  @override
  String get settingsMenuKiosk => 'Mode kiosque';

  @override
  String get settingsMenuKioskSummary =>
      'Geste de sortie, code PIN, boutons matériels';

  @override
  String get settingsMenuHomeLauncher => 'Lanceur d\'accueil';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Remplacer l\'écran d\'accueil de l\'appareil';

  @override
  String get settingsMenuAppLauncher => 'Lanceur d\'applications';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Ouvrir d\'autres applications depuis le kiosque';

  @override
  String get settingsMenuGestures => 'Gestes';

  @override
  String get settingsMenuGesturesSummary =>
      'Gestes tactiles, de la main et par claquements';

  @override
  String get settingsMenuDevice => 'Appareil';

  @override
  String get settingsMenuDeviceSummary =>
      'Nom, thème de l\'application, accès à distance';

  @override
  String get settingsMenuFleet => 'Gestion de flotte';

  @override
  String get settingsMenuFleetSummary => 'Diriger ou suivre d\'autres kiosques';

  @override
  String get settingsMenuPlugins => 'Gestionnaire de plugins';

  @override
  String get settingsMenuPluginsSummary => 'Installer et gérer des plugins';

  @override
  String get settingsMenuLogs => 'Journaux';

  @override
  String get settingsMenuLogsSummary =>
      'Journal de l\'application et console web';

  @override
  String get settingsMenuAbout => 'À propos';

  @override
  String get settingsMenuAboutSummary => 'Version, auteur, licence';

  @override
  String get settingsMenuOverview => 'Vue d\'ensemble';

  @override
  String get settingsMenuOverviewSummary => 'Écran et contrôles rapides';

  @override
  String get settingsMenuLockdown => 'Mode verrouillage';

  @override
  String get settingsMenuLockdownSummary =>
      'Désactiver les interactions à l\'écran';

  @override
  String get settingsMenuFiles => 'Gestionnaire de fichiers';

  @override
  String get settingsMenuFilesSummary =>
      'Parcourir, télécharger et envoyer des fichiers';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Affichage';

  @override
  String get settingsGroupMediaCameras => 'Média et caméras';

  @override
  String get settingsGroupKiosk => 'Kiosque';

  @override
  String get settingsGroupSystem => 'Système';

  @override
  String get settingsMenuMenu => 'Menu';

  @override
  String get settingsMenuTheme => 'Thème';

  @override
  String get settingsMenuLogout => 'Se déconnecter';

  @override
  String get settingsMenuSwitchKiosk => 'Changer de kiosque';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Thème : $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automatique';

  @override
  String get settingAdaptiveBrightnessTitle => 'Luminosité adaptative';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Assombrir l\'écran à mesure que la pièce s\'obscurcit, à l\'aide du capteur de lumière ambiante.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Luminosité minimale';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Luminosité de l\'écran dans une pièce sombre.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Luminosité maximale';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Luminosité de l\'écran dans une pièce lumineuse.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Pièce sombre (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Niveau de lumière en dessous duquel (inclus) l\'écran reste à la luminosité minimale.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Pièce lumineuse (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Niveau de lumière au-dessus duquel (inclus) l\'écran reste à la luminosité maximale.';

  @override
  String get screenAudioAdaptiveHint =>
      'Suivre la lumière de la pièce avec le capteur de lumière ambiante';

  @override
  String get screenAudioAdaptiveNote =>
      'Niveau dans une pièce lumineuse. La luminosité adaptative l\'assombrit à partir de là.';

  @override
  String get screenAudioAdaptiveOwns => 'La luminosité adaptative est activée.';

  @override
  String get screenAudioNoSensor =>
      'Aucun capteur de lumière ambiante sur cet appareil.';

  @override
  String get screenAudioAmbientLight => 'Lumière ambiante';

  @override
  String get screenAudioAmbientHelp =>
      'Ce que lit actuellement le capteur de lumière ambiante.';

  @override
  String get screenAudioNoReading => 'Pas encore de mesure';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (dernière valeur connue)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Définit la luminosité maximale : la luminosité adaptative est activée.';

  @override
  String get screenAudioSetsDefault => 'Définit la luminosité par défaut.';

  @override
  String get settingAudioMicDeviceTitle => 'Microphone';

  @override
  String get settingAudioMicDeviceDescription =>
      'Le microphone utilisé pour la détection du mot de réveil et les échanges vocaux.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Haut-parleur';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Sortie pour les sons de Voice Satellite ; la lecture multimédia suit la sortie audio du système. L\'annulation d\'écho ne fonctionne qu\'avec le microphone et le haut-parleur sur le même appareil.';

  @override
  String get screenAudioDevices => 'Périphériques audio';

  @override
  String get screenAudioSelectedDevice => 'Périphérique sélectionné';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (non connecté)';
  }

  @override
  String get settingMicAudioSourceTitle => 'Mode de capture';

  @override
  String get settingMicAudioSourceDescription =>
      'Le mode Communication vocale est le seul à offrir l\'annulation d\'écho ; ne le changez donc que si le microphone semble bien plus faible ici que dans une application d\'enregistrement.';

  @override
  String get settingMicEchoCancellationTitle => 'Annulation d\'écho';

  @override
  String get settingMicEchoCancellationDescription =>
      'Empêche le microphone de capter le haut-parleur du kiosque afin que le mot d\'arrêt fonctionne pendant la lecture. Ne la désactivez que si le microphone semble bien plus faible ici que dans une application d\'enregistrement.';

  @override
  String get settingMicChannelTitle => 'Canal du microphone';

  @override
  String get settingMicChannelDescription =>
      'Les microphones multicanaux réservent souvent un canal à la reconnaissance vocale ; le sélectionner peut améliorer la détection.';

  @override
  String get settingMicAgcTitle => 'Contrôle automatique du gain';

  @override
  String get settingMicAgcDescription =>
      'Laisser Android ajuster le niveau du microphone au lieu d\'un gain fixe. Cela amplifie aussi le bruit ambiant, et sur certains appareils cela n\'a aucun effet.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Suppression du bruit';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Réduire le bruit de fond du microphone via le traitement Android. Selon l\'appareil, cela peut améliorer ou nuire à la détection du mot de réveil.';

  @override
  String get settingMicGainDbTitle => 'Gain du microphone';

  @override
  String get settingMicGainDbDescription =>
      'Amplifier ou atténuer le signal du microphone avant tout traitement. Visez un niveau proche de 0,05 dans le testeur de mot de réveil ; trop de gain déforme la voix et nuit à la détection.';

  @override
  String get settingMicCaptureFormatTitle => 'Format de capture';

  @override
  String get settingMicCaptureFormatDescription =>
      'Choisissez Stéréo 48 kHz si le microphone fonctionne dans d\'autres applications mais pas ici : certaines cartes son n\'enregistrent que dans ce format et l\'application le convertit elle-même.';

  @override
  String get screenAudioMicrophoneSettings => 'Paramètres du microphone';

  @override
  String get screenAudioMicrophoneHint =>
      'Mode de capture, canal, gain, niveau en direct';

  @override
  String get screenAudioMicrophoneNote =>
      'Ajustez la capture pour votre microphone et votre pièce. Testez les mots de réveil et les interactions vocales après avoir modifié ces paramètres.';

  @override
  String get screenAudioVoiceCommunication =>
      'Communication vocale (par défaut)';

  @override
  String get screenAudioVoiceRecognition => 'Reconnaissance vocale';

  @override
  String get screenAudioRawMicrophone => 'Microphone brut';

  @override
  String get screenAudioAutomaticDefault => 'Automatique (par défaut)';

  @override
  String get screenAudioStereo => 'Stéréo 48 kHz';

  @override
  String get screenAudioDownmix => 'Sous-mixage (par défaut)';

  @override
  String screenAudioChannel(String channel) {
    return 'Canal $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Canal $channel (absent sur ce microphone)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Niveau du microphone';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Parlez depuis l\'endroit où vous utilisez l\'appareil ; ajustez le gain jusqu\'à ce qu\'une voix normale culmine vers la fin de la zone verte.';

  @override
  String get settingBrowserCutoutModeTitle => 'Encoche d\'affichage';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Comment traiter la zone de l\'écran autour d\'une encoche ou d\'un trou de caméra. Choisissez « Éviter l\'encoche » si la caméra se trouve au-dessus de boutons en haut du tableau de bord.';

  @override
  String get settingScreenOrientationTitle => 'Orientation de l\'écran';

  @override
  String get settingScreenOrientationDescription =>
      'Forcer l\'écran dans une orientation. Utilisez ceci sur un appareil sans capteur de rotation, ou installé d\'une façon que le capteur interprète mal.';

  @override
  String get settingKeepScreenOnTitle => 'Garder l\'écran allumé';

  @override
  String get settingKeepScreenOnDescription =>
      'Empêcher le système d\'exploitation d\'éteindre l\'écran.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Définir la luminosité au démarrage';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Appliquer la luminosité par défaut à chaque démarrage de l\'application.';

  @override
  String get settingDefaultBrightnessTitle => 'Luminosité par défaut';

  @override
  String get settingDefaultBrightnessDescription =>
      'Luminosité de l\'écran appliquée au démarrage de l\'application. Déplacer le curseur l\'applique immédiatement.';

  @override
  String get screenAudioScreen => 'Écran';

  @override
  String get screenAudioCutoutAlways => 'Utiliser la zone de l\'encoche';

  @override
  String get screenAudioCutoutShort => 'Bords courts uniquement';

  @override
  String get screenAudioCutoutDefault => 'Valeur par défaut du système';

  @override
  String get screenAudioCutoutNever => 'Éviter l\'encoche';

  @override
  String get screenAudioAutomatic => 'Automatique';

  @override
  String get screenAudioLandscape => 'Paysage';

  @override
  String get screenAudioReverseLandscape => 'Paysage inversé';

  @override
  String get screenAudioPortrait => 'Portrait';

  @override
  String get screenAudioReversePortrait => 'Portrait inversé';

  @override
  String get screenAudioPermission => 'Autorisation';

  @override
  String get screenAudioBrightnessFallback =>
      'La luminosité utilise une solution de secours';

  @override
  String get screenAudioBrightnessPermission =>
      'Sans l\'autorisation « Modifier les paramètres système », les changements de luminosité ne font qu\'assombrir cette application au lieu de régler la luminosité réelle de l\'écran.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Sans l\'autorisation « Modifier les paramètres système », les changements de luminosité ne font qu\'assombrir l\'application au lieu de régler la luminosité réelle de l\'écran.';

  @override
  String get screenAudioAlwaysOn => 'Affichage toujours actif';

  @override
  String get screenAudioAlwaysOnClock =>
      'Cet appareil garde une horloge tamisée allumée';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Éteindre l\'écran met l\'appareil en veille, mais l\'affichage toujours actif rallume l\'écran de verrouillage et aucune application ne peut l\'en empêcher. Désactivez « Toujours afficher l\'heure et les infos » dans les paramètres Android, sous Affichage, près des options de l\'écran de verrouillage ; certaines ROM l\'appellent « always-on display ». L\'entité écran de Home Assistant reste indisponible tant que ce n\'est pas fait.';

  @override
  String get settingMediaVolumeTitle => 'Volume multimédia';

  @override
  String get settingMediaVolumeDescription =>
      'La musique et la vidéo sont lues à cette proportion du volume principal. Le volume du lecteur Sendspin dans Music Assistant déplace ce curseur.';

  @override
  String get settingAssistantVolumeTitle => 'Volume de l\'assistant';

  @override
  String get settingAssistantVolumeDescription =>
      'Les réponses vocales et les carillons sont lus à cette proportion du volume principal, indépendamment du volume multimédia.';

  @override
  String get settingAssistantFullVolumeRangeTitle =>
      'Plage de volume complète pour l\'assistant';

  @override
  String get settingAssistantFullVolumeRangeDescription =>
      'Initialiser le volume d\'appel du haut-parleur intégré à 100 % au premier démarrage de l\'audio de l\'assistant. Le volume principal et le volume de l\'assistant s\'appliquent toujours. D\'autres applications partagent ce volume d\'appel, qui n\'est pas restauré ensuite.';

  @override
  String get settingIntercomVolumeTitle => 'Volume de l\'interphone';

  @override
  String get settingIntercomVolumeDescription =>
      'La voix et les annonces de l\'autre kiosque sont lues à cette proportion du volume principal.';

  @override
  String get screenAudioVolume => 'Volume audio';

  @override
  String get screenAudioMasterVolume => 'Volume principal';

  @override
  String get screenAudioMasterHelp =>
      'Le volume de l\'appareil. Les volumes multimédia, interphone et assistant sont proportionnels à celui-ci.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Masquer tous les extras';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Garde l\'écran entièrement noir : pas de petite horloge, d\'entités « En un coup d\'œil », ni d\'autres superpositions.';

  @override
  String get screensaverBlackSection => 'Économiseur d\'écran noir';

  @override
  String get settingScreensaverClockStyleTitle => 'Style';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Comment l\'horloge est dessinée.';

  @override
  String get settingScreensaverClockFontTitle => 'Famille de police';

  @override
  String get settingScreensaverClockFontDescription =>
      'La police avec laquelle l\'horloge est dessinée.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Graisse de police';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Épaisseur des chiffres de l\'horloge. Par défaut, chaque police garde sa propre graisse.';

  @override
  String get settingScreensaverClock24hTitle => 'Horloge 24 heures';

  @override
  String get settingScreensaverClock24hDescription =>
      'Afficher une heure au format 24 heures plutôt qu\'AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Afficher les secondes';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Inclure les secondes dans l\'horloge.';

  @override
  String get settingScreensaverClockDateTitle => 'Afficher la date';

  @override
  String get settingScreensaverClockDateDescription =>
      'Afficher le jour de la semaine et la date sous l\'horloge.';

  @override
  String get settingScreensaverClockScaleTitle => 'Taille de l\'horloge';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Ajuster la taille de l\'horloge de 50 à 300 % pour cet écran.';

  @override
  String get settingScreensaverClockColorTitle => 'Couleur de l\'horloge';

  @override
  String get settingScreensaverClockColorDescription =>
      'La couleur du texte de l\'horloge.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Couleur d\'arrière-plan';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'La couleur derrière l\'horloge.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Photo d\'arrière-plan';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Afficher une photo derrière l\'horloge au lieu de la couleur unie. Indiquez le chemin d\'une image sur l\'appareil, ou l\'URL d\'une image que l\'appareil récupère.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Actualiser l\'arrière-plan depuis l\'URL';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Minutes entre deux récupérations d\'un arrière-plan défini par URL. 0 ne le récupère qu\'à l\'enregistrement du paramètre.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Couleur des chiffres';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'La couleur des chiffres à bascule.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Couleur des cartes';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'La couleur des cartes.';

  @override
  String get settingScreensaverFlipBackdropColorTitle =>
      'Couleur d\'arrière-plan';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'La couleur derrière les cartes.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Couleur des chiffres';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'La couleur des chiffres défilants.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Couleur d\'arrière-plan';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'La couleur derrière les chiffres.';

  @override
  String get settingScreensaverClockNightTitle => 'Mode nuit';

  @override
  String get settingScreensaverClockNightDescription =>
      'Changer la couleur de l\'horloge quand la pièce est sombre.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Niveau de lumière';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'À ce niveau de lumière ou en dessous, l\'horloge prend la couleur de nuit.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Couleur de nuit';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'La couleur de l\'horloge et des widgets dans l\'obscurité.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Arrière-plan de nuit';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'La couleur derrière l\'horloge dans l\'obscurité.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Masquer la photo d\'arrière-plan';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Utiliser la couleur d\'arrière-plan de nuit au lieu de la photo tant que le mode nuit est actif.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Couleur des cartes de nuit';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'La couleur des cartes à bascule dans l\'obscurité.';

  @override
  String get screensaverClockSection => 'Économiseur d\'écran horloge';

  @override
  String get screensaverClockHint =>
      'Style, police, taille, couleurs, mode nuit, photo d\'arrière-plan';

  @override
  String get screensaverStyleDigital => 'Horloge numérique';

  @override
  String get screensaverStyleFlip => 'Horloge à bascule';

  @override
  String get screensaverStyleRoller => 'Horloge à rouleaux';

  @override
  String get screensaverFontDefault => 'Par défaut';

  @override
  String get screensaverFontLight => 'Légère';

  @override
  String get screensaverFontRegular => 'Normale';

  @override
  String get screensaverFontMedium => 'Moyenne';

  @override
  String get screensaverFontBold => 'Grasse';

  @override
  String get screensaverFontBlack => 'Extra grasse';

  @override
  String get screensaverNoPhoto => 'Aucune photo sélectionnée';

  @override
  String get screensaverBackgroundHint =>
      'Chemin vers une image sur l\'appareil, ou une URL d\'image';

  @override
  String get screensaverImageUrlError => 'Saisissez une URL d\'image complète';

  @override
  String get screensaverRefreshError =>
      'Saisissez un nombre entier de minutes entre 0 et 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Utilisez au maximum $count caractères';
  }

  @override
  String get screensaverOverlayEntity => 'Entité';

  @override
  String get screensaverOverlayNotSet => 'Non défini';

  @override
  String get screensaverOverlayName => 'Nom';

  @override
  String get screensaverOverlayNameHelp =>
      'Laissez vide pour utiliser le nom Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Valeur affichée';

  @override
  String get screensaverOverlayState => 'État';

  @override
  String get screensaverOverlayEntityRequired => 'Choisissez une entité.';

  @override
  String get screensaverOverlaySearchHint => 'Nom ou identifiant d\'entité';

  @override
  String get screensaverOverlaySearchHintRemote =>
      'Rechercher par nom ou identifiant d\'entité';

  @override
  String get screensaverOverlaySearchEmpty =>
      'Tapez pour rechercher des entités.';

  @override
  String get screensaverOverlayNoMatches => 'Aucun résultat.';

  @override
  String get screensaverOverlaySearching => 'Recherche…';

  @override
  String get screensaverOverlayUnreachable =>
      'Impossible de joindre Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'L\'appareil n\'a pas répondu.';

  @override
  String screensaverOverlaySearchError(String error) {
    return 'Impossible de rechercher les entités : $error';
  }

  @override
  String get settingScreensaverDismissOnFaceTitle => 'Fermer sur visage';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Réveiller l\'écran quand quelqu\'un regarde le kiosque, pas sur simple mouvement. La caméra ne fonctionne que pendant l\'économiseur d\'écran. ATTENTION : nécessite un visage éclairé ; dans l\'obscurité, programmez plutôt la détection de mouvement.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Uniquement quand l\'écran est éteint';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Garder l\'économiseur d\'écran visible quand un visage est détecté alors que l\'écran est allumé. Une fois l\'écran éteint, la détection réveille le tableau de bord. Toucher l\'écran ferme toujours l\'économiseur d\'écran.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Reporter l\'économiseur d\'écran sur visage';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Retarder l\'activation de l\'économiseur d\'écran tant que quelqu\'un regarde le kiosque. ATTENTION : garde la caméra en fonctionnement en permanence, avec en plus la détection de visage et son coût en CPU.';

  @override
  String get settingFaceSensitivityTitle => 'Sensibilité au visage';

  @override
  String get settingFaceSensitivityDescription =>
      'Une valeur plus élevée réveille l\'écran pour des visages plus petits ou plus éloignés. 1 nécessite un visage proche de l\'écran ; 100 réagit à tout visage que la caméra peut distinguer.';

  @override
  String get screensaverDetectionFacePage => 'Détection de visage';

  @override
  String get screensaverDetectionFaceHint =>
      'Fermer l\'économiseur d\'écran quand quelqu\'un le regarde';

  @override
  String get screensaverDetectionMotionPrecedence =>
      '« Fermer sur mouvement » est activé et prend le dessus : la détection de visage reste inactive tant qu\'il n\'est pas désactivé.';

  @override
  String get screensaverDetectionFaceTuning =>
      'La fréquence d\'images, le choix de la caméra et le délai de démarrage se règlent dans les paramètres de la Caméra.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'Non disponible sur cette version d\'Android.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'Non disponible sur les appareils x86.';

  @override
  String get settingFacePreviewTitle => 'Afficher l\'aperçu caméra';

  @override
  String get settingFacePreviewDescription =>
      'Afficher un petit aperçu rond en direct de la caméra dans un coin de l\'écran pendant quelques secondes lorsqu\'un visage réveille le kiosque.';

  @override
  String get settingFacePreviewSecondsTitle => 'Durée de l\'aperçu';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Durée d\'affichage de l\'aperçu à l\'écran.';

  @override
  String get settingFacePreviewScaleTitle => 'Mise à l\'échelle de l\'aperçu';

  @override
  String get settingFacePreviewScaleDescription =>
      'Ajuste la taille de l\'aperçu à votre écran.';

  @override
  String get settingFacePreviewPositionTitle => 'Position de l\'aperçu';

  @override
  String get settingFacePreviewPositionDescription =>
      'Dans quel coin l\'aperçu apparaît.';

  @override
  String get screensaverDetectionPreviewSection => 'Aperçu caméra';

  @override
  String get settingScreensaverEnabledTitle => 'Économiseur d\'écran';

  @override
  String get settingScreensaverEnabledDescription =>
      'Assombrir l\'écran ou l\'afficher en noir après une période d\'inactivité.';

  @override
  String get settingScreensaverTimeoutSecondsTitle =>
      'Délai d\'inactivité (secondes)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Période d\'inactivité avant le démarrage de l\'économiseur d\'écran.';

  @override
  String get settingScreensaverModeTitle => 'Mode de l\'économiseur d\'écran';

  @override
  String get settingScreensaverModeDescription =>
      'Ce que l\'économiseur d\'écran affiche après le délai d\'inactivité. « Tamisé » se contente de baisser le rétroéclairage et laisse le tableau de bord à l\'écran.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Décalage de pixels';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Déplace légèrement l\'image chaque minute pour protéger les écrans OLED. Sans effet pour l\'économiseur d\'écran noir, dont les pixels sont déjà éteints.';

  @override
  String get settingScreensaverMenuTitle => 'Afficher dans le menu du kiosque';

  @override
  String get settingScreensaverMenuDescription =>
      'Ajoute une entrée Démarrer l\'économiseur d\'écran au menu du kiosque.';

  @override
  String get settingScreensaverDimLevelTitle => 'Niveau de tamisage';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Luminosité de l\'écran pendant le tamisage de l\'économiseur d\'écran.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Luminosité de l\'économiseur d\'écran';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Utiliser une luminosité distincte pendant l\'affichage de l\'économiseur d\'écran.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Niveau de luminosité';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'S\'applique à tous les modes sauf Tamisé et Noir.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Éclaircir pour les notifications';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Suspendre le tamisage de l\'économiseur d\'écran tant qu\'une notification est affichée.';

  @override
  String get settingScreensaverScreenOffMinutesTitle =>
      'Éteindre l\'écran après';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Coupe l\'alimentation du panneau d\'affichage une fois l\'économiseur d\'écran actif depuis la durée définie. Réglez sur 0 pour garder l\'écran allumé indéfiniment. Nécessite l\'autorisation Administrateur de l\'appareil.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Réveiller vers l\'économiseur d\'écran';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescription =>
      'La détection de mouvement, de visage, de proximité ou de présence après l\'extinction de l\'écran ramène l\'économiseur d\'écran plutôt que le tableau de bord, avec un nouveau compte à rebours « Éteindre l\'écran après ». Toucher l\'écran ouvre toujours le tableau de bord.';

  @override
  String get screensaverModeDim => 'Tamisé';

  @override
  String get screensaverModeBlack => 'Noir';

  @override
  String get screensaverModeClock => 'Horloge';

  @override
  String get screensaverModeMedia => 'Média Home Assistant';

  @override
  String get screensaverModeLocal => 'Média local';

  @override
  String get screensaverModeGallery => 'Galerie photo';

  @override
  String get screensaverModeImmich => 'Média Immich';

  @override
  String get screensaverModeWebsite => 'Site web';

  @override
  String get screensaverModeCamera => 'Flux de caméras';

  @override
  String get screensaverDimSection => 'Économiseur d\'écran tamisé';

  @override
  String get screensaverWarningTitle => 'ATTENTION : à lire attentivement !';

  @override
  String get screensaverScreenOffProceed => 'Éteindre l\'écran quand même';

  @override
  String get screensaverAdminMissing =>
      'Non accordée : l\'écran ne peut donc pas s\'éteindre.';

  @override
  String get screensaverAdminMissingRemote =>
      'Autorisation Administrateur de l\'appareil manquante';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Sans elle, l\'écran ne peut pas être éteint. La boîte de dialogue d\'autorisation apparaît sur l\'écran de la tablette.';

  @override
  String get screensaverDimWarning =>
      'ATTENTION : « Tamisé » garde le tableau de bord visible : l\'optimisation « Suspendre le tableau de bord pendant l\'économiseur d\'écran » ne sera donc pas appliquée et le tableau de bord continuera d\'utiliser le CPU, le GPU et la batterie.';

  @override
  String get screensaverUnavailablePlugin =>
      'Économiseur d\'écran de plugin indisponible';

  @override
  String get screensaverScreenOffWarning =>
      'Une fois que l\'affichage s\'éteint réellement, la gestion de l\'alimentation propre à la tablette prend le relais, et de nombreux modèles Android se comportent alors mal : le Wi-Fi somnole ou se coupe, les entités Home Assistant deviennent indisponibles, l\'accès à la caméra peut être révoqué, et certains modèles arrêtent purement et simplement les applications en arrière-plan. Le comportement dépend du fabricant.\n\nL\'alternative fiable est l\'économiseur d\'écran Noir avec ce paramètre laissé à 0 : le panneau paraît tout aussi sombre, et l\'application garde le contrôle total.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Utiliser un écran noir à la place';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Afficher un écran entièrement noir à luminosité nulle au lieu d\'éteindre l\'affichage. Masque les widgets et Lecture en cours. Aucune autorisation Administrateur de l\'appareil n\'est nécessaire.';

  @override
  String get settingScreensaverGlanceScaleTitle =>
      'Mise à l\'échelle de la ligne';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Ajuste la taille de la ligne à votre écran.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Famille de police';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'La police avec laquelle la ligne est dessinée.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Graisse de police';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Épaisseur du texte de la ligne. Par défaut, chaque ligne garde sa propre graisse : normale pour les noms, semi-grasse pour les valeurs.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Masquer les noms';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Afficher uniquement l\'icône et la valeur, avec la valeur dessinée plus grande.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Icônes monochromes';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Garder chaque icône dans un gris neutre au lieu de la couleur de son état.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle => 'Style de texte flottant';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Afficher les entités sous forme de texte flottant au lieu de puces.';

  @override
  String get screensaverOverlayAppearance => 'Apparence';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'En un coup d\'œil';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Afficher une ligne d\'états d\'entités Home Assistant sur l\'économiseur d\'écran.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entités';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Jusqu\'à quatre entités à afficher, chacune avec un nom personnalisé facultatif.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Afficher sur Lecture en cours';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Afficher la ligne sur la vue plein écran Lecture en cours. Elle reste masquée pendant l\'affichage des paroles.';

  @override
  String get screensaverOverlayShowing => 'Affichées';

  @override
  String get screensaverOverlayReorder =>
      'Affichées (glisser pour réorganiser)';

  @override
  String get screensaverOverlayFull =>
      'C\'est le maximum que la ligne peut afficher. Retirez-en une pour en ajouter une autre.';

  @override
  String get screensaverOverlayPickerTitle => 'Entités « En un coup d\'œil »';

  @override
  String screensaverOverlayGlanceEmpty(String count) {
    return 'Aucune pour l\'instant. Jusqu\'à $count entités.';
  }

  @override
  String get screensaverOverlayNone => 'Aucune pour l\'instant';

  @override
  String screensaverOverlayLimit(String count) {
    return 'Jusqu\'à $count entités.';
  }

  @override
  String get screensaverOverlayGlancePage => 'En un coup d\'œil';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entités affichées par-dessus l\'économiseur d\'écran';

  @override
  String get glanceUnavailable => 'Indisponible';

  @override
  String get glanceUnknown => 'Inconnu';

  @override
  String get settingScreensaverImmichUrlTitle => 'Adresse du serveur';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'L\'adresse de votre serveur Immich, avec son port.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'Clé API';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Créée dans Immich sous Paramètres du compte → Clés API.';

  @override
  String get screensaverMediaImmichPage => 'Économiseur d\'écran média Immich';

  @override
  String get screensaverMediaImmichHint =>
      'Serveur, média, diaporama, métadonnées, filtres';

  @override
  String get screensaverMediaServerConnection => 'Connexion au serveur';

  @override
  String get screensaverMediaValidateFailedLog =>
      'Échec de la validation. Consultez le journal de l\'application pour l\'appel en échec.';

  @override
  String get screensaverMediaValidateFailed => 'Échec de la validation.';

  @override
  String get screensaverMediaNoAnswer => 'L\'appareil n\'a pas répondu.';

  @override
  String get screensaverMediaAddressFirst =>
      'Saisissez d\'abord l\'adresse du serveur.';

  @override
  String get screensaverMediaKeyFirst => 'Saisissez d\'abord une clé API.';

  @override
  String get screensaverMediaBadAddress =>
      'L\'adresse du serveur n\'est pas une URL valide.';

  @override
  String get screensaverMediaKeyRejected => 'La clé API a été rejetée.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'Il manque à la clé API l\'autorisation $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'Il manque une autorisation à la clé API : $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'Le serveur a répondu $status : $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'Impossible de joindre $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'Impossible de communiquer avec le serveur : $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Personnes';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Afficher uniquement les médias avec l\'une de ces personnes.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle =>
      'Exclure des personnes';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Ignorer les médias avec l\'une de ces personnes.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Étiquettes';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Afficher uniquement les médias portant l\'une de ces étiquettes.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle =>
      'Exclure des étiquettes';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Ignorer les médias portant l\'une de ces étiquettes.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Favoris uniquement';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Afficher uniquement les médias marqués comme favoris.';

  @override
  String get settingScreensaverImmichTakenWithinTitle =>
      'Période de prise de vue';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'N\'afficher que les médias pris dans cette période.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Du';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Ignorer les médias pris avant cette date.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Au';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Ignorer les médias pris après cette date. Le jour lui-même est inclus.';

  @override
  String get screensaverMediaFilters => 'Filtres';

  @override
  String get screensaverMediaAnyone => 'N\'importe qui';

  @override
  String get screensaverMediaAnyoneDevice => 'N\'importe qui.';

  @override
  String get screensaverMediaNoOne => 'Personne';

  @override
  String get screensaverMediaNoOneDevice => 'Personne.';

  @override
  String get screensaverMediaAny => 'N\'importe laquelle';

  @override
  String get screensaverMediaAnyDevice => 'N\'importe laquelle.';

  @override
  String get screensaverMediaNoTagsChosen => 'Aucune étiquette';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Aucune étiquette.';

  @override
  String get screensaverMediaNoPeople =>
      'Aucune personne nommée pour l\'instant. Nommez-les d\'abord dans Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Aucune étiquette pour l\'instant. Créez-les d\'abord dans Immich.';

  @override
  String get screensaverMediaPeopleFailed =>
      'Impossible de lister les personnes';

  @override
  String get screensaverMediaTagsFailed =>
      'Impossible de lister les étiquettes';

  @override
  String get screensaverMediaHidden => 'Masqué';

  @override
  String get screensaverMediaAnyTime => 'N\'importe quand';

  @override
  String get screensaverMediaPastMonth => 'Dernier mois';

  @override
  String get screensaverMediaPast3Months => '3 derniers mois';

  @override
  String get screensaverMediaPastYear => 'Dernière année';

  @override
  String get screensaverMediaPast2Years => '2 dernières années';

  @override
  String get screensaverMediaPast5Years => '5 dernières années';

  @override
  String get screensaverMediaPast10Years => '10 dernières années';

  @override
  String get screensaverMediaSince => 'Depuis';

  @override
  String get screensaverMediaTimeframe => 'Période';

  @override
  String get screensaverMediaToday => 'Aujourd\'hui';

  @override
  String get screensaverMediaDateFormat => 'Utilisez AAAA-MM-JJ.';

  @override
  String get screensaverMediaNotDate => 'Ce n\'est pas une date.';

  @override
  String get settingScreensaverImmichMetadataTitle =>
      'Afficher les métadonnées';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Album, date, appareil photo et lieu par-dessus le média.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Nom de l\'album';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Afficher de quel album provient la photo.';

  @override
  String get settingScreensaverImmichMetadataDateTitle =>
      'Date de prise de vue';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Afficher la date de prise de vue de la photo.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle =>
      'Détails de l\'appareil photo';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Afficher la focale, l\'ouverture et la sensibilité ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Lieu';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Afficher l\'endroit où la photo a été prise.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Position des métadonnées';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'Dans quel coin les détails apparaissent.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle =>
      'Ombre portée du texte';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Ajouter une ombre portée au texte des métadonnées pour la lisibilité sur les photos.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle =>
      'Mise à l\'échelle du texte';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Ajuste la taille des détails de la photo à votre écran.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Intensité du vignettage';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Opacité de l\'ombrage sombre derrière les détails, pour la lisibilité sur les photos claires. 0 le désactive.';

  @override
  String get screensaverMediaMetadata => 'Métadonnées';

  @override
  String get screensaverMediaTopLeft => 'En haut à gauche';

  @override
  String get screensaverMediaTopRight => 'En haut à droite';

  @override
  String get screensaverMediaBottomLeft => 'En bas à gauche';

  @override
  String get screensaverMediaBottomRight => 'En bas à droite';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Secondes par image';

  @override
  String get settingScreensaverImmichIntervalDescription =>
      'Durée d\'affichage de chaque image avant la suivante. Les vidéos sont lues en entier.';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Aléatoire';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Parcourir le média dans un ordre aléatoire.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Transition';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Comment un élément cède la place au suivant.';

  @override
  String get settingScreensaverImmichFillTitle => 'Remplir l\'écran';

  @override
  String get settingScreensaverImmichFillDescription =>
      '« Désactivé » garde la photo entière entre des bandes noires. « Intelligent » agrandit les photos dont la forme est proche de celle de l\'écran et encadre les autres sur un arrière-plan flouté. « Toujours » agrandit chaque photo en coupant ce qui dépasse.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Associer les photos portrait';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Afficher deux photos portrait côte à côte pour qu\'elles remplissent l\'écran.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Associer les photos paysage';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Afficher deux photos paysage l\'une au-dessus de l\'autre pour qu\'elles remplissent un écran en portrait.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Appuyer sur les bords pour changer de diapositive';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Un appui sur le cinquième gauche ou droit de l\'écran affiche la diapositive précédente ou suivante au lieu de fermer l\'économiseur d\'écran.';

  @override
  String get screensaverMediaSlideshow => 'Diaporama';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Source multimédia';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Toute la bibliothèque, ou les albums que vous choisissez.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Photos uniquement';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Ignorer les vidéos dans le diaporama.';

  @override
  String get settingScreensaverImmichCacheTitle =>
      'Mettre le média en cache localement';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Conserver des copies sur l\'appareil pour un chargement instantané des images.';

  @override
  String get settingScreensaverImmichCacheMaxTitle =>
      'Taille du cache (éléments)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Les éléments les plus anciens sont supprimés une fois le cache plein.';

  @override
  String get screensaverMediaAll => 'Tous les médias';

  @override
  String get screensaverMediaAllDevice => 'Tous les médias.';

  @override
  String get screensaverMediaNoAlbums =>
      'Aucun album pour l\'instant. Créez-en d\'abord un dans Immich.';

  @override
  String get screensaverMediaAlbumsFailed => 'Impossible de lister les albums';

  @override
  String screensaverMediaListError(String error) {
    return 'Impossible de les lister : $error';
  }

  @override
  String get screensaverMediaListingFailed =>
      'échec de la récupération de la liste';

  @override
  String screensaverMediaItems(String count) {
    return '$count éléments';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count en cache, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Vues caméra';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Les vues caméra que l\'économiseur d\'écran affiche, dans cet ordre.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Secondes par vue caméra';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Durée d\'affichage de chaque vue avant la suivante. Avec une seule vue sélectionnée, il n\'y a pas de rotation.';

  @override
  String get settingScreensaverCameraMuteTitle =>
      'Couper le son sur toutes les vues';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Garde toutes les vues silencieuses, même une seule caméra.';

  @override
  String get screensaverMediaCameraPage =>
      'Économiseur d\'écran flux de caméras';

  @override
  String get screensaverMediaCameraHint =>
      'Vues à afficher, secondes par vue, son';

  @override
  String get screensaverMediaNoCameras =>
      'Aucune vue caméra n\'a de caméras pour l\'instant. Ajoutez-en une dans Flux de caméras.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Aucune vue caméra n\'a de caméras pour l\'instant';

  @override
  String get screensaverMediaAddCameras =>
      'Ajoutez-en une dans Flux de caméras.';

  @override
  String get screensaverMediaNoViews =>
      'Aucune pour l\'instant. Choisissez les vues que l\'économiseur d\'écran doit faire défiler.';

  @override
  String get screensaverMediaRotation =>
      'Dans la rotation (glisser pour réorganiser)';

  @override
  String get screensaverMediaAvailable => 'Disponible';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count caméra';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count caméras';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Position $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Aucune';

  @override
  String get screensaverMediaTransitionFade => 'Fondu enchaîné';

  @override
  String get screensaverMediaTransitionSlide => 'Glissement';

  @override
  String get screensaverMediaTransitionZoom => 'Zoom';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Aléatoire';

  @override
  String get screensaverMediaFillOff => 'Désactivé';

  @override
  String get screensaverMediaFillSmart => 'Intelligent';

  @override
  String get screensaverMediaFillAlways => 'Toujours';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Photos';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Les photos et vidéos que cet économiseur d\'écran fait défiler. Choisies depuis la galerie de l\'appareil ; une nouvelle sélection remplace la précédente.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Secondes par photo';

  @override
  String get settingScreensaverGalleryIntervalDescription =>
      'Durée d\'affichage de chaque photo avant la suivante. Les vidéos sont lues en entier.';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Aléatoire';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Parcourir la sélection dans un ordre aléatoire.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Transition';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Comment une photo cède la place à la suivante.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Remplir l\'écran';

  @override
  String get settingScreensaverGalleryFillDescription =>
      '« Désactivé » garde la photo entière entre des bandes noires. « Intelligent » agrandit les photos dont la forme est proche de celle de l\'écran et encadre les autres sur un arrière-plan flouté. « Toujours » agrandit chaque photo en coupant ce qui dépasse.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Appuyer sur les bords pour changer de diapositive';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Un appui sur le cinquième gauche ou droit de l\'écran affiche la diapositive précédente ou suivante au lieu de fermer l\'économiseur d\'écran.';

  @override
  String get screensaverMediaGalleryPage =>
      'Économiseur d\'écran galerie photo';

  @override
  String get screensaverMediaGalleryHint =>
      'Photos, cadence, aléatoire, transition';

  @override
  String get screensaverMediaLoadingPhotos => 'Chargement des photos...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Copie de la photo $index sur $total...';
  }

  @override
  String get screensaverMediaCopyFailed => 'Impossible de copier les photos';

  @override
  String get screensaverMediaSmallerSelection =>
      'Essayez une sélection plus réduite.';

  @override
  String get screensaverMediaNoPhotos => 'Aucune photo sélectionnée';

  @override
  String screensaverMediaSelected(String count) {
    return 'Sélection : $count';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'Aucune sélection. Choisissez sur l\'appareil.';

  @override
  String get settingScreensaverMediaIdTitle => 'Source multimédia';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Un média, un dossier ou une caméra de Home Assistant. Utilisez Parcourir pour en choisir un.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Secondes par image';

  @override
  String get settingScreensaverMediaIntervalDescription =>
      'Durée d\'affichage de chaque image avant la suivante. Les vidéos sont lues en entier.';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Aléatoire';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Lire un dossier dans un ordre aléatoire.';

  @override
  String get settingScreensaverMediaRecursiveTitle =>
      'Inclure les sous-dossiers';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Inclure le contenu des sous-dossiers lorsqu\'un dossier est choisi.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Transition';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Comment un élément cède la place au suivant.';

  @override
  String get settingScreensaverMediaFillTitle => 'Remplir l\'écran';

  @override
  String get settingScreensaverMediaFillDescription =>
      '« Désactivé » garde la photo entière entre des bandes noires. « Intelligent » agrandit les photos dont la forme est proche de celle de l\'écran et encadre les autres sur un arrière-plan flouté. « Toujours » agrandit chaque photo en coupant ce qui dépasse.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Appuyer sur les bords pour changer de diapositive';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Un appui sur le cinquième gauche ou droit de l\'écran affiche la diapositive précédente ou suivante au lieu de fermer l\'économiseur d\'écran.';

  @override
  String get screensaverMediaHaPage =>
      'Économiseur d\'écran média Home Assistant';

  @override
  String get screensaverMediaHaHint =>
      'Source multimédia, cadence, aléatoire, remplissage';

  @override
  String get screensaverMediaChoose => 'Choisir un média';

  @override
  String get screensaverMediaRoot => 'Média';

  @override
  String get screensaverMediaHaUnavailable =>
      'Impossible de joindre Home Assistant, ou le jeton est manquant.';

  @override
  String get screensaverMediaEmpty => 'Aucun contenu ici.';

  @override
  String get screensaverMediaUseFolder => 'Utiliser ce dossier';

  @override
  String get screensaverMediaFolder => 'dossier';

  @override
  String get screensaverMediaCamera => 'caméra';

  @override
  String get screensaverMediaItem => 'élément';

  @override
  String get screensaverMediaBrowseFailed => 'échec de l\'exploration';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'Impossible de parcourir : $error';
  }

  @override
  String get screensaverMediaNotSet => 'Non défini';

  @override
  String get settingScreensaverLocalFolderTitle => 'Dossier local';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Dossier sur cet appareil dont l\'économiseur d\'écran fait défiler les photos et vidéos. Choisi sur l\'appareil ; le chemin peut aussi être saisi ici à distance.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Secondes par photo';

  @override
  String get settingScreensaverLocalIntervalDescription =>
      'Durée d\'affichage de chaque photo avant la suivante. Les vidéos sont lues en entier.';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Aléatoire';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Parcourir le dossier dans un ordre aléatoire plutôt que par nom.';

  @override
  String get settingScreensaverLocalRecursiveTitle =>
      'Inclure les sous-dossiers';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Parcourir aussi les photos et vidéos des sous-dossiers.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Transition';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Comment une photo cède la place à la suivante.';

  @override
  String get settingScreensaverLocalFillTitle => 'Remplir l\'écran';

  @override
  String get settingScreensaverLocalFillDescription =>
      '« Désactivé » garde la photo entière entre des bandes noires. « Intelligent » agrandit les photos dont la forme est proche de celle de l\'écran et encadre les autres sur un arrière-plan flouté. « Toujours » agrandit chaque photo en coupant ce qui dépasse.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Appuyer sur les bords pour changer de diapositive';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Un appui sur le cinquième gauche ou droit de l\'écran affiche la diapositive précédente ou suivante au lieu de fermer l\'économiseur d\'écran.';

  @override
  String get screensaverMediaLocalPage => 'Économiseur d\'écran média local';

  @override
  String get screensaverMediaLocalHint =>
      'Dossier, cadence, aléatoire, transition';

  @override
  String get settingScreensaverDismissOnMotionTitle => 'Fermer sur mouvement';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Surveiller la caméra tant que l\'économiseur d\'écran est actif et réveiller l\'écran quand quelqu\'un s\'approche. La caméra ne fonctionne que pendant l\'économiseur d\'écran.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Uniquement quand l\'écran est éteint';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Garder l\'économiseur d\'écran visible quand un mouvement est détecté alors que l\'écran est allumé. Une fois l\'écran éteint, la détection réveille le tableau de bord. Toucher l\'écran ferme toujours l\'économiseur d\'écran.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Reporter l\'économiseur d\'écran sur mouvement';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Retarder l\'activation de l\'économiseur d\'écran quand un mouvement est détecté. ATTENTION : garde la caméra en fonctionnement en permanence.';

  @override
  String get screensaverDetectionMotionPage => 'Détection de mouvement';

  @override
  String get screensaverDetectionMotionHint =>
      'Fermer ou reporter l\'économiseur d\'écran sur mouvement';

  @override
  String get screensaverDetectionMotionTuning =>
      'La détection de mouvement se règle dans les paramètres de la Caméra.';

  @override
  String get settingScreensaverDismissOnPersonTitle => 'Fermer sur présence';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Lire le capteur de présence de l\'appareil tant que l\'économiseur d\'écran est actif et réveiller l\'écran quand quelqu\'un se trouve devant. Nécessite l\'autorisation d\'accès aux journaux ci-dessous.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Uniquement quand l\'écran est éteint';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Garder l\'économiseur d\'écran visible quand quelqu\'un arrive alors que l\'écran est allumé. Une fois l\'écran éteint, la détection réveille le tableau de bord. Toucher l\'écran ferme toujours l\'économiseur d\'écran.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Reporter l\'économiseur d\'écran sur présence';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Retarder l\'activation de l\'économiseur d\'écran tant que quelqu\'un se trouve devant l\'appareil.';

  @override
  String get screensaverDetectionPersonPage => 'Détection de présence';

  @override
  String get screensaverDetectionPersonHint =>
      'Fermer ou reporter l\'économiseur d\'écran via le capteur de présence de l\'appareil';

  @override
  String get screensaverDetectionOccupancy => 'Occupation';

  @override
  String get screensaverDetectionStatusUnavailable => 'État indisponible.';

  @override
  String get screensaverDetectionOff => 'Désactivé.';

  @override
  String get screensaverDetectionStarting => 'Démarrage...';

  @override
  String get screensaverDetectionWaiting =>
      'En attente du premier signal. Le capteur transmet une mesure toutes les 30 secondes tant que quelqu\'un est visible.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Dernier signal $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return 'il y a $count s';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return 'il y a $count min';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return 'il y a $count h';
  }

  @override
  String get screensaverDetectionDetected => 'Détecté';

  @override
  String get screensaverDetectionClear => 'Libre';

  @override
  String get screensaverDetectionPermissions =>
      'Autorisations système requises';

  @override
  String get screensaverDetectionLogAccess => 'Accès aux journaux';

  @override
  String get screensaverDetectionChecking => 'Vérification...';

  @override
  String get screensaverDetectionReadable =>
      'Le capteur de présence de l\'appareil peut être lu.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Accordée. Redémarrez Kiosk Satellite pour l\'appliquer.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Cette autorisation ne peut être accordée que via ADB. La documentation Meta Portal contient la commande complète. Redémarrez Kiosk Satellite ensuite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Cette autorisation ne peut être accordée que via ADB. Voici la commande complète, prête à être copiée. Redémarrez Kiosk Satellite ensuite.';

  @override
  String get screensaverDetectionGranted => 'Accordée';

  @override
  String get screensaverDetectionMissing => 'Manquante';

  @override
  String get screensaverDetectionRestart => 'Redémarrer';

  @override
  String get screensaverDetectionRestartRemote => 'Redémarrer sur l\'appareil';

  @override
  String get screensaverDetectionLogRestart =>
      'L\'accès aux journaux est accordé mais prend effet au redémarrage de Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing =>
      'Accès aux journaux non accordé.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Fermer sur proximité';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Surveiller le capteur de proximité tant que l\'économiseur d\'écran est actif et réveiller l\'écran quand quelque chose s\'approche de l\'appareil. Un appareil équipé uniquement de capteurs conçus pour les appels (« palm », « touch ») ne fonctionnera pas.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Uniquement quand l\'écran est éteint';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Garder l\'économiseur d\'écran visible quand quelque chose s\'approche alors que l\'écran est allumé. Une fois l\'écran éteint, la détection réveille le tableau de bord. Toucher l\'écran ferme toujours l\'économiseur d\'écran.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Reporter l\'économiseur d\'écran sur proximité';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Retarder l\'activation de l\'économiseur d\'écran tant que quelque chose est proche du capteur.';

  @override
  String get screensaverDetectionProximityPage => 'Détection de proximité';

  @override
  String get screensaverDetectionProximityHint =>
      'Fermer ou reporter l\'économiseur d\'écran via le capteur de proximité';

  @override
  String get screensaverDetectionNoProximity =>
      'Non disponible sur cet appareil : il n\'a pas de capteur de proximité.';

  @override
  String get screensaverDetectionSensor => 'Capteur';

  @override
  String get screensaverDetectionSensorHelp =>
      'Ce que l\'appareil indique comme capteur de proximité. Un capteur conçu pour les appels nommé « palm » ou « touch » ne fonctionnera pas.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Activer les économiseurs d\'écran programmés';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Changer d\'économiseur d\'écran à des heures précises de la journée.';

  @override
  String get settingScreensaverScheduleTitle => 'Horaires';

  @override
  String get settingScreensaverScheduleDescription =>
      'Chaque horaire change l\'économiseur d\'écran à partir de ce moment.';

  @override
  String get screensaverScheduleSection => 'Économiseurs d\'écran programmés';

  @override
  String get screensaverTime => 'Heure';

  @override
  String get screensaverAddTime => 'Ajouter un horaire';

  @override
  String get screensaverRemoveTime => 'Supprimer l\'horaire';

  @override
  String get screensaverNoTimes => 'Pas encore d\'horaires';

  @override
  String get screensaverTimeHelp =>
      'Un économiseur d\'écran à partir de cette heure.';

  @override
  String get screensaverPickTime => 'Choisissez une heure.';

  @override
  String get screensaverDefault => 'Par défaut';

  @override
  String get screensaverOn => 'Activé';

  @override
  String get screensaverOff => 'Désactivé';

  @override
  String get screensaverBrightness => 'Luminosité';

  @override
  String get screensaverBrightnessFollow =>
      'Suit le paramètre de luminosité de l\'économiseur d\'écran.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'S\'applique à tous les modes sauf Noir.';

  @override
  String get screensaverScreenOffFollow =>
      'Suit le paramètre « Éteindre l\'écran après ».';

  @override
  String get screensaverScreenOnHours =>
      'Garde l\'écran allumé pendant ces heures.';

  @override
  String get screensaverScreenOffHelp =>
      'Coupe l\'alimentation de l\'affichage une fois l\'économiseur d\'écran actif depuis cette durée. Nécessite l\'autorisation Administrateur de l\'appareil.';

  @override
  String get screensaverScreenOffNever => 'Écran jamais éteint';

  @override
  String get screensaverMotion => 'Fermer sur mouvement';

  @override
  String get screensaverFace => 'Fermer sur visage';

  @override
  String get screensaverProximity => 'Fermer sur proximité';

  @override
  String get screensaverPerson => 'Fermer sur présence';

  @override
  String get screensaverWidgets => 'Widgets';

  @override
  String get screensaverGlance => 'En un coup d\'œil';

  @override
  String get screensaverNowPlaying =>
      'Afficher Lecture en cours à côté de l\'économiseur d\'écran';

  @override
  String get screensaverNowPlayingHelp =>
      '« Par défaut » suit la disposition globale. « Activé » utilise une disposition partagée quand Lecture en cours est activée. « Désactivé » masque Lecture en cours pendant ces heures.';

  @override
  String get screensaverCameraRequired =>
      'Nécessite la caméra. Activez-la d\'abord dans les paramètres de la Caméra.';

  @override
  String get screensaverNotAvailable => 'Non disponible sur cet appareil.';

  @override
  String get screensaverSummaryMotionOn => 'Mouvement activé';

  @override
  String get screensaverSummaryMotionOff => 'Mouvement désactivé';

  @override
  String get screensaverSummaryFaceOn => 'Visage activé';

  @override
  String get screensaverSummaryFaceOff => 'Visage désactivé';

  @override
  String get screensaverSummaryProximityOn => 'Proximité activée';

  @override
  String get screensaverSummaryProximityOff => 'Proximité désactivée';

  @override
  String get screensaverSummaryPersonOn => 'Présence activée';

  @override
  String get screensaverSummaryPersonOff => 'Présence désactivée';

  @override
  String get screensaverSummaryWidgetsOn => 'Widgets activés';

  @override
  String get screensaverSummaryWidgetsOff => 'Widgets désactivés';

  @override
  String get screensaverSummaryGlanceOn => 'En un coup d\'œil activé';

  @override
  String get screensaverSummaryGlanceOff => 'En un coup d\'œil désactivé';

  @override
  String get screensaverSummaryNowPlayingOn => 'Lecture en cours activée';

  @override
  String get screensaverSummaryNowPlayingOff => 'Lecture en cours désactivée';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Luminosité $percent %';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Écran éteint après $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Ambiance météo';

  @override
  String get screensaverWeatherMoodPage => 'Économiseur d’écran Ambiance météo';

  @override
  String get screensaverWeatherMoodSummary => 'Entité météo, éclairs, aperçu';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Entité météo';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'L’entité météo Home Assistant qui contrôle la scène animée. Le jour, l’aube/crépuscule et la nuit suivent sun.sun, avec l’heure locale comme solution de repli.';

  @override
  String get settingScreensaverWeatherLightningTitle => 'Éclairs';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Afficher les éclairs et l’illumination des nuages pendant les orages.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Sélectionnez une entité météo dans Paramètres > Économiseur d’écran > Ambiance météo.';

  @override
  String get screensaverWeatherPreviewGroup => 'Aperçu météo';

  @override
  String get settingScreensaverWeatherPreviewTitle => 'Activer l’aperçu météo';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Affiche la scène sélectionnée à la place de la météo actuelle. Désactivez l’aperçu pour suivre à nouveau Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Type de météo';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'La scène météo animée à afficher dans l’aperçu.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle =>
      'Moment de la journée';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Choisir la version de jour, d’aube/crépuscule ou de nuit de la scène.';

  @override
  String get screensaverWeatherPreviewSunny => 'Ciel dégagé';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Partiellement nuageux';

  @override
  String get screensaverWeatherPreviewCloudy => 'Nuageux';

  @override
  String get screensaverWeatherPreviewRainy => 'Pluie';

  @override
  String get screensaverWeatherPreviewPouring => 'Forte pluie';

  @override
  String get screensaverWeatherPreviewSnowy => 'Neige';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Neige et pluie';

  @override
  String get screensaverWeatherPreviewFog => 'Brouillard';

  @override
  String get screensaverWeatherPreviewHail => 'Grêle';

  @override
  String get screensaverWeatherPreviewLightning => 'Éclairs';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Éclairs et pluie';

  @override
  String get screensaverWeatherPreviewWindy => 'Vent';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Vent et nuages';

  @override
  String get screensaverWeatherPreviewExceptional => 'Météo exceptionnelle';

  @override
  String get screensaverWeatherPreviewDay => 'Jour';

  @override
  String get screensaverWeatherPreviewNight => 'Nuit';

  @override
  String get settingScreensaverWeatherClockTitle => 'Activer l’horloge';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Afficher une horloge numérique sur la scène météo.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Ajouter une ombre au texte pour le rendre plus lisible sur la scène météo.';

  @override
  String get screensaverWeatherBarGroup => 'Informations météo';

  @override
  String get settingScreensaverWeatherBarTitle => 'Activer la barre météo';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Afficher les informations météo en direct en bas de l’écran.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Taille du texte';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Ajuster la taille des informations météo de 50 à 200 pour cent.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Couleur du texte';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'La couleur des informations météo.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle =>
      'Opacité de l’arrière-plan';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Assombrir la barre inférieure pour que les informations météo restent lisibles.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Afficher les titres';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Nommer chaque mesure au-dessus de sa valeur. Sans titres, les valeurs ont la taille de la température.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Afficher l’humidité lorsque l’entité météo la fournit.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Afficher la vitesse du vent lorsque l’entité météo la fournit.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Afficher la visibilité lorsque l’entité météo la fournit.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Flou de la scène';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Adoucir la scène météo animée tout en gardant l’horloge, la barre météo et les widgets nets.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Aube/Crépuscule';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Affiche la température ressentie à la place de la température réelle lorsqu’elle est disponible.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'URL du site web';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Une page à afficher en plein écran. Elle doit autoriser l\'intégration (embedding).';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Niveau de zoom';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Met à l\'échelle l\'ensemble de la vue web de l\'économiseur d\'écran externe.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Double appui pour fermer';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Les appuis simples interagissent avec le site web au lieu de fermer l\'économiseur d\'écran.';

  @override
  String get screensaverWebsiteSection => 'Économiseur d\'écran site web';

  @override
  String get screensaverOverlaySmallClock => 'Petite horloge';

  @override
  String get screensaverOverlayWeather => 'Météo';

  @override
  String get screensaverOverlayBattery => 'Batterie';

  @override
  String get screensaverOverlayClockNote =>
      'Masqué dans les modes d\'économiseur d\'écran Horloge numérique et Flux de caméras.';

  @override
  String get screensaverOverlayCameraNote =>
      'Masqué dans le mode d\'économiseur d\'écran Flux de caméras.';

  @override
  String get screensaverOverlayScale => 'Échelle';

  @override
  String get screensaverOverlayScaleHelp =>
      'Ajuste la taille de ce widget à votre écran.';

  @override
  String get screensaverOverlayFont => 'Famille de police';

  @override
  String get screensaverOverlayCorner => 'Coin';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => 'Horloge 24 heures';

  @override
  String get screensaverOverlayClock24Help =>
      'Afficher une heure au format 24 heures plutôt qu\'AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Afficher la date';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Ajouter une date courte sous l\'horloge.';

  @override
  String get screensaverOverlayPercentage => 'Afficher le pourcentage';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Le niveau de charge à côté de l\'icône.';

  @override
  String get screensaverOverlayLow => 'Uniquement si la batterie est faible';

  @override
  String get screensaverOverlayLowHelp =>
      'Rester masqué tant que la charge n\'est pas descendue à 20 %.';

  @override
  String get screensaverOverlayShowName => 'Afficher le nom';

  @override
  String get screensaverOverlayShowNameHelp => 'Le nom sous la valeur.';

  @override
  String get screensaverOverlayFontSystem => 'Système';

  @override
  String get screensaverOverlayFontSerif => 'Serif';

  @override
  String get screensaverOverlayFontCondensed => 'Condensée';

  @override
  String get screensaverOverlayFontMonospace => 'Monospace';

  @override
  String get screensaverOverlayFontCasual => 'Manuscrite décontractée';

  @override
  String get screensaverOverlayFontCursive => 'Cursive';

  @override
  String get screensaverOverlayColor => 'Couleur';

  @override
  String get screensaverOverlayWeatherEntity => 'Entité météo';

  @override
  String get screensaverOverlayNoWeather => 'Aucune entité météo';

  @override
  String get screensaverOverlayNoWeatherHelp =>
      'Home Assistant n\'en a signalé aucune.';

  @override
  String get screensaverOverlayPickWeather => 'Choisir une entité météo…';

  @override
  String get screensaverOverlayWeatherRequired =>
      'Choisissez une entité météo.';

  @override
  String get screensaverOverlayLocationName => 'Nom du lieu';

  @override
  String get screensaverOverlayLocationHelp =>
      'Laissez vide pour masquer la ligne du lieu.';

  @override
  String get screensaverOverlayLocation => 'Lieu';

  @override
  String get screensaverOverlayLocationDetail =>
      'Le nom du lieu au-dessus de la température.';

  @override
  String get screensaverOverlayFeelsLike => 'Ressenti';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Affiche la température ressentie sur une ligne avec un libellé sous la température réelle.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Ressenti uniquement';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Affiche la température ressentie avec le libellé « Ressenti » à la place de la température réelle.';

  @override
  String get screensaverOverlayForecast => 'Prévisions';

  @override
  String get screensaverOverlayForecastHelp =>
      'Les conditions météo, avec l\'icône correspondante.';

  @override
  String get screensaverOverlayHumidity => 'Humidité';

  @override
  String get screensaverOverlayWind => 'Vitesse du vent';

  @override
  String get screensaverOverlayVisibility => 'Visibilité';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Ressenti : $temperature';
  }

  @override
  String get settingScreensaverWidgetsTitle => 'Widgets';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Petites superpositions dans les coins de l\'économiseur d\'écran.';

  @override
  String get settingScreensaverWidgetScaleTitle =>
      'Mise à l\'échelle globale des widgets';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Ajuste la taille de tous les widgets à votre écran. Chaque widget conserve sa propre échelle par rapport aux autres.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Famille de police globale';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'La police avec laquelle chaque widget est dessiné. Un widget peut choisir la sienne.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Graisse de police globale';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Épaisseur du texte de chaque widget. Par défaut, chaque ligne garde sa propre graisse. Un widget peut choisir la sienne.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Ombre portée du texte';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Ajouter une ombre portée au texte des widgets pour la lisibilité sur les photos.';

  @override
  String get settingScreensaverVignetteStrengthTitle =>
      'Intensité du vignettage';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Opacité de l\'ombrage sombre derrière les widgets, pour la lisibilité sur les photos claires. 0 le désactive.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Pas encore de widgets';

  @override
  String get screensaverOverlayRemove => 'Supprimer le widget';

  @override
  String get screensaverOverlayAdd => 'Ajouter un widget';

  @override
  String get screensaverOverlayAddHelp =>
      'Une petite horloge, la météo, la batterie ou une entité dans un coin.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Superpositions en coin et leur échelle';

  @override
  String get settingsSearchHint => 'Rechercher dans les paramètres';

  @override
  String get settingsSearchClear => 'Effacer la recherche';

  @override
  String get settingsSearchResults => 'Résultats de recherche';

  @override
  String settingsSearchEmpty(String query) {
    return 'Aucun paramètre ne correspond à « $query ».';
  }

  @override
  String get searchInstallApk =>
      'Envoyez un APK de Kiosk Satellite via l\'administration à distance et installez-le.';

  @override
  String get searchPermissionsHelp =>
      'Chaque autorisation Android utilisable par l\'application, avec son statut : microphone, caméra, notifications, batterie sans restriction, affichage par-dessus d\'autres applications, modification des paramètres système, protection de l\'interface système, administrateur de l\'appareil, accès à tous les fichiers, accès à l\'utilisation et localisation.';

  @override
  String get searchServiceStatus => 'État du service';

  @override
  String get searchServiceHelp =>
      'Indique si le Kiosk Satellite Service est en cours d\'exécution et ce qu\'il maintient actif.';

  @override
  String get searchServicePermissions =>
      'Les autorisations dont le Kiosk Satellite Service a besoin.';

  @override
  String get searchIntercomKiosks =>
      'Les kiosques connus et si chacun peut recevoir un appel.';

  @override
  String get searchHaValidate =>
      'Vérifiez l\'URL et le jeton auprès de votre Home Assistant.';

  @override
  String get searchHaProxy =>
      'Servir un Home Assistant en http simple via un proxy sécurisé intégré à l\'application.';

  @override
  String get searchHaDashboard =>
      'Choisissez le tableau de bord et la vue que le kiosque affiche.';

  @override
  String get searchKioskPermissions =>
      'Les autorisations dont les protections du kiosque et du verrouillage ont besoin.';

  @override
  String get searchHomeStatus => 'État de l\'écran d\'accueil';

  @override
  String get searchHomeHelp =>
      'Indique si Kiosk Satellite est l\'écran d\'accueil de l\'appareil, et où finaliser sa définition comme écran par défaut.';

  @override
  String get searchMasterVolume =>
      'Le volume de l\'appareil, dont dépendent les curseurs multimédia et assistant.';

  @override
  String get searchSmallClock =>
      'Un widget horloge dans un coin de l\'économiseur d\'écran.';

  @override
  String get searchBattery =>
      'Un widget batterie dans un coin de l\'économiseur d\'écran : la charge de cet appareil.';

  @override
  String get searchPersonPermission =>
      'L\'autorisation d\'accès aux journaux dont le capteur de présence de l\'appareil a besoin.';

  @override
  String get searchSonosSpeakers =>
      'Les enceintes Sonos connues de cet appareil, une recherche sur le réseau et un champ d\'adresse.';

  @override
  String get voiceAppearanceHint =>
      'Habillage de la superposition, thème, barre d\'activité, taille du texte';

  @override
  String get voiceSkin => 'Habillage';

  @override
  String get voiceSkinHelp =>
      'L\'apparence de la superposition de l\'assistant vocal.';

  @override
  String get voiceTheme => 'Mode du thème';

  @override
  String get voiceThemeHelp => 'Rendu clair ou sombre de la superposition.';

  @override
  String get voiceReactive => 'Barre d\'activité réactive';

  @override
  String get voiceReactiveHelp =>
      'La barre d\'activité réagit à l\'audio. NON RECOMMANDÉ pour les appareils peu puissants comme l\'Echo Show.';

  @override
  String get voiceRate => 'Fréquence de mise à jour de la barre réactive';

  @override
  String get voiceRateHelp =>
      'Fréquence de rafraîchissement de la barre d\'activité. Une valeur plus élevée est plus fluide mais utilise davantage le CPU.';

  @override
  String get voiceScaleHelp => 'La taille du texte de la superposition.';

  @override
  String get voiceUpdateIntegration =>
      'Mettez à jour l\'intégration Voice Satellite dans Home Assistant pour contrôler ces paramètres depuis le kiosque.';

  @override
  String get voiceDashboardRequired =>
      'Disponible tant que le kiosque affiche votre tableau de bord Home Assistant.';

  @override
  String get voiceChimesPage => 'Carillons';

  @override
  String get voiceChimesHint =>
      'Sons de réveil, de fin, d\'erreur, de minuteur et d\'annonce';

  @override
  String get voiceChimesPreview => 'Écouter sur le kiosque';

  @override
  String get voiceChimesPreviewFailed => 'Impossible de lire le son.';

  @override
  String get voiceChimesHelp =>
      'Choisissez les sons de ce kiosque. Envoyez ici vos fichiers personnalisés. Les sons enregistrés dans Home Assistant ne sont pas utilisés pour les carillons locaux.';

  @override
  String get voiceChimeWakeTitle => 'Son de réveil';

  @override
  String get voiceChimeWakeDescription =>
      'Joué quand Voice Satellite commence à écouter.';

  @override
  String get voiceChimeDoneTitle => 'Son de fin';

  @override
  String get voiceChimeDoneDescription =>
      'Joué quand une interaction vocale se termine.';

  @override
  String get voiceChimeErrorTitle => 'Son d\'erreur';

  @override
  String get voiceChimeErrorDescription =>
      'Joué quand une interaction vocale échoue.';

  @override
  String get voiceChimeTimerTitle => 'Son du minuteur';

  @override
  String get voiceChimeTimerDescription =>
      'Répété à la fin d\'un minuteur jusqu\'à ce que vous le fermiez.';

  @override
  String get voiceChimeAnnounceTitle => 'Son d\'annonce';

  @override
  String get voiceChimeAnnounceDescription =>
      'Joué avant une annonce de Voice Satellite, sauf si l\'annonce fournit son propre son.';

  @override
  String get voiceEngine => 'Moteur';

  @override
  String get voiceEngineHelp =>
      'Démarrer ou arrêter le moteur Voice Satellite.';

  @override
  String get voiceAssigned => 'Satellite assigné';

  @override
  String get voiceAssignedHelp =>
      'L\'entité assist_satellite sous laquelle ce kiosque s\'identifie dans Home Assistant. La modifier recharge le tableau de bord.';

  @override
  String get voiceAssignedSearch =>
      'L\'entité assist_satellite sous laquelle ce kiosque s\'identifie dans Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Aucun assigné';

  @override
  String get voiceAutoStart => 'Démarrage automatique';

  @override
  String get voiceAutoStartHelp =>
      'Démarrer automatiquement Voice Satellite au chargement du tableau de bord.';

  @override
  String get voiceMuteHelp => 'Arrêter d\'écouter les mots de réveil.';

  @override
  String get voicePipeline1 => 'Pipeline Assist 1';

  @override
  String get voicePipeline1Help =>
      'Le pipeline Assist par lequel passent les commandes vocales.';

  @override
  String get voicePipeline2 => 'Pipeline Assist 2';

  @override
  String get voicePipeline2Help =>
      'Le pipeline utilisé lorsque le second mot de réveil se déclenche.';

  @override
  String get voiceVad => 'Détection de fin de parole';

  @override
  String get voiceVadHelp =>
      'Durée de la pause qui met fin à une commande vocale.';

  @override
  String get voiceMutedWarning =>
      'Désactiver l\'avertissement de microphone coupé';

  @override
  String get voiceMutedWarningHelp =>
      'Masquer l\'avertissement de microphone coupé au démarrage et chaque fois que le microphone du satellite est coupé.';

  @override
  String get voiceDebug => 'Journalisation de débogage';

  @override
  String get voiceDebugHelp =>
      'Afficher les informations de débogage de Voice Satellite dans la console du navigateur.';

  @override
  String get voiceVersion => 'Version de Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'La version de l\'intégration installée dans Home Assistant.';

  @override
  String get voiceVadDefault => 'Par défaut';

  @override
  String get voiceVadRelaxed => 'Tolérante';

  @override
  String get voiceVadAggressive => 'Agressive';

  @override
  String get voiceGeneral => 'Général';

  @override
  String get voiceStart => 'Démarrer';

  @override
  String get voiceNotavailable => 'Non disponible';

  @override
  String get voiceDisabled => 'Désactivé';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Continuer à écouter en arrière-plan';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Continuer à écouter le mot de réveil pendant qu\'une autre application est au premier plan, et revenir au premier plan dès qu\'il est détecté. Nécessite une notification permanente et l\'affichage par-dessus d\'autres applications.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Revenir à l\'application précédente';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Revenir à l\'application précédente ou à l\'écran d\'accueil une fois qu\'une interaction vocale a ramené Kiosk Satellite au premier plan puis s\'est terminée.';

  @override
  String get voiceMicHeld =>
      'La détection du mot de réveil peut vous entendre.';

  @override
  String get voiceMicBlocked =>
      'Bloqué. Android ne redemandera pas l\'autorisation : autorisez le microphone dans les paramètres de l\'application.';

  @override
  String get voiceMicMissing => 'Sans cela, rien n\'écoute le mot de réveil.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite peut revenir au premier plan quand il vous entend.';

  @override
  String get voiceForegroundMissing =>
      'Sans cela, le mot de réveil est entendu et rien ne se passe.';

  @override
  String get voiceNotificationHeld =>
      'La notification permanente qui active l\'écoute en arrière-plan.';

  @override
  String get voiceNotificationMissing =>
      'Nécessaire pour que l\'écoute en arrière-plan fonctionne de manière fiable.';

  @override
  String get voiceBatteryHeld =>
      'Android laissera l\'écouteur en fonctionnement.';

  @override
  String get voiceBatteryMissing =>
      'Sans cela, l\'écouteur est arrêté après quelques heures.';

  @override
  String get voicePermissionDirections =>
      'Accordez ceci directement sur l\'appareil : balayez depuis le bord gauche → Paramètres → Voice Satellite → Autorisations système requises.';

  @override
  String get voicePermissionsSearch =>
      'Le microphone et les autres autorisations dont la détection du mot de réveil a besoin.';

  @override
  String get voiceDisconnected => 'Home Assistant non connecté';

  @override
  String get voiceValidate =>
      'Validez d\'abord la connexion dans Configuration Home Assistant.';

  @override
  String get voiceChecking => 'Recherche de Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite n\'est pas installé dans Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite transforme ce kiosque en un assistant vocal mains libres complet pour Home Assistant : détection du mot de réveil, conversations, minuteurs et annonces, directement sur le tableau de bord.\n\nIl est disponible dans le dépôt HACS par défaut. Installez-le sur votre instance Home Assistant, puis revenez ici.';

  @override
  String get voiceLearnMore => 'En savoir plus sur ';

  @override
  String get voiceGithub => 'Voice Satellite sur Github';

  @override
  String get voiceHacs => 'Ouvrir le dépôt HACS';

  @override
  String get voiceLoading => 'Chargement des contrôles Voice Satellite…';

  @override
  String get voiceTester => 'Testeur de mot de réveil';

  @override
  String get voiceTesterHelp =>
      'Observez en temps réel ce que le moteur entend et évalue, pour comprendre pourquoi le mot de réveil se déclenche ou non.';

  @override
  String get voiceTesterSearch =>
      'Un aperçu en direct de ce que le moteur entend et évalue.';

  @override
  String get voiceTesterWaiting => 'En attente de Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (mot d\'arrêt)';
  }

  @override
  String get voiceScore => 'Score';

  @override
  String get voiceThreshold => 'Seuil';

  @override
  String get voiceHits => 'Détections';

  @override
  String get voiceNearMisses => 'Presque déclenchés';

  @override
  String get voicePeak => 'Pic';

  @override
  String get voiceMicLevel => 'Niveau du micro';

  @override
  String get voiceChunkProcessing => 'Traitement des blocs (min / moy / max)';

  @override
  String get voiceLog => 'Journal';

  @override
  String get voiceLogEmpty =>
      'Les détections et les presque déclenchés apparaîtront ici.';

  @override
  String get voiceLogHit => 'DÉTECTÉ';

  @override
  String get voiceLogNear => 'proche';

  @override
  String get voiceLogScore => 'score';

  @override
  String get voiceLogDecoded => 'décodé';

  @override
  String get voiceLogDistance => 'dist';

  @override
  String get voiceLogConfidence => 'conf';

  @override
  String get voiceTesterPlayRecent => 'Écouter les 10 dernières secondes';

  @override
  String get voiceWakePage => 'Mot de réveil';

  @override
  String get voiceWakeHint =>
      'Moteur, mots de réveil, sensibilité, modèles en cache';

  @override
  String get voiceWakeLabel => 'Mot de réveil';

  @override
  String get voiceWakeEngine => 'Moteur de mot de réveil';

  @override
  String get voiceWakeEngineHelp =>
      'Où la détection s\'exécute et quel moteur écoute.';

  @override
  String get voiceWake1 => 'Mot de réveil 1';

  @override
  String get voiceWake1Help => 'Le mot qui démarre une commande vocale.';

  @override
  String get voiceWake2 => 'Mot de réveil 2';

  @override
  String get voiceWake2Help =>
      'Un second mot de réveil, pris en charge par le pipeline Assist 2.';

  @override
  String get voiceSensitivity => 'Sensibilité du mot de réveil';

  @override
  String get voiceSensitivityHelp =>
      'Avec quelle facilité le mot de réveil se déclenche.';

  @override
  String get voiceNoiseGate => 'Porte de bruit du mot de réveil';

  @override
  String get voiceNoiseGateHelp =>
      'Ignorer l\'inférence locale du mot de réveil tant que la pièce est silencieuse, ce qui économise le CPU.';

  @override
  String get voiceStopInterruption => 'Interruption par mot d\'arrêt';

  @override
  String get voiceStopInterruptionHelp =>
      'Prononcez le mot d\'arrêt pour interrompre les réponses.';

  @override
  String get voiceAssignFirst =>
      'Assignez un satellite pour contrôler ces paramètres.';

  @override
  String get voiceCachedModels => 'Modèles en cache';

  @override
  String get voiceCachedModelsHelp =>
      'Retélécharger depuis Home Assistant. À utiliser après avoir republié un modèle.';

  @override
  String get voiceClearCache => 'Vider le cache';

  @override
  String get voiceClearing => 'Suppression…';

  @override
  String voiceCacheCleared(String count) {
    return 'Fichiers supprimés : $count. Nouveau téléchargement en cours.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Supprimés : $count';
  }

  @override
  String get voiceVerySensitive => 'Très sensible';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'Préférer les modèles vsWakeWord fp32';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Utilise les modèles fp32 au lieu des versions int8 plus légères. Augmente l\'utilisation du CPU de 10 à 30 % pendant l\'écoute, pour éviter environ 2 % de dérive de confiance.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Délai de reprise (secondes)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Auto-réparation : reprend l\'écoute si la page n\'appelle jamais setWakeWordActive(true) après un transfert. Attend tant qu\'un échange vocal diffuse encore de l\'audio, pour ne jamais couper un long échange.';

  @override
  String get voiceSlightlySensitive => 'Légèrement sensible';

  @override
  String get voiceModeratelySensitive => 'Modérément sensible';

  @override
  String get voiceOnDevice => 'Sur l\'appareil';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'Sur l\'appareil ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Diagnostic du mot de réveil';

  @override
  String get voiceDiagnosticsHint =>
      'Déclenchements récents et presque déclenchés avec extraits audio';

  @override
  String get voiceDiagnosticsTitle => 'Activer le diagnostic du mot de réveil';

  @override
  String get voiceDiagnosticsDescription =>
      'Enregistre les 10 derniers déclenchements et presque déclenchés du mot de réveil avec leurs scores et un extrait audio de 3 secondes pour chacun. Désactiver cette option les supprime.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Aucun déclenchement du mot de réveil enregistré pour l\'instant.';

  @override
  String get voiceDiagnosticsActivations => 'Déclenchements';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Aucun presque déclenché enregistré pour l\'instant.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Niveau de crête';

  @override
  String get voiceDiagnosticsAverageLevel => 'Niveau moyen';

  @override
  String get voiceDiagnosticsClipped => 'Saturé';

  @override
  String get voiceDiagnosticsHeard => 'Entendu';

  @override
  String get settingDisableCacheTitle => 'Désactiver le cache';

  @override
  String get settingDisableCacheDescription =>
      'Toujours récupérer depuis le réseau et abandonner les données de page en cache au chargement, afin qu\'un tableau de bord redéployé soit toujours à jour. Lent ; à considérer comme un outil de développement.';

  @override
  String get settingAllowMixedContentTitle => 'Autoriser le contenu mixte';

  @override
  String get settingAllowMixedContentDescription =>
      'Laisser les pages HTTPS charger des ressources HTTP non sécurisées. Utile quand un tableau de bord https:// affiché par Home Assistant contient du contenu http:// non sécurisé.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ignorer les erreurs SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Accepter les certificats non fiables ou auto-signés. À n\'utiliser que sur votre propre réseau, car cela désactive la vérification des certificats.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Rechargement automatique en cas d\'erreur';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Se rétablir automatiquement après les échecs de page et les plantages de l\'application.';

  @override
  String get settingPullToRefreshTitle =>
      'Activer l\'actualisation par glissement';

  @override
  String get settingPullToRefreshDescription =>
      'Tirez vers le bas depuis le haut de la page pour la recharger. Désactivé par défaut : sur un tableau de bord qui défile, il est facile de déclencher l\'actualisation par erreur.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Vider le cache lors de l\'actualisation par glissement';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Ce geste vide aussi le cache web et les modèles de mot de réveil avant le rechargement, pour que tout revienne à jour. La connexion et les données de page enregistrées sont conservées.';

  @override
  String get settingBrowserZoomTitle => 'Niveau de zoom';

  @override
  String get settingBrowserZoomDescription =>
      'Met à l\'échelle la page entière. Au-dessus de 1x pour les tablettes murales vues de loin ; en dessous de 1x pour faire tenir plus de tableau de bord sur un petit écran.';

  @override
  String get settingPinchToZoomTitle => 'Activer le zoom par pincement';

  @override
  String get settingPinchToZoomDescription =>
      'Zoomer la page avec un pincement à deux doigts. Désactivé par défaut afin qu\'un tableau de bord de kiosque reste stable malgré les touches accidentelles.';

  @override
  String get settingDisableScrollingTitle => 'Désactiver le défilement';

  @override
  String get settingDisableScrollingDescription =>
      'Verrouiller la page en place pour qu\'elle ne puisse défiler dans aucune direction. Les appuis et boutons continuent de fonctionner.';

  @override
  String get browserCrashPermissionHelp =>
      'Sans cela, le kiosque ne peut pas revenir après un plantage.';

  @override
  String get browserCrashPermissionMissing =>
      'Autorisation « Affichage par-dessus d\'autres applications » manquante';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Sans elle, le kiosque ne peut pas revenir de lui-même après un plantage. L\'écran d\'autorisation apparaît sur la tablette.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Injecter du JavaScript sur le tableau de bord HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Exécuter ce code JavaScript après chaque chargement de la page du tableau de bord. Utile pour masquer des éléments gênants ou ajuster un tableau de bord que vous ne contrôlez pas.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Injecter du JavaScript sur les pages externes';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Exécuter ce code JavaScript après le chargement de chaque page externe : pages ouvertes par un lien du tableau de bord, pages de rotation du tableau de bord et économiseur d\'écran de site web. La page Music Assistant n\'est pas concernée.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Exemple : masquer un élément gênant\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Exemple : zoomer un site qui ignore le niveau de zoom du tableau de bord\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get setupConnectHeading => 'Connexion à Home Assistant';

  @override
  String get setupConnectLead =>
      'L\'URL de base de votre instance et un jeton d\'accès de longue durée, créé dans votre profil HA → Sécurité → Jetons d\'accès de longue durée.';

  @override
  String get setupBaseUrl => 'URL de base de Home Assistant';

  @override
  String get setupToken => 'Jeton d\'accès de longue durée';

  @override
  String get setupScanQr => 'Scanner le code QR';

  @override
  String get setupInvalidToken => 'Jeton d\'accès invalide';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant a rejeté ce jeton. Dans Home Assistant, ouvrez votre profil → Sécurité → Jetons d\'accès de longue durée, créez un nouveau jeton et copiez sa valeur complète.';

  @override
  String get setupUnreachable => 'Impossible de joindre Home Assistant';

  @override
  String get setupUnreachableHelp =>
      'Aucune réponse de cette adresse. Vérifiez que l\'URL est correcte et que cet appareil se trouve sur le même réseau que votre serveur Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Un serveur a répondu, mais il ne semble pas s\'agir de Home Assistant. Vérifiez que l\'URL correspond à l\'adresse de base de votre Home Assistant, par exemple https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'Connexion impossible';

  @override
  String get setupCameraPermission => 'Autorisation de la caméra requise';

  @override
  String get setupCameraBlocked =>
      'Autorisez la caméra pour Kiosk Satellite dans les paramètres Android pour scanner le code QR.';

  @override
  String get setupCameraAllow => 'Autorisez la caméra pour scanner le code QR.';

  @override
  String get setupEnterBaseUrl =>
      'Saisissez l\'URL de base de votre Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'URL de base invalide';

  @override
  String get setupBaseUrlHelp =>
      'C\'est l\'adresse que vous utilisez pour ouvrir Home Assistant, par exemple https://homeassistant.local:8123.';

  @override
  String get setupEnterToken => 'Saisissez un jeton d\'accès de longue durée';

  @override
  String get setupEnterTokenHelp =>
      'Dans Home Assistant, ouvrez votre profil → Sécurité → Jetons d\'accès de longue durée pour en créer un.';

  @override
  String get setupValidateContinue => 'Valider et continuer';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Réponse inattendue ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Saisissez une URL valide, par exemple https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Saisissez uniquement l\'URL de base, sans chemin de tableau de bord. Exemple : https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Saisissez uniquement l\'URL de base, sans rien après le port. Exemple : https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Choisir un tableau de bord';

  @override
  String get setupDashboardHelp =>
      'C\'est ce que le kiosque affichera à son démarrage.';

  @override
  String get setupSelectDashboard => 'Sélectionner un tableau de bord';

  @override
  String get setupSelectDashboardHelp =>
      'Choisissez le tableau de bord que le kiosque affichera. Vous pourrez le modifier plus tard dans Paramètres.';

  @override
  String get setupWelcome => 'Bienvenue';

  @override
  String get setupConnect => 'Connexion';

  @override
  String get setupConnectSummary => 'URL et jeton Home Assistant';

  @override
  String get setupDashboard => 'Tableau de bord';

  @override
  String get setupDashboardSummary => 'Ce que le kiosque affiche';

  @override
  String get setupRecommendedSummary => 'Paramètres recommandés';

  @override
  String get setupPermissions => 'Autorisations';

  @override
  String get setupPermissionsSummary => 'Ce dont la configuration a besoin';

  @override
  String get setupPermissionLead =>
      'Android va demander ces autorisations. Tout est demandé à l\'avance pour que le kiosque ne vous interrompe jamais par la suite.';

  @override
  String get setupRemotePermissionLead =>
      'Android les demande directement sur la tablette. Rendez-vous près de l\'appareil pour accepter les demandes, puis terminez ici.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite et l\'interphone ont besoin d\'accéder au microphone';

  @override
  String get setupNotificationListening =>
      'Autorise la notification permanente du Kiosk Satellite Service, qui indique ce que le service maintient actif et quand le kiosque écoute.';

  @override
  String get setupBatteryService =>
      'Autorise le Kiosk Satellite Service à s\'exécuter en arrière-plan sans être mis en pause ou arrêté.';

  @override
  String get setupOverlayBoot =>
      'Permet à Kiosk Satellite de revenir après un plantage et de se lancer au démarrage de votre appareil.';

  @override
  String get setupOverlayCrash =>
      'Permet à Kiosk Satellite de revenir à l\'écran après un plantage.';

  @override
  String get setupBrightnessHelp =>
      'Autorise Kiosk Satellite à définir la luminosité réelle de l\'écran (modifier les paramètres système).';

  @override
  String get setupScreenControl => 'Contrôle de l\'écran';

  @override
  String get setupScreenControlHelp =>
      'Autorise Kiosk Satellite à éteindre l\'écran sur demande (administrateur de l\'appareil).';

  @override
  String get setupGrantPermissions =>
      'Accorder les autorisations sur l\'appareil';

  @override
  String get setupRequestingPermissions => 'Demande en cours sur l\'appareil…';

  @override
  String get setupPermissionsRequested =>
      'Autorisations demandées sur l\'appareil';

  @override
  String get setupQrFlipCamera => 'Changer de caméra';

  @override
  String get setupQrCameraFailed => 'Impossible de démarrer la caméra.';

  @override
  String get setupQrTitle => 'Scanner le code QR du jeton';

  @override
  String get setupQrHelp =>
      'Il apparaît à côté d\'un jeton nouvellement créé dans votre profil Home Assistant.';

  @override
  String get setupQrFlashOff => 'Éteindre la lampe torche';

  @override
  String get setupQrFlashOn => 'Allumer la lampe torche';

  @override
  String get setupPasswordFirst =>
      'Définissez d\'abord le mot de passe d\'administration';

  @override
  String get setupPasswordBeforeImport =>
      'Saisissez un mot de passe d\'administration ci-dessus (4 caractères minimum), puis importez la sauvegarde.';

  @override
  String get setupPasswordFailed => 'Impossible de définir le mot de passe';

  @override
  String get setupPasswordExists => 'Un mot de passe est déjà défini';

  @override
  String get setupPasswordExistsHelp =>
      'Connectez-vous avec le mot de passe défini sur la tablette pour continuer ici. Rechargement…';

  @override
  String get setupNotBackup => 'Ce n\'est pas un fichier de sauvegarde';

  @override
  String get setupInvalidBackupHelp =>
      'Ce fichier n\'est pas un JSON valide. Exportez une configuration depuis les Paramètres d\'un Kiosk Satellite déjà configuré, ou depuis son administration à distance.';

  @override
  String get setupWrongBackupKind =>
      'Exportez une configuration depuis l\'onglet Paramètres d\'un Kiosk Satellite déjà configuré.';

  @override
  String get setupImportFailedHelp => 'Le fichier n\'a pas pu être appliqué.';

  @override
  String get setupBackupNoDashboard =>
      'La sauvegarde ne contient pas de tableau de bord';

  @override
  String get setupBackupNoDashboardHelp =>
      'Les paramètres ont été appliqués, mais cette sauvegarde a été faite avant la configuration de son appareil : il n\'y a donc aucun tableau de bord à afficher. Poursuivez l\'assistant pour en choisir un.';

  @override
  String get setupImporting => 'Importation…';

  @override
  String get setupRemoteRestoreHelp =>
      'Importez une configuration exportée depuis Kiosk Satellite et passez le reste de cet assistant.';

  @override
  String get setupFinishOnDevice => 'Terminer sur l\'appareil';

  @override
  String get setupFinishOnDeviceHelp =>
      'La configuration a été importée. Répondez aux demandes d\'autorisation sur l\'écran de la tablette ; cette page continue automatiquement lorsque le tableau de bord se charge.';

  @override
  String get setupBackupObject => 'La sauvegarde doit contenir un objet JSON.';

  @override
  String get setupBackupKind =>
      'Ce n\'est pas un fichier de configuration Kiosk Satellite.';

  @override
  String get setupBackupSettings =>
      'La sauvegarde ne contient aucun paramètre.';

  @override
  String get setupServiceHelp =>
      'Maintient l\'application active lorsque l\'écran est éteint ou qu\'une autre application est au premier plan, afin que la connexion Home Assistant et d\'autres fonctionnalités comme la détection de mouvement et le proxy Bluetooth restent actives. Les autorisations ci-dessous sont facultatives mais recommandées : chacune l\'aide à survivre à l\'extinction de l\'écran.';

  @override
  String get setupBatteryMissing =>
      'Android peut mettre l\'application en pause lorsque l\'écran est éteint, ce qui coupe du même coup la connexion Home Assistant.';

  @override
  String get setupOverlayMissing =>
      'Sans cela, le service ne peut pas relancer le kiosque après un plantage.';

  @override
  String get setupVoiceDetected => 'Voice Satellite détecté';

  @override
  String get setupVoiceHelp =>
      'Cette instance Home Assistant exécute l\'intégration Voice Satellite. Choisissez le satellite que représente ce kiosque, puis vérifiez ses paramètres. Tout peut être modifié plus tard.';

  @override
  String get setupNoSatellites => 'Aucun satellite trouvé';

  @override
  String get setupNoSatellitesHelp =>
      'Ajoutez un satellite d\'assistance dans l\'intégration Voice Satellite, ou continuez sans satellite et choisissez-en un plus tard sur le tableau de bord.';

  @override
  String get setupNewSatelliteHelp =>
      'S\'il s\'agit d\'un nouvel appareil, créez d\'abord une nouvelle entité satellite dans Home Assistant. Paramètres → Appareils et services → Voice Satellite → Ajouter une entrée. IMPORTANT : deux appareils ne peuvent pas partager la même entité.';

  @override
  String get setupApplyRecommended =>
      'Appliquer tous les paramètres recommandés';

  @override
  String get setupRecommendedHelp =>
      'Les paramètres optimaux pour une intégration et un fonctionnement complets de Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Requis par Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Accès au microphone';

  @override
  String get setupNativeWakeWord => 'Détection native du mot de réveil';

  @override
  String get setupPullRefresh => 'Actualisation par glissement';

  @override
  String get setupAutoplay => 'Lecture automatique de l\'audio et de la vidéo';

  @override
  String get setupVoiceSkipped => 'Non installé, ignoré';

  @override
  String get setupRemoteHeading => 'Administration à distance';

  @override
  String get setupTitle => 'Configurer\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Transformez cette tablette en kiosque Home Assistant. La configuration prend quelques minutes et cet assistant vous guide à chaque étape.';

  @override
  String get setupDeviceName => 'Nom de l\'appareil';

  @override
  String get setupDeviceNameHelp =>
      'Le nom de ce kiosque dans Home Assistant, dans l\'administration à distance et sur le réseau. Modifiable à tout moment dans Paramètres, Appareil.';

  @override
  String get setupEnableRemote => 'Activer l\'administration à distance';

  @override
  String get setupEnableRemoteHelp =>
      'Continuez à gérer ce kiosque depuis un navigateur web après la configuration, où coller le jeton d\'accès Home Assistant est bien plus simple.';

  @override
  String get setupRemotePassword => 'Mot de passe d\'administration à distance';

  @override
  String get setupRestoreHeading => 'Restaurer une sauvegarde';

  @override
  String get setupRestore => 'Restaurer depuis un fichier de configuration';

  @override
  String get setupRestoreHelp =>
      'Importez une configuration exportée depuis Kiosk Satellite et passez le reste de cet assistant. Les paramètres, le tableau de bord et la connexion sont inclus.';

  @override
  String get setupServicePermissions => 'Autorisations de service recommandées';

  @override
  String get setupPasswordShort => 'Mot de passe trop court';

  @override
  String get setupPasswordMinimum => 'Utilisez au moins 4 caractères.';

  @override
  String setupRemoteAddress(String address) {
    return 'Vous pouvez poursuivre cette configuration à distance depuis un navigateur web à l\'adresse $address, que l\'interrupteur ci-dessus soit activé ou non.';
  }

  @override
  String get remoteWelcomeTitle => 'Bienvenue dans Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Cette tablette attend d\'être configurée. Protégez d\'abord cette administration à distance avec un mot de passe.';

  @override
  String get remoteWelcomeReady =>
      'Cette tablette attend d\'être configurée. Le mot de passe d\'administration à distance est déjà défini ; saisissez-en un nouveau ici pour le modifier.';

  @override
  String get remoteInitialPassword =>
      'Mot de passe d\'administration (4 caractères min.)';

  @override
  String get remoteNewPassword =>
      'Nouveau mot de passe d\'administration (laisser vide pour conserver l\'actuel)';

  @override
  String get intercomBuiltinRing => 'Sonnerie intégrée';

  @override
  String get intercomBuiltinChime => 'Carillon intégré';

  @override
  String intercomMissingFile(String file) {
    return '$file (manquant)';
  }

  @override
  String get intercomAddSound => 'Ajouter un son';

  @override
  String get intercomCopySoundHelp =>
      'Copier un fichier audio depuis cet appareil vers le dossier des sons.';

  @override
  String get intercomUploadSoundHelp =>
      'Envoyer un fichier audio depuis cet ordinateur vers le dossier des sons.';

  @override
  String get intercomUpload => 'Envoyer';

  @override
  String get intercomUploading => 'Envoi…';

  @override
  String get intercomUnsupportedSound => 'Son non pris en charge';

  @override
  String get intercomChooseSound =>
      'Son non pris en charge : choisissez un fichier MP3, OGG, WAV, FLAC, M4A ou AAC.';

  @override
  String get intercomCopyFailed => 'Impossible de copier le fichier';

  @override
  String intercomUploadFailed(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'Non enregistré : $error';
  }

  @override
  String get intercomSoundFilename =>
      'Saisissez un nom de fichier, pas un chemin.';

  @override
  String get intercomSoundFormats =>
      'Choisissez un fichier MP3, OGG, WAV, FLAC, M4A ou AAC.';

  @override
  String get voiceTimerDefaultName => 'Minuteur';

  @override
  String get voiceTimerDrag => 'Faites glisser pour déplacer les minuteurs';

  @override
  String get voiceTimerPauseHint =>
      'Appuyez pour mettre en pause. Appuyez deux fois pour annuler. Faites glisser pour déplacer.';

  @override
  String get voiceTimerResumeHint =>
      'Appuyez pour reprendre. Appuyez deux fois pour annuler. Faites glisser pour déplacer.';

  @override
  String get voiceTimerCancel => 'Annuler le minuteur';

  @override
  String get voiceTimerActionError =>
      'Impossible de modifier le minuteur. Vérifiez la connexion et mettez à jour Voice Satellite si nécessaire.';

  @override
  String get voiceTimerFinished => 'Minuteur terminé';

  @override
  String get voiceTimerDismissHint =>
      'Appuyez pour fermer l\'alerte du minuteur.';
}
