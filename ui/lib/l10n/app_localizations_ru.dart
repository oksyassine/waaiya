// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Убирает музыкальные инструменты во всех приложениях и оставляет речь и чтение Корана.';

  @override
  String get onboardTitle => 'Добро пожаловать';

  @override
  String get onboardBody =>
      'Waaiya убирает музыкальные инструменты из звука всех приложений на этом телефоне. Речь и чтение Корана сохраняются. Пока что пение тоже убирается.';

  @override
  String get onboardQuestion => 'Я';

  @override
  String get genderMan => 'Мужчина';

  @override
  String get genderWoman => 'Женщина';

  @override
  String get onboardWhy =>
      'От этого зависит только то, какие дополнительные настройки вы увидите. Например, «Отключать женское пение» предлагается только мужчинам. Это можно изменить позже.';

  @override
  String get stateOnTitle => 'Фильтр включён';

  @override
  String get stateOffTitle => 'Фильтр выключен';

  @override
  String get stateStarting => 'Запуск…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Инструменты убраны во всех приложениях. Звук идёт с опозданием примерно на $delayMs мс (1000 мс — это одна секунда).';
  }

  @override
  String get stateOffDetail => 'Нажмите кнопку, чтобы включить.';

  @override
  String get stateModelFailed =>
      'Не удалось загрузить звуковую модель, поэтому звук отключён для надёжности.';

  @override
  String get stateCaptureDenied =>
      'Нужно разрешение на микрофон, чтобы получать звук других приложений.';

  @override
  String get stateStoppedBySystem =>
      'Android остановил фильтр. Нажмите кнопку, чтобы включить его снова.';

  @override
  String get stateSilencedTitle => 'Фильтр остановлен';

  @override
  String get stateSilenced =>
      'Фильтр остановлен: звук других приложений отключён. Нажмите кнопку, чтобы включить фильтр снова, или «Стоп», чтобы слышать их без фильтра.';

  @override
  String get releaseSilence => 'Стоп: слушать приложения без фильтра';

  @override
  String get powerStartCd => 'Включить фильтр';

  @override
  String get powerStopCd => 'Выключить фильтр';

  @override
  String get captureHint =>
      'Android спросит разрешение на трансляцию экрана. Используется только звук: ничего не записывается и не отправляется.';

  @override
  String get needRecordAudio =>
      'Waaiya нужно разрешение на микрофон, чтобы получать звук других приложений. Ваш голос никогда не записывается.';

  @override
  String get micOpenSettings => 'Открыть настройки Waaiya и разрешить микрофон';

  @override
  String get keepRunningTitle => 'Не давайте закрывать Waaiya';

  @override
  String get keepRunningBattery =>
      'Телефон может через какое-то время закрыть Waaiya ради экономии батареи, и фильтрация остановится. В настройках Waaiya в разделе «Батарея» выберите «Без ограничений». На Xiaomi, Redmi и POCO: «Нет ограничений», и включите также Автозапуск.';

  @override
  String get keepRunningNotifications =>
      'Уведомления Waaiya выключены, поэтому он не сможет сообщить, когда фильтрация остановится. Включите их в настройках Waaiya.';

  @override
  String get keepRunningOpen => 'Открыть настройки Waaiya';

  @override
  String get lockAskTitle => 'Продолжать фильтрацию при блокировке экрана?';

  @override
  String get lockTitle => 'Продолжать фильтрацию при блокировке экрана';

  @override
  String get lockBody =>
      'На этом телефоне Android спрашивает перед каждым запуском, а затем останавливает фильтрацию при каждой блокировке экрана. Waaiya может этого избежать, снимая защиту демонстрации экрана Android на время фильтрации, и возвращает её, когда фильтрация останавливается. Пока защита снята, другая демонстрация экрана в это же время (например, видеозвонок) тоже может показать ваши уведомления. Изменение действует со следующего запуска.';

  @override
  String get lockYes => 'Продолжать фильтрацию';

  @override
  String get lockNo => 'Останавливать при блокировке';

  @override
  String get setupBannerTitle => 'Ещё один шаг';

  @override
  String get setupBannerBody =>
      'Без однократной настройки ниже вы будете слышать музыку и отфильтрованный звук одновременно.';

  @override
  String get step1Title => 'Установите Shizuku';

  @override
  String get step1Body =>
      'Бесплатное вспомогательное приложение из Google Play.';

  @override
  String get step1Action => 'Скачать Shizuku';

  @override
  String get step2Title => 'Запустите Shizuku';

  @override
  String get step2Body =>
      'Shizuku запускается через Wi-Fi с помощью отладки по Wi-Fi в Android. Нажмите кнопку, чтобы увидеть шаги, затем вернитесь сюда.';

  @override
  String get step2Action => 'Открыть Shizuku';

  @override
  String get step2Update => 'Обновить Shizuku';

  @override
  String get step2TooOld =>
      'Ваша версия Shizuku слишком старая. Обновите её в Google Play.';

  @override
  String get step2Denied =>
      'В Shizuku для Waaiya выбрано «всегда запрещать». Разрешите Waaiya в списке приложений в Shizuku.';

  @override
  String get step3Title => 'Дайте разрешение';

  @override
  String get step3Body => 'Одно нажатие, затем выберите «Разрешить».';

  @override
  String get step3Action => 'Дать разрешение';

  @override
  String get step3Busy => 'Настройка…';

  @override
  String get setupDoneRestart =>
      'Готово. Выключите и снова включите фильтр, чтобы это заработало.';

  @override
  String setupFailed(String details) {
    return 'Настройка не завершилась. Подробности:\n$details';
  }

  @override
  String get shizukuRefused =>
      'В разрешении Shizuku отказано. Нажмите кнопку, чтобы попробовать ещё раз.';

  @override
  String get setupSlow =>
      'Shizuku отвечает дольше обычного. Подождите ещё: на некоторых телефонах его помощнику нужно до минуты, чтобы запуститься в первый раз.';

  @override
  String get setupTimeout =>
      'Shizuku не ответил за 2 минуты. Откройте Shizuku, проверьте, что там написано, что он запущен, и снова нажмите кнопку. Если настройка завершится позже, этот экран обновится сам.';

  @override
  String get setupRefusedXiaomi =>
      'Телефон отклонил разрешения. На Xiaomi, Redmi и POCO включите «Отладка по USB (Настройки безопасности)» в разделе «Для разработчиков» (потребуется войти в аккаунт Xiaomi), затем попробуйте ещё раз.';

  @override
  String get setupRefusedColoros =>
      'Телефон отклонил разрешения. На OPPO, OnePlus и realme в разделе «Для разработчиков» включите «Отключить мониторинг разрешений» (в новых версиях он называется «Отключить оптимизацию системы» и может появляться, только если на телефоне выбран английский язык: «Disable permission monitoring» или «Disable system optimization»). Чтобы найти его, введите «разрешени» в поиске Настроек (или «permission» на английском). Затем попробуйте ещё раз.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi и POCO: если в уведомлении нет поля для ввода кода, выберите стиль уведомлений «Android» в настройках уведомлений или введите код в Waaiya в режиме разделённого экрана.';

  @override
  String get stepDoneCd => 'Готово';

  @override
  String stepTodoCd(int step) {
    return 'Шаг $step';
  }

  @override
  String get computerToggle => 'Использовать компьютер';

  @override
  String get computerWeb =>
      'Проще всего: на компьютере откройте waaiya.mssid.org/usb в Chrome или Edge, включите отладку по USB и подключите телефон кабелем. Ничего устанавливать не нужно, работает и на Android 10. Или, если установлен adb:';

  @override
  String get computerBody =>
      'Включите отладку по USB, подключите телефон и выполните:';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get computerNote =>
      'Вторая строка необязательна: она убирает вопрос о трансляции экрана при каждом запуске.';

  @override
  String get settingsTitle => 'Параметры';

  @override
  String get settingSilenceTitle =>
      'Отключать звук приложений, которые не дают фильтровать';

  @override
  String get settingSilenceBody =>
      'Рекомендуется. Некоторые приложения не позволяют фильтровать свой звук; эта настройка отключает их звук, чтобы музыка не проходила.';

  @override
  String get settingHoldSilenceTitle =>
      'Не возвращать звук приложений, если фильтр остановился сам';

  @override
  String get settingHoldSilenceBody =>
      'Рекомендуется. Если фильтр остановит Android (а не вы), другие приложения останутся без звука, пока вы снова не включите фильтр или не нажмёте «Стоп», а не будут играть музыку без фильтра. Нужна однократная настройка.';

  @override
  String get settingStereoTitle => 'Стереозвук';

  @override
  String get settingStereoBody =>
      'Выкл.: моно, расходует примерно вдвое меньше заряда и успевает на большем числе телефонов. Вкл.: левый и правый каналы звучат раздельно. Если телефон слишком медленный для стерео, он всё равно сам переключится на моно.';

  @override
  String get settingSingingTitle => 'Отключать женское пение';

  @override
  String get settingSingingBody =>
      'Например, песня, которую поёт женщина, отключается, но женщину, которая читает лекцию, по-прежнему слышно.';

  @override
  String get settingSingingNoModel =>
      'В этой версии нет распознавания пения, поэтому, пока это включено, отключаются все голоса.';

  @override
  String get settingRestart =>
      'Выключите и снова включите фильтр, чтобы применить изменения.';

  @override
  String get settingGenderTitle => 'Я';

  @override
  String get change => 'Изменить';

  @override
  String get playerTitle => 'Видео с идеальной синхронизацией';

  @override
  String get playerBody =>
      'Поделитесь видео с Waaiya (или выберите «Открыть с помощью»), чтобы смотреть его с фильтром без задержки.';

  @override
  String get licences => 'Лицензии открытого ПО';

  @override
  String get licencesIntro =>
      'Waaiya — свободное ПО под лицензией GNU Affero General Public License версии 3 или более поздней. Исходный код: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (данные для обучения): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Полные тексты';

  @override
  String get back => 'Назад';

  @override
  String get linkEntryTitle => 'Открыть ссылку';

  @override
  String get linkEntryBody =>
      'Вставьте ссылку на YouTube, TikTok или Instagram, чтобы посмотреть или сохранить видео без музыки.';

  @override
  String get linkTitle => 'Открыть ссылку';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Ссылка на видео или аудио';

  @override
  String get linkPaste => 'Вставить';

  @override
  String get linkOpen => 'Открыть';

  @override
  String get linkResolving => 'Открываем ссылку…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Смотреть без музыки';

  @override
  String get linkSave => 'Сохранить без музыки';

  @override
  String get linkListen => 'Слушать без музыки';

  @override
  String get linkAudioOnly =>
      'Видео по этой ссылке пока нельзя открыть: доступен только звук.';

  @override
  String get linkDownloading => 'Загрузка…';

  @override
  String get linkFiltering => 'Убираем музыку…';

  @override
  String get linkCancel => 'Отмена';

  @override
  String get linkCancelled => 'Отменено. Ничего не сохранено.';

  @override
  String get linkTimedOut =>
      'Android остановил сохранение: такая работа разрешена только несколько часов в день. Ничего не сохранено; откройте Waaiya и попробуйте ещё раз.';

  @override
  String get linkExportFailed => 'Не удалось сохранить. Ничего не сохранено.';

  @override
  String get linkSaved => 'Сохранено без музыки';

  @override
  String get linkSavedVideo => 'В галерее: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'В музыке: Music › Waaiya';

  @override
  String get linkPlay => 'Воспроизвести';

  @override
  String get linkShare => 'Поделиться';

  @override
  String get linkShareNote =>
      'Делитесь только теми видео, которыми вам разрешено делиться.';

  @override
  String get linkLive => 'Прямые трансляции сохранить нельзя.';

  @override
  String get linkBusy =>
      'Сейчас сохраняется другое видео. Дождитесь, пока оно сохранится.';

  @override
  String get linkInvalid => 'Вставьте веб-ссылку (она начинается с https://).';

  @override
  String get linkLogin =>
      'Сайт не показал это видео без аккаунта. Общедоступные публикации обычно открываются: попробуйте ещё раз через несколько минут. Закрытые публикации открыть нельзя.';

  @override
  String get linkUnsupported => 'Этот сайт не поддерживается.';

  @override
  String get linkPlaylist => 'Это плейлист. Откройте одно видео.';

  @override
  String get linkNoFormat =>
      'Это видео в формате, который Waaiya пока не умеет фильтровать.';

  @override
  String get linkFailed =>
      'Не удалось открыть ссылку. Проверьте подключение к интернету и попробуйте ещё раз.';

  @override
  String get linkPlayFailed =>
      'Не удалось воспроизвести. Ничего не было воспроизведено без фильтра.';

  @override
  String get linkLimited =>
      'Сайт сейчас ограничивает запросы. Попробуйте ещё раз через несколько минут.';

  @override
  String get blurTitle => 'Размытие экрана';

  @override
  String get blurBody =>
      'Закрывает людей и изображения на экране во всех приложениях, пока включён фильтр. Работает на самом телефоне; ничего никуда не отправляется.';

  @override
  String get blurOnTitle => 'Размытие включено';

  @override
  String get blurOffTitle => 'Размытие выключено';

  @override
  String get blurStartCd => 'Включить размытие';

  @override
  String get blurStopCd => 'Выключить размытие';

  @override
  String get blurOffDetail =>
      'Нажмите кнопку, чтобы начать. Фильтрация включится вместе с ним.';

  @override
  String get blurWhatTitle => 'Что размывать';

  @override
  String get blurWomenTitle => 'Размывать женщин';

  @override
  String get blurWomenBody =>
      'Закрывает всё тело. Если приложение не уверено, что человек — мужчина, оно закрывает и его.';

  @override
  String get blurNudityTitle => 'Размывать нескромные изображения';

  @override
  String get blurNudityBody =>
      'Нагота или откровенная одежда, у кого угодно: закрывается весь экран.';

  @override
  String get blurFailTitle => 'Закрывать экран, если размытие не успевает';

  @override
  String get blurFailBody =>
      'Вкл.: весь экран закрывается, когда телефон слишком медленный или размытие не работает. Выкл.: экран остаётся видимым, с предупреждением.';

  @override
  String get blurSetupManual => 'Разрешить в настройках Android';

  @override
  String get blurStatusNeedsSetup =>
      'Чтобы размывать, Waaiya нужно показываться поверх других приложений. Лучше всего: «Перейти к настройке», тогда ваши нажатия по-прежнему доходят до приложения под размытием. Или «Разрешить в настройках Android», но тогда нажатие на размытую область ничего не делает.';

  @override
  String get blurStatusNeedsOverlay =>
      'Чтобы размывать, Waaiya нужно показываться поверх других приложений. Лучше всего: пройдите разовую настройку, тогда ваши нажатия по-прежнему доходят до приложения под размытием. Или разрешите «Поверх других приложений» в настройках Android, но тогда нажатие на размытую область ничего не делает.';

  @override
  String get blurFailUnavailable =>
      'Пока недоступно: заслонка на весь экран блокировала бы все нажатия, и вы могли бы застрять. Запустите помощника Waaiya (Android 12 или новее), и эта настройка станет доступна: тогда заслонки рисуются так, что нажатия проходят сквозь них. А до тех пор, если размытие не успевает, экран остаётся видимым, с предупреждением.';

  @override
  String get blurFailNeedsA11y =>
      'Пока недоступно: заслонка на весь экран блокировала бы все нажатия, и вы могли бы застрять. Запустите помощника Waaiya (Android 12 или новее) или включите в настройках Android службу специальных возможностей «Размытие Waaiya», и эта настройка станет доступна. А до тех пор экран остаётся видимым, с предупреждением.';

  @override
  String get languageTitle => 'Язык';

  @override
  String settingLanguageTitle(String language) {
    return 'Язык: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Выключите и снова включите фильтр, чтобы применить настройки размытия.';

  @override
  String get blurStatusStarting => 'Размытие запускается…';

  @override
  String get blurStatusOn => 'Размытие включено.';

  @override
  String get blurStatusOnVisible =>
      'Размытие включено, в осторожном режиме: этот телефон показывает размытие в собственной записи экрана, поэтому размытая область остаётся размытой, пока не сменится картинка.';

  @override
  String get blurStatusModels =>
      'В этой версии нет модели размытия для выбранного варианта.';

  @override
  String get blurStatusFailing => 'Размытие сейчас не успевает.';

  @override
  String get blurStatusNoOverlay =>
      'Размытие не может показываться поверх других приложений: разрешите это выше.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Размытие не видит экран. Подробности:\n$details';
  }

  @override
  String get step2Guide => 'Как запустить Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Недоступно: на этой версии Android заслонка на весь экран блокировала бы все нажатия, и вы могли бы застрять (заслонкам, сквозь которые проходят нажатия, нужен Android 12 или новее). Если размытие не успевает, экран остаётся видимым, с предупреждением.';

  @override
  String get guideTitle => 'Запуск Shizuku по шагам';

  @override
  String get guideOpenDev => 'Для разработчиков';

  @override
  String get guideOpenShizuku => 'Открыть Shizuku';

  @override
  String get guideClose => 'Закрыть';

  @override
  String get guideBody =>
      'Нужны Wi-Fi и Android 11 или новее. Сопряжение делается один раз; после перезагрузки телефона нужно повторить только шаг 7.\n\n1. Подключите телефон к Wi-Fi.\n\n2. Включите режим разработчика: Настройки › Сведения о телефоне › Сведения о ПО › нажмите «Номер сборки» 7 раз. (На других телефонах: Настройки › О телефоне › Номер сборки.)\n\n3. Откройте Shizuku. Если он попросит разрешение на уведомления, разрешите: код подключения вводится в уведомлении Shizuku.\n\n4. В Shizuku в разделе «Запуск через отладку по Wi-Fi» нажмите «Сопряжение». На открывшейся странице нажмите «Для разработчиков», включите «Отладка по Wi-Fi» и подтвердите «Разрешить».\n\n5. Нажмите на слова «Отладка по Wi-Fi» (не на переключатель), затем «Подключить устройство с помощью кода подключения». Появится 6-значный код.\n\n6. Не закрывайте этот экран и потяните вниз шторку уведомлений. Когда в уведомлении Shizuku появится «Найдена служба сопряжения», нажмите «Ввести код сопряжения» и введите код. Shizuku сообщит, что сопряжение выполнено.\n\n7. Вернитесь в Shizuku и нажмите «Запустить» в разделе «Запуск через отладку по Wi-Fi». Подождите, пока не появится «Shizuku запущен».\n\n8. Вернитесь в Waaiya и нажмите «Дать разрешение», затем «Разрешить».\n\nПосле перезагрузки телефона Shizuku останавливается: подключитесь к Wi-Fi, снова включите «Отладка по Wi-Fi», если она выключена, откройте Shizuku и нажмите «Запустить». Новое сопряжение не нужно.';

  @override
  String get wsetupRouteTitle => 'Настроить на этом телефоне';

  @override
  String get wsetupRouteBody =>
      'Четыре коротких шага, один раз. Без других приложений и без компьютера. Waaiya отмечает каждый шаг, когда он выполнен.';

  @override
  String get wizDevTitle => 'Включите режим разработчика';

  @override
  String get wizDevBody =>
      'В разделе «О телефоне» нажмите «Номер сборки» 7 раз, затем вернитесь сюда. Если не можете его найти, введите «Номер сборки» в поиске Настроек.';

  @override
  String get wizDevBodySamsung =>
      'В разделе «Сведения о телефоне» › «Сведения о ПО» нажмите «Номер сборки» 7 раз, затем вернитесь сюда.';

  @override
  String get wizDevBodyXiaomi =>
      'В разделе «О телефоне» нажмите «Версия ОС» 7 раз (на старых телефонах — «Версия MIUI»; на некоторых она находится в разделе «Все параметры»), затем вернитесь сюда.';

  @override
  String get wizDevBodyColoros =>
      'В разделе «Об устройстве» (или «О телефоне») › «Версия» нажмите «Номер сборки» 7 раз, затем вернитесь сюда.';

  @override
  String get wizDevBodyVivo =>
      'В разделе «О телефоне» нажмите «Версия ПО» 7 раз (на некоторых телефонах: «Сведения о ПО» › «Номер сборки»), затем вернитесь сюда.';

  @override
  String get wizDevBodyHuawei =>
      'В разделе «О телефоне» нажмите «Номер сборки» 7 раз, затем вернитесь сюда.';

  @override
  String get wizDevBodyTranssion =>
      'В разделе «Мой телефон» (или «О телефоне») нажмите «Номер сборки» 7 раз, затем вернитесь сюда.';

  @override
  String get setupNoteHuawei =>
      'Huawei: на многих телефонах Huawei нет «Отладки по Wi-Fi». Если вы не нашли её в разделе «Для разработчиков», используйте компьютер («Другие способы» ниже).';

  @override
  String get wsetupFilterOn =>
      'Фильтр включён: на этой версии Android, пока он работает, код нельзя ввести в уведомлении. Сначала выключите фильтр или используйте разделённый экран и кнопку «Ввести код здесь».';

  @override
  String get wizDevSearch =>
      'Названия могут отличаться в зависимости от языка телефона: если не можете найти, воспользуйтесь поиском вверху Настроек.';

  @override
  String get wizDevAction => 'Открыть «О телефоне»';

  @override
  String get wizWifiTitle => 'Подключитесь к Wi-Fi';

  @override
  String get wizWifiBody => 'Подойдёт любая сеть Wi-Fi; интернет не нужен.';

  @override
  String get wizWifiAction => 'Открыть настройки Wi-Fi';

  @override
  String get wizWdTitle => 'Включите отладку по Wi-Fi';

  @override
  String get wizWdBody =>
      'Waaiya откроет раздел «Для разработчиков» на пункте «Отладка по Wi-Fi». Включите её и нажмите «Разрешить».';

  @override
  String get wizWdAction => 'Открыть «Для разработчиков»';

  @override
  String get wizPairTitle => 'Введите код подключения';

  @override
  String get wizPairBody =>
      'Нажмите на слова «Отладка по Wi-Fi», затем «Подключить устройство с помощью кода подключения». Введите 6 цифр в уведомлении Waaiya. Остальное Waaiya сделает само.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya уже сопряжено с этим телефоном: код не нужен. Нажмите кнопку, и Waaiya завершит всё само.';

  @override
  String get wizPairAction => 'Продолжить';

  @override
  String get wizAgain => 'Пройти настройку ещё раз';

  @override
  String get setupShizukuReadyTitle => 'Через Shizuku, который уже запущен';

  @override
  String get setupOtherWaysPlain => 'Другие способы настройки';

  @override
  String get wizSkip => 'Сразу к отладке по Wi-Fi';

  @override
  String get setupOtherWays => 'Другие способы: Shizuku или компьютер';

  @override
  String get wsetupEnterHere => 'Ввести код здесь';

  @override
  String get wsetupCancel => 'Отмена';

  @override
  String get wsetupAndroid10 =>
      'Android 10 не может выполнить настройку сам: нужен компьютер — напрямую (ниже) или чтобы один раз запустить Shizuku.';

  @override
  String get wsetupShizukuHeading => 'Или через приложение Shizuku';

  @override
  String get wsetupShizukuNote =>
      'Shizuku также позволяет нажатиям проходить сквозь заслонки на экране.';

  @override
  String get wsetupChannel => 'Однократная настройка';

  @override
  String get wsetupNotifTitle => 'Настройка Waaiya: ожидание кода подключения';

  @override
  String get wsetupFoundTitle => 'Экран сопряжения найден';

  @override
  String get wsetupBusyTitle => 'Настройка Waaiya';

  @override
  String get wsetupDoneTitle => 'Настройка завершена';

  @override
  String get wsetupDoneBody =>
      'Теперь Waaiya может отключать исходный звук. Отладку по Wi-Fi можно выключить.';

  @override
  String get wsetupDoneHelperBody =>
      'Готово. Этот телефон не позволяет приложениям сохранять эти разрешения, поэтому исходный звук отключает помощник Waaiya. Помощник останавливается при перезагрузке телефона и при обновлении Waaiya. Когда вы после этого откроете Waaiya, оно само снова запустит помощника, если отладка по Wi-Fi включена; если нет, покажет для этого кнопку.';

  @override
  String get helperMissingTitle => 'Помощник Waaiya остановлен';

  @override
  String get helperMissingBody =>
      'Этот телефон не сохраняет разрешения Waaiya, поэтому Waaiya использует помощника. Помощник останавливается при перезагрузке телефона и при обновлении Waaiya. Подключитесь к Wi-Fi, включите «Отладка по Wi-Fi» в разделе «Для разработчиков», затем нажмите «Запустить помощника Waaiya».';

  @override
  String get helperChannel => 'Помощник Waaiya';

  @override
  String get helperStarting => 'Запуск помощника…';

  @override
  String get helperModeNote =>
      'Этот телефон не позволяет приложениям сохранять эти разрешения: работу выполняет помощник Waaiya. Он останавливается при перезагрузке телефона и при обновлении Waaiya. Когда вы после этого откроете Waaiya, оно само снова запустит помощника, если отладка по Wi-Fi включена; если нет, покажет для этого кнопку.';

  @override
  String get helperTipXiaomi =>
      'Необязательно. Чтобы разрешения сохранялись навсегда (без помощника после перезагрузок): в разделе «Для разработчиков» включите «Отладка по USB (Настройки безопасности)» (потребуется войти в аккаунт Xiaomi), затем пройдите настройку ещё раз.';

  @override
  String get helperTipColoros =>
      'Необязательно. Чтобы разрешения сохранялись навсегда (без помощника после перезагрузок): в разделе «Для разработчиков» включите «Отключить мониторинг разрешений» (в новых версиях — «Отключить оптимизацию системы»; пункт может появляться, только если на телефоне выбран английский язык), затем пройдите настройку ещё раз.';

  @override
  String get stateOnHelperMissing =>
      'Исходный звук не отключён, поэтому вы слышите музыку вместе с отфильтрованным звуком: помощник Waaiya остановлен. Подключитесь к Wi-Fi, включите отладку по Wi-Fi, затем нажмите «Запустить помощника Waaiya».';

  @override
  String get setupRefusedTryWireless =>
      'Или выберите «Настроить на этом телефоне» на этой странице: тогда помощник Waaiya работает и без этого переключателя.';

  @override
  String get helperStartAnywayTitle => 'Помощник Waaiya остановлен';

  @override
  String get helperStartAnywayBody =>
      'Без него вы будете слышать музыку вместе с отфильтрованным звуком. Сначала запустите помощника (отладка по Wi-Fi должна быть включена) или всё равно включите фильтр.';

  @override
  String get wsetupFailedTitle => 'Настройка не завершилась';

  @override
  String get wsetupPairing => 'Сопряжение…';

  @override
  String get wsetupConnecting => 'Подключение и выдача разрешений…';

  @override
  String get wsetupNeedWifi =>
      'Сначала подключитесь к сети Wi-Fi (интернет не нужен): отладка по Wi-Fi работает только через Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'В разделе «Для разработчиков» включите «Отладка по Wi-Fi», затем нажмите на её название и на «Подключить устройство с помощью кода подключения».';

  @override
  String get wsetupOpenDialog =>
      'В разделе «Отладка по Wi-Fi» нажмите «Подключить устройство с помощью кода подключения». Оставьте код на экране и нажмите здесь «Ввести код».';

  @override
  String get wsetupEnterCodeBody =>
      'Нажмите «Ввести код» и введите 6-значный код, показанный в Настройках.';

  @override
  String get wsetupCodeWaiting =>
      'Код получен. Ожидание экрана «Подключить устройство с помощью кода подключения»: не закрывайте его.';

  @override
  String get wsetupWrongCode =>
      'Код не принят. Проверьте 6 цифр на экране и введите их снова. Если экран сопряжения закрылся, откройте его снова: код изменится.';

  @override
  String get wsetupPairingFailed =>
      'Сопряжение не удалось. Закройте экран сопряжения, снова откройте «Подключить устройство с помощью кода подключения» и введите новый код.';

  @override
  String get wsetupWaitingConnect =>
      'Сопряжение выполнено. Не выключайте «Отладку по Wi-Fi»: Waaiya подключается.';

  @override
  String get wsetupNotPaired =>
      'Этот телефон больше не знает Waaiya (сопряжение удалено или истекло). Откройте «Подключить устройство с помощью кода подключения» и введите код.';

  @override
  String get wsetupConnectFailed =>
      'Не удалось подключиться к отладке по Wi-Fi. Выключите и снова включите её: Waaiya само попробует ещё раз.';

  @override
  String get wsetupGrantFailed =>
      'Подключено, но разрешений всё ещё нет. Используйте Shizuku или компьютер (ниже).';

  @override
  String get wsetupTimeout =>
      'Остановлено через 10 минут: настройка не завершилась. Можно попробовать ещё раз.';

  @override
  String get wsetupCodeUnreadable => 'Введите 6 цифр кода подключения.';

  @override
  String get wsetupCodeHint => '6-значный код';

  @override
  String get wsetupEnterCode => 'Ввести код';

  @override
  String wsetupDetail(String details) {
    return 'Подробности: $details';
  }

  @override
  String get wsetupErrTimeout => 'нет ответа вовремя';

  @override
  String get wsetupErrRefused => 'в подключении отказано';

  @override
  String get wsetupDevOff =>
      'Режим разработчика выключен. В разделе «О телефоне» нажмите «Номер сборки» 7 раз, затем вернитесь.';

  @override
  String get wsetupOpenAbout => 'О телефоне';

  @override
  String get wsetupNotifOff =>
      'Уведомления Waaiya выключены, поэтому код нельзя ввести в уведомлении. Используйте разделённый экран (Настройки в одной половине, Waaiya в другой) и нажмите «Ввести код здесь».';

  @override
  String get wsetupCodeDialogTitle => 'Код подключения';

  @override
  String get wsetupCodeDialogBody =>
      'Только в режиме разделённого экрана (Настройки в одной половине, Waaiya в другой): если уйти из Настроек, экран сопряжения закроется и его код перестанет работать. Введите 6-значный код, показанный в разделе «Подключить устройство с помощью кода подключения».';

  @override
  String get wsetupCodeOk => 'Подключить';

  @override
  String get blurStrictTitle => 'Кто остаётся открытым';

  @override
  String blurStrictValue(String level) {
    return 'Кто остаётся открытым: $level';
  }

  @override
  String get blurStrict0 =>
      'Строго: только те, кого приложение почти наверняка считает мужчинами';

  @override
  String get blurStrict1 =>
      'Сбалансированно: открытыми остаются примерно вдвое больше мужчин';

  @override
  String get blurStrict2 =>
      'Мягко: ещё немного больше мужчин, чем при сбалансированном';

  @override
  String get blurStrict0Short => 'строго';

  @override
  String get blurStrict1Short => 'сбалансированно';

  @override
  String get blurStrict2Short => 'мягко';

  @override
  String get blurStrictHelp =>
      'Закрывается каждый, про кого приложение не уверено, что это мужчина. «Строго» оставляет открытыми около 7 мужчин из 100, «сбалансированно» — около 14, «мягко» — около 16. Каждый шаг в сторону меньшей строгости также оставляет открытыми примерно на 1 женщину из 100 больше.';

  @override
  String get stateOnNotMuted =>
      'Исходный звук ещё не отключён, поэтому вы слышите музыку вместе с отфильтрованным звуком. Завершите однократную настройку ниже.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya не может отключить исходный звук приложения, которое сейчас играет, поэтому музыка может быть слышна. Выключите и снова включите фильтр. Если не поможет, отправьте диагностический отчёт (Параметры).';

  @override
  String get stateTooSlow =>
      'Этот телефон слишком медленный, чтобы фильтровать звук на лету, поэтому звук прерывается. «Открыть ссылку» ниже всё равно работает: видео фильтруется до воспроизведения.';

  @override
  String get stateTooSlowNoLinks =>
      'Этот телефон слишком медленный, чтобы фильтровать звук на лету, поэтому звук прерывается.';

  @override
  String get stateMonoNote => 'Звук в моно, чтобы этот телефон успевал.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Без звука, так как фильтрация не разрешена: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Играет без фильтра, так как фильтрация не разрешена: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android не передал Waaiya звук других приложений. Нажмите кнопку, чтобы включить фильтр снова.';

  @override
  String get stateCaptureCancelled =>
      'Запуск отменён на вопросе Android о трансляции экрана. Чтобы получать звук, там нужно нажать «Начать». Ничего не записывается и не отправляется.';

  @override
  String get startNoSetupTitle => 'Музыка всё равно будет слышна';

  @override
  String get startNoSetupBody =>
      'Однократная настройка ещё не выполнена. Без неё Waaiya не может отключить исходный звук: вы будете слышать музыку и отфильтрованный звук вместе.\n\n«Открыть ссылку» работает без всякой настройки.';

  @override
  String get startNoSetupBodyNoLinks =>
      'Однократная настройка ещё не выполнена. Без неё Waaiya не может отключить исходный звук: вы будете слышать музыку и отфильтрованный звук вместе.';

  @override
  String get startNoSetupSetup => 'Пройти настройку';

  @override
  String get startNoSetupAnyway => 'Всё равно включить';

  @override
  String get diagButton => 'Проблема? Диагностический отчёт';

  @override
  String get diagTitle => 'Диагностический отчёт';

  @override
  String get diagNote =>
      'Что Waaiya видит на этом телефоне. Скопируйте или отправьте это тому, кто вам помогает. Само приложение ничего не отправляет.';

  @override
  String get notifStoppedTitle => 'Waaiya остановлено';

  @override
  String get notifStoppedText =>
      'Звук больше не фильтруется. Нажмите, чтобы включить снова.';

  @override
  String get wsetupGuide => 'Шаги с картинками';

  @override
  String get navFilter => 'Фильтр';

  @override
  String get navScreen => 'Экран';

  @override
  String get navLinks => 'Ссылки';

  @override
  String get navSetup => 'Настройка';

  @override
  String get navSettings => 'Параметры';

  @override
  String get setupDoneTitle => 'Настройка завершена';

  @override
  String get setupDoneBody =>
      'Waaiya может отключать исходный звук других приложений. Повторяйте настройку, только если что-то изменилось (настройка была сброшена или Waaiya сообщает, что её нет).';

  @override
  String get setupRedo => 'Показать настройку снова';

  @override
  String get setupGo => 'Перейти к настройке';

  @override
  String get helperTitle => 'Нажатия сквозь заслонки';

  @override
  String get helperBodyOff =>
      'Без помощника заслонка блокирует нажатия под ней. Помощник Waaiya рисует заслонки так, чтобы нажатия проходили сквозь них. Включите отладку по Wi-Fi (нужен Wi-Fi) и нажмите кнопку; в первый раз выполните сопряжение, как при настройке. После перезагрузки телефона нажмите кнопку снова.';

  @override
  String get helperStart => 'Запустить помощника Waaiya';

  @override
  String get helperOn =>
      'Помощник Waaiya рисует заслонки: нажатия проходят сквозь них. Он останавливается при перезагрузке телефона или при выключении отладки по USB; тогда снова нажмите кнопку.';

  @override
  String get helperShizukuOn =>
      'Shizuku рисует заслонки: нажатия проходят сквозь них.';

  @override
  String get helperOrShizuku => 'Или через Shizuku:';

  @override
  String get filterOptionsTitle => 'Параметры фильтра';

  @override
  String get settingsGeneralTitle => 'Общие';

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
  String get worshipPrayerFajr => 'Фаджр';

  @override
  String get worshipPrayerSunrise => 'Восход';

  @override
  String get worshipPrayerDhuhr => 'Зухр';

  @override
  String get worshipPrayerAsr => 'Аср';

  @override
  String get worshipPrayerMaghrib => 'Магриб';

  @override
  String get worshipPrayerIsha => 'Иша';

  @override
  String get worshipEndSilent => 'Выйти из беззвучного режима';

  @override
  String get worshipUnmute => 'Включить звук сейчас';

  @override
  String get worshipSmsDefault =>
      'Сейчас время намаза, я не могу ответить. Я вам перезвоню.';

  @override
  String get updateTitle => 'Обновления приложения';

  @override
  String get updateAuto => 'Проверять новую версию раз в день';

  @override
  String get updateAutoBody =>
      'Waaiya спрашивает у waaiya.mssid.org, есть ли более новая версия, и больше ничего не отправляет. Ничего не скачивается, пока вы не нажмёте «Обновить сейчас».';

  @override
  String get updateCheck => 'Проверить сейчас';

  @override
  String get updateChecking => 'Проверка…';

  @override
  String updateNone(String version) {
    return 'У вас последняя версия ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Доступна Waaiya $latest. У вас $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Загрузка: $size, только изменения (всё приложение — $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Загрузка: $size.';
  }

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String updateDownloading(String progress) {
    return 'Загрузка: $progress';
  }

  @override
  String get updatePreparing => 'Подготовка обновления…';

  @override
  String get updateInstalling =>
      'Подтвердите установку на экране, который покажет Android.';

  @override
  String get updateStopsFilter =>
      'Установка останавливает фильтрацию. Запустите её снова после обновления.';

  @override
  String get updatePermission =>
      'Разрешите Waaiya устанавливать свои обновления, затем снова нажмите «Обновить сейчас».';

  @override
  String get updateFailed =>
      'Не удалось завершить обновление. Попробуйте позже или скачайте его с сайта.';

  @override
  String get updateOpenPage => 'Открыть страницу загрузки';

  @override
  String get updateCheckFailed =>
      'Сейчас проверить не удалось. Попробуйте позже.';

  @override
  String get moveOldTitle => 'Waaiya переехала';

  @override
  String get moveOldBody =>
      'Теперь Waaiya выходит на Android как новое приложение (та же Waaiya под новым именем), а это больше не будет обновляться. Установите новое: ваши настройки перейдут в него. Затем выполните в нём одноразовую настройку и удалите это.';

  @override
  String get moveOldInstalled =>
      'Новая Waaiya установлена. Откройте её: она заберёт ваши настройки. Выполните одноразовую настройку, затем удалите эту старую, чтобы они никогда не фильтровали одновременно.';

  @override
  String get moveInstall => 'Установить новую Waaiya';

  @override
  String get moveOpenNew => 'Открыть новую Waaiya';

  @override
  String get moveRemoveThis => 'Удалить эту старую Waaiya';

  @override
  String get moveNewTitle => 'Старая Waaiya всё ещё установлена';

  @override
  String get moveNewBody =>
      'Старая Waaiya (до версии 0.2.15) всё ещё на этом телефоне. Удалите её, чтобы они никогда не фильтровали одновременно.';

  @override
  String get moveNewImported => 'Ваши настройки перенесены из неё.';

  @override
  String get moveRemoveOld => 'Удалить старую Waaiya';

  @override
  String get desktopPreview =>
      'Предварительный просмотр: движок фильтра на этом компьютере пока не подключён. Кнопка только показывает, как будет работать приложение.';

  @override
  String actionFailed(String details) {
    return 'Не получилось: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Инструменты убраны во всех приложениях.';

  @override
  String get engineErrorNoPactl =>
      'Не найдены звуковые инструменты (pactl). Waaiya нужен PulseAudio или PipeWire с pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'Звуковой сервер не запущен (PulseAudio или PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'В этой системе нет пользовательского сеанса systemd, который запускает фильтр в фоне.';

  @override
  String get engineErrorNoOutput => 'Не найдены динамики или наушники.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Не удалось установить фильтр. Подробности:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Фильтр не запустился. Подробности:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Фильтр остановился с ошибкой. Подробности:\n$details';
  }

  @override
  String get autostartTitle => 'Запускать при входе в систему';

  @override
  String get autostartBody => 'Фильтровать звук сразу после входа в систему.';

  @override
  String get blurBodyDesktop =>
      'Закрывает людей и изображения на экране поверх всех окон, пока Waaiya открыто (и с включённым, и с выключенным фильтром звука). Всё происходит на этом компьютере; ничего никуда не отправляется. Если закрыть окно Waaiya, размытие остановится.';

  @override
  String get blurFailBodyDesktop =>
      'Вкл.: весь экран закрывается, когда компьютер слишком медленный или размытие не работает; щелчки всё равно доходят до окон под ним. Выкл.: экран остаётся видимым, с красной полосой вверху.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Размытие включено. Этот рабочий стол показывает размытие в собственной записи экрана, поэтому размытая область остаётся размытой, пока не сменится картинка.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Размытие не может показываться поверх других окон на этом рабочем столе. Подробности:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Выберите свой экран в окне трансляции экрана и разрешите доступ. Waaiya спрашивает только один раз; изображение остаётся на этом компьютере.';

  @override
  String blurStatusExited(String details) {
    return 'Размытие неожиданно остановилось. Выключите и снова включите любой вариант размытия, чтобы попробовать ещё раз. Подробности:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Распознавание женского пения не загрузилось, поэтому, пока этот вариант включён, голоса отключаются.';

  @override
  String get blurStatusUncovered =>
      'Один из мониторов не закрыт размытием: к нему не дали доступ или его подключили позже. Выключите и снова включите любой вариант размытия и выберите все экраны в окне трансляции экрана.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'В этой установке нет моделей размытия, поэтому оно ничего не может закрыть; вверху экрана остаётся красная полоса. Переустановите Waaiya.';

  @override
  String get diagNoteDesktop =>
      'Что Waaiya видит на этом компьютере. Скопируйте это и передайте тому, кто вам помогает. Само приложение ничего не отправляет.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Рекомендуется. Если фильтр остановится сам (из-за ошибки, а не по вашей воле), другие приложения останутся без звука, пока вы снова не включите фильтр или не нажмёте «Стоп», а не будут играть музыку без фильтра.';

  @override
  String get settingStereoBodyDesktop =>
      'Выкл.: моно, меньше нагружает компьютер. Вкл.: левый и правый каналы звучат раздельно. Если компьютер слишком медленный для стерео, он сам переключится на моно.';

  @override
  String get linkEntryBodyDesktop =>
      'Вставьте ссылку на YouTube, TikTok или Instagram, чтобы посмотреть видео с включённым фильтром или сохранить его без музыки.';

  @override
  String get linkEntryBodyWatch =>
      'Вставьте ссылку на YouTube, TikTok или Instagram, чтобы посмотреть видео в браузере с включённым фильтром.';

  @override
  String get linkWatchNoteDesktop =>
      'Открывается в браузере. Waaiya сначала включает фильтр, поэтому музыка убирается и там.';

  @override
  String get linkFilterFailed =>
      'Фильтр не запустился, поэтому ссылка не открыта. Включите его на странице «Фильтр» и попробуйте ещё раз.';

  @override
  String get linkSavedVideoDesktop => 'В папке «Видео»: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'В папке «Музыка»: Waaiya';

  @override
  String get linkShowInFolder => 'Показать в папке';

  @override
  String get linkSingingNote =>
      'Женское пение тоже отключено, как задано в параметрах.';

  @override
  String get singingKeepTitle => 'Сохранять пение (тест)';

  @override
  String get singingKeepBody =>
      'Инструменты убираются, но поющие голоса сохраняются, поэтому в лекции с нашидом на фоне голос нашида тоже останется; допустимо ли это, решать вам.';

  @override
  String get singingKeepNoModel =>
      'В этой версии нет модели для пения, поэтому, пока это включено, звука нет. Выключите это.';

  @override
  String get fixFilterAppsTitle => 'Приложения без фильтра';

  @override
  String get fixFilterAppsBody =>
      'Приложения, которые вы здесь выберете, играют как есть: без фильтра, и их звук не отключается. Например, приложение для видеозвонков, чтобы в звонках не было задержки.';

  @override
  String get fixAddApp => 'Добавить приложение';

  @override
  String fixRemoveApp(Object app) {
    return 'Убрать $app';
  }

  @override
  String get fixNoApps => 'Приложения не выбраны.';

  @override
  String get fixPickTitle => 'Выберите приложение';

  @override
  String get fixPickEmpty => 'Других приложений не найдено.';

  @override
  String get fixPickPlayingDesktop =>
      'Приложения, которые сейчас воспроизводят звук, и уже выбранные.';

  @override
  String get fixCancel => 'Отмена';

  @override
  String get fixBlurAppsTitle => 'Приложения без заслонок';

  @override
  String get fixBlurAppsBody =>
      'Заслонок нет, пока одно из этих приложений занимает весь экран, например карты или приложение вашего банка. Заслонки возвращаются, как только вы из него выйдете, или всякий раз, когда Waaiya не уверено, какое приложение на экране.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Нужна однократная настройка: без неё Waaiya не может определить, какое приложение на экране, поэтому размытие остаётся включённым везде.';

  @override
  String get fixBlurAppsHelperMode =>
      'Помощник Waaiya не запущен, поэтому нельзя узнать, какое приложение на экране. Размытие остаётся включённым везде, пока помощник снова не запустят на странице «Настройка».';

  @override
  String get fixHandTitle => 'Закрыть область вручную';

  @override
  String get fixHandBody =>
      'Пока работает размытие, вы можете сами закрыть часть экрана, например картинку, которую размытие пропустило: нажмите «Закрыть область» и проведите по ней пальцем. Это место остаётся закрытым, пока вы не уберёте заслонку или пока размытие не остановится.';

  @override
  String get fixHandNotRunning =>
      'Доступно, пока работает размытие: фильтр включён и включён один из вариантов размытия.';

  @override
  String get fixCoverArea => 'Закрыть область';

  @override
  String fixRemoveCovers(Object count) {
    return 'Убрать ручные заслонки ($count)';
  }

  @override
  String get fixNoteTitle => 'Отметить ошибку';

  @override
  String get fixNoteBody =>
      'Когда Waaiya ошибается, нажмите на то, что произошло, например «Музыка прошла сквозь фильтр». Заметка сохраняет время, приложение и настройки, чтобы помочь найти причину. Она остаётся на этом устройстве и никуда не отправляется.';

  @override
  String get fixMissedSound => 'Музыка прошла сквозь фильтр';

  @override
  String get fixWrongSound => 'Голос убран по ошибке';

  @override
  String get fixMissedScreen => 'Что-то не было закрыто';

  @override
  String get fixWrongScreen => 'Закрыто по ошибке';

  @override
  String fixNoted(Object count) {
    return 'Записано (заметок на этом устройстве: $count).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Заметок на этом устройстве: $count';
  }

  @override
  String get fixNotesShow => 'Показать заметки';

  @override
  String get fixNotesDelete => 'Удалить заметки';

  @override
  String get fixNotesDeleteAsk => 'Удалить все заметки? Это нельзя отменить.';

  @override
  String get fixNotesTitle => 'Заметки об ошибках';

  @override
  String get worshipTitle => 'Время намаза';

  @override
  String get worshipBody =>
      'Необязательно. Рассчитывается на этом телефоне по выбранному вами месту. Ничего не отправляется.';

  @override
  String worshipPlace(Object place) {
    return 'Место: $place';
  }

  @override
  String get worshipPlaceNone => 'Место: не выбрано';

  @override
  String get worshipChoose => 'Выбрать';

  @override
  String get worshipPlaceSearch => 'Найти город';

  @override
  String get worshipPlaceNoMatch =>
      'Город не найден. Вместо этого можно ввести координаты.';

  @override
  String get worshipPlaceCustom => 'Ввести координаты';

  @override
  String get worshipLat => 'Широта (север +, юг −)';

  @override
  String get worshipLon => 'Долгота (восток +, запад −)';

  @override
  String get worshipZone => 'Часовой пояс, например Europe/Moscow';

  @override
  String get worshipCustomInvalid => 'Проверьте числа и часовой пояс.';

  @override
  String get worshipPlaceInvalid =>
      'Это место нельзя использовать. Выберите его заново.';

  @override
  String worshipMethod(Object method) {
    return 'Расчёт: $method';
  }

  @override
  String get worshipMethodTitle => 'Метод расчёта';

  @override
  String get worshipMethodNote =>
      'Выбран по стране города. Выберите тот, которому следует ваша мечеть.';

  @override
  String worshipAsr(Object rule) {
    return 'Аср: $rule';
  }

  @override
  String get worshipAsrTitle => 'Время Асра';

  @override
  String get worshipAsrStandard =>
      'Стандартный (шафиитский, маликитский, ханбалитский)';

  @override
  String get worshipAsrHanafi => 'Ханафитский';

  @override
  String get worshipMethodMwl => 'Всемирная исламская лига';

  @override
  String get worshipMethodIsna => 'Исламское общество Северной Америки (ISNA)';

  @override
  String get worshipMethodEgypt => 'Египетское главное управление геодезии';

  @override
  String get worshipMethodUmmAlQura => 'Умм аль-Кура, Мекка';

  @override
  String get worshipMethodKarachi => 'Университет исламских наук, Карачи';

  @override
  String get worshipMethodTehran =>
      'Институт геофизики Тегеранского университета';

  @override
  String get worshipMethodGulf => 'Регион Залива';

  @override
  String get worshipMethodKuwait => 'Кувейт';

  @override
  String get worshipMethodQatar => 'Катар';

  @override
  String get worshipMethodSingapore => 'Сингапур (MUIS)';

  @override
  String get worshipMethodTurkey => 'Турция (Diyanet)';

  @override
  String get worshipMethodFrance => 'Франция (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Марокко (Министерство хабусов)';

  @override
  String get worshipMethodIndonesia => 'Индонезия (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Малайзия (JAKIM)';

  @override
  String get worshipMethodDubai => 'Дубай';

  @override
  String get worshipToday => 'Сегодня';

  @override
  String get worshipNoTimes =>
      'Сегодня здесь нет времени намаза: солнце не восходит или не заходит.';

  @override
  String get worshipSilentTitle => 'Без звука во время намаза';

  @override
  String get worshipSilentBody =>
      'В каждое время намаза телефон замолкает (режим «Не беспокоить») на указанное ниже число минут, затем всё возвращается как было. Например, с намаза Зухр в 12:00 до 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Без звука: $minutes мин';
  }

  @override
  String get worshipMuteTitle => 'Выключать звук медиа во время азана';

  @override
  String get worshipMuteBody =>
      'В каждое время намаза звук медиа (видео, музыка, игры) выключается на указанное ниже число минут. Из уведомления его можно сразу включить.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Медиа без звука: $minutes мин';
  }

  @override
  String get worshipMinutesTitle => 'Длительность';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes мин';
  }

  @override
  String get worshipNeedPlace => 'Сначала выберите место.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Следующий: $prayer в $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Без звука до $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Звук медиа выключен до $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Разрешите Waaiya управлять режимом «Не беспокоить», иначе телефон не сможет переходить в беззвучный режим.';

  @override
  String get worshipAllow => 'Разрешить';

  @override
  String get worshipExactNeeded =>
      'Для Waaiya не разрешены «Будильники и напоминания», поэтому каждое изменение может опаздывать до 10 минут, а пока телефон в спящем режиме — и больше.';

  @override
  String get worshipNotificationsNeeded =>
      'Уведомления выключены: вы не увидите, когда телефон переходит в беззвучный режим и когда звук возвращается.';

  @override
  String get worshipTonesTitle => 'Простой рингтон и звук уведомлений';

  @override
  String get worshipTonesBody =>
      'Waaiya не может фильтровать рингтон и звуки уведомлений, только заменить их. Выберите простой звук без музыки:';

  @override
  String worshipToneRing(Object number) {
    return 'Простой рингтон $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Простой звук уведомления $number';
  }

  @override
  String get worshipTonePlay => 'Прослушать';

  @override
  String get worshipToneSet => 'Установить';

  @override
  String get worshipToneInUse => 'Используется';

  @override
  String get worshipToneDone => 'Готово.';

  @override
  String get worshipTonePermission =>
      'Разрешите Waaiya изменять системные настройки, вернитесь и нажмите ещё раз.';

  @override
  String get worshipToneFailed =>
      'Этот телефон не дал Waaiya его изменить. В настройках звука выберите мелодию «Waaiya plain».';

  @override
  String get worshipOpenSound => 'Открыть настройки звука';

  @override
  String get worshipSmsTitle => 'Отвечать на звонки по SMS во время намаза';

  @override
  String get worshipSmsBody =>
      'В минуты тишины после каждого времени намаза на звонок, оставшийся без ответа, уходит одно SMS. Один раз на номер за намаз; никогда на скрытые и короткие номера.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'Ждать перед SMS: $seconds с';
  }

  @override
  String get worshipSmsDelayTitle => 'Сколько секунд звонка до SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds с';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Сообщение: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Ваше сообщение';

  @override
  String get worshipSmsTextDefault => 'Использовать стандартное';

  @override
  String get worshipSmsCost =>
      'Каждый ответ — обычное SMS с вашей SIM-карты по цене вашего тарифа. В роуминге ничего не отправляется.';

  @override
  String get worshipSmsRoaming => 'Сейчас роуминг: SMS не отправляются.';

  @override
  String get worshipSmsLogTitle =>
      'Отправленные ответы (хранятся только на этом телефоне)';

  @override
  String get worshipContinue => 'Продолжить';

  @override
  String get worshipWhyDnd =>
      'Чтобы телефон затихал во время намаза, разрешите Waaiya доступ к режиму «Не беспокоить» на следующей странице.';

  @override
  String get worshipWhyExact =>
      'Чтобы всё срабатывало точно вовремя, разрешите Waaiya устанавливать будильники и напоминания на следующей странице. Без этого изменения могут опаздывать до 10 минут.';

  @override
  String get worshipWhyNotifications =>
      'Разрешите уведомления, чтобы видеть каждое изменение и иметь возможность его отменить.';

  @override
  String get worshipWhyWrite =>
      'Чтобы сменить рингтон или звук уведомлений, разрешите Waaiya изменять системные настройки на следующей странице.';

  @override
  String get worshipWhyPhone =>
      'Чтобы знать, что идёт звонок, и видеть его номер, Waaiya нужны разрешения «Телефон» и «Журналы вызовов». С телефона ничего не уходит, кроме вашего ответа.';

  @override
  String get worshipWhySms =>
      'Чтобы отправить ваш ответ, Waaiya нужно разрешение на отправку SMS. Отправляется только этот ответ, не больше одного раза на номер за намаз.';

  @override
  String get worshipMissingDnd =>
      'Доступ к режиму «Не беспокоить» не разрешён, поэтому тишина остаётся выключенной.';

  @override
  String get worshipMissingPhone =>
      'Разрешения «Телефон» и «Журналы вызовов» не предоставлены, поэтому ответ по SMS остаётся выключенным.';

  @override
  String get worshipMissingSms =>
      'Разрешение на отправку SMS не предоставлено, поэтому ответ по SMS остаётся выключенным.';

  @override
  String get worshipTryAgain => 'Попробовать ещё раз';

  @override
  String get protectTitle => 'Защита на минуты слабости';

  @override
  String get protectBody =>
      'Для минуты слабости, когда вам может захотеться выключить фильтр. Выберите сейчас, пока вы спокойны, время ожидания: тогда кнопка остановки не останавливает фильтр сразу, и вы решаете заново, когда ожидание закончится. Родитель может также задать PIN-код.';

  @override
  String protectDelay(Object value) {
    return 'Ожидание перед выключением: $value';
  }

  @override
  String get protectDelayTitle => 'Ожидание перед выключением';

  @override
  String get protectDelayBody =>
      'Например, с 30 минутами: вы нажимаете кнопку остановки, но фильтр продолжает работать. Через 30 минут эта страница спрашивает, хотите ли вы всё ещё остановить его. Нажмите «Подтвердить» в течение 15 минут, и он остановится; иначе ничего не изменится. То же самое при отключении заслонки или любой другой защиты. Включение всегда срабатывает сразу.';

  @override
  String get protectDelayOff => 'Нет';

  @override
  String get protectDelay1m => '1 минута';

  @override
  String get protectDelay5m => '5 минут';

  @override
  String get protectDelay15m => '15 минут';

  @override
  String get protectDelay30m => '30 минут';

  @override
  String get protectDelay1h => '1 час';

  @override
  String get protectDelay4h => '4 часа';

  @override
  String get protectDelay24h => '24 часа';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes мин';
  }

  @override
  String get protectPinNone => 'PIN-код: не задан';

  @override
  String get protectPinIsSet => 'PIN-код: задан';

  @override
  String get protectPinSet => 'Задать PIN-код';

  @override
  String get protectPinRemove => 'Удалить';

  @override
  String get protectPinBody =>
      'Если задан PIN-код, то чтобы остановить фильтр или выключить любую защиту, сначала нужно ввести PIN-код. Например, родитель задаёт его, чтобы ребёнок не мог выключить фильтр. Чтобы изменить время ожидания или PIN-код, он тоже нужен.';

  @override
  String get protectPinForgot =>
      'Запишите PIN-код и храните в надёжном месте: если его забыть, сбросить его нельзя. Остаётся только очистить данные Waaiya или переустановить его, а это сотрёт и все его настройки.';

  @override
  String get protectPinTitle => 'Введите PIN-код';

  @override
  String get protectPinNewTitle => 'Придумайте PIN-код';

  @override
  String get protectPinChangeTitle => 'Изменить PIN-код';

  @override
  String get protectPinCurrent => 'Текущий PIN-код';

  @override
  String get protectPinNew => 'Новый PIN-код (от 4 до 8 цифр)';

  @override
  String get protectPinAgain => 'Новый PIN-код ещё раз';

  @override
  String get protectPinBad => 'Используйте от 4 до 8 цифр.';

  @override
  String get protectPinDiffer => 'Два новых PIN-кода не совпадают.';

  @override
  String protectPinWrong(Object count) {
    return 'Неверный PIN-код. Осталось попыток до паузы: $count.';
  }

  @override
  String protectLocked(Object time) {
    return 'Слишком много неверных попыток. Попробуйте снова в $time.';
  }

  @override
  String get protectOk => 'ОК';

  @override
  String get protectCancel => 'Отмена';

  @override
  String get protectCancelChange => 'Отменить изменение';

  @override
  String get protectConfirm => 'Подтвердить';

  @override
  String protectPending(Object time, Object what) {
    return '$what: ожидание до $time. Затем подтвердите в разделе «Параметры».';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: ожидание закончилось. Вы всё ещё этого хотите? Нажмите «Подтвердить» до $time; иначе ничего не изменится.';
  }

  @override
  String get protectWaitTitle => 'Это изменение вступит в силу не сразу';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what не произойдёт сейчас. В $time, если вы всё ещё этого хотите, подтвердите в разделе «Параметры» в течение 15 минут. Если ничего не делать, ничего не изменится.';
  }

  @override
  String get protectWaitStart => 'Начать ожидание';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Уже ожидание до $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Ожидание до $time. Затем подтвердите в разделе «Параметры».';
  }

  @override
  String protectTomorrow(Object time) {
    return '$time завтра';
  }

  @override
  String get protectHeldBack =>
      'Не сейчас: по вашим настройкам защиты это изменение должно подождать или требует PIN-код.';

  @override
  String get protectLimits =>
      'Чего это не может предотвратить: принудительную остановку, удаление, очистку данных Waaiya и собственные настройки Android. Чтобы это заблокировать, нужны особые разрешения Android, которые Waaiya не использует. Это защита от минуты слабости, а не от человека, который твёрдо решил это сделать.';

  @override
  String get protectLimitsDesktop =>
      'Чего это не может предотвратить: команду waaiya в терминале, удаление Waaiya или его папки настроек. Это защита от минуты слабости, а не от решительно настроенного человека.';

  @override
  String get protectLimitsWindows =>
      'Чего это не может предотвратить: команду waaiya-filter.exe в терминале, удаление Waaiya или его папки настроек. Это защита от минуты слабости, а не от решительно настроенного человека.';

  @override
  String get protectWhatStop => 'Остановить фильтр';

  @override
  String protectWhatOff(Object name) {
    return 'Выключить: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Включить: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Добавить приложение в: $name';
  }

  @override
  String get protectWhatStrictness => 'Сделать размытие менее строгим';

  @override
  String get protectWhatGender => 'Изменить, кто пользуется Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'Изменить ожидание перед выключением на: $value';
  }

  @override
  String get protectWhatPinChange => 'Изменить PIN-код';

  @override
  String get protectWhatPinClear => 'Удалить PIN-код';

  @override
  String get protectWhatSetting => 'Изменить настройку';

  @override
  String get onboardBodyDesktop =>
      'Waaiya убирает музыкальные инструменты из звука всех приложений на этом компьютере. Речь и чтение Корана сохраняются. Пока что пение тоже убирается.';

  @override
  String get worshipUseLocation => 'Моё местоположение';

  @override
  String get worshipWhyLocation =>
      'Чтобы найти время намаза там, где вы находитесь, Waaiya один раз, сейчас, считывает примерное местоположение телефона. Оно хранится на телефоне как ваше место и никуда не отправляется.';

  @override
  String get worshipLocating => 'Определяем, где вы…';

  @override
  String get worshipLocationDenied =>
      'Доступ к местоположению не разрешён. Вместо этого можно найти свой город.';

  @override
  String get worshipLocationOff =>
      'Геолокация на этом телефоне выключена. Включите её и повторите, или найдите свой город.';

  @override
  String get worshipLocationSettings => 'Настройки геолокации';

  @override
  String get worshipLocationFailed =>
      'Не удалось определить местоположение. Повторите чуть позже или найдите свой город.';

  @override
  String worshipPlaceNear(Object city) {
    return 'рядом с $city';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Официальное время Министерства хабусов и исламских дел для города $city.';
  }

  @override
  String get trayOpen => 'Открыть Waaiya';

  @override
  String get trayQuit => 'Выйти';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows не разрешает Waaiya запускаться при входе в систему. Включите Waaiya в Параметры › Приложения › Автозагрузка, затем снова включите этот параметр.';

  @override
  String get engineErrorAutostartPolicy =>
      'Настройки этого компьютера, выбранные его администратором, не разрешают Waaiya запускаться при входе в систему.';

  @override
  String get notifTextTitle =>
      'Показывать текст уведомлений во время фильтрации';

  @override
  String get notifTextBody =>
      'Android скрывает содержимое уведомлений, пока какое-либо приложение записывает весь экран, а фильтрация считается такой записью. Включено: Waaiya снимает эту защиту только на время фильтрации, чтобы вы могли читать уведомления. Другие трансляции экрана в это же время тоже не защищены.';

  @override
  String get notifTextNextStart =>
      'Остановите и снова запустите фильтрацию, чтобы изменение вступило в силу.';

  @override
  String get notifTextRefused =>
      'Телефон отклонил изменение. Включите сами «Отключить защиту при демонстрации экрана» в параметрах разработчика.';

  @override
  String get notifTextByHand =>
      'Показывается: защита Android отключена в параметрах разработчика («Отключить защиту при демонстрации экрана»). Она остаётся отключённой для любой демонстрации экрана, пока вы не включите её там снова.';

  @override
  String get notifTextHowTo =>
      'Android скрывает содержимое уведомлений, пока Waaiya фильтрует. После разовой настройки Waaiya их показывает: снимает эту защиту только на время фильтрации.';

  @override
  String get notifTextOpenDev => 'Открыть параметры разработчика';

  @override
  String get notifTextLockNote =>
      'На этом телефоне Android также останавливает фильтрацию при блокировке экрана, и другие приложения молчат, пока вы не нажмёте «Продолжить». Настройка предотвращает и это.';

  @override
  String get notifTextHandOptional =>
      'Необязательно, без настройки: включите «Отключить защиту при демонстрации экрана» в параметрах разработчика. Тогда она останется отключённой для любой демонстрации экрана, и на некоторых телефонах её нет.';

  @override
  String get notifTextForced =>
      'Включено: на этом телефоне Android спрашивает перед каждым запуском и тогда останавливал бы фильтрацию при каждой блокировке экрана. Waaiya снимает эту защиту на время фильтрации, поэтому текст уведомлений тоже виден. Другие трансляции экрана в это же время тоже не защищены.';

  @override
  String get oneAppTitle =>
      'При запуске: «Показать одно приложение», затем Waaiya';

  @override
  String get oneAppBody =>
      'Когда Android спросит, что транслировать, выберите «Показать одно приложение», затем Waaiya. Все приложения по-прежнему фильтруются, уведомления остаются читаемыми, а фильтрация продолжается при блокировке экрана. При трансляции всего экрана Android скрывает текст уведомлений и останавливает фильтрацию при каждой блокировке.';

  @override
  String get oneAppPair =>
      'Чтобы Waaiya работала полностью, один раз выполните сопряжение через отладку по Wi-Fi на странице «Настройка»: тогда исходная музыка тоже заглушается, а Android перестаёт спрашивать при каждом запуске.';

  @override
  String get notifTextOneApp =>
      'Показывается, если при запуске выбрать «Показать одно приложение», затем Waaiya. При трансляции всего экрана Android его скрывает; после разовой настройки Waaiya снимает это на время фильтрации.';

  @override
  String get blurNeedsRestart =>
      'Остановите и снова запустите фильтрацию, чтобы использовать размытие: ему нужен весь экран, а эта фильтрация началась с предложением «Показать одно приложение».';
}
