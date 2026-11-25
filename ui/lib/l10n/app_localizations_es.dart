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
      'Esto solo decide qué ajustes opcionales ve. Por ejemplo, «Silenciar el canto de mujeres» solo se ofrece a los hombres. Puede cambiarlo más tarde.';

  @override
  String get stateOnTitle => 'El filtrado está activado';

  @override
  String get stateOffTitle => 'El filtrado está desactivado';

  @override
  String get stateStarting => 'Iniciando…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Se quitan los instrumentos de todas las aplicaciones. El sonido llega unos $delayMs ms tarde (1000 ms son un segundo).';
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
  String get micOpenSettings =>
      'Abrir los ajustes de Waaiya y permitir el micrófono';

  @override
  String get keepRunningTitle => 'Mantener Waaiya en marcha';

  @override
  String get keepRunningBattery =>
      'Este teléfono puede cerrar Waaiya al cabo de un rato para ahorrar batería, y entonces el filtrado se detiene. En los ajustes de Waaiya, en Batería, elige «Sin restricciones». En Xiaomi, Redmi y POCO: «Sin restricciones», y activa también el Inicio automático.';

  @override
  String get keepRunningNotifications =>
      'Las notificaciones de Waaiya están desactivadas, así que no puede avisarte cuando el filtrado se detiene. Actívalas en los ajustes de Waaiya.';

  @override
  String get keepRunningOpen => 'Abrir los ajustes de Waaiya';

  @override
  String get lockAskTitle => '¿Seguir filtrando al bloquear la pantalla?';

  @override
  String get lockTitle => 'Seguir filtrando al bloquear la pantalla';

  @override
  String get lockBody =>
      'En este teléfono Android pregunta antes de cada inicio y luego detiene el filtrado cada vez que se bloquea la pantalla. Waaiya puede evitarlo levantando la protección de pantalla compartida de Android mientras filtra, y la restablece cuando el filtrado se detiene. Mientras está levantada, otra pantalla compartida al mismo tiempo (una videollamada, por ejemplo) también puede mostrar tus notificaciones. Un cambio se aplica en el próximo inicio.';

  @override
  String get lockYes => 'Seguir filtrando';

  @override
  String get lockNo => 'Detener en cada bloqueo';

  @override
  String get sendToSupport => 'Enviar a Waaiya';

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
  String get computerWeb =>
      'Lo más sencillo: en un ordenador, abra waaiya.mssid.org/usb en Chrome o Edge, active la depuración por USB y conecte el teléfono con un cable. No hay que instalar nada y funciona también en Android 10. O, con adb instalado:';

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
  String get settingSingingBody =>
      'Por ejemplo, se silencia una canción cantada por una mujer, pero se sigue oyendo a una mujer que da una charla.';

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
  String get blurOnTitle => 'El desenfoque está activado';

  @override
  String get blurOffTitle => 'El desenfoque está desactivado';

  @override
  String get blurStartCd => 'Activar el desenfoque';

  @override
  String get blurStopCd => 'Desactivar el desenfoque';

  @override
  String get blurOffDetail =>
      'Toque el botón para empezar. El filtrado empieza con él.';

  @override
  String get blurWhatTitle => 'Qué desenfocar';

  @override
  String get blurWomenTitle => 'Desenfocar a las mujeres';

  @override
  String get blurWomenBody =>
      'Cubre todo el cuerpo. Si la aplicación no está segura de que una persona es un hombre, también la cubre.';

  @override
  String get blurNudityTitle => 'Desenfocar imágenes indecentes';

  @override
  String get blurNudityBody =>
      'Desnudez o ropa reveladora, en cualquier persona: se cubre toda la pantalla.';

  @override
  String get blurFailTitle =>
      'Cubrir la pantalla si el desenfoque no da abasto';

  @override
  String get blurFailBody =>
      'Activado: se cubre toda la pantalla cuando el teléfono es demasiado lento o el desenfoque falla. Desactivado: la pantalla sigue visible con un aviso.';

  @override
  String get blurSetupManual => 'Permitir en los ajustes de Android';

  @override
  String get blurStatusNeedsSetup =>
      'Para desenfocar, Waaiya tiene que mostrarse sobre otras aplicaciones. Lo mejor: «Ir a la configuración», para que sus toques sigan llegando a la aplicación que está debajo del desenfoque. O «Permitir en los ajustes de Android», pero entonces un toque en una zona desenfocada no hace nada.';

  @override
  String get blurStatusNeedsOverlay =>
      'Para desenfocar, Waaiya tiene que mostrarse sobre otras aplicaciones. Lo mejor: haga la configuración única, para que sus toques sigan llegando a la aplicación que está debajo del desenfoque. O permita «Mostrar sobre otras aplicaciones» en los ajustes de Android, pero entonces un toque en una zona desenfocada no hace nada.';

  @override
  String get blurFailUnavailable =>
      'No disponible por ahora: una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado. Inicie el ayudante de Waaiya (Android 12 o posterior) y esta opción se habilita: así las cubiertas se dibujan de forma que los toques las atraviesan. Hasta entonces, cuando el desenfoque no da abasto, la pantalla sigue visible con un aviso.';

  @override
  String get blurFailNeedsA11y =>
      'No disponible por ahora: una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado. Inicie el ayudante de Waaiya (Android 12 o posterior) o active el servicio de accesibilidad Desenfoque Waaiya en los ajustes de Android y esta opción se habilita. Hasta entonces, la pantalla sigue visible con un aviso.';

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
  String get step2Guide => 'Cómo iniciar Shizuku';

  @override
  String get blurFailOldAndroid =>
      'No disponible: en esta versión de Android una cubierta de pantalla completa bloquearía todos los toques y podría quedarse atascado (las cubiertas que dejan pasar los toques necesitan Android 12 o posterior). Cuando el desenfoque no da abasto, la pantalla sigue visible con un aviso.';

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
      'Waaiya no puede silenciar el sonido original de la aplicación que suena ahora, así que puede que aún se oiga la música. Detenga e inicie el filtrado. Si sigue igual, envíe el informe de diagnóstico (Ajustes).';

  @override
  String get stateTooSlow =>
      'Este teléfono es demasiado lento para filtrar el sonido en directo, así que el sonido se corta. «Abrir un enlace», más abajo, sigue funcionando: filtra el vídeo antes de reproducirlo.';

  @override
  String get stateTooSlowNoLinks =>
      'Este teléfono es demasiado lento para filtrar el sonido en directo, así que el sonido se corta.';

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
  String get startNoSetupBodyNoLinks =>
      'La configuración inicial aún no está hecha. Sin ella, Waaiya no puede silenciar el sonido original: oirá la música y el sonido filtrado a la vez.';

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
  String get worshipPrayerSunrise => 'Salida del sol';

  @override
  String get worshipPrayerDhuhr => 'Dhuhr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'Terminar el silencio ya';

  @override
  String get worshipUnmute => 'Reactivar el sonido ya';

  @override
  String get worshipSmsDefault =>
      'Es la hora de la oración y no puedo contestar ahora. Devuelvo la llamada después.';

  @override
  String get updateTitle => 'Actualizaciones';

  @override
  String get updateAuto => 'Buscar una versión nueva una vez al día';

  @override
  String get updateAutoBody =>
      'Waaiya pregunta a waaiya.mssid.org si hay una versión más reciente, y no envía nada más. No se descarga nada hasta que toques Actualizar ahora.';

  @override
  String get updateCheck => 'Buscar ahora';

  @override
  String get updateChecking => 'Buscando…';

  @override
  String updateNone(String version) {
    return 'Tienes la última versión ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest está disponible. Tienes la $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Descarga: $size, solo los cambios (la aplicación completa ocupa $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Descarga: $size.';
  }

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String updateDownloading(String progress) {
    return 'Descargando: $progress';
  }

  @override
  String get updatePreparing => 'Preparando la actualización…';

  @override
  String get updateInstalling =>
      'Confirma la instalación en la pantalla que muestra Android.';

  @override
  String get updateStopsFilter =>
      'Instalar detiene el filtrado. Vuelve a iniciarlo después de la actualización.';

  @override
  String get updatePermission =>
      'Permite que Waaiya instale sus actualizaciones y vuelve a tocar Actualizar ahora.';

  @override
  String get updateFailed =>
      'No se pudo completar la actualización. Inténtalo más tarde o descárgala desde el sitio web.';

  @override
  String get updateOpenPage => 'Abrir la página de descarga';

  @override
  String get updateCheckFailed =>
      'No se pudo comprobar ahora. Inténtalo más tarde.';

  @override
  String get moveOldTitle => 'Waaiya se ha mudado';

  @override
  String get moveOldBody =>
      'Waaiya llega ahora como una nueva app en Android (la misma Waaiya con otro nombre), y esta ya no recibirá actualizaciones. Instale la nueva: sus ajustes se pasan a ella. Después haga su configuración única y desinstale esta.';

  @override
  String get moveOldInstalled =>
      'La nueva Waaiya está instalada. Ábrala: toma sus ajustes. Haga su configuración única y luego desinstale esta antigua para que nunca filtren las dos a la vez.';

  @override
  String get moveInstall => 'Instalar la nueva Waaiya';

  @override
  String get moveOpenNew => 'Abrir la nueva Waaiya';

  @override
  String get moveRemoveThis => 'Desinstalar esta Waaiya antigua';

  @override
  String get moveNewTitle => 'La Waaiya antigua sigue instalada';

  @override
  String get moveNewBody =>
      'La Waaiya antigua (anterior a la versión 0.2.15) sigue en este teléfono. Desinstálela para que nunca filtren las dos a la vez.';

  @override
  String get moveNewImported => 'Sus ajustes se trajeron de ella.';

  @override
  String get moveRemoveOld => 'Desinstalar la Waaiya antigua';

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

  @override
  String get singingKeepTitle => 'Conservar el canto (prueba)';

  @override
  String get singingKeepBody =>
      'Se quitan los instrumentos pero se conservan las voces que cantan, así que una charla con un nasheed de fondo también conserva la voz del nasheed; usted decide si eso es aceptable.';

  @override
  String get singingKeepNoModel =>
      'Esta versión no tiene el modelo de canto, así que el sonido queda en silencio mientras esto esté activado. Desactívelo.';

  @override
  String get fixFilterAppsTitle => 'Aplicaciones que se oyen sin filtrar';

  @override
  String get fixFilterAppsBody =>
      'Las aplicaciones que elija aquí suenan tal cual: sin filtro y sin silencio. Por ejemplo, una aplicación de videollamadas, para que las llamadas no tengan retraso.';

  @override
  String get fixAddApp => 'Añadir una aplicación';

  @override
  String fixRemoveApp(Object app) {
    return 'Quitar $app';
  }

  @override
  String get fixNoApps => 'No se ha elegido ninguna aplicación.';

  @override
  String get fixPickTitle => 'Elegir una aplicación';

  @override
  String get fixPickEmpty => 'No se encontró ninguna otra aplicación.';

  @override
  String get fixPickPlayingDesktop =>
      'Las aplicaciones que suenan ahora y las que ya están elegidas.';

  @override
  String get fixCancel => 'Cancelar';

  @override
  String get fixBlurAppsTitle => 'Aplicaciones sin cubrir';

  @override
  String get fixBlurAppsBody =>
      'No hay cubiertas mientras una de estas aplicaciones ocupa toda la pantalla, por ejemplo una aplicación de mapas o la de su banco. Las cubiertas vuelven en cuanto sale de ella, o siempre que Waaiya no está seguro de qué aplicación se muestra.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Necesita la configuración inicial: sin ella, Waaiya no puede saber qué aplicación hay en la pantalla, así que el desenfoque sigue activo en todas partes.';

  @override
  String get fixBlurAppsHelperMode =>
      'El ayudante de Waaiya no está en marcha, así que no se puede saber qué aplicación hay en la pantalla. El desenfoque sigue activo en todas partes hasta que se vuelva a iniciar el ayudante desde la página Configuración.';

  @override
  String get fixHandTitle => 'Cubrir una zona a mano';

  @override
  String get fixHandBody =>
      'Mientras el desenfoque está en marcha, puede cubrir por su cuenta una parte de la pantalla, por ejemplo una imagen que el desenfoque no cubrió: toque «Cubrir una zona» y deslice el dedo sobre ella. Queda cubierta hasta que quite la cubierta o el desenfoque se detenga.';

  @override
  String get fixHandNotRunning =>
      'Disponible mientras el desenfoque está en marcha: filtrado activado y una opción de desenfoque activada.';

  @override
  String get fixCoverArea => 'Cubrir una zona';

  @override
  String fixRemoveCovers(Object count) {
    return 'Quitar las cubiertas manuales ($count)';
  }

  @override
  String get fixNoteTitle => 'Anotar un error';

  @override
  String get fixNoteBody =>
      'Cuando Waaiya se equivoque, toque lo que pasó, por ejemplo «Se oyó música». La nota guarda la hora, la aplicación y los ajustes, para ayudar a encontrar la causa. Se queda en este dispositivo y nunca se envía.';

  @override
  String get fixMissedSound => 'Se oyó música';

  @override
  String get fixWrongSound => 'Voz quitada por error';

  @override
  String get fixMissedScreen => 'Algo no se cubrió';

  @override
  String get fixWrongScreen => 'Cubierto por error';

  @override
  String fixNoted(Object count) {
    return 'Anotado ($count notas en este dispositivo).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Notas en este dispositivo: $count';
  }

  @override
  String get fixNotesShow => 'Ver las notas';

  @override
  String get fixNotesDelete => 'Borrar las notas';

  @override
  String get fixNotesDeleteAsk =>
      '¿Borrar todas las notas? No se puede deshacer.';

  @override
  String get fixNotesTitle => 'Notas sobre errores';

  @override
  String get worshipTitle => 'Horarios de oración';

  @override
  String get worshipBody =>
      'Opcional. Se calculan en este teléfono a partir del lugar que elija. No se envía nada.';

  @override
  String worshipPlace(Object place) {
    return 'Lugar: $place';
  }

  @override
  String get worshipPlaceNone => 'Lugar: sin elegir';

  @override
  String get worshipChoose => 'Elegir';

  @override
  String get worshipPlaceSearch => 'Buscar una ciudad';

  @override
  String get worshipPlaceNoMatch =>
      'No se encontró ninguna ciudad. Puede escribir las coordenadas en su lugar.';

  @override
  String get worshipPlaceCustom => 'Escribir coordenadas';

  @override
  String get worshipLat => 'Latitud (norte +, sur −)';

  @override
  String get worshipLon => 'Longitud (este +, oeste −)';

  @override
  String get worshipZone => 'Zona horaria, por ejemplo Europe/Madrid';

  @override
  String get worshipCustomInvalid => 'Revise los números y la zona horaria.';

  @override
  String get worshipPlaceInvalid =>
      'Este lugar no se puede usar. Vuelva a elegirlo.';

  @override
  String worshipMethod(Object method) {
    return 'Cálculo: $method';
  }

  @override
  String get worshipMethodTitle => 'Método de cálculo';

  @override
  String get worshipMethodNote =>
      'Elegido según el país de la ciudad. Escoja el que sigue su mezquita.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Hora del Asr';

  @override
  String get worshipAsrStandard => 'Estándar (shafií, malikí, hanbalí)';

  @override
  String get worshipAsrHanafi => 'Hanafí';

  @override
  String get worshipMethodMwl => 'Liga Mundial Musulmana';

  @override
  String get worshipMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get worshipMethodEgypt => 'Autoridad General Egipcia de Topografía';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, La Meca';

  @override
  String get worshipMethodKarachi =>
      'Universidad de Ciencias Islámicas, Karachi';

  @override
  String get worshipMethodTehran =>
      'Instituto de Geofísica, Universidad de Teherán';

  @override
  String get worshipMethodGulf => 'Región del Golfo';

  @override
  String get worshipMethodKuwait => 'Kuwait';

  @override
  String get worshipMethodQatar => 'Catar';

  @override
  String get worshipMethodSingapore => 'Singapur (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turquía (Diyanet)';

  @override
  String get worshipMethodFrance => 'Francia (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marruecos (Ministerio de los Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesia (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malasia (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubái';

  @override
  String get worshipToday => 'Hoy';

  @override
  String get worshipNoTimes =>
      'Hoy no hay horarios de oración aquí: el sol no sale o no se pone.';

  @override
  String get worshipSilentTitle => 'Silencio en las horas de oración';

  @override
  String get worshipSilentBody =>
      'En cada hora de oración, el teléfono se queda en silencio («No molestar») durante los minutos de abajo y luego vuelve a como estaba. Por ejemplo, desde el Dhuhr a las 12:00 hasta las 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'En silencio durante: $minutes min';
  }

  @override
  String get worshipMuteTitle => 'Silenciar el multimedia con el adhan';

  @override
  String get worshipMuteBody =>
      'En cada hora de oración, el sonido multimedia (vídeos, música, juegos) se silencia durante los minutos de abajo. Desde la notificación puede reactivarlo al momento.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Silenciado durante: $minutes min';
  }

  @override
  String get worshipMinutesTitle => 'Duración';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get worshipNeedPlace => 'Primero elija un lugar.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Siguiente: $prayer a las $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'En silencio hasta las $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Multimedia silenciado hasta las $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Permita que Waaiya cambie «No molestar»; si no, el teléfono no puede ponerse en silencio.';

  @override
  String get worshipAllow => 'Permitir';

  @override
  String get worshipExactNeeded =>
      'Waaiya no tiene permiso para «Alarmas y recordatorios», así que cada cambio puede llegar hasta 10 minutos tarde, o más mientras el teléfono está en reposo.';

  @override
  String get worshipNotificationsNeeded =>
      'Las notificaciones están desactivadas: no verá cuándo el teléfono se pone en silencio ni cuándo vuelve a sonar.';

  @override
  String get worshipTonesTitle =>
      'Tono de llamada y sonido de notificación sencillos';

  @override
  String get worshipTonesBody =>
      'Waaiya no puede filtrar el tono de llamada ni los sonidos de notificación, solo cambiarlos. Elija un tono sencillo, sin música:';

  @override
  String worshipToneRing(Object number) {
    return 'Tono de llamada sencillo $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Sonido de notificación sencillo $number';
  }

  @override
  String get worshipTonePlay => 'Escuchar';

  @override
  String get worshipToneSet => 'Usar';

  @override
  String get worshipToneInUse => 'En uso';

  @override
  String get worshipToneDone => 'Listo.';

  @override
  String get worshipTonePermission =>
      'Permita que Waaiya modifique los ajustes del sistema, vuelva y toque de nuevo.';

  @override
  String get worshipToneFailed =>
      'Este teléfono no dejó que Waaiya lo cambiara. En los ajustes de Sonido, elija un tono llamado «Waaiya plain».';

  @override
  String get worshipOpenSound => 'Abrir los ajustes de Sonido';

  @override
  String get worshipSmsTitle =>
      'Responder a las llamadas por SMS durante la oración';

  @override
  String get worshipSmsBody =>
      'En los minutos de silencio tras cada hora de oración, una llamada que sigue sonando recibe un SMS. Una vez por número y por oración; nunca a números ocultos ni a números cortos.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Después de: $seconds s sonando';
  }

  @override
  String get worshipSmsDelayTitle => 'Segundos sonando antes del SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Mensaje: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Su mensaje';

  @override
  String get worshipSmsTextDefault => 'Usar el predeterminado';

  @override
  String get worshipSmsCost =>
      'Cada respuesta es un SMS normal desde su SIM, al precio de su tarifa. No se envía nada en itinerancia.';

  @override
  String get worshipSmsRoaming =>
      'En itinerancia ahora: no se envía ningún SMS.';

  @override
  String get worshipSmsLogTitle =>
      'Respuestas enviadas (guardadas solo en este teléfono)';

  @override
  String get worshipContinue => 'Continuar';

  @override
  String get worshipWhyDnd =>
      'Para poner el teléfono en silencio en las horas de oración, permita el acceso de Waaiya a «No molestar» en la página siguiente.';

  @override
  String get worshipWhyExact =>
      'Para actuar a la hora exacta, permita que Waaiya programe alarmas y recordatorios en la página siguiente. Sin esto, los cambios pueden llegar hasta 10 minutos tarde.';

  @override
  String get worshipWhyNotifications =>
      'Permita las notificaciones para ver cada cambio y poder deshacerlo.';

  @override
  String get worshipWhyWrite =>
      'Para cambiar su tono de llamada o su sonido de notificación, permita que Waaiya modifique los ajustes del sistema en la página siguiente.';

  @override
  String get worshipWhyPhone =>
      'Para saber que suena una llamada y de qué número es, Waaiya necesita los permisos Teléfono y Registros de llamadas. Nada sale del teléfono salvo su respuesta.';

  @override
  String get worshipWhySms =>
      'Para enviar su respuesta, Waaiya necesita permiso para enviar SMS. Solo envía esa respuesta, como mucho una vez por número y por oración.';

  @override
  String get worshipMissingDnd =>
      'No se permitió el acceso a «No molestar», así que el silencio sigue desactivado.';

  @override
  String get worshipMissingPhone =>
      'No se concedieron los permisos Teléfono y Registros de llamadas, así que la respuesta por SMS sigue desactivada.';

  @override
  String get worshipMissingSms =>
      'No se concedió el permiso para enviar SMS, así que la respuesta por SMS sigue desactivada.';

  @override
  String get worshipTryAgain => 'Volver a intentarlo';

  @override
  String get protectTitle => 'Protección para los momentos de debilidad';

  @override
  String get protectBody =>
      'Para un momento de debilidad en el que quizá quiera apagar el filtro. Elija ahora, con calma, un tiempo de espera: entonces el botón de detener no detiene el filtro al instante, y usted vuelve a decidir cuando termina la espera. Un padre o una madre también puede poner un PIN.';

  @override
  String protectDelay(Object value) {
    return 'Espera antes de apagar: $value';
  }

  @override
  String get protectDelayTitle => 'Espera antes de apagar';

  @override
  String get protectDelayBody =>
      'Por ejemplo, con 30 minutos: pulsa el botón para detener, pero el filtro sigue funcionando. Pasados 30 minutos, esta página le pregunta si todavía quiere detenerlo. Pulse «Confirmar» en los 15 minutos siguientes y se detiene; si no, no cambia nada. Lo mismo vale para desactivar una cubierta o cualquier otra protección. Activar algo siempre funciona al momento.';

  @override
  String get protectDelayOff => 'Ninguno';

  @override
  String get protectDelay1m => '1 minuto';

  @override
  String get protectDelay5m => '5 minutos';

  @override
  String get protectDelay15m => '15 minutos';

  @override
  String get protectDelay30m => '30 minutos';

  @override
  String get protectDelay1h => '1 hora';

  @override
  String get protectDelay4h => '4 horas';

  @override
  String get protectDelay24h => '24 horas';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes minutos';
  }

  @override
  String get protectPinNone => 'PIN: sin poner';

  @override
  String get protectPinIsSet => 'PIN: puesto';

  @override
  String get protectPinSet => 'Poner un PIN';

  @override
  String get protectPinRemove => 'Quitar';

  @override
  String get protectPinBody =>
      'Con un PIN, detener el filtro o desactivar cualquier protección pide primero el PIN. Por ejemplo, un padre o una madre pone uno para que un niño no pueda apagar el filtro. Cambiar el periodo de espera o el PIN también lo pide.';

  @override
  String get protectPinForgot =>
      'Anote el PIN en un lugar seguro: si se olvida, no hay forma de restablecerlo. La única salida es borrar los datos de Waaiya o reinstalar Waaiya, lo que también borra todos sus ajustes.';

  @override
  String get protectPinTitle => 'Escriba el PIN';

  @override
  String get protectPinNewTitle => 'Elija un PIN';

  @override
  String get protectPinChangeTitle => 'Cambiar el PIN';

  @override
  String get protectPinCurrent => 'PIN actual';

  @override
  String get protectPinNew => 'PIN nuevo (de 4 a 8 cifras)';

  @override
  String get protectPinAgain => 'Repita el PIN nuevo';

  @override
  String get protectPinBad => 'Use de 4 a 8 cifras.';

  @override
  String get protectPinDiffer => 'Los dos PIN nuevos no coinciden.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN incorrecto. Quedan $count intentos antes de una pausa.';
  }

  @override
  String protectLocked(Object time) {
    return 'Demasiados intentos fallidos. Vuelva a intentarlo a partir de $time.';
  }

  @override
  String get protectOk => 'Aceptar';

  @override
  String get protectCancel => 'Cancelar';

  @override
  String get protectCancelChange => 'Cancelar el cambio';

  @override
  String get protectConfirm => 'Confirmar';

  @override
  String protectPending(Object time, Object what) {
    return '$what: esperando hasta las $time. Después confírmelo en «Ajustes».';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: la espera ha terminado. ¿Todavía lo quiere? Pulse «Confirmar» antes de las $time; si no, no cambia nada.';
  }

  @override
  String get protectWaitTitle => 'Este cambio espera';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what no ocurre ahora. A las $time, si todavía lo quiere, confírmelo en «Ajustes» en los 15 minutos siguientes. Si no hace nada, no cambia nada.';
  }

  @override
  String get protectWaitStart => 'Empezar la espera';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Ya está esperando hasta las $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Esperando hasta las $time. Después confírmelo en «Ajustes».';
  }

  @override
  String protectTomorrow(Object time) {
    return 'mañana a las $time';
  }

  @override
  String get protectHeldBack =>
      'Ahora no: sus ajustes de protección hacen esperar este cambio o piden el PIN.';

  @override
  String get protectLimits =>
      'Lo que esto no puede impedir: forzar la detención, desinstalar, borrar los datos de Waaiya y los propios ajustes de Android. Bloquear eso necesitaría permisos especiales de Android que Waaiya no usa. Esto protege de un momento de debilidad, no de una persona decidida.';

  @override
  String get protectLimitsDesktop =>
      'Lo que esto no puede impedir: el comando waaiya en una terminal, quitar Waaiya o borrar su carpeta de ajustes. Esto protege de un momento de debilidad, no de una persona decidida.';

  @override
  String get protectLimitsWindows =>
      'Lo que esto no puede impedir: el comando waaiya-filter.exe en una terminal, quitar Waaiya o borrar su carpeta de ajustes. Esto protege de un momento de debilidad, no de una persona decidida.';

  @override
  String get protectWhatStop => 'Detener el filtrado';

  @override
  String protectWhatOff(Object name) {
    return 'Desactivar: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Activar: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Añadir una aplicación a: $name';
  }

  @override
  String get protectWhatStrictness => 'Hacer el desenfoque menos estricto';

  @override
  String get protectWhatGender => 'Cambiar quién usa Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'Cambiar la espera antes de apagar a: $value';
  }

  @override
  String get protectWhatPinChange => 'Cambiar el PIN';

  @override
  String get protectWhatPinClear => 'Quitar el PIN';

  @override
  String get protectWhatSetting => 'Cambiar un ajuste';

  @override
  String get onboardBodyDesktop =>
      'Waaiya quita los instrumentos musicales del sonido de todas las aplicaciones de este ordenador. Se conservan el habla y la recitación del Corán. Por ahora, también se quitan las voces que cantan.';

  @override
  String get worshipUseLocation => 'Usar mi ubicación';

  @override
  String get worshipWhyLocation =>
      'Para conocer los horarios de oración donde está, Waaiya lee una sola vez, ahora, la ubicación aproximada de este teléfono. Se guarda en el teléfono como su lugar y no se envía a ninguna parte.';

  @override
  String get worshipLocating => 'Buscando dónde está…';

  @override
  String get worshipLocationDenied =>
      'No se permitió la ubicación. Puede buscar su ciudad en su lugar.';

  @override
  String get worshipLocationOff =>
      'La ubicación está desactivada en este teléfono. Actívela e inténtelo de nuevo, o busque su ciudad.';

  @override
  String get worshipLocationSettings => 'Ajustes de ubicación';

  @override
  String get worshipLocationFailed =>
      'No se pudo encontrar su ubicación. Inténtelo de nuevo en un momento, o busque su ciudad.';

  @override
  String worshipPlaceNear(Object city) {
    return 'cerca de $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Los horarios oficiales del Ministerio de Habices y Asuntos Islámicos para $city.';
  }

  @override
  String get trayOpen => 'Abrir Waaiya';

  @override
  String get trayQuit => 'Salir';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows no deja que Waaiya se inicie al iniciar sesión. Activa Waaiya en Configuración › Aplicaciones › Inicio y vuelve a activar esta opción.';

  @override
  String get engineErrorAutostartPolicy =>
      'La configuración de este equipo, elegida por su administrador, no permite que Waaiya se inicie al iniciar sesión.';

  @override
  String get notifTextTitle =>
      'Mostrar el texto de las notificaciones al filtrar';

  @override
  String get notifTextBody =>
      'Android oculta el contenido de las notificaciones mientras una app graba toda la pantalla, y filtrar cuenta como eso. Activado: Waaiya quita esta protección solo mientras filtra, para que puedas leer tus notificaciones. Otras pantallas compartidas al mismo tiempo tampoco quedan protegidas.';

  @override
  String get notifTextNextStart =>
      'Detén el filtrado y vuelve a iniciarlo para aplicar este cambio.';

  @override
  String get notifTextRefused =>
      'Este teléfono rechazó el cambio. Activa tú mismo «Desactivar protecciones al compartir pantalla» en las opciones para desarrolladores.';

  @override
  String get notifTextByHand =>
      'Visible: la protección de Android está desactivada en las opciones para desarrolladores («Desactivar protecciones al compartir pantalla»). Sigue desactivada para cualquier pantalla compartida hasta que la vuelvas a activar allí.';

  @override
  String get notifTextHowTo =>
      'Android oculta el contenido de las notificaciones mientras Waaiya filtra. Tras la configuración única, Waaiya las muestra: quita esta protección solo mientras filtra.';

  @override
  String get notifTextOpenDev => 'Abrir opciones para desarrolladores';

  @override
  String get notifTextLockNote =>
      'En este teléfono Android también detiene el filtrado al bloquear la pantalla, y las demás apps quedan en silencio hasta que toques Reanudar. La configuración también lo evita.';

  @override
  String get notifTextHandOptional =>
      'Opcional, sin configuración: activa «Desactivar protecciones al compartir pantalla» en las opciones para desarrolladores. Quedará desactivada para cualquier pantalla compartida, y algunos teléfonos no la tienen.';

  @override
  String get notifTextForced =>
      'Activado: en este teléfono Android pregunta antes de cada inicio y detendría el filtrado en cada bloqueo de pantalla. Waaiya quita esta protección mientras filtra, lo que también muestra el texto de las notificaciones. Otras pantallas compartidas al mismo tiempo tampoco quedan protegidas.';

  @override
  String get oneAppTitle => 'Al iniciar: «Compartir una app» y luego Waaiya';

  @override
  String get oneAppBody =>
      'Cuando Android pregunte qué compartir, elige «Compartir una app» y luego Waaiya. Todas las apps siguen filtradas, las notificaciones se pueden leer y el filtrado sigue al bloquear la pantalla. Con la pantalla completa, Android oculta el texto de las notificaciones y detiene el filtrado en cada bloqueo.';

  @override
  String get oneAppPair =>
      'Para que Waaiya funcione por completo, emparéjalo una vez con la depuración inalámbrica en la página Configuración: así también se silencia la música original y Android deja de preguntar en cada inicio.';

  @override
  String get notifTextOneApp =>
      'Visible cuando eliges «Compartir una app» y luego Waaiya al iniciar. Con la pantalla completa Android lo oculta; tras la configuración única, Waaiya quita eso mientras filtra.';

  @override
  String get blurNeedsRestart =>
      'Detén el filtrado y vuelve a iniciarlo para usar el difuminado: necesita la pantalla completa, y este filtrado empezó ofreciendo «Compartir una app».';
}
