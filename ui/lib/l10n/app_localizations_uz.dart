// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Barcha ilovalardan musiqa asboblarini olib tashlaydi, nutq va tilovatni saqlaydi.';

  @override
  String get onboardTitle => 'Xush kelibsiz';

  @override
  String get onboardBody =>
      'Waaiya bu telefondagi barcha ilovalar ovozidan musiqa asboblarini olib tashlaydi. Nutq va Qurʼon tilovati saqlanadi. Hozircha qoʻshiq aytayotgan ovozlar ham olib tashlanadi.';

  @override
  String get onboardQuestion => 'Men';

  @override
  String get genderMan => 'Erkakman';

  @override
  String get genderWoman => 'Ayolman';

  @override
  String get onboardWhy =>
      'Bu faqat qaysi qoʻshimcha sozlamalarni koʻrishingizni belgilaydi. Keyinroq oʻzgartirishingiz mumkin.';

  @override
  String get stateOnTitle => 'Filtrlash yoqilgan';

  @override
  String get stateOffTitle => 'Filtrlash oʻchirilgan';

  @override
  String get stateStarting => 'Ishga tushirilmoqda…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Barcha ilovalardan musiqa asboblari olib tashlanmoqda. Kechikish taxminan $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Boshlash uchun tugmani bosing.';

  @override
  String get stateModelFailed =>
      'Ovoz modeli yuklanmadi, shuning uchun xavfsizlik uchun ovoz oʻchirildi.';

  @override
  String get stateCaptureDenied =>
      'Boshqa ilovalarning ovozini qabul qilish uchun mikrofon ruxsati kerak.';

  @override
  String get stateStoppedBySystem =>
      'Android filtrlashni toʻxtatdi. Qayta boshlash uchun tugmani bosing.';

  @override
  String get stateSilencedTitle => 'Filtrlash toʻxtadi';

  @override
  String get stateSilenced =>
      'Filtrlash toʻxtadi: boshqa ilovalar ovozsiz qilindi. Qayta boshlash uchun tugmani bosing yoki ularni filtrsiz eshitish uchun “Toʻxtatish”ni bosing.';

  @override
  String get releaseSilence => 'Toʻxtatish: ilovalarni filtrsiz eshitish';

  @override
  String get powerStartCd => 'Filtrlashni boshlash';

  @override
  String get powerStopCd => 'Filtrlashni toʻxtatish';

  @override
  String get captureHint =>
      'Android ekraningizni ulashishni soʻraydi. Faqat ovoz ishlatiladi: hech narsa yozib olinmaydi va yuborilmaydi.';

  @override
  String get needRecordAudio =>
      'Boshqa ilovalarning ovozini qabul qilishi uchun Waaiyaga mikrofon ruxsati kerak. U hech qachon sizni yozib olmaydi.';

  @override
  String get setupBannerTitle => 'Yana bir qadam';

  @override
  String get setupBannerBody =>
      'Quyidagi bir martalik sozlashsiz musiqa va filtrlangan ovozni birga eshitasiz.';

  @override
  String get step1Title => 'Shizuku ilovasini oʻrnating';

  @override
  String get step1Body => 'Play Marketdagi bepul yordamchi ilova.';

  @override
  String get step1Action => 'Shizuku ilovasini olish';

  @override
  String get step2Title => 'Shizuku ilovasini ishga tushiring';

  @override
  String get step2Body =>
      'Shizuku Wi-Fi orqali, Androidning “Wi-Fi orqali debaglash” funksiyasi yordamida ishga tushadi. Qadamlarni koʻrish uchun tugmani bosing, soʻng bu yerga qayting.';

  @override
  String get step2Action => 'Shizuku ilovasini ochish';

  @override
  String get step2Update => 'Shizuku ilovasini yangilash';

  @override
  String get step2TooOld =>
      'Shizuku versiyangiz juda eski. Uni Play Marketdan yangilang.';

  @override
  String get step2Denied =>
      'Shizukuda Waaiya uchun “doim rad etish” tanlangan. Shizuku ilovasidagi ilovalar roʻyxatida Waaiyaga ruxsat bering.';

  @override
  String get step3Title => 'Ruxsat bering';

  @override
  String get step3Body => 'Bir marta bosing, soʻng “Ruxsat berish”ni tanlang.';

  @override
  String get step3Action => 'Ruxsat bering';

  @override
  String get step3Busy => 'Sozlanmoqda…';

  @override
  String get setupDoneRestart =>
      'Tayyor. Buni qoʻllash uchun filtrlashni bir marta toʻxtatib, qayta boshlang.';

  @override
  String setupFailed(String details) {
    return 'Sozlash tugamadi. Tafsilotlar:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Shizuku ruxsati rad etildi. Qayta urinish uchun tugmani bosing.';

  @override
  String get setupSlow =>
      'Shizuku odatdagidan uzoqroq vaqt olmoqda. Kutib turing: baʼzi telefonlarda uning yordamchisi birinchi marta ishga tushishi uchun bir daqiqagacha vaqt ketadi.';

  @override
  String get setupTimeout =>
      'Shizuku 2 daqiqa ichida javob bermadi. Shizuku ilovasini oching, unda ishlayotgani yozilganini tekshiring, soʻng tugmani yana bosing. Agar sozlash keyinroq tugasa, bu ekran oʻzi yangilanadi.';

  @override
  String get setupRefusedXiaomi =>
      'Bu telefon ruxsatlarni rad etdi. Xiaomi, Redmi va POCO telefonlarida “Dasturchilar uchun” (Developer options) boʻlimida “USB orqali debaglash (Xavfsizlik sozlamalari)” [USB debugging (Security settings)] bandini yoqing (u Xiaomi hisobiga kirishni soʻraydi), soʻng qayta urinib koʻring.';

  @override
  String get setupRefusedColoros =>
      'Bu telefon ruxsatlarni rad etdi. OPPO, OnePlus va realme telefonlarida “Dasturchilar uchun” boʻlimida “Disable permission monitoring” (Ruxsatlar nazoratini oʻchirish) bandini yoqing (eng yangi versiyalarda u “Disable system optimization” (Tizim optimallashtirishini oʻchirish) deb ataladi va faqat telefon tili inglizcha boʻlganda koʻrinishi mumkin). Uni topish uchun Sozlamalarda “permission” soʻzini qidiring. Soʻng qayta urinib koʻring.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi va POCO: agar bildirishnomada kodni yozish uchun maydon boʻlmasa, bildirishnoma sozlamalarida bildirishnoma uslubini “Android” qilib qoʻying yoki ekranni ikkiga boʻlib, kodni Waaiyada yozing.';

  @override
  String get stepDoneCd => 'Bajarildi';

  @override
  String stepTodoCd(int step) {
    return '$step-qadam';
  }

  @override
  String get computerToggle => 'Oʻrniga kompyuterdan foydalanish';

  @override
  String get computerBody =>
      '“USB orqali debaglash” (USB debugging) ni yoqing, telefonni kompyuterga ulang va quyidagini ishga tushiring:';

  @override
  String get copy => 'Nusxalash';

  @override
  String get copied => 'Nusxalandi';

  @override
  String get computerNote =>
      'Ikkinchi qator ixtiyoriy: u har safar ishga tushirishda ekranni ulashish haqidagi savolni chiqarmaydi.';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingSilenceTitle =>
      'Filtrlashga yoʻl qoʻymaydigan ilovalarni ovozsiz qilish';

  @override
  String get settingSilenceBody =>
      'Tavsiya etiladi. Baʼzi ilovalar oʻz ovozini filtrlashga ruxsat bermaydi; bu sozlama musiqani oʻtkazib yuborish oʻrniga ularni ovozsiz qiladi.';

  @override
  String get settingHoldSilenceTitle =>
      'Filtrlash oʻzidan oʻzi toʻxtasa, ilovalarni ovozsiz qoldirish';

  @override
  String get settingHoldSilenceBody =>
      'Tavsiya etiladi. Agar filtrlashni siz emas, Android toʻxtatsa, boshqa ilovalar musiqani filtrsiz chalish oʻrniga, siz qayta boshlamaguningizcha yoki “Toʻxtatish”ni bosmaguningizcha ovozsiz qoladi. Bir martalik sozlash kerak.';

  @override
  String get settingStereoTitle => 'Stereo ovoz';

  @override
  String get settingStereoBody =>
      'Oʻchirilgan: mono, u batareyani taxminan ikki baravar kam sarflaydi va koʻproq telefonlarda uzilishsiz ishlaydi. Yoqilgan: chap va oʻng tomonlarni alohida saqlaydi. Telefon stereo uchun juda sekin boʻlsa, baribir oʻzi monoga oʻtadi.';

  @override
  String get settingSingingTitle => 'Ayollar qoʻshigʻini oʻchirish';

  @override
  String get settingSingingBody => 'Ayollarning nutqi saqlanadi.';

  @override
  String get settingSingingNoModel =>
      'Bu versiyada qoʻshiq aniqlagichi yoʻq, shuning uchun bu yoqilganda barcha ovozlar oʻchiriladi.';

  @override
  String get settingRestart =>
      'Oʻzgarishlarni qoʻllash uchun filtrlashni toʻxtatib, qayta boshlang.';

  @override
  String get settingGenderTitle => 'Men';

  @override
  String get change => 'Oʻzgartirish';

  @override
  String get playerTitle => 'Mukammal sinxron videolar';

  @override
  String get playerBody =>
      'Videoni kechikishsiz, filtrlangan holda koʻrish uchun uni Waaiyaga ulashing (yoki “Open with” / “… orqali ochish” bilan Waaiyada oching).';

  @override
  String get licences => 'Ochiq kodli litsenziyalar';

  @override
  String get licencesIntro =>
      'Waaiya — GNU Affero General Public License v3 yoki undan keyingi versiyasi ostidagi erkin dasturiy taʼminot. Manba kodi: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (oʻqitish maʼlumotlari): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Toʻliq matnlar';

  @override
  String get back => 'Orqaga';

  @override
  String get linkEntryTitle => 'Havolani ochish';

  @override
  String get linkEntryBody =>
      'YouTube, TikTok yoki Instagram havolasini qoʻying va uni musiqasiz koʻring yoki saqlang.';

  @override
  String get linkTitle => 'Havolani ochish';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Video yoki audio havolasi';

  @override
  String get linkPaste => 'Qoʻyish';

  @override
  String get linkOpen => 'Ochish';

  @override
  String get linkResolving => 'Havola ochilmoqda…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Musiqasiz koʻrish';

  @override
  String get linkSave => 'Musiqasiz saqlash';

  @override
  String get linkListen => 'Musiqasiz tinglash';

  @override
  String get linkAudioOnly =>
      'Bu havoladagi videoni hozircha ochib boʻlmaydi: faqat uning ovozini.';

  @override
  String get linkDownloading => 'Yuklab olinmoqda…';

  @override
  String get linkFiltering => 'Musiqa olib tashlanmoqda…';

  @override
  String get linkCancel => 'Bekor qilish';

  @override
  String get linkCancelled => 'Bekor qilindi. Hech narsa saqlanmadi.';

  @override
  String get linkTimedOut =>
      'Android saqlashni toʻxtatdi: u bunday ishga kuniga faqat bir necha soat ruxsat beradi. Hech narsa saqlanmadi; Waaiyani oching va qayta urinib koʻring.';

  @override
  String get linkExportFailed => 'Buni saqlab boʻlmadi. Hech narsa saqlanmadi.';

  @override
  String get linkSaved => 'Musiqasiz saqlandi';

  @override
  String get linkSavedVideo => 'Galereyangizda: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'Musiqalaringizda: Music › Waaiya';

  @override
  String get linkPlay => 'Ijro etish';

  @override
  String get linkShare => 'Ulashish';

  @override
  String get linkShareNote =>
      'Faqat ulashishga ruxsatingiz bor videolarni ulashing.';

  @override
  String get linkLive => 'Jonli efirlarni saqlab boʻlmaydi.';

  @override
  String get linkBusy =>
      'Boshqa video saqlanmoqda. Iltimos, u tugashini kuting.';

  @override
  String get linkInvalid =>
      'Iltimos, veb-havolani qoʻying (https:// bilan boshlanadigan).';

  @override
  String get linkLogin =>
      'Sayt bu videoni hisobsiz koʻrsatmadi. Ommaviy postlar odatda ochiladi: bir necha daqiqadan soʻng qayta urinib koʻring. Shaxsiy postlarni ochib boʻlmaydi.';

  @override
  String get linkUnsupported => 'Bu sayt qoʻllab-quvvatlanmaydi.';

  @override
  String get linkPlaylist => 'Bu pleylist. Iltimos, bitta videoni oching.';

  @override
  String get linkNoFormat =>
      'Bu video hozircha Waaiya filtrlay oladigan formatda emas.';

  @override
  String get linkFailed =>
      'Bu havolani ochib boʻlmadi. Internet aloqangizni tekshiring va qayta urinib koʻring.';

  @override
  String get linkPlayFailed =>
      'Buni ijro etib boʻlmadi. Filtrlanmagan hech narsa ijro etilmadi.';

  @override
  String get linkLimited =>
      'Sayt hozir soʻrovlarni cheklamoqda. Bir necha daqiqadan soʻng qayta urinib koʻring.';

  @override
  String get blurTitle => 'Ekranni xiralashtirish';

  @override
  String get blurBody =>
      'Filtrlash yoqilganda barcha ilovalarda ekrandagi odamlar va tasvirlarni yopadi. U telefonning oʻzida ishlaydi; hech narsa hech qayerga yuborilmaydi.';

  @override
  String get blurWomenTitle => 'Ayollarni xiralashtirish';

  @override
  String get blurWomenBody =>
      'Butun tana. Ilova erkak ekanini aniq ajrata olmagan odamlar ham xiralashtiriladi.';

  @override
  String get blurNudityTitle => 'Odobsiz tasvirlarni xiralashtirish';

  @override
  String get blurNudityBody =>
      'Har qanday kishining yalangʻochligi va ochiq-sochiq kiyimi: butun ekran yopiladi.';

  @override
  String get blurFailTitle => 'Xiralashtirish ulgurmasa, ekranni yopish';

  @override
  String get blurFailBody =>
      'Yoqilgan: telefon juda sekin boʻlsa yoki xiralashtirish ishlamay qolsa, butun ekran yopiladi. Oʻchirilgan: ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get blurSetupShizuku => 'Shizuku orqali ruxsat berish';

  @override
  String get blurSetupManual => 'Android sozlamalarida ruxsat berish';

  @override
  String get blurStatusNeedsSetup =>
      'Xiralashtirish boshqa ilovalar ustida chizishi kerak. Eng yaxshisi: Shizuku orqali ruxsat bering (u “Waaiya xiralashtirish” maxsus imkoniyatlar xizmatini yoqadi, shunda bosishlar ostidagi ilovaga yetib boradi). Yoki Android sozlamalarida “Boshqa ilovalar ustidan ochish” (Display over other apps) uchun ruxsat bering (bunda xiralashtirilgan joyga bosishlar yoʻqoladi).';

  @override
  String get blurStatusNeedsOverlay =>
      'Xiralashtirish boshqa ilovalar ustida chizishi kerak. Eng yaxshisi: Shizuku ilovasini ishga tushiring (va unda Waaiyaga ruxsat bering): shunda xiralashtirish oʻz qatlamini chizadi va bosishlar undan oʻtib ketadi. Aks holda Android sozlamalarida “Boshqa ilovalar ustidan ochish” (Display over other apps) uchun ruxsat bering; bunda xiralashtirilgan joyga bosish ostidagi ilovaga yetib bormaydi.';

  @override
  String get blurFailUnavailable =>
      'Hozircha nofaol: butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin. Waaiya yordamchisini yoki Shizuku ilovasini ishga tushiring (Android 12 yoki yangiroq) va bu sozlama yoqiladi: shunda qoplamalar bosishlar ulardan oʻtib ketadigan qilib chiziladi. Ungacha xiralashtirish ulgurmasa, ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get blurFailNeedsA11y =>
      'Hozircha nofaol: butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin. Shizuku ilovasini ishga tushiring (Android 12 yoki yangiroq) yoki “Waaiya xiralashtirish” maxsus imkoniyatlar xizmatini yoqing (yuqoridagi “Shizuku orqali ruxsat berish”) va bu sozlama yoqiladi. Ungacha ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get languageTitle => 'Til';

  @override
  String settingLanguageTitle(String language) {
    return 'Til: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Xiralashtirish sozlamalarini qoʻllash uchun filtrlashni toʻxtatib, qayta boshlang.';

  @override
  String get blurStatusStarting => 'Xiralashtirish ishga tushmoqda…';

  @override
  String get blurStatusOn => 'Xiralashtirish yoqilgan.';

  @override
  String get blurStatusOnVisible =>
      'Xiralashtirish ehtiyotkor rejimda yoqilgan: bu telefon xiralashtirishni oʻz ekran tasvirida koʻrsatadi, shuning uchun xiralashtirilgan joy sahna oʻzgarmaguncha xira boʻlib qoladi.';

  @override
  String get blurStatusModels =>
      'Bu versiyada tanlangan variant uchun xiralashtirish modeli yoʻq.';

  @override
  String get blurStatusFailing => 'Xiralashtirish hozir ulgurmayapti.';

  @override
  String get blurStatusNoOverlay =>
      'Xiralashtirish boshqa ilovalar ustida chiza olmaydi: yuqorida unga ruxsat bering.';

  @override
  String blurStatusNoCapture(String details) {
    return 'Xiralashtirish ekranni koʻra olmayapti. Tafsilotlar:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku ruxsat bera olmadi:\n$details';
  }

  @override
  String get step2Guide => 'Shizuku qanday ishga tushiriladi';

  @override
  String get blurFailOldAndroid =>
      'Nofaol: Androidning bu versiyasida butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin (Shizuku qoplamalari uchun Android 12 yoki yangiroq kerak). Xiralashtirish ulgurmasa, ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get guideTitle => 'Shizuku ilovasini qadamma-qadam ishga tushirish';

  @override
  String get guideOpenDev => 'Dasturchilar uchun';

  @override
  String get guideOpenShizuku => 'Shizuku ilovasini ochish';

  @override
  String get guideClose => 'Yopish';

  @override
  String get guideBody =>
      'Sizga Wi-Fi va Android 11 yoki yangiroq kerak. Juftlash bir marta bajariladi; telefon qayta ishga tushgandan keyin faqat 7-qadamni takrorlaysiz.\n\n1. Telefonni Wi-Fi tarmogʻiga ulang.\n\n2. “Dasturchilar uchun” (Developer options) boʻlimini yoqing: Sozlamalar › Telefon haqida › Dasturiy taʼminot haqida maʼlumot › “Versiya raqami” (Build number) ustiga 7 marta bosing. (Boshqa telefonlarda: Sozlamalar › Telefon haqida › Versiya raqami.)\n\n3. Shizuku ilovasini oching. Agar u bildirishnomalar koʻrsatishga ruxsat soʻrasa, ruxsat bering: juftlash kodi Shizuku bildirishnomasida yoziladi.\n\n4. Shizuku ilovasida “Start via Wireless debugging” (Wi-Fi orqali debaglash bilan ishga tushirish) ostida “Pairing” (Juftlash) tugmasini bosing. Ochilgan sahifada “Developer options” (Dasturchilar uchun) tugmasini bosing, “Wi-Fi orqali debaglash” (Wireless debugging) ni yoqing va “Ruxsat berish” bilan tasdiqlang.\n\n5. “Wi-Fi orqali debaglash” soʻzlarini bosing (almashtirgichni emas), soʻng “Qurilmani juftlash kodi bilan ulash” (Pair device with pairing code) ni bosing. 6 xonali kod paydo boʻladi.\n\n6. Bu ekranni ochiq qoldiring va bildirishnomalarni pastga torting. Shizuku bildirishnomasida “Pairing service found” (Juftlash xizmati topildi) yozuvi chiqqanda, “Enter pairing code” (Juftlash kodini kiriting) tugmasini bosing va kodni yozing. Shizuku juftlash muvaffaqiyatli boʻlganini aytadi.\n\n7. Shizuku ilovasiga qayting va “Start via Wireless debugging” ostidagi “Start” (Boshlash) tugmasini bosing. “Shizuku is running” (Shizuku ishlamoqda) yozuvi chiqquncha kuting.\n\n8. Waaiyaga qayting va “Ruxsat bering” tugmasini, soʻng “Ruxsat berish”ni bosing.\n\nTelefon qayta ishga tushgandan keyin Shizuku toʻxtaydi: Wi-Fi tarmogʻiga ulaning, “Wi-Fi orqali debaglash” oʻchiq boʻlsa, uni qayta yoqing, Shizuku ilovasini oching va “Start” tugmasini bosing. Yangi juftlash kerak emas.';

  @override
  String get wsetupRouteTitle => 'Shu telefonda sozlash';

  @override
  String get wsetupRouteBody =>
      'Toʻrtta qisqa qadam, bir marta bajariladi. Qoʻshimcha ilova ham, kompyuter ham kerak emas. Har bir qadam bajarilganda Waaiya uni belgilab qoʻyadi.';

  @override
  String get wizDevTitle => '“Dasturchilar uchun” boʻlimini yoqing';

  @override
  String get wizDevBody =>
      '“Telefon haqida” boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng bu yerga qayting. Topa olmasangiz, Sozlamalarda “Versiya raqami” yoki “Build number” ni qidiring.';

  @override
  String get wizDevBodySamsung =>
      '“Telefon haqida” › “Dasturiy taʼminot haqida maʼlumot” boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng bu yerga qayting.';

  @override
  String get wizDevBodyXiaomi =>
      '“Telefon haqida” boʻlimida “OS versiyasi” (OS version) ustiga 7 marta bosing (eski telefonlarda “MIUI versiyasi”; baʼzilarida u “Batafsil maʼlumot va xususiyatlar” ichida), soʻng bu yerga qayting.';

  @override
  String get wizDevBodyColoros =>
      '“Qurilma haqida” (yoki “Telefon haqida”) › “Versiya” boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng bu yerga qayting.';

  @override
  String get wizDevBodyVivo =>
      '“Telefon haqida” boʻlimida “Dasturiy taʼminot versiyasi” (Software version) ustiga 7 marta bosing (baʼzi telefonlarda: Dasturiy taʼminot haqida maʼlumot › “Versiya raqami”), soʻng bu yerga qayting.';

  @override
  String get wizDevBodyHuawei =>
      '“Telefon haqida” boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng bu yerga qayting.';

  @override
  String get wizDevBodyTranssion =>
      '“Mening telefonim” (yoki “Telefon haqida”) boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng bu yerga qayting.';

  @override
  String get setupNoteHuawei =>
      'Huawei: koʻp Huawei telefonlarida “Wi-Fi orqali debaglash” (Wireless debugging) yoʻq. Uni “Dasturchilar uchun” boʻlimida topa olmasangiz, kompyuterdan foydalaning (quyidagi “Boshqa usullar”).';

  @override
  String get wsetupFilterOn =>
      'Filtrlash yoqilgan: Androidning bu versiyasida filtrlash ishlayotganda kodni bildirishnomada yozib boʻlmaydi. Avval filtrlashni toʻxtating yoki ekranni ikkiga boʻling va “Kodni shu yerda kiriting” tugmasidan foydalaning.';

  @override
  String get wizDevSearch =>
      'Nomlar telefon tiliga qarab farq qilishi mumkin: topa olmasangiz, Sozlamalar yuqorisidagi qidiruvdan foydalaning.';

  @override
  String get wizDevAction => '“Telefon haqida”ni ochish';

  @override
  String get wizWifiTitle => 'Wi-Fi tarmogʻiga ulaning';

  @override
  String get wizWifiBody =>
      'Har qanday Wi-Fi tarmogʻi boʻladi; internet kerak emas.';

  @override
  String get wizWifiAction => 'Wi-Fi sozlamalarini ochish';

  @override
  String get wizWdTitle => 'Wi-Fi orqali debaglashni yoqing';

  @override
  String get wizWdBody =>
      'Waaiya “Dasturchilar uchun” boʻlimini “Wi-Fi orqali debaglash” (Wireless debugging) bandida ochadi. Uni yoqing va “Ruxsat berish”ni bosing.';

  @override
  String get wizWdAction => '“Dasturchilar uchun”ni ochish';

  @override
  String get wizPairTitle => 'Juftlash kodini kiriting';

  @override
  String get wizPairBody =>
      '“Wi-Fi orqali debaglash” soʻzlarini, soʻng “Qurilmani juftlash kodi bilan ulash” (Pair device with pairing code) ni bosing. 6 ta raqamni Waaiya bildirishnomasida yozing. Qolganini Waaiya oʻzi bajaradi.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya bu telefon bilan allaqachon juftlangan: kod kerak emas. Tugmani bosing, Waaiya oʻzi yakunlaydi.';

  @override
  String get wizPairAction => 'Davom etish';

  @override
  String get wizAgain => 'Sozlashni qayta bajarish';

  @override
  String get setupShizukuReadyTitle =>
      'Allaqachon ishlab turgan Shizuku orqali';

  @override
  String get setupOtherWaysPlain => 'Sozlashning boshqa usullari';

  @override
  String get wizSkip => 'Wi-Fi orqali debaglashga oʻtish';

  @override
  String get setupOtherWays => 'Boshqa usullar: Shizuku yoki kompyuter';

  @override
  String get wsetupEnterHere => 'Kodni shu yerda kiriting';

  @override
  String get wsetupCancel => 'Bekor qilish';

  @override
  String get wsetupAndroid10 =>
      'Android 10 sozlashni oʻzi bajara olmaydi: buning uchun kompyuter kerak, toʻgʻridan-toʻgʻri (quyida) yoki Shizuku ilovasini bir marta ishga tushirish uchun.';

  @override
  String get wsetupShizukuHeading => 'Yoki Shizuku ilovasi orqali';

  @override
  String get wsetupShizukuNote =>
      'Shizuku bosishlarni ekran qoplamalaridan oʻtkazib yuborishga ham imkon beradi.';

  @override
  String get wsetupChannel => 'Bir martalik sozlash';

  @override
  String get wsetupNotifTitle => 'Waaiya sozlanmoqda: juftlash kodi kutilmoqda';

  @override
  String get wsetupFoundTitle => 'Juftlash ekrani topildi';

  @override
  String get wsetupBusyTitle => 'Waaiya sozlanmoqda';

  @override
  String get wsetupDoneTitle => 'Sozlash tugadi';

  @override
  String get wsetupDoneBody =>
      'Endi Waaiya asl ovozni oʻchira oladi. Wi-Fi orqali debaglashni oʻchirib qoʻyishingiz mumkin.';

  @override
  String get wsetupDoneHelperBody =>
      'Tayyor. Bu telefon ilovalarga bu ruxsatlarni saqlab qolishga yoʻl qoʻymaydi, shuning uchun asl ovozni Waaiya yordamchisi oʻchiradi. Yordamchi telefon qayta ishga tushganda va Waaiya yangilanganda toʻxtaydi. Shundan keyin Waaiyani ochganingizda, Wi-Fi orqali debaglash yoqilgan boʻlsa, u yordamchini oʻzi qayta ishga tushiradi; aks holda buning uchun tugma koʻrsatadi.';

  @override
  String get helperMissingTitle => 'Waaiya yordamchisi toʻxtagan';

  @override
  String get helperMissingBody =>
      'Bu telefon Waaiya ruxsatlarini saqlamaydi, shuning uchun Waaiya oʻz yordamchisidan foydalanadi. Yordamchi telefon qayta ishga tushganda va Waaiya yangilanganda toʻxtaydi. Wi-Fi tarmogʻiga ulaning, “Dasturchilar uchun” boʻlimida “Wi-Fi orqali debaglash” ni yoqing, soʻng “Waaiya yordamchisini ishga tushirish” tugmasini bosing.';

  @override
  String get helperChannel => 'Waaiya yordamchisi';

  @override
  String get helperStarting => 'Yordamchi ishga tushirilmoqda…';

  @override
  String get helperModeNote =>
      'Bu telefon ilovalarga bu ruxsatlarni saqlab qolishga yoʻl qoʻymaydi: ishni Waaiya yordamchisi bajaradi. U telefon qayta ishga tushganda va Waaiya yangilanganda toʻxtaydi. Shundan keyin Waaiyani ochganingizda, Wi-Fi orqali debaglash yoqilgan boʻlsa, u yordamchini oʻzi qayta ishga tushiradi; aks holda buning uchun tugma koʻrsatadi.';

  @override
  String get helperTipXiaomi =>
      'Ixtiyoriy, ruxsatlarni butunlay saqlab qolish uchun (qayta ishga tushgandan keyin yordamchisiz): “Dasturchilar uchun” boʻlimida “USB orqali debaglash (Xavfsizlik sozlamalari)” [USB debugging (Security settings)] bandini yoqing (u Xiaomi hisobiga kirishni soʻraydi), soʻng sozlashni qayta bajaring.';

  @override
  String get helperTipColoros =>
      'Ixtiyoriy, ruxsatlarni butunlay saqlab qolish uchun (qayta ishga tushgandan keyin yordamchisiz): “Dasturchilar uchun” boʻlimida “Disable permission monitoring” (Ruxsatlar nazoratini oʻchirish) bandini yoqing (eng yangi versiyalarda “Disable system optimization”; u faqat telefon tili inglizcha boʻlganda koʻrinishi mumkin), soʻng sozlashni qayta bajaring.';

  @override
  String get stateOnHelperMissing =>
      'Asl ovoz oʻchirilmagan, shuning uchun musiqani filtrlangan ovoz bilan birga eshitasiz: Waaiya yordamchisi toʻxtagan. Wi-Fi tarmogʻiga ulaning, Wi-Fi orqali debaglashni yoqing, soʻng “Waaiya yordamchisini ishga tushirish” tugmasini bosing.';

  @override
  String get setupRefusedTryWireless =>
      'Yoki shu sahifadagi “Shu telefonda sozlash” usulidan foydalaning: shunda Waaiya yordamchisi bu kalitsiz ishlaydi.';

  @override
  String get helperStartAnywayTitle => 'Waaiya yordamchisi toʻxtagan';

  @override
  String get helperStartAnywayBody =>
      'Usiz musiqani filtrlangan ovoz bilan birga eshitasiz. Avval yordamchini ishga tushiring (Wi-Fi orqali debaglash yoqilgan boʻlishi kerak) yoki baribir filtrlashni boshlang.';

  @override
  String get wsetupFailedTitle => 'Sozlash tugamadi';

  @override
  String get wsetupPairing => 'Juftlanmoqda…';

  @override
  String get wsetupConnecting => 'Ulanmoqda va ruxsatlar berilmoqda…';

  @override
  String get wsetupNeedWifi =>
      'Avval Wi-Fi tarmogʻiga ulaning (internet kerak emas): Wi-Fi orqali debaglash faqat Wi-Fi tarmogʻida ishlaydi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      '“Dasturchilar uchun” boʻlimida “Wi-Fi orqali debaglash” (Wireless debugging) ni yoqing, soʻng uning nomini va “Qurilmani juftlash kodi bilan ulash” ni bosing.';

  @override
  String get wsetupOpenDialog =>
      '“Wi-Fi orqali debaglash” ichida “Qurilmani juftlash kodi bilan ulash” ni bosing. Kodni ekranda qoldiring va bu yerda “Kodni kiritish” ni bosing.';

  @override
  String get wsetupEnterCodeBody =>
      '“Kodni kiritish” ni bosing va Sozlamalarda koʻrsatilgan 6 xonali kodni yozing.';

  @override
  String get wsetupCodeWaiting =>
      'Kod olindi. “Qurilmani juftlash kodi bilan ulash” ekrani kutilmoqda: uni ochiq qoldiring.';

  @override
  String get wsetupWrongCode =>
      'Bu kod qabul qilinmadi. Ekrandagi 6 ta raqamni tekshiring va qayta kiriting. Agar juftlash ekrani yopilgan boʻlsa, uni qayta oching: kod oʻzgaradi.';

  @override
  String get wsetupPairingFailed =>
      'Juftlash amalga oshmadi. Juftlash ekranini yoping, “Qurilmani juftlash kodi bilan ulash” ni qayta oching va yangi kodni kiriting.';

  @override
  String get wsetupWaitingConnect =>
      'Juftlandi. “Wi-Fi orqali debaglash” ni yoqilgan holda qoldiring: Waaiya ulanmoqda.';

  @override
  String get wsetupNotPaired =>
      'Bu telefon endi Waaiyani tanimaydi (juftlash oʻchirilgan yoki muddati tugagan). “Qurilmani juftlash kodi bilan ulash” ni oching va kodni kiriting.';

  @override
  String get wsetupConnectFailed =>
      'Wi-Fi orqali debaglashga ulanib boʻlmadi. Uni oʻchirib, qayta yoqing: Waaiya oʻzi qayta urinadi.';

  @override
  String get wsetupGrantFailed =>
      'Ulandi, lekin ruxsatlar hali ham yoʻq. Quyida Shizuku yoki kompyuterdan foydalaning.';

  @override
  String get wsetupTimeout =>
      '10 daqiqadan keyin tugallanmasdan toʻxtadi. Qayta urinib koʻrishingiz mumkin.';

  @override
  String get wsetupCodeUnreadable => 'Juftlash kodining 6 ta raqamini yozing.';

  @override
  String get wsetupCodeHint => '6 xonali kod';

  @override
  String get wsetupEnterCode => 'Kodni kiritish';

  @override
  String wsetupDetail(String details) {
    return 'Tafsilotlar: $details';
  }

  @override
  String get wsetupErrTimeout => 'vaqtida javob kelmadi';

  @override
  String get wsetupErrRefused => 'ulanish rad etildi';

  @override
  String get wsetupDevOff =>
      '“Dasturchilar uchun” (Developer options) oʻchiq. “Telefon haqida” boʻlimida “Versiya raqami” (Build number) ustiga 7 marta bosing, soʻng qayting.';

  @override
  String get wsetupOpenAbout => 'Telefon haqida';

  @override
  String get wsetupNotifOff =>
      'Waaiya uchun bildirishnomalar oʻchirilgan, shuning uchun kodni bildirishnomada yozib boʻlmaydi. Ekranni ikkiga boʻling (bir yarmida Sozlamalar, ikkinchisida Waaiya) va “Kodni shu yerda kiriting” ni bosing.';

  @override
  String get wsetupCodeDialogTitle => 'Juftlash kodi';

  @override
  String get wsetupCodeDialogBody =>
      'Faqat ekranni ikkiga boʻlganda (bir yarmida Sozlamalar, ikkinchisida Waaiya): Sozlamalardan chiqsangiz, juftlash ekrani yopiladi va uning kodi ishlamay qoladi. “Qurilmani juftlash kodi bilan ulash” ostida koʻrsatilgan 6 xonali kodni yozing.';

  @override
  String get wsetupCodeOk => 'Juftlash';

  @override
  String get blurStrictTitle => 'Kim yopilmasdan qoladi';

  @override
  String blurStrictValue(String level) {
    return 'Kim yopilmasdan qoladi: $level';
  }

  @override
  String get blurStrict0 =>
      'Qatʼiy: faqat ilova erkak ekaniga deyarli ishongan odamlar';

  @override
  String get blurStrict1 =>
      'Muvozanatli: taxminan ikki baravar koʻp erkak yopilmaydi';

  @override
  String get blurStrict2 => 'Yumshoq: muvozanatlidan biroz koʻproq erkak';

  @override
  String get blurStrict0Short => 'qatʼiy';

  @override
  String get blurStrict1Short => 'muvozanatli';

  @override
  String get blurStrict2Short => 'yumshoq';

  @override
  String get blurStrictHelp =>
      'Ilova erkak ekaniga ishonmagan har qanday kishi yopiladi. Qatʼiy rejim 100 erkakdan taxminan 7 tasini yopmaydi; muvozanatli taxminan 14 tasini, yumshoq taxminan 16 tasini. Har bir yumshoqroq bosqich 100 ayoldan yana taxminan 1 tasini ham yopmasdan qoldiradi.';

  @override
  String get stateOnNotMuted =>
      'Asl ovoz hali oʻchirilmagan, shuning uchun musiqani filtrlangan ovoz bilan birga eshitasiz. Quyidagi bir martalik sozlashni yakunlang.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya hozir ijro etayotgan ilovaning asl ovozini oʻchira olmayapti, shuning uchun musiqa hali ham eshitilishi mumkin. Filtrlashni toʻxtatib, qayta boshlang. Agar shunday qolsa, diagnostika hisobotini yuboring (bu ekranning pastida).';

  @override
  String get stateTooSlow =>
      'Bu telefon jonli ovozni filtrlash uchun juda sekin, shuning uchun ovoz uziladi. Quyidagi “Havolani ochish” baribir ishlaydi: u videoni ijro etishdan oldin filtrlaydi.';

  @override
  String get stateMonoNote => 'Bu telefon ulgurishi uchun ovoz mono rejimda.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Filtrlashga ruxsat bermagani uchun ovozsiz qilindi: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Filtrlashga ruxsat bermagani uchun filtrsiz ijro etilmoqda: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android Waaiyaga boshqa ilovalarning ovozini bermadi. Qayta boshlash uchun tugmani bosing.';

  @override
  String get stateCaptureCancelled =>
      'Ishga tushirish Androidning ekranni ulashish haqidagi savolida bekor qilindi. Waaiya ovozni qabul qilishi uchun u yerda “Boshlash” ni tanlashingiz kerak. Hech narsa yozib olinmaydi va yuborilmaydi.';

  @override
  String get startNoSetupTitle => 'Musiqa baribir eshitiladi';

  @override
  String get startNoSetupBody =>
      'Bir martalik sozlash hali bajarilmagan. Usiz Waaiya asl ovozni oʻchira olmaydi: musiqa va filtrlangan ovozni birga eshitasiz.\n\n“Havolani ochish” hech qanday sozlashsiz ishlaydi.';

  @override
  String get startNoSetupSetup => 'Sozlashni bajarish';

  @override
  String get startNoSetupAnyway => 'Baribir boshlash';

  @override
  String get diagButton => 'Muammo bormi? Diagnostika hisoboti';

  @override
  String get diagTitle => 'Diagnostika hisoboti';

  @override
  String get diagNote =>
      'Waaiya bu telefonda nimalarni koʻrayotgani. Uni nusxalang yoki sizga yordam berayotgan kishiga ulashing. Ilovaning oʻzi hech narsa yubormaydi.';

  @override
  String get notifStoppedTitle => 'Waaiya toʻxtadi';

  @override
  String get notifStoppedText =>
      'Ovoz endi filtrlanmayapti. Qayta boshlash uchun bosing.';

  @override
  String get wsetupGuide => 'Rasmli qadamlar';

  @override
  String get navFilter => 'Filtr';

  @override
  String get navScreen => 'Ekran';

  @override
  String get navLinks => 'Havolalar';

  @override
  String get navSetup => 'Sozlash';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get setupDoneTitle => 'Sozlash tugadi';

  @override
  String get setupDoneBody =>
      'Waaiya boshqa ilovalarning asl ovozini oʻchira oladi. Buni faqat biror narsa oʻzgarganda qayta bajaring (sozlash bekor qilingan boʻlsa yoki Waaiya u yoʻqligini aytsa).';

  @override
  String get setupRedo => 'Sozlashni yana koʻrsatish';

  @override
  String get setupGo => 'Sozlashga oʻtish';

  @override
  String get helperTitle => 'Qoplamalar orqali bosish';

  @override
  String get helperBodyOff =>
      'Yordamsiz qoplama ostidagi bosishlarni toʻsib qoʻyadi. Waaiya yordamchisi qoplamalarni bosishlar ulardan oʻtib ketadigan qilib chizadi. Wi-Fi orqali debaglashni yoqing (Wi-Fi kerak) va tugmani bosing; birinchi marta sozlashdagidek bir marta juftlang. Telefon qayta ishga tushgandan keyin tugmani yana bosing.';

  @override
  String get helperStart => 'Waaiya yordamchisini ishga tushirish';

  @override
  String get helperOn =>
      'Waaiya yordamchisi qoplamalarni chizmoqda: bosishlar ulardan oʻtib ketadi. U telefon qayta ishga tushganda yoki USB orqali debaglash oʻchirilganda toʻxtaydi; shunda tugmani yana bosing.';

  @override
  String get helperShizukuOn =>
      'Qoplamalarni Shizuku chizmoqda: bosishlar ulardan oʻtib ketadi.';

  @override
  String get helperOrShizuku => 'Yoki Shizuku orqali:';

  @override
  String get filterOptionsTitle => 'Filtr sozlamalari';

  @override
  String get settingsGeneralTitle => 'Umumiy';

  @override
  String get desktopPreview =>
      'Namoyish rejimi: filtr mexanizmi bu kompyuterda hali ulanmagan. Tugma faqat ilova qanday ishlashini koʻrsatadi.';

  @override
  String actionFailed(String details) {
    return 'Bu ishlamadi: $details';
  }

  @override
  String get stateOnDetailNoDelay =>
      'Barcha ilovalardan musiqa asboblari olib tashlanmoqda.';

  @override
  String get engineErrorNoPactl =>
      'Ovoz vositalari topilmadi (pactl). Waaiya uchun PulseAudio yoki pipewire-pulse bilan PipeWire kerak.';

  @override
  String get engineErrorNoSoundServer =>
      'Ovoz serveri ishlamayapti (PulseAudio yoki PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'Bu tizimda filtrni fonda ishlatadigan systemd foydalanuvchi seansi yoʻq.';

  @override
  String get engineErrorNoOutput => 'Karnay yoki quloqchin topilmadi.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Filtrni oʻrnatib boʻlmadi. Tafsilotlar:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'Filtr ishga tushmadi. Tafsilotlar:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'Filtr xato bilan toʻxtadi. Tafsilotlar:\n$details';
  }

  @override
  String get autostartTitle => 'Tizimga kirganda ishga tushirish';

  @override
  String get autostartBody => 'Tizimga kirishingiz bilan ovozni filtrlash.';

  @override
  String get blurBodyDesktop =>
      'Waaiya ochiq turganda barcha oynalar ustidan ekrandagi odamlar va tasvirlarni yopadi (ovoz filtri yoqilgan yoki oʻchirilganidan qatʼi nazar ishlaydi). U shu kompyuterda ishlaydi; hech narsa hech qayerga yuborilmaydi. Waaiya oynasini yopish xiralashtirishni toʻxtatadi.';

  @override
  String get blurFailBodyDesktop =>
      'Yoqilgan: kompyuter juda sekin boʻlsa yoki xiralashtirish ishlamay qolsa, butun ekran yopiladi; sichqoncha bosishlari baribir ostidagi oynalarga yetib boradi. Oʻchirilgan: ekran yuqorisida qizil chiziq bilan koʻrinib turadi.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Xiralashtirish yoqilgan. Bu ish stoli xiralashtirishni oʻz ekran tasvirida koʻrsatadi, shuning uchun xiralashtirilgan joy sahna oʻzgarmaguncha xira boʻlib qoladi.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'Xiralashtirish bu ish stolida boshqa oynalar ustida chiza olmaydi. Tafsilotlar:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Ekranni ulashish oynasida ekraningizni tanlang va ruxsat bering. Waaiya faqat bir marta soʻraydi; tasvir shu kompyuterda qoladi.';

  @override
  String blurStatusExited(String details) {
    return 'Xiralashtirish kutilmaganda toʻxtadi. Qayta urinish uchun xiralashtirish variantlaridan birini oʻchirib, qayta yoqing. Tafsilotlar:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'Ayollar qoʻshigʻini aniqlagich yuklanmadi, shuning uchun bu variant yoqilganda ovozlar oʻchiriladi.';

  @override
  String get blurStatusUncovered =>
      'Bitta monitor xiralashtirish bilan yopilmagan: u xiralashtirishga ulashilmagan yoki keyinroq ulangan. Xiralashtirish variantlaridan birini oʻchirib, qayta yoqing va ekranni ulashish oynasida barcha ekranlarni tanlang.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'Bu oʻrnatishda xiralashtirish modellari yoʻq, shuning uchun u hech narsani yopa olmaydi; ekran yuqorisida qizil chiziq qoladi. Waaiyani qayta oʻrnating.';

  @override
  String get diagNoteDesktop =>
      'Waaiya bu kompyuterda nimalarni koʻrayotgani. Uni nusxalang va sizga yordam berayotgan kishiga bering. Ilovaning oʻzi hech narsa yubormaydi.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Tavsiya etiladi. Agar filtrlash oʻzidan oʻzi toʻxtasa (siz emas, xato tufayli), boshqa ilovalar musiqani filtrsiz chalish oʻrniga, siz qayta boshlamaguningizcha yoki “Toʻxtatish” ni bosmaguningizcha ovozsiz qoladi.';

  @override
  String get settingStereoBodyDesktop =>
      'Oʻchirilgan: mono, u kompyuterni kamroq band qiladi. Yoqilgan: chap va oʻng tomonlarni alohida saqlaydi. Kompyuter stereo uchun juda sekin boʻlsa, u oʻzi monoga oʻtadi.';

  @override
  String get linkEntryBodyDesktop =>
      'YouTube, TikTok yoki Instagram havolasini qoʻying va uni filtr yoqilgan holda koʻring yoki musiqasiz saqlang.';

  @override
  String get linkEntryBodyWatch =>
      'YouTube, TikTok yoki Instagram havolasini qoʻying va uni brauzeringizda filtr yoqilgan holda koʻring.';

  @override
  String get linkWatchNoteDesktop =>
      'Brauzeringizda ochiladi. Waaiya avval filtrni ishga tushiradi, shuning uchun u yerda ham musiqa olib tashlanadi.';

  @override
  String get linkFilterFailed =>
      'Filtr ishga tushmadi, shuning uchun havola ochilmadi. Uni Filtr sahifasida ishga tushiring va qayta urinib koʻring.';

  @override
  String get linkSavedVideoDesktop => 'Videolar (Videos) jildingizda: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'Musiqa (Music) jildingizda: Waaiya';

  @override
  String get linkShowInFolder => 'Jildda koʻrsatish';

  @override
  String get linkSingingNote =>
      'Sozlamalaringizdagidek, ayollar qoʻshigʻi ham oʻchiriladi.';
}
