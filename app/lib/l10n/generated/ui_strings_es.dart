// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ui_strings.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class UiStringsEs extends UiStrings {
  UiStringsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutApp => 'Aplicación';

  @override
  String get aboutVersion => 'Versión de la aplicación';

  @override
  String get aboutBuild => 'Compilación';

  @override
  String get aboutPackage => 'Paquete';

  @override
  String get aboutAttribution => 'Créditos';

  @override
  String get aboutAuthor => 'Autor';

  @override
  String get aboutWebsite => 'Sitio web';

  @override
  String get aboutSourceCode => 'Código fuente';

  @override
  String get aboutLicense => 'Licencia';

  @override
  String get aboutLicenseSummary =>
      'Kiosk Satellite es gratuito para uso personal y no comercial. Se distribuye bajo la licencia CC BY-NC-ND 4.0: puedes usarlo y compartirlo, pero no se permite el uso comercial de la aplicación ni la redistribución de versiones modificadas. Los plugins independientes tienen permisos adicionales según PLUGIN-EXCEPTION.md.';

  @override
  String get aboutLocalizationCredits => 'Créditos de traducción';

  @override
  String get aboutLocalizationCreditsHint => 'Colaboradores por idioma';

  @override
  String get aboutCheckNow => 'Buscar actualizaciones ahora';

  @override
  String get aboutChecking => 'Buscando…';

  @override
  String get aboutCheckFailed =>
      'No se pudieron buscar actualizaciones. ¿Puede el dispositivo conectarse con GitHub?';

  @override
  String get aboutOverlayMissing =>
      'Falta el permiso «Mostrar sobre otras aplicaciones»';

  @override
  String get aboutOverlayHelp =>
      'Sin este permiso, la aplicación no puede volver a abrirse después de actualizarse. La pantalla para concederlo aparece en la tablet.';

  @override
  String aboutDownloadProgress(String percent) {
    return 'Descargando… $percent%';
  }

  @override
  String aboutDownloadFailed(String error) {
    return 'La actualización falló: $error';
  }

  @override
  String get aboutAlreadyCurrent => 'Ya está actualizado';

  @override
  String get aboutInstallHelp =>
      'La descarga se realiza en la tablet. Debes confirmar la instalación en su pantalla.';

  @override
  String get androidAccessibilityHelp =>
      'Cierra el panel de notificaciones y la pantalla de aplicaciones recientes cuando se abren mientras el modo kiosko o el modo de bloqueo protege la pantalla. Kiosk Satellite no lee el contenido de la pantalla.';

  @override
  String get androidServiceChannelHelp =>
      'Se muestra mientras el servicio de Kiosk Satellite mantiene la aplicación activa con la pantalla apagada o detrás de otra aplicación.';

  @override
  String get androidServiceListening => 'escuchando una palabra de activación';

  @override
  String get androidServiceRtspAudio => 'audio del micrófono RTSP activado';

  @override
  String get androidServiceEsphome => 'atendiendo conexiones de ESPHome';

  @override
  String get androidServiceBluetooth =>
      'transmitiendo datos de dispositivos Bluetooth';

  @override
  String get androidServiceCamera => 'supervisando la cámara';

  @override
  String get androidServiceLocation => 'informando la ubicación';

  @override
  String get androidServiceRemote => 'atendiendo la administración remota';

  @override
  String get androidServiceKiosk => 'protegiendo el modo kiosko';

  @override
  String get androidServiceSessions =>
      'manteniendo la conexión con Home Assistant';

  @override
  String get launcherErrorAndroidOnly =>
      'La lista de aplicaciones solo está disponible en Android';

  @override
  String launcherErrorListDetail(String error) {
    return 'No se pudo obtener la lista de aplicaciones: $error';
  }

  @override
  String launcherOpenFailed(String name) {
    return 'No se pudo abrir $name';
  }

  @override
  String get launcherUninstalled => 'Es posible que se haya desinstalado.';

  @override
  String get launcherNoneHelp =>
      'Aún no hay ninguna. Elige las aplicaciones que ofrecerá el lanzador.';

  @override
  String get launcherNone => 'Aún no hay ninguna';

  @override
  String get launcherListFailed => 'No se pudieron obtener las aplicaciones';

  @override
  String launcherListError(String error) {
    return 'No se pudieron obtener las aplicaciones: $error';
  }

  @override
  String get launcherListingFailed => 'no se pudo obtener la lista';

  @override
  String get launcherEmpty =>
      'No se encontraron aplicaciones que se puedan abrir.';

  @override
  String get cameraViewerTitle => 'Vista de cámaras';

  @override
  String get cameraViewerConnecting => 'Conectando...';

  @override
  String get cameraViewerReconnecting => 'Reconectando...';

  @override
  String cameraViewerTrying(String transport) {
    return 'Probando $transport...';
  }

  @override
  String cameraViewerCannotDecode(String codec) {
    return 'Este dispositivo no puede decodificar $codec';
  }

  @override
  String cameraViewerCannotPlay(String transport) {
    return 'Este dispositivo no puede reproducir transmisiones $transport';
  }

  @override
  String get cameraViewerCannotDecodeStream =>
      'Este dispositivo no puede decodificar esta transmisión';

  @override
  String cameraViewerHaRetry(String seconds) {
    return 'No se puede conectar a Home Assistant. Se reintentará en $seconds s';
  }

  @override
  String cameraViewerServerRetry(String seconds) {
    return 'No se puede conectar al servidor de cámaras. Se reintentará en $seconds s';
  }

  @override
  String cameraViewerConnectionRetry(String seconds) {
    return 'La conexión falló. Se reintentará en $seconds s';
  }

  @override
  String get cameraViewerStartRetry =>
      'El servidor de cámaras no pudo iniciar esta transmisión. Reintentando...';

  @override
  String cameraViewerStartDelayedRetry(String seconds) {
    return 'El servidor de cámaras no pudo iniciar esta transmisión. Se reintentará en $seconds s';
  }

  @override
  String cameraViewerMissingRetry(String seconds) {
    return 'No se encontró la transmisión en el servidor de cámaras. Se reintentará en $seconds s';
  }

  @override
  String cameraViewerLoginRetry(String seconds) {
    return 'El servidor de cámaras rechazó el inicio de sesión. Se reintentará en $seconds s';
  }

  @override
  String get cameraViewerMissing => 'Transmisión no disponible en Go2RTC';

  @override
  String get commonImport => 'Importar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonFinish => 'Finalizar';

  @override
  String get commonWorking => 'Procesando…';

  @override
  String get commonSettings => 'Configuración';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonGrant => 'Conceder';

  @override
  String get commonEnable => 'Activar';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonTest => 'Probar';

  @override
  String get commonInstall => 'Instalar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonRemove => 'Eliminar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonBrowse => 'Examinar';

  @override
  String get commonSet => 'Establecer';

  @override
  String get commonHour => 'Hora';

  @override
  String get commonMinute => 'Minuto';

  @override
  String get commonUp => 'Aumentar';

  @override
  String get commonDown => 'Disminuir';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSaveFailed => 'No se pudo guardar';

  @override
  String get commonColorWhite => 'Blanco';

  @override
  String get commonColorWarm => 'Cálido';

  @override
  String get commonColorAmber => 'Ámbar';

  @override
  String get commonColorRed => 'Rojo';

  @override
  String get commonColorGreen => 'Verde';

  @override
  String get commonColorBlue => 'Azul';

  @override
  String get commonColorCyan => 'Cian';

  @override
  String get commonColorDim => 'Gris oscuro';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonMoveUp => 'Subir';

  @override
  String get commonMoveDown => 'Bajar';

  @override
  String get commonPreviousMonth => 'Mes anterior';

  @override
  String get commonNextMonth => 'Mes siguiente';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonChoose => 'Elegir';

  @override
  String get dlnaPortInvalid =>
      'Introduce un puerto entre 1024 y 65535 o déjalo vacío';

  @override
  String get commonSelectAll => 'Seleccionar todo';

  @override
  String get dlnaCannotDecode =>
      'Este dispositivo no puede decodificar este video.';

  @override
  String get dlnaCannotRead => 'No se pudo leer este archivo.';

  @override
  String get dlnaCannotPlay => 'No se pudo reproducir este contenido.';

  @override
  String get dlnaSeeLogs =>
      'Consulta los registros de la aplicación para ver los detalles';

  @override
  String get dlnaLoading => 'Cargando contenido';

  @override
  String get dlnaImageFailed => 'No se pudo mostrar esta imagen.';

  @override
  String get dlnaStop => 'Detener reproducción';

  @override
  String drawerPluginAction(String pluginName, String actionTitle) {
    return '$pluginName: $actionTitle';
  }

  @override
  String get drawerPluginActionErrorTitle => 'Acción del plugin';

  @override
  String get drawerPluginActionError => 'No se pudo ejecutar esta acción.';

  @override
  String get drawerDashboard => 'Panel de control';

  @override
  String get drawerHaKiosk => 'Modo kiosko de HA';

  @override
  String get drawerCameraView => 'Vista de cámaras';

  @override
  String get drawerIntercom => 'Intercomunicador';

  @override
  String get drawerMusicAssistant => 'Music Assistant';

  @override
  String get drawerHidePlayer => 'Ocultar reproductor flotante';

  @override
  String get drawerShowPlayer => 'Mostrar reproductor flotante';

  @override
  String get drawerNowPlaying => 'Reproduciendo Ahora';

  @override
  String get drawerScreensaver => 'Iniciar protector de pantalla';

  @override
  String get drawerLockdown => 'Modo de bloqueo';

  @override
  String get drawerHoldOff => 'Desactivar modo de pausa';

  @override
  String get drawerHoldOn => 'Activar modo de pausa';

  @override
  String get drawerApps => 'Aplicaciones';

  @override
  String get drawerClearCache => 'Borrar caché web';

  @override
  String get drawerRestartDevice => 'Reiniciar dispositivo';

  @override
  String get drawerRestartConfirm =>
      '¿Reiniciar este dispositivo? Kiosk Satellite volverá a abrirse cuando se inicie.';

  @override
  String get drawerRestart => 'Reiniciar';

  @override
  String get drawerExitApplication => 'Salir de la aplicación';

  @override
  String get drawerExitConfirm => '¿Cerrar Kiosk Satellite?';

  @override
  String get drawerExit => 'Salir';

  @override
  String get drawerHoldActive => 'El modo de pausa está activado';

  @override
  String get drawerHoldHelp =>
      'El protector de pantalla y los temporizadores están en pausa · toca para desactivar';

  @override
  String get drawerThemeDark => 'Oscuro';

  @override
  String get drawerThemeLight => 'Claro';

  @override
  String get drawerThemeAndroid => 'Seguir Android';

  @override
  String drawerVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get drawerUpdateAvailable => 'Actualización disponible';

  @override
  String drawerUpdateInstall(String version) {
    return 'Versión $version · toca para instalar';
  }

  @override
  String get drawerUpdateChecking => 'Buscando actualizaciones…';

  @override
  String get drawerUpdateCurrent => 'Actualizado';

  @override
  String get drawerUpdateCurrentHelp => 'Tienes la versión más reciente.';

  @override
  String get drawerUpdateCheckFailed => 'No se pudieron buscar actualizaciones';

  @override
  String get drawerUpdateOffline =>
      '¿El dispositivo tiene conexión a internet?';

  @override
  String drawerUpdateTo(String version) {
    return 'Actualizar a $version';
  }

  @override
  String get drawerUpdateInstructions =>
      'La descarga comienza al tocar Actualizar. Android te pedirá que confirmes la instalación.';

  @override
  String get drawerUpdateRelaunch =>
      'Sin el permiso \"Mostrar sobre otras aplicaciones\", la aplicación no puede volver a abrirse después de actualizarse.';

  @override
  String get drawerUpdate => 'Actualizar';

  @override
  String get drawerUpdateDownloading => 'Descargando actualización';

  @override
  String get drawerUpdateStarting => 'Iniciando…';

  @override
  String get drawerUpdateFailed => 'No se pudo actualizar';

  @override
  String get drawerUpdates => 'Actualizaciones';

  @override
  String get drawerNoReleaseNotes => 'No hay notas de la versión.';

  @override
  String get esphomeAllExposed => 'Se exponen todas las entidades disponibles';

  @override
  String esphomeExcludedCount(String count) {
    return '$count excluidas';
  }

  @override
  String get esphomeEntitySearch => 'Buscar entidades';

  @override
  String get esphomeEntityLoading => 'Cargando entidades…';

  @override
  String get esphomeEntityUnavailable => 'No disponible actualmente';

  @override
  String get esphomeEntityNoMatch => 'No hay entidades que coincidan';

  @override
  String get esphomeEntityLoadFailed =>
      'No se pudieron cargar las entidades. Cierra el selector e inténtalo de nuevo.';

  @override
  String get esphomeEntitySaveFailed =>
      'No se pudieron guardar las exclusiones. Inténtalo de nuevo.';

  @override
  String get esphomeTypeConfig => 'Configuración';

  @override
  String get esphomeTypeDiagnostics => 'Diagnóstico';

  @override
  String get esphomeTypeSensorGroup => 'Sensor';

  @override
  String get esphomeTypeControl => 'Control';

  @override
  String get esphomeTypeSensor => 'sensor';

  @override
  String get esphomeTypeTextSensor => 'sensor de texto';

  @override
  String get esphomeTypeBinarySensor => 'sensor binario';

  @override
  String get esphomeTypeCamera => 'cámara';

  @override
  String get esphomeTypeSwitch => 'interruptor';

  @override
  String get esphomeTypeButton => 'botón';

  @override
  String get esphomeTypeNumber => 'número';

  @override
  String get esphomeTypeSelect => 'selección';

  @override
  String get esphomeTypeLight => 'luz';

  @override
  String get esphomeTypeUpdate => 'actualización';

  @override
  String get esphomeTypeText => 'texto';

  @override
  String get filesUpload => 'Subir archivo';

  @override
  String get filesUploading => 'Subiendo…';

  @override
  String get filesUploadFailed => 'No se pudo subir el archivo';

  @override
  String get filesUploaded => 'Archivo subido';

  @override
  String get filesPermissionMissing =>
      'Falta el permiso de acceso a todos los archivos';

  @override
  String get filesPermissionHelp =>
      'Sin este permiso solo puedes explorar la carpeta de la aplicación. La pantalla de permisos se abre en la tablet.';

  @override
  String get filesGrant => 'Conceder en el dispositivo';

  @override
  String get filesUp => 'Subir una carpeta';

  @override
  String get filesShared => 'Almacenamiento compartido';

  @override
  String get filesApp => 'Carpeta de la aplicación';

  @override
  String get filesReadFailed => 'No se pudo leer la carpeta';

  @override
  String get filesEmpty => 'Carpeta vacía';

  @override
  String get filesEmptyHelp => 'Todavía no hay nada aquí.';

  @override
  String get filesFolder => 'Carpeta';

  @override
  String get filesDownload => 'Descargar';

  @override
  String get filesDownloadFailed => 'No se pudo descargar el archivo';

  @override
  String filesDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get filesDeleteHelp => 'El archivo se eliminará del dispositivo.';

  @override
  String get filesInvalidPath => 'Ruta no válida';

  @override
  String get filesNoFolder => 'La carpeta no existe';

  @override
  String get filesNoFile => 'El archivo no existe';

  @override
  String filesReadError(String error) {
    return 'No se puede leer la carpeta: $error';
  }

  @override
  String filesWriteError(String error) {
    return 'No se pudo escribir: $error';
  }

  @override
  String get filesDeleteFailed => 'No se pudo eliminar el archivo';

  @override
  String get fleetFleetManagementNeedsTheRemoteAdmin =>
      'La gestión de flota necesita la administración remota';

  @override
  String get fleetKiosksFindEachOtherThroughItTurnOnRemote =>
      'Los kioskos se encuentran mediante la administración remota. Activa Administración remota y Buscar otros kioskos en Dispositivo y luego vuelve aquí.';

  @override
  String get fleetLeadThisFleet => 'Dirigir esta flota';

  @override
  String get fleetSyncThisKioskSSettingsToItsFollowersRequires =>
      'Sincroniza la configuración de este kiosko con los que lo siguen. Todos los kioskos deben usar la misma versión.';

  @override
  String get fleetAKioskThatFollowsALeaderCannotLead =>
      'Un kiosko que sigue a un líder no puede dirigir una flota.';

  @override
  String get fleetFollowers => 'Seguidores';

  @override
  String get fleetProfiles => 'Perfiles';

  @override
  String get fleetLeader => 'Líder';

  @override
  String get fleetLearnWhichSettingsSyncAndWhichDoNotIn =>
      'Consulta qué ajustes se sincronizan y cuáles no en la ';

  @override
  String get fleetFleetManagementDocumentation =>
      'documentación de gestión de flota';

  @override
  String get fleetMore => 'Más';

  @override
  String get fleetSearchFollowers =>
      'Los kioskos que siguen a este, su estado y la opción de añadir uno.';

  @override
  String get fleetAddAKiosk => 'Añadir un kiosko';

  @override
  String get fleetKiosksMemberOfTheFleetAFollowerMustConfirm =>
      'Añade un kiosko encontrado o introduce su dirección IP. El seguidor debe aceptar la invitación en su pantalla.';

  @override
  String get fleetSendInvitation => 'Enviar invitación';

  @override
  String get fleetInviteAgain => 'Volver a invitar';

  @override
  String fleetRemoveName(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get fleetItStopsFollowingThisKioskAndKeepsItsSettings =>
      'Deja de seguir a este kiosko y conserva su configuración.';

  @override
  String fleetNameWantsToLeadThisKiosk(String name) {
    return '$name quiere dirigir este kiosko';
  }

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategories =>
      'A partir de ahora, su configuración sustituye a la de este kiosko en las categorías que sincroniza. Este kiosko conserva su nombre e identidad.';

  @override
  String get fleetItsSettingsReplaceThisKioskSInTheCategoriesDetail =>
      'A partir de ahora, su configuración sustituye a la de este kiosko en las categorías que sincroniza. Este kiosko conserva su nombre, sus identidades en Home Assistant, Music Assistant y ESPHome y sus dispositivos seleccionados. Puedes salir de la flota cuando quieras desde Configuración > Gestión de flota.';

  @override
  String get fleetConfirmOnTheKioskItselfTheInvitationIsWaiting =>
      'Confirma en el propio kiosko. La invitación aparece en su pantalla y en Configuración > Gestión de flota.';

  @override
  String get fleetAccept => 'Aceptar';

  @override
  String get fleetLookingForOtherKiosks => 'Buscando otros kioskos…';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKiosk =>
      'No se encontraron kioskos. Usa Añadir por IP para buscar uno en una dirección conocida.';

  @override
  String fleetFollowsName(String name) {
    return 'Sigue a $name';
  }

  @override
  String get fleetLeadsAFleet => 'Dirige una flota';

  @override
  String get fleetNoFleetManagement => 'Sin gestión de flota';

  @override
  String get fleetKiosksOnThisNetworkThatDoNotFollowThis =>
      'Kioskos de esta red que no siguen a este. Selecciona uno y elige qué recibirá para enviarle la invitación. Si su versión no incluye Gestión de flota, podrá unirse cuando la actualice.';

  @override
  String get fleetJoinedTheFleet => 'Te has unido a la flota';

  @override
  String get fleetSettingsFromTheLeaderArriveShortly =>
      'La configuración del líder llegará en breve.';

  @override
  String get fleetAddByIp => 'Añadir por IP';

  @override
  String get fleetFindKiosk => 'Buscar kiosko';

  @override
  String get fleetFindingKiosk => 'Buscando kiosko…';

  @override
  String get fleetIpAddress => 'Dirección IP';

  @override
  String get fleetRemoteAdminPort => 'Puerto de administración remota';

  @override
  String get fleetAddressHelp =>
      'Introduce la dirección IP del kiosko y su puerto de administración remota.';

  @override
  String get fleetAddAProfile => 'Añadir un perfil';

  @override
  String get fleetTheCollectionOfSettingsCredentialsAndExclusionsToSync =>
      'El conjunto de ajustes, credenciales y exclusiones para sincronizar.';

  @override
  String get fleetNewProfile => 'Nuevo perfil';

  @override
  String get fleetProfile => 'Perfil';

  @override
  String get fleetUpdatesOnly => 'Solo actualizaciones';

  @override
  String get fleetNothingSyncsOnlyUpdatesArePushed =>
      'No se sincroniza ningún ajuste. Solo se envían actualizaciones.';

  @override
  String
  fleetCategoriesSelectedOfTotalCredentialsCredentialsOfCredentialtotalExcluded(
    String selected,
    String total,
    String credentials,
    String credentialTotal,
    String excluded,
  ) {
    return 'Categorías: $selected de $total. Credenciales: $credentials de $credentialTotal. Excluidos: $excluded.';
  }

  @override
  String get fleetThisProfileIsGone => 'Este perfil ya no existe';

  @override
  String get fleetItWasDeletedFromAnotherPage =>
      'Se eliminó desde otra página.';

  @override
  String get fleetName => 'Nombre';

  @override
  String get fleetRename => 'Cambiar nombre';

  @override
  String get fleetRenameProfile => 'Cambiar nombre del perfil';

  @override
  String get fleetWhatItSyncs => 'Qué se sincroniza';

  @override
  String get fleetNothing => 'Nada';

  @override
  String get fleetKiosksOnThisProfileKeepEverySettingOfTheir =>
      'Los kioskos con este perfil conservan toda su configuración. El líder solo les envía actualizaciones.';

  @override
  String get fleetCategories => 'Categorías';

  @override
  String fleetSelectedOfTotalNames(
    String selected,
    String total,
    String names,
  ) {
    return '$selected de $total: $names';
  }

  @override
  String get fleetCredentials => 'Credenciales';

  @override
  String get fleetNoneTravel => 'No se envía ninguna';

  @override
  String get fleetIncludeTheDashboard => 'Incluir el panel de control';

  @override
  String get fleetTheStartPageAndTheDefaultDashboard =>
      'La página de inicio y el panel de control predeterminado.';

  @override
  String get fleetExcludedSettings => 'Ajustes excluidos';

  @override
  String get fleetOneSettingLeftOut => 'Un ajuste excluido';

  @override
  String fleetCountSettingsLeftOut(String count) {
    return '$count ajustes excluidos';
  }

  @override
  String get fleetNoKiosksAssigned => 'No hay kioskos asignados';

  @override
  String get fleetAssignThisProfileToAKioskOnTheFleet =>
      'Asigna este perfil a un kiosko en la página Gestión de flota.';

  @override
  String get fleetDuplicate => 'Duplicar';

  @override
  String get fleetCloneThisProfileIntoANewOne =>
      'Crea un perfil nuevo a partir de este.';

  @override
  String get fleetDuplicateProfile => 'Duplicar perfil';

  @override
  String fleetNameCopy(String name) {
    return 'Copia de $name';
  }

  @override
  String get fleetDeleteProfile => 'Eliminar perfil';

  @override
  String get fleetNoKioskIsOnIt => 'Ningún kiosko usa este perfil.';

  @override
  String get fleetKiosksOnItGetTheDefaultProfile =>
      'Los kioskos que lo usan reciben el perfil Predeterminado.';

  @override
  String fleetDeleteName(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get fleetBlackScreens => 'Pantallas negras';

  @override
  String fleetSyncToName(String name) {
    return 'Sincronizar con $name';
  }

  @override
  String get fleetDefault => 'Predeterminado';

  @override
  String get fleetNone => 'Ninguno';

  @override
  String get fleetSearchProfiles =>
      'Los perfiles que se pueden asignar a un seguidor: categorías, credenciales, panel de control y ajustes excluidos.';

  @override
  String get fleetSyncNow => 'Sincronizar ahora';

  @override
  String get fleetChangedHereWaitingForTheLeader =>
      'Cambios locales, esperando al líder';

  @override
  String fleetSyncedTime(String time) {
    return 'Sincronizado $time';
  }

  @override
  String get fleetWaitingForTheFirstSync =>
      'Esperando la primera sincronización';

  @override
  String get fleetNothingYet => 'Nada todavía';

  @override
  String get fleetNoCredentials => 'Sin credenciales';

  @override
  String fleetWithTheNames(String names) {
    return 'Con $names';
  }

  @override
  String get fleetTheDashboard => 'el panel de control';

  @override
  String get fleetNoDashboard => 'sin panel de control';

  @override
  String get fleetTheDashboardDetail => 'El panel de control';

  @override
  String get fleetNoDashboardDetail => 'Sin panel de control';

  @override
  String get fleetSyncedFromTheLeader => 'Sincronizado desde el líder';

  @override
  String get fleetLeaveTheFleet => 'Salir de la flota';

  @override
  String get fleetStopsTheSyncSettingsStayAsTheyAre =>
      'Detiene la sincronización. La configuración se conserva tal como está.';

  @override
  String get fleetLeaveTheFleetDetail => '¿Salir de la flota?';

  @override
  String fleetNameStopsPushingSettingsHereEverythingStaysAsIt(String name) {
    return '$name deja de enviar ajustes a este kiosko. Todo se conserva tal como está.';
  }

  @override
  String get fleetLeave => 'Salir';

  @override
  String get fleetJustNow => 'ahora mismo';

  @override
  String fleetCountMinAgo(String count) {
    return 'hace $count min';
  }

  @override
  String fleetCountHAgo(String count) {
    return 'hace $count h';
  }

  @override
  String fleetCountDaysAgo(String count) {
    return 'hace $count días';
  }

  @override
  String fleetNameLeadsTheseSettingsAChangeHereIsReplaced(String name) {
    return '$name dirige estos ajustes. Los cambios locales se sustituyen en la siguiente sincronización.';
  }

  @override
  String get fleetDeclinedOnTheKiosk => 'Rechazado en el kiosko';

  @override
  String get fleetWaitingForItsOk => 'Esperando su confirmación';

  @override
  String get fleetLeftTheFleet => 'Salió de la flota';

  @override
  String fleetSendingPercent(String percent) {
    return 'Enviando $percent%';
  }

  @override
  String get fleetInstalling => 'Instalando';

  @override
  String fleetRunsVersionThisKioskNeedsAnUpdate(String version) {
    return 'Usa $version, este kiosko necesita una actualización';
  }

  @override
  String fleetNeedsVersion(String version) {
    return 'Necesita $version';
  }

  @override
  String fleetDownloadingPercent(String percent) {
    return 'Descargando $percent%';
  }

  @override
  String get fleetSyncing => 'Sincronizando…';

  @override
  String get fleetErrorUnreachable => 'Inaccesible';

  @override
  String get fleetErrorBadAnswer => 'Respuesta no válida';

  @override
  String get fleetErrorThePushFailed => 'No se pudo enviar la configuración';

  @override
  String get fleetErrorLeadThisFleetIsOff =>
      'Dirigir esta flota está desactivado';

  @override
  String get fleetErrorTheRemoteAdminAndFindOtherKiosksMustBeOn =>
      'La administración remota y Buscar otros kioskos deben estar activados';

  @override
  String get fleetErrorPickAnotherKiosk => 'Selecciona otro kiosko';

  @override
  String get fleetErrorThatKioskIsNotOnTheNetworkRightNow =>
      'Ese kiosko no está en la red en este momento';

  @override
  String get fleetErrorThatKioskDidNotAnswer => 'Ese kiosko no respondió';

  @override
  String get fleetErrorThatKioskRefusedTheInvitation =>
      'Ese kiosko rechazó la invitación';

  @override
  String get fleetErrorTheDefaultProfileStays =>
      'El perfil Predeterminado no se puede eliminar';

  @override
  String get fleetErrorTheUpdatesOnlyProfileStays =>
      'El perfil Solo actualizaciones no se puede eliminar';

  @override
  String get fleetErrorNoSuchProfile => 'Ese perfil no existe';

  @override
  String get fleetErrorNoSuchFollower => 'Ese seguidor no existe';

  @override
  String get fleetErrorNoInvitationIsWaiting =>
      'No hay invitaciones pendientes';

  @override
  String get fleetErrorMalformedInvitation => 'Invitación no válida';

  @override
  String get fleetErrorCouldNotMintAToken => 'No se pudo generar un token';

  @override
  String get fleetErrorNotAFollowerYet => 'aún no es un seguidor';

  @override
  String get fleetErrorOffline => 'sin conexión';

  @override
  String get fleetErrorUpToDate => 'actualizado';

  @override
  String get fleetErrorAlreadyDownloading => 'ya se está descargando';

  @override
  String get fleetErrorDidNotAnswer => 'no respondió';

  @override
  String get fleetErrorDidNotTakeTheUpload => 'no aceptó el archivo';

  @override
  String fleetProfileNameExists(String name) {
    return 'Ya existe un perfil llamado $name';
  }

  @override
  String fleetAlreadyOnVersion(String version) {
    return 'ya usa $version';
  }

  @override
  String get fleetUnsupportedBuild =>
      'Ese kiosko usa una versión sin Gestión de flota. Podrá unirse cuando la actualice.';

  @override
  String get fleetErrorAddressMismatch =>
      'La dirección corresponde a otro kiosko o a otra flota';

  @override
  String get fleetErrorInvalidIp => 'Introduce una dirección IP válida.';

  @override
  String get fleetErrorInvalidPort => 'Introduce un puerto entre 1 y 65535.';

  @override
  String get fleetErrorIdentityNotReady =>
      'La identidad de este kiosko aún no está lista. Inténtalo de nuevo.';

  @override
  String get fleetErrorInvalidIdentity =>
      'Esa dirección no devolvió una identidad de kiosko válida.';

  @override
  String get fleetErrorAlreadyMember =>
      'Este kiosko ya pertenece a esta flota.';

  @override
  String get fleetErrorIsLeader => 'Ese kiosko dirige una flota.';

  @override
  String get fleetErrorOtherLeader => 'Ese kiosko ya sigue a otro líder.';

  @override
  String get fleetSwitchKiosk => 'Cambiar de kiosko';

  @override
  String get fleetKiosksOnThisNetworkWithTheRemoteAdminOn =>
      'Kioskos encontrados y miembros guardados de la flota. Selecciona uno para abrir aquí su administración remota en esta misma página.';

  @override
  String get fleetNoOtherKioskFoundOnThisNetworkAKioskDetail =>
      'No se encontraron otros kioskos. Los kioskos aparecen al encontrarlos en la red o al estar guardados como miembros de la flota.';

  @override
  String get fleetSyncedCredentials => 'Credenciales sincronizadas';

  @override
  String get fleetTheSettingsOnThisListWillNotBeSynced =>
      'Los ajustes de esta lista no se sincronizan con los seguidores.';

  @override
  String get fleetNothingLeftOut => 'No hay ajustes excluidos';

  @override
  String get fleetSyncItAgain => 'Volver a sincronizar';

  @override
  String get fleetAddASetting => 'Añadir un ajuste';

  @override
  String get fleetExcludeASetting => 'Excluir un ajuste';

  @override
  String get fleetSearchSettings => 'Buscar ajustes';

  @override
  String fleetCountMoreTypeToNarrowTheList(String count) {
    return '$count más. Escribe para filtrar la lista.';
  }

  @override
  String fleetNotSyncedNote(String note) {
    return 'No se sincroniza: $note';
  }

  @override
  String get fleetTheAssignedSatellite => 'el satélite asignado';

  @override
  String get fleetMicrophoneAndSpeakerDevicesMicGain =>
      'los dispositivos de micrófono y altavoz y la ganancia del micrófono';

  @override
  String get fleetTheDeviceCamera => 'la cámara del dispositivo';

  @override
  String get fleetTheFollowedPlayerTheSendspinPlayerId =>
      'el reproductor seguido y el identificador del reproductor Sendspin';

  @override
  String get fleetNodeNameMacEncryptionKey =>
      'el nombre del nodo, la MAC y la clave de cifrado';

  @override
  String get fleetThePinIsAlsoSynced => 'el PIN también se sincroniza';

  @override
  String get fleetTheKeyUnlessSyncedAsACredential =>
      'la clave, salvo que se sincronice como credencial';

  @override
  String get fleetNameRemoteAdministrationRendererWorkaroundsScale =>
      'el nombre, la administración remota, los ajustes de compatibilidad del renderizador y la escala';

  @override
  String get fleetHomeAssistantToken => 'Token de Home Assistant';

  @override
  String get fleetMusicAssistantToken => 'Token de Music Assistant';

  @override
  String get fleetImmichApiKey => 'Clave de API de Immich';

  @override
  String get fleetUpdateTheFleet => 'Actualizar la flota';

  @override
  String get fleetUpdateTheWholeFleetToTheKioskSatelliteVersion =>
      'Actualiza toda la flota a la versión de Kiosk Satellite que usa el líder.';

  @override
  String get fleetKeepFollowersOnThisVersion =>
      'Mantener a los seguidores en esta versión';

  @override
  String get fleetAutomaticallyUpdateAllFollowersToTheKioskSatelliteVersion =>
      'Actualiza automáticamente a todos los seguidores a la versión de Kiosk Satellite que usa el líder.';

  @override
  String get fleetNothingToUpdate => 'No hay nada que actualizar';

  @override
  String get fleetUpdating => 'Actualizando';

  @override
  String fleetNamesInstalling(String names) {
    return 'Instalando en $names.';
  }

  @override
  String get fleetSearchUpdates =>
      'Instala la versión disponible en cada seguidor y luego aquí.';

  @override
  String get gestureAction => 'Acción';

  @override
  String get gestureNavigate => 'Ir a una vista del panel de control';

  @override
  String get gestureUrl => 'Abrir una página web';

  @override
  String get gestureCameraView => 'Mostrar una vista de cámaras';

  @override
  String get gestureLauncher => 'Abrir el lanzador de aplicaciones';

  @override
  String get gestureIntercomOpen => 'Abrir Llamar a un kiosko';

  @override
  String get gestureIntercomCall => 'Llamar a un kiosko';

  @override
  String get gestureScreensaver => 'Iniciar el protector de pantalla';

  @override
  String get gestureScreensaverStop => 'Detener el protector de pantalla';

  @override
  String get gestureHoldMode => 'Activar o desactivar el modo de pausa';

  @override
  String get gestureHaKiosk => 'Activar o desactivar el modo kiosko de HA';

  @override
  String get gesturePluginRun => 'Ejecutar una acción de un plugin';

  @override
  String get gestureLaunchApp => 'Abrir otra aplicación';

  @override
  String get gestureDeepLink => 'Abrir un enlace profundo';

  @override
  String get gestureAndroidSettings => 'Abrir configuración de Android';

  @override
  String get gestureService => 'Llamar a un servicio';

  @override
  String get gestureScript => 'Ejecutar un script';

  @override
  String get gestureAutomation => 'Activar una automatización';

  @override
  String get gestureEvent => 'Emitir un evento';

  @override
  String get gesturePluginAction => 'Acción de plugin';

  @override
  String get gesturePluginActions => 'Acciones de plugins';

  @override
  String get gesturePluginHelp =>
      'Primero activa un plugin con acciones en el administrador de plugins.';

  @override
  String get gesturePluginFailed =>
      'No se pudieron cargar las acciones de los plugins.';

  @override
  String get gestureUrlError => 'Introduce una URL http(s) completa.';

  @override
  String get gesturePackage => 'Nombre del paquete';

  @override
  String get gesturePackageError => 'Introduce un nombre de paquete.';

  @override
  String get gestureUriError => 'Introduce una URI completa.';

  @override
  String get gestureNoDashboards => 'No hay paneles de control';

  @override
  String get gestureDashboardsFailed =>
      'No se pudieron obtener los paneles de control';

  @override
  String get gestureHaConnected => '¿Está conectado Home Assistant?';

  @override
  String get gestureDashboardsHelp =>
      'No se pudieron obtener los paneles de control. ¿Está conectado Home Assistant?';

  @override
  String get gestureCameraTitle => 'Vista de cámaras';

  @override
  String gestureCameraShow(String name) {
    return 'Mostrar $name';
  }

  @override
  String get gestureCameraClose => 'Cerrar la vista de cámaras';

  @override
  String get gestureCameraEmpty => 'Aún no hay vistas de cámaras configuradas.';

  @override
  String get gestureIntercomEmpty =>
      'Aún no se ha encontrado ningún kiosko en la red.';

  @override
  String gestureDescribeCornerTaps(String count, String corner) {
    return '$count toques en la esquina $corner';
  }

  @override
  String gestureDescribeCornerHold(String corner, String seconds) {
    return 'Mantener pulsada la esquina $corner durante ${seconds}s';
  }

  @override
  String gestureDescribeFingerDouble(String count) {
    return 'Doble toque con $count dedos';
  }

  @override
  String gestureDescribeFingerTap(String count) {
    return 'Toque con $count dedos';
  }

  @override
  String gestureDescribeFingerHold(String count, String seconds) {
    return 'Mantener pulsado con $count dedos durante ${seconds}s';
  }

  @override
  String gestureDescribeSequence(String sequence) {
    return 'Secuencia de esquinas: $sequence';
  }

  @override
  String gestureDescribeClaps(String count) {
    return '$count palmadas';
  }

  @override
  String get gestureDescribeOpenHand => 'Mostrar la mano abierta';

  @override
  String gestureDescribeOneFinger(String count) {
    return 'Mostrar $count dedo';
  }

  @override
  String gestureDescribeFingers(String count) {
    return 'Mostrar $count dedos';
  }

  @override
  String get gestureTopLeft => 'superior izquierda';

  @override
  String get gestureTopRight => 'superior derecha';

  @override
  String get gestureBottomLeft => 'inferior izquierda';

  @override
  String get gestureBottomRight => 'inferior derecha';

  @override
  String gestureGoTo(String value) {
    return 'Ir a $value';
  }

  @override
  String gestureOpen(String value) {
    return 'Abrir $value';
  }

  @override
  String get gestureCameraToggle => 'Mostrar u ocultar la vista de cámaras';

  @override
  String gestureCameraToggleName(String name) {
    return 'Mostrar u ocultar la vista de cámaras $name';
  }

  @override
  String gestureCall(String value) {
    return 'Llamar a $value';
  }

  @override
  String gestureOpenApp(String package) {
    return 'Abrir aplicación $package';
  }

  @override
  String gestureRun(String value) {
    return 'Ejecutar $value';
  }

  @override
  String gestureTriggerAction(String value) {
    return 'Activar $value';
  }

  @override
  String gestureFireEvent(String value) {
    return 'Emitir evento $value';
  }

  @override
  String get gestureValid => 'Todo correcto.';

  @override
  String get gestureValidationFailed => 'No se pudo validar.';

  @override
  String gestureDomainMissing(String value) {
    return 'No se encontró el dominio $value.';
  }

  @override
  String gestureServiceMissing(String value) {
    return 'No se encontró el servicio $value.';
  }

  @override
  String gestureEntityMissing(String value) {
    return 'No se encontró la entidad $value.';
  }

  @override
  String gestureEntityRequired(String domain) {
    return 'Introduce una entidad $domain.*.';
  }

  @override
  String get gestureScriptEntity => 'Entidad del script';

  @override
  String get gestureAutomationEntity => 'Entidad de la automatización';

  @override
  String get gestureDomain => 'Dominio';

  @override
  String get gestureEntityOptional => 'Entidad (opcional)';

  @override
  String get gestureServiceData => 'Datos del servicio (opcional)';

  @override
  String get gestureServiceTitle => 'Llamar a un servicio de Home Assistant';

  @override
  String get gestureServiceRequired =>
      'El dominio y el servicio son obligatorios.';

  @override
  String get gestureServiceJson =>
      'Los datos del servicio deben ser un objeto JSON.';

  @override
  String get gestureEventType => 'Tipo de evento';

  @override
  String get gestureEventData => 'Datos del evento (opcional)';

  @override
  String get gestureEventTitle => 'Emitir un evento de Home Assistant';

  @override
  String get gestureEventRequired => 'El tipo de evento es obligatorio.';

  @override
  String get gestureEventJson =>
      'Los datos del evento deben ser un objeto JSON.';

  @override
  String get gestureTester => 'Prueba de gestos con la mano';

  @override
  String get gestureOpenTester => 'Abrir prueba';

  @override
  String get gestureCameraFirst =>
      'Primero activa la cámara en la configuración de Cámara.';

  @override
  String get gestureTesterHelp =>
      'Observa qué dedos detecta la cámara para aprender cómo colocar la mano.';

  @override
  String get gestureHandHelp =>
      'Levanta la mano a la altura del hombro, con la palma hacia la cámara y los dedos separados. Dobla un dedo por completo para dejar de contarlo. Dobla el pulgar sobre la palma para mostrar cuatro: el pulgar solo cuenta con la mano abierta.';

  @override
  String get gestureTesterPaused =>
      'Los gestos no se ejecutan mientras la prueba está abierta.';

  @override
  String get gestureShowHand => 'Muestra una mano a la cámara.';

  @override
  String gestureTesterTrigger(String action) {
    return 'Ejecuta: $action';
  }

  @override
  String get gestureNoCount => 'Ningún gesto usa esta cantidad de dedos.';

  @override
  String get gestureNoHand => 'No se ve ninguna mano';

  @override
  String get gestureReadingHand => 'Detectando la mano';

  @override
  String get gestureNoFingers => 'Ningún dedo levantado';

  @override
  String gestureHandsCount(String count) {
    return 'Se ven $count manos. Se está detectando la más grande.';
  }

  @override
  String get gestureTesterSearch =>
      'Muestra en tiempo real los dedos que detecta la cámara.';

  @override
  String get gestureHoldConfirmed => 'Gesto confirmado';

  @override
  String gestureHoldProgress(String progress) {
    return 'Progreso del gesto: $progress';
  }

  @override
  String gestureTesterHoldDuration(String duration) {
    return 'Tiempo de espera: $duration';
  }

  @override
  String get gestureHaServiceKind => 'Servicio de Home Assistant';

  @override
  String get gestureHaScriptKind => 'Script de Home Assistant';

  @override
  String get gestureHaAutomationKind => 'Automatización de Home Assistant';

  @override
  String get gestureHaEventKind => 'Evento de Home Assistant';

  @override
  String gestureRan(String value) {
    return 'Se ejecutó $value';
  }

  @override
  String gestureRunFailed(String value) {
    return 'No se pudo ejecutar $value';
  }

  @override
  String gestureCalled(String value) {
    return 'Se llamó a $value';
  }

  @override
  String gestureCallFailed(String value) {
    return 'No se pudo llamar a $value';
  }

  @override
  String gestureTriggered(String value) {
    return 'Se activó $value';
  }

  @override
  String gestureTriggerFailed(String value) {
    return 'No se pudo activar $value';
  }

  @override
  String gestureFired(String value) {
    return 'Se emitió el evento $value';
  }

  @override
  String gestureFireFailed(String value) {
    return 'No se pudo emitir el evento $value';
  }

  @override
  String get gestureDone => 'Hecho';

  @override
  String get gestureFailed => 'Error';

  @override
  String get gestureEdit => 'Editar gesto';

  @override
  String get gestureTrigger => 'Gesto';

  @override
  String get gestureCornerTaps => 'Toques en una esquina';

  @override
  String get gestureCornerHold => 'Mantener pulsada una esquina';

  @override
  String get gestureFingerTaps => 'Toque con varios dedos';

  @override
  String get gestureFingerHold => 'Mantener pulsado con varios dedos';

  @override
  String get gestureSequence => 'Secuencia de esquinas';

  @override
  String get gestureClaps => 'Palmadas';

  @override
  String get gestureShowFingers => 'Mostrar dedos';

  @override
  String get gestureCorner => 'Esquina';

  @override
  String get gestureCornerTl => 'Esquina superior izquierda';

  @override
  String get gestureCornerTr => 'Esquina superior derecha';

  @override
  String get gestureCornerBl => 'Esquina inferior izquierda';

  @override
  String get gestureCornerBr => 'Esquina inferior derecha';

  @override
  String get gestureTaps => 'Toques';

  @override
  String get gestureTaps2 => '2 toques';

  @override
  String get gestureTaps3 => '3 toques';

  @override
  String get gestureTaps4 => '4 toques';

  @override
  String get gestureFingers => 'Dedos';

  @override
  String get gestureFinger1 => '1 dedo';

  @override
  String get gestureFinger2 => '2 dedos';

  @override
  String get gestureFinger3 => '3 dedos';

  @override
  String get gestureFinger4 => '4 dedos';

  @override
  String get gestureOpenHand5 => 'Mano abierta (5)';

  @override
  String get gestureSingleTap => 'Un toque';

  @override
  String get gestureDoubleTap => 'Doble toque';

  @override
  String gestureHoldDuration(String seconds) {
    return 'Mantén pulsado durante $seconds s';
  }

  @override
  String get gestureCameraHelp =>
      'Necesita la cámara activada y un lugar bien iluminado.';

  @override
  String get gestureUnavailable => 'No disponible en este dispositivo.';

  @override
  String get gestureClaps2 => '2 palmadas';

  @override
  String get gestureClaps3 => '3 palmadas';

  @override
  String get gestureClaps4 => '4 palmadas';

  @override
  String get gestureClapHelp =>
      'Las palmadas se detectan con el micrófono, con o sin detección de la palabra de activación.';

  @override
  String get gestureSequenceHelp =>
      'Toca las esquinas en orden (de 2 a 8 pasos).';

  @override
  String get gestureRemoveStep => 'Quitar último paso';

  @override
  String get gestureUndo => 'Deshacer';

  @override
  String get gestureChooseAction => 'Elige una acción';

  @override
  String get gestureActionHelp => 'Lo que ejecuta este gesto.';

  @override
  String get gestureChangeHelp => 'Toca para cambiar.';

  @override
  String get gestureChooseError => 'Elige una acción.';

  @override
  String get gestureSequenceError => 'Añade al menos dos esquinas.';

  @override
  String get intercomCall => 'Llamar';

  @override
  String get intercomNoReady => 'No hay kioskos listos.';

  @override
  String get intercomOneReady => 'Hay 1 kiosko listo.';

  @override
  String intercomManyReady(String count) {
    return 'Hay $count kioskos listos.';
  }

  @override
  String get intercomCallKiosk => 'Llamar a un kiosko';

  @override
  String get intercomAnnounceAll => 'Anunciar a todos';

  @override
  String get intercomAnnounceHelp =>
      'Habla a todos los kioskos. Solo tú puedes hablar.';

  @override
  String intercomMissedFrom(String name) {
    return 'Llamada perdida de $name';
  }

  @override
  String intercomRangFor(String seconds) {
    return 'Sonó durante $seconds segundos.';
  }

  @override
  String get intercomCallBack => 'Devolver llamada';

  @override
  String get intercomDeclined => 'Rechazada';

  @override
  String get intercomBusy => 'Ocupado';

  @override
  String get intercomPeerOff => 'Su intercomunicador está desactivado';

  @override
  String get intercomPeerKey => 'Clave de intercomunicador diferente';

  @override
  String get intercomNoAnswer => 'Sin respuesta';

  @override
  String get intercomDidNotAnswer => 'No respondió';

  @override
  String get intercomVoiceFailed => 'Falló la conexión de voz';

  @override
  String get intercomCancelled => 'Cancelada';

  @override
  String get intercomPageMic => 'La página tomó el micrófono';

  @override
  String get intercomNobody => 'Nadie pudo recibirlo';

  @override
  String get intercomDone => 'Finalizado';

  @override
  String get intercomEnded => 'Llamada finalizada';

  @override
  String get intercomAnnouncement => 'Anuncio';

  @override
  String get intercomAnnouncingOne => 'Anunciando a 1 kiosko';

  @override
  String intercomAnnouncingMany(String count) {
    return 'Anunciando a $count kioskos';
  }

  @override
  String get intercomIsCalling => 'está llamando';

  @override
  String get intercomIsAnnouncing => 'está anunciando';

  @override
  String get intercomCalling => 'Llamando…';

  @override
  String intercomAnswersIn(String seconds) {
    return 'Responde en $seconds s';
  }

  @override
  String get intercomRinging => 'Sonando';

  @override
  String get intercomConnecting => 'Conectando…';

  @override
  String intercomDoneDuration(String duration) {
    return 'Finalizado, $duration';
  }

  @override
  String intercomEndedDuration(String duration) {
    return 'Llamada finalizada, $duration';
  }

  @override
  String get intercomDecline => 'Rechazar';

  @override
  String get intercomAnswer => 'Responder';

  @override
  String get intercomEveryKiosk => 'Todos los kioskos';

  @override
  String get intercomStop => 'Detener';

  @override
  String intercomHearsYou(String name) {
    return '$name te escucha';
  }

  @override
  String get intercomAllHearYou => 'Todos los kioskos te escuchan';

  @override
  String get intercomHoldHelp =>
      'Mantén pulsado para hablar y suelta para escuchar';

  @override
  String get intercomMuted => 'Silenciado';

  @override
  String get intercomMute => 'Silenciar';

  @override
  String get intercomEnd => 'Finalizar';

  @override
  String get intercomReply => 'Responder';

  @override
  String get intercomDismiss => 'Cerrar';

  @override
  String get intercomCallAgain => 'Volver a llamar';

  @override
  String get intercomDashboardMic =>
      'El panel de control está usando el micrófono. Solo puedes escuchar.';

  @override
  String get intercomMicDenied =>
      'No se concedió acceso al micrófono. Solo puedes escuchar.';

  @override
  String get intercomHoldTalk => 'Mantén pulsado para hablar';

  @override
  String get intercomPlaying => 'Reproduciendo';

  @override
  String get intercomAKiosk => 'un kiosko';

  @override
  String intercomCallingName(String name) {
    return 'Llamando a $name';
  }

  @override
  String intercomNameCalling(String name) {
    return '$name está llamando';
  }

  @override
  String intercomInCallName(String name) {
    return 'En una llamada con $name';
  }

  @override
  String intercomNameAnnouncing(String name) {
    return '$name está anunciando';
  }

  @override
  String intercomHaMessage(String message) {
    return 'Home Assistant: $message';
  }

  @override
  String get intercomEndCall => 'Finalizar llamada';

  @override
  String get intercomCallFailed => 'No se pudo llamar';

  @override
  String get intercomKeyFailed => 'No se pudo cambiar la clave';

  @override
  String get intercomBroadcastFailed => 'No se pudo hablar a todos';

  @override
  String get intercomDeviceNoAnswer => 'El dispositivo no respondió.';

  @override
  String get intercomUnknownKiosk => 'kiosko desconocido';

  @override
  String get intercomNothingRinging => 'no hay ninguna llamada sonando';

  @override
  String get intercomNoCall => 'no hay ninguna llamada';

  @override
  String get intercomDisabled => 'el intercomunicador está desactivado';

  @override
  String get intercomNeedsRemote => 'necesita la administración remota';

  @override
  String get intercomNeedsDiscovery =>
      'el intercomunicador necesita la administración remota y Buscar otros kioskos';

  @override
  String get intercomAlreadyCalling => 'ya hay una llamada en curso';

  @override
  String get intercomNoReadyError => 'no hay kioskos listos';

  @override
  String get intercomKeyLength => 'la clave debe tener al menos 16 caracteres';

  @override
  String get intercomMicHeld => 'la página está usando el micrófono';

  @override
  String get intercomMicPermission => 'no se concedió acceso al micrófono';

  @override
  String get intercomCallerNoAnswer => 'el kiosko que llama no respondió';

  @override
  String get intercomMissedcall => 'Llamada perdida';

  @override
  String get intercomListening => 'Escuchando';

  @override
  String get intercomAnnouncementsoff => 'Anuncios desactivados';

  @override
  String get intercomEncryptionMismatch => 'El cifrado no coincide';

  @override
  String get intercomEncryptionMismatchHelp =>
      'El cifrado no coincide. Activa Cifrar comunicaciones en todos los kioscos de la llamada.';

  @override
  String get kioskBackClose => 'Pulsa Atrás de nuevo para cerrar la aplicación';

  @override
  String get kioskBackAgain => 'Pulsa Atrás de nuevo para retroceder';

  @override
  String get kioskHoldOn => 'Modo de pausa activado';

  @override
  String get kioskHoldOff => 'Modo de pausa desactivado';

  @override
  String get kioskHoldNotice =>
      'La vista actual se mantiene hasta que lo desactives.';

  @override
  String get kioskDownloadComplete => 'Descarga completada';

  @override
  String get kioskDownloadFailed => 'No se pudo descargar el archivo';

  @override
  String get kioskDownload => 'Descarga';

  @override
  String get kioskDownloading => 'Descargando';

  @override
  String get kioskOpen => 'Abrir';

  @override
  String get kioskTip => 'Consejo';

  @override
  String get kioskMenuHint =>
      'Desliza desde el borde izquierdo para abrir el menú.';

  @override
  String get kioskUnknownLink => 'Enlace del kiosko desconocido';

  @override
  String get kioskOpenAppFailed => 'No se pudo abrir la aplicación';

  @override
  String get kioskWebViewMissing => 'Android System WebView no está instalado';

  @override
  String get kioskWebViewMissingHelp =>
      'Este dispositivo no tiene un proveedor de WebView, por lo que no se puede mostrar Home Assistant. Instala Android System WebView o Chrome y reinicia Kiosk Satellite.';

  @override
  String get kioskPinTitle => 'PIN del kiosko';

  @override
  String get kioskPinHint => 'PIN';

  @override
  String get kioskWrongPin => 'PIN incorrecto';

  @override
  String get kioskUnlock => 'Desbloquear';

  @override
  String get lockdownScreenLocked => 'La pantalla está bloqueada';

  @override
  String get logsWebConsole => 'Consola web';

  @override
  String get logsDock => 'Acoplar sobre la página actual';

  @override
  String get logsNoOutput => 'La consola aún no tiene mensajes';

  @override
  String get logsShareSubject => 'Registro de la consola de Kiosk Satellite';

  @override
  String get logsInput => 'Ejecutar JavaScript en la página';

  @override
  String get logsInputHistory =>
      'Ejecutar JavaScript en la página (Intro para ejecutar, arriba/abajo para el historial)';

  @override
  String get logsRun => 'Ejecutar';

  @override
  String get logsEvaluationFailed => 'No se pudo ejecutar';

  @override
  String get logsDeviceUnreachable => 'No se puede conectar con el dispositivo';

  @override
  String logsEntries(String count) {
    return '$count entradas';
  }

  @override
  String get logsCopyLog => 'Copiar registro';

  @override
  String get logsShareLog => 'Compartir registro';

  @override
  String get logsCopied => 'Copiado';

  @override
  String get logsCopyFailed => 'No se pudo copiar';

  @override
  String get logsOnClipboard => 'El registro está en el portapapeles.';

  @override
  String get logsConsoleOnClipboard =>
      'El registro de la consola está en el portapapeles.';

  @override
  String get logsSystemLog =>
      'Registro del sistema Android para esta aplicación (incluye los fallos)';

  @override
  String get logsErrors => 'Errores y fallos';

  @override
  String get logsWarnings => 'Advertencias';

  @override
  String get logsInfo => 'Información y depuración';

  @override
  String get logsNoMatches =>
      'No hay líneas que coincidan. Activa más tipos arriba para ver el registro completo.';

  @override
  String get logsUnavailable => 'Logcat no disponible';

  @override
  String logsReadFailed(String error) {
    return 'No se pudo leer Logcat: $error';
  }

  @override
  String get logsUnknown => 'desconocido';

  @override
  String get offlineDashboard => 'Panel de control no disponible';

  @override
  String get offlineNetwork => 'Sin conexión de red';

  @override
  String get offlinePageHelp => 'No se pudo cargar la página.';

  @override
  String get offlineNetworkHelp =>
      'El panel de control volverá cuando se restablezca la conexión de red.';

  @override
  String get offlineLost => 'Se perdió la conexión de red';

  @override
  String get offlineRestored => 'Se restableció la conexión de red';

  @override
  String get mediaPlay => 'Reproducir';

  @override
  String get mediaPause => 'Pausar';

  @override
  String get mediaPreviousTrack => 'Pista anterior';

  @override
  String get mediaNextTrack => 'Pista siguiente';

  @override
  String get mediaPlaying => 'Reproduciendo';

  @override
  String get mediaPaused => 'En pausa';

  @override
  String get mediaIdle => 'En espera';

  @override
  String get mediaStatusUnavailable => 'Estado no disponible';

  @override
  String get mediaUnknownTrack => 'Pista desconocida';

  @override
  String mediaStatusSource(String status, String source) {
    return '$status - $source';
  }

  @override
  String get mediaShowVolume => 'Mostrar volumen';

  @override
  String get mediaHideVolume => 'Ocultar volumen';

  @override
  String get mediaMute => 'Silenciar';

  @override
  String get mediaUnmute => 'Activar sonido';

  @override
  String get mediaFavoriteAdd => 'Añadir a favoritos';

  @override
  String get mediaFavoriteRemove => 'Quitar de favoritos';

  @override
  String get mediaShuffleOn => 'Activar reproducción aleatoria';

  @override
  String get mediaShuffleOff => 'Desactivar reproducción aleatoria';

  @override
  String get mediaRepeatAll => 'Repetir todo';

  @override
  String get mediaRepeatOne => 'Repetir una';

  @override
  String get mediaRepeatOff => 'Desactivar repetición';

  @override
  String get mediaShowLyrics => 'Mostrar letras';

  @override
  String get mediaHideLyrics => 'Ocultar letras';

  @override
  String get mediaShowQueue => 'Mostrar cola';

  @override
  String get mediaHideQueue => 'Ocultar cola';

  @override
  String get mediaVolume => 'Volumen';

  @override
  String get mediaPlaybackPosition => 'Posición de reproducción';

  @override
  String get mediaShowNowPlaying => 'Mostrar Reproduciendo Ahora';

  @override
  String get mediaShowFloatingPlayer => 'Mostrar el reproductor flotante';

  @override
  String get mediaOpenMusicAssistant => 'Abrir Music Assistant';

  @override
  String get mediaCannotControl =>
      'El comando no es compatible o no se pudo enviar.';

  @override
  String get mediaNothingQueued => 'No hay nada en cola';

  @override
  String get mediaChapters => 'Capítulos';

  @override
  String get mediaNowPlaying => 'Reproduciendo Ahora';

  @override
  String get mediaUpNext => 'A continuación';

  @override
  String mediaUnnamedChapter(String number) {
    return 'Capítulo $number';
  }

  @override
  String get mediaGroupLead => 'Dirige el grupo';

  @override
  String get mediaGroupReadFailed => 'No se pudo consultar el grupo.';

  @override
  String get mediaGroupEmpty => 'No hay otros reproductores para agrupar.';

  @override
  String get mediaSpeakerSelection => 'Selección de altavoces';

  @override
  String pluginCloseWindow(String name) {
    return 'Cerrar $name';
  }

  @override
  String get pluginActions => 'Acciones';

  @override
  String get pluginKioskDrawer => 'Menú del kiosko';

  @override
  String get pluginToAssignAGestureOpenGesturesAndChooseRun =>
      'Para asignar un gesto, abre Gestos y selecciona Ejecutar una acción de plugin.';

  @override
  String get pluginShowInKioskDrawer => 'Mostrar en el menú del kiosko';

  @override
  String get pluginAlsoAvailableWhileLockedIfTheKioskDrawerIs =>
      'También está disponible durante el bloqueo si se permite el menú del kiosko.';

  @override
  String get pluginExposeToHomeAssistant => 'Publicar en Home Assistant';

  @override
  String get pluginAddsAButtonToTheKioskEsphomeDeviceRequires =>
      'Añade un botón al dispositivo ESPHome del kiosko. Requiere ESPHome y entidades nativas.';

  @override
  String get pluginSelectAnEntity => 'Seleccionar una entidad';

  @override
  String pluginChooseName(String name) {
    return 'Elegir $name';
  }

  @override
  String pluginConfigureName(String name) {
    return 'Configurar $name';
  }

  @override
  String get pluginPlugin => 'Plugin';

  @override
  String get pluginEnablePlugins => 'Activar plugins';

  @override
  String
  get pluginPluginsAddAdditionalCommunityDevelopedFeaturesToKioskSatellite =>
      'Los plugins añaden funciones desarrolladas por la comunidad a Kiosk Satellite.';

  @override
  String get pluginInstalledPlugins => 'Plugins instalados';

  @override
  String get pluginNoPluginsInstalledAddARepositoryToGetStarted =>
      'No hay plugins instalados. Añade un repositorio para empezar.';

  @override
  String get pluginDeveloperTools => 'Herramientas de desarrollo';

  @override
  String get pluginCreateAPlugin => 'Crear un plugin';

  @override
  String get pluginLearnHowToCreatePluginsWithTheHelloWorld =>
      'Aprende a crear plugins con la plantilla Hello World y la documentación.';

  @override
  String get pluginThisPluginIsNoLongerInstalled =>
      'Este plugin ya no está instalado.';

  @override
  String get pluginEnablePluginsToRunThisPlugin =>
      'Activa los plugins para ejecutar este plugin.';

  @override
  String get pluginEnableThisPluginFromItsEntryRowToRun =>
      'Activa este plugin desde su fila en la lista para ejecutarlo.';

  @override
  String pluginUninstallName(String name) {
    return '¿Desinstalar $name?';
  }

  @override
  String pluginUninstallNameDetail(String name) {
    return 'Desinstalar $name';
  }

  @override
  String pluginCheckForUpdatesForName(String name) {
    return 'Buscar actualizaciones de $name';
  }

  @override
  String pluginAboutName(String name) {
    return 'Acerca de $name';
  }

  @override
  String get pluginThisRemovesThePluginAndItsSettings =>
      'Elimina el plugin y su configuración.';

  @override
  String get pluginUninstall => 'Desinstalar';

  @override
  String get pluginNoUpdatesAvailable => 'No hay actualizaciones disponibles.';

  @override
  String get pluginThisPluginWasInstalledFromZipAndHasNo =>
      'Este plugin se instaló desde un ZIP y no tiene un README de repositorio.';

  @override
  String get pluginImageUnavailable => 'Imagen no disponible';

  @override
  String get pluginCouldNotOpenThisLink => 'No se pudo abrir este enlace.';

  @override
  String pluginEnableName(String name) {
    return 'Activar $name';
  }

  @override
  String get pluginAddPlugin => 'Añadir plugin';

  @override
  String get pluginInstallFromAGithubRepository =>
      'Instalar desde un repositorio de GitHub';

  @override
  String get pluginMakeSureYouTrustThePluginSAuthorAnd =>
      'Asegúrate de confiar en el autor del plugin y en su código antes de instalarlo.';

  @override
  String get pluginPreview => 'Vista previa';

  @override
  String get pluginInstalledVersion => 'Versión instalada';

  @override
  String get pluginAuthor => 'Autor';

  @override
  String get pluginLicense => 'Licencia';

  @override
  String get pluginPluginsRunCodeInsideKioskSatelliteAndCanAccess =>
      'Los plugins ejecutan código dentro de Kiosk Satellite y pueden acceder a los datos de la aplicación y a los permisos de Android concedidos. Un plugin defectuoso o malicioso puede exponer información privada o impedir que la aplicación funcione. Instala únicamente plugins de autores en los que confíes.';

  @override
  String get pluginNewPluginsStartDisabledUpdatesPreserveTheEnabledState =>
      'Los plugins nuevos se instalan desactivados. Las actualizaciones conservan su estado de activación y reinician automáticamente los plugins en ejecución.';

  @override
  String get pluginTrustAndUpdate => 'Confiar y actualizar';

  @override
  String get pluginTrustAndInstall => 'Confiar e instalar';

  @override
  String get pluginInstallFromZip => 'Instalar desde ZIP';

  @override
  String get pluginForDevelopersOnlyTestALocalBuild =>
      'Solo para desarrolladores: probar una compilación local';

  @override
  String get pluginPluginZip => 'ZIP del plugin';

  @override
  String get pluginPluginZipMustBeAtMost4Mb =>
      'El ZIP del plugin debe ocupar como máximo 4 MB';

  @override
  String get pluginCouldNotReadTheSelectedZip =>
      'No se pudo leer el ZIP seleccionado';

  @override
  String get pluginCharts => 'Gráficas';

  @override
  String get pluginReadings => 'Lecturas';

  @override
  String get pluginWaitingForSamples => 'Esperando muestras';

  @override
  String get pluginLatest => 'Más reciente';

  @override
  String get pluginSelected => 'Seleccionada';

  @override
  String get pluginNoDataYet => 'Todavía no hay datos';

  @override
  String get pluginTapOrDragToInspectSamplesDoubleTapTo =>
      'Toca o arrastra para examinar las muestras. Toca dos veces para seguir la más reciente.';

  @override
  String get pluginNoData => 'Sin datos';

  @override
  String get pluginOn => 'Activado';

  @override
  String get pluginEmpty => 'Vacío';

  @override
  String get pluginChartKeyboardHelp =>
      'Usa las flechas para examinar las muestras y Fin para ir a la más reciente.';

  @override
  String get pluginErrorAssetPath => 'La ruta del archivo no es válida';

  @override
  String get pluginErrorAssetMissing =>
      'El archivo no existe o está fuera de su paquete';

  @override
  String get pluginErrorAssetSymlink =>
      'El directorio de archivos no puede ser un enlace simbólico';

  @override
  String get pluginErrorAssetSymlinks =>
      'Los directorios de archivos no pueden ser enlaces simbólicos';

  @override
  String get pluginErrorAssetsIntegrity =>
      'Los archivos instalados no pasaron la verificación de integridad';

  @override
  String get pluginErrorAssetIntegrity =>
      'El archivo instalado no pasó la verificación de integridad';

  @override
  String get pluginErrorManifestMismatch =>
      'El manifiesto del paquete no coincide con el de la versión revisada';

  @override
  String get pluginErrorStagingExists =>
      'El directorio de preparación ya existe';

  @override
  String get pluginErrorCreateDirectory =>
      'No se puede crear el directorio del plugin';

  @override
  String get pluginErrorFileCount =>
      'Se admiten hasta 512 archivos por paquete';

  @override
  String get pluginErrorProtectFile =>
      'No se puede proteger el archivo del plugin';

  @override
  String get pluginErrorExpandedSize =>
      'El plugin descomprimido supera los 4 MB';

  @override
  String get pluginErrorManifestSize => 'El manifiesto supera los 32 KB';

  @override
  String get pluginErrorRequiredFiles =>
      'El paquete necesita kiosk-satellite-plugin.json, plugin.jar y LICENSE';

  @override
  String get pluginErrorNativeCapability =>
      'Las bibliotecas nativas requieren la capacidad native';

  @override
  String get pluginErrorNativeElf => 'La biblioteca ELF nativa no es válida';

  @override
  String get pluginErrorNativeAbi =>
      'La ABI de la biblioteca nativa no coincide con su directorio';

  @override
  String get pluginErrorDexOnly => 'plugin.jar solo debe contener archivos DEX';

  @override
  String get pluginErrorDexHeader => 'La cabecera DEX no es válida';

  @override
  String get pluginErrorDexSize => 'El DEX descomprimido supera los 4 MB';

  @override
  String get pluginErrorDexEmpty => 'El archivo DEX está vacío';

  @override
  String get pluginErrorDexMissing => 'plugin.jar no contiene classes.dex';

  @override
  String pluginErrorZipEntry(String name) {
    return 'Entrada ZIP inesperada o duplicada: $name';
  }

  @override
  String get pluginErrorRepositoryMismatch =>
      'La versión publicada del repositorio pertenece a otro plugin.';

  @override
  String get pluginErrorRepositoryUrl =>
      'Ingresa la URL de un repositorio público con el formato https://github.com/owner/repository';

  @override
  String get pluginErrorRepositoryPath =>
      'Usa la URL del repositorio sin la ruta de un archivo o una rama';

  @override
  String get pluginErrorDownloadOutsideGithub =>
      'La descarga del plugin se redirigió fuera de GitHub';

  @override
  String get pluginErrorInvalidRedirect =>
      'La redirección de GitHub no es válida';

  @override
  String get pluginErrorRepositoryNotFound =>
      'No se encontró el repositorio público, la versión estable, kiosk-satellite-plugin.json, README.md o un archivo de la versión publicada.';

  @override
  String get pluginErrorGithubLimited =>
      'GitHub rechazó la solicitud o se alcanzó su límite de solicitudes. Vuelve a intentarlo más tarde.';

  @override
  String get pluginErrorRepositorySize =>
      'El archivo del repositorio supera el límite de tamaño';

  @override
  String get pluginErrorTooManyRedirects =>
      'Demasiadas redirecciones de GitHub';

  @override
  String get pluginErrorStableRelease =>
      'GitHub no devolvió una versión estable publicada';

  @override
  String get pluginErrorReleaseTag => 'La etiqueta de la versión no es válida';

  @override
  String get pluginErrorManifestFile =>
      'El manifiesto kiosk-satellite-plugin.json no es válido';

  @override
  String get pluginErrorIdVersion =>
      'El ID o la versión del plugin no es válido';

  @override
  String get pluginErrorChecksumFilename =>
      'La suma de verificación de la versión o el nombre del paquete no es válido';

  @override
  String get pluginErrorGithubDigest =>
      'La suma de verificación de la versión debe coincidir con el SHA-256 del archivo en GitHub';

  @override
  String get pluginErrorTagRevision =>
      'GitHub no devolvió la revisión de la etiqueta de la versión';

  @override
  String get pluginErrorTrustAuthor =>
      'Confirma que confías en el autor del plugin';

  @override
  String get pluginErrorPreviewExpired =>
      'Esta vista previa caducó. Vuelve a consultar la vista previa del repositorio antes de instalar.';

  @override
  String get pluginErrorReviewedChecksum =>
      'El SHA-256 del paquete no coincide con la versión revisada';

  @override
  String get pluginErrorNotInstalled => 'El plugin no está instalado';

  @override
  String get pluginErrorUpdateZip =>
      'Este plugin se instaló desde un ZIP. Usa Instalar desde ZIP para actualizarlo.';

  @override
  String get pluginErrorAndroidOnly =>
      'Los plugins están disponibles en Android.';

  @override
  String pluginErrorGithubRequest(String status) {
    return 'La solicitud a GitHub falló ($status)';
  }

  @override
  String pluginErrorReleaseAsset(String name) {
    return 'La versión debe tener exactamente un archivo $name subido';
  }

  @override
  String pluginErrorAssetPublisher(String name) {
    return 'GitHub Actions debe publicar el archivo $name de la versión. No se admiten archivos subidos manualmente.';
  }

  @override
  String pluginErrorAssetSize(String name) {
    return 'El archivo $name de la versión supera el límite de tamaño o está vacío';
  }

  @override
  String pluginErrorAssetUrl(String name) {
    return 'La URL de la versión para $name no es válida';
  }

  @override
  String get pluginErrorNativeLibrary =>
      'El plugin no tiene una biblioteca nativa para la ABI de este dispositivo';

  @override
  String get pluginErrorCallbackTimeout =>
      'La respuesta del plugin tardó demasiado. Reinicia el kiosko si el plugin dejó tareas en ejecución.';

  @override
  String get pluginErrorEnableFirst => 'Activa primero el plugin';

  @override
  String get pluginErrorSaveState => 'No se puede guardar el estado del plugin';

  @override
  String get pluginErrorPackageHash =>
      'El hash del paquete instalado no es válido';

  @override
  String get pluginErrorChecksum => 'El SHA-256 del paquete no coincide';

  @override
  String get pluginErrorDifferentRepository =>
      'Este ID de plugin pertenece a otro repositorio. Desinstálalo antes de cambiar de origen.';

  @override
  String get pluginErrorRestartReplace =>
      'Este plugin no se detuvo correctamente. Reinicia Kiosk Satellite antes de reemplazarlo.';

  @override
  String get pluginErrorPluginLimit => 'Se pueden instalar hasta 8 plugins';

  @override
  String get pluginErrorAlreadyInstalled => 'Este paquete ya está instalado';

  @override
  String get pluginErrorLoadedIntegrity =>
      'El paquete cargado anteriormente no pasó la verificación de integridad. Reinicia Kiosk Satellite antes de reinstalarlo.';

  @override
  String get pluginErrorRemovePackage =>
      'No se puede eliminar el paquete sin usar';

  @override
  String get pluginErrorInstallPackage =>
      'No se puede instalar el paquete del plugin';

  @override
  String get pluginErrorUpdateCanceled =>
      'Se canceló la actualización porque el plugin no se detuvo correctamente. Reinicia Kiosk Satellite antes de volver a intentarlo.';

  @override
  String get pluginErrorVersionRetained => 'Se conservó la versión anterior.';

  @override
  String get pluginErrorRetainedDisabled =>
      'Se conservó la versión anterior, pero está desactivada. Reinicia Kiosk Satellite antes de activarla.';

  @override
  String get pluginErrorVersionRunning =>
      'La versión anterior vuelve a estar en ejecución.';

  @override
  String get pluginErrorEnablePlugins => 'Activa primero los plugins';

  @override
  String get pluginErrorRestartEnable =>
      'Este plugin no se detuvo correctamente. Reinicia Kiosk Satellite antes de activarlo.';

  @override
  String get pluginErrorInstalledIntegrity =>
      'El plugin instalado no pasó la verificación de integridad. Reinstálalo.';

  @override
  String get pluginErrorAndroidOld =>
      'La versión de Android es demasiado antigua';

  @override
  String get pluginErrorNativeIntegrity =>
      'Las bibliotecas nativas instaladas no pasaron la verificación de integridad';

  @override
  String get pluginErrorNativeFileIntegrity =>
      'La biblioteca nativa instalada no pasó la verificación de integridad';

  @override
  String pluginErrorReadInstalled(String error) {
    return 'No se puede leer el plugin instalado: $error';
  }

  @override
  String pluginErrorPreviousRestart(String error) {
    return 'No se pudo reiniciar la versión anterior: $error';
  }

  @override
  String pluginErrorUpdateFailed(String error, String recovery) {
    return 'La actualización del plugin falló: $error. $recovery';
  }

  @override
  String get pluginShizuku13OrLaterIsRequiredTapForSetup =>
      'Se requiere Shizuku 13 o posterior. Toca para ver las instrucciones de configuración.';

  @override
  String get pluginStartShizukuOnThisDeviceTapForSetupInstructions =>
      'Inicia Shizuku en este dispositivo. Toca para ver las instrucciones de configuración.';

  @override
  String get pluginShizukuGrantsKioskSatelliteShellOrRootAccessInstalled =>
      'Shizuku concede a Kiosk Satellite acceso shell o root. Los plugins instalados se ejecutan dentro de KS, así que concede acceso solo si confías en ellos.';

  @override
  String get pluginSetUp => 'Configurar';

  @override
  String get pluginGrantAccess => 'Conceder acceso';

  @override
  String get pluginApproveThePermissionRequestOnTheKiosk =>
      'Aprueba la solicitud de permiso en el kiosko.';

  @override
  String get pluginErrorInvalidId => 'El ID del plugin no es válido';

  @override
  String get pluginErrorInvalidVersion => 'La versión no es válida';

  @override
  String get pluginErrorEntryClass => 'La clase de entrada no es válida';

  @override
  String get pluginErrorManifestSchema =>
      'El esquema del manifiesto no es compatible';

  @override
  String get pluginErrorSdkVersion =>
      'Este plugin necesita otra versión del SDK';

  @override
  String get pluginErrorMinimumSdk =>
      'El SDK mínimo de Android debe ser al menos 24';

  @override
  String get pluginErrorCapability =>
      'La capacidad del plugin no es compatible';

  @override
  String get pluginErrorTooManySettings => 'Demasiados ajustes o comandos';

  @override
  String get pluginErrorSettingKey =>
      'La clave del ajuste no es válida o está duplicada';

  @override
  String get pluginErrorGroupsArray =>
      'Los grupos de visualización deben ser una lista';

  @override
  String get pluginErrorTooManyGroups => 'Demasiados grupos de visualización';

  @override
  String get pluginErrorUniqueGroups =>
      'Los grupos de visualización deben referirse a grupos de ajustes únicos';

  @override
  String get pluginErrorGroupReferences => 'Demasiadas referencias en el grupo';

  @override
  String get pluginErrorDuplicateReference =>
      'La referencia del grupo no es válida o está duplicada';

  @override
  String get pluginErrorCommandId =>
      'El ID del comando no es válido o está duplicado';

  @override
  String get pluginErrorUnknownSetting => 'El ajuste del plugin es desconocido';

  @override
  String get pluginErrorTextLength =>
      'Los ajustes de texto no deben superar los 512 caracteres';

  @override
  String get pluginErrorEntityId =>
      'Se esperaba un ID de entidad de Home Assistant';

  @override
  String get pluginErrorBoolean => 'Se esperaba un ajuste booleano';

  @override
  String get pluginErrorColor => 'Se esperaba un color RGB hexadecimal';

  @override
  String get pluginErrorNumber => 'Se esperaba un ajuste numérico';

  @override
  String get pluginErrorRange => 'El ajuste numérico está fuera de su rango';

  @override
  String get pluginErrorStep =>
      'El ajuste numérico no coincide con su incremento';

  @override
  String get pluginErrorSelection => 'El ajuste de selección no es válido';

  @override
  String get pluginErrorSelectionOption =>
      'La opción de selección es desconocida';

  @override
  String get pluginErrorSettingType => 'El tipo de ajuste no es compatible';

  @override
  String get pluginErrorInvalidManifest =>
      'El manifiesto del plugin no es válido';

  @override
  String pluginErrorAndroidApi(String version) {
    return 'El plugin necesita la API $version de Android';
  }

  @override
  String pluginErrorInvalidField(String field) {
    return 'El campo $field no es válido';
  }

  @override
  String get remoteDisableTitle => '¿Desactivar la administración remota?';

  @override
  String get remoteDisableHelp =>
      'ADVERTENCIA: Ya no podrás acceder a esta página. Para volver a activarla, usa el dispositivo o el interruptor de administración remota en Home Assistant.';

  @override
  String get remoteDisableConfirm => 'Desactivar';

  @override
  String get remoteCopyHelp => 'Selecciona la clave y cópiala manualmente.';

  @override
  String get remoteSaveSettingFailed =>
      'No se pudo guardar este ajuste. Inténtalo de nuevo.';

  @override
  String get remoteReconnecting => 'Reconectando…';

  @override
  String remoteConnectionLost(String name) {
    return 'Se perdió la conexión con $name. Esta página continuará automáticamente cuando se restablezca.';
  }

  @override
  String get remoteConnectionLostUnnamed =>
      'Se perdió la conexión con el kiosko. Esta página continuará automáticamente cuando se restablezca.';

  @override
  String get remoteReloadPage => 'Recargar página';

  @override
  String get remoteUpdated => 'Kiosk Satellite se actualizó';

  @override
  String remoteUpdatedHelp(String version, String build, String seconds) {
    return 'El dispositivo ahora usa la versión $version$build. Esta página corresponde a la versión anterior y se recargará en $seconds s.';
  }

  @override
  String remoteBuild(String build) {
    return ' (compilación $build)';
  }

  @override
  String get remoteReloadNow => 'Recargar ahora';

  @override
  String get remoteLogin => 'Iniciar sesión';

  @override
  String get remoteInvalidPassword => 'Contraseña incorrecta';

  @override
  String get remoteLoginThrottled =>
      'Demasiados intentos. Espera 5 minutos y vuelve a intentarlo.';

  @override
  String get deviceScreenOffPermission =>
      'Para apagar la pantalla, debes conceder un permiso una sola vez. La tableta está mostrando la pantalla para activar el administrador del dispositivo. Concede el permiso allí y vuelve a intentarlo.';

  @override
  String get deviceAdminInactive =>
      'El permiso de administrador del dispositivo no está activo.';

  @override
  String get deviceRestartOverlay =>
      'Para reiniciar, se necesita el permiso «Mostrar sobre otras aplicaciones» para que la aplicación pueda volver a abrirse. La pantalla para concederlo se está abriendo en el dispositivo. Concede el permiso allí y vuelve a intentarlo.';

  @override
  String get deviceRebootPermission =>
      'Para reiniciar el dispositivo, Kiosk Satellite debe estar configurado como propietario del dispositivo o tener una conexión autorizada con Shizuku.';

  @override
  String get deviceRestartAndroidOnly =>
      'El reinicio solo está disponible en Android.';

  @override
  String get deviceRestartShizukuRefused => 'Shizuku rechazó el reinicio';

  @override
  String deviceRestartFailed(String error) {
    return 'No se pudo reiniciar: $error';
  }

  @override
  String get overviewAttention => 'Requiere atención';

  @override
  String get overviewOpen => 'Abrir';

  @override
  String get overviewUpdate => 'Actualizar';

  @override
  String overviewInvitation(String name) {
    return '$name quiere dirigir este kiosko';
  }

  @override
  String get overviewInvitationHelp =>
      'Confirma en la pantalla del kiosko o en Administración de flota en ese dispositivo.';

  @override
  String get overviewOutdatedOne => '1 seguidor usa otra versión';

  @override
  String overviewOutdatedMany(String count) {
    return '$count seguidores usan otra versión';
  }

  @override
  String overviewSyncWaiting(String names, String version) {
    return '$names. La sincronización espera la versión $version.';
  }

  @override
  String get overviewThisRelease => 'actual';

  @override
  String get overviewUpdateAvailable => 'Actualización disponible';

  @override
  String overviewInstallHelp(String version) {
    return 'Kiosk Satellite $version está listo para instalar. La instalación se confirma en la pantalla de la tablet.';
  }

  @override
  String get overviewHaSetup => 'Home Assistant sin configurar';

  @override
  String get overviewHaSetupHelp =>
      'Conecta el kiosko a Home Assistant para cargar un panel de control.';

  @override
  String get overviewSetUp => 'Configurar';

  @override
  String get overviewHaNotValidated => 'Home Assistant sin validar';

  @override
  String get overviewHaNotValidatedHelp =>
      'La URL y el token no han superado una comprobación de conexión en esta ejecución. El kiosko vuelve a intentarlo cada 30 segundos.';

  @override
  String get overviewOpenSetup => 'Abrir configuración';

  @override
  String get overviewWakeStopped =>
      'Detección de palabras de activación detenida';

  @override
  String get overviewWakeReleased => 'El motor se detuvo.';

  @override
  String get overviewOpenVoice => 'Abrir Voice Satellite';

  @override
  String get overviewOpenService => 'Abrir servicio';

  @override
  String overviewPermissionMissing(String permission) {
    return 'Falta el permiso: $permission';
  }

  @override
  String get overviewQuick => 'Controles rápidos';

  @override
  String get overviewReload => 'Recargar página';

  @override
  String get overviewScreenOn => 'Encender pantalla';

  @override
  String get overviewScreenOff => 'Apagar pantalla';

  @override
  String get overviewSaverStart => 'Iniciar protector de pantalla';

  @override
  String get overviewSaverStop => 'Cerrar protector de pantalla';

  @override
  String get overviewCameraShow => 'Mostrar vista de cámaras';

  @override
  String get overviewCameraHide => 'Cerrar vista de cámaras';

  @override
  String get overviewSaverPostpone => 'Posponer protector de pantalla';

  @override
  String get overviewDnd => 'No molestar';

  @override
  String get overviewDndOn => 'No molestar activado';

  @override
  String get overviewSnapshot => 'Tomar captura';

  @override
  String get overviewCheckUpdates => 'Buscar actualizaciones';

  @override
  String get overviewRestartApp => 'Reiniciar aplicación';

  @override
  String get overviewRestartDevice => 'Reiniciar dispositivo';

  @override
  String get overviewExit => 'Salir de la aplicación';

  @override
  String get overviewBrightness => 'Brillo';

  @override
  String get overviewVolume => 'Volumen principal';

  @override
  String get overviewBrightnessGrant =>
      'El brillo está usando un ajuste limitado a la aplicación. Concede el permiso \"Modificar ajustes del sistema\" para controlar el brillo real de la pantalla.';

  @override
  String get overviewRestartQuestion =>
      '¿Reiniciar este dispositivo? Kiosk Satellite volverá a abrirse cuando arranque.';

  @override
  String get overviewRestart => 'Reiniciar';

  @override
  String get overviewNoSnapshot => 'No se recibió ninguna captura.';

  @override
  String get overviewSnapshotTitle => 'Captura de la cámara';

  @override
  String get overviewUpdateCheckFailed =>
      'No se pudieron buscar actualizaciones. ¿El dispositivo puede acceder a GitHub?';

  @override
  String get overviewLatest => 'Tienes la versión más reciente.';

  @override
  String overviewVersionAvailable(String version) {
    return 'La versión $version está disponible';
  }

  @override
  String get overviewInstallAttention => 'Instálala desde Requiere atención.';

  @override
  String get overviewNoViewsWithCameras =>
      'Ninguna vista tiene cámaras todavía. Primero agrega cámaras a una vista en Cámaras.';

  @override
  String get overviewShowViewFailed => 'No se pudo mostrar la vista';

  @override
  String get overviewAppVersion => 'Versión de la aplicación';

  @override
  String get overviewNotSetup => 'Sin configurar';

  @override
  String get overviewNotValidated => 'Sin validar';

  @override
  String get overviewCheckingFilter => 'Comprobando el filtro…';

  @override
  String get overviewValidated => 'Validado';

  @override
  String get overviewFilterUnavailable => 'Estado del filtro no disponible';

  @override
  String get overviewUnfiltered => 'Actualizaciones sin filtrar';

  @override
  String get overviewWatchingOne => 'Supervisando 1 entidad';

  @override
  String overviewWatchingMany(String count) {
    return 'Supervisando $count entidades';
  }

  @override
  String overviewFilterDisabled(String count) {
    return 'Filtrado desactivado, la vista usa $count entidades';
  }

  @override
  String get overviewWakeOff =>
      'Detección de palabras de activación desactivada';

  @override
  String overviewListeningFor(String words) {
    return 'Escuchando: $words';
  }

  @override
  String get overviewListening => 'Escuchando';

  @override
  String get overviewNotListening => 'Sin escuchar';

  @override
  String get overviewEntitiesProxy => 'Entidades y proxy Bluetooth';

  @override
  String get overviewEntitiesOnly => 'Solo entidades';

  @override
  String get overviewProxyOnly => 'Solo proxy Bluetooth';

  @override
  String get overviewWaitingHA => 'Esperando a Home Assistant';

  @override
  String get overviewNotRunning => 'Sin ejecutar';

  @override
  String get overviewRunningOne => 'En ejecución - 1 función';

  @override
  String overviewRunningMany(String count) {
    return 'En ejecución - $count funciones';
  }

  @override
  String overviewDownloading(String version) {
    return 'Descargando: $version';
  }

  @override
  String overviewNewVersion(String version) {
    return 'Nueva versión: $version';
  }

  @override
  String overviewCurrentVersion(String version) {
    return 'Al día: $version';
  }

  @override
  String get overviewCurrent => 'Al día';

  @override
  String overviewPluginAttribution(String name) {
    return 'Complemento $name';
  }

  @override
  String get overviewMuted => 'Silenciado';

  @override
  String get overviewBrowser => 'Detección en el navegador';

  @override
  String get overviewWakeWaiting =>
      'Esperando a Voice Satellite. La integración configura el motor y las palabras de activación cuando este dispositivo abre su panel de control.';

  @override
  String get overviewWakeDisabled =>
      'La detección de palabras de activación está desactivada. Actívala para recibir los modelos de Voice Satellite.';

  @override
  String get overviewMicBlocked =>
      'Micrófono bloqueado. Android no volverá a solicitar el permiso. Concédelo en los ajustes de la aplicación y vuelve a intentarlo.';

  @override
  String get overviewMicDeclined =>
      'Se rechazó el permiso del micrófono. La detección de palabras de activación lo necesita. Vuelve a intentarlo para solicitarlo de nuevo.';

  @override
  String get overviewMicLost =>
      'El micrófono dejó de funcionar. Vuelve a intentarlo o recarga la página.';

  @override
  String get overviewModelsUnavailable =>
      'No se pudieron descargar los modelos de Home Assistant. Vuelve a intentarlo cuando esté accesible.';

  @override
  String get overviewCrashed =>
      'El detector fallaba repetidamente en este dispositivo y se detuvo. Voice Satellite está escuchando desde el navegador. Vuelve a intentarlo o reinicia la aplicación.';

  @override
  String get overviewWakeFailed =>
      'No se pudo iniciar el motor de palabras de activación. Vuelve a intentarlo o recarga la página.';

  @override
  String overviewNativeUnavailable(String engine) {
    return 'No hay un motor nativo para $engine. Voice Satellite mantiene la detección en el navegador.';
  }

  @override
  String get overviewNativeListening => 'Escuchando con el motor nativo';

  @override
  String get overviewSuspended =>
      'Listo (en pausa durante una interacción de voz)';

  @override
  String get overviewCpu => 'CPU';

  @override
  String get overviewMemory => 'RAM';

  @override
  String get overviewTemperature => 'Temp.';

  @override
  String overviewMemoryFree(String amount) {
    return '$amount GB libres';
  }

  @override
  String overviewMetricPercent(String value) {
    return '$value%';
  }

  @override
  String overviewMetricDegrees(String value) {
    return '$value°C';
  }

  @override
  String get overviewNoScreenshot => 'Sin captura de pantalla';

  @override
  String get overviewStill => 'Fija';

  @override
  String get overviewLive => 'En vivo';

  @override
  String get overviewFullSize => 'Tamaño completo';

  @override
  String get overviewLiveInterval => 'En vivo, cada 5 segundos';

  @override
  String overviewTaken(String age) {
    return 'Captura: $age';
  }

  @override
  String overviewCameraViewNamed(String name) {
    return 'Vista de cámaras: $name';
  }

  @override
  String get overviewCameraView => 'Vista de cámaras';

  @override
  String get overviewScreenOffState => 'Pantalla apagada';

  @override
  String get overviewGoView => 'Ir a una vista';

  @override
  String get overviewLoadingViews => 'Cargando vistas…';

  @override
  String get overviewPickView => 'Elige una vista del panel de control…';

  @override
  String get overviewDefaultView => 'Vista predeterminada';

  @override
  String get overviewNoDashboards => 'No se encontraron paneles de control';

  @override
  String get overviewViewsUnavailable => 'Vistas no disponibles';

  @override
  String get screensaverNoPhotos =>
      'No hay fotos seleccionadas. Elige algunas en Configuración.';

  @override
  String get screensaverNoFolder =>
      'No hay ninguna carpeta seleccionada. Elige una en Configuración.';

  @override
  String screensaverFolderEmpty(String folder) {
    return 'No hay fotos ni videos en $folder';
  }

  @override
  String screensaverFolderUnreadable(String folder) {
    return 'No se pudo leer $folder. ¿Se ha concedido el permiso de acceso al contenido multimedia?';
  }

  @override
  String get screensaverReadPhotosFailed => 'No se pudieron leer las fotos.';

  @override
  String get screensaverImmichNotReady =>
      'Immich no está conectado. Valídalo en Configuración.';

  @override
  String get screensaverNoMediaMatch =>
      'No hay contenido multimedia que coincida con el origen y los filtros.';

  @override
  String get screensaverNoMediaSource =>
      'No hay contenido multimedia en el origen seleccionado.';

  @override
  String get screensaverImmichUnreachable =>
      'No se pudo conectar con el servidor de Immich.';

  @override
  String screensaverRetryNotice(String error) {
    return '$error Se reintentará automáticamente.';
  }

  @override
  String get screensaverVideosTooLarge =>
      'Todos los videos de esta lista son demasiado grandes para que este dispositivo los reproduzca.';

  @override
  String get settingLauncherEnabledTitle => 'Activar lanzador de aplicaciones';

  @override
  String get settingLauncherEnabledDescription =>
      'Abre desde el kiosko una selección de aplicaciones instaladas.';

  @override
  String get settingLauncherAppsDescription =>
      'Las aplicaciones que ofrece el lanzador.';

  @override
  String get settingLauncherAutoReturnTitle => 'Volver automáticamente';

  @override
  String get settingLauncherAutoReturnDescription =>
      'Vuelve al kiosko cuando la otra aplicación lleva un tiempo sin recibir toques.';

  @override
  String get settingLauncherAutoReturnSecondsTitle =>
      'Volver después de (segundos)';

  @override
  String get settingLauncherAutoReturnSecondsDescription =>
      'Tiempo sin tocar la otra aplicación antes de volver al kiosko.';

  @override
  String get launcherOverlayHeld =>
      'Kiosk Satellite puede volver al primer plano y detectar toques en la otra aplicación.';

  @override
  String get launcherOverlayMissing =>
      'Sin este permiso, el kiosko no puede volver por sí solo ni detectar toques en la otra aplicación.';

  @override
  String get launcherOverlayRemote =>
      'Sin este permiso, el kiosko no puede volver por sí solo ni detectar toques en la otra aplicación. La pantalla para concederlo aparece en la tablet.';

  @override
  String get launcherBatteryMissing =>
      'Android puede pausar la aplicación mientras la otra está abierta. Si el temporizador se pausa, el kiosko no vuelve.';

  @override
  String get launcherBatteryRemote =>
      'Android puede pausar la aplicación mientras la otra está abierta. Si el temporizador se pausa, el kiosko no vuelve. El diálogo para conceder el permiso aparece en la tablet.';

  @override
  String get launcherPermissionsSearch =>
      'Los permisos que necesita Volver automáticamente.';

  @override
  String get settingCameraEnabledTitle => 'Activar cámara';

  @override
  String get settingCameraEnabledDescription =>
      'El uso de la cámara aumenta la carga de CPU y el calor, lo que puede reducir la vida útil de la batería y del dispositivo.';

  @override
  String get settingCameraDeviceTitle => 'Cámara';

  @override
  String get settingCameraDeviceDescription => 'Cámara que se usará.';

  @override
  String get settingCameraSnapshotResolutionTitle =>
      'Resolución de las capturas';

  @override
  String get settingCameraSnapshotResolutionDescription =>
      'Una resolución mayor mejora la nitidez, pero consume más CPU y ancho de banda.';

  @override
  String get settingCameraDisableDetectionSnapshotsTitle =>
      'Desactivar capturas al detectar actividad';

  @override
  String get settingCameraDisableDetectionSnapshotsDescription =>
      'Evita las capturas automáticas por detección. La detección de movimiento, rostros, presencia y gestos sigue funcionando. Las solicitudes manuales y las capturas continuas pueden seguir tomando imágenes.';

  @override
  String get settingCameraSnapshotsTitle => 'Capturas continuas';

  @override
  String get settingCameraSnapshotsDescription =>
      'Publica una nueva captura de la cámara en Home Assistant a intervalos fijos.';

  @override
  String get settingCameraSnapshotIntervalTitle => 'Intervalo entre capturas';

  @override
  String get settingCameraSnapshotIntervalDescription =>
      'Segundos entre capturas.';

  @override
  String get cameraFront => 'Frontal';

  @override
  String get cameraBack => 'Trasera';

  @override
  String get cameraOnlyCamera => 'La única cámara de este dispositivo.';

  @override
  String get settingMotionSensorTitle => 'Sensor de movimiento';

  @override
  String get settingMotionSensorDescription =>
      'Publica el movimiento como un sensor de Home Assistant. ADVERTENCIA: Mantiene la cámara encendida permanentemente, incluso con la pantalla apagada.';

  @override
  String get settingMotionSensorOffDelayTitle => 'Dejar de detectar después de';

  @override
  String get settingMotionSensorOffDelayDescription =>
      'Segundos sin movimiento antes de que el sensor deje de indicar movimiento.';

  @override
  String get settingMotionFpsTitle =>
      'Frecuencia de cuadros para detectar movimiento';

  @override
  String get settingMotionFpsDescription =>
      'Cuadros por segundo que la cámara analiza para detectar movimiento. Un valor menor consume menos CPU. Con 2 es suficiente para detectar que alguien se acerca.';

  @override
  String get settingMotionStartDelayTitle => 'Retraso de inicio';

  @override
  String get settingMotionStartDelayDescription =>
      'Ignora el movimiento durante este tiempo después de iniciar la cámara. Útil en dispositivos cuya cámara se mueve físicamente al abrirse.';

  @override
  String get settingMotionSensitivityTitle => 'Sensibilidad de movimiento';

  @override
  String get settingMotionSensitivityDescription =>
      'Los valores más altos detectan movimientos más pequeños. El valor 1 requiere un cambio grande en la imagen. El valor 100 responde al movimiento más leve.';

  @override
  String get cameraMotionPage => 'Sensor de movimiento';

  @override
  String get cameraMotionHint =>
      'Sensor de movimiento de Home Assistant y ajustes compartidos de detección';

  @override
  String get cameraNoCamera => 'No se detectó ninguna cámara';

  @override
  String get cameraNoCameraHelp =>
      'Este dispositivo no informa de ninguna cámara utilizable.';

  @override
  String get cameraCameraPermission => 'Falta el permiso de cámara';

  @override
  String get cameraCameraPermissionHelp =>
      'Sin este permiso no se puede usar la cámara. El diálogo para concederlo aparece en la pantalla de la tableta.';

  @override
  String get cameraGrantOnDevice => 'Conceder en el dispositivo';

  @override
  String get cameraCameraBlocked =>
      'Bloqueado. Android no volverá a preguntar. Permítelo en la configuración de la aplicación.';

  @override
  String get cameraCameraNeeded =>
      'Sin este permiso no se puede usar la cámara.';

  @override
  String get cameraAppSettings => 'Configuración de la aplicación';

  @override
  String get cameraLatest => 'Última captura';

  @override
  String get cameraNoSnapshot => 'Aún no hay capturas.';

  @override
  String get cameraImageAlt => 'Última captura de la cámara';

  @override
  String get cameraTakeSnapshot => 'Tomar captura';

  @override
  String get cameraSnapshotFailed => 'No se pudo tomar la captura.';

  @override
  String cameraSnapshotError(String error) {
    return 'No se pudo tomar la captura: $error';
  }

  @override
  String get cameraCameraDisabled =>
      'La cámara está desactivada en la configuración de Cámara.';

  @override
  String get cameraSnapshotBusy => 'Ya hay una captura en curso.';

  @override
  String get cameraPermissionDenied =>
      'No se ha concedido el permiso de cámara.';

  @override
  String get cameraDetectionDisabled =>
      'Las capturas por detección están desactivadas.';

  @override
  String get cameraNoImage => 'La cámara no devolvió ninguna imagen.';

  @override
  String get cameraTimedOut => 'La cámara no respondió a tiempo.';

  @override
  String get cameraBackground =>
      'La cámara no está disponible mientras la aplicación está en segundo plano.';

  @override
  String get cameraJustNow => 'hace un momento';

  @override
  String cameraSecondsAgo(String count) {
    return 'hace $count segundos';
  }

  @override
  String get cameraMinuteAgo => 'hace 1 minuto';

  @override
  String cameraMinutesAgo(String count) {
    return 'hace $count minutos';
  }

  @override
  String get cameraHourAgo => 'hace 1 hora';

  @override
  String cameraHoursAgo(String count) {
    return 'hace $count horas';
  }

  @override
  String get cameraDayAgo => 'hace 1 día';

  @override
  String cameraDaysAgo(String count) {
    return 'hace $count días';
  }

  @override
  String get cameraStatusHeading => 'Estado de la transmisión';

  @override
  String get cameraClientsHeading => 'Clientes conectados';

  @override
  String get cameraUnavailable => 'No disponible';

  @override
  String get cameraStopped => 'Detenida';

  @override
  String get cameraStreaming => 'Transmitiendo';

  @override
  String get cameraIdle => 'En espera';

  @override
  String get cameraConnected => 'Conectado';

  @override
  String get cameraChecking => 'Comprobando...';

  @override
  String get cameraCheckingStatus =>
      'Comprobando el estado de la transmisión...';

  @override
  String get cameraStatusUnavailable =>
      'Estado de la transmisión no disponible.';

  @override
  String get cameraListenerStopped => 'El servidor está detenido.';

  @override
  String cameraViewer(String count, String resolution) {
    return '$count espectador conectado. Video real: $resolution.';
  }

  @override
  String cameraViewers(String count, String resolution) {
    return '$count espectadores conectados. Video real: $resolution.';
  }

  @override
  String get cameraReady =>
      'Listo. El codificador se inicia cuando se conecta un espectador.';

  @override
  String cameraFallback(String requested, String actual) {
    return 'Se solicitó $requested y la cámara proporcionó $actual.';
  }

  @override
  String cameraAudioError(String error) {
    return 'Audio: $error';
  }

  @override
  String get cameraAudioPaused =>
      'Audio en pausa mientras el navegador usa el micrófono.';

  @override
  String get cameraAudioStreaming => 'Transmitiendo audio del micrófono.';

  @override
  String get cameraAudioIdle => 'Audio del micrófono en espera.';

  @override
  String cameraDiscoveryError(String error) {
    return 'Detección ONVIF: $error';
  }

  @override
  String get cameraOnvifUrl => 'URL de ONVIF';

  @override
  String get cameraStreamUrl => 'URL de la transmisión';

  @override
  String get cameraWaitingAddress => 'Esperando una dirección de red';

  @override
  String get cameraClientsUnavailable =>
      'Información de clientes no disponible.';

  @override
  String get cameraNoClients => 'No hay clientes conectados.';

  @override
  String cameraClientDetails(String status, String transport, String port) {
    return '$status · $transport · Puerto $port';
  }

  @override
  String cameraConnectedFor(String duration) {
    return 'Conectado durante $duration';
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
      'Establece un nombre de usuario y una contraseña de transmisión para activar la autenticación.';

  @override
  String get cameraPortWaiting => 'Esperando a que se libere el puerto RTSP.';

  @override
  String get cameraListenerFailed => 'No se pudo iniciar el servidor RTSP.';

  @override
  String get settingCameraRtspEnabledTitle =>
      'Activar transmisión de la cámara';

  @override
  String get settingCameraRtspEnabledDescription =>
      'Comparte video H.264 con clientes RTSP u ONVIF. El video se codifica solo mientras hay un espectador conectado. Se prefiere la codificación por hardware y se usa software cuando es necesario. Usa la cámara elegida en la configuración de Cámara.';

  @override
  String get settingCameraStreamingProtocolTitle => 'Protocolo de transmisión';

  @override
  String get settingCameraStreamingProtocolDescription =>
      'ONVIF permite que los clientes compatibles descubran la cámara y se conecten a su transmisión.';

  @override
  String get settingCameraRtspPortTitle => 'Puerto';

  @override
  String get settingCameraRtspPortDescription => 'Puerto del servidor RTSP.';

  @override
  String get settingCameraOnvifPortTitle => 'Puerto';

  @override
  String get settingCameraOnvifPortDescription => 'Puerto del servidor ONVIF.';

  @override
  String get settingCameraRtspResolutionTitle => 'Resolución';

  @override
  String get settingCameraRtspResolutionDescription =>
      'Tamaños de transmisión compatibles con la cámara y el codificador elegidos. El video sigue la orientación del dispositivo.';

  @override
  String get settingCameraRtspAnalysisTitle =>
      'Analizar movimiento durante la transmisión';

  @override
  String get settingCameraRtspAnalysisDescription =>
      'Mantiene disponibles la detección de movimiento, rostros y gestos de manos mientras hay espectadores conectados. Desactivarlo puede permitir resoluciones mayores. Las capturas usan entonces cuadros de video con la resolución de transmisión.';

  @override
  String get settingCameraRtspFpsTitle => 'Frecuencia de cuadros';

  @override
  String get settingCameraRtspFpsDescription =>
      'Cuadros de video por segundo deseados. El movimiento conserva su frecuencia de análisis independiente. La frecuencia real depende de la cámara.';

  @override
  String get settingCameraRtspBitrateTitle => 'Tasa de bits';

  @override
  String get settingCameraRtspBitrateDescription =>
      'Tasa de bits de video deseada. Un valor mayor mejora el detalle y consume más ancho de banda.';

  @override
  String get settingCameraRtspAudioTitle => 'Incluir audio del micrófono';

  @override
  String get settingCameraRtspAudioDescription =>
      'Incluye audio del micrófono en la transmisión de la cámara. Usa la configuración del micrófono. ADVERTENCIA: Aumenta el consumo de CPU.';

  @override
  String get settingCameraRtspAuthTitle => 'Exigir autenticación';

  @override
  String get settingCameraRtspAuthDescription =>
      'Requiere un nombre de usuario y una contraseña para ver la transmisión. La autenticación no activa el cifrado.';

  @override
  String get settingCameraRtspUsernameTitle => 'Nombre de usuario';

  @override
  String get settingCameraRtspUsernameDescription =>
      'Nombre de usuario para los clientes de transmisión.';

  @override
  String get settingCameraRtspPasswordTitle => 'Contraseña';

  @override
  String get settingCameraRtspPasswordDescription =>
      'Establece una contraseña para iniciar la transmisión con autenticación.';

  @override
  String get cameraStreamingPage => 'Transmisión RTSP y ONVIF';

  @override
  String get cameraStreamingHint =>
      'Comparte la cámara del dispositivo mediante RTSP u ONVIF';

  @override
  String get cameraPortError =>
      'Introduce un número de puerto entero entre 1024 y 65535.';

  @override
  String get cameraUsernameError =>
      'Usa entre 1 y 64 caracteres sin espacios, comillas, dos puntos ni barras invertidas.';

  @override
  String get cameraNoSizes => 'No hay tamaños compatibles disponibles';

  @override
  String get cameraNoSizesHelp =>
      'No hay tamaños compatibles disponibles. Revisa la conexión de la cámara.';

  @override
  String get cameraResolutionSupport => 'Compatibilidad de resoluciones';

  @override
  String get cameraCheckingSizes =>
      'Comprobando la compatibilidad de la cámara y del codificador H.264...';

  @override
  String get cameraSupportedSizes =>
      'Solo se muestran los tamaños compatibles con la cámara y el codificador H.264 con la configuración actual de transmisión.';

  @override
  String cameraExtraSizes(String sizes) {
    return 'Desactiva Analizar movimiento durante la transmisión para usar también $sizes.';
  }

  @override
  String get cameraAnalysisOff =>
      'La detección de movimiento, rostros y gestos de manos se pausa mientras hay espectadores conectados. Las capturas usan cuadros de video con la resolución de transmisión.';

  @override
  String cameraRejectedSizes(String sizes) {
    return 'El codificador no puede usar $sizes con esta configuración.';
  }

  @override
  String cameraRejectedCount(String count) {
    return 'Se excluyen $count tamaños de cámara porque el codificador no puede usarlos con esta configuración.';
  }

  @override
  String get cameraCaptureRejected =>
      'Otros tamaños de cámara no están disponibles con la configuración actual de captura.';

  @override
  String get cameraOverlaysHeading => 'Superposiciones';

  @override
  String get settingCameraRtspDateTimeTitle => 'Mostrar fecha y hora';

  @override
  String get settingCameraRtspDateTimeDescription =>
      'Muestra la fecha y hora del dispositivo en la esquina superior izquierda del video con su formato de fecha y de 12 o 24 horas.';

  @override
  String get settingCameraRtspDateTimeBackgroundTitle => 'Fondo negro';

  @override
  String get settingCameraRtspDateTimeBackgroundDescription =>
      'Agrega un fondo negro detrás de la fecha y hora para facilitar la lectura.';

  @override
  String get settingCameraRtspTlsTitle => 'Cifrar transmisión';

  @override
  String get settingCameraRtspTlsDescription =>
      'Usa TLS para cifrar el video y el audio. Requiere un visor compatible.';

  @override
  String get cameraStreamsNameRequired => 'Escribe un nombre.';

  @override
  String get cameraStreamsBaseUrlRequired =>
      'Escribe una URL base HTTP o HTTPS válida.';

  @override
  String get cameraStreamsServerNotFound => 'No se encontró el servidor.';

  @override
  String get cameraStreamsInvalidStreamList =>
      'Go2RTC devolvió una lista de transmisiones no válida.';

  @override
  String get cameraStreamsKindRequired =>
      'Elige una transmisión Go2RTC, una URL WHEP o una cámara de Home Assistant.';

  @override
  String get cameraStreamsProtocolRequired =>
      'Elige Automático, WebRTC, HLS o MJPEG.';

  @override
  String get cameraStreamsServerRequired => 'Elige un servidor válido.';

  @override
  String get cameraStreamsStreamRequired =>
      'Escribe el nombre de la transmisión.';

  @override
  String get cameraStreamsEntityRequired =>
      'Escribe una entidad que empiece por camera.';

  @override
  String get cameraStreamsWhepRequired => 'Escribe una URL WHEP válida.';

  @override
  String get cameraStreamsCameraNotFound => 'No se encontró la cámara.';

  @override
  String get cameraStreamsListRequired =>
      'La selección de cámaras debe ser una lista.';

  @override
  String get cameraStreamsViewCount =>
      'La vista debe contener entre 1 y 12 cámaras.';

  @override
  String get cameraStreamsRepeatedCamera =>
      'Una cámara solo puede aparecer una vez en cada vista.';

  @override
  String get cameraStreamsUnknownViewCamera =>
      'La vista contiene una cámara desconocida.';

  @override
  String get cameraStreamsUniqueViewName =>
      'Usa un nombre diferente para la vista.';

  @override
  String get cameraStreamsGridRange =>
      'La cuadrícula debe tener entre 1 y 12 espacios.';

  @override
  String get cameraStreamsGridTooSmall =>
      'La cuadrícula tiene menos espacios que cámaras.';

  @override
  String get cameraStreamsViewNotFound => 'No se encontró la vista.';

  @override
  String get cameraStreamsDefaultViewDelete =>
      'No se puede eliminar la vista predeterminada. Quita todas sus cámaras para dejarla vacía.';

  @override
  String get cameraStreamsViewEmpty => 'La vista no tiene cámaras.';

  @override
  String cameraStreamsHaReadFailed(String error) {
    return 'No se pudo leer Home Assistant: $error';
  }

  @override
  String cameraStreamsConnectFailed(String server, String error) {
    return 'No se pudo conectar a $server: $error';
  }

  @override
  String get cameraStreamsHaUnavailable =>
      'Home Assistant no está configurado o no responde.';

  @override
  String cameraStreamsHttpError(String status) {
    return 'Go2RTC devolvió HTTP $status';
  }

  @override
  String get cameraStreamsImportHa => 'Importar cámaras de Home Assistant';

  @override
  String get cameraStreamsImportHaHelp =>
      'Añade todas las cámaras de Home Assistant y las reproduce mediante WebRTC, HLS o MJPEG. Si vuelves a importar, se incorporan las cámaras nuevas.';

  @override
  String get cameraStreamsImportFailed => 'No se pudo importar';

  @override
  String get cameraStreamsImportComplete => 'Importación completada';

  @override
  String cameraStreamsImportCounts(String added, String missing) {
    return '$added añadidas, $missing no disponibles.';
  }

  @override
  String get settingCameraAllowH265Title => 'Permitir transmisiones H.265';

  @override
  String get settingCameraAllowH265Description =>
      'Reproduce las transmisiones H.265 sin convertirlas. Si el dispositivo no puede decodificar H.265, muestra una imagen en blanco.';

  @override
  String get settingCameraPreferMseTitle => 'Preferir MSE en lugar de WebRTC';

  @override
  String get settingCameraPreferMseDescription =>
      'Usa MSE primero para las cámaras Go2RTC. Para dispositivos que no pueden reproducir WebRTC. Añade uno o dos segundos de retraso.';

  @override
  String get settingCameraPreferHlsTitle => 'Preferir HLS en lugar de WebRTC';

  @override
  String get settingCameraPreferHlsDescription =>
      'Usa HLS primero para las cámaras de Home Assistant. Para dispositivos que no pueden reproducir WebRTC. Añade unos segundos de retraso.';

  @override
  String get settingCameraSingleAudioTitle =>
      'Reproducir sonido con una sola cámara';

  @override
  String get settingCameraSingleAudioDescription =>
      'Reproduce el sonido de la cámara cuando solo hay una en pantalla. Las cuadrículas con varias cámaras permanecen en silencio.';

  @override
  String get settingCameraPinchZoomTitle =>
      'Pellizcar para ampliar una sola cámara';

  @override
  String get settingCameraPinchZoomDescription =>
      'Amplía la imagen con dos dedos cuando solo hay una cámara en pantalla. Arrastra para desplazarte y toca dos veces para restablecer la imagen.';

  @override
  String get settingCameraAutoDismissSecondsTitle =>
      'Cerrar automáticamente después de';

  @override
  String get settingCameraAutoDismissSecondsDescription =>
      'Cierra automáticamente una vista de cámaras abierta. Con 0 permanece abierta. No afecta al protector de pantalla de cámaras.';

  @override
  String get cameraStreamsPlayback => 'Reproducción';

  @override
  String get cameraStreamsOff => 'Desactivado';

  @override
  String cameraStreamsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get cameraStreamsGridHelp =>
      'Las cuadrículas con varias cámaras solo muestran video. En dispositivos de baja potencia, usa transmisiones Go2RTC de menor resolución en las vistas y, si lo deseas, una transmisión diferente para pantalla completa.';

  @override
  String get cameraStreamsServers => 'Servidores Go2RTC';

  @override
  String get cameraStreamsImportStreams => 'Importar transmisiones';

  @override
  String get cameraStreamsDeleteServer => 'Eliminar servidor';

  @override
  String get cameraStreamsAddServer => 'Añadir servidor Go2RTC';

  @override
  String get cameraStreamsAddServerHelp =>
      'Conéctate a un servidor e importa sus transmisiones.';

  @override
  String get cameraStreamsEditServer => 'Editar servidor';

  @override
  String get cameraStreamsName => 'Nombre';

  @override
  String get cameraStreamsBaseUrl => 'URL base';

  @override
  String get cameraStreamsUsername => 'Nombre de usuario (opcional)';

  @override
  String get cameraStreamsNewPassword =>
      'Nueva contraseña (dejar en blanco para conservarla)';

  @override
  String get cameraStreamsPassword => 'Contraseña (opcional)';

  @override
  String get cameraStreamsInvalidCertificate =>
      'Permitir certificado TLS no válido';

  @override
  String get cameraStreamsSaveServerFailed => 'No se pudo guardar el servidor';

  @override
  String get cameraStreamsDeleteServerHelp =>
      'Sus cámaras se eliminarán de todas las vistas.';

  @override
  String get cameraStreamsCameras => 'Cámaras';

  @override
  String get cameraStreamsNoCameras => 'No hay cámaras configuradas';

  @override
  String get cameraStreamsNoCamerasHelp =>
      'Importa cámaras de Home Assistant o Go2RTC, o añade una manualmente.';

  @override
  String get cameraStreamsDeleteCamera => 'Eliminar cámara';

  @override
  String get cameraStreamsAddManually => 'Añadir cámara manualmente';

  @override
  String get cameraStreamsAddManuallyHelp =>
      'Usa el nombre de una transmisión Go2RTC, una URL WHEP o una entidad de cámara de Home Assistant.';

  @override
  String get cameraStreamsUnknownCamera => 'Cámara desconocida';

  @override
  String get cameraStreamsUnknownServer => 'Servidor desconocido';

  @override
  String get cameraStreamsMissing => ' (no disponible)';

  @override
  String get cameraStreamsAddCamera => 'Añadir cámara';

  @override
  String get cameraStreamsEditCamera => 'Editar cámara';

  @override
  String get cameraStreamsType => 'Tipo';

  @override
  String get cameraStreamsGo2RtcStream => 'Transmisión Go2RTC';

  @override
  String get cameraStreamsDirectWhep => 'URL WHEP directa';

  @override
  String get cameraStreamsHaCamera => 'Cámara de Home Assistant';

  @override
  String get cameraStreamsEntity => 'Entidad de cámara';

  @override
  String get cameraStreamsProtocol => 'Protocolo preferido';

  @override
  String get cameraStreamsAuto => 'Automático';

  @override
  String get cameraStreamsServer => 'Servidor';

  @override
  String get cameraStreamsStreamName => 'Nombre de la transmisión';

  @override
  String get cameraStreamsGo2RtcStreamName => 'Nombre de la transmisión Go2RTC';

  @override
  String get cameraStreamsFullscreen =>
      'Transmisión a pantalla completa (opcional)';

  @override
  String get cameraStreamsWhep => 'URL WHEP';

  @override
  String get cameraStreamsSaveCameraFailed => 'No se pudo guardar la cámara';

  @override
  String get cameraStreamsDeleteCameraHelp =>
      'Se eliminará de todas las vistas.';

  @override
  String get cameraStreamsLoadFailed => 'No se pudieron cargar las cámaras.';

  @override
  String get cameraStreamsViews => 'Vistas';

  @override
  String get cameraStreamsEmptyView => 'Todavía no hay cámaras';

  @override
  String get cameraStreamsNamesShown => 'Nombres visibles';

  @override
  String get cameraStreamsNamesHidden => 'Nombres ocultos';

  @override
  String get cameraStreamsShowView => 'Mostrar vista';

  @override
  String get cameraStreamsDeleteView => 'Eliminar vista';

  @override
  String get cameraStreamsCreateView => 'Crear vista de cámaras';

  @override
  String get cameraStreamsAddFirst => 'Añade una cámara primero.';

  @override
  String get cameraStreamsChooseCameras => 'Elige y ordena hasta 12 cámaras.';

  @override
  String get cameraStreamsShowFailed => 'No se pudo mostrar la vista';

  @override
  String get cameraStreamsShowFailedRemote => 'No se pudo mostrar la vista';

  @override
  String get cameraStreamsEditView => 'Editar vista';

  @override
  String get cameraStreamsShowNames => 'Mostrar nombres de cámaras';

  @override
  String get cameraStreamsShowNamesHelp =>
      'Muestra una etiqueta sobre cada cámara.';

  @override
  String get cameraStreamsGrid => 'Cuadrícula';

  @override
  String cameraStreamsOneCamera(String count) {
    return '$count cámara';
  }

  @override
  String cameraStreamsManyCameras(String count) {
    return '$count cámaras';
  }

  @override
  String get cameraStreamsInView => 'En esta vista';

  @override
  String get cameraStreamsAvailable => 'Disponibles';

  @override
  String cameraStreamsPosition(String position) {
    return 'Posición $position';
  }

  @override
  String get cameraStreamsMissingGo2Rtc => 'No disponible en Go2RTC';

  @override
  String get cameraStreamsSaveViewFailed => 'No se pudo guardar la vista';

  @override
  String cameraStreamsDeleteNamed(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get cameraStreamsCannotUndo => 'Esta acción no se puede deshacer.';

  @override
  String get cameraStreamsShow => 'Mostrar';

  @override
  String get cameraStreamsStop => 'Detener';

  @override
  String get settingAnalyticsBasicTitle => 'Estadísticas básicas';

  @override
  String get settingAnalyticsBasicDescription =>
      'Información del dispositivo, como el modelo, la versión de Android, la versión de la aplicación, el tamaño de pantalla y el idioma.';

  @override
  String get settingAnalyticsUsageTitle => 'Uso';

  @override
  String get settingAnalyticsUsageDescription =>
      'Detalles de lo que usas con Kiosk Satellite.';

  @override
  String get settingAnalyticsDiagnosticsTitle => 'Diagnóstico';

  @override
  String get settingAnalyticsDiagnosticsDescription =>
      'Comparte informes de fallos cuando se producen errores inesperados.';

  @override
  String get deviceAnalyticsPage => 'Estadísticas de Kiosk Satellite';

  @override
  String get deviceAnalyticsIntro =>
      'Comparte información anónima de tu instalación para mejorar Kiosk Satellite y ayudar a decidir qué dispositivos y funciones necesitan atención.';

  @override
  String get deviceAnalyticsLearn => 'Cómo procesamos tus datos';

  @override
  String get deviceAnalyticsLearnHelp =>
      'Qué envían las estadísticas de Kiosk Satellite y qué información nunca se envía.';

  @override
  String get deviceExportConfig => 'Exportar configuración';

  @override
  String get deviceExportConfigHelp =>
      'Guarda toda la configuración y el almacenamiento local de la página en un archivo.';

  @override
  String get deviceExportConfigRemoteHelp =>
      'Descarga toda la configuración y el almacenamiento local de la página.';

  @override
  String get deviceImportConfig => 'Importar configuración';

  @override
  String get deviceImportConfigHelp =>
      'Reemplaza la configuración de este dispositivo con la de un archivo exportado.';

  @override
  String get deviceExportFailed => 'No se pudo exportar';

  @override
  String get deviceExported => 'Configuración exportada';

  @override
  String get deviceImportFailed => 'No se pudo importar';

  @override
  String get deviceInvalidJson => 'El archivo no contiene JSON válido.';

  @override
  String get deviceImportComplete => 'Importación completada';

  @override
  String deviceAppliedSettings(String count) {
    return 'Se aplicaron $count opciones de configuración.';
  }

  @override
  String deviceAppliedReload(String count) {
    return 'Se aplicaron $count opciones de configuración. Es posible que la página se recargue.';
  }

  @override
  String get deviceReplaceOriginal => 'Reemplazar el dispositivo original';

  @override
  String get deviceReplaceQuestion =>
      '¿Reemplazar la configuración de este dispositivo con la del archivo? Es posible que la página se recargue.';

  @override
  String get deviceNewDevice => 'Configurar como dispositivo nuevo';

  @override
  String get deviceReplaceIdentity =>
      'Conserva el nombre y la identidad de ESPHome de la copia de seguridad. El dispositivo original debe permanecer desconectado.';

  @override
  String get deviceNewIdentity =>
      'Asigna un nombre y una identidad de ESPHome propios para que los dos dispositivos sean únicos.';

  @override
  String get deviceRestoreStorage =>
      'Restaurar el almacenamiento local de WebView';

  @override
  String get deviceRestoreStorageHelp =>
      'Incluye la sesión iniciada de Home Assistant y la selección de assist_satellite de Voice Satellite. Dos dispositivos no deben compartir un satélite.';

  @override
  String get deviceDownload => 'Descargar';

  @override
  String get deviceChooseFile => 'Elegir archivo…';

  @override
  String get deviceImportFailedSentence => 'No se pudo importar.';

  @override
  String deviceReplaceNamed(String name) {
    return 'Reemplazar \"$name\"';
  }

  @override
  String get settingDeviceNameTitle => 'Nombre del dispositivo';

  @override
  String get settingDeviceNameDescription =>
      'Nombre que se muestra en la administración remota y con el que se identifica el dispositivo en Home Assistant.';

  @override
  String get settingDeviceHostnameTitle => 'Nombre mDNS';

  @override
  String get settingDeviceHostnameDescription =>
      'Accede a la administración remota con este nombre y el puerto configurado en la red local. Bórralo para volver a usar el nombre del dispositivo.';

  @override
  String get settingDisableImpellerTitle => 'Renderizador antiguo';

  @override
  String get settingDisableImpellerDescription =>
      'Usa el renderizador Skia para GPU antiguas que fallan al iniciar. Se activa automáticamente después de dos fallos de este tipo. Se aplica la próxima vez que se inicia la aplicación.';

  @override
  String get settingLegacyWebViewTitle => 'Renderizador WebView antiguo';

  @override
  String get settingLegacyWebViewDescription =>
      'Dibuja el panel de control en una textura para GPU antiguas que fallan cuando aparece. Se activa automáticamente cuando el dispositivo lo necesita. Se aplica la próxima vez que se inicia la aplicación.';

  @override
  String get deviceHostnamePlaceholder => 'Se toma del nombre del dispositivo';

  @override
  String get deviceConfiguration => 'Configuración';

  @override
  String get devicePermissionsManager => 'Gestor de permisos';

  @override
  String get deviceOptions => 'Opciones';

  @override
  String get deviceStatus => 'Estado';

  @override
  String get deviceConnection => 'Conexión';

  @override
  String get devicePermissions => 'Permisos';

  @override
  String get deviceHelp => 'Ayuda';

  @override
  String get deviceAccess => 'Acceso';

  @override
  String get deviceReading => 'Leyendo…';

  @override
  String get deviceChecking => 'Comprobando...';

  @override
  String get deviceUnavailable => 'Estado no disponible.';

  @override
  String get deviceGrantOnDevice => 'Conceder en el dispositivo';

  @override
  String get deviceAppSettings => 'Configuración de la aplicación';

  @override
  String get deviceCopyCommand => 'Copiar comando';

  @override
  String get deviceOpenGuide => 'Abrir guía';

  @override
  String get deviceNotSet => 'Sin definir';

  @override
  String get deviceGranted => 'Concedido';

  @override
  String get deviceNotGranted => 'Sin conceder';

  @override
  String get deviceMissing => 'Falta';

  @override
  String get deviceNotOffered => 'No disponible';

  @override
  String get deviceOn => 'activado';

  @override
  String get deviceOff => 'desactivado';

  @override
  String get deviceServiceHint =>
      'Estado, funciones que mantiene activas, permisos necesarios';

  @override
  String get deviceRemoteHintActual =>
      'Administra este kiosko desde un navegador de tu red';

  @override
  String get deviceUpdatesHint => 'Dónde busca la aplicación nuevas versiones';

  @override
  String get deviceShizukuHint =>
      'Conexión, permisos de Android y configuración';

  @override
  String get deviceHelperHint =>
      'Estado de las actualizaciones sin confirmación, configuración por ADB e instrucciones';

  @override
  String get deviceAnalyticsHint =>
      'Comparte información anónima para mejorar Kiosk Satellite';

  @override
  String get deviceHardwareHint =>
      'Modelo, versión de Android, direcciones, memoria, tiempo de actividad';

  @override
  String get deviceHaHint => 'Conexión, versión y contenido del kiosko';

  @override
  String get deviceWebViewHint =>
      'Versión del motor, renderizador y agente de usuario';

  @override
  String get devicePasswordSet => '•••••• (definida)';

  @override
  String get deviceSaveFailed =>
      'No se pudo guardar esta opción. Inténtalo de nuevo.';

  @override
  String get deviceOpenSettingsDevice =>
      'Abrir configuración en el dispositivo';

  @override
  String get deviceHardwarePage => 'Hardware';

  @override
  String get deviceWebViewPage => 'WebView';

  @override
  String get deviceModel => 'Modelo del dispositivo';

  @override
  String get deviceAndroidVersion => 'Versión de Android';

  @override
  String get deviceAndroidBuild => 'Compilación de Android';

  @override
  String get deviceIpv4 => 'Dirección IPv4';

  @override
  String get deviceIpv6 => 'Direcciones IPv6';

  @override
  String get deviceAppUptime => 'Tiempo de actividad de la aplicación';

  @override
  String get deviceNetworkUptime => 'Tiempo de actividad de la red';

  @override
  String get deviceCpuUsage => 'Uso de CPU';

  @override
  String get deviceCpuTemp => 'Temperatura de CPU';

  @override
  String get deviceBatteryLevel => 'Nivel de batería';

  @override
  String get deviceScreenBrightness => 'Brillo de pantalla';

  @override
  String get deviceScreenStatus => 'Estado de la pantalla';

  @override
  String get deviceScreenSize => 'Tamaño de pantalla';

  @override
  String get deviceRam => 'RAM (libre/total)';

  @override
  String get deviceStorage => 'Almacenamiento interno (libre/total)';

  @override
  String get deviceHaUrl => 'URL de Home Assistant';

  @override
  String get deviceWakeDetection => 'Detección de palabras de activación';

  @override
  String get deviceWakeStatus => 'Estado de la palabra de activación';

  @override
  String get deviceEngine => 'Motor';

  @override
  String get deviceWakeWords => 'Palabras de activación';

  @override
  String get deviceStopWord => 'Palabra de detención';

  @override
  String get deviceMotionDetection => 'Detección de movimiento';

  @override
  String get deviceFaceDetection => 'Detección de rostros';

  @override
  String get deviceProvider => 'Proveedor';

  @override
  String get deviceVersion => 'Versión';

  @override
  String get deviceUserAgent => 'Agente de usuario';

  @override
  String get devicePlugged => 'conectada';

  @override
  String get deviceLowMemory => 'escasa';

  @override
  String get deviceRequiredPermissions => 'Permisos del sistema necesarios';

  @override
  String get devicePermissionIntro =>
      'Los permisos se conceden en este dispositivo. Cada botón abre aquí un diálogo o una pantalla de configuración de Android. Algunas marcas incluyen su propio gestor de batería o de inicio automático, que Android no puede consultar.';

  @override
  String get devicePermissionIntroRemote =>
      'Los permisos se conceden en el dispositivo. Cada botón abre allí un diálogo o una pantalla de configuración de Android. Algunas marcas incluyen su propio gestor de batería o de inicio automático, que Android no puede consultar.';

  @override
  String get deviceMicrophone => 'Micrófono';

  @override
  String get deviceMicrophoneHeld =>
      'Permite usar el micrófono para detectar palabras de activación, convertir voz en texto y hacer llamadas por el intercomunicador.';

  @override
  String get deviceBattery => 'Batería sin restricciones';

  @override
  String get deviceBatteryHeld =>
      'Permite que el proceso se ejecute en segundo plano sin que se pause ni se cierre.';

  @override
  String get deviceCamera => 'Cámara';

  @override
  String get deviceCameraHeld =>
      'La detección de movimiento y las capturas pueden usar la cámara.';

  @override
  String get deviceBluetooth => 'Dispositivos cercanos';

  @override
  String get deviceBluetoothHeld =>
      'El proxy Bluetooth puede buscar dispositivos cercanos.';

  @override
  String get deviceNotifications => 'Notificaciones';

  @override
  String get deviceNotificationsHeld =>
      'Permite la notificación permanente del servicio de Kiosk Satellite, que indica qué funciones mantiene activas.';

  @override
  String get deviceOverlay => 'Mostrar sobre otras aplicaciones';

  @override
  String get deviceOverlayHeld =>
      'Kiosk Satellite puede volver al primer plano.';

  @override
  String get deviceWriteSettings => 'Modificar la configuración del sistema';

  @override
  String get deviceWriteSettingsHeld =>
      'Los cambios de brillo ajustan el brillo real de la pantalla.';

  @override
  String get deviceUiGuard => 'Protección de la interfaz del sistema';

  @override
  String get deviceUiGuardHeld =>
      'El panel de notificaciones y las aplicaciones recientes se cierran automáticamente mientras la pantalla está protegida.';

  @override
  String get deviceDeviceAdmin => 'Administrador del dispositivo';

  @override
  String get deviceDeviceAdminHeld =>
      'Permite que la aplicación apague la pantalla.';

  @override
  String get deviceAllFiles => 'Acceso a todos los archivos';

  @override
  String get deviceAllFilesHeld =>
      'El gestor de archivos puede explorar el almacenamiento compartido.';

  @override
  String get deviceUsageAccess => 'Acceso al uso';

  @override
  String get deviceUsageAccessHeld =>
      'El sensor de aplicación en primer plano puede identificar la aplicación que aparece en pantalla.';

  @override
  String get deviceLocation => 'Ubicación';

  @override
  String get deviceLocationHeld =>
      'Las páginas, la búsqueda Bluetooth y los sensores de ubicación pueden usar la posición del dispositivo.';

  @override
  String get deviceMicBlocked =>
      'Bloqueado. Android no volverá a solicitarlo. Concédelo en la configuración de la aplicación.';

  @override
  String get deviceMicMissing =>
      'La detección de palabras de activación está activada, pero no hay nada escuchando.';

  @override
  String get deviceMicIdle =>
      'Necesario para detectar palabras de activación, usar el intercomunicador y abrir páginas que soliciten el micrófono.';

  @override
  String get deviceBatteryMissing =>
      'Android puede pausar la aplicación con la pantalla apagada, interrumpiendo la conexión con Home Assistant y las entidades de ESPHome.';

  @override
  String get deviceCameraMissing =>
      'La cámara está activada, pero no se puede abrir.';

  @override
  String get deviceCameraIdle =>
      'Necesario para detectar movimiento, tomar capturas y abrir páginas que soliciten la cámara.';

  @override
  String get deviceBluetoothMissing =>
      'El proxy Bluetooth está activado, pero no puede buscar dispositivos.';

  @override
  String get deviceBluetoothLocation =>
      'La búsqueda Bluetooth necesita el permiso de ubicación.';

  @override
  String get deviceBluetoothLocationOff =>
      'La ubicación está desactivada en la configuración del dispositivo, por lo que la búsqueda Bluetooth no encuentra dispositivos.';

  @override
  String get deviceBluetoothIdle =>
      'Necesario para que el proxy Bluetooth busque dispositivos.';

  @override
  String get deviceNotificationMissing =>
      'Necesario para mostrar la notificación permanente del servicio de Kiosk Satellite.';

  @override
  String get deviceOverlayMissing =>
      'Sin este permiso, la aplicación no puede volver a abrirse después de un fallo, una actualización o una palabra de activación escuchada mientras otra aplicación está en primer plano.';

  @override
  String get deviceOverlayIdle =>
      'Permite que la aplicación vuelva al primer plano y que la protección del modo de bloqueo cubra toda la pantalla.';

  @override
  String get deviceBrightnessMissing =>
      'El brillo solo atenúa la ventana de la aplicación. La pantalla y Home Assistant no reciben el cambio.';

  @override
  String get deviceBrightnessIdle =>
      'Necesario para ajustar el brillo real de la pantalla en lugar de atenuar la ventana de la aplicación.';

  @override
  String get deviceGuardMissing =>
      'El panel de notificaciones y las aplicaciones recientes siguen accesibles. Activa Kiosk Satellite en Accesibilidad.';

  @override
  String get deviceGuardIdle =>
      'Cierra el panel de notificaciones y las aplicaciones recientes mientras el modo kiosko protege la pantalla.';

  @override
  String get deviceAdminIdle =>
      'Permite que la acción de apagar pantalla la apague de verdad en lugar de mostrarla en negro.';

  @override
  String get deviceFilesIdle =>
      'Permite que el gestor de archivos explore el almacenamiento compartido y no solo la carpeta de la aplicación.';

  @override
  String get deviceUsageIdle =>
      'Permite que el sensor de aplicación en primer plano identifique otras aplicaciones además de Kiosk Satellite.';

  @override
  String get deviceLocationMissing =>
      'Android no entrega resultados de búsqueda Bluetooth sin ubicación y los sensores de ubicación no pueden leer el receptor GPS.';

  @override
  String get deviceLocationIdle =>
      'Lo usan las páginas que solicitan tu ubicación, la búsqueda Bluetooth y los sensores de ubicación de ESPHome.';

  @override
  String get deviceServiceOverlayMissing =>
      'Sin este permiso, el servicio no puede volver a abrir el kiosko después de un fallo o de cerrarlo desde las aplicaciones recientes.';

  @override
  String get deviceServiceOverlayIdle =>
      'Necesario para volver a abrir el kiosko después de un fallo.';

  @override
  String get deviceListeningMissing =>
      'La escucha en segundo plano está activada, pero no hay nada escuchando.';

  @override
  String get deviceListeningIdle =>
      'Necesario para la escucha en segundo plano.';

  @override
  String get deviceMotionIdle => 'Necesario para la detección de movimiento.';

  @override
  String get deviceBatteryAdb =>
      'Este dispositivo no tiene una pantalla de configuración para este permiso. Concédelo mediante ADB: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

  @override
  String get deviceOverlayAdb =>
      'Este dispositivo no tiene una pantalla de configuración para este permiso. Concédelo mediante ADB: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';

  @override
  String get settingRemoteEnabledTitle => 'Administración remota';

  @override
  String get settingRemoteEnabledDescription =>
      'Activa el servidor web integrado para administrar el dispositivo.';

  @override
  String get settingRemotePortTitle => 'Puerto del servidor';

  @override
  String get settingRemotePortDescription =>
      'Puerto de la interfaz de administración remota.';

  @override
  String get settingRemotePasswordTitle => 'Contraseña de administración';

  @override
  String get settingRemotePasswordDescription =>
      'Necesaria para iniciar sesión en la interfaz remota.';

  @override
  String get settingRemoteFleetDiscoveryTitle => 'Buscar otros kioskos';

  @override
  String get settingRemoteFleetDiscoveryDescription =>
      'Anuncia este dispositivo en la red y muestra los otros kioskos en la administración remota para cambiar entre ellos.';

  @override
  String get deviceRemotePage => 'Administración remota';

  @override
  String get deviceAdminAddress => 'Dirección de administración';

  @override
  String get deviceAdminAddressHelp =>
      'Abre esta dirección en un navegador de tu computadora.';

  @override
  String get deviceByName => 'Por nombre';

  @override
  String get deviceByNameHelp =>
      'La misma dirección mediante el nombre del equipo, en redes que resuelven nombres .local.';

  @override
  String get devicePasswordNeeded =>
      'Define una contraseña de administración abajo para iniciar el servidor.';

  @override
  String get deviceServerStopped => 'El servidor no está en ejecución.';

  @override
  String devicePortError(String port, String error) {
    return 'No se pudo escuchar en el puerto $port: $error';
  }

  @override
  String get settingRemoteTlsTitle => 'Usar HTTPS';

  @override
  String get settingRemoteTlsDescription =>
      'Cifra la administración remota, la API y WebSocket. El navegador puede pedirte que aceptes el certificado del dispositivo.';

  @override
  String get settingServiceCpuAwakeTitle =>
      'Mantener la CPU activa con la pantalla apagada';

  @override
  String get settingServiceCpuAwakeDescription =>
      'Impide que la CPU entre en suspensión con la pantalla apagada para que las conexiones y los temporizadores sigan funcionando a tiempo. Consume batería si la tableta no está conectada a la corriente.';

  @override
  String get deviceServicePage => 'Servicio de Kiosk Satellite';

  @override
  String get deviceKeepingRunning => 'Funciones que mantiene activas';

  @override
  String get deviceService => 'Servicio';

  @override
  String get deviceStopped => 'Detenido';

  @override
  String get deviceStoppedSentence => 'Detenido.';

  @override
  String get deviceRunning => 'En ejecución';

  @override
  String get deviceRunningSentence => 'En ejecución.';

  @override
  String get deviceRunningBackground =>
      'En ejecución sin la excepción de servicio en primer plano.';

  @override
  String get deviceServiceTypes => 'Tipos de servicio en primer plano';

  @override
  String get deviceServiceTypesHelp =>
      'Lo que el servicio declara a Android para las funciones que mantiene activas.';

  @override
  String get deviceNoneDeclared => 'Ninguno declarado.';

  @override
  String get deviceNone => 'ninguno';

  @override
  String get deviceCpuLock => 'Bloqueo de suspensión de la CPU';

  @override
  String get deviceCpuOff =>
      'Desactivado: la opción de abajo está desactivada.';

  @override
  String get deviceCpuHeld => 'Activo: la pantalla está apagada.';

  @override
  String get deviceCpuReleased =>
      'Liberado mientras la pantalla está encendida.';

  @override
  String get deviceNotHeld => 'No está activo.';

  @override
  String get deviceHeld => 'Activo';

  @override
  String get deviceReleased => 'Liberado';

  @override
  String get deviceWifiLock => 'Bloqueo de suspensión de Wi-Fi';

  @override
  String get deviceWifiHeld =>
      'Activo: la radio no entra en ahorro de energía.';

  @override
  String get deviceWifiHelp =>
      'Impide que la radio entre en ahorro de energía con la pantalla apagada.';

  @override
  String get deviceNotification => 'Notificación';

  @override
  String get deviceNotificationHidden =>
      'Oculta: las notificaciones de la aplicación están desactivadas. El servicio sigue funcionando.';

  @override
  String get deviceNotificationShown =>
      'Se muestra en el panel de notificaciones mientras el servicio está en ejecución.';

  @override
  String get deviceHidden => 'Oculta';

  @override
  String get deviceShown => 'Visible';

  @override
  String get deviceReasonHa => 'Conexión con Home Assistant';

  @override
  String get deviceReasonHaHelp =>
      'Mantiene abiertas la sesión del panel de control y su conexión WebSocket con la pantalla apagada.';

  @override
  String get deviceReasonListening => 'Escucha en segundo plano';

  @override
  String get deviceReasonListeningHelp =>
      'Mantiene activos el motor de palabras de activación y su micrófono mientras se usan otras aplicaciones.';

  @override
  String get deviceReasonRtsp => 'Audio del micrófono por RTSP';

  @override
  String get deviceReasonRtspHelp =>
      'Mantiene disponible la transmisión del micrófono para los clientes RTSP conectados.';

  @override
  String get deviceReasonEspHome => 'Servidor ESPHome';

  @override
  String get deviceReasonEspHomeHelp =>
      'Mantiene disponible el servidor de la API de ESPHome para Home Assistant.';

  @override
  String get deviceReasonRemote => 'Administración remota';

  @override
  String get deviceReasonRemoteHelp =>
      'Mantiene disponible el servidor web de administración.';

  @override
  String get deviceReasonProtections => 'Protecciones del kiosko';

  @override
  String get deviceReasonProtectionsHelp =>
      'Vuelve a abrir el kiosko si se cierra desde las aplicaciones recientes o por un fallo.';

  @override
  String get deviceReasonBluetooth => 'Proxy Bluetooth';

  @override
  String get deviceReasonBluetoothHelp =>
      'Mantiene activa la búsqueda Bluetooth mientras la aplicación no está en pantalla.';

  @override
  String get deviceReasonLocation => 'Sensores de ubicación';

  @override
  String get deviceReasonLocationHelp =>
      'Sigue recibiendo posiciones GPS con la pantalla apagada o mientras otra aplicación está en primer plano.';

  @override
  String get deviceReasonPerson => 'Detección de personas';

  @override
  String get deviceReasonPersonHelp =>
      'Sigue leyendo el sensor de personas del dispositivo mientras otra aplicación está en primer plano.';

  @override
  String get deviceReasonCameraHelp =>
      'Mantiene disponible la cámara después de apagar la pantalla para detectar movimiento y rostros.';

  @override
  String deviceServiceStopped(String error) {
    return 'Detenido: $error';
  }

  @override
  String deviceServiceRunning(String uptime) {
    return 'En ejecución durante $uptime.';
  }

  @override
  String get settingShizukuInstallUpdatesTitle =>
      'Instalar actualizaciones mediante Shizuku';

  @override
  String get settingShizukuInstallUpdatesDescription =>
      'Instala actualizaciones de Kiosk Satellite sin confirmación en el dispositivo. Shizuku debe estar en ejecución y autorizado.';

  @override
  String get deviceShizukuAccess => 'Acceso de Shizuku';

  @override
  String get deviceShizukuCheck => 'Comprobando disponibilidad';

  @override
  String get deviceShizukuRoot => 'Conectado con acceso root';

  @override
  String get deviceShizukuShell => 'Conectado con acceso shell';

  @override
  String get deviceShizukuGrant =>
      'Toca para conceder acceso. Aprueba la solicitud en este kiosko.';

  @override
  String get deviceShizukuGrantRemote =>
      'Concede acceso y aprueba la solicitud en este kiosko.';

  @override
  String get deviceShizukuDenied =>
      'Autoriza Kiosk Satellite en la aplicación Shizuku.';

  @override
  String get deviceShizukuUnsupported =>
      'Se requiere Shizuku 13 o una versión posterior.';

  @override
  String get deviceShizukuStart => 'Inicia Shizuku en este dispositivo.';

  @override
  String get deviceShizukuTest => 'Probar conexión';

  @override
  String get deviceShizukuTestHelp =>
      'Consulta la identidad del proceso sin modificar el dispositivo.';

  @override
  String get deviceShizukuTestTitle => 'Prueba de conexión';

  @override
  String get deviceShizukuTestFailed =>
      'Shizuku no pudo completar la prueba de conexión.';

  @override
  String get deviceShizukuAlreadyGranted =>
      'Ya se concedieron todos los permisos.';

  @override
  String get deviceShizukuConfirmed =>
      'Android confirmó los permisos solicitados.';

  @override
  String get deviceShizukuResults => 'Resultados de los permisos';

  @override
  String get deviceShizukuGrantAll => 'Conceder todos los permisos';

  @override
  String get deviceShizukuGrantAllHelp =>
      'Concede todos los permisos que usa KS, incluidas las funciones que están desactivadas.';

  @override
  String get deviceShizukuSetup => 'Configurar Shizuku';

  @override
  String get deviceShizukuSetupHelp =>
      'Consulta las instrucciones de instalación e inicio.';

  @override
  String get deviceShizukuLifetime =>
      'Si inicias Shizuku mediante ADB, debes volver a iniciarlo después de reiniciar el dispositivo. El acceso shell no proporciona permisos root.';

  @override
  String get deviceShizukuFailed => 'Falló la solicitud de Shizuku';

  @override
  String get deviceShizukuApprove => 'Aprueba la solicitud en el kiosko.';

  @override
  String deviceShizukuTestOk(String access) {
    return 'Shizuku ejecutó un comando correctamente con acceso $access.';
  }

  @override
  String get shizukuPermissionUnconfirmed =>
      'Android no ha confirmado este permiso. Revisa el Administrador de permisos en el dispositivo.';

  @override
  String get shizukuPermissionReadFailed =>
      'No se pudieron consultar los permisos actuales. Inténtalo de nuevo.';

  @override
  String get shizukuRestartTimedOut =>
      'Se agotó el tiempo de espera del comando de reinicio';

  @override
  String get shizukuRestartRefused => 'Android rechazó el reinicio';

  @override
  String get shizukuCommandTimedOut =>
      'Se agotó el tiempo de espera del comando';

  @override
  String get shizukuRequestRejected => 'Android rechazó la solicitud';

  @override
  String get deviceDisconnectedError => 'El dispositivo se desconectó';

  @override
  String get deviceResponseTimedOut =>
      'Se agotó el tiempo de espera de la respuesta del dispositivo';

  @override
  String get deviceRequestAborted => 'Solicitud cancelada';

  @override
  String get shizukuActionBusy =>
      'Ya hay una acción de Shizuku en curso en el dispositivo';

  @override
  String get shizukuGrantFirst => 'Primero concede acceso a Shizuku';

  @override
  String get shizukuNoResponse => 'El comando de Shizuku no respondió';

  @override
  String get shizukuCommandFailed => 'El comando de Shizuku falló';

  @override
  String get shizukuStartRequired =>
      'Inicia Shizuku 13 o posterior y autoriza Kiosk Satellite en Shizuku';

  @override
  String get shizukuConnectionFailed => 'La conexión con Shizuku falló';

  @override
  String get shizukuHelperNotConnected =>
      'El asistente de Shizuku no se conectó';

  @override
  String get shizukuHelperUnavailable =>
      'El asistente de Shizuku no está disponible';

  @override
  String get tlsTLS => 'TLS';

  @override
  String get tlsConnectionEncryptionAndCertificates =>
      'Cifrado de conexiones y certificados';

  @override
  String get tlsCertificateType => 'Tipo de certificado';

  @override
  String get tlsImported => 'Importado';

  @override
  String get tlsSelfSigned => 'Autofirmado';

  @override
  String get tlsExpires => 'Caduca';

  @override
  String get tlsSHA256Fingerprint => 'Huella digital SHA-256';

  @override
  String get tlsCertificateExpiredRenewOrImportAReplacement =>
      'El certificado ha caducado. Renuévalo o importa uno nuevo.';

  @override
  String get tlsCopyPublicCertificate => 'Copiar certificado público';

  @override
  String get tlsDownloadPublicCertificate => 'Descargar certificado público';

  @override
  String get tlsUseThisCertificateInBrowsersAndStreamingClients =>
      'Usa este certificado en navegadores y clientes de streaming.';

  @override
  String get tlsRenewCertificate => 'Renovar certificado';

  @override
  String get tlsKeepTheCurrentPrivateKeyAndUpdateTheCertificateDates =>
      'Conserva la clave privada actual y actualiza las fechas del certificado.';

  @override
  String get tlsImportCertificate => 'Importar certificado';

  @override
  String get tlsUseACertificateIssuedForThisDevice =>
      'Usa un certificado emitido para este dispositivo.';

  @override
  String get tlsReplaceCertificate => 'Reemplazar certificado';

  @override
  String get tlsGenerateANewPrivateKeyAndSelfSignedCertificate =>
      'Genera una nueva clave privada y un certificado autofirmado.';

  @override
  String
  get tlsGenerateANewPrivateKeyAndCertificateActiveEncryptedConnectionsWillCloseBrowsersMayAskYouToAcceptTheNewCertificate =>
      '¿Generar una nueva clave privada y un certificado? Las conexiones cifradas activas se cerrarán. Los navegadores pueden pedirte que aceptes el nuevo certificado.';

  @override
  String
  get tlsPasteThePEMCertificateChainAndItsUnencryptedPrivateKeyTheyAreValidatedBeforeReplacingTheCurrentCertificate =>
      'Pega la cadena de certificados PEM y su clave privada sin cifrar. Se validarán antes de reemplazar el certificado actual.';

  @override
  String get tlsCertificateChainPEM => 'Cadena de certificados (PEM)';

  @override
  String get tlsPrivateKeyPEM => 'Clave privada (PEM)';

  @override
  String get tlsThisFieldIsRequired => 'Este campo es obligatorio.';

  @override
  String get tlsReplace => 'Reemplazar';

  @override
  String get tlsRenew => 'Renovar';

  @override
  String get tlsEnableHTTPSBeforeImportingAPrivateKeyRemotely =>
      'Activa HTTPS antes de importar una clave privada de forma remota.';

  @override
  String get tlsCertificateOperationFailed =>
      'La operación con el certificado ha fallado.';

  @override
  String get tlsChangeConnectionProtocol => 'Cambiar protocolo de conexión';

  @override
  String get tlsConnectionProtocolHelp =>
      'La conexión remota actual se cerrará. Vuelve a conectarte con la dirección que aparece abajo. Es posible que debas iniciar sesión de nuevo.';

  @override
  String get tlsConfirm => 'Confirmar';

  @override
  String get tlsCertificateManagement => 'Gestión de certificados';

  @override
  String get tlsServerCertificateRequired =>
      'Usa un certificado de servidor, no un certificado de una autoridad de certificación.';

  @override
  String get tlsServerAuthenticationRequired =>
      'El certificado no permite la autenticación de servidor.';

  @override
  String get tlsKeyAlgorithmRequired => 'Usa una clave privada EC o RSA.';

  @override
  String get tlsKeyMismatch =>
      'El certificado y la clave privada no coinciden.';

  @override
  String get tlsMaterialTooLarge =>
      'El certificado o la clave son demasiado grandes.';

  @override
  String get tlsPemCertificatesRequired => 'Se esperaban certificados PEM.';

  @override
  String get tlsCertificateMissing => 'No se encontró ningún certificado.';

  @override
  String get tlsUnencryptedKeyRequired =>
      'Usa una clave privada PEM sin cifrar.';

  @override
  String get tlsHostnameRequired =>
      'Se requiere un nombre de host o una dirección IP.';

  @override
  String get tlsIssuerRenewalRequired =>
      'Importa un certificado renovado por su emisor.';

  @override
  String get tlsStoredIdentityDamaged =>
      'La identidad TLS almacenada está dañada.';

  @override
  String get tlsExpiredCertificate =>
      'El certificado TLS ha caducado. Renuévalo o importa uno nuevo.';

  @override
  String get deviceHelperPage => 'Asistente de actualización opcional';

  @override
  String get deviceHelperStatus => 'Estado del asistente';

  @override
  String get deviceHelperError =>
      'No se pudo consultar el asistente de actualización.';

  @override
  String get deviceHelperUnneeded =>
      'Android ya puede instalar actualizaciones sin confirmación. No se necesita el asistente.';

  @override
  String get deviceHelperIntro =>
      'Este dispositivo necesita confirmación en la pantalla para instalar actualizaciones mediante Android. El asistente opcional permite que Kiosk Satellite instale actualizaciones sin tocar la pantalla.';

  @override
  String get deviceHelperBusy => 'Instalando una actualización.';

  @override
  String get deviceHelperReady =>
      'Listo. Las actualizaciones se instalan sin confirmación.';

  @override
  String get deviceHelperUnavailable =>
      'No disponible. Inicia el asistente mediante ADB para permitir actualizaciones sin confirmación.';

  @override
  String get deviceHelperLifetime =>
      'El asistente sigue funcionando después de reiniciar o actualizar la aplicación, pero se detiene al reiniciar el dispositivo. Ejecuta el comando desde una computadora con ADB para iniciarlo de nuevo. Luego puedes desconectar la computadora.';

  @override
  String get deviceHelperStart => 'Iniciar mediante ADB';

  @override
  String get deviceHelperGuide => 'Guía de configuración';

  @override
  String get deviceHelperGuideHelp =>
      'Consulta las instrucciones y los requisitos del asistente de actualización.';

  @override
  String get settingUpdateSourceTitle => 'Origen de las actualizaciones';

  @override
  String get settingUpdateSourceDescription =>
      'Dónde busca la aplicación las nuevas versiones.';

  @override
  String get settingUpdateSourceUrlTitle => 'URL del repositorio';

  @override
  String get settingUpdateSourceUrlDescription =>
      'Carpeta en un servidor web al que el kiosko pueda acceder, que contiene releases.json y los APK de las versiones.';

  @override
  String get deviceUpdatesPage => 'Actualizaciones';

  @override
  String get deviceUpdateGithub => 'Repositorio de GitHub';

  @override
  String get deviceUpdateCustom => 'Repositorio personalizado';

  @override
  String get deviceUpdateGuide => 'Guía del repositorio personalizado';

  @override
  String get deviceUpdateGuideHelp =>
      'Cómo alojar el archivo de versiones y los APK en tu propia red.';

  @override
  String get deviceInstallFile => 'Instalar desde un archivo';

  @override
  String get deviceInstallFileHelp =>
      'Sube un APK de Kiosk Satellite desde una computadora mediante la administración remota, en esta misma página. Para un kiosko que no puede acceder a GitHub ni a un repositorio personalizado.';

  @override
  String get deviceInstallFileRemoteHelp =>
      'Sube un APK de Kiosk Satellite desde esta computadora e instálalo. Para un kiosko que no puede acceder a GitHub ni a un repositorio personalizado.';

  @override
  String get deviceUploadedApk => 'APK subido';

  @override
  String get deviceInstalling => 'Instalando…';

  @override
  String get deviceDeviceNoAnswer => 'El dispositivo no respondió.';

  @override
  String get deviceInstallFailed =>
      'Falló la actualización. Revisa los registros del dispositivo.';

  @override
  String get deviceConfirmTablet => 'Confirma en la pantalla de la tableta';

  @override
  String deviceUploadedVersion(String version, String build, String size) {
    return 'La versión $version (compilación $build, $size MB) está en el dispositivo, pendiente de instalación.';
  }

  @override
  String deviceInstallVersion(String version) {
    return 'Instalar la versión $version';
  }

  @override
  String deviceHttpError(String code) {
    return 'El dispositivo respondió con HTTP $code.';
  }

  @override
  String get deviceUploadFailed => 'No se pudo subir el archivo.';

  @override
  String get deviceInstallFleet => 'Instalar en la flota';

  @override
  String get deviceSendingFleet => 'Enviando a la flota…';

  @override
  String get deviceSameBuild => 'El kiosko ya usa esta compilación.';

  @override
  String get deviceInstallConfirmation =>
      'Debes confirmar la instalación en la pantalla de la tableta, a menos que el kiosko instale sin confirmación.';

  @override
  String get deviceSelfLast => 'Este kiosko se instala al final.';

  @override
  String get deviceUpdatingFleet => 'Actualizando la flota';

  @override
  String deviceUploading(String percent) {
    return 'Subiendo… $percent%';
  }

  @override
  String deviceUploadedDetails(String version, String build, String size) {
    return 'El APK subido es la versión $version (compilación $build, $size MB).';
  }

  @override
  String deviceCurrentBuild(String version, String build) {
    return 'El kiosko usa la versión $version (compilación $build).';
  }

  @override
  String deviceSendingTo(String name, String percent) {
    return 'Enviando a $name… $percent%';
  }

  @override
  String deviceInstallingOn(String name) {
    return 'Instalando en $name…';
  }

  @override
  String deviceInstallingNames(String names) {
    return 'Instalando en $names.';
  }

  @override
  String get deviceUpdateUrlInvalid =>
      'Introduce la URL de la carpeta, por ejemplo http://nas.local/kiosk-satellite';

  @override
  String get deviceUpdateUrlPath =>
      'Introduce solo la URL de la carpeta, sin nada después de la ruta. Ejemplo: http://nas.local/kiosk-satellite';

  @override
  String get updateDownloadBusy =>
      'Hay una descarga en curso. Espera a que termine.';

  @override
  String get updateInstallBusy =>
      'Hay una instalación en curso. Espera a que termine.';

  @override
  String get updateNoAvailable => 'No hay actualizaciones disponibles.';

  @override
  String get updateNoUploaded =>
      'No hay ningún APK cargado pendiente de instalación.';

  @override
  String get updateUploadEmpty => 'El archivo cargado estaba vacío.';

  @override
  String get updateInvalidApk => 'El archivo no es un APK de Android.';

  @override
  String get updateUploadedGone =>
      'El APK cargado ya no está disponible. Vuelve a cargarlo.';

  @override
  String get updateShizukuInstallerFailed =>
      'Shizuku no pudo instalar la actualización. No se abrió el instalador que solicita confirmación.';

  @override
  String updateUploadSpace(String size, String required, String free) {
    return 'No hay suficiente espacio libre: el APK ocupa $size MB y la instalación necesita unos $required MB, pero el dispositivo solo tiene $free MB libres.';
  }

  @override
  String updateUploadInterrupted(String size, String error) {
    return 'La carga se interrumpió después de $size MB: $error';
  }

  @override
  String updateUploadEarly(String received, String expected) {
    return 'La carga terminó antes de completarse: se recibieron $received de $expected MB.';
  }

  @override
  String updateWrongPackage(String package, String expected) {
    return 'El APK corresponde a $package, no a Kiosk Satellite ($expected).';
  }

  @override
  String updateOlderBuild(
    String version,
    String build,
    String currentVersion,
    String currentBuild,
  ) {
    return 'El APK es la versión $version (compilación $build), anterior a la versión instalada $currentVersion (compilación $currentBuild). No se permite instalar versiones anteriores. Android tampoco las instalaría.';
  }

  @override
  String updateDownloadHttpFailed(String status) {
    return 'La descarga falló (HTTP $status).';
  }

  @override
  String updateDownloadStalled(String seconds) {
    return 'La descarga se detuvo: no se recibieron datos durante $seconds segundos.';
  }

  @override
  String deviceUpdateFailedDetail(String error) {
    return 'La actualización falló: $error';
  }

  @override
  String deviceInstallFailedDetail(String error) {
    return 'La instalación falló: $error';
  }

  @override
  String get updateAnotherPackage => 'otro paquete';

  @override
  String get settingUiLanguageTitle => 'Idioma';

  @override
  String get settingUiLanguageDescription =>
      'Idioma de Kiosk Satellite y de la administración remota. Home Assistant conserva su propio idioma.';

  @override
  String get settingUiThemeTitle => 'Tema de la aplicación';

  @override
  String get settingUiThemeDescription =>
      'Claro u oscuro para las pantallas de la aplicación: menú, configuración y diálogos. Sistema sigue la configuración de Android.';

  @override
  String get settingUiScaleTitle => 'Escala de la interfaz';

  @override
  String get settingUiScaleDescription =>
      'Tamaño de las pantallas de la aplicación: menú, configuración y diálogos. Para pantallas de alta densidad. El contenido web conserva su tamaño.';

  @override
  String get deviceUserInterface => 'Interfaz de usuario';

  @override
  String get deviceThemeDark => 'Oscuro';

  @override
  String get deviceThemeLight => 'Claro';

  @override
  String get deviceThemeSystem => 'Sistema';

  @override
  String get settingDlnaEnabledTitle => 'Activar receptor DLNA';

  @override
  String get settingDlnaEnabledDescription =>
      'Muestra imágenes y reproduce contenido enviado desde Home Assistant o cualquier aplicación DLNA. El dispositivo aparece como un reproductor multimedia con el nombre del dispositivo.';

  @override
  String get settingDlnaAudioBackgroundTitle =>
      'Mantener el audio en segundo plano';

  @override
  String get settingDlnaAudioBackgroundDescription =>
      'El audio recibido se reproduce sin ocupar la pantalla.';

  @override
  String get settingDlnaPortTitle => 'Puerto del servidor';

  @override
  String get settingDlnaPortDescription =>
      'El puerto que usa el receptor se completa cuando este inicia. Cámbialo para usar otro puerto o déjalo vacío para que el receptor elija uno de nuevo.';

  @override
  String get settingDlnaPortPlaceholder =>
      'Se establece cuando inicia el receptor';

  @override
  String get settingEsphomeRealMacTitle =>
      'Usar la dirección MAC real del Wi-Fi';

  @override
  String get settingEsphomeRealMacDescription =>
      'Home Assistant vincula este kiosko con el mismo dispositivo que tus integraciones de red ya detectan. Si cambias esta opción, se crea un nuevo dispositivo ESPHome en Home Assistant.';

  @override
  String get settingEsphomeMacOverrideTitle =>
      'Usar una dirección MAC de Wi-Fi personalizada';

  @override
  String get settingEsphomeMacOverrideDescription =>
      'Como no se puede obtener la dirección MAC, puedes introducir una aquí. Si la cambias, se crea un nuevo dispositivo ESPHome en Home Assistant.';

  @override
  String get esphomeAdvanced => 'Configuración avanzada';

  @override
  String get esphomeAdvancedHelp =>
      'Dirección MAC de Wi-Fi real o personalizada';

  @override
  String get esphomeMacInvalid => 'Introduce una dirección MAC válida.';

  @override
  String esphomeMacHardware(String mac) {
    return 'Se está usando $mac.';
  }

  @override
  String esphomeMacManual(String mac) {
    return 'Se está usando $mac, introducida abajo.';
  }

  @override
  String get esphomeMacUnavailable =>
      'Android no permite obtener la dirección de hardware de este dispositivo.';

  @override
  String get settingAnnouncementsEnabledTitle => 'Activar anuncios';

  @override
  String get settingAnnouncementsEnabledDescription =>
      'Reproduce los anuncios que Home Assistant envía con la acción announce.';

  @override
  String get settingAnnouncementsTtsEngineTitle => 'Motor de texto a voz';

  @override
  String get settingAnnouncementsTtsEngineDescription =>
      'La entidad de texto a voz de Home Assistant que lee los anuncios.';

  @override
  String get esphomeTtsFirst => 'Primero disponible';

  @override
  String get settingAnnouncementsChimeTitle => 'Reproducir un tono primero';

  @override
  String get settingAnnouncementsChimeDescription =>
      'Reproduce un tono antes del anuncio.';

  @override
  String get settingAnnouncementsChimeFileTitle => 'Sonido del tono';

  @override
  String get settingAnnouncementsChimeFileDescription =>
      'Se reproduce al volumen de notificaciones.';

  @override
  String get esphomeAnnouncements => 'Anuncios';

  @override
  String get esphomeAnnouncementsHelp => 'Anuncios de voz de Home Assistant';

  @override
  String get esphomeChime => 'Tono';

  @override
  String get esphomeTtsUnavailable => 'No se pudo conectar con Home Assistant';

  @override
  String get settingBtproxyEnabledTitle => 'Activar proxy Bluetooth';

  @override
  String get settingBtproxyEnabledDescription =>
      'Conecta los dispositivos Bluetooth cercanos con Home Assistant a través de este kiosko.';

  @override
  String get settingBtproxyScanDutyTitle => 'Intensidad del escaneo';

  @override
  String get settingBtproxyScanDutyDescription =>
      'Cuánto tiempo escucha la radio. Una intensidad menor reduce el uso de CPU. Los dispositivos que transmiten con poca frecuencia tardan más en aparecer.';

  @override
  String get settingBtproxyConnectionsTitle =>
      'Permitir conexiones a dispositivos';

  @override
  String get settingBtproxyConnectionsDescription =>
      'Home Assistant puede conectarse a dispositivos Bluetooth a través de este proxy.';

  @override
  String get settingBtproxyMacLookupTitle =>
      'Consultar fabricantes de dispositivos en línea';

  @override
  String get settingBtproxyMacLookupDescription =>
      'Identifica los dispositivos cercanos desconocidos por el prefijo de su dirección de hardware mediante api.macvendors.com. Solo se envía el prefijo de 3 bytes del fabricante, una vez por fabricante. Ningún otro dato sale del dispositivo.';

  @override
  String get settingBtproxyNearbySortTitle => 'Ordenar por';

  @override
  String get settingBtproxyNearbySortDescription =>
      'El orden de la lista de dispositivos cercanos que aparece abajo.';

  @override
  String get settingBtproxyMinConnectRssiTitle =>
      'Señal mínima para conexiones';

  @override
  String get settingBtproxyMinConnectRssiDescription =>
      'Rechaza las conexiones a dispositivos cuya señal sea más débil que este valor, para que las atienda un proxy más cercano.';

  @override
  String get esphomeOptionContinuous => 'Continuo';

  @override
  String get esphomeOptionBalanced => 'Equilibrado';

  @override
  String get esphomeOptionLowPower => 'Bajo consumo';

  @override
  String get esphomeOptionLastSeen => 'Última detección';

  @override
  String get esphomeOptionName => 'Nombre';

  @override
  String get esphomeOptionMacAddress => 'Dirección MAC';

  @override
  String get esphomeOptionSignalStrength => 'Intensidad de la señal';

  @override
  String get esphomeOptionNoLimit => 'Sin límite';

  @override
  String get esphomeOption70DbmSameRoom => '-70 dBm (misma habitación)';

  @override
  String get esphomeOption80Dbm => '-80 dBm';

  @override
  String get esphomeOption85Dbm => '-85 dBm';

  @override
  String get esphomeOption90DbmEdgeOfRange => '-90 dBm (límite de alcance)';

  @override
  String get esphomeBluetooth => 'Proxy Bluetooth';

  @override
  String get esphomeBluetoothHelp =>
      'Conecta los dispositivos Bluetooth cercanos con Home Assistant';

  @override
  String get esphomeBluetoothOff =>
      'Bluetooth está desactivado. Actívalo para usar el proxy.';

  @override
  String get esphomeBluetoothUnsupported =>
      'No disponible en este dispositivo: no tiene Bluetooth.';

  @override
  String get esphomeBluetoothBuildUnsupported =>
      'No disponible en este dispositivo: su versión de Android no admite Bluetooth LE.';

  @override
  String get esphomeIdentityBthome => 'Sensor BTHome';

  @override
  String get esphomeIdentityXiaomi => 'Sensor Xiaomi';

  @override
  String get esphomeIdentityQingping => 'Sensor Qingping';

  @override
  String get esphomeIdentityGoogleNest => 'Dispositivo Google/Nest';

  @override
  String get esphomeIdentityEddystone => 'Baliza Eddystone';

  @override
  String get esphomeIdentityGoogleFastPair => 'Dispositivo Google Fast Pair';

  @override
  String get esphomeIdentityAppleFindMy => 'Dispositivo Apple Find My';

  @override
  String get esphomeIdentityExposure => 'Notificación de exposición (teléfono)';

  @override
  String get esphomeIdentityAugustYale => 'Cerradura August/Yale';

  @override
  String get esphomeIdentityAmazon => 'Dispositivo Amazon';

  @override
  String get esphomeIdentityTile => 'Localizador Tile';

  @override
  String get esphomeIdentityInput =>
      'Dispositivo de entrada (control remoto/teclado)';

  @override
  String get esphomeIdentityHeartRate => 'Sensor de frecuencia cardíaca';

  @override
  String get esphomeIdentityEnvironmental => 'Sensor ambiental';

  @override
  String get esphomeIdentityApple => 'Dispositivo Apple';

  @override
  String get esphomeIdentityWindows => 'PC con Windows';

  @override
  String get esphomeIdentitySamsung => 'Dispositivo Samsung';

  @override
  String get esphomeIdentityGoogle => 'Dispositivo Google';

  @override
  String get esphomeIdentityUnknown => 'Dispositivo desconocido';

  @override
  String esphomeIdentityVendor(String vendor) {
    return 'Dispositivo $vendor';
  }

  @override
  String get esphomeNearby => 'Dispositivos cercanos';

  @override
  String get esphomeNearbySearch =>
      'Los dispositivos Bluetooth que detecta este kiosko, con sus nombres cuando se conocen.';

  @override
  String get esphomeNearbyEmpty => 'Aún no se ha detectado ningún dispositivo.';

  @override
  String get esphomeNearbyWaiting =>
      'Aún no se ha detectado ningún dispositivo. Los dispositivos aparecen aquí cuando el proxy empieza a escanear.';

  @override
  String get esphomeRotating => '(dirección variable)';

  @override
  String esphomeNearbyCount(String count, String total) {
    return 'Se muestran los primeros $count de $total.';
  }

  @override
  String esphomeSlots(String count) {
    return 'Se pueden conectar hasta $count dispositivos a la vez a través de este proxy. Home Assistant conecta los demás dispositivos a través de otros proxies.';
  }

  @override
  String esphomeSecondsAgo(String count) {
    return 'hace $count s';
  }

  @override
  String esphomeMinutesAgo(String count) {
    return 'hace $count min';
  }

  @override
  String esphomeHoursAgo(String count) {
    return 'hace $count h';
  }

  @override
  String get settingLocationEnabledTitle => 'Informar ubicación';

  @override
  String get settingLocationEnabledDescription =>
      'Lee la posición del GPS y la expone en Home Assistant como sensores de latitud, longitud, precisión, altitud y velocidad. Activar o desactivar esta opción vuelve a registrar el dispositivo ESPHome.';

  @override
  String get settingLocationIntervalTitle => 'Intervalo de actualización';

  @override
  String get settingLocationIntervalDescription =>
      'Segundos entre lecturas de posición.';

  @override
  String get esphomeGps => 'Sensor GPS';

  @override
  String get esphomeGpsHelp =>
      'Expone los datos del sensor GPS en Home Assistant';

  @override
  String get esphomeLocationOff => 'Desactivado.';

  @override
  String get esphomeLocationWaiting =>
      'Esperando la primera posición. Un inicio en frío a cielo abierto puede tardar unos minutos.';

  @override
  String get esphomeCoordinates => 'Últimas coordenadas';

  @override
  String get esphomeLocationDenied =>
      'No se ha concedido el permiso de ubicación.';

  @override
  String get esphomeLocationAbsent => 'No hay receptor GPS.';

  @override
  String esphomeLocationError(String error) {
    return 'GPS no disponible: $error';
  }

  @override
  String get esphomeLocationUnsupported =>
      'No disponible en este dispositivo: no tiene receptor GPS.';

  @override
  String get settingNotificationsTransparencyTitle => 'Transparencia';

  @override
  String get settingNotificationsTransparencyDescription =>
      'Permite ver la pantalla a través de las tarjetas de notificación. El texto y los iconos se mantienen opacos.';

  @override
  String get settingNotificationsBlurTitle => 'Desenfoque del fondo';

  @override
  String get settingNotificationsBlurDescription =>
      'Desenfoca lo que se ve a través de una tarjeta de notificación transparente. Nota: el desenfoque no se puede aplicar sobre el panel de control de Home Assistant.';

  @override
  String get settingNotificationsChimeFileTitle => 'Sonido de notificación';

  @override
  String get settingNotificationsChimeFileDescription =>
      'Los archivos de sonido se leen desde Android/data/me.jxl.kiosk_satellite/files/sounds en el dispositivo. También puedes acceder a esa carpeta desde el Administrador de archivos.';

  @override
  String get settingNotificationsVolumeTitle => 'Volumen de notificaciones';

  @override
  String get settingNotificationsVolumeDescription =>
      'Volumen del sonido de notificación, independiente de los volúmenes de contenido multimedia y del asistente.';

  @override
  String get esphomeNotifications => 'Notificaciones';

  @override
  String get esphomeNotificationsHelp =>
      'Transparencia, desenfoque, sonido y notificación de prueba';

  @override
  String get esphomeAppearance => 'Apariencia';

  @override
  String get esphomeSound => 'Sonido';

  @override
  String get esphomeNotificationTest => 'Notificación de prueba';

  @override
  String esphomeNotificationHelp(String action) {
    return 'Las notificaciones se envían desde Home Assistant con la acción $action. La prueba muestra una sobre el panel de control.';
  }

  @override
  String get esphomeNotificationBody =>
      'Así se ve y suena una notificación de Home Assistant.';

  @override
  String get esphomeNotificationSearch =>
      'La acción de Home Assistant que envía notificaciones y un botón para mostrar una.';

  @override
  String get esphomeLocation => 'Ubicación';

  @override
  String get esphomeLocationSearch =>
      'El permiso de ubicación que necesitan los sensores de ubicación.';

  @override
  String get esphomeBluetoothSearch =>
      'El permiso de dispositivos cercanos que necesita el proxy Bluetooth para escanear.';

  @override
  String get esphomeLocationMissing =>
      'Sin este permiso no se puede leer el receptor GPS y los sensores de ubicación quedan sin datos.';

  @override
  String get esphomeLocationServicesOff =>
      'La ubicación está desactivada en los ajustes del dispositivo, por lo que el receptor no proporciona datos.';

  @override
  String get esphomeLocationGranted =>
      'Los sensores de ubicación pueden leer el receptor GPS.';

  @override
  String get esphomeBluetoothGranted =>
      'El proxy puede escanear dispositivos Bluetooth cercanos.';

  @override
  String get esphomeBluetoothMissing =>
      'Sin este permiso, el proxy no puede escanear dispositivos.';

  @override
  String get esphomeBluetoothLocationMissing =>
      'Android solo proporciona resultados del escaneo Bluetooth, incluidas las balizas, cuando se concede el permiso de ubicación. El proxy nunca lee la posición del dispositivo.';

  @override
  String get esphomeBluetoothLocationOff =>
      'La ubicación está desactivada en los ajustes del dispositivo, por lo que el escaneo Bluetooth no encuentra nada.';

  @override
  String get esphomeBluetoothBeacons =>
      'El escaneo Bluetooth puede detectar balizas.';

  @override
  String get esphomeSent => 'Enviada';

  @override
  String get esphomeNotsaved => 'No se guardó';

  @override
  String get settingEsphomeEnabledTitle => 'Activar ESPHome';

  @override
  String get settingEsphomeEnabledDescription =>
      'Presenta este kiosko a Home Assistant como un dispositivo ESPHome, con sus sensores y controles como entidades nativas. Se descubre automáticamente.';

  @override
  String get settingEsphomeEntitiesTitle => 'Exponer las entidades del kiosko';

  @override
  String get settingEsphomeEntitiesDescription =>
      'Expone los sensores y controles de este dispositivo como entidades ESPHome.';

  @override
  String get settingEsphomeExcludedEntitiesTitle => 'Entidades excluidas';

  @override
  String get settingEsphomeExcludedEntitiesDescription =>
      'Elige las entidades que quieres excluir de Home Assistant. Se exponen todas las demás entidades disponibles. Al guardar, ESPHome vuelve a conectarse.';

  @override
  String get settingEsphomeNodeNameTitle => 'Nombre del nodo';

  @override
  String get settingEsphomeNodeNameDescription =>
      'Identifica este kiosko en la red. Home Assistant usa este nombre para crear los nombres de sus acciones. Si lo cambias, también cambian los nombres de esas acciones.';

  @override
  String get settingEsphomeNodeNamePlaceholder =>
      'Se establece al iniciar por primera vez';

  @override
  String get settingBtproxyKeyTitle => 'Clave de cifrado';

  @override
  String get settingBtproxyKeyDescription =>
      'Pega esta clave en Home Assistant cuando te pida la clave de cifrado. Se genera automáticamente al iniciar por primera vez.';

  @override
  String get settingBtproxyKeyPlaceholder =>
      'Se genera al iniciar por primera vez';

  @override
  String get settingBtproxyPortTitle => 'Puerto de la API';

  @override
  String get settingBtproxyPortDescription =>
      'El puerto al que se conecta Home Assistant. Déjalo vacío para usar el puerto estándar de ESPHome, 6053.';

  @override
  String esphomeStartFailed(String error) {
    return 'El servidor ESPHome no pudo iniciarse: $error';
  }

  @override
  String get esphomeExcludedInvalid =>
      'Elige una lista de identificadores de entidades.';

  @override
  String settingsMadeBy(String heart, String author) {
    return 'Hecho con $heart por $author';
  }

  @override
  String get settingsBuyCoffee => 'Invítame a un café';

  @override
  String get settingClapStrictnessTitle => 'Detección de palmadas';

  @override
  String get settingClapStrictnessDescription =>
      'El modo estricto necesita palmadas más fuertes y espaciadas de forma regular. Pruébalo si los ruidos de casa activan los gestos por error.';

  @override
  String get gestureStrictnessStandard => 'Estándar';

  @override
  String get gestureStrictnessStrict => 'Estricto';

  @override
  String get gestureOff => 'Los gestos están desactivados';

  @override
  String get gestureOffHelp =>
      'Desactivar gestos está activado en la configuración del modo kiosko.';

  @override
  String get gestureEmpty => 'No hay gestos configurados';

  @override
  String get gestureEmptyHelp =>
      'Un gesto ejecuta su acción sin ningún control visible.';

  @override
  String get gestureDeleteTooltip => 'Eliminar gesto';

  @override
  String get gestureDeleteTitle => '¿Eliminar gesto?';

  @override
  String gestureDeleteMessage(String trigger, String action) {
    return '¿Eliminar este gesto? Gesto: $trigger. Acción: $action.';
  }

  @override
  String get gestureAdd => 'Añadir gesto';

  @override
  String get gestureAddHelp => 'Elige un gesto y la acción que ejecuta.';

  @override
  String get gestureTouchHelp =>
      'Los gestos se detectan sin bloquearlos: los toques también llegan al panel de control. Usar esquinas y varios dedos evita activar sus controles por accidente.';

  @override
  String get gestureClapper => 'Control por palmadas';

  @override
  String get gestureReadFailed => 'No se pudo leer la configuración.';

  @override
  String get gestureHandGestures => 'Gestos de la mano';

  @override
  String get settingHandGestureHoldSecondsTitle => 'Tiempo de espera';

  @override
  String get settingHandGestureHoldSecondsDescription =>
      'Mantén el mismo gesto de los dedos durante este tiempo antes de ejecutar la acción. Auméntalo para reducir las activaciones accidentales.';

  @override
  String get gestureHoldInstant => 'Al instante';

  @override
  String gestureHoldSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get settingHaHoldModeTitle => 'Modo de pausa';

  @override
  String get settingHaHoldModeDescription =>
      'Mantiene la vista actual en pantalla. El protector de pantalla, la rotación de vistas y el temporizador de regreso al inicio quedan en pausa hasta desactivarlo.';

  @override
  String get settingHaHoldReleaseMinutesTitle =>
      'Terminar la pausa automáticamente después de';

  @override
  String get settingHaHoldReleaseMinutesDescription =>
      'Desactiva el modo de pausa al cumplirse el tiempo indicado. Con 0, continúa hasta desactivarlo manualmente.';

  @override
  String get settingHaHoldMenuTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingHaHoldMenuDescription =>
      'Añade una opción al menú para activar y desactivar el modo de pausa.';

  @override
  String get haHoldHint =>
      'Mantiene la vista actual, finalización automática y opción de menú';

  @override
  String get haNever => 'Nunca';

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
  String get settingDisableSuspendTitle =>
      'Mantener la conexión en segundo plano';

  @override
  String get settingDisableSuspendDescription =>
      'Desactiva la opción «Suspender conexiones en segundo plano» de Home Assistant, que de otro modo cerraría la conexión unos minutos después de apagarse la pantalla.';

  @override
  String get settingFreezeOnScreensaverTitle =>
      'Pausar el panel de control durante el protector de pantalla';

  @override
  String get settingFreezeOnScreensaverDescription =>
      'Deja de dibujar el panel de control mientras lo cubre el protector de pantalla para reducir el uso de CPU y GPU. La conexión sigue activa. No se aplica al modo Atenuar.';

  @override
  String get settingWsFilterTitle =>
      'Filtrar las actualizaciones del panel de control';

  @override
  String get settingWsFilterDescription =>
      'Procesa solo las actualizaciones de las entidades de la vista actual para reducir las interrupciones en tabletas poco potentes. Las vistas cuyas entidades no se puedan determinar quedan sin filtrar.';

  @override
  String get settingPauseDashboardCamerasTitle =>
      'Pausar las cámaras del panel de control durante el protector de pantalla';

  @override
  String get settingPauseDashboardCamerasDescription =>
      'Pausa las transmisiones de cámara compatibles y silenciadas del panel de control de Home Assistant mientras lo cubre el protector de pantalla. Se reconectan al cerrarlo. No afecta a la cámara del dispositivo ni a la función Transmisiones de cámara.';

  @override
  String get haOptimizations => 'Optimizaciones';

  @override
  String get haOptimizationsHint =>
      'Conexión en segundo plano, pausa del panel de control y las cámaras, filtro de actualizaciones';

  @override
  String get haScanUnavailable =>
      'Los detalles del análisis no están disponibles para la vista actual.';

  @override
  String get haScanDetails => 'Detalles del análisis del panel de control';

  @override
  String haWatchedTitle(String count) {
    return 'Entidades supervisadas ($count)';
  }

  @override
  String get haWatched => 'Entidades supervisadas';

  @override
  String get haEntityListUnavailable =>
      'La lista de entidades no está disponible en este momento.';

  @override
  String haWatching(String count) {
    return 'Se supervisan $count entidades en esta vista.';
  }

  @override
  String get haNoUpdates => 'No hubo actualizaciones en el último minuto.';

  @override
  String haFiltered(String percent, String dropped, String total) {
    return 'Se filtró el $percent% de las actualizaciones del último minuto ($dropped de $total).';
  }

  @override
  String get haRawUpdates =>
      'Un elemento de esta página recibe todas las actualizaciones de entidades de todas formas, por lo que el filtrado ahorra menos aquí.';

  @override
  String get haAllStates =>
      'Esta vista lee los estados de todas las entidades, por lo que sus actualizaciones no se filtran.';

  @override
  String get haUnknownEntities =>
      'No se pueden determinar las entidades de esta vista, por lo que sus actualizaciones no se filtran.';

  @override
  String get haWaiting => 'Esperando a que se cargue el panel de control…';

  @override
  String get haShowScan => 'Mostrar detalles del análisis.';

  @override
  String haThreshold(String count) {
    return 'Esta vista usa $count entidades, lo que supera el umbral del filtro. El filtrado está desactivado.';
  }

  @override
  String get settingHaReturnHomeEnabledTitle =>
      'Volver a la vista de inicio del panel de control';

  @override
  String get settingHaReturnHomeEnabledDescription =>
      'Vuelve al panel de control configurado arriba después de un periodo de inactividad.';

  @override
  String get settingHaReturnHomeSecondsTitle => 'Volver después de (segundos)';

  @override
  String get settingHaReturnHomeSecondsDescription =>
      'Periodo de inactividad antes de que el kiosko vuelva.';

  @override
  String get haReturnHint =>
      'Vuelve a la vista de inicio tras un periodo de inactividad';

  @override
  String get haReturnDisabled =>
      'Se desactiva mientras está activa la rotación de vistas del panel de control.';

  @override
  String get haReturnNoPath =>
      'El panel de control configurado no tiene una ruta de vista a la que volver.';

  @override
  String haReturnPath(String path) {
    return 'Vuelve a \"$path\" al cumplirse el tiempo de espera.';
  }

  @override
  String get settingHaRotationEnabledTitle =>
      'Activar la rotación de vistas del panel de control';

  @override
  String get settingHaRotationEnabledDescription =>
      'Recorre las vistas seleccionadas del panel de control en un ciclo continuo y muestra cada una durante el número de segundos elegido.';

  @override
  String get settingHaRotationSecondsTitle => 'Segundos por vista';

  @override
  String get settingHaRotationSecondsDescription =>
      'Cuánto tiempo permanece cada vista en pantalla.';

  @override
  String get settingHaRotationPauseSecondsTitle =>
      'Pausa de la rotación al interactuar (segundos)';

  @override
  String get settingHaRotationPauseSecondsDescription =>
      'Tocar la pantalla pausa la rotación durante este tiempo y cada toque reinicia la cuenta. Las interacciones de voz la pausan hasta que terminan. Con 0, los toques no pausan la rotación.';

  @override
  String get settingHaRotationCrossfadeTitle => 'Fundido entre vistas';

  @override
  String get settingHaRotationCrossfadeDescription =>
      'Se desvanece hasta el fondo y luego aparece la siguiente vista en lugar de cambiar al instante. Los cambios a otro panel de control o a una página externa siguen siendo instantáneos.';

  @override
  String get settingHaRotationFadeSecondsTitle =>
      'Duración del fundido (segundos)';

  @override
  String get settingHaRotationFadeSecondsDescription =>
      'Tiempo total de desaparición y aparición. Cargar la siguiente vista puede añadir tiempo, sobre todo al abrirla por primera vez.';

  @override
  String get haRotation => 'Rotación de vistas del panel de control';

  @override
  String get haRotationHint =>
      'Recorre las vistas, duración de cada vista y fundido';

  @override
  String get haDefaultView => 'Vista predeterminada';

  @override
  String get haExternalPages => 'Páginas externas';

  @override
  String get haFadeError =>
      'Elige una duración de fundido entre 0.2 y 5 segundos.';

  @override
  String get haPauseRemoteHelp =>
      'Tocar la pantalla pausa la rotación durante este tiempo y cada toque reinicia la cuenta. Las interacciones de voz la pausan hasta que terminan. Con 0, los toques no pausan la rotación.';

  @override
  String get settingHaUrlTitle => 'URL base de Home Assistant';

  @override
  String get settingHaUrlDescription =>
      'Por ejemplo, https://homeassistant.local:8123, sin la ruta de un panel de control.';

  @override
  String get settingHaTokenTitle => 'Token de acceso de larga duración';

  @override
  String get settingHaTokenDescription =>
      'Se crea en tu perfil de Home Assistant → Seguridad.';

  @override
  String get settingHaAutoLoginTitle => 'Iniciar sesión automáticamente';

  @override
  String get settingHaAutoLoginDescription =>
      'Inicia sesión en el panel de control con el token de acceso indicado arriba en lugar de mostrar la página de inicio de sesión de Home Assistant.';

  @override
  String get haValidate => 'Validar';

  @override
  String get haValidateConnection => 'Validar conexión';

  @override
  String get haChecking => 'Comprobando…';

  @override
  String get haConnected => 'Conectado';

  @override
  String get haConnectedRemote => 'Conectado.';

  @override
  String get haNotValidated =>
      'Aún no se ha validado. Las opciones de abajo se habilitan cuando se confirma la conexión.';

  @override
  String get haConnectFailed => 'No se pudo conectar.';

  @override
  String get haNotConfigured =>
      'La URL y el token de Home Assistant no están configurados';

  @override
  String get haInvalidToken => 'Token no válido';

  @override
  String haUnreachable(String error) {
    return 'No se pudo conectar con Home Assistant: $error';
  }

  @override
  String get haProxy => 'Proxy de contexto seguro';

  @override
  String get haProxyHelp =>
      'Pasa la conexión http de Home Assistant por un proxy dentro de la aplicación para que el navegador habilite el micrófono y otras funciones exclusivas de https. Solo para direcciones http.';

  @override
  String get haProxyRemoteHelp =>
      'Pasa la conexión http de Home Assistant por un proxy dentro de la aplicación para que el navegador habilite el micrófono y otras funciones exclusivas de https. Solo para direcciones http.';

  @override
  String get haProxyNotice =>
      'Esta dirección de Home Assistant usa http y los navegadores bloquean el micrófono y otras funciones en páginas http. Kiosk Satellite pasará el panel de control por un proxy seguro dentro de la aplicación para habilitarlas. Es posible que tengas que volver a iniciar sesión en Home Assistant.';

  @override
  String get haProxyRemoteNotice =>
      'Esta dirección de Home Assistant usa http y los navegadores bloquean el micrófono y otras funciones en páginas http. Kiosk Satellite pasará el panel de control por un proxy seguro dentro de la aplicación para habilitarlas. Es posible que tengas que volver a iniciar sesión en Home Assistant en la tableta.';

  @override
  String get haDashboard => 'Panel de control';

  @override
  String get haChooseView => 'Elegir una vista';

  @override
  String get haLoadingDashboards => 'Cargando paneles de control…';

  @override
  String get haListFailed => 'No se pudieron listar los paneles de control';

  @override
  String get haRetryHint => 'Toca para volver a intentarlo.';

  @override
  String get haChangeView => 'Cambiar vista';

  @override
  String get haNoViews => 'No hay vistas secundarias';

  @override
  String get haNoViewsHelp =>
      'Este panel de control no tiene vistas secundarias seleccionables.';

  @override
  String get haNoDashboards => 'No se encontraron paneles de control';

  @override
  String get settingHaThemeTitle => 'Tema';

  @override
  String get settingHaThemeDescription =>
      'Tema claro u oscuro para el panel de control de Home Assistant. También se puede elegir desde la entidad Tema de Home Assistant. Automático sigue las opciones de abajo.';

  @override
  String get settingThemeMatchAppTitle =>
      'Sincronizar el tema de Home Assistant con Kiosk Satellite';

  @override
  String get settingThemeMatchAppDescription =>
      'Adapta automáticamente el tema de Home Assistant al de la interfaz de Kiosk Satellite.';

  @override
  String get settingThemeAutoTitle => 'Cambiar el tema según la hora';

  @override
  String get settingThemeAutoDescription =>
      'Cambia Home Assistant entre claro y oscuro según un horario. Conserva el tema seleccionado y cambia solo su variante clara u oscura.';

  @override
  String get settingThemeDarkAtTitle => 'Tema oscuro a las';

  @override
  String get settingThemeDarkAtDescription =>
      'Hora local para cambiar al tema oscuro.';

  @override
  String get settingThemeLightAtTitle => 'Tema claro a las';

  @override
  String get settingThemeLightAtDescription =>
      'Hora local para volver al tema claro.';

  @override
  String get settingThemeAutoAppTitle =>
      'Cambiar también el tema de la aplicación';

  @override
  String get settingThemeAutoAppDescription =>
      'Cambia el tema de Kiosk Satellite (menú y configuración) junto con el cambio programado de Home Assistant.';

  @override
  String get haThemeHint =>
      'Sincroniza con la aplicación o cambia entre claro y oscuro según un horario';

  @override
  String get haThemeAuto => 'Automático';

  @override
  String get settingHaKioskModeTitle => 'Modo kiosko de HA';

  @override
  String get settingHaKioskModeDescription =>
      'Oculta la cabecera y la barra lateral de Home Assistant. Se aplica de inmediato.';

  @override
  String get settingHaKioskHideHeaderTitle => 'Ocultar la cabecera';

  @override
  String get settingHaKioskHideHeaderDescription =>
      'Oculta la barra de herramientas del panel de control y las pestañas de las vistas mientras está activo el modo kiosko de HA. Déjalo desactivado si cambias de vista desde la cabecera.';

  @override
  String get settingHaKioskHideSidebarTitle => 'Ocultar la barra lateral';

  @override
  String get settingHaKioskHideSidebarDescription =>
      'Oculta la barra lateral de navegación mientras está activo el modo kiosko de HA.';

  @override
  String get settingHaKioskMenuTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingHaKioskMenuDescription =>
      'Añade una opción al menú del kiosko para activar y desactivar el modo kiosko de HA.';

  @override
  String get settingHaDashboardCarouselTitle =>
      'Activar el carrusel del panel de control';

  @override
  String get settingHaDashboardCarouselDescription =>
      'Desliza a izquierda o derecha sobre el panel de control para cambiar de vista. No afecta a los gestos sobre controles deslizantes, mapas y tarjetas con desplazamiento.';

  @override
  String get settingHaCarouselOverCardsTitle =>
      'Capturar deslizamientos sobre tarjetas';

  @override
  String get settingHaCarouselOverCardsDescription =>
      'Cambia de vista incluso cuando el gesto comienza sobre una tarjeta que responde a deslizamientos. Los controles deslizantes siguen funcionando normalmente.';

  @override
  String get settingHaHapticsTitle => 'Activar la vibración';

  @override
  String get settingHaHapticsDescription =>
      'Vibra al usar botones, interruptores, tarjetas, controles deslizantes y diales de termostato. Requiere un motor de vibración.';

  @override
  String get settingHaHapticsStrengthTitle => 'Intensidad de la vibración';

  @override
  String get settingHaHapticsStrengthDescription =>
      'Qué tan intensa se siente la vibración.';

  @override
  String get settingHaTapSoundTitle => 'Reproducir sonidos al tocar';

  @override
  String get settingHaTapSoundDescription =>
      'Reproduce el sonido de toque de Android al usar botones, interruptores, tarjetas, controles deslizantes y diales de termostato.';

  @override
  String get settingHaTapSoundVolumeTitle => 'Volumen del sonido de toque';

  @override
  String get settingHaTapSoundVolumeDescription =>
      'Qué tan fuerte suena cada toque.';

  @override
  String get haUserInterface => 'Interfaz de usuario';

  @override
  String get haInterfaceHint =>
      'Modo kiosko, carrusel del panel de control, vibración y sonidos de toque';

  @override
  String get haHaptics => 'Vibración y sonidos';

  @override
  String get haVibrationLight => 'Suave';

  @override
  String get haVibrationMedium => 'Media';

  @override
  String get haVibrationStrong => 'Fuerte';

  @override
  String get settingHomeLauncherEnabledTitle => 'Usar como pantalla de inicio';

  @override
  String get settingHomeLauncherEnabledDescription =>
      'Registra Kiosk Satellite como pantalla de inicio del dispositivo: el kiosko se abre al encenderlo y cada pulsación de Inicio vuelve a él. Se desactiva y restaura el lanzador anterior si la aplicación falla al iniciarse repetidamente.';

  @override
  String get settingHomeKeepPinningTitle => 'Mantener fijación de pantalla';

  @override
  String get settingHomeKeepPinningDescription =>
      'Fija la pantalla incluso cuando Kiosk Satellite es la pantalla de inicio. Bloquea los botones Aplicaciones recientes y Atrás a nivel del sistema, pero vuelve a mostrar la confirmación de fijación en dispositivos donde la aplicación no es propietaria del dispositivo.';

  @override
  String get kioskHomeScreen => 'Pantalla de inicio';

  @override
  String get kioskCheckingDevice => 'Comprobando el dispositivo...';

  @override
  String get kioskFireOs => 'Fire OS no permite sustituir su lanzador.';

  @override
  String get kioskUnsupported =>
      'Este dispositivo no permite cambiar la pantalla de inicio.';

  @override
  String get kioskRecovered =>
      'Se desactivó automáticamente tras varios fallos al iniciar y se restauró el lanzador anterior. Vuelve a activar el interruptor para intentarlo de nuevo.';

  @override
  String get kioskHeld =>
      'Kiosk Satellite es la pantalla de inicio. El kiosko se abre al encender el dispositivo y cada pulsación de Inicio vuelve a él.';

  @override
  String get kioskDisabled =>
      'No es la pantalla de inicio. Activa Usar como pantalla de inicio arriba.';

  @override
  String get kioskWaiting =>
      'Aún no es la pantalla de inicio actual: el dispositivo espera una confirmación.';

  @override
  String get kioskOpenHomeSettings => 'Abrir configuración de inicio';

  @override
  String get kioskSetDefault => 'Establecer como predeterminada';

  @override
  String get kioskActive => 'Activo';

  @override
  String get kioskNotHome => 'No es la pantalla de inicio.';

  @override
  String get kioskWaitingRemote =>
      'Esperando confirmación en el dispositivo: allí se abre el diálogo del sistema o la configuración de inicio.';

  @override
  String get kioskSetDevice => 'Configurar en el dispositivo';

  @override
  String get settingIntercomAnswerModeTitle => 'Modo de respuesta';

  @override
  String get settingIntercomAnswerModeDescription =>
      'Sonar pide que respondas en la pantalla. Responder automáticamente abre la llamada después de un tono.';

  @override
  String get settingIntercomRingSecondsTitle => 'Duración del timbre';

  @override
  String get settingIntercomRingSecondsDescription =>
      'Cuánto tiempo suena una llamada antes de marcarla como perdida.';

  @override
  String get settingIntercomRingSoundTitle => 'Sonido del timbre';

  @override
  String get settingIntercomRingSoundDescription =>
      'Se reproduce al volumen de las notificaciones.';

  @override
  String get settingIntercomAcceptAnnouncementsTitle => 'Aceptar anuncios';

  @override
  String get settingIntercomAcceptAnnouncementsDescription =>
      'Reproduce los anuncios enviados a todos desde otros kioskos.';

  @override
  String get intercomOptionAnswerRing => 'Sonar';

  @override
  String get intercomOptionAnswerAuto => 'Responder automáticamente';

  @override
  String get intercomOptionAnswerDnd => 'No molestar';

  @override
  String get intercomOptionAnswer15 => '15 segundos';

  @override
  String get intercomOptionAnswer30 => '30 segundos';

  @override
  String get intercomOptionAnswer45 => '45 segundos';

  @override
  String get intercomOptionAnswer60 => '60 segundos';

  @override
  String get intercomAnswerSection => 'Respuesta';

  @override
  String get settingIntercomEnabledTitle => 'Activar intercomunicador';

  @override
  String get settingIntercomEnabledDescription =>
      'Llama a los otros kioskos de esta red y recibe sus llamadas.';

  @override
  String get settingIntercomKeyTitle => 'Clave del intercomunicador';

  @override
  String get settingIntercomKeyDescription =>
      'Los kioskos con la misma clave pueden llamarse entre sí. La gestión de flota puede sincronizarla.';

  @override
  String get settingIntercomKeyPlaceholder =>
      'Se crea al activar el intercomunicador';

  @override
  String get settingIntercomMenuTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingIntercomMenuDescription =>
      'Añade la opción Intercomunicador al menú del kiosko.';

  @override
  String get intercomNeedsAdmin =>
      'El intercomunicador necesita la administración remota';

  @override
  String get intercomAdminHelp =>
      'Los kioskos se encuentran y se conectan a través de ella. Activa Administración remota y Buscar otros kioskos en Dispositivo y luego vuelve aquí.';

  @override
  String get intercomChangeKey => 'Cambiar clave';

  @override
  String get intercomChangeKeyHelp =>
      'Pega la clave de otro kiosko o crea una nueva.';

  @override
  String get intercomChange => 'Cambiar';

  @override
  String get intercomKeyWarning =>
      'Los kioskos con esta clave pueden llamarse entre sí. Una clave nueva desconecta este kiosko de los demás hasta que ellos también la tengan.';

  @override
  String get intercomRegenerate => 'Generar de nuevo';

  @override
  String get intercomKeyChanged => 'Clave cambiada';

  @override
  String get intercomNotSet => 'Sin configurar';

  @override
  String get intercomOpen => 'Abrir';

  @override
  String get settingIntercomTlsTitle => 'Cifrar comunicaciones';

  @override
  String get settingIntercomTlsDescription =>
      'Usa TLS para cifrar las llamadas de intercomunicación entre kioscos. Todos los kioscos de la llamada deben tener esta opción activada.';

  @override
  String get intercomKiosks => 'Kioskos';

  @override
  String get intercomRosterHelp =>
      'Kioscos detectados y miembros guardados de la flota. Un kiosco está listo cuando es accesible, tiene la intercomunicación activada y usa la misma clave y los mismos ajustes de cifrado.';

  @override
  String get intercomNoOther => 'No se encontraron otros kioskos';

  @override
  String get intercomRosterDeviceHelp =>
      'Aquí aparecen los kioskos que tienen activadas Administración remota y Buscar otros kioskos.';

  @override
  String get intercomNoneHeard => 'No se encontraron kioskos';

  @override
  String get intercomRosterRemoteHelp =>
      'Los kioskos aparecen al encontrarlos en la red o al estar guardados como miembros de la flota. Administración remota y Buscar otros kioskos deben estar activados.';

  @override
  String get intercomReady => 'Listo';

  @override
  String get intercomOff => 'Intercomunicador desactivado';

  @override
  String get intercomDifferentKey => 'Clave diferente';

  @override
  String get intercomUnreachable => 'No accesible';

  @override
  String get intercomOffline => 'Desconectado';

  @override
  String get intercomChecking => 'Comprobando…';

  @override
  String get settingIntercomTalkModeTitle => 'Modo de conversación';

  @override
  String get settingIntercomTalkModeDescription =>
      'Pulsar para hablar envía tu voz mientras mantienes pulsado el botón. Manos libres mantiene abierto el micrófono durante toda la llamada.';

  @override
  String get intercomOptionTalkPtt => 'Pulsar para hablar';

  @override
  String get intercomOptionTalkHandsfree => 'Manos libres';

  @override
  String get intercomTalkSection => 'Conversación';

  @override
  String get settingKioskAllowDrawerTitle =>
      'Permitir menú con acciones rápidas';

  @override
  String get settingKioskAllowDrawerDescription =>
      'Un deslizamiento desde el borde abre el menú sin gesto de salida ni PIN, limitado a las acciones seleccionadas abajo.';

  @override
  String get settingKioskAllowDashboardTitle => 'Panel de control';

  @override
  String get settingKioskAllowDashboardDescription =>
      'Vuelve a cargar la página de inicio.';

  @override
  String get settingKioskAllowHaKioskTitle => 'Modo kiosko de HA';

  @override
  String get settingKioskAllowHaKioskDescription =>
      'Muestra u oculta la cabecera y la barra lateral de Home Assistant.';

  @override
  String get settingKioskAllowCameraTitle => 'Vista de cámaras';

  @override
  String get settingKioskAllowCameraDescription =>
      'Abre la vista de cámaras predeterminada.';

  @override
  String get settingKioskAllowIntercomTitle => 'Intercomunicador';

  @override
  String get settingKioskAllowIntercomDescription =>
      'Llama a otros kioskos desde el menú del kiosko.';

  @override
  String get settingKioskAllowMusicTitle => 'Music Assistant';

  @override
  String get settingKioskAllowMusicDescription =>
      'Abre la interfaz web de Music Assistant.';

  @override
  String get settingKioskAllowSendspinPlayerTitle => 'Reproductor flotante';

  @override
  String get settingKioskAllowSendspinPlayerDescription =>
      'Muestra u oculta el reproductor flotante y abre Reproduciendo Ahora.';

  @override
  String get settingKioskAllowScreensaverTitle =>
      'Iniciar protector de pantalla';

  @override
  String get settingKioskAllowScreensaverDescription =>
      'Inicia el protector de pantalla ahora.';

  @override
  String get settingKioskAllowHoldTitle => 'Modo de pausa';

  @override
  String get settingKioskAllowHoldDescription =>
      'Activa o desactiva el modo de pausa.';

  @override
  String get settingKioskAllowLockdownTitle => 'Modo de bloqueo';

  @override
  String get settingKioskAllowLockdownDescription =>
      'Bloquea la pantalla hasta usar el gesto de salida o desbloquearla de forma remota.';

  @override
  String get settingKioskAllowThemeTitle => 'Selector de tema';

  @override
  String get settingKioskAllowThemeDescription =>
      'Cambia entre los temas claro y oscuro.';

  @override
  String get settingKioskAllowAppsTitle => 'Aplicaciones';

  @override
  String get settingKioskAllowAppsDescription =>
      'Abre el lanzador de aplicaciones. Si Desactivar botón Inicio está activado, abrir una aplicación libera la fijación del kiosko hasta que vuelvas a él.';

  @override
  String get kioskAllowedActions => 'Acciones permitidas';

  @override
  String get kioskAllowedHelp =>
      'Qué acciones rápidas ofrece el menú del kiosko';

  @override
  String get settingKioskEnabledTitle => 'Activar modo kiosko';

  @override
  String get settingKioskEnabledDescription =>
      'Mantiene la tablet en Kiosk Satellite. El gesto de salida sustituye al deslizamiento para abrir el menú, el botón Atrás permanece dentro del kiosko y se activan las protecciones de abajo.';

  @override
  String get settingKioskStartOnBootTitle => 'Iniciar al encender';

  @override
  String get settingKioskStartOnBootDescription =>
      'Abre Kiosk Satellite cuando se enciende el dispositivo. En Android 10 o posterior necesita el permiso para mostrarse sobre otras aplicaciones. Android lo solicita al activar esta opción por primera vez.';

  @override
  String get settingKioskExitGestureTitle => 'Gesto de salida del kiosko';

  @override
  String get settingKioskExitGestureDescription =>
      'Los toques rápidos en cualquier lugar abren el menú después de pedir el PIN, si hay uno. Las variantes que indican mantener pulsado requieren mantener el último toque. Si se desactiva, solo se puede acceder a la configuración desde la administración remota.';

  @override
  String get settingKioskPinTitle => 'PIN del modo kiosko';

  @override
  String get settingKioskPinDescription =>
      'Se solicita después del gesto de salida y antes de abrir el menú. Déjalo vacío para no usar PIN.';

  @override
  String get settingKioskDisableStatusBarTitle => 'Desactivar barra de estado';

  @override
  String get settingKioskDisableStatusBarDescription =>
      'Bloquea el despliegue de la barra de estado con una protección sobre el borde superior. Necesita el permiso para mostrarse sobre otras aplicaciones. Android lo solicita al activar esta opción por primera vez.';

  @override
  String get settingKioskDisableVolumeTitle => 'Desactivar botones de volumen';

  @override
  String get settingKioskDisableVolumeDescription =>
      'Ignora los botones físicos de volumen.';

  @override
  String get settingKioskDisablePowerTitle => 'Desactivar botón de encendido';

  @override
  String get settingKioskDisablePowerDescription =>
      'Android no permite bloquear el botón de encendido, así que la pantalla vuelve a encenderse en cuanto se pulsa. Aún puedes apagar la pantalla de forma remota.';

  @override
  String get settingKioskDisableHomeTitle => 'Desactivar botón Inicio';

  @override
  String get settingKioskDisableHomeDescription =>
      'Fija la aplicación con la función de fijación de pantalla de Android, que bloquea los botones Inicio y Aplicaciones recientes. Android pide confirmación la primera vez.';

  @override
  String get settingKioskDisableContextMenusTitle =>
      'Desactivar menús contextuales';

  @override
  String get settingKioskDisableContextMenusDescription =>
      'Impide los menús de pulsación prolongada y la selección de texto en la vista web.';

  @override
  String get settingKioskDisablePullRefreshTitle =>
      'Desactivar deslizar para actualizar';

  @override
  String get settingKioskDisablePullRefreshDescription =>
      'Ignora el gesto de deslizar para actualizar mientras el modo kiosko está activado.';

  @override
  String get settingKioskDisableGesturesTitle => 'Desactivar gestos';

  @override
  String get settingKioskDisableGesturesDescription =>
      'Ignora los gestos de la página Gestos mientras el modo kiosko está activado.';

  @override
  String get kioskGestureTaps5 => '5 toques rápidos';

  @override
  String get kioskGestureTaps7 => '7 toques rápidos';

  @override
  String get kioskGestureTaps5Hold => '5 toques rápidos, manteniendo el último';

  @override
  String get kioskGestureTaps7Hold => '7 toques rápidos, manteniendo el último';

  @override
  String get kioskGestureNone => 'Desactivado (solo administración remota)';

  @override
  String get kioskForeground => 'Kiosk Satellite puede volver al primer plano.';

  @override
  String get kioskOverlayMissing =>
      'Sin este permiso, el kiosko no puede volver al primer plano y la protección del modo de bloqueo solo cubre la aplicación.';

  @override
  String get kioskGuardHeld =>
      'El panel de notificaciones y las aplicaciones recientes se cierran automáticamente mientras la pantalla está protegida.';

  @override
  String get kioskGuardMissing =>
      'Sin este permiso, el panel de notificaciones y las aplicaciones recientes siguen siendo accesibles. Activa Kiosk Satellite en Accesibilidad.';

  @override
  String get kioskOverlayRemote =>
      'Sin este permiso, el kiosko no puede volver al primer plano. La pantalla para concederlo aparece en la tablet.';

  @override
  String get kioskGuardRemote =>
      'Sin este permiso, el panel de notificaciones y las aplicaciones recientes siguen siendo accesibles. Activa Kiosk Satellite en Accesibilidad en la tablet.';

  @override
  String get kioskGrantDevice => 'Conceder en el dispositivo';

  @override
  String get kioskOpenSettingsDevice => 'Abrir configuración en el dispositivo';

  @override
  String get settingLockdownEnabledTitle => 'Activar modo de bloqueo';

  @override
  String get settingLockdownEnabledDescription =>
      'Desactiva las interacciones con la pantalla hasta que se desactive desde Home Assistant o con el gesto de salida.';

  @override
  String get settingLockdownMenuTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingLockdownMenuDescription =>
      'Añade una opción de modo de bloqueo al menú del kiosko para bloquear la pantalla. Usa el gesto de salida, la administración remota o Home Assistant para desbloquearla.';

  @override
  String get settingLockdownBlackoutTitle => 'Pantalla en negro';

  @override
  String get settingLockdownBlackoutDescription =>
      'Pone la pantalla en negro mientras está bloqueada.';

  @override
  String get settingLockdownAllowScreensaverTitle =>
      'Permitir el protector de pantalla';

  @override
  String get settingLockdownAllowScreensaverDescription =>
      'Permite que el protector de pantalla funcione mientras la pantalla está bloqueada. La detección de movimiento no lo desactiva hasta que se quite el bloqueo.';

  @override
  String get settingLockdownExitGestureTitle => 'Gesto de salida del bloqueo';

  @override
  String get settingLockdownExitGestureDescription =>
      'Los toques rápidos en cualquier parte desactivan el modo de bloqueo, después de introducir el PIN del kiosko si hay uno. Las variantes que requieren mantener el toque necesitan que mantengas pulsado el último. Si se desactiva el gesto, solo la administración remota o Home Assistant pueden quitar el bloqueo.';

  @override
  String get lockdownGestureNone => 'Desactivado (solo de forma remota)';

  @override
  String get lockdownExplanation =>
      'El modo de bloqueo desactiva las interacciones con el panel de control, activa todas las protecciones del modo kiosko sin cambiar su configuración y silencia la detección de la palabra de activación mientras está activo. Con la protección de la interfaz del sistema activada arriba, también se bloquean el panel de notificaciones y las aplicaciones recientes. Home Assistant recibe un interruptor del modo de bloqueo a través de ESPHome.';

  @override
  String get lockdownSearch =>
      'Bloqueo táctil que se configura desde la administración remota. Sus permisos están en Permisos del sistema necesarios.';

  @override
  String get lockdownOverlayHeld => 'El bloqueo puede cubrir toda la pantalla.';

  @override
  String get lockdownOverlayMissing =>
      'Sin este permiso, el bloqueo solo cubre la aplicación. La pantalla para concederlo aparece en la tablet.';

  @override
  String get lockdownPermissionsSearch =>
      'Los permisos que necesitan las protecciones del modo de bloqueo.';

  @override
  String get mediaCacheTitle => 'Caché de portadas';

  @override
  String get mediaCacheReadFailed => 'No se pudo leer el tamaño de la caché.';

  @override
  String get mediaCacheClearFailed => 'No se pudo borrar la caché.';

  @override
  String get mediaCacheChecking => 'Comprobando el tamaño de la caché...';

  @override
  String get mediaCacheClearing => 'Borrando...';

  @override
  String mediaCacheUsage(String used, String limit) {
    return '$used usados de $limit. Las miniaturas de la cola se guardan automáticamente en caché.';
  }

  @override
  String get settingSendspinShowPlayerTitle =>
      'Mostrar el reproductor flotante';

  @override
  String get settingSendspinShowPlayerDescription =>
      'Mientras se reproduce música, muestra una pequeña ventana sobre el panel de control con la portada, los datos de la pista y el progreso. Arrástrala a cualquier lugar. Su posición se guarda.';

  @override
  String get settingSendspinPlayerSizeTitle => 'Tamaño del reproductor';

  @override
  String get settingSendspinPlayerSizeDescription =>
      'Compacto muestra una ventana pequeña y discreta. Grande añade botones táctiles para la pista anterior, reproducir o pausar y la siguiente pista. Controlan todo el grupo de reproducción.';

  @override
  String get settingSendspinPausedHideMinutesTitle =>
      'Ocultar el reproductor pausado después de';

  @override
  String get settingSendspinPausedHideMinutesDescription =>
      'Cuánto tiempo permanece en pantalla un reproductor pausado. Se aplica tanto al reproductor flotante como a la vista Reproduciendo Ahora.';

  @override
  String get settingSendspinDismissKeepsPlayingTitle =>
      'Seguir reproduciendo al ocultarlo';

  @override
  String get settingSendspinDismissKeepsPlayingDescription =>
      'Deslizar el reproductor flotante fuera de la pantalla lo oculta sin detener la música.';

  @override
  String get settingSendspinPlayerShortcutTitle =>
      'Mostrar en el menú del kiosko';

  @override
  String get settingSendspinPlayerShortcutDescription =>
      'Añade una entrada al menú del kiosko para mostrar u ocultar el reproductor flotante. ADVERTENCIA: No aparece si no hay nada en reproducción ni una cola para este reproductor.';

  @override
  String get mediaFloatingPage => 'Reproductor flotante';

  @override
  String get mediaFloatingHint =>
      'La pequeña ventana sobre el panel de control';

  @override
  String get mediaCompact => 'Compacto';

  @override
  String get mediaLargeControls => 'Grande con controles';

  @override
  String get settingSendspinPlayerSourceTitle => 'Origen del reproductor';

  @override
  String get settingSendspinPlayerSourceDescription =>
      'Lo que muestran y controlan el reproductor flotante y Reproduciendo Ahora: este dispositivo o un reproductor en otro lugar.';

  @override
  String get settingSendspinPlayerTitle => 'Reproductor';

  @override
  String get settingSendspinPlayerDescription =>
      'El reproductor de ese origen que se mostrará y controlará.';

  @override
  String get settingSendspinDuckPercentTitle =>
      'Reducir volumen durante interacciones de voz';

  @override
  String get settingSendspinDuckPercentDescription =>
      'La música baja a este porcentaje de su volumen durante las interacciones de voz y las llamadas del intercomunicador. Después vuelve al volumen anterior.';

  @override
  String get settingSendspinVolumeKeysTitle =>
      'Controlar el reproductor con los botones de volumen';

  @override
  String get settingSendspinVolumeKeysDescription =>
      'Los botones de volumen de este dispositivo cambian el volumen del reproductor controlado. Se aplican solo mientras se muestra Reproduciendo Ahora o siempre que el reproductor esté reproduciendo.';

  @override
  String get settingSendspinVolumeKeyStepTitle =>
      'Incremento de los botones de volumen';

  @override
  String get settingSendspinVolumeKeyStepDescription =>
      'Cuánto cambia el volumen del reproductor con cada pulsación.';

  @override
  String get mediaIntro =>
      'El reproductor flotante y Reproduciendo Ahora solo aparecen cuando el reproductor elegido tiene una pista en reproducción o una cola cargada. Si no hay nada en reproducción ni en cola, no aparecen.';

  @override
  String get mediaThisDevice => 'Este dispositivo';

  @override
  String get mediaOff => 'Desactivado';

  @override
  String get mediaKeysNowPlaying => 'Mientras se muestra Reproduciendo Ahora';

  @override
  String get mediaKeysPlaying => 'Mientras el reproductor está reproduciendo';

  @override
  String get mediaAnotherPlayer => 'otro reproductor';

  @override
  String mediaLocalOffline(String player) {
    return 'El reproductor Sendspin de este dispositivo permanece desconectado mientras se controla $player.';
  }

  @override
  String get settingSendspinLyricsEnabledTitle => 'Activar letras';

  @override
  String get settingSendspinLyricsEnabledDescription =>
      'Letras sincronizadas en Reproduciendo Ahora para todos los orígenes de reproductor.';

  @override
  String get settingSendspinLyricsSourceTitle => 'Origen de las letras';

  @override
  String get settingSendspinLyricsSourceDescription =>
      'De dónde se obtienen las letras. Music Assistant necesita la dirección del servidor y el token en su página de configuración.';

  @override
  String get settingSendspinLyricsFallbackTitle =>
      'Usar Music Assistant como alternativa';

  @override
  String get settingSendspinLyricsFallbackDescription =>
      'Si no se puede conectar con LRCLIB, se consulta Music Assistant. Requiere la conexión con Music Assistant.';

  @override
  String get settingSendspinLyricsOffsetTitle => 'Sincronización de las letras';

  @override
  String get settingSendspinLyricsOffsetDescription =>
      'Ajusta las letras respecto a la música. Un valor positivo muestra cada línea antes y uno negativo, después. Útil si las letras de una pista aparecen siempre desfasadas.';

  @override
  String get mediaLyricsPage => 'Letras';

  @override
  String get mediaLyricsHint =>
      'Letras sincronizadas, su origen y sincronización';

  @override
  String get settingSendspinMaUrlTitle => 'Dirección del servidor';

  @override
  String get settingSendspinMaUrlDescription =>
      'La dirección del servidor Music Assistant, tal como aparece en su interfaz web. Normalmente usa https y el puerto 8095.';

  @override
  String get settingSendspinMaTokenTitle => 'Token de autenticación';

  @override
  String get settingSendspinMaTokenDescription =>
      'Un token de larga duración de Music Assistant, en Settings y luego Users. El acceso de lectura es suficiente para las letras. El acceso directo del menú del kiosko abre la interfaz web con el usuario al que pertenece el token.';

  @override
  String get settingSendspinMaShortcutTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingSendspinMaShortcutDescription =>
      'Añade una entrada de Music Assistant al menú del kiosko para abrir la interfaz web del servidor sobre el panel de control. Requiere la dirección del servidor indicada arriba.';

  @override
  String get settingSendspinMaOpenFullscreenTitle =>
      'Abrir directamente Reproduciendo Ahora';

  @override
  String get settingSendspinMaOpenFullscreenDescription =>
      'Abre el reproductor de pantalla completa de Music Assistant desde el menú del kiosko o con el gesto Abrir Music Assistant.';

  @override
  String get settingSendspinMaAutoCloseTitle => 'Cerrar tras inactividad';

  @override
  String get settingSendspinMaAutoCloseDescription =>
      'Vuelve al panel de control cuando nadie haya tocado la página de Music Assistant durante este tiempo. Con cero, permanece abierta hasta que se cierre.';

  @override
  String get settingSendspinMaHideCloseTitle => 'Ocultar el botón de cierre';

  @override
  String get settingSendspinMaHideCloseDescription =>
      'El botón de cierre flotante puede cubrir controles de Music Assistant, como el menú de Reproduciendo Ahora. Sin él, cierra la página con el botón Atrás o con el menú lateral del kiosko.';

  @override
  String get mediaMaHint =>
      'Servidor, token y acceso directo en el menú del kiosko';

  @override
  String get mediaKioskMenu => 'Menú del kiosko';

  @override
  String get mediaValidateConnection => 'Validar conexión';

  @override
  String get mediaValidate => 'Validar';

  @override
  String get mediaChecking => 'Comprobando…';

  @override
  String get mediaConnected => 'Conectado';

  @override
  String mediaConnectedVersion(String version) {
    return 'Conectado a Music Assistant $version';
  }

  @override
  String get mediaValidateHint =>
      'Comprueba la dirección y el token antes de activar el acceso directo o las letras.';

  @override
  String get mediaDeviceNoAnswer => 'El dispositivo no respondió.';

  @override
  String get mediaValidationFailed => 'La validación falló.';

  @override
  String get mediaNoAddress =>
      'No se ha configurado la dirección del servidor.';

  @override
  String get mediaNoToken => 'No se ha configurado un token de autenticación.';

  @override
  String get mediaTimeout => 'Music Assistant no respondió a tiempo.';

  @override
  String mediaUnreachable(String host, String error) {
    return 'No se pudo conectar con $host: $error';
  }

  @override
  String get mediaServerClosed => 'el servidor cerró la conexión';

  @override
  String get settingSendspinFullscreenControlsTitle =>
      'Mostrar controles multimedia';

  @override
  String get settingSendspinFullscreenControlsDescription =>
      'Botones de pista anterior, reproducir o pausar y pista siguiente, junto con una barra de progreso en Reproduciendo Ahora. Con los controles activados, se cierra con un botón en lugar de tocar cualquier parte de la pantalla.';

  @override
  String get settingSendspinFullscreenTextScaleTitle => 'Escala del texto';

  @override
  String get settingSendspinFullscreenTextScaleDescription =>
      'Tamaño del título de la pista, artista, álbum, letras y texto de la cola. Se aplica en ambas distribuciones y junto al protector de pantalla. La portada se ajusta para dejar espacio al texto.';

  @override
  String get settingSendspinFullscreenButtonScaleTitle =>
      'Escala de los botones';

  @override
  String get settingSendspinFullscreenButtonScaleDescription =>
      'Tamaño de los botones de reproducción y la barra de progreso, independiente del tamaño del texto. Se aplica en ambas distribuciones y junto al protector de pantalla. Los controles se adaptan al espacio disponible.';

  @override
  String get settingSendspinFullscreenHorizontalTitle => 'Modo horizontal';

  @override
  String get settingSendspinFullscreenHorizontalDescription =>
      'Divide la portada y los controles en dos mitades iguales, izquierda y derecha. Con las letras o la cola abiertas, los datos de la pista pasan debajo de la portada. No se aplica cuando Reproduciendo Ahora se muestra junto al protector de pantalla.';

  @override
  String get settingSendspinFullscreenDoubleTapTitle =>
      'Tocar dos veces para cerrar';

  @override
  String get settingSendspinFullscreenDoubleTapDescription =>
      'Tocar dos veces cualquier parte de Reproduciendo Ahora cierra la vista. No se muestra el botón de cierre. No se aplica cuando Reproduciendo Ahora se muestra junto al protector de pantalla.';

  @override
  String get settingSendspinFullscreenOnPlayTitle =>
      'Abrir Reproduciendo Ahora al empezar la música';

  @override
  String get settingSendspinFullscreenOnPlayDescription =>
      'Abre Reproduciendo Ahora en cuanto comienza la reproducción, sin esperar el tiempo de espera del protector de pantalla.';

  @override
  String get settingSendspinFullscreenMotionTitle =>
      'Cerrar \"Reproduciendo Ahora\" al detectar movimiento';

  @override
  String get settingSendspinFullscreenMotionDescription =>
      'Permite cerrar Reproduciendo Ahora con movimiento, como un protector de pantalla normal. Si está desactivado, solo se cierra al tocar la pantalla, para que pasar cerca no interrumpa la vista de música. No se aplica cuando Reproduciendo Ahora se muestra junto al protector de pantalla.';

  @override
  String get settingSendspinFullscreenShortcutTitle =>
      'Mostrar en el menú del kiosko';

  @override
  String get settingSendspinFullscreenShortcutDescription =>
      'Añade una entrada al menú del kiosko para mostrar Reproduciendo Ahora. ADVERTENCIA: No aparece si no hay nada en reproducción ni una cola para este reproductor.';

  @override
  String get settingSendspinSpeakerPillTitle => 'Mostrar selector de altavoces';

  @override
  String get settingSendspinSpeakerPillDescription =>
      'Muestra el selector de altavoces durante 5 segundos después de interactuar con la pantalla. Permite añadir o quitar altavoces del grupo actual.';

  @override
  String get settingSendspinQueueArtTitle => 'Mostrar portadas en la cola';

  @override
  String get settingSendspinQueueArtDescription =>
      'Una portada en cada fila de la cola.';

  @override
  String get mediaNowPlayingHint =>
      'Vista de pantalla completa mientras se reproduce música';

  @override
  String get mediaInterfaceHeading => 'Interfaz de usuario';

  @override
  String get settingSendspinFullscreenTitle =>
      '\"Reproduciendo Ahora\" en lugar del protector de pantalla';

  @override
  String get settingSendspinFullscreenDescription =>
      'Mientras se reproduce música, el protector de pantalla se convierte en la vista Reproduciendo Ahora a pantalla completa con la portada del álbum. Si no se reproduce nada, se usa el protector de pantalla habitual.';

  @override
  String get settingSendspinFullscreenSplitTitle =>
      'Mostrar junto al protector de pantalla';

  @override
  String get settingSendspinFullscreenSplitDescription =>
      'Mantiene el protector de pantalla visible junto a Reproduciendo Ahora. En pantallas verticales, el protector de pantalla aparece encima del reproductor. Las pantallas pequeñas mantienen el reproductor a pantalla completa.';

  @override
  String get settingSendspinFullscreenPhotoFillTitle => 'Llenar la pantalla';

  @override
  String get settingSendspinFullscreenPhotoFillDescription =>
      'Cambia cómo se ajustan las fotos cuando el protector de pantalla comparte la pantalla con Reproduciendo Ahora. Predeterminado usa el ajuste de cada protector de pantalla. Desactivado conserva toda la foto entre barras negras. Inteligente amplía las fotos con proporciones similares a la pantalla y muestra las demás sobre un fondo desenfocado. Siempre amplía todas las fotos y recorta lo que no cabe.';

  @override
  String get settingSendspinFullscreenOverrideBrightnessTitle =>
      'Cambiar el brillo del protector de pantalla';

  @override
  String get settingSendspinFullscreenOverrideBrightnessDescription =>
      'Usa el brillo normal de la pantalla en lugar del brillo del protector de pantalla mientras Reproduciendo Ahora se muestra junto a él. También reemplaza el brillo de los protectores de pantalla programados.';

  @override
  String get mediaScreensaverHeading => 'Protector de pantalla';

  @override
  String get mediaDefaultFill => 'Predeterminado';

  @override
  String get mediaFillOff => 'Desactivado';

  @override
  String get mediaFillSmart => 'Inteligente';

  @override
  String get mediaFillAlways => 'Siempre';

  @override
  String get mediaPickPlayer => 'Elegir un reproductor';

  @override
  String get mediaMaPlayer => 'Reproductor de Music Assistant';

  @override
  String get mediaHaPlayer => 'Reproductor multimedia de Home Assistant';

  @override
  String get mediaSonosRoom => 'Habitación de Sonos';

  @override
  String get mediaSearchPlayers => 'Buscar reproductores';

  @override
  String get mediaOffline => 'Desconectado';

  @override
  String mediaOfflineName(String name) {
    return '$name (desconectado)';
  }

  @override
  String get mediaSetUpMa =>
      'Configura Music Assistant para ver sus reproductores.';

  @override
  String get mediaSetUpHa =>
      'Conecta Home Assistant para ver sus reproductores multimedia.';

  @override
  String get mediaSetUpSonos =>
      'Todavía no hay altavoces Sonos registrados. Busca o añade uno en la página Sonos.';

  @override
  String mediaHaFailed(String error) {
    return 'Home Assistant no respondió: $error';
  }

  @override
  String get mediaSaveFailed => 'No se pudo guardar el reproductor.';

  @override
  String get mediaSelectFailed => 'No se pudo seleccionar el reproductor';

  @override
  String get settingSendspinEnabledTitle => 'Activar reproductor Sendspin';

  @override
  String get settingSendspinEnabledDescription =>
      'Convierte este dispositivo en un reproductor Sendspin sincronizado. Aparece en Music Assistant con el nombre del dispositivo, sincronizado con los demás altavoces Sendspin.';

  @override
  String get settingSendspinServerTitle => 'Servidor';

  @override
  String get settingSendspinServerDescription =>
      'Dirección del servidor Sendspin, por ejemplo 192.168.1.10:8927. Deja el campo vacío para buscar el servidor automáticamente en la red.';

  @override
  String get settingSendspinCodecTitle => 'Códec de audio preferido';

  @override
  String get settingSendspinCodecDescription =>
      'FLAC no tiene pérdida y es ideal para WiFi o Ethernet. El servidor elige el códec entre los que ofrece este dispositivo.';

  @override
  String get settingSendspinSyncOffsetTitle =>
      'Ajuste de sincronización de audio (ms)';

  @override
  String get settingSendspinSyncOffsetDescription =>
      'Un valor negativo hace que este dispositivo reproduzca antes, para compensar altavoces que se retrasan respecto al grupo, como los Bluetooth. Ajusta de oído. Se aplica de inmediato.';

  @override
  String get mediaSendspinPage => 'Reproductor Sendspin';

  @override
  String get mediaSendspinHint =>
      'Convierte este dispositivo en un reproductor sincronizado de Music Assistant';

  @override
  String get mediaFlac => 'FLAC (sin pérdida)';

  @override
  String get mediaOpus => 'Opus (eficiente)';

  @override
  String get mediaPcm => 'PCM (sin compresión)';

  @override
  String get settingSendspinSonosGroupVolumeTitle =>
      'Ajustar el volumen del grupo';

  @override
  String get settingSendspinSonosGroupVolumeDescription =>
      'Cuando la habitación controlada reproduce en un grupo, el control de volumen ajusta todo el grupo. Si está desactivado, solo ajusta esa habitación.';

  @override
  String get settingSendspinSonosInputsTitle => 'Mostrar TV y entrada de línea';

  @override
  String get settingSendspinSonosInputsDescription =>
      'Muestra actividad en el reproductor multimedia cuando las entradas eARC o de línea están activas.';

  @override
  String get mediaSonosHint => 'Altavoces en la red y añadir por dirección';

  @override
  String get mediaSonosSpeakers => 'Altavoces';

  @override
  String get mediaSonosNoneFound => 'No se encontró ningún Sonos';

  @override
  String get mediaSonosDiscoveryEmpty =>
      'Ningún altavoz respondió en esta red. Añade uno por su dirección.';

  @override
  String get mediaSonosAddTitle => 'Añadir un Sonos por dirección';

  @override
  String get mediaSonosLooking => 'Buscando…';

  @override
  String get mediaSonosEmpty => 'Aún no hay altavoces';

  @override
  String get mediaSonosEmptyHelp =>
      'Busca en esta red o añade un altavoz por su dirección.';

  @override
  String get mediaSonosForget => 'Olvidar';

  @override
  String get mediaSonosSearchTitle => 'Buscar en la red';

  @override
  String get mediaSonosSearchHelp =>
      'Busca altavoces Sonos en esta red. Los altavoces deben estar en la misma VLAN que este dispositivo para encontrarlos automáticamente.';

  @override
  String get mediaSonosSearch => 'Buscar';

  @override
  String get mediaSonosSearching => 'Buscando…';

  @override
  String get mediaSonosAddAddress => 'Añadir por dirección';

  @override
  String get mediaSonosAddressHelp =>
      'La dirección del altavoz en la red. A partir de él se añaden todos los altavoces de su sistema Sonos.';

  @override
  String get mediaSonosPickRoom =>
      'Elige una habitación en Origen del reproductor, Sonos.';

  @override
  String get mediaSonosAdded => 'Sonos añadido';

  @override
  String get mediaSonosNoRooms => 'El altavoz no devolvió ninguna habitación.';

  @override
  String get mediaSonosNoAddress => 'sin dirección';

  @override
  String mediaSonosUnreachable(String host) {
    return 'Ningún Sonos respondió en $host.';
  }

  @override
  String get settingsMenuHomeAssistant => 'Configuración de Home Assistant';

  @override
  String get settingsMenuHomeAssistantSummary =>
      'Conexión, panel de control, modo kiosko';

  @override
  String get settingsMenuVoiceSatellite => 'Voice Satellite';

  @override
  String get settingsMenuVoiceSatelliteSummary =>
      'Palabra de activación, escucha en segundo plano';

  @override
  String get settingsMenuEsphome => 'ESPHome';

  @override
  String get settingsMenuEsphomeSummary =>
      'Entidades nativas y proxy Bluetooth';

  @override
  String get settingsMenuScreenAudio => 'Pantalla y audio';

  @override
  String get settingsMenuScreenAudioSummary => 'Brillo, volumen, micrófono';

  @override
  String get settingsMenuScreensaver => 'Protector de pantalla';

  @override
  String get settingsMenuScreensaverSummary =>
      'Tiempo de inactividad, modos, activación por movimiento';

  @override
  String get settingsMenuBrowser => 'Navegación web';

  @override
  String get settingsMenuBrowserSummary => 'Caché, SSL, nivel de zoom';

  @override
  String get settingsMenuMediaPlayer => 'Reproductor multimedia';

  @override
  String get settingsMenuMediaPlayerSummary =>
      'Music Assistant, Sendspin, Sonos';

  @override
  String get settingsMenuDlna => 'Receptor DLNA';

  @override
  String get settingsMenuDlnaSummary =>
      'Reproduce imágenes, videos y audio de forma remota';

  @override
  String get settingsMenuIntercom => 'Intercomunicador';

  @override
  String get settingsMenuIntercomSummary => 'Habla entre kioskos';

  @override
  String get settingsMenuCamera => 'Cámara';

  @override
  String get settingsMenuCameraSummary =>
      'Cámara del dispositivo, movimiento, transmisión';

  @override
  String get settingsMenuCameraStreams => 'Transmisiones de cámaras';

  @override
  String get settingsMenuCameraStreamsSummary =>
      'Cámaras de Go2RTC y Home Assistant';

  @override
  String get settingsMenuKiosk => 'Modo kiosko';

  @override
  String get settingsMenuKioskSummary =>
      'Gesto de salida, PIN, botones físicos';

  @override
  String get settingsMenuHomeLauncher => 'Lanzador de Inicio';

  @override
  String get settingsMenuHomeLauncherSummary =>
      'Reemplaza la pantalla de inicio del dispositivo';

  @override
  String get settingsMenuAppLauncher => 'Lanzador de aplicaciones';

  @override
  String get settingsMenuAppLauncherSummary =>
      'Abre otras aplicaciones desde el kiosko';

  @override
  String get settingsMenuGestures => 'Gestos';

  @override
  String get settingsMenuGesturesSummary =>
      'Gestos táctiles, con la palma y con aplausos';

  @override
  String get settingsMenuDevice => 'Dispositivo';

  @override
  String get settingsMenuDeviceSummary =>
      'Nombre, tema de la aplicación, acceso remoto';

  @override
  String get settingsMenuFleet => 'Gestión de flotas';

  @override
  String get settingsMenuFleetSummary => 'Coordina otros kioskos o sigue a uno';

  @override
  String get settingsMenuPlugins => 'Gestor de plugins';

  @override
  String get settingsMenuPluginsSummary => 'Instala y administra plugins';

  @override
  String get settingsMenuLogs => 'Registros';

  @override
  String get settingsMenuLogsSummary =>
      'Registro de la aplicación y consola web';

  @override
  String get settingsMenuAbout => 'Acerca de';

  @override
  String get settingsMenuAboutSummary => 'Versión, autor, licencia';

  @override
  String get settingsMenuOverview => 'Vista general';

  @override
  String get settingsMenuOverviewSummary => 'Pantalla y controles rápidos';

  @override
  String get settingsMenuLockdown => 'Modo de bloqueo';

  @override
  String get settingsMenuLockdownSummary =>
      'Desactiva las interacciones con la pantalla';

  @override
  String get settingsMenuFiles => 'Gestor de archivos';

  @override
  String get settingsMenuFilesSummary => 'Explora, descarga y sube archivos';

  @override
  String get settingsGroupHomeAssistant => 'Home Assistant';

  @override
  String get settingsGroupDisplay => 'Pantalla';

  @override
  String get settingsGroupMediaCameras => 'Multimedia y cámaras';

  @override
  String get settingsGroupKiosk => 'Kiosko';

  @override
  String get settingsGroupSystem => 'Sistema';

  @override
  String get settingsMenuMenu => 'Menú';

  @override
  String get settingsMenuTheme => 'Tema';

  @override
  String get settingsMenuLogout => 'Cerrar sesión';

  @override
  String get settingsMenuSwitchKiosk => 'Cambiar de kiosko';

  @override
  String settingsMenuThemeState(String theme) {
    return 'Tema: $theme';
  }

  @override
  String get settingsMenuThemeAuto => 'Automático';

  @override
  String get settingAdaptiveBrightnessTitle => 'Brillo adaptativo';

  @override
  String get settingAdaptiveBrightnessDescription =>
      'Atenúa la pantalla a medida que se oscurece la habitación usando el sensor de luz ambiental.';

  @override
  String get settingAdaptiveMinBrightnessTitle => 'Brillo mínimo';

  @override
  String get settingAdaptiveMinBrightnessDescription =>
      'Brillo de la pantalla en una habitación oscura.';

  @override
  String get settingAdaptiveMaxBrightnessTitle => 'Brillo máximo';

  @override
  String get settingAdaptiveMaxBrightnessDescription =>
      'Brillo de la pantalla en una habitación iluminada.';

  @override
  String get settingAdaptiveDarkLuxTitle => 'Habitación oscura (lx)';

  @override
  String get settingAdaptiveDarkLuxDescription =>
      'Nivel de luz en el que la pantalla alcanza el brillo mínimo. Por debajo, permanece en ese nivel.';

  @override
  String get settingAdaptiveBrightLuxTitle => 'Habitación iluminada (lx)';

  @override
  String get settingAdaptiveBrightLuxDescription =>
      'Nivel de luz en el que la pantalla alcanza el brillo máximo. Por encima, permanece en ese nivel.';

  @override
  String get screenAudioAdaptiveHint =>
      'Ajusta el brillo a la luz de la habitación con el sensor de luz ambiental';

  @override
  String get screenAudioAdaptiveNote =>
      'Nivel en una habitación iluminada. El brillo adaptativo lo reduce a partir de ese valor.';

  @override
  String get screenAudioAdaptiveOwns => 'El brillo adaptativo está activado.';

  @override
  String get screenAudioNoSensor =>
      'Este dispositivo no tiene sensor de luz ambiental.';

  @override
  String get screenAudioAmbientLight => 'Luz ambiental';

  @override
  String get screenAudioAmbientHelp =>
      'Lectura actual del sensor de luz ambiental.';

  @override
  String get screenAudioNoReading => 'Aún no hay lectura';

  @override
  String screenAudioLux(String lux) {
    return '$lux lx';
  }

  @override
  String screenAudioLuxLast(String lux) {
    return '$lux lx (última lectura)';
  }

  @override
  String get screenAudioSetsMaximum =>
      'Ajusta el brillo máximo porque el brillo adaptativo está activado.';

  @override
  String get screenAudioSetsDefault => 'Ajusta el brillo predeterminado.';

  @override
  String get settingAudioMicDeviceTitle => 'Micrófono';

  @override
  String get settingAudioMicDeviceDescription =>
      'Micrófono que se usa para detectar la palabra de activación y capturar las interacciones de voz.';

  @override
  String get settingAudioSpeakerDeviceTitle => 'Altavoz';

  @override
  String get settingAudioSpeakerDeviceDescription =>
      'Salida para los sonidos de Voice Satellite. La reproducción multimedia sigue la ruta del sistema. La cancelación de eco solo funciona si el micrófono y el altavoz pertenecen al mismo dispositivo.';

  @override
  String get screenAudioDevices => 'Dispositivos de audio';

  @override
  String get screenAudioSelectedDevice => 'Dispositivo seleccionado';

  @override
  String screenAudioDisconnected(String name) {
    return '$name (sin conectar)';
  }

  @override
  String get settingMicAudioSourceTitle => 'Modo de captura';

  @override
  String get settingMicAudioSourceDescription =>
      'Comunicación de voz es el único modo con cancelación de eco. Déjalo seleccionado salvo que el micrófono capte un volumen mucho más bajo aquí que en una aplicación de grabación.';

  @override
  String get settingMicEchoCancellationTitle => 'Cancelación de eco';

  @override
  String get settingMicEchoCancellationDescription =>
      'Evita que el micrófono capte el altavoz del kiosko para que la palabra de parada funcione durante la reproducción. Desactívala solo si el micrófono capta un volumen mucho más bajo aquí que en una aplicación de grabación.';

  @override
  String get settingMicChannelTitle => 'Canal del micrófono';

  @override
  String get settingMicChannelDescription =>
      'Los micrófonos multicanal suelen reservar un canal para el reconocimiento de voz. Elegirlo puede mejorar la detección.';

  @override
  String get settingMicAgcTitle => 'Control automático de ganancia';

  @override
  String get settingMicAgcDescription =>
      'Permite que Android ajuste el nivel del micrófono en lugar de usar una ganancia fija. También amplifica el ruido ambiental y en algunos dispositivos no tiene ningún efecto.';

  @override
  String get settingMicNoiseSuppressionTitle => 'Supresión de ruido';

  @override
  String get settingMicNoiseSuppressionDescription =>
      'Reduce el ruido de fondo del micrófono mediante el procesamiento de Android. Puede mejorar o empeorar la detección de la palabra de activación según el dispositivo.';

  @override
  String get settingMicGainDbTitle => 'Ganancia del micrófono';

  @override
  String get settingMicGainDbDescription =>
      'Amplifica o atenúa el micrófono antes de procesar el audio. Busca un nivel cercano a 0.05 en el probador de palabras de activación. Una ganancia excesiva distorsiona la voz y empeora la detección.';

  @override
  String get settingMicCaptureFormatTitle => 'Formato de captura';

  @override
  String get settingMicCaptureFormatDescription =>
      'Elige Estéreo a 48 kHz cuando el micrófono funcione en otras aplicaciones pero no aquí. Algunas tarjetas de sonido solo graban en ese formato y la aplicación lo convierte por su cuenta.';

  @override
  String get screenAudioMicrophoneSettings => 'Configuración del micrófono';

  @override
  String get screenAudioMicrophoneHint =>
      'Modo de captura, canal, ganancia y nivel en tiempo real';

  @override
  String get screenAudioMicrophoneNote =>
      'Ajusta la captura al micrófono y a la habitación. Prueba las palabras de activación y las interacciones de voz después de cambiar estas opciones.';

  @override
  String get screenAudioVoiceCommunication =>
      'Comunicación de voz (predeterminado)';

  @override
  String get screenAudioVoiceRecognition => 'Reconocimiento de voz';

  @override
  String get screenAudioRawMicrophone => 'Micrófono sin procesar';

  @override
  String get screenAudioAutomaticDefault => 'Automático (predeterminado)';

  @override
  String get screenAudioStereo => 'Estéreo a 48 kHz';

  @override
  String get screenAudioDownmix => 'Mezclar canales (predeterminado)';

  @override
  String screenAudioChannel(String channel) {
    return 'Canal $channel';
  }

  @override
  String screenAudioChannelMissing(String channel) {
    return 'Canal $channel (no disponible en este micrófono)';
  }

  @override
  String get screenAudioMicrophoneLevel => 'Nivel del micrófono';

  @override
  String get screenAudioMicrophoneLevelHelp =>
      'Habla desde donde usas el dispositivo. Ajusta la ganancia hasta que la voz normal alcance aproximadamente el final de la zona verde.';

  @override
  String get settingBrowserCutoutModeTitle => 'Área de la cámara frontal';

  @override
  String get settingBrowserCutoutModeDescription =>
      'Qué hacer con el área de la pantalla alrededor de la cámara frontal. Elige Evitar el área de la cámara si esta cubre los botones de la parte superior del panel de control.';

  @override
  String get settingScreenOrientationTitle => 'Orientación de la pantalla';

  @override
  String get settingScreenOrientationDescription =>
      'Fuerza la pantalla a una orientación. Úsalo en un dispositivo sin sensor de rotación o instalado de una forma que el sensor no detecta correctamente.';

  @override
  String get settingKeepScreenOnTitle => 'Mantener la pantalla encendida';

  @override
  String get settingKeepScreenOnDescription =>
      'Evita que el sistema operativo apague la pantalla.';

  @override
  String get settingSetBrightnessOnLaunchTitle =>
      'Establecer el brillo al iniciar';

  @override
  String get settingSetBrightnessOnLaunchDescription =>
      'Aplica el brillo predeterminado cada vez que se inicia la aplicación.';

  @override
  String get settingDefaultBrightnessTitle => 'Brillo predeterminado';

  @override
  String get settingDefaultBrightnessDescription =>
      'Brillo de la pantalla al iniciar la aplicación. Mover el control deslizante lo aplica de inmediato.';

  @override
  String get screenAudioScreen => 'Pantalla';

  @override
  String get screenAudioCutoutAlways => 'Usar el área de la cámara';

  @override
  String get screenAudioCutoutShort => 'Solo en los bordes cortos';

  @override
  String get screenAudioCutoutDefault => 'Predeterminado del sistema';

  @override
  String get screenAudioCutoutNever => 'Evitar el área de la cámara';

  @override
  String get screenAudioAutomatic => 'Automático';

  @override
  String get screenAudioLandscape => 'Horizontal';

  @override
  String get screenAudioReverseLandscape => 'Horizontal invertida';

  @override
  String get screenAudioPortrait => 'Vertical';

  @override
  String get screenAudioReversePortrait => 'Vertical invertida';

  @override
  String get screenAudioPermission => 'Permiso';

  @override
  String get screenAudioBrightnessFallback =>
      'El brillo usa un método alternativo';

  @override
  String get screenAudioBrightnessPermission =>
      'Sin el permiso «Modificar ajustes del sistema», los cambios de brillo solo atenúan esta aplicación en lugar de ajustar el brillo real de la pantalla.';

  @override
  String get screenAudioBrightnessPermissionRemote =>
      'Sin el permiso «Modificar ajustes del sistema», los cambios de brillo solo atenúan la aplicación en lugar de ajustar el brillo real de la pantalla.';

  @override
  String get screenAudioAlwaysOn => 'Pantalla siempre activa';

  @override
  String get screenAudioAlwaysOnClock =>
      'Este dispositivo mantiene un reloj tenue encendido';

  @override
  String get screenAudioAlwaysOnHelp =>
      'Apagar la pantalla pone el dispositivo en reposo, pero la función de pantalla siempre activa vuelve a encender la pantalla de bloqueo y ninguna aplicación puede impedirlo. Desactiva «Mostrar siempre la hora y la información» en los ajustes de Android, en Pantalla, junto a las opciones de bloqueo. Algunas ROM llaman a esta función Pantalla siempre activa. La entidad de pantalla de Home Assistant seguirá sin estar disponible hasta que lo hagas.';

  @override
  String get settingMediaVolumeTitle => 'Volumen multimedia';

  @override
  String get settingMediaVolumeDescription =>
      'La música y los videos se reproducen a esta proporción del volumen principal. El volumen del reproductor Sendspin en Music Assistant mueve este control.';

  @override
  String get settingAssistantVolumeTitle => 'Volumen del asistente';

  @override
  String get settingAssistantVolumeDescription =>
      'Las respuestas de voz y los sonidos se reproducen a esta proporción del volumen principal, independientemente del volumen multimedia.';

  @override
  String get settingAssistantFullVolumeRangeTitle =>
      'Rango completo del volumen del asistente';

  @override
  String get settingAssistantFullVolumeRangeDescription =>
      'Establece el volumen de llamadas del altavoz integrado al 100 % cuando se inicia el audio del asistente por primera vez. El volumen principal y el del asistente siguen aplicándose. Otras aplicaciones comparten este volumen de llamadas, que no se restaura después.';

  @override
  String get settingIntercomVolumeTitle => 'Volumen del intercomunicador';

  @override
  String get settingIntercomVolumeDescription =>
      'La voz y los anuncios del otro kiosko se reproducen a esta proporción del volumen principal.';

  @override
  String get screenAudioVolume => 'Volumen de audio';

  @override
  String get screenAudioMasterVolume => 'Volumen principal';

  @override
  String get screenAudioMasterHelp =>
      'Volumen del dispositivo. Los volúmenes multimedia, del intercomunicador y del asistente se ajustan en proporción a este.';

  @override
  String get settingScreensaverBlackHideExtrasTitle =>
      'Ocultar todos los elementos adicionales';

  @override
  String get settingScreensaverBlackHideExtrasDescription =>
      'Mantiene la pantalla completamente negra, sin reloj pequeño, entidades de De un vistazo ni otros elementos superpuestos.';

  @override
  String get screensaverBlackSection => 'Protector de pantalla: Negro';

  @override
  String get settingScreensaverClockStyleTitle => 'Estilo';

  @override
  String get settingScreensaverClockStyleDescription =>
      'Cómo se muestra el reloj.';

  @override
  String get settingScreensaverClockFontTitle => 'Tipo de letra';

  @override
  String get settingScreensaverClockFontDescription =>
      'Tipo de letra del reloj.';

  @override
  String get settingScreensaverClockFontWeightTitle => 'Grosor de la letra';

  @override
  String get settingScreensaverClockFontWeightDescription =>
      'Grosor de los dígitos del reloj. Predeterminado usa el grosor propio de cada estilo.';

  @override
  String get settingScreensaverClock24hTitle => 'Reloj de 24 horas';

  @override
  String get settingScreensaverClock24hDescription =>
      'Muestra la hora en formato de 24 horas en lugar de AM/PM.';

  @override
  String get settingScreensaverClockSecondsTitle => 'Mostrar segundos';

  @override
  String get settingScreensaverClockSecondsDescription =>
      'Incluye los segundos en el reloj.';

  @override
  String get settingScreensaverClockDateTitle => 'Mostrar fecha';

  @override
  String get settingScreensaverClockDateDescription =>
      'Muestra el día de la semana y la fecha debajo del reloj.';

  @override
  String get settingScreensaverClockScaleTitle => 'Tamaño del reloj';

  @override
  String get settingScreensaverClockScaleDescription =>
      'Ajusta el tamaño del reloj del 50 al 300 por ciento para esta pantalla.';

  @override
  String get settingScreensaverClockColorTitle => 'Color del reloj';

  @override
  String get settingScreensaverClockColorDescription =>
      'Color del texto del reloj.';

  @override
  String get settingScreensaverClockBgColorTitle => 'Color de fondo';

  @override
  String get settingScreensaverClockBgColorDescription =>
      'Color detrás del reloj.';

  @override
  String get settingScreensaverClockBackgroundTitle => 'Foto de fondo';

  @override
  String get settingScreensaverClockBackgroundDescription =>
      'Muestra una foto detrás del reloj en lugar de un color sólido. Puede ser la ruta de una imagen en el dispositivo o una URL desde la que el dispositivo descarga la imagen.';

  @override
  String get settingScreensaverClockBackgroundRefreshTitle =>
      'Actualizar el fondo desde la URL';

  @override
  String get settingScreensaverClockBackgroundRefreshDescription =>
      'Minutos entre descargas de una imagen de fondo desde una URL. Con 0, solo se descarga al guardar esta opción.';

  @override
  String get settingScreensaverFlipDigitColorTitle => 'Color de los dígitos';

  @override
  String get settingScreensaverFlipDigitColorDescription =>
      'Color de los dígitos del reloj de láminas.';

  @override
  String get settingScreensaverFlipBgColorTitle => 'Color de las láminas';

  @override
  String get settingScreensaverFlipBgColorDescription =>
      'Color de las láminas del reloj.';

  @override
  String get settingScreensaverFlipBackdropColorTitle => 'Color de fondo';

  @override
  String get settingScreensaverFlipBackdropColorDescription =>
      'Color detrás de las láminas.';

  @override
  String get settingScreensaverRollerDigitColorTitle => 'Color de los dígitos';

  @override
  String get settingScreensaverRollerDigitColorDescription =>
      'Color de los dígitos del reloj de rodillos.';

  @override
  String get settingScreensaverRollerBgColorTitle => 'Color de fondo';

  @override
  String get settingScreensaverRollerBgColorDescription =>
      'Color detrás de los dígitos.';

  @override
  String get settingScreensaverClockNightTitle => 'Modo nocturno';

  @override
  String get settingScreensaverClockNightDescription =>
      'Cambia los colores del reloj cuando la habitación está oscura.';

  @override
  String get settingScreensaverClockNightLuxTitle => 'Nivel de luz';

  @override
  String get settingScreensaverClockNightLuxDescription =>
      'Con este nivel de luz o uno inferior, el reloj usa el color nocturno.';

  @override
  String get settingScreensaverClockNightColorTitle => 'Color nocturno';

  @override
  String get settingScreensaverClockNightColorDescription =>
      'Color del reloj y los widgets en la oscuridad.';

  @override
  String get settingScreensaverClockNightBgColorTitle => 'Fondo nocturno';

  @override
  String get settingScreensaverClockNightBgColorDescription =>
      'Color detrás del reloj en la oscuridad.';

  @override
  String get settingScreensaverClockNightHideBackgroundTitle =>
      'Ocultar la foto de fondo';

  @override
  String get settingScreensaverClockNightHideBackgroundDescription =>
      'Usa el color de fondo nocturno en lugar de la foto mientras está activo el modo nocturno.';

  @override
  String get settingScreensaverClockNightCardColorTitle =>
      'Color nocturno de las láminas';

  @override
  String get settingScreensaverClockNightCardColorDescription =>
      'Color de las láminas del reloj en la oscuridad.';

  @override
  String get screensaverClockSection => 'Protector de pantalla: Reloj';

  @override
  String get screensaverClockHint =>
      'Estilo, tipo de letra, tamaño, colores, modo nocturno y foto de fondo';

  @override
  String get screensaverStyleDigital => 'Reloj digital';

  @override
  String get screensaverStyleFlip => 'Reloj de láminas';

  @override
  String get screensaverStyleRoller => 'Reloj de rodillos';

  @override
  String get screensaverFontDefault => 'Predeterminado';

  @override
  String get screensaverFontLight => 'Fino';

  @override
  String get screensaverFontRegular => 'Normal';

  @override
  String get screensaverFontMedium => 'Medio';

  @override
  String get screensaverFontBold => 'Negrita';

  @override
  String get screensaverFontBlack => 'Muy grueso';

  @override
  String get screensaverNoPhoto => 'No se ha seleccionado ninguna foto';

  @override
  String get screensaverBackgroundHint =>
      'Ruta de una imagen en el dispositivo o URL de una imagen';

  @override
  String get screensaverImageUrlError =>
      'Introduce la URL completa de una imagen';

  @override
  String get screensaverRefreshError =>
      'Introduce minutos enteros entre 0 y 1440';

  @override
  String screensaverMaxCharacters(String count) {
    return 'Usa como máximo $count caracteres';
  }

  @override
  String get screensaverOverlayEntity => 'Entidad';

  @override
  String get screensaverOverlayNotSet => 'Sin configurar';

  @override
  String get screensaverOverlayName => 'Nombre';

  @override
  String get screensaverOverlayNameHelp =>
      'Déjalo vacío para usar el nombre de Home Assistant.';

  @override
  String get screensaverOverlayValue => 'Valor mostrado';

  @override
  String get screensaverOverlayState => 'Estado';

  @override
  String get screensaverOverlayEntityRequired => 'Elige una entidad.';

  @override
  String get screensaverOverlaySearchHint => 'Nombre o ID de entidad';

  @override
  String get screensaverOverlaySearchHintRemote =>
      'Buscar por nombre o ID de entidad';

  @override
  String get screensaverOverlaySearchEmpty => 'Escribe para buscar entidades.';

  @override
  String get screensaverOverlayNoMatches => 'No hay coincidencias.';

  @override
  String get screensaverOverlaySearching => 'Buscando…';

  @override
  String get screensaverOverlayUnreachable =>
      'No se pudo conectar con Home Assistant';

  @override
  String get screensaverOverlayNoAnswer => 'El dispositivo no respondió.';

  @override
  String screensaverOverlaySearchError(String error) {
    return 'No se pudieron buscar entidades: $error';
  }

  @override
  String get settingScreensaverDismissOnFaceTitle =>
      'Cerrar al detectar un rostro';

  @override
  String get settingScreensaverDismissOnFaceDescription =>
      'Activa la pantalla cuando alguien mira el kiosko, no solo cuando hay movimiento. La cámara funciona solo durante el protector de pantalla. ADVERTENCIA: Necesita un rostro iluminado. En la oscuridad, programa la detección de movimiento.';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyTitle =>
      'Solo cuando la pantalla está apagada';

  @override
  String get settingScreensaverDismissOnFaceScreenOffOnlyDescription =>
      'Mantiene visible el protector de pantalla si detecta un rostro con la pantalla encendida. Cuando la pantalla está apagada, la detección abre el panel de control. Tocar la pantalla sigue cerrando el protector de pantalla.';

  @override
  String get settingScreensaverPostponeOnFaceTitle =>
      'Posponer el protector de pantalla al detectar un rostro';

  @override
  String get settingScreensaverPostponeOnFaceDescription =>
      'Retrasa la activación del protector de pantalla mientras alguien mira el kiosko. ADVERTENCIA: Mantiene la cámara encendida permanentemente, con el consumo adicional de CPU de la detección de rostros.';

  @override
  String get settingFaceSensitivityTitle =>
      'Sensibilidad de detección de rostros';

  @override
  String get settingFaceSensitivityDescription =>
      'Los valores más altos detectan rostros más pequeños y lejanos. El valor 1 requiere un rostro cerca de la pantalla. El valor 100 responde a cualquier rostro que la cámara pueda distinguir.';

  @override
  String get screensaverDetectionFacePage => 'Detección de rostros';

  @override
  String get screensaverDetectionFaceHint =>
      'Cierra el protector de pantalla cuando alguien lo mira';

  @override
  String get screensaverDetectionMotionPrecedence =>
      'Cerrar al detectar movimiento está activado y tiene prioridad. La detección de rostros queda inactiva hasta que lo desactives.';

  @override
  String get screensaverDetectionFaceTuning =>
      'La frecuencia de cuadros, la cámara y el retraso de inicio se ajustan en la configuración de Cámara.';

  @override
  String get screensaverDetectionAndroidUnsupported =>
      'No disponible en esta versión de Android.';

  @override
  String get screensaverDetectionX86Unsupported =>
      'No disponible en dispositivos x86.';

  @override
  String get settingFacePreviewTitle => 'Mostrar vista previa de la cámara';

  @override
  String get settingFacePreviewDescription =>
      'Muestra una pequeña vista circular en vivo de la cámara en una esquina durante unos segundos cuando un rostro activa el kiosko.';

  @override
  String get settingFacePreviewSecondsTitle => 'Duración de la vista previa';

  @override
  String get settingFacePreviewSecondsDescription =>
      'Tiempo que la vista previa permanece en pantalla.';

  @override
  String get settingFacePreviewScaleTitle => 'Escala de la vista previa';

  @override
  String get settingFacePreviewScaleDescription =>
      'Ajusta el tamaño de la vista previa a la pantalla.';

  @override
  String get settingFacePreviewPositionTitle => 'Posición de la vista previa';

  @override
  String get settingFacePreviewPositionDescription =>
      'Esquina en la que se muestra la vista previa.';

  @override
  String get screensaverDetectionPreviewSection => 'Vista previa de la cámara';

  @override
  String get settingScreensaverEnabledTitle => 'Protector de pantalla';

  @override
  String get settingScreensaverEnabledDescription =>
      'Atenúa o deja en negro la pantalla tras un periodo de inactividad.';

  @override
  String get settingScreensaverTimeoutSecondsTitle =>
      'Tiempo de inactividad (segundos)';

  @override
  String get settingScreensaverTimeoutSecondsDescription =>
      'Periodo de inactividad antes de que se active el protector de pantalla.';

  @override
  String get settingScreensaverModeTitle => 'Modo del protector de pantalla';

  @override
  String get settingScreensaverModeDescription =>
      'Qué muestra el protector de pantalla tras el tiempo de inactividad. Atenuar solo reduce la iluminación y mantiene visible el panel de control.';

  @override
  String get settingScreensaverPixelShiftTitle => 'Desplazamiento de píxeles';

  @override
  String get settingScreensaverPixelShiftDescription =>
      'Mueve ligeramente la imagen cada minuto para proteger las pantallas OLED. No se aplica al protector de pantalla Negro, cuyos píxeles ya están apagados.';

  @override
  String get settingScreensaverMenuTitle => 'Mostrar en el menú del kiosko';

  @override
  String get settingScreensaverMenuDescription =>
      'Añade la opción Iniciar protector de pantalla al menú del kiosko.';

  @override
  String get settingScreensaverDimLevelTitle => 'Nivel de atenuación';

  @override
  String get settingScreensaverDimLevelDescription =>
      'Brillo de la pantalla mientras el protector de pantalla la atenúa.';

  @override
  String get settingScreensaverBrightnessEnabledTitle =>
      'Brillo del protector de pantalla';

  @override
  String get settingScreensaverBrightnessEnabledDescription =>
      'Usa un brillo diferente mientras se muestra el protector de pantalla.';

  @override
  String get settingScreensaverBrightnessLevelTitle => 'Nivel de brillo';

  @override
  String get settingScreensaverBrightnessLevelDescription =>
      'Se aplica a todos los modos excepto Atenuar y Negro.';

  @override
  String get settingScreensaverNotificationBrightnessTitle =>
      'Aumentar el brillo para las notificaciones';

  @override
  String get settingScreensaverNotificationBrightnessDescription =>
      'Reduce la atenuación del protector de pantalla mientras se muestra una notificación.';

  @override
  String get settingScreensaverScreenOffMinutesTitle =>
      'Apagar la pantalla después de';

  @override
  String get settingScreensaverScreenOffMinutesDescription =>
      'Apaga la pantalla cuando el protector de pantalla lleva activo el tiempo indicado. Con 0, la pantalla permanece encendida indefinidamente. Requiere permiso de administrador del dispositivo.';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverTitle =>
      'Volver al protector de pantalla al despertar';

  @override
  String get settingScreensaverScreenOffWakeToScreensaverDescription =>
      'Tras apagarse la pantalla, la detección de movimiento, rostros, proximidad o personas muestra el protector de pantalla en lugar del panel de control y reinicia el tiempo para apagar la pantalla. Tocar la pantalla sigue abriendo el panel de control.';

  @override
  String get screensaverModeDim => 'Atenuar';

  @override
  String get screensaverModeBlack => 'Negro';

  @override
  String get screensaverModeClock => 'Reloj';

  @override
  String get screensaverModeMedia => 'Contenido multimedia de Home Assistant';

  @override
  String get screensaverModeLocal => 'Contenido multimedia local';

  @override
  String get screensaverModeGallery => 'Galería de fotos';

  @override
  String get screensaverModeImmich => 'Immich';

  @override
  String get screensaverModeWebsite => 'Sitio web';

  @override
  String get screensaverModeCamera => 'Transmisiones de cámara';

  @override
  String get screensaverDimSection => 'Protector de pantalla: Atenuar';

  @override
  String get screensaverWarningTitle => 'ADVERTENCIA: Lee antes de continuar';

  @override
  String get screensaverScreenOffProceed => 'Apagar la pantalla de todos modos';

  @override
  String get screensaverAdminMissing =>
      'No se ha concedido el permiso, por lo que la pantalla no puede apagarse.';

  @override
  String get screensaverAdminMissingRemote =>
      'Falta el permiso de administrador del dispositivo';

  @override
  String get screensaverAdminMissingRemoteHelp =>
      'Sin este permiso no se puede apagar la pantalla. El diálogo para concederlo aparece en la tableta.';

  @override
  String get screensaverDimWarning =>
      'ADVERTENCIA: Atenuar mantiene visible el panel de control, por lo que no se aplica la optimización «Pausar el panel de control durante el protector de pantalla». El panel de control sigue usando CPU, GPU y batería.';

  @override
  String get screensaverUnavailablePlugin =>
      'Protector de pantalla de un plugin no disponible';

  @override
  String get screensaverScreenOffWarning =>
      'Cuando la pantalla se apaga por completo, la administración de energía de la tableta toma el control. Muchos modelos de Android presentan problemas en ese estado: el Wi-Fi se suspende o se desconecta, las entidades de Home Assistant dejan de estar disponibles, se puede perder el acceso a la cámara y algunos modelos cierran las aplicaciones en segundo plano. El comportamiento depende del fabricante.\n\nLa alternativa fiable es usar el protector de pantalla Negro y dejar esta opción en 0. La pantalla se ve igual de oscura y la aplicación mantiene el control.';

  @override
  String get settingScreensaverScreenOffBlackTitle =>
      'Usar una pantalla negra en su lugar';

  @override
  String get settingScreensaverScreenOffBlackDescription =>
      'Muestra una pantalla negra con el brillo a cero en lugar de apagarla. Oculta los widgets y Reproduciendo Ahora. No requiere permiso de administrador del dispositivo.';

  @override
  String get settingScreensaverGlanceScaleTitle => 'Escala de la fila';

  @override
  String get settingScreensaverGlanceScaleDescription =>
      'Ajusta el tamaño de la fila a la pantalla.';

  @override
  String get settingScreensaverGlanceFontTitle => 'Fuente';

  @override
  String get settingScreensaverGlanceFontDescription =>
      'Fuente que usa la fila.';

  @override
  String get settingScreensaverGlanceFontWeightTitle => 'Grosor de la fuente';

  @override
  String get settingScreensaverGlanceFontWeightDescription =>
      'Grosor del texto de la fila. Predeterminado usa el grosor propio de cada línea: normal para los nombres y seminegrita para los valores.';

  @override
  String get settingScreensaverGlanceHideNamesTitle => 'Ocultar nombres';

  @override
  String get settingScreensaverGlanceHideNamesDescription =>
      'Muestra solo el icono y el valor, con el valor más grande.';

  @override
  String get settingScreensaverGlanceBwIconsTitle => 'Iconos monocromáticos';

  @override
  String get settingScreensaverGlanceBwIconsDescription =>
      'Mantiene todos los iconos en gris neutro en lugar del color de su estado.';

  @override
  String get settingScreensaverGlanceTextOnlyTitle =>
      'Estilo de texto flotante';

  @override
  String get settingScreensaverGlanceTextOnlyDescription =>
      'Muestra las entidades como texto flotante en lugar de recuadros.';

  @override
  String get screensaverOverlayAppearance => 'Apariencia';

  @override
  String get settingScreensaverGlanceEnabledTitle => 'De un vistazo';

  @override
  String get settingScreensaverGlanceEnabledDescription =>
      'Muestra una fila de estados de entidades de Home Assistant en el protector de pantalla.';

  @override
  String get settingScreensaverGlanceEntitiesTitle => 'Entidades';

  @override
  String get settingScreensaverGlanceEntitiesDescription =>
      'Hasta cuatro entidades para mostrar, cada una con un nombre personalizado opcional.';

  @override
  String get settingScreensaverGlanceNowPlayingTitle =>
      'Mostrar en Reproduciendo Ahora';

  @override
  String get settingScreensaverGlanceNowPlayingDescription =>
      'Muestra la fila en la vista Reproduciendo Ahora a pantalla completa. Se oculta mientras se muestra la letra.';

  @override
  String get screensaverOverlayShowing => 'Entidades mostradas';

  @override
  String get screensaverOverlayReorder =>
      'Entidades mostradas (arrastra para reordenar)';

  @override
  String get screensaverOverlayFull =>
      'La fila ya tiene el máximo de entidades. Quita una para añadir otra.';

  @override
  String get screensaverOverlayPickerTitle => 'Entidades de un vistazo';

  @override
  String screensaverOverlayGlanceEmpty(String count) {
    return 'Aún no hay ninguna. Hasta $count entidades.';
  }

  @override
  String get screensaverOverlayNone => 'Aún no hay ninguna';

  @override
  String screensaverOverlayLimit(String count) {
    return 'Hasta $count entidades.';
  }

  @override
  String get screensaverOverlayGlancePage => 'De un vistazo';

  @override
  String get screensaverOverlayGlanceHint =>
      'Entidades que se muestran sobre el protector de pantalla';

  @override
  String get glanceUnavailable => 'No disponible';

  @override
  String get glanceUnknown => 'Desconocido';

  @override
  String get settingScreensaverImmichUrlTitle => 'Dirección del servidor';

  @override
  String get settingScreensaverImmichUrlDescription =>
      'Dirección del servidor de Immich, incluido su puerto.';

  @override
  String get settingScreensaverImmichApiKeyTitle => 'Clave de API';

  @override
  String get settingScreensaverImmichApiKeyDescription =>
      'Se crea en Immich, en Ajustes de la cuenta → Claves de API.';

  @override
  String get screensaverMediaImmichPage => 'Protector de pantalla: Immich';

  @override
  String get screensaverMediaImmichHint =>
      'Servidor, contenido multimedia, presentación, metadatos y filtros';

  @override
  String get screensaverMediaServerConnection => 'Conexión con el servidor';

  @override
  String get screensaverMediaValidateFailedLog =>
      'La validación falló. Consulta en el registro de la aplicación qué llamada falló.';

  @override
  String get screensaverMediaValidateFailed => 'La validación falló.';

  @override
  String get screensaverMediaNoAnswer => 'El dispositivo no respondió.';

  @override
  String get screensaverMediaAddressFirst =>
      'Introduce primero la dirección del servidor.';

  @override
  String get screensaverMediaKeyFirst => 'Introduce primero una clave de API.';

  @override
  String get screensaverMediaBadAddress =>
      'La dirección del servidor no es una URL válida.';

  @override
  String get screensaverMediaKeyRejected => 'Se rechazó la clave de API.';

  @override
  String screensaverMediaScopeMissing(String scope) {
    return 'A la clave de API le falta el permiso $scope.';
  }

  @override
  String screensaverMediaPermissionMissing(String error) {
    return 'A la clave de API le falta un permiso: $error';
  }

  @override
  String screensaverMediaServerError(String status, String error) {
    return 'El servidor respondió $status: $error';
  }

  @override
  String screensaverMediaUnreachable(String url) {
    return 'No se pudo conectar con $url.';
  }

  @override
  String screensaverMediaTalkError(String error) {
    return 'No se pudo comunicar con el servidor: $error';
  }

  @override
  String get settingScreensaverImmichPeopleTitle => 'Personas';

  @override
  String get settingScreensaverImmichPeopleDescription =>
      'Muestra solo contenido en el que aparezca alguna de estas personas.';

  @override
  String get settingScreensaverImmichExcludePeopleTitle => 'Excluir personas';

  @override
  String get settingScreensaverImmichExcludePeopleDescription =>
      'Omite el contenido en el que aparezca alguna de estas personas.';

  @override
  String get settingScreensaverImmichTagsTitle => 'Etiquetas';

  @override
  String get settingScreensaverImmichTagsDescription =>
      'Muestra solo contenido con alguna de estas etiquetas.';

  @override
  String get settingScreensaverImmichExcludeTagsTitle => 'Excluir etiquetas';

  @override
  String get settingScreensaverImmichExcludeTagsDescription =>
      'Omite el contenido que tenga alguna de estas etiquetas.';

  @override
  String get settingScreensaverImmichFavoritesOnlyTitle => 'Solo favoritos';

  @override
  String get settingScreensaverImmichFavoritesOnlyDescription =>
      'Muestra solo el contenido marcado como favorito.';

  @override
  String get settingScreensaverImmichTakenWithinTitle => 'Fecha de captura';

  @override
  String get settingScreensaverImmichTakenWithinDescription =>
      'Muestra solo el contenido capturado durante este periodo.';

  @override
  String get settingScreensaverImmichTakenFromTitle => 'Desde';

  @override
  String get settingScreensaverImmichTakenFromDescription =>
      'Omite el contenido capturado antes de esta fecha.';

  @override
  String get settingScreensaverImmichTakenToTitle => 'Hasta';

  @override
  String get settingScreensaverImmichTakenToDescription =>
      'Omite el contenido capturado después de esta fecha. Incluye el día indicado.';

  @override
  String get screensaverMediaFilters => 'Filtros';

  @override
  String get screensaverMediaAnyone => 'Cualquier persona';

  @override
  String get screensaverMediaAnyoneDevice => 'Cualquier persona.';

  @override
  String get screensaverMediaNoOne => 'Ninguna persona';

  @override
  String get screensaverMediaNoOneDevice => 'Ninguna persona.';

  @override
  String get screensaverMediaAny => 'Cualquiera';

  @override
  String get screensaverMediaAnyDevice => 'Cualquiera.';

  @override
  String get screensaverMediaNoTagsChosen => 'Ninguna etiqueta';

  @override
  String get screensaverMediaNoTagsChosenDevice => 'Ninguna etiqueta.';

  @override
  String get screensaverMediaNoPeople =>
      'Aún no hay personas con nombre. Asígnales un nombre primero en Immich.';

  @override
  String get screensaverMediaNoTags =>
      'Aún no hay etiquetas. Créalas primero en Immich.';

  @override
  String get screensaverMediaPeopleFailed =>
      'No se pudieron listar las personas';

  @override
  String get screensaverMediaTagsFailed =>
      'No se pudieron listar las etiquetas';

  @override
  String get screensaverMediaHidden => 'Oculto';

  @override
  String get screensaverMediaAnyTime => 'Cualquier fecha';

  @override
  String get screensaverMediaPastMonth => 'Último mes';

  @override
  String get screensaverMediaPast3Months => 'Últimos 3 meses';

  @override
  String get screensaverMediaPastYear => 'Último año';

  @override
  String get screensaverMediaPast2Years => 'Últimos 2 años';

  @override
  String get screensaverMediaPast5Years => 'Últimos 5 años';

  @override
  String get screensaverMediaPast10Years => 'Últimos 10 años';

  @override
  String get screensaverMediaSince => 'Desde una fecha';

  @override
  String get screensaverMediaTimeframe => 'Intervalo de fechas';

  @override
  String get screensaverMediaToday => 'Hoy';

  @override
  String get screensaverMediaDateFormat => 'Usa el formato YYYY-MM-DD.';

  @override
  String get screensaverMediaNotDate => 'La fecha no es válida.';

  @override
  String get settingScreensaverImmichMetadataTitle => 'Mostrar metadatos';

  @override
  String get settingScreensaverImmichMetadataDescription =>
      'Muestra el álbum, la fecha, la cámara y la ubicación sobre el contenido multimedia.';

  @override
  String get settingScreensaverImmichMetadataAlbumTitle => 'Nombre del álbum';

  @override
  String get settingScreensaverImmichMetadataAlbumDescription =>
      'Muestra de qué álbum proviene la foto.';

  @override
  String get settingScreensaverImmichMetadataDateTitle => 'Fecha de captura';

  @override
  String get settingScreensaverImmichMetadataDateDescription =>
      'Muestra cuándo se tomó la foto.';

  @override
  String get settingScreensaverImmichMetadataCameraTitle =>
      'Detalles de la cámara';

  @override
  String get settingScreensaverImmichMetadataCameraDescription =>
      'Muestra la distancia focal, la apertura y el ISO.';

  @override
  String get settingScreensaverImmichMetadataLocationTitle => 'Ubicación';

  @override
  String get settingScreensaverImmichMetadataLocationDescription =>
      'Muestra dónde se tomó la foto.';

  @override
  String get settingScreensaverImmichMetadataPositionTitle =>
      'Posición de los metadatos';

  @override
  String get settingScreensaverImmichMetadataPositionDescription =>
      'Esquina en la que se muestran los detalles.';

  @override
  String get settingScreensaverImmichMetadataTextShadowTitle =>
      'Sombra del texto';

  @override
  String get settingScreensaverImmichMetadataTextShadowDescription =>
      'Añade una sombra al texto de los metadatos para facilitar su lectura sobre las fotos.';

  @override
  String get settingScreensaverImmichMetadataScaleTitle => 'Tamaño del texto';

  @override
  String get settingScreensaverImmichMetadataScaleDescription =>
      'Ajusta el tamaño de los detalles de la foto a la pantalla.';

  @override
  String get settingScreensaverImmichVignetteStrengthTitle =>
      'Intensidad del sombreado';

  @override
  String get settingScreensaverImmichVignetteStrengthDescription =>
      'Oscuridad del sombreado detrás de los detalles para facilitar la lectura sobre fotos claras. Con 0, se desactiva.';

  @override
  String get screensaverMediaMetadata => 'Metadatos';

  @override
  String get screensaverMediaTopLeft => 'Arriba a la izquierda';

  @override
  String get screensaverMediaTopRight => 'Arriba a la derecha';

  @override
  String get screensaverMediaBottomLeft => 'Abajo a la izquierda';

  @override
  String get screensaverMediaBottomRight => 'Abajo a la derecha';

  @override
  String get settingScreensaverImmichIntervalTitle => 'Segundos por imagen';

  @override
  String get settingScreensaverImmichIntervalDescription =>
      'Tiempo que se muestra cada imagen antes de pasar a la siguiente. Los videos se reproducen completos.';

  @override
  String get settingScreensaverImmichShuffleTitle => 'Orden aleatorio';

  @override
  String get settingScreensaverImmichShuffleDescription =>
      'Recorre el contenido multimedia en orden aleatorio.';

  @override
  String get settingScreensaverImmichTransitionTitle => 'Transición';

  @override
  String get settingScreensaverImmichTransitionDescription =>
      'Cómo se pasa de un elemento al siguiente.';

  @override
  String get settingScreensaverImmichFillTitle => 'Llenar la pantalla';

  @override
  String get settingScreensaverImmichFillDescription =>
      'Desactivado mantiene la foto completa entre franjas negras. Inteligente amplía las fotos de proporciones similares a la pantalla y muestra las demás sobre un fondo desenfocado. Siempre amplía todas las fotos y recorta lo que no cabe.';

  @override
  String get settingScreensaverImmichPairPortraitTitle =>
      'Combinar fotos verticales';

  @override
  String get settingScreensaverImmichPairPortraitDescription =>
      'Muestra dos fotos verticales una junto a la otra para llenar la pantalla.';

  @override
  String get settingScreensaverImmichPairLandscapeTitle =>
      'Combinar fotos horizontales';

  @override
  String get settingScreensaverImmichPairLandscapeDescription =>
      'Muestra dos fotos horizontales una sobre la otra para llenar una pantalla vertical.';

  @override
  String get settingScreensaverImmichEdgeTapsTitle =>
      'Tocar los bordes para cambiar de imagen';

  @override
  String get settingScreensaverImmichEdgeTapsDescription =>
      'Tocar el quinto izquierdo o derecho de la pantalla muestra la imagen anterior o siguiente en lugar de cerrar el protector de pantalla.';

  @override
  String get screensaverMediaSlideshow => 'Presentación';

  @override
  String get settingScreensaverImmichAlbumTitle => 'Origen multimedia';

  @override
  String get settingScreensaverImmichAlbumDescription =>
      'Toda la biblioteca o los álbumes que elijas.';

  @override
  String get settingScreensaverImmichPhotosOnlyTitle => 'Solo fotos';

  @override
  String get settingScreensaverImmichPhotosOnlyDescription =>
      'Omite los videos de la presentación.';

  @override
  String get settingScreensaverImmichCacheTitle =>
      'Guardar contenido en caché local';

  @override
  String get settingScreensaverImmichCacheDescription =>
      'Guarda copias en el dispositivo para que las imágenes carguen al instante.';

  @override
  String get settingScreensaverImmichCacheMaxTitle =>
      'Tamaño de la caché (elementos)';

  @override
  String get settingScreensaverImmichCacheMaxDescription =>
      'Elimina los elementos más antiguos cuando se llena la caché.';

  @override
  String get screensaverMediaAll => 'Todo el contenido';

  @override
  String get screensaverMediaAllDevice => 'Todo el contenido.';

  @override
  String get screensaverMediaNoAlbums =>
      'Aún no hay álbumes. Crea uno primero en Immich.';

  @override
  String get screensaverMediaAlbumsFailed =>
      'No se pudieron listar los álbumes';

  @override
  String screensaverMediaListError(String error) {
    return 'No se pudieron listar los elementos: $error';
  }

  @override
  String get screensaverMediaListingFailed =>
      'No se pudieron listar los elementos';

  @override
  String screensaverMediaItems(String count) {
    return '$count elementos';
  }

  @override
  String screensaverMediaCached(String count, String size) {
    return '$count en caché, $size';
  }

  @override
  String get settingScreensaverCameraViewsTitle => 'Vistas de cámaras';

  @override
  String get settingScreensaverCameraViewsDescription =>
      'Vistas de cámaras que muestra el protector de pantalla, en este orden.';

  @override
  String get settingScreensaverCameraViewSecondsTitle =>
      'Segundos por vista de cámaras';

  @override
  String get settingScreensaverCameraViewSecondsDescription =>
      'Tiempo que permanece cada vista en pantalla antes de pasar a la siguiente. Si solo se elige una vista, no hay rotación.';

  @override
  String get settingScreensaverCameraMuteTitle => 'Silenciar todas las vistas';

  @override
  String get settingScreensaverCameraMuteDescription =>
      'Mantiene todas las vistas en silencio, incluso las de una sola cámara.';

  @override
  String get screensaverMediaCameraPage =>
      'Protector de pantalla: Transmisiones de cámara';

  @override
  String get screensaverMediaCameraHint =>
      'Vistas que se muestran, segundos por vista y sonido';

  @override
  String get screensaverMediaNoCameras =>
      'Ninguna vista tiene cámaras todavía. Añade una en Transmisiones de cámara.';

  @override
  String get screensaverMediaNoCamerasRemote =>
      'Ninguna vista tiene cámaras todavía';

  @override
  String get screensaverMediaAddCameras =>
      'Añade una en Transmisiones de cámara.';

  @override
  String get screensaverMediaNoViews =>
      'Aún no hay vistas seleccionadas. Elige las vistas que recorre el protector de pantalla.';

  @override
  String get screensaverMediaRotation =>
      'En la rotación (arrastra para reordenar)';

  @override
  String get screensaverMediaAvailable => 'Disponibles';

  @override
  String screensaverMediaOneCamera(String count) {
    return '$count cámara';
  }

  @override
  String screensaverMediaCameras(String count) {
    return '$count cámaras';
  }

  @override
  String screensaverMediaPosition(String index, String cameras) {
    return 'Posición $index · $cameras';
  }

  @override
  String get screensaverMediaTransitionNone => 'Ninguna';

  @override
  String get screensaverMediaTransitionFade => 'Fundido cruzado';

  @override
  String get screensaverMediaTransitionSlide => 'Deslizamiento';

  @override
  String get screensaverMediaTransitionZoom => 'Zoom';

  @override
  String get screensaverMediaTransitionKenBurns => 'Ken Burns';

  @override
  String get screensaverMediaTransitionRandom => 'Aleatoria';

  @override
  String get screensaverMediaFillOff => 'Desactivado';

  @override
  String get screensaverMediaFillSmart => 'Inteligente';

  @override
  String get screensaverMediaFillAlways => 'Siempre';

  @override
  String get settingScreensaverGalleryItemsTitle => 'Fotos';

  @override
  String get settingScreensaverGalleryItemsDescription =>
      'Fotos y videos que recorre este protector de pantalla. Se eligen desde la galería del dispositivo. Volver a elegir reemplaza la selección.';

  @override
  String get settingScreensaverGalleryIntervalTitle => 'Segundos por foto';

  @override
  String get settingScreensaverGalleryIntervalDescription =>
      'Tiempo que se muestra cada foto antes de pasar a la siguiente. Los videos se reproducen completos.';

  @override
  String get settingScreensaverGalleryShuffleTitle => 'Orden aleatorio';

  @override
  String get settingScreensaverGalleryShuffleDescription =>
      'Recorre la selección en orden aleatorio.';

  @override
  String get settingScreensaverGalleryTransitionTitle => 'Transición';

  @override
  String get settingScreensaverGalleryTransitionDescription =>
      'Cómo se pasa de una foto a la siguiente.';

  @override
  String get settingScreensaverGalleryFillTitle => 'Llenar la pantalla';

  @override
  String get settingScreensaverGalleryFillDescription =>
      'Desactivado mantiene la foto completa entre franjas negras. Inteligente amplía las fotos de proporciones similares a la pantalla y muestra las demás sobre un fondo desenfocado. Siempre amplía todas las fotos y recorta lo que no cabe.';

  @override
  String get settingScreensaverGalleryEdgeTapsTitle =>
      'Tocar los bordes para cambiar de imagen';

  @override
  String get settingScreensaverGalleryEdgeTapsDescription =>
      'Tocar el quinto izquierdo o derecho de la pantalla muestra la imagen anterior o siguiente en lugar de cerrar el protector de pantalla.';

  @override
  String get screensaverMediaGalleryPage =>
      'Protector de pantalla: Galería de fotos';

  @override
  String get screensaverMediaGalleryHint =>
      'Fotos, duración, orden aleatorio y transición';

  @override
  String get screensaverMediaLoadingPhotos => 'Cargando fotos...';

  @override
  String screensaverMediaCopying(String index, String total) {
    return 'Copiando foto $index de $total...';
  }

  @override
  String get screensaverMediaCopyFailed => 'No se pudieron copiar las fotos';

  @override
  String get screensaverMediaSmallerSelection =>
      'Prueba con una selección más pequeña.';

  @override
  String get screensaverMediaNoPhotos => 'No se han seleccionado fotos';

  @override
  String screensaverMediaSelected(String count) {
    return '$count seleccionados';
  }

  @override
  String get screensaverMediaPickOnDevice =>
      'No hay elementos seleccionados. Elígelos en el dispositivo.';

  @override
  String get settingScreensaverMediaIdTitle => 'Origen multimedia';

  @override
  String get settingScreensaverMediaIdDescription =>
      'Elemento multimedia, carpeta o cámara de Home Assistant. Usa Examinar para elegir uno.';

  @override
  String get settingScreensaverMediaIntervalTitle => 'Segundos por imagen';

  @override
  String get settingScreensaverMediaIntervalDescription =>
      'Tiempo que se muestra cada imagen antes de pasar a la siguiente. Los videos se reproducen completos.';

  @override
  String get settingScreensaverMediaShuffleTitle => 'Orden aleatorio';

  @override
  String get settingScreensaverMediaShuffleDescription =>
      'Reproduce una carpeta en orden aleatorio.';

  @override
  String get settingScreensaverMediaRecursiveTitle => 'Incluir subcarpetas';

  @override
  String get settingScreensaverMediaRecursiveDescription =>
      'Incluye las subcarpetas de la carpeta elegida.';

  @override
  String get settingScreensaverMediaTransitionTitle => 'Transición';

  @override
  String get settingScreensaverMediaTransitionDescription =>
      'Cómo se pasa de un elemento al siguiente.';

  @override
  String get settingScreensaverMediaFillTitle => 'Llenar la pantalla';

  @override
  String get settingScreensaverMediaFillDescription =>
      'Desactivado mantiene la foto completa entre franjas negras. Inteligente amplía las fotos de proporciones similares a la pantalla y muestra las demás sobre un fondo desenfocado. Siempre amplía todas las fotos y recorta lo que no cabe.';

  @override
  String get settingScreensaverMediaEdgeTapsTitle =>
      'Tocar los bordes para cambiar de imagen';

  @override
  String get settingScreensaverMediaEdgeTapsDescription =>
      'Tocar el quinto izquierdo o derecho de la pantalla muestra la imagen anterior o siguiente en lugar de cerrar el protector de pantalla.';

  @override
  String get screensaverMediaHaPage =>
      'Protector de pantalla: Contenido multimedia de Home Assistant';

  @override
  String get screensaverMediaHaHint =>
      'Origen multimedia, duración, orden aleatorio y ajuste a la pantalla';

  @override
  String get screensaverMediaChoose => 'Elegir contenido multimedia';

  @override
  String get screensaverMediaRoot => 'Contenido multimedia';

  @override
  String get screensaverMediaHaUnavailable =>
      'No se pudo conectar con Home Assistant o falta el token.';

  @override
  String get screensaverMediaEmpty => 'No hay elementos aquí.';

  @override
  String get screensaverMediaUseFolder => 'Usar esta carpeta';

  @override
  String get screensaverMediaFolder => 'carpeta';

  @override
  String get screensaverMediaCamera => 'cámara';

  @override
  String get screensaverMediaItem => 'elemento';

  @override
  String get screensaverMediaBrowseFailed => 'No se pudo explorar el contenido';

  @override
  String screensaverMediaBrowseError(String error) {
    return 'No se pudo explorar el contenido: $error';
  }

  @override
  String get screensaverMediaNotSet => 'Sin configurar';

  @override
  String get settingScreensaverLocalFolderTitle => 'Carpeta local';

  @override
  String get settingScreensaverLocalFolderDescription =>
      'Carpeta de este dispositivo cuyas fotos y videos recorre el protector de pantalla. Se elige en el dispositivo. También se puede escribir la ruta desde la administración remota.';

  @override
  String get settingScreensaverLocalIntervalTitle => 'Segundos por foto';

  @override
  String get settingScreensaverLocalIntervalDescription =>
      'Tiempo que se muestra cada foto antes de pasar a la siguiente. Los videos se reproducen completos.';

  @override
  String get settingScreensaverLocalShuffleTitle => 'Orden aleatorio';

  @override
  String get settingScreensaverLocalShuffleDescription =>
      'Recorre la carpeta en orden aleatorio en lugar de ordenar por nombre.';

  @override
  String get settingScreensaverLocalRecursiveTitle => 'Incluir subcarpetas';

  @override
  String get settingScreensaverLocalRecursiveDescription =>
      'Incluye también las fotos y los videos de las subcarpetas.';

  @override
  String get settingScreensaverLocalTransitionTitle => 'Transición';

  @override
  String get settingScreensaverLocalTransitionDescription =>
      'Cómo se pasa de una foto a la siguiente.';

  @override
  String get settingScreensaverLocalFillTitle => 'Llenar la pantalla';

  @override
  String get settingScreensaverLocalFillDescription =>
      'Desactivado mantiene la foto completa entre franjas negras. Inteligente amplía las fotos de proporciones similares a la pantalla y muestra las demás sobre un fondo desenfocado. Siempre amplía todas las fotos y recorta lo que no cabe.';

  @override
  String get settingScreensaverLocalEdgeTapsTitle =>
      'Tocar los bordes para cambiar de imagen';

  @override
  String get settingScreensaverLocalEdgeTapsDescription =>
      'Tocar el quinto izquierdo o derecho de la pantalla muestra la imagen anterior o siguiente en lugar de cerrar el protector de pantalla.';

  @override
  String get screensaverMediaLocalPage =>
      'Protector de pantalla: Contenido multimedia local';

  @override
  String get screensaverMediaLocalHint =>
      'Carpeta, duración, orden aleatorio y transición';

  @override
  String get settingScreensaverDismissOnMotionTitle =>
      'Cerrar al detectar movimiento';

  @override
  String get settingScreensaverDismissOnMotionDescription =>
      'Usa la cámara mientras se muestra el protector de pantalla y activa la pantalla cuando alguien se acerca. La cámara funciona solo durante el protector de pantalla.';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyTitle =>
      'Solo cuando la pantalla está apagada';

  @override
  String get settingScreensaverDismissOnMotionScreenOffOnlyDescription =>
      'Mantiene visible el protector de pantalla si detecta movimiento con la pantalla encendida. Cuando la pantalla está apagada, la detección abre el panel de control. Tocar la pantalla sigue cerrando el protector de pantalla.';

  @override
  String get settingScreensaverPostponeOnMotionTitle =>
      'Posponer el protector de pantalla al detectar movimiento';

  @override
  String get settingScreensaverPostponeOnMotionDescription =>
      'Retrasa la activación del protector de pantalla cuando detecta movimiento. ADVERTENCIA: Mantiene la cámara encendida permanentemente.';

  @override
  String get screensaverDetectionMotionPage => 'Detección de movimiento';

  @override
  String get screensaverDetectionMotionHint =>
      'Cierra o pospone el protector de pantalla al detectar movimiento';

  @override
  String get screensaverDetectionMotionTuning =>
      'La detección de movimiento se ajusta en la configuración de Cámara.';

  @override
  String get settingScreensaverDismissOnPersonTitle =>
      'Cerrar al detectar una persona';

  @override
  String get settingScreensaverDismissOnPersonDescription =>
      'Usa el sensor de personas del dispositivo mientras se muestra el protector de pantalla y activa la pantalla cuando alguien está frente a él. Requiere el permiso de acceso a los registros que aparece abajo.';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyTitle =>
      'Solo cuando la pantalla está apagada';

  @override
  String get settingScreensaverDismissOnPersonScreenOffOnlyDescription =>
      'Mantiene visible el protector de pantalla si llega alguien con la pantalla encendida. Cuando la pantalla está apagada, la detección abre el panel de control. Tocar la pantalla sigue cerrando el protector de pantalla.';

  @override
  String get settingScreensaverPostponeOnPersonTitle =>
      'Posponer el protector de pantalla al detectar una persona';

  @override
  String get settingScreensaverPostponeOnPersonDescription =>
      'Retrasa la activación del protector de pantalla mientras alguien está frente al dispositivo.';

  @override
  String get screensaverDetectionPersonPage => 'Detección de personas';

  @override
  String get screensaverDetectionPersonHint =>
      'Cierra o pospone el protector de pantalla con el sensor de personas del dispositivo';

  @override
  String get screensaverDetectionOccupancy => 'Presencia';

  @override
  String get screensaverDetectionStatusUnavailable => 'Estado no disponible.';

  @override
  String get screensaverDetectionOff => 'Desactivado.';

  @override
  String get screensaverDetectionStarting => 'Iniciando...';

  @override
  String get screensaverDetectionWaiting =>
      'Esperando la primera señal del sensor. El sensor informa cada 30 segundos mientras hay alguien a la vista.';

  @override
  String screensaverDetectionLastHeartbeat(String ago) {
    return 'Última señal del sensor: $ago.';
  }

  @override
  String screensaverDetectionSecondsAgo(String count) {
    return 'hace $count s';
  }

  @override
  String screensaverDetectionMinutesAgo(String count) {
    return 'hace $count min';
  }

  @override
  String screensaverDetectionHoursAgo(String count) {
    return 'hace $count h';
  }

  @override
  String get screensaverDetectionDetected => 'Persona detectada';

  @override
  String get screensaverDetectionClear => 'Sin personas';

  @override
  String get screensaverDetectionPermissions =>
      'Permisos del sistema necesarios';

  @override
  String get screensaverDetectionLogAccess => 'Acceso a los registros';

  @override
  String get screensaverDetectionChecking => 'Comprobando...';

  @override
  String get screensaverDetectionReadable =>
      'Se puede leer el sensor de personas del dispositivo.';

  @override
  String get screensaverDetectionRestartRequired =>
      'Concedido. Reinicia Kiosk Satellite para aplicarlo.';

  @override
  String get screensaverDetectionGrantHelp =>
      'Este permiso solo se puede conceder mediante ADB. La documentación de Meta Portal incluye el comando completo. Después, reinicia Kiosk Satellite.';

  @override
  String get screensaverDetectionGrantRemoteHelp =>
      'Este permiso solo se puede conceder mediante ADB. Abajo está el comando completo, listo para copiar. Después, reinicia Kiosk Satellite.';

  @override
  String get screensaverDetectionGranted => 'Concedido';

  @override
  String get screensaverDetectionMissing => 'Falta el permiso';

  @override
  String get screensaverDetectionRestart => 'Reiniciar';

  @override
  String get screensaverDetectionRestartRemote => 'Reiniciar el dispositivo';

  @override
  String get screensaverDetectionLogRestart =>
      'El acceso a los registros está concedido, pero se aplica al reiniciar Kiosk Satellite.';

  @override
  String get screensaverDetectionLogMissing =>
      'No se ha concedido el acceso a los registros.';

  @override
  String get settingScreensaverDismissOnProximityTitle =>
      'Cerrar al detectar proximidad';

  @override
  String get settingScreensaverDismissOnProximityDescription =>
      'Usa el sensor de proximidad mientras se muestra el protector de pantalla y activa la pantalla cuando algo se acerca al dispositivo. Los sensores diseñados solo para llamadas, como \"palm\" o \"touch\", no sirven para esta función.';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyTitle =>
      'Solo cuando la pantalla está apagada';

  @override
  String get settingScreensaverDismissOnProximityScreenOffOnlyDescription =>
      'Mantiene visible el protector de pantalla si algo se acerca con la pantalla encendida. Cuando la pantalla está apagada, la detección abre el panel de control. Tocar la pantalla sigue cerrando el protector de pantalla.';

  @override
  String get settingScreensaverPostponeOnProximityTitle =>
      'Posponer el protector de pantalla al detectar proximidad';

  @override
  String get settingScreensaverPostponeOnProximityDescription =>
      'Retrasa la activación del protector de pantalla mientras algo está cerca del sensor.';

  @override
  String get screensaverDetectionProximityPage => 'Detección de proximidad';

  @override
  String get screensaverDetectionProximityHint =>
      'Cierra o pospone el protector de pantalla con el sensor de proximidad';

  @override
  String get screensaverDetectionNoProximity =>
      'No disponible en este dispositivo: no tiene sensor de proximidad.';

  @override
  String get screensaverDetectionSensor => 'Sensor';

  @override
  String get screensaverDetectionSensorHelp =>
      'Sensor de proximidad que informa el dispositivo. Un sensor diseñado para llamadas llamado \"palm\" o \"touch\" no sirve para esta función.';

  @override
  String get settingScreensaverScheduleEnabledTitle =>
      'Activar los protectores de pantalla programados';

  @override
  String get settingScreensaverScheduleEnabledDescription =>
      'Cambia a otro protector de pantalla a determinadas horas del día.';

  @override
  String get settingScreensaverScheduleTitle => 'Horas';

  @override
  String get settingScreensaverScheduleDescription =>
      'Cada hora indica cuándo empieza a usarse ese protector de pantalla.';

  @override
  String get screensaverScheduleSection =>
      'Protectores de pantalla programados';

  @override
  String get screensaverTime => 'Hora';

  @override
  String get screensaverAddTime => 'Añadir hora';

  @override
  String get screensaverRemoveTime => 'Eliminar hora';

  @override
  String get screensaverNoTimes => 'Aún no hay horas programadas';

  @override
  String get screensaverTimeHelp =>
      'Protector de pantalla que se usa a partir de esa hora.';

  @override
  String get screensaverPickTime => 'Elige una hora.';

  @override
  String get screensaverDefault => 'Predeterminado';

  @override
  String get screensaverOn => 'Activado';

  @override
  String get screensaverOff => 'Desactivado';

  @override
  String get screensaverBrightness => 'Brillo';

  @override
  String get screensaverBrightnessFollow =>
      'Sigue la opción Brillo del protector de pantalla.';

  @override
  String get screensaverBrightnessExceptBlack =>
      'Se aplica a todos los modos excepto Negro.';

  @override
  String get screensaverScreenOffFollow =>
      'Sigue la opción Apagar la pantalla después de.';

  @override
  String get screensaverScreenOnHours =>
      'Mantiene la pantalla encendida durante estas horas.';

  @override
  String get screensaverScreenOffHelp =>
      'Apaga la pantalla cuando el protector de pantalla lleva activo este tiempo. Requiere permiso de administrador del dispositivo.';

  @override
  String get screensaverScreenOffNever => 'No apagar la pantalla';

  @override
  String get screensaverMotion => 'Cerrar al detectar movimiento';

  @override
  String get screensaverFace => 'Cerrar al detectar un rostro';

  @override
  String get screensaverProximity => 'Cerrar al detectar proximidad';

  @override
  String get screensaverPerson => 'Cerrar al detectar una persona';

  @override
  String get screensaverWidgets => 'Widgets';

  @override
  String get screensaverGlance => 'De un vistazo';

  @override
  String get screensaverNowPlaying =>
      'Mostrar Reproduciendo Ahora junto al protector de pantalla';

  @override
  String get screensaverNowPlayingHelp =>
      'Predeterminado sigue la distribución general. Activado comparte la pantalla cuando Reproduciendo Ahora está habilitado. Desactivado oculta Reproduciendo Ahora durante estas horas.';

  @override
  String get screensaverCameraRequired =>
      'Requiere la cámara. Actívala primero en la configuración de Cámara.';

  @override
  String get screensaverNotAvailable =>
      'No está disponible en este dispositivo.';

  @override
  String get screensaverSummaryMotionOn => 'Movimiento: activado';

  @override
  String get screensaverSummaryMotionOff => 'Movimiento: desactivado';

  @override
  String get screensaverSummaryFaceOn => 'Rostros: activado';

  @override
  String get screensaverSummaryFaceOff => 'Rostros: desactivado';

  @override
  String get screensaverSummaryProximityOn => 'Proximidad: activado';

  @override
  String get screensaverSummaryProximityOff => 'Proximidad: desactivado';

  @override
  String get screensaverSummaryPersonOn => 'Personas: activado';

  @override
  String get screensaverSummaryPersonOff => 'Personas: desactivado';

  @override
  String get screensaverSummaryWidgetsOn => 'Widgets: activado';

  @override
  String get screensaverSummaryWidgetsOff => 'Widgets: desactivado';

  @override
  String get screensaverSummaryGlanceOn => 'De un vistazo: activado';

  @override
  String get screensaverSummaryGlanceOff => 'De un vistazo: desactivado';

  @override
  String get screensaverSummaryNowPlayingOn => 'Reproduciendo Ahora: activado';

  @override
  String get screensaverSummaryNowPlayingOff =>
      'Reproduciendo Ahora: desactivado';

  @override
  String screensaverBrightnessPercent(String percent) {
    return 'Brillo del $percent %';
  }

  @override
  String screensaverScreenOffAfter(String minutes) {
    return 'Apagar la pantalla después de $minutes min';
  }

  @override
  String get screensaverWeatherMood => 'Ambiente meteorológico';

  @override
  String get screensaverWeatherMoodPage =>
      'Salvapantallas de ambiente meteorológico';

  @override
  String get screensaverWeatherMoodSummary =>
      'Entidad meteorológica, rayos, vista previa';

  @override
  String get settingScreensaverWeatherEntityTitle => 'Entidad meteorológica';

  @override
  String get settingScreensaverWeatherEntityDescription =>
      'La entidad meteorológica de Home Assistant que controla la escena animada. El día, el amanecer/atardecer y la noche siguen sun.sun, con la hora local como alternativa.';

  @override
  String get settingScreensaverWeatherLightningTitle =>
      'Destellos de relámpagos';

  @override
  String get settingScreensaverWeatherLightningDescription =>
      'Muestra rayos y destellos en las nubes durante las tormentas.';

  @override
  String get screensaverWeatherMoodSelectEntity =>
      'Selecciona una entidad meteorológica en Ajustes > Salvapantallas > Ambiente meteorológico.';

  @override
  String get screensaverWeatherPreviewGroup => 'Vista previa del tiempo';

  @override
  String get settingScreensaverWeatherPreviewTitle =>
      'Activar vista previa del tiempo';

  @override
  String get settingScreensaverWeatherPreviewDescription =>
      'Muestra la escena seleccionada en lugar del tiempo actual. Desactívala para volver a seguir Home Assistant.';

  @override
  String get settingScreensaverWeatherPreviewConditionTitle => 'Tipo de tiempo';

  @override
  String get settingScreensaverWeatherPreviewConditionDescription =>
      'Escena meteorológica animada que se mostrará en la vista previa.';

  @override
  String get settingScreensaverWeatherPreviewPeriodTitle => 'Momento del día';

  @override
  String get settingScreensaverWeatherPreviewPeriodDescription =>
      'Elige la versión de día, amanecer/atardecer o noche de la escena.';

  @override
  String get screensaverWeatherPreviewSunny => 'Despejado';

  @override
  String get screensaverWeatherPreviewPartlycloudy => 'Parcialmente nublado';

  @override
  String get screensaverWeatherPreviewCloudy => 'Nublado';

  @override
  String get screensaverWeatherPreviewRainy => 'Lluvia';

  @override
  String get screensaverWeatherPreviewPouring => 'Lluvia intensa';

  @override
  String get screensaverWeatherPreviewSnowy => 'Nieve';

  @override
  String get screensaverWeatherPreviewSnowyRainy => 'Nieve y lluvia';

  @override
  String get screensaverWeatherPreviewFog => 'Niebla';

  @override
  String get screensaverWeatherPreviewHail => 'Granizo';

  @override
  String get screensaverWeatherPreviewLightning => 'Rayos';

  @override
  String get screensaverWeatherPreviewLightningRainy => 'Rayos y lluvia';

  @override
  String get screensaverWeatherPreviewWindy => 'Viento';

  @override
  String get screensaverWeatherPreviewWindyVariant => 'Viento y nubes';

  @override
  String get screensaverWeatherPreviewExceptional => 'Tiempo excepcional';

  @override
  String get screensaverWeatherPreviewDay => 'Día';

  @override
  String get screensaverWeatherPreviewNight => 'Noche';

  @override
  String get settingScreensaverWeatherClockTitle => 'Activar reloj';

  @override
  String get settingScreensaverWeatherClockDescription =>
      'Mostrar un reloj digital sobre la escena meteorológica.';

  @override
  String get screensaverWeatherTextShadowDescription =>
      'Añadir una sombra al texto para facilitar su lectura sobre la escena meteorológica.';

  @override
  String get screensaverWeatherBarGroup => 'Información meteorológica';

  @override
  String get settingScreensaverWeatherBarTitle => 'Activar barra del tiempo';

  @override
  String get settingScreensaverWeatherBarDescription =>
      'Mostrar información meteorológica en tiempo real en la parte inferior de la pantalla.';

  @override
  String get settingScreensaverWeatherBarScaleTitle => 'Escala del texto';

  @override
  String get settingScreensaverWeatherBarScaleDescription =>
      'Ajustar la información meteorológica entre el 50 y el 200 por ciento.';

  @override
  String get settingScreensaverWeatherBarColorTitle => 'Color del texto';

  @override
  String get settingScreensaverWeatherBarColorDescription =>
      'El color de la información meteorológica.';

  @override
  String get settingScreensaverWeatherBarOpacityTitle => 'Opacidad del fondo';

  @override
  String get settingScreensaverWeatherBarOpacityDescription =>
      'Oscurecer la barra inferior para facilitar la lectura de la información meteorológica.';

  @override
  String get settingScreensaverWeatherBarTitlesTitle => 'Mostrar títulos';

  @override
  String get settingScreensaverWeatherBarTitlesDescription =>
      'Nombrar cada dato sobre su valor. Si se desactiva, los valores tienen el tamaño de la temperatura.';

  @override
  String get screensaverWeatherBarHumidityDescription =>
      'Mostrar la humedad cuando la entidad meteorológica la proporcione.';

  @override
  String get screensaverWeatherBarWindDescription =>
      'Mostrar la velocidad del viento cuando la entidad meteorológica la proporcione.';

  @override
  String get screensaverWeatherBarVisibilityDescription =>
      'Mostrar la visibilidad cuando la entidad meteorológica la proporcione.';

  @override
  String get settingScreensaverWeatherBlurTitle => 'Desenfoque de la escena';

  @override
  String get settingScreensaverWeatherBlurDescription =>
      'Suavizar la escena meteorológica animada manteniendo nítidos el reloj, la barra del tiempo y los widgets.';

  @override
  String get screensaverWeatherPreviewTwilight => 'Amanecer/Atardecer';

  @override
  String get screensaverWeatherBarFeelsLikeDescription =>
      'Muestra la sensación térmica en lugar de la temperatura real cuando está disponible.';

  @override
  String get settingScreensaverWebsiteUrlTitle => 'URL del sitio web';

  @override
  String get settingScreensaverWebsiteUrlDescription =>
      'Página que se muestra a pantalla completa. Debe permitir que se incruste.';

  @override
  String get settingScreensaverWebsiteZoomTitle => 'Nivel de zoom';

  @override
  String get settingScreensaverWebsiteZoomDescription =>
      'Cambia la escala de toda la vista web del protector de pantalla.';

  @override
  String get settingScreensaverWebsiteDoubleTapTitle =>
      'Tocar dos veces para cerrar';

  @override
  String get settingScreensaverWebsiteDoubleTapDescription =>
      'Un solo toque permite interactuar con el sitio web en lugar de cerrar el protector de pantalla.';

  @override
  String get screensaverWebsiteSection => 'Protector de pantalla: Sitio web';

  @override
  String get screensaverOverlaySmallClock => 'Reloj pequeño';

  @override
  String get screensaverOverlayWeather => 'Clima';

  @override
  String get screensaverOverlayBattery => 'Batería';

  @override
  String get screensaverOverlayClockNote =>
      'Se oculta en los modos Reloj digital y Transmisiones de cámara del protector de pantalla.';

  @override
  String get screensaverOverlayCameraNote =>
      'Se oculta en el modo Transmisiones de cámara del protector de pantalla.';

  @override
  String get screensaverOverlayScale => 'Escala';

  @override
  String get screensaverOverlayScaleHelp =>
      'Ajusta el tamaño de este widget a la pantalla.';

  @override
  String get screensaverOverlayFont => 'Fuente';

  @override
  String get screensaverOverlayCorner => 'Esquina';

  @override
  String get screensaverOverlayWidget => 'Widget';

  @override
  String get screensaverOverlayClock24 => 'Reloj de 24 horas';

  @override
  String get screensaverOverlayClock24Help =>
      'Usa el formato de 24 horas en lugar de AM/PM.';

  @override
  String get screensaverOverlayShowDate => 'Mostrar fecha';

  @override
  String get screensaverOverlayShowDateHelp =>
      'Añade una fecha corta debajo del reloj.';

  @override
  String get screensaverOverlayPercentage => 'Mostrar porcentaje';

  @override
  String get screensaverOverlayPercentageHelp =>
      'Muestra la carga junto al icono.';

  @override
  String get screensaverOverlayLow => 'Solo con batería baja';

  @override
  String get screensaverOverlayLowHelp =>
      'Se oculta hasta que la carga baja al 20 por ciento.';

  @override
  String get screensaverOverlayShowName => 'Mostrar nombre';

  @override
  String get screensaverOverlayShowNameHelp =>
      'Muestra el nombre debajo del valor.';

  @override
  String get screensaverOverlayFontSystem => 'Sistema';

  @override
  String get screensaverOverlayFontSerif => 'Con remates';

  @override
  String get screensaverOverlayFontCondensed => 'Condensada';

  @override
  String get screensaverOverlayFontMonospace => 'Monoespaciada';

  @override
  String get screensaverOverlayFontCasual => 'Informal';

  @override
  String get screensaverOverlayFontCursive => 'Cursiva';

  @override
  String get screensaverOverlayColor => 'Color';

  @override
  String get screensaverOverlayWeatherEntity => 'Entidad del clima';

  @override
  String get screensaverOverlayNoWeather => 'No hay entidades del clima';

  @override
  String get screensaverOverlayNoWeatherHelp =>
      'Home Assistant no devolvió ninguna.';

  @override
  String get screensaverOverlayPickWeather => 'Elige una entidad del clima…';

  @override
  String get screensaverOverlayWeatherRequired =>
      'Elige una entidad del clima.';

  @override
  String get screensaverOverlayLocationName => 'Nombre de la ubicación';

  @override
  String get screensaverOverlayLocationHelp =>
      'Déjalo vacío para ocultar la línea de ubicación.';

  @override
  String get screensaverOverlayLocation => 'Ubicación';

  @override
  String get screensaverOverlayLocationDetail =>
      'Muestra el nombre del lugar encima de la temperatura.';

  @override
  String get screensaverOverlayFeelsLike => 'Sensación térmica';

  @override
  String get screensaverOverlayFeelsLikeHelp =>
      'Muestra la sensación térmica en una línea etiquetada debajo de la temperatura real.';

  @override
  String get screensaverOverlayFeelsLikeOnly => 'Solo sensación térmica';

  @override
  String get screensaverOverlayFeelsLikeOnlyHelp =>
      'Muestra la sensación térmica con su etiqueta en lugar de la temperatura real.';

  @override
  String get screensaverOverlayForecast => 'Pronóstico';

  @override
  String get screensaverOverlayForecastHelp =>
      'Muestra las condiciones con su icono correspondiente.';

  @override
  String get screensaverOverlayHumidity => 'Humedad';

  @override
  String get screensaverOverlayWind => 'Velocidad del viento';

  @override
  String get screensaverOverlayVisibility => 'Visibilidad';

  @override
  String screensaverWeatherFeelsLikeValue(String temperature) {
    return 'Sensación térmica: $temperature';
  }

  @override
  String get settingScreensaverWidgetsTitle => 'Widgets';

  @override
  String get settingScreensaverWidgetsDescription =>
      'Pequeños elementos superpuestos en las esquinas del protector de pantalla.';

  @override
  String get settingScreensaverWidgetScaleTitle =>
      'Escala global de los widgets';

  @override
  String get settingScreensaverWidgetScaleDescription =>
      'Ajusta el tamaño de todos los widgets a la pantalla. Cada widget conserva su escala con respecto a los demás.';

  @override
  String get settingScreensaverWidgetFontTitle => 'Fuente global';

  @override
  String get settingScreensaverWidgetFontDescription =>
      'Fuente que usan todos los widgets. Cada widget puede elegir la suya.';

  @override
  String get settingScreensaverWidgetFontWeightTitle =>
      'Grosor global de la fuente';

  @override
  String get settingScreensaverWidgetFontWeightDescription =>
      'Grosor del texto de todos los widgets. Predeterminado usa el grosor propio de cada línea. Cada widget puede elegir el suyo.';

  @override
  String get settingScreensaverWidgetTextShadowTitle => 'Sombra del texto';

  @override
  String get settingScreensaverWidgetTextShadowDescription =>
      'Añade una sombra al texto de los widgets para facilitar su lectura sobre las fotos.';

  @override
  String get settingScreensaverVignetteStrengthTitle =>
      'Intensidad del sombreado';

  @override
  String get settingScreensaverVignetteStrengthDescription =>
      'Oscuridad del fondo detrás de los widgets para facilitar su lectura sobre fotos claras. El valor 0 lo desactiva.';

  @override
  String get screensaverOverlayWidgetsEmpty => 'Aún no hay widgets';

  @override
  String get screensaverOverlayRemove => 'Quitar widget';

  @override
  String get screensaverOverlayAdd => 'Añadir widget';

  @override
  String get screensaverOverlayAddHelp =>
      'Un reloj pequeño, el clima, la batería o una entidad en una esquina.';

  @override
  String get screensaverOverlayWidgetsHint =>
      'Elementos en las esquinas y su escala';

  @override
  String get settingsSearchHint => 'Buscar en la configuración';

  @override
  String get settingsSearchClear => 'Borrar búsqueda';

  @override
  String get settingsSearchResults => 'Resultados de búsqueda';

  @override
  String settingsSearchEmpty(String query) {
    return 'No hay opciones que coincidan con \"$query\".';
  }

  @override
  String get searchInstallApk =>
      'Sube un APK de Kiosk Satellite desde la administración remota e instálalo.';

  @override
  String get searchPermissionsHelp =>
      'Todos los permisos de Android que puede usar la aplicación y su estado: micrófono, cámara, notificaciones, batería sin restricciones, mostrar sobre otras aplicaciones, modificar ajustes del sistema, protección de la interfaz del sistema, administrador del dispositivo, acceso a todos los archivos, acceso de uso y ubicación.';

  @override
  String get searchServiceStatus => 'Estado del servicio';

  @override
  String get searchServiceHelp =>
      'Indica si el servicio de Kiosk Satellite está en ejecución y qué mantiene activo.';

  @override
  String get searchServicePermissions =>
      'Los permisos que necesita el servicio de Kiosk Satellite.';

  @override
  String get searchIntercomKiosks =>
      'Kioskos conocidos y si cada uno puede recibir una llamada.';

  @override
  String get searchHaValidate =>
      'Comprueba la URL y el token con tu Home Assistant.';

  @override
  String get searchHaProxy =>
      'Sirve Home Assistant mediante un proxy seguro dentro de la aplicación cuando usa HTTP.';

  @override
  String get searchHaDashboard =>
      'Elige el panel de control y la vista que muestra el kiosko.';

  @override
  String get searchKioskPermissions =>
      'Los permisos que necesitan las protecciones del modo kiosko y del modo de bloqueo.';

  @override
  String get searchHomeStatus => 'Estado de la pantalla de inicio';

  @override
  String get searchHomeHelp =>
      'Indica si Kiosk Satellite es la pantalla de inicio del dispositivo y dónde establecerlo como opción predeterminada.';

  @override
  String get searchMasterVolume =>
      'El volumen del dispositivo que sirve de base para los controles de volumen multimedia y del asistente.';

  @override
  String get searchSmallClock =>
      'Un reloj en una esquina del protector de pantalla.';

  @override
  String get searchBattery =>
      'Un indicador de batería en una esquina del protector de pantalla con la carga de este dispositivo.';

  @override
  String get searchPersonPermission =>
      'El permiso de acceso a registros que necesita el sensor de presencia del dispositivo.';

  @override
  String get searchSonosSpeakers =>
      'Los altavoces Sonos que conoce este dispositivo, una búsqueda en la red y un campo de dirección.';

  @override
  String get voiceAppearanceHint =>
      'Estilo del asistente, tema, barra de actividad, tamaño del texto';

  @override
  String get voiceSkin => 'Estilo';

  @override
  String get voiceSkinHelp => 'La apariencia del asistente de voz en pantalla.';

  @override
  String get voiceTheme => 'Modo del tema';

  @override
  String get voiceThemeHelp => 'Muestra el asistente en modo claro u oscuro.';

  @override
  String get voiceReactive => 'Barra de actividad reactiva';

  @override
  String get voiceReactiveHelp =>
      'La barra de actividad reacciona al audio. NO SE RECOMIENDA para dispositivos de poca potencia como el Echo Show.';

  @override
  String get voiceRate => 'Frecuencia de actualización de la barra reactiva';

  @override
  String get voiceRateHelp =>
      'Con qué frecuencia se actualiza la barra de actividad. Una frecuencia mayor se ve más fluida y usa más CPU.';

  @override
  String get voiceScaleHelp => 'El tamaño del texto del asistente en pantalla.';

  @override
  String get voiceUpdateIntegration =>
      'Actualiza la integración Voice Satellite en Home Assistant para controlar estos ajustes desde el kiosko.';

  @override
  String get voiceDashboardRequired =>
      'Disponible mientras el kiosko muestra tu panel de control de Home Assistant.';

  @override
  String get voiceChimesPage => 'Sonidos';

  @override
  String get voiceChimesHint =>
      'Sonidos de activación, finalización, error, temporizadores y anuncios';

  @override
  String get voiceChimesPreview => 'Reproducir en el kiosco';

  @override
  String get voiceChimesPreviewFailed => 'No se pudo reproducir el sonido.';

  @override
  String get voiceChimesHelp =>
      'Elige los sonidos de este kiosco. Sube aquí tus archivos personalizados. Los sonidos guardados en Home Assistant no se usan para los avisos locales.';

  @override
  String get voiceChimeWakeTitle => 'Sonido de activación';

  @override
  String get voiceChimeWakeDescription =>
      'Se reproduce cuando Voice Satellite empieza a escuchar.';

  @override
  String get voiceChimeDoneTitle => 'Sonido de finalización';

  @override
  String get voiceChimeDoneDescription =>
      'Se reproduce cuando termina una interacción de voz.';

  @override
  String get voiceChimeErrorTitle => 'Sonido de error';

  @override
  String get voiceChimeErrorDescription =>
      'Se reproduce cuando falla una interacción de voz.';

  @override
  String get voiceChimeTimerTitle => 'Sonido del temporizador';

  @override
  String get voiceChimeTimerDescription =>
      'Se repite cuando termina un temporizador hasta que lo cierres.';

  @override
  String get voiceChimeAnnounceTitle => 'Sonido de anuncio';

  @override
  String get voiceChimeAnnounceDescription =>
      'Se reproduce antes de un anuncio de Voice Satellite, salvo que el anuncio incluya su propio sonido.';

  @override
  String get voiceEngine => 'Motor';

  @override
  String get voiceEngineHelp => 'Inicia o detén el motor de Voice Satellite.';

  @override
  String get voiceAssigned => 'Satélite asignado';

  @override
  String get voiceAssignedHelp =>
      'La entidad assist_satellite con la que este kiosko se identifica en Home Assistant. Cambiarla vuelve a cargar el panel de control.';

  @override
  String get voiceAssignedSearch =>
      'La entidad assist_satellite con la que este kiosko se identifica en Home Assistant.';

  @override
  String get voiceNoneAssigned => 'Ninguno asignado';

  @override
  String get voiceAutoStart => 'Inicio automático';

  @override
  String get voiceAutoStartHelp =>
      'Inicia Voice Satellite automáticamente al cargar el panel de control.';

  @override
  String get voiceMuteHelp => 'Deja de escuchar palabras de activación.';

  @override
  String get voicePipeline1 => 'Canal de Assist 1';

  @override
  String get voicePipeline1Help =>
      'El canal de Assist que procesa los comandos de voz.';

  @override
  String get voicePipeline2 => 'Canal de Assist 2';

  @override
  String get voicePipeline2Help =>
      'El canal que se usa cuando se detecta la segunda palabra de activación.';

  @override
  String get voiceVad => 'Detección del fin del habla';

  @override
  String get voiceVadHelp =>
      'Cuánto debe durar una pausa para dar por terminado un comando de voz.';

  @override
  String get voiceMutedWarning => 'Desactivar el aviso de micrófono silenciado';

  @override
  String get voiceMutedWarningHelp =>
      'Oculta el aviso de micrófono silenciado al iniciar y cuando se silencia el micrófono del satélite.';

  @override
  String get voiceDebug => 'Registro de depuración';

  @override
  String get voiceDebugHelp =>
      'Muestra información de depuración de Voice Satellite en la consola del navegador.';

  @override
  String get voiceVersion => 'Versión de Voice Satellite';

  @override
  String get voiceVersionHelp =>
      'La versión de la integración instalada en Home Assistant.';

  @override
  String get voiceVadDefault => 'Predeterminado';

  @override
  String get voiceVadRelaxed => 'Relajado';

  @override
  String get voiceVadAggressive => 'Agresivo';

  @override
  String get voiceGeneral => 'General';

  @override
  String get voiceStart => 'Iniciar';

  @override
  String get voiceNotavailable => 'No disponible';

  @override
  String get voiceDisabled => 'Desactivado';

  @override
  String get settingWakeWordBackgroundTitle =>
      'Seguir escuchando en segundo plano';

  @override
  String get settingWakeWordBackgroundDescription =>
      'Sigue escuchando la palabra de activación mientras otra aplicación está en primer plano y vuelve al detectarla. Requiere una notificación permanente y el permiso para mostrar sobre otras aplicaciones.';

  @override
  String get settingWakeWordReturnToBackgroundTitle =>
      'Volver a la aplicación anterior';

  @override
  String get settingWakeWordReturnToBackgroundDescription =>
      'Vuelve a la aplicación anterior o a la pantalla de inicio cuando termine la interacción de voz que trajo Kiosk Satellite al primer plano.';

  @override
  String get voiceMicHeld =>
      'La detección de palabras de activación puede escucharte.';

  @override
  String get voiceMicBlocked =>
      'Bloqueado. Android no volverá a solicitar el permiso. Concédelo en los ajustes de la aplicación.';

  @override
  String get voiceMicMissing =>
      'Sin este permiso, nada escucha la palabra de activación.';

  @override
  String get voiceForegroundHeld =>
      'Kiosk Satellite puede pasar al primer plano cuando te escucha.';

  @override
  String get voiceForegroundMissing =>
      'Sin este permiso, se detecta la palabra de activación pero no ocurre nada.';

  @override
  String get voiceNotificationHeld =>
      'La notificación permanente que permite escuchar en segundo plano.';

  @override
  String get voiceNotificationMissing =>
      'Necesario para que la escucha en segundo plano funcione de forma fiable.';

  @override
  String get voiceBatteryHeld =>
      'Android mantendrá la escucha en funcionamiento.';

  @override
  String get voiceBatteryMissing =>
      'Sin este permiso, la escucha se detiene después de unas horas.';

  @override
  String get voicePermissionDirections =>
      'Concede estos permisos en el dispositivo: desliza desde el borde izquierdo → Configuración → Voice Satellite → Permisos del sistema necesarios.';

  @override
  String get voicePermissionsSearch =>
      'Micrófono y otros permisos necesarios para detectar palabras de activación.';

  @override
  String get voiceDisconnected => 'Home Assistant no está conectado';

  @override
  String get voiceValidate =>
      'Primero valida la conexión en Configuración de Home Assistant.';

  @override
  String get voiceChecking => 'Buscando Voice Satellite…';

  @override
  String get voiceMissing =>
      'Voice Satellite no está instalado en Home Assistant';

  @override
  String get voiceInstallHelp =>
      'Voice Satellite convierte este kiosko en un asistente de voz de manos libres para Home Assistant: detección de palabras de activación, conversaciones, temporizadores y anuncios, directamente en el panel de control.\n\nEstá disponible en el repositorio predeterminado de HACS. Instálalo en tu instancia de Home Assistant y luego vuelve aquí.';

  @override
  String get voiceLearnMore => 'Más información sobre ';

  @override
  String get voiceGithub => 'Voice Satellite en GitHub';

  @override
  String get voiceHacs => 'Abrir el repositorio de HACS';

  @override
  String get voiceLoading => 'Cargando los controles de Voice Satellite…';

  @override
  String get voiceTester => 'Prueba de palabras de activación';

  @override
  String get voiceTesterHelp =>
      'Observa en tiempo real lo que escucha y puntúa el motor para entender por qué detecta o no la palabra de activación.';

  @override
  String get voiceTesterSearch =>
      'Una vista en tiempo real de lo que escucha y puntúa el motor.';

  @override
  String get voiceTesterWaiting => 'Esperando a Voice Satellite';

  @override
  String voiceStopWordNamed(String word) {
    return '$word (palabra de detención)';
  }

  @override
  String get voiceScore => 'Puntuación';

  @override
  String get voiceThreshold => 'Umbral';

  @override
  String get voiceHits => 'Detecciones';

  @override
  String get voiceNearMisses => 'Casi detecciones';

  @override
  String get voicePeak => 'Máximo';

  @override
  String get voiceMicLevel => 'Nivel del micrófono';

  @override
  String get voiceChunkProcessing =>
      'Procesamiento por bloque (mín. / prom. / máx.)';

  @override
  String get voiceLog => 'Registro';

  @override
  String get voiceLogEmpty =>
      'Aquí aparecerán las detecciones y las casi detecciones.';

  @override
  String get voiceLogHit => 'DETECCIÓN';

  @override
  String get voiceLogNear => 'casi';

  @override
  String get voiceLogScore => 'puntuación';

  @override
  String get voiceLogDecoded => 'decodificado';

  @override
  String get voiceLogDistance => 'dist.';

  @override
  String get voiceLogConfidence => 'conf.';

  @override
  String get voiceTesterPlayRecent => 'Reproducir los últimos 10 segundos';

  @override
  String get voiceWakePage => 'Palabra de activación';

  @override
  String get voiceWakeHint =>
      'Motor, palabras de activación, sensibilidad, modelos en caché';

  @override
  String get voiceWakeLabel => 'Palabra de activación';

  @override
  String get voiceWakeEngine => 'Motor de palabras de activación';

  @override
  String get voiceWakeEngineHelp =>
      'Dónde se ejecuta la detección y qué motor escucha.';

  @override
  String get voiceWake1 => 'Palabra de activación 1';

  @override
  String get voiceWake1Help => 'La palabra que inicia un comando de voz.';

  @override
  String get voiceWake2 => 'Palabra de activación 2';

  @override
  String get voiceWake2Help =>
      'Una segunda palabra de activación que responde a través del canal de Assist 2.';

  @override
  String get voiceSensitivity => 'Sensibilidad de la palabra de activación';

  @override
  String get voiceSensitivityHelp =>
      'Con qué facilidad se detecta la palabra de activación.';

  @override
  String get voiceNoiseGate => 'Puerta de ruido para la palabra de activación';

  @override
  String get voiceNoiseGateHelp =>
      'Omite el procesamiento local de palabras de activación mientras la habitación está en silencio para reducir el uso de CPU.';

  @override
  String get voiceStopInterruption => 'Interrumpir con la palabra de detención';

  @override
  String get voiceStopInterruptionHelp =>
      'Di la palabra de detención para interrumpir las respuestas.';

  @override
  String get voiceAssignFirst =>
      'Asigna un satélite para controlar estos ajustes.';

  @override
  String get voiceCachedModels => 'Modelos en caché';

  @override
  String get voiceCachedModelsHelp =>
      'Vuelve a descargar los modelos desde Home Assistant. Úsalo después de volver a publicar un modelo.';

  @override
  String get voiceClearCache => 'Borrar caché';

  @override
  String get voiceClearing => 'Borrando…';

  @override
  String voiceCacheCleared(String count) {
    return 'Archivos borrados: $count. Descargando de nuevo.';
  }

  @override
  String voiceCacheCount(String count) {
    return 'Archivos borrados: $count';
  }

  @override
  String get voiceVerySensitive => 'Muy sensible';

  @override
  String get voiceWakeWordPreferFp32Title =>
      'Preferir modelos fp32 de vsWakeWord';

  @override
  String get voiceWakeWordPreferFp32Description =>
      'Usa modelos fp32 en lugar de las versiones int8 más pequeñas. Aumenta el uso de CPU entre un 10 y un 30% durante la escucha para evitar una variación de confianza de aproximadamente el 2%.';

  @override
  String get voiceWakeWordResumeTimeoutSecondsTitle =>
      'Tiempo de espera para reanudar (segundos)';

  @override
  String get voiceWakeWordResumeTimeoutSecondsDescription =>
      'Recuperación automática: reanuda la escucha si la página no llama a setWakeWordActive(true) después de cederle el control. Espera mientras una interacción de voz sigue transmitiendo audio para no cortar una interacción larga.';

  @override
  String get voiceSlightlySensitive => 'Poco sensible';

  @override
  String get voiceModeratelySensitive => 'Moderadamente sensible';

  @override
  String get voiceOnDevice => 'En el dispositivo';

  @override
  String voiceOnDeviceEngine(String engine) {
    return 'En el dispositivo ($engine)';
  }

  @override
  String get voiceDiagnosticsPage => 'Diagnóstico de la palabra de activación';

  @override
  String get voiceDiagnosticsHint =>
      'Activaciones y casi detecciones recientes con clips de audio';

  @override
  String get voiceDiagnosticsTitle =>
      'Activar el diagnóstico de la palabra de activación';

  @override
  String get voiceDiagnosticsDescription =>
      'Graba las últimas 10 activaciones y casi detecciones de la palabra de activación con sus puntuaciones y un clip de audio de 3 segundos de cada una. Al desactivarlo se eliminan.';

  @override
  String get voiceDiagnosticsEmpty =>
      'Aún no se han grabado activaciones de la palabra de activación.';

  @override
  String get voiceDiagnosticsActivations => 'Activaciones';

  @override
  String get voiceDiagnosticsNoNearMisses =>
      'Aún no se han grabado casi detecciones.';

  @override
  String get voiceDiagnosticsPeakLevel => 'Nivel máximo';

  @override
  String get voiceDiagnosticsAverageLevel => 'Nivel medio';

  @override
  String get voiceDiagnosticsClipped => 'Saturado';

  @override
  String get voiceDiagnosticsHeard => 'Escuchado';

  @override
  String get settingDisableCacheTitle => 'Desactivar caché';

  @override
  String get settingDisableCacheDescription =>
      'Siempre carga desde la red y descarta los datos de la página almacenados en caché al cargar, para mostrar la versión más reciente del panel de control. Es lento. Úsalo como ayuda durante el desarrollo.';

  @override
  String get settingAllowMixedContentTitle => 'Permitir contenido mixto';

  @override
  String get settingAllowMixedContentDescription =>
      'Permite que las páginas HTTPS carguen recursos HTTP no seguros. Útil cuando Home Assistant incluye contenido http:// en un panel de control que usa https:// para conectarse.';

  @override
  String get settingIgnoreSslErrorsTitle => 'Ignorar errores SSL';

  @override
  String get settingIgnoreSslErrorsDescription =>
      'Acepta certificados no confiables o autofirmados. Úsalo solo en tu propia red, ya que desactiva la verificación de certificados.';

  @override
  String get settingAutoReloadOnErrorTitle =>
      'Recargar automáticamente si hay un error';

  @override
  String get settingAutoReloadOnErrorDescription =>
      'Recupera la página automáticamente tras un error de carga o un cierre inesperado de la aplicación.';

  @override
  String get settingPullToRefreshTitle => 'Activar deslizar para recargar';

  @override
  String get settingPullToRefreshDescription =>
      'Desliza hacia abajo desde la parte superior de la página para recargarla. Desactivado de forma predeterminada porque es fácil hacerlo por accidente al desplazarse por un panel de control.';

  @override
  String get settingPullToRefreshClearCacheTitle =>
      'Borrar caché al deslizar para recargar';

  @override
  String get settingPullToRefreshClearCacheDescription =>
      'Al deslizar también se borran la caché web y los modelos de palabras de activación antes de recargar. Se conservan la sesión y los datos guardados de la página.';

  @override
  String get settingBrowserZoomTitle => 'Nivel de zoom';

  @override
  String get settingBrowserZoomDescription =>
      'Cambia la escala de toda la página. Un valor superior a 1x facilita verla a distancia en una tableta de pared. Un valor inferior a 1x permite mostrar más del panel de control en una pantalla pequeña.';

  @override
  String get settingPinchToZoomTitle => 'Activar zoom con dos dedos';

  @override
  String get settingPinchToZoomDescription =>
      'Acerca o aleja la página con dos dedos. Desactivado de forma predeterminada para evitar que los toques accidentales cambien el panel de control del kiosko.';

  @override
  String get settingDisableScrollingTitle => 'Desactivar desplazamiento';

  @override
  String get settingDisableScrollingDescription =>
      'Fija la página para que no se pueda desplazar en ninguna dirección. Los toques y botones siguen funcionando.';

  @override
  String get browserCrashPermissionHelp =>
      'Sin este permiso, el kiosko no puede volver a abrirse después de un cierre inesperado.';

  @override
  String get browserCrashPermissionMissing =>
      'Falta el permiso \"Mostrar sobre otras aplicaciones\"';

  @override
  String get browserCrashPermissionRemoteHelp =>
      'Sin este permiso, el kiosko no puede volver a abrirse después de un cierre inesperado. La pantalla para concederlo aparece en la tableta.';

  @override
  String get settingBrowserInjectJsTitle =>
      'Inyectar JavaScript en el panel de control de HA';

  @override
  String get settingBrowserInjectJsDescription =>
      'Ejecuta este código JavaScript después de cada carga del panel de control. Útil para ocultar elementos que distraen o modificar un panel de control que no administras.';

  @override
  String get settingBrowserInjectJsExternalTitle =>
      'Inyectar JavaScript en páginas externas';

  @override
  String get settingBrowserInjectJsExternalDescription =>
      'Ejecuta este código JavaScript después de cargar cada página externa: las abiertas desde un enlace del panel de control, las de la rotación de paneles de control y las del protector de pantalla de sitio web. No se aplica a la página de Music Assistant.';

  @override
  String get browserInjectJsPlaceholder =>
      '// Ejemplo: ocultar un elemento que distrae\ndocument.querySelector(\'#banner\').style.display = \'none\';';

  @override
  String get browserInjectJsExternalPlaceholder =>
      '// Ejemplo: ampliar un sitio que ignora el nivel de zoom del panel de control\ndocument.documentElement.style.zoom = \'1.25\';';

  @override
  String get setupConnectHeading => 'Conectar con Home Assistant';

  @override
  String get setupConnectLead =>
      'La URL base de tu instancia y un token de acceso de larga duración, que puedes crear en tu perfil de Home Assistant → Seguridad → Tokens de acceso de larga duración.';

  @override
  String get setupBaseUrl => 'URL base de Home Assistant';

  @override
  String get setupToken => 'Token de acceso de larga duración';

  @override
  String get setupScanQr => 'Escanear el código QR';

  @override
  String get setupInvalidToken => 'Token de acceso no válido';

  @override
  String get setupInvalidTokenHelp =>
      'Home Assistant rechazó este token. En Home Assistant, abre tu perfil → Seguridad → Tokens de acceso de larga duración, crea un nuevo token y copia su valor completo.';

  @override
  String get setupUnreachable => 'Home Assistant no responde';

  @override
  String get setupUnreachableHelp =>
      'No se recibió respuesta de esta dirección. Comprueba que la URL sea correcta y que este dispositivo esté en la misma red que tu servidor de Home Assistant.';

  @override
  String get setupUnexpectedResponseHelp =>
      'Un servidor respondió, pero no parece ser Home Assistant. Comprueba que la URL sea la dirección base de Home Assistant, por ejemplo https://homeassistant.local:8123.';

  @override
  String get setupCannotConnect => 'No se pudo conectar';

  @override
  String get setupCameraPermission => 'Se necesita permiso para usar la cámara';

  @override
  String get setupCameraBlocked =>
      'Permite que Kiosk Satellite acceda a la cámara en la configuración de Android para escanear el código QR.';

  @override
  String get setupCameraAllow =>
      'Permite el acceso a la cámara para escanear el código QR.';

  @override
  String get setupEnterBaseUrl => 'Introduce la URL base de Home Assistant';

  @override
  String get setupInvalidBaseUrl => 'URL base no válida';

  @override
  String get setupBaseUrlHelp =>
      'Es la dirección que usas para abrir Home Assistant, por ejemplo https://homeassistant.local:8123.';

  @override
  String get setupEnterToken =>
      'Introduce un token de acceso de larga duración';

  @override
  String get setupEnterTokenHelp =>
      'En Home Assistant, abre tu perfil → Seguridad → Tokens de acceso de larga duración para crear uno.';

  @override
  String get setupValidateContinue => 'Validar y continuar';

  @override
  String setupUnexpectedResponse(String error) {
    return 'Respuesta inesperada ($error)';
  }

  @override
  String get baseUrlInvalid =>
      'Introduce una URL válida, por ejemplo https://homeassistant.local:8123';

  @override
  String get baseUrlPath =>
      'Introduce solo la URL base, sin la ruta de un panel de control. Ejemplo: https://homeassistant.local:8123';

  @override
  String get baseUrlQuery =>
      'Introduce solo la URL base, sin nada después del puerto. Ejemplo: https://homeassistant.local:8123';

  @override
  String get setupChooseDashboard => 'Elige un panel de control';

  @override
  String get setupDashboardHelp =>
      'Esto es lo que mostrará el kiosko al iniciar.';

  @override
  String get setupSelectDashboard => 'Selecciona un panel de control';

  @override
  String get setupSelectDashboardHelp =>
      'Elige el panel de control que mostrará el kiosko. Puedes cambiarlo después en Configuración.';

  @override
  String get setupWelcome => 'Bienvenido';

  @override
  String get setupConnect => 'Conectar';

  @override
  String get setupConnectSummary => 'URL y token de Home Assistant';

  @override
  String get setupDashboard => 'Panel de control';

  @override
  String get setupDashboardSummary => 'Lo que muestra el kiosko';

  @override
  String get setupRecommendedSummary => 'Configuración recomendada';

  @override
  String get setupPermissions => 'Permisos';

  @override
  String get setupPermissionsSummary => 'Lo necesario para la configuración';

  @override
  String get setupPermissionLead =>
      'Android solicitará estos permisos. Se piden todos al principio para que el kiosko no te interrumpa después.';

  @override
  String get setupRemotePermissionLead =>
      'Android solicita estos permisos en la propia tablet. Acércate y acepta las solicitudes. Después, termina aquí.';

  @override
  String get setupMicrophoneHelp =>
      'Voice Satellite y el intercomunicador necesitan acceso al micrófono';

  @override
  String get setupNotificationListening =>
      'Permite la notificación permanente del servicio de Kiosk Satellite, que indica qué funciones mantiene activas y cuándo está escuchando el kiosko.';

  @override
  String get setupBatteryService =>
      'Permite que el servicio de Kiosk Satellite se ejecute en segundo plano sin que Android lo pause o lo cierre.';

  @override
  String get setupOverlayBoot =>
      'Permite que Kiosk Satellite vuelva a abrirse después de un fallo y se inicie al encender el dispositivo.';

  @override
  String get setupOverlayCrash =>
      'Permite que Kiosk Satellite vuelva a mostrarse después de un fallo.';

  @override
  String get setupBrightnessHelp =>
      'Permite que Kiosk Satellite ajuste el brillo real de la pantalla (modificar ajustes del sistema).';

  @override
  String get setupScreenControl => 'Control de pantalla';

  @override
  String get setupScreenControlHelp =>
      'Permite que Kiosk Satellite apague la pantalla cuando se le solicite (administración del dispositivo).';

  @override
  String get setupGrantPermissions => 'Conceder permisos en el dispositivo';

  @override
  String get setupRequestingPermissions =>
      'Solicitando permisos en el dispositivo…';

  @override
  String get setupPermissionsRequested =>
      'Permisos solicitados en el dispositivo';

  @override
  String get setupQrFlipCamera => 'Cambiar de cámara';

  @override
  String get setupQrCameraFailed => 'No se pudo iniciar la cámara.';

  @override
  String get setupQrTitle => 'Escanea el código QR del token';

  @override
  String get setupQrHelp =>
      'Aparece junto a un token recién creado en tu perfil de Home Assistant.';

  @override
  String get setupQrFlashOff => 'Apagar la linterna';

  @override
  String get setupQrFlashOn => 'Encender la linterna';

  @override
  String get setupPasswordFirst =>
      'Primero establece la contraseña de administración';

  @override
  String get setupPasswordBeforeImport =>
      'Escribe arriba una contraseña de administración de al menos 4 caracteres y después importa la copia de seguridad.';

  @override
  String get setupPasswordFailed => 'No se pudo establecer la contraseña';

  @override
  String get setupPasswordExists => 'Ya hay una contraseña establecida';

  @override
  String get setupPasswordExistsHelp =>
      'Inicia sesión con la contraseña establecida en la tablet para continuar aquí. Recargando…';

  @override
  String get setupNotBackup => 'El archivo no es una copia de seguridad';

  @override
  String get setupInvalidBackupHelp =>
      'El archivo no contiene JSON válido. Exporta una configuración desde Configuración en un Kiosk Satellite ya configurado o desde su administración remota.';

  @override
  String get setupWrongBackupKind =>
      'Exporta una configuración desde Configuración en un Kiosk Satellite ya configurado.';

  @override
  String get setupImportFailedHelp => 'No se pudo aplicar el archivo.';

  @override
  String get setupBackupNoDashboard =>
      'La copia de seguridad no tiene un panel de control';

  @override
  String get setupBackupNoDashboardHelp =>
      'Se aplicaron los ajustes, pero la copia se creó antes de configurar el dispositivo y no hay un panel de control para mostrar. Continúa con el asistente para elegir uno.';

  @override
  String get setupImporting => 'Importando…';

  @override
  String get setupRemoteRestoreHelp =>
      'Importa una configuración exportada de Kiosk Satellite para omitir el resto de este asistente.';

  @override
  String get setupFinishOnDevice => 'Termina en el dispositivo';

  @override
  String get setupFinishOnDeviceHelp =>
      'Se importó la configuración. Responde a las solicitudes de permisos en la pantalla de la tablet. Esta página continuará automáticamente cuando se cargue el panel de control.';

  @override
  String get setupBackupObject =>
      'La copia de seguridad debe contener un objeto JSON.';

  @override
  String get setupBackupKind =>
      'Este archivo no contiene una configuración de Kiosk Satellite.';

  @override
  String get setupBackupSettings =>
      'La copia de seguridad no contiene ajustes.';

  @override
  String get setupServiceHelp =>
      'Mantiene la aplicación activa cuando la pantalla está apagada o hay otra aplicación en primer plano. Así se mantienen la conexión con Home Assistant y funciones como la detección de movimiento y el proxy Bluetooth. Los permisos siguientes son opcionales pero recomendados: cada uno ayuda a mantener el servicio activo con la pantalla apagada.';

  @override
  String get setupBatteryMissing =>
      'Android puede pausar la aplicación cuando la pantalla está apagada y cerrar la conexión con Home Assistant.';

  @override
  String get setupOverlayMissing =>
      'Sin este permiso, el servicio no puede volver a abrir el kiosko después de un fallo.';

  @override
  String get setupVoiceDetected => 'Voice Satellite detectado';

  @override
  String get setupVoiceHelp =>
      'Esta instancia de Home Assistant tiene la integración Voice Satellite. Elige qué satélite corresponde a este kiosko y revisa su configuración. Puedes cambiarlo todo después.';

  @override
  String get setupNoSatellites => 'No se encontraron satélites';

  @override
  String get setupNoSatellitesHelp =>
      'Agrega un satélite de Assist en la integración Voice Satellite o continúa sin uno y selecciónalo después en el panel de control.';

  @override
  String get setupNewSatelliteHelp =>
      'Si este dispositivo es nuevo, primero crea una entidad de satélite en Home Assistant. Configuración → Dispositivos y servicios → Voice Satellite → Añadir entrada. IMPORTANTE: Dos dispositivos no pueden compartir la misma entidad.';

  @override
  String get setupApplyRecommended => 'Aplicar todos los ajustes recomendados';

  @override
  String get setupRecommendedHelp =>
      'Los ajustes óptimos para aprovechar todas las funciones de la integración Voice Satellite.';

  @override
  String get setupVoiceRequired => 'Obligatorio para Voice Satellite';

  @override
  String get setupMicrophoneAccess => 'Acceso al micrófono';

  @override
  String get setupNativeWakeWord =>
      'Detección nativa de palabras de activación';

  @override
  String get setupPullRefresh => 'Deslizar hacia abajo para actualizar';

  @override
  String get setupAutoplay => 'Reproducir audio y video automáticamente';

  @override
  String get setupVoiceSkipped => 'No instalado, omitido';

  @override
  String get setupRemoteHeading => 'Administración remota';

  @override
  String get setupTitle => 'Configurar\nKiosk Satellite';

  @override
  String get setupWelcomeLead =>
      'Convierte esta tableta en un kiosko de Home Assistant. La configuración tarda un par de minutos y este asistente te guía paso a paso.';

  @override
  String get setupDeviceName => 'Nombre del dispositivo';

  @override
  String get setupDeviceNameHelp =>
      'Nombre con el que se identifica este kiosko en Home Assistant, en la administración remota y en la red. Puedes cambiarlo cuando quieras en Configuración > Dispositivo.';

  @override
  String get setupEnableRemote => 'Activar la administración remota';

  @override
  String get setupEnableRemoteHelp =>
      'Sigue administrando este kiosko desde un navegador web después de configurarlo. Desde allí es mucho más fácil pegar el token de acceso de Home Assistant.';

  @override
  String get setupRemotePassword => 'Contraseña de administración remota';

  @override
  String get setupRestoreHeading => 'Restaurar copia de seguridad';

  @override
  String get setupRestore => 'Restaurar desde un archivo de configuración';

  @override
  String get setupRestoreHelp =>
      'Importa una configuración exportada desde Kiosk Satellite y omite el resto de este asistente. Se incluyen la configuración, el panel de control y los datos de inicio de sesión.';

  @override
  String get setupServicePermissions =>
      'Permisos recomendados para el servicio';

  @override
  String get setupPasswordShort => 'La contraseña es demasiado corta';

  @override
  String get setupPasswordMinimum => 'Usa al menos 4 caracteres.';

  @override
  String setupRemoteAddress(String address) {
    return 'Puedes continuar esta configuración de forma remota desde un navegador web en $address, aunque el interruptor de arriba esté desactivado.';
  }

  @override
  String get remoteWelcomeTitle => 'Bienvenido a Kiosk Satellite';

  @override
  String get remoteWelcomePassword =>
      'Esta tableta está pendiente de configurar. Primero, protege la administración remota con una contraseña.';

  @override
  String get remoteWelcomeReady =>
      'Esta tableta está pendiente de configurar. La contraseña de administración remota ya está definida. Para cambiarla, escribe una nueva aquí.';

  @override
  String get remoteInitialPassword =>
      'Contraseña de administración (mínimo 4 caracteres)';

  @override
  String get remoteNewPassword =>
      'Nueva contraseña de administración (deja el campo vacío para conservar la actual)';

  @override
  String get intercomBuiltinRing => 'Timbre integrado';

  @override
  String get intercomBuiltinChime => 'Tono integrado';

  @override
  String intercomMissingFile(String file) {
    return '$file (no encontrado)';
  }

  @override
  String get intercomAddSound => 'Añadir un sonido';

  @override
  String get intercomCopySoundHelp =>
      'Copia un archivo de sonido de este dispositivo a la carpeta de sonidos.';

  @override
  String get intercomUploadSoundHelp =>
      'Sube un archivo de sonido de esta computadora a la carpeta de sonidos.';

  @override
  String get intercomUpload => 'Subir';

  @override
  String get intercomUploading => 'Subiendo…';

  @override
  String get intercomUnsupportedSound => 'Sonido no compatible';

  @override
  String get intercomChooseSound =>
      'Sonido no compatible: elige un archivo MP3, OGG, WAV, FLAC, M4A o AAC.';

  @override
  String get intercomCopyFailed => 'No se pudo copiar el archivo';

  @override
  String intercomUploadFailed(String error) {
    return 'No se pudo subir: $error';
  }

  @override
  String intercomSaveFailed(String error) {
    return 'No se guardó: $error';
  }

  @override
  String get intercomSoundFilename =>
      'Introduce un nombre de archivo, no una ruta.';

  @override
  String get intercomSoundFormats =>
      'Elige un archivo MP3, OGG, WAV, FLAC, M4A o AAC.';

  @override
  String get voiceTimerDefaultName => 'Temporizador';

  @override
  String get voiceTimerDrag => 'Arrastra para mover los temporizadores';

  @override
  String get voiceTimerPauseHint =>
      'Toca para pausar. Toca dos veces para cancelar. Arrastra para mover.';

  @override
  String get voiceTimerResumeHint =>
      'Toca para reanudar. Toca dos veces para cancelar. Arrastra para mover.';

  @override
  String get voiceTimerCancel => 'Cancelar temporizador';

  @override
  String get voiceTimerActionError =>
      'No se pudo cambiar el temporizador. Comprueba la conexión y actualiza Voice Satellite si es necesario.';

  @override
  String get voiceTimerFinished => 'Finalizado';

  @override
  String get voiceTimerDismissHint =>
      'Toca para cerrar la alerta del temporizador.';
}
