// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Quita los instrumentos musicales de todas las aplicaciones y conserva el habla y la recitación.';

  @override
  String get onboardTitle => 'Le damos la bienvenida';

  @override
  String get onboardBody =>
      'Waaiya quita los instrumentos musicales del sonido de todas las aplicaciones de este teléfono. Se conservan el habla y la recitación del Corán. Por ahora, también se quitan las voces que cantan.';

  @override
  String get onboardQuestion => 'Soy';

  @override
  String get genderMan => 'Un hombre';

  @override
  String get genderWoman => 'Una mujer';

  @override
  String get onboardWhy =>
      'Esto solo decide qué ajustes opcionales ve. Puede cambiarlo más tarde.';

  @override
  String get stateOnTitle => 'El filtrado está activado';

  @override
  String get stateOffTitle => 'El filtrado está desactivado';

  @override
  String get stateStarting => 'Iniciando…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Se quitan los instrumentos de todas las aplicaciones. Retraso de unos $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Toque el botón para empezar.';

  @override
  String get stateModelFailed =>
      'No se pudo cargar el modelo de sonido, así que el sonido se silencia por seguridad.';

  @override
  String get stateCaptureDenied =>
      'Se necesita el permiso del micrófono para recibir el sonido de otras aplicaciones.';

  @override
  String get stateStoppedBySystem =>
      'Android detuvo el filtrado. Toque el botón para empezar de nuevo.';

  @override
  String get stateSilencedTitle => 'Filtrado detenido';

  @override
  String get stateSilenced =>
      'Filtrado detenido: las otras aplicaciones están en silencio. Toque el botón para empezar de nuevo, o Detener para oírlas sin filtrar.';

  @override
  String get releaseSilence => 'Detener: oír las aplicaciones sin filtrar';

  @override
  String get powerStartCd => 'Iniciar el filtrado';

  @override
  String get powerStopCd => 'Detener el filtrado';

  @override
  String get captureHint =>
      'Android le pedirá compartir su pantalla. Solo se usa el sonido: no se graba ni se envía nada.';

  @override
  String get needRecordAudio =>
      'Waaiya necesita el permiso del micrófono para recibir el sonido de otras aplicaciones. Nunca graba su voz.';

  @override
  String get setupBannerTitle => 'Un paso más';

  @override
  String get setupBannerBody =>
      'Sin la configuración inicial de abajo, oirá la música y el sonido filtrado a la vez.';

  @override
  String get step1Title => 'Instale Shizuku';

  @override
  String get step1Body => 'Una aplicación auxiliar gratuita de Play Store.';

  @override
  String get step1Action => 'Obtener Shizuku';

  @override
  String get step2Title => 'Inicie Shizuku';

  @override
  String get step2Body =>
      'Shizuku se inicia por Wi-Fi con la depuración inalámbrica de Android. Toque el botón para ver los pasos y luego vuelva aquí.';

  @override
  String get step2Action => 'Abrir Shizuku';

  @override
  String get step2Update => 'Actualizar Shizuku';

  @override
  String get step2TooOld =>
      'Su versión de Shizuku es demasiado antigua. Actualícela desde Play Store.';

  @override
  String get step2Denied =>
      'Shizuku está configurado para rechazar siempre a Waaiya. En Shizuku, permítalo en la lista de aplicaciones.';

  @override
  String get step3Title => 'Dé permiso';

  @override
  String get step3Body => 'Un toque y luego elija «Permitir».';

  @override
  String get step3Action => 'Dar permiso';

  @override
  String get step3Busy => 'Configurando…';

  @override
  String get setupDoneRestart =>
      'Listo. Detenga e inicie el filtrado una vez para aplicarlo.';

  @override
  String setupFailed(String details) {
    return 'La configuración no terminó. Detalles:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Se rechazó el permiso de Shizuku. Toque el botón para intentarlo de nuevo.';

  @override
  String get setupSlow =>
      'Shizuku está tardando más de lo normal. Siga esperando: en algunos teléfonos su ayudante tarda hasta un minuto en iniciarse la primera vez.';

  @override
  String get setupTimeout =>
      'Shizuku no respondió en 2 minutos. Abra Shizuku, compruebe que indica que está en marcha y vuelva a tocar el botón. Si la configuración termina más tarde, esta pantalla se actualiza sola.';

  @override
  String get setupRefusedXiaomi =>
      'Este teléfono rechazó los permisos. En Xiaomi, Redmi y POCO, active «Depuración USB (ajustes de seguridad)» en Opciones para desarrolladores (le pide iniciar sesión en una cuenta Xiaomi) y vuelva a intentarlo.';

  @override
  String get setupRefusedColoros =>
      'Este teléfono rechazó los permisos. En OPPO, OnePlus y realme, en Opciones para desarrolladores, active «Disable permission monitoring» (Desactivar supervisión de permisos); en las versiones más recientes se llama «Disable system optimization» (Desactivar optimización del sistema) y puede que solo aparezca con el teléfono en inglés. Para encontrarlo, busque «permission» en Ajustes. Luego vuelva a intentarlo.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi y POCO: si la notificación no tiene un campo para escribir el código, ponga el estilo de notificación en «Android» en los ajustes de notificaciones, o escriba el código en Waaiya con la pantalla dividida.';

  @override
  String get stepDoneCd => 'Hecho';

  @override
  String stepTodoCd(int step) {
    return 'Paso $step';
  }

  @override
  String get computerToggle => 'Usar un ordenador en su lugar';

  @override
  String get computerBody =>
      'Active la depuración por USB, conecte el teléfono y ejecute:';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get computerNote =>
      'La segunda línea es opcional: evita la pregunta de compartir pantalla en cada inicio.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingSilenceTitle =>
      'Silenciar las aplicaciones que bloquean el filtrado';

  @override
  String get settingSilenceBody =>
      'Recomendado. Algunas aplicaciones no permiten que se filtre su sonido; esta opción las silencia en lugar de dejar pasar la música.';

  @override
  String get settingHoldSilenceTitle =>
      'Mantener las aplicaciones en silencio si el filtrado se detiene solo';

  @override
  String get settingHoldSilenceBody =>
      'Recomendado. Si Android termina el filtrado (no usted), las otras aplicaciones siguen en silencio hasta que vuelva a empezar o toque Detener, en lugar de reproducir la música sin filtrar. Necesita la configuración inicial.';

  @override
  String get settingStereoTitle => 'Sonido estéreo';

  @override
  String get settingStereoBody =>
      'Desactivado: mono, que gasta aproximadamente la mitad de batería y funciona con fluidez en más teléfonos. Activado: mantiene separados los lados izquierdo y derecho. Si el teléfono es demasiado lento para el estéreo, igualmente pasa a mono solo.';

  @override
  String get settingSingingTitle => 'Silenciar el canto de mujeres';

  @override
  String get settingSingingBody => 'Se conserva el habla de las mujeres.';

  @override
  String get settingSingingNoModel =>
      'Esta versión no tiene detector de canto, así que se silencian todas las voces mientras esta opción esté activada.';

  @override
  String get settingRestart =>
      'Detenga e inicie el filtrado para aplicar los cambios.';

  @override
  String get settingGenderTitle => 'Soy';

  @override
  String get change => 'Cambiar';

  @override
  String get playerTitle => 'Vídeos perfectamente sincronizados';

  @override
  String get playerBody =>
      'Comparta un vídeo con Waaiya (o use «Abrir con») para verlo filtrado sin retraso.';

  @override
  String get licences => 'Licencias de código abierto';

  @override
  String get licencesIntro =>
      'Waaiya es software libre bajo la GNU Affero General Public License v3 o posterior. Código fuente: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Atribución 4.0 (datos de entrenamiento): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Textos completos';

  @override
  String get back => 'Atrás';

  @override
  String get linkEntryTitle => 'Abrir un enlace';

  @override
  String get linkEntryBody =>
      'Pegue un enlace de YouTube, TikTok o Instagram para verlo o guardarlo sin música.';

  @override
  String get linkTitle => 'Abrir un enlace';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Enlace de vídeo o audio';

  @override
  String get linkPaste => 'Pegar';

  @override
  String get linkOpen => 'Abrir';

  @override
  String get linkResolving => 'Abriendo el enlace…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Ver sin música';

  @override
  String get linkSave => 'Guardar sin música';

  @override
  String get linkListen => 'Escuchar sin música';

  @override
  String get linkAudioOnly =>
      'El vídeo de este enlace aún no se puede abrir: solo su sonido.';

  @override
  String get linkDownloading => 'Descargando…';

  @override
  String get linkFiltering => 'Quitando la música…';

  @override
  String get linkCancel => 'Cancelar';

  @override
  String get linkCancelled => 'Cancelado. No se guardó nada.';

  @override
  String get linkTimedOut =>
      'Android detuvo el guardado: solo permite este tipo de trabajo unas pocas horas al día. No se guardó nada; abra Waaiya e inténtelo de nuevo.';

  @override
  String get linkExportFailed => 'No se pudo guardar este. No se guardó nada.';

  @override
  String get linkSaved => 'Guardado sin música';

  @override
  String get linkSavedVideo => 'En su galería: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'En su música: Music › Waaiya';

  @override
  String get linkPlay => 'Reproducir';

  @override
  String get linkShare => 'Compartir';

  @override
  String get linkShareNote =>
      'Comparta solo los vídeos que tenga permiso para compartir.';

  @override
  String get linkLive => 'Las emisiones en directo no se pueden guardar.';

  @override
  String get linkBusy => 'Se está guardando otro vídeo. Espere a que termine.';

  @override
  String get linkInvalid => 'Pegue un enlace web (que empiece por https://).';

  @override
  String get linkLogin =>
      'El sitio no quiso mostrar este vídeo sin una cuenta. Las publicaciones públicas suelen abrirse: inténtelo de nuevo en unos minutos. Las publicaciones privadas no se pueden abrir.';

  @override
  String get linkUnsupported => 'Este sitio no es compatible.';

  @override
  String get linkPlaylist =>
      'Esto es una lista de reproducción. Abra un solo vídeo.';

  @override
  String get linkNoFormat =>
      'Este vídeo aún no está en un formato que Waaiya pueda filtrar.';

  @override
  String get linkFailed =>
      'No se pudo abrir este enlace. Compruebe su conexión e inténtelo de nuevo.';

  @override
  String get linkPlayFailed =>
      'No se pudo reproducir. No se reprodujo nada sin filtrar.';

  @override
  String get linkLimited =>
      'El sitio está limitando las solicitudes ahora mismo. Inténtelo de nuevo en unos minutos.';

  @override
  String get blurTitle => 'Desenfoque de pantalla';

  @override
  String get blurBody =>
      'Cubre personas e imágenes en la pantalla, en todas las aplicaciones, mientras el filtrado está activado. Funciona en el teléfono; no se envía nada a ningún sitio.';

  @override
  String get blurWomenTitle => 'Desenfocar a las mujeres';

  @override
  String get blurWomenBody =>
      'Todo el cuerpo. Las personas que la aplicación no puede identificar claramente como hombres también se desenfocan.';

  @override
  String get blurNudityTitle => 'Desenfocar imágenes indecentes';

  @override
  String get blurNudityBody =>
      'Desnudez y ropa reveladora, de cualquier persona: se cubre toda la pantalla.';

  @override
  String get blurFailTitle =>
      'Cubrir la pantalla si el desenfoque no da abasto';

  @override
  String get blurFailBody =>
      'Activado: se cubre toda la pantalla cuando el teléfono es demasiado lento o el desenfoque falla. Desactivado: la pantalla sigue visible con un aviso.';

  @override
  String get blurSetupShizuku => 'Permitir con Shizuku';

  @override
  String get blurSetupManual => 'Permitir en los ajustes de Android';

  @override
  String get blurStatusNeedsSetup =>
      'El desenfoque necesita mostrarse sobre otras aplicaciones. Lo mejor: permitirlo con Shizuku (activa el servicio de accesibilidad Desenfoque Waaiya, para que los toques sigan llegando a la aplicación de debajo). O permita «Mostrar sobre otras aplicaciones» en los ajustes de Android (entonces se pierden los toques en una zona desenfocada).';

  @override
  String get blurStatusNeedsOverlay =>
      'El desenfoque necesita mostrarse sobre otras aplicaciones. Lo mejor: inicie Shizuku (y permita Waaiya en él): así el desenfoque dibuja su propia capa, que los toques atraviesan. Si no, permita «Mostrar sobre otras aplicaciones» en los ajustes de Android; entonces un toque en una zona desenfocada no llega a la aplicación de debajo.';

  @override
  String get blurFailUnavailable =>
      'No disponible por ahora: una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado. Inicie el ayudante de Waaiya o Shizuku (Android 12 o posterior) y esta opción se habilita: así las cubiertas se dibujan de forma que los toques las atraviesan. Hasta entonces, cuando el desenfoque no da abasto, la pantalla sigue visible con un aviso.';

  @override
  String get blurFailNeedsA11y =>
      'No disponible por ahora: una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado. Inicie Shizuku (Android 12 o posterior) o active el servicio de accesibilidad Desenfoque Waaiya (Permitir con Shizuku, arriba) y esta opción se habilita. Hasta entonces, la pantalla sigue visible con un aviso.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String settingLanguageTitle(String language) {
    return 'Idioma: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Detenga e inicie el filtrado para aplicar los ajustes del desenfoque.';

  @override
  String get blurStatusStarting => 'Iniciando el desenfoque…';

  @override
  String get blurStatusOn => 'Desenfoque activado.';

  @override
  String get blurStatusOnVisible =>
      'Desenfoque activado, en modo prudente: este teléfono muestra el desenfoque en su propia captura de pantalla, así que una zona desenfocada sigue desenfocada hasta que cambia la escena.';

  @override
  String get blurStatusModels =>
      'A esta versión le falta un modelo de desenfoque para la opción elegida.';

  @override
  String get blurStatusFailing => 'El desenfoque no da abasto ahora mismo.';

  @override
  String get blurStatusNoOverlay =>
      'El desenfoque no puede mostrarse sobre otras aplicaciones: permítalo arriba.';

  @override
  String blurStatusNoCapture(String details) {
    return 'El desenfoque no puede ver la pantalla. Detalles:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku no pudo permitirlo:\n$details';
  }

  @override
  String get step2Guide => 'Cómo iniciar Shizuku';

  @override
  String get blurFailOldAndroid =>
      'No disponible: en esta versión de Android una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado (las cubiertas de Shizuku necesitan Android 12 o posterior). Cuando el desenfoque no da abasto, la pantalla sigue visible con un aviso.';

  @override
  String get guideTitle => 'Iniciar Shizuku, paso a paso';

  @override
  String get guideOpenDev => 'Opciones para desarrolladores';

  @override
  String get guideOpenShizuku => 'Abrir Shizuku';

  @override
  String get guideClose => 'Cerrar';

  @override
  String get guideBody =>
      'Necesita Wi-Fi y Android 11 o posterior. La vinculación se hace una sola vez; después de reiniciar el teléfono solo repite el paso 7.\n\n1. Conecte el teléfono a una red Wi-Fi.\n\n2. Active las Opciones para desarrolladores: Ajustes › Información del teléfono › Información de software › toque «Número de compilación» 7 veces. (En otros teléfonos: Ajustes › Información del teléfono › Número de compilación.)\n\n3. Abra Shizuku. Si le pide mostrar notificaciones, permítalo: el código de vinculación se escribe en una notificación de Shizuku.\n\n4. En Shizuku, en «Start via Wireless debugging» (Iniciar mediante depuración inalámbrica), toque «Pairing» (Vincular). En la página que se abre, toque «Developer options» (Opciones para desarrolladores), active «Depuración inalámbrica» y confirme con «Permitir».\n\n5. Toque las palabras «Depuración inalámbrica» (no el interruptor) y luego «Vincular dispositivo con código de vinculación». Aparece un código de 6 dígitos.\n\n6. Deje esa pantalla abierta y despliegue las notificaciones. Cuando la notificación de Shizuku diga «Pairing service found» (Servicio de vinculación encontrado), toque «Enter pairing code» (Introducir código de vinculación) y escriba el código. Shizuku indica que la vinculación se ha completado.\n\n7. Vuelva a Shizuku y toque «Start» (Iniciar) en «Start via Wireless debugging». Espere hasta que diga «Shizuku is running» (Shizuku está en marcha).\n\n8. Vuelva a Waaiya y toque «Dar permiso» y luego «Permitir».\n\nTras reiniciar el teléfono, Shizuku se detiene: conéctese a la red Wi-Fi, vuelva a activar «Depuración inalámbrica» si está desactivada, abra Shizuku y toque «Start». No hace falta volver a vincular.';

  @override
  String get wsetupRouteTitle => 'Configurar en este teléfono';

  @override
  String get wsetupRouteBody =>
      'Cuatro pasos cortos, una sola vez. Sin otra aplicación y sin ordenador. Waaiya marca cada paso cuando está hecho.';

  @override
  String get wizDevTitle => 'Active las Opciones para desarrolladores';

  @override
  String get wizDevBody =>
      'En Información del teléfono, toque «Número de compilación» 7 veces y luego vuelva aquí. Si no lo encuentra, busque «Número de compilación» en Ajustes.';

  @override
  String get wizDevBodySamsung =>
      'En Información del teléfono › Información de software, toque «Número de compilación» 7 veces y luego vuelva aquí.';

  @override
  String get wizDevBodyXiaomi =>
      'En Información del teléfono, toque «Versión del SO» (OS version) 7 veces (en teléfonos más antiguos, «Versión de MIUI»; en algunos está en «Información detallada y especificaciones») y luego vuelva aquí.';

  @override
  String get wizDevBodyColoros =>
      'En Información del dispositivo (o Información del teléfono) › Versión, toque «Número de compilación» 7 veces y luego vuelva aquí.';

  @override
  String get wizDevBodyVivo =>
      'En Información del teléfono, toque «Versión de software» 7 veces (en algunos teléfonos: Información de software › «Número de compilación») y luego vuelva aquí.';

  @override
  String get wizDevBodyHuawei =>
      'En Información del teléfono, toque «Número de compilación» 7 veces y luego vuelva aquí.';

  @override
  String get wizDevBodyTranssion =>
      'En Mi teléfono (o Información del teléfono), toque «Número de compilación» 7 veces y luego vuelva aquí.';

  @override
  String get setupNoteHuawei =>
      'Huawei: muchos teléfonos Huawei no tienen «Depuración inalámbrica». Si no la encuentra en Opciones para desarrolladores, use un ordenador («Otras formas», abajo).';

  @override
  String get wsetupFilterOn =>
      'El filtrado está activado: en esta versión de Android el código no se puede escribir en una notificación mientras funciona. Detenga primero el filtrado, o use la pantalla dividida y «Escribir el código aquí».';

  @override
  String get wizDevSearch =>
      'Los nombres pueden variar según el idioma del teléfono: si no lo encuentra, use la búsqueda de la parte superior de Ajustes.';

  @override
  String get wizDevAction => 'Abrir Información del teléfono';

  @override
  String get wizWifiTitle => 'Conéctese a una red Wi-Fi';

  @override
  String get wizWifiBody =>
      'Sirve cualquier red Wi-Fi; no hace falta internet.';

  @override
  String get wizWifiAction => 'Abrir los ajustes de Wi-Fi';

  @override
  String get wizWdTitle => 'Active la depuración inalámbrica';

  @override
  String get wizWdBody =>
      'Waaiya abre Opciones para desarrolladores en «Depuración inalámbrica». Actívela y toque «Permitir».';

  @override
  String get wizWdAction => 'Abrir Opciones para desarrolladores';

  @override
  String get wizPairTitle => 'Escriba el código de vinculación';

  @override
  String get wizPairBody =>
      'Toque las palabras «Depuración inalámbrica» y luego «Vincular dispositivo con código de vinculación». Escriba los 6 dígitos en la notificación de Waaiya. Waaiya hace el resto.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya ya está vinculado con este teléfono: no hace falta ningún código. Toque el botón y Waaiya termina solo.';

  @override
  String get wizPairAction => 'Continuar';

  @override
  String get wizAgain => 'Volver a hacer la configuración';

  @override
  String get setupShizukuReadyTitle => 'Con Shizuku, que ya está en marcha';

  @override
  String get setupOtherWaysPlain => 'Otras formas de hacer la configuración';

  @override
  String get wizSkip => 'Ir directamente a la depuración inalámbrica';

  @override
  String get setupOtherWays => 'Otras formas: Shizuku o un ordenador';

  @override
  String get wsetupEnterHere => 'Escribir el código aquí';

  @override
  String get wsetupCancel => 'Cancelar';

  @override
  String get wsetupAndroid10 =>
      'Android 10 no puede hacer la configuración por sí solo: necesita un ordenador, directamente (abajo) o para iniciar Shizuku una vez.';

  @override
  String get wsetupShizukuHeading => 'O con la aplicación Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku también deja que los toques atraviesen las cubiertas de la pantalla.';

  @override
  String get wsetupChannel => 'Configuración inicial';

  @override
  String get wsetupNotifTitle =>
      'Configuración de Waaiya: esperando el código de vinculación';

  @override
  String get wsetupFoundTitle => 'Pantalla de vinculación encontrada';

  @override
  String get wsetupBusyTitle => 'Configuración de Waaiya';

  @override
  String get wsetupDoneTitle => 'Configuración terminada';

  @override
  String get wsetupDoneBody =>
      'Waaiya ya puede silenciar el sonido original. Puede desactivar la depuración inalámbrica.';

  @override
  String get wsetupDoneHelperBody =>
      'Listo. Este teléfono no deja que las aplicaciones conserven estos permisos, así que el ayudante de Waaiya silencia el sonido original. El ayudante se detiene cuando el teléfono se reinicia y cuando Waaiya se actualiza. Cuando abra Waaiya después, vuelve a iniciar el ayudante solo si la depuración inalámbrica está activada; si no, muestra un botón para hacerlo.';

  @override
  String get helperMissingTitle => 'El ayudante de Waaiya está detenido';

  @override
  String get helperMissingBody =>
      'Este teléfono no conserva los permisos de Waaiya, así que Waaiya usa su ayudante. El ayudante se detiene cuando el teléfono se reinicia y cuando Waaiya se actualiza. Conéctese a una red Wi-Fi, active «Depuración inalámbrica» en Opciones para desarrolladores y luego toque «Iniciar el ayudante de Waaiya».';

  @override
  String get helperChannel => 'Ayudante de Waaiya';

  @override
  String get helperStarting => 'Iniciando el ayudante…';

  @override
  String get helperModeNote =>
      'Este teléfono no deja que las aplicaciones conserven estos permisos: el ayudante de Waaiya hace el trabajo. Se detiene cuando el teléfono se reinicia y cuando Waaiya se actualiza. Cuando abra Waaiya después, vuelve a iniciar el ayudante solo si la depuración inalámbrica está activada; si no, muestra un botón para hacerlo.';

  @override
  String get helperTipXiaomi =>
      'Opcional, para conservar los permisos para siempre (sin ayudante tras los reinicios): en Opciones para desarrolladores, active «Depuración USB (ajustes de seguridad)» (le pide iniciar sesión en una cuenta Xiaomi) y luego vuelva a hacer la configuración.';

  @override
  String get helperTipColoros =>
      'Opcional, para conservar los permisos para siempre (sin ayudante tras los reinicios): en Opciones para desarrolladores, active «Disable permission monitoring» (Desactivar supervisión de permisos); en las versiones más recientes, «Disable system optimization» (Desactivar optimización del sistema), que puede que solo aparezca con el teléfono en inglés. Luego vuelva a hacer la configuración.';

  @override
  String get stateOnHelperMissing =>
      'El sonido original no está silenciado, así que oye la música junto con el sonido filtrado: el ayudante de Waaiya está detenido. Conéctese a una red Wi-Fi, active la depuración inalámbrica y luego toque «Iniciar el ayudante de Waaiya».';

  @override
  String get setupRefusedTryWireless =>
      'O use «Configurar en este teléfono» en esta página: así el ayudante de Waaiya funciona sin ese interruptor.';

  @override
  String get helperStartAnywayTitle => 'El ayudante de Waaiya está detenido';

  @override
  String get helperStartAnywayBody =>
      'Sin él oirá la música junto con el sonido filtrado. Inicie primero el ayudante (la depuración inalámbrica debe estar activada), o inicie el filtrado de todos modos.';

  @override
  String get wsetupFailedTitle => 'La configuración no terminó';

  @override
  String get wsetupPairing => 'Vinculando…';

  @override
  String get wsetupConnecting => 'Conectando y dando los permisos…';

  @override
  String get wsetupNeedWifi =>
      'Conéctese primero a una red Wi-Fi (no hace falta internet): la depuración inalámbrica solo funciona con Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'En Opciones para desarrolladores, active «Depuración inalámbrica» y luego toque su nombre y «Vincular dispositivo con código de vinculación».';

  @override
  String get wsetupOpenDialog =>
      'En Depuración inalámbrica, toque «Vincular dispositivo con código de vinculación». Deje el código en pantalla y toque «Introducir código» aquí.';

  @override
  String get wsetupEnterCodeBody =>
      'Toque «Introducir código» y escriba el código de 6 dígitos que se muestra en Ajustes.';

  @override
  String get wsetupCodeWaiting =>
      'Código recibido. Esperando la pantalla «Vincular dispositivo con código de vinculación»: déjela abierta.';

  @override
  String get wsetupWrongCode =>
      'Ese código no se aceptó. Compruebe los 6 dígitos de la pantalla e introdúzcalos de nuevo. Si la pantalla de vinculación se cerró, vuelva a abrirla: el código cambia.';

  @override
  String get wsetupPairingFailed =>
      'La vinculación no funcionó. Cierre la pantalla de vinculación, vuelva a abrir «Vincular dispositivo con código de vinculación» e introduzca el nuevo código.';

  @override
  String get wsetupWaitingConnect =>
      'Vinculado. Mantenga activada la «Depuración inalámbrica»: Waaiya se está conectando.';

  @override
  String get wsetupNotPaired =>
      'Este teléfono ya no reconoce a Waaiya (la vinculación se eliminó o caducó). Abra «Vincular dispositivo con código de vinculación» e introduzca el código.';

  @override
  String get wsetupConnectFailed =>
      'No se pudo conectar a la depuración inalámbrica. Desactívela y vuelva a activarla: Waaiya lo intenta de nuevo solo.';

  @override
  String get wsetupGrantFailed =>
      'Conectado, pero aún faltan los permisos. Use Shizuku o un ordenador (abajo).';

  @override
  String get wsetupTimeout =>
      'Se detuvo tras 10 minutos sin terminar. Puede intentarlo de nuevo.';

  @override
  String get wsetupCodeUnreadable =>
      'Escriba los 6 dígitos del código de vinculación.';

  @override
  String get wsetupCodeHint => 'Código de 6 dígitos';

  @override
  String get wsetupEnterCode => 'Introducir código';

  @override
  String wsetupDetail(String details) {
    return 'Detalles: $details';
  }

  @override
  String get wsetupErrTimeout => 'sin respuesta a tiempo';

  @override
  String get wsetupErrRefused => 'conexión rechazada';

  @override
  String get wsetupDevOff =>
      'Las Opciones para desarrolladores están desactivadas. En Información del teléfono, toque «Número de compilación» 7 veces y luego vuelva.';

  @override
  String get wsetupOpenAbout => 'Información del teléfono';

  @override
  String get wsetupNotifOff =>
      'Las notificaciones están desactivadas para Waaiya, así que el código no se puede escribir en una notificación. Use la pantalla dividida (Ajustes en una mitad, Waaiya en la otra) y toque «Escribir el código aquí».';

  @override
  String get wsetupCodeDialogTitle => 'Código de vinculación';

  @override
  String get wsetupCodeDialogBody =>
      'Solo con pantalla dividida (Ajustes en una mitad, Waaiya en la otra): salir de Ajustes cierra la pantalla de vinculación y su código deja de funcionar. Escriba el código de 6 dígitos que aparece en «Vincular dispositivo con código de vinculación».';

  @override
  String get wsetupCodeOk => 'Vincular';

  @override
  String get blurStrictTitle => 'Quién queda sin cubrir';

  @override
  String blurStrictValue(String level) {
    return 'Quién queda sin cubrir: $level';
  }

  @override
  String get blurStrict0 =>
      'Estricto: solo las personas que la aplicación casi seguro identifica como hombres';

  @override
  String get blurStrict1 =>
      'Equilibrado: aproximadamente el doble de hombres sin cubrir';

  @override
  String get blurStrict2 => 'Flexible: algunos hombres más que en equilibrado';

  @override
  String get blurStrict0Short => 'estricto';

  @override
  String get blurStrict1Short => 'equilibrado';

  @override
  String get blurStrict2Short => 'flexible';

  @override
  String get blurStrictHelp =>
      'Se cubre a toda persona que la aplicación no tenga claro que es un hombre. Estricto deja sin cubrir a unos 7 hombres de cada 100; equilibrado, a unos 14; flexible, a unos 16. Cada nivel menos estricto también deja sin cubrir a aproximadamente 1 mujer más de cada 100.';

  @override
  String get stateOnNotMuted =>
      'El sonido original aún no está silenciado, así que oye la música junto con el sonido filtrado. Termine la configuración inicial de abajo.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya no puede silenciar el sonido original de la aplicación que suena ahora, así que puede que aún se oiga la música. Detenga e inicie el filtrado. Si sigue igual, envíe el informe de diagnóstico (al final de esta pantalla).';

  @override
  String get stateTooSlow =>
      'Este teléfono es demasiado lento para filtrar el sonido en directo, así que el sonido se corta. «Abrir un enlace», más abajo, sigue funcionando: filtra el vídeo antes de reproducirlo.';

  @override
  String get stateMonoNote =>
      'El sonido está en mono para que este teléfono pueda seguir el ritmo.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'En silencio, porque no permite el filtrado: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Se oye sin filtrar, porque no permite el filtrado: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android no dio a Waaiya el sonido de otras aplicaciones. Toque el botón para empezar de nuevo.';

  @override
  String get stateCaptureCancelled =>
      'El inicio se canceló en la pregunta de Android sobre compartir pantalla. Waaiya necesita que elija «Iniciar» ahí para recibir el sonido. No se graba ni se envía nada.';

  @override
  String get startNoSetupTitle => 'La música se seguirá oyendo';

  @override
  String get startNoSetupBody =>
      'La configuración inicial aún no está hecha. Sin ella, Waaiya no puede silenciar el sonido original: oirá la música y el sonido filtrado a la vez.\n\n«Abrir un enlace» funciona sin ninguna configuración.';

  @override
  String get startNoSetupSetup => 'Hacer la configuración';

  @override
  String get startNoSetupAnyway => 'Iniciar de todos modos';

  @override
  String get diagButton => '¿Algún problema? Informe de diagnóstico';

  @override
  String get diagTitle => 'Informe de diagnóstico';

  @override
  String get diagNote =>
      'Lo que Waaiya ve en este teléfono. Cópielo o compártalo con quien le ayude. La aplicación por sí sola no envía nada.';

  @override
  String get notifStoppedTitle => 'Waaiya se detuvo';

  @override
  String get notifStoppedText =>
      'El sonido ya no se filtra. Toque para empezar de nuevo.';

  @override
  String get wsetupGuide => 'Pasos con imágenes';

  @override
  String get navFilter => 'Filtro';

  @override
  String get navScreen => 'Pantalla';

  @override
  String get navLinks => 'Enlaces';

  @override
  String get navSetup => 'Configuración';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get setupDoneTitle => 'Configuración terminada';

  @override
  String get setupDoneBody =>
      'Waaiya puede silenciar el sonido original de otras aplicaciones. Vuelva a hacerla solo si algo cambió (la configuración se deshizo, o Waaiya dice que falta).';

  @override
  String get setupRedo => 'Mostrar de nuevo la configuración';

  @override
  String get setupGo => 'Ir a la configuración';

  @override
  String get helperTitle => 'Toques a través de las cubiertas';

  @override
  String get helperBodyOff =>
      'Sin ayuda, una cubierta bloquea los toques que hay debajo. El ayudante de Waaiya dibuja las cubiertas para que los toques las atraviesen. Active la depuración inalámbrica (se necesita Wi-Fi) y toque el botón; la primera vez, vincule una vez como en la configuración. Después de reiniciar el teléfono, vuelva a tocarlo.';

  @override
  String get helperStart => 'Iniciar el ayudante de Waaiya';

  @override
  String get helperOn =>
      'El ayudante de Waaiya dibuja las cubiertas: los toques las atraviesan. Se detiene cuando el teléfono se reinicia o cuando se desactiva la depuración por USB; entonces vuelva a tocar el botón.';

  @override
  String get helperShizukuOn =>
      'Shizuku dibuja las cubiertas: los toques las atraviesan.';

  @override
  String get helperOrShizuku => 'O con Shizuku:';

  @override
  String get filterOptionsTitle => 'Opciones del filtro';

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String get desktopPreview =>
      'Vista previa: el motor del filtro aún no está conectado en este ordenador. El botón solo muestra cómo funcionará la aplicación.';

  @override
  String actionFailed(String details) {
    return 'No funcionó: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Se quitan los instrumentos de todas las aplicaciones.';

  @override
  String get engineErrorNoPactl =>
      'No se encontraron las herramientas de sonido (pactl). Waaiya necesita PulseAudio, o PipeWire con pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'El servidor de sonido no está en marcha (PulseAudio o PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Este sistema no tiene una sesión de usuario de systemd, que es la que ejecuta el filtro en segundo plano.';

  @override
  String get engineErrorNoOutput =>
      'No se encontraron altavoces ni auriculares.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'No se pudo instalar el filtro. Detalles:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'El filtro no se inició. Detalles:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'El filtro se detuvo con un error. Detalles:\n$details';
  }

  @override
  String get autostartTitle => 'Iniciar al iniciar sesión';

  @override
  String get autostartBody => 'Filtrar el sonido en cuanto inicie sesión.';

  @override
  String get blurBodyDesktop =>
      'Cubre personas e imágenes en la pantalla, sobre todas las ventanas, mientras Waaiya está abierto (funciona tanto si el filtro de sonido está activado como si no). Funciona en este ordenador; no se envía nada a ningún sitio. Al cerrar la ventana de Waaiya se detiene el desenfoque.';

  @override
  String get blurFailBodyDesktop =>
      'Activado: se cubre toda la pantalla cuando el ordenador es demasiado lento o el desenfoque falla; los clics siguen llegando a las ventanas de debajo. Desactivado: la pantalla sigue visible con una barra roja arriba.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Desenfoque activado. Este escritorio muestra el desenfoque en su propia captura de pantalla, así que una zona desenfocada sigue desenfocada hasta que cambia la escena.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'El desenfoque no puede mostrarse sobre otras ventanas en este escritorio. Detalles:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Elija su pantalla en la ventana de compartir pantalla y permítalo. Waaiya lo pide solo una vez; la imagen se queda en este ordenador.';

  @override
  String blurStatusExited(String details) {
    return 'El desenfoque se detuvo inesperadamente. Desactive y vuelva a activar una opción de desenfoque para intentarlo de nuevo. Detalles:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'El detector de canto de mujeres no se cargó, así que se silencian las voces mientras esa opción esté activada.';

  @override
  String get blurStatusUncovered =>
      'Un monitor no está cubierto por el desenfoque: no se compartió con él, o se conectó más tarde. Desactive y vuelva a activar una opción de desenfoque, y elija todas las pantallas en la ventana de compartir pantalla.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Faltan los modelos del desenfoque en esta instalación, así que no puede cubrir nada; queda una barra roja en la parte superior de la pantalla. Vuelva a instalar Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Lo que Waaiya ve en este ordenador. Cópielo y déselo a quien le ayude. La aplicación por sí sola no envía nada.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Recomendado. Si el filtrado se detiene solo (por un error, no por usted), las otras aplicaciones siguen en silencio hasta que vuelva a empezar o pulse Detener, en lugar de reproducir la música sin filtrar.';

  @override
  String get settingStereoBodyDesktop =>
      'Desactivado: mono, que exige menos al ordenador. Activado: mantiene separados los lados izquierdo y derecho. Si el ordenador es demasiado lento para el estéreo, pasa a mono solo.';

  @override
  String get linkEntryBodyDesktop =>
      'Pegue un enlace de YouTube, TikTok o Instagram para verlo con el filtro activado, o para guardarlo sin música.';

  @override
  String get linkEntryBodyWatch =>
      'Pegue un enlace de YouTube, TikTok o Instagram para verlo en su navegador con el filtro activado.';

  @override
  String get linkWatchNoteDesktop =>
      'Se abre en su navegador. Waaiya inicia primero el filtro, así que la música también se quita ahí.';

  @override
  String get linkFilterFailed =>
      'El filtro no se inició, así que el enlace no se abrió. Inícielo en la página Filtro e inténtelo de nuevo.';

  @override
  String get linkSavedVideoDesktop => 'En su carpeta Vídeos: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'En su carpeta Música: Waaiya';

  @override
  String get linkShowInFolder => 'Mostrar en la carpeta';

  @override
  String get linkSingingNote =>
      'El canto de mujeres también se silencia, como en sus ajustes.';
}
