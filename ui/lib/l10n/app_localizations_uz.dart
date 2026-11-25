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
      'Ilovalaringiz ovozidan musiqa asboblarini olib tashlaydi, nutq va tilovatni saqlaydi.';

  @override
  String get onboardTitle => 'Xush kelibsiz';

  @override
  String get onboardBody =>
      'Waaiya bu telefondagi ilovalar ovozidan musiqa asboblarini olib tashlaydi. Nutq va Qurʼon tilovati saqlanadi. Qoʻshiq aytayotgan ovozlar ham olib tashlanadi.';

  @override
  String get onboardQuestion => 'Men';

  @override
  String get genderMan => 'Erkakman';

  @override
  String get genderWoman => 'Ayolman';

  @override
  String get onboardWhy =>
      'Bu faqat qaysi qoʻshimcha sozlamalarni koʻrishingizni belgilaydi. Masalan, “Ayollar qoʻshigʻini oʻchirish” faqat erkaklarga taklif qilinadi. Keyinroq oʻzgartirishingiz mumkin.';

  @override
  String get stateOnTitle => 'Filtrlash yoqilgan';

  @override
  String get stateOffTitle => 'Filtrlash oʻchirilgan';

  @override
  String get stateStarting => 'Ishga tushirilmoqda…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Ilovalaringiz ovozi filtrlanmoqda. U taxminan $delayMs ms kech keladi (1000 ms — bu bir soniya).';
  }

  @override
  String get stateOffDetail => 'Boshlash uchun tugmani bosing.';

  @override
  String get stateModelFailed =>
      'Filtr yuklanmadi, shuning uchun ovoz filtrsiz ijro etilish oʻrniga oʻchirildi.';

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
      'Android ekraningizni ulashishni soʻraydi. Hech narsa yozib olinmaydi va yuborilmaydi.';

  @override
  String get needRecordAudio =>
      'Boshqa ilovalarning ovozini qabul qilishi uchun Waaiyaga mikrofon ruxsati kerak. U hech qachon sizni yozib olmaydi.';

  @override
  String get setupBannerTitle => 'Yana bir qadam';

  @override
  String get setupBannerBody =>
      'Bir martalik sozlashsiz musiqa va filtrlangan ovozni birga eshitasiz.';

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
  String get computerWeb =>
      'Eng osoni: kompyuterda Chrome yoki Edge’da waaiya.mssid.org/usb sahifasini oching, “USB orqali debaglash” ni yoqing va telefonni kabel bilan ulang. Hech narsa o‘rnatish shart emas, Android 10 da ham ishlaydi. Yoki adb o‘rnatilgan bo‘lsa:';

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
  String get settingSingingBody =>
      'Masalan, ayol aytgan qoʻshiq oʻchiriladi, lekin maʼruza qilayotgan ayolning ovozi baribir eshitiladi.';

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
  String get playerTitle => 'Ovozi va tasviri sinxron videolar';

  @override
  String get playerBody =>
      'Videoni filtrlangan holda, ovozi va tasviri sinxron, jonli filtr kechikishisiz koʻrish uchun uni Waaiyaga ulashing (yoki “Open with” / “… orqali ochish” bilan Waaiyada oching).';

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
      'Filtrlash yoqilganda ekrandagi odamlar va tasvirlarni yopadi. U telefonning oʻzida ishlaydi; hech narsa hech qayerga yuborilmaydi.';

  @override
  String get blurOnTitle => 'Xiralashtirish yoqilgan';

  @override
  String get blurOffTitle => 'Xiralashtirish oʻchirilgan';

  @override
  String get blurStartCd => 'Xiralashtirishni boshlash';

  @override
  String get blurStopCd => 'Xiralashtirishni toʻxtatish';

  @override
  String get blurOffDetail =>
      'Boshlash uchun tugmani bosing. Filtrlash ham u bilan birga boshlanadi.';

  @override
  String get blurWhatTitle => 'Nimani xiralashtirish';

  @override
  String get blurWomenTitle => 'Ayollar tasvirlarini xiralashtirish';

  @override
  String get blurWomenBody =>
      'Butun tanani yopadi. Agar ilova odamning erkak ekaniga ishonch hosil qila olmasa, uni ham yopadi.';

  @override
  String get blurNudityTitle => 'Odobsiz tasvirlarni xiralashtirish';

  @override
  String get blurNudityBody =>
      'Har qanday kishining yalangʻochligi yoki ochiq-sochiq kiyimi: butun ekran yopiladi.';

  @override
  String get blurFailTitle => 'Xiralashtirish ulgurmasa, ekranni yopish';

  @override
  String get blurFailBody =>
      'Yoqilgan: telefon juda sekin boʻlsa yoki xiralashtirish ishlamay qolsa, butun ekran yopiladi. Oʻchirilgan: ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get blurSetupManual => 'Android sozlamalarida ruxsat berish';

  @override
  String get blurStatusNeedsSetup =>
      'Xiralashtirish uchun Waaiya boshqa ilovalar ustida chizishi kerak. Eng yaxshisi: “Sozlashga oʻtish”, shunda bosishlaringiz xiralik ostidagi ilovaga yetib boradi. Yoki “Android sozlamalarida ruxsat berish”, lekin unda xiralashtirilgan joyga bosish hech narsa qilmaydi.';

  @override
  String get blurStatusNeedsOverlay =>
      'Xiralashtirish uchun Waaiya boshqa ilovalar ustida chizishi kerak. Eng yaxshisi: bir martalik sozlashni bajaring, shunda bosishlaringiz xiralik ostidagi ilovaga yetib boradi. Yoki Android sozlamalarida “Boshqa ilovalar ustidan ochish” (Display over other apps) uchun ruxsat bering, lekin unda xiralashtirilgan joyga bosish hech narsa qilmaydi.';

  @override
  String get blurFailUnavailable =>
      'Hozircha nofaol: butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin. Waaiya yordamchisini ishga tushiring (Android 12 yoki yangiroq) va bu sozlama yoqiladi: shunda qoplamalar bosishlar ulardan oʻtib ketadigan qilib chiziladi. Ungacha xiralashtirish ulgurmasa, ekran ogohlantirish bilan koʻrinib turadi.';

  @override
  String get blurFailNeedsA11y =>
      'Hozircha nofaol: butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin. Waaiya yordamchisini ishga tushiring (Android 12 yoki yangiroq) yoki Android sozlamalarida “Waaiya xiralashtirish” maxsus imkoniyatlar xizmatini yoqing va bu sozlama yoqiladi. Ungacha ekran ogohlantirish bilan koʻrinib turadi.';

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
  String get step2Guide => 'Shizuku qanday ishga tushiriladi';

  @override
  String get blurFailOldAndroid =>
      'Nofaol: Androidning bu versiyasida butun ekranni yopuvchi qoplama har qanday bosishni toʻsib qoʻyadi va siz telefonni boshqara olmay qolishingiz mumkin (bosishlar oʻtib ketadigan qoplamalar uchun Android 12 yoki yangiroq kerak). Xiralashtirish ulgurmasa, ekran ogohlantirish bilan koʻrinib turadi.';

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
  String get blurStrictTitle =>
      'Erkak koʻrsatilishi uchun qancha ishonch kerak';

  @override
  String blurStrictValue(String level) {
    return 'Erkak koʻrsatilishi uchun qancha ishonch kerak: $level';
  }

  @override
  String get blurStrict0 =>
      'Qatʼiy: faqat ilova erkak ekaniga deyarli ishongan odamlar';

  @override
  String get blurStrict1 =>
      'Muvozanatli: taxminan ikki baravar koʻp erkak koʻrsatiladi';

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
      'Odam faqat ilova uning erkak ekaniga ishonch hosil qilgandagina koʻrsatiladi; qolgan hamma xiralashtiriladi. Qatʼiy rejim 100 erkakdan taxminan 7 tasini koʻrsatadi, muvozanatli taxminan 14 tasini, yumshoq taxminan 16 tasini. Baʼzi ayollar baribir oʻtkazib yuboriladi; har bir yumshoqroq bosqich 100 tadan yana taxminan 1 tasini oʻtkazib yuboradi.';

  @override
  String get stateOnNotMuted =>
      'Asl ovoz hali oʻchirilmagan, shuning uchun musiqani filtrlangan ovoz bilan birga eshitasiz. “Sozlash” sahifasidagi bir martalik sozlashni yakunlang.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya hozir ijro etayotgan ilovaning asl ovozini oʻchira olmayapti, shuning uchun musiqa hali ham eshitilishi mumkin. Filtrlashni toʻxtatib, qayta boshlang. Agar shunday qolsa, diagnostika hisobotini yuboring (Sozlamalar).';

  @override
  String get stateTooSlow =>
      'Bu telefon jonli ovozni filtrlash uchun juda sekin, shuning uchun ovoz uziladi. “Havolalar” sahifasidagi “Havolani ochish” baribir ishlaydi: u videoni ijro etishdan oldin filtrlaydi.';

  @override
  String get stateMonoNote => 'Bu telefon ulgurishi uchun ovoz mono rejimda.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Ovozsiz qilindi, chunki bular filtrlashga ruxsat bermaydi: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Filtrsiz ijro etilmoqda, chunki bular filtrlashga ruxsat bermaydi: $apps.';
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
      'Waaiya bu telefonda nimalarni koʻrayotgani. Uni nusxalang yoki sizga yordam berayotgan kishiga ulashing. Waaiya uni oʻzi yubormaydi: kim olishini siz tanlaysiz.';

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
  String get helperTitle => 'Xiralashtirilgan joylar orqali bosish';

  @override
  String get helperBodyOff =>
      'Yordamsiz qoplama ostidagi bosishlarni toʻsib qoʻyadi. Waaiya yordamchisi qoplamalarni bosishlar ulardan oʻtib ketadigan qilib chizadi. Wi-Fi orqali debaglashni yoqing (Wi-Fi kerak) va tugmani bosing; birinchi marta sozlashdagidek bir marta juftlang. Telefon qayta ishga tushgandan keyin tugmani yana bosing.';

  @override
  String get helperStart => 'Waaiya yordamchisini ishga tushirish';

  @override
  String get helperOn =>
      'Waaiya yordamchisi xiralashtirishni chizmoqda: bosishlar undan oʻtib ketadi. U telefon qayta ishga tushganda yoki “USB orqali debaglash” (“Dasturchilar uchun” boʻlimidagi alohida kalit) oʻchirilganda toʻxtaydi; shunda tugmani yana bosing.';

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
  String get simpleTitle =>
      'Oddiy rejim (sinov): “Dasturchilar uchun” boʻlimisiz';

  @override
  String get simpleBody =>
      'Quyidagi sozlash juda qiyin boʻlgan telefonlar uchun. Waaiya filtrlayotganda telefonning media ovozini oʻchiradi va filtrlangan ovozni boshqa ovoz kanalida ijro etadi. Ovoz tugmalaringiz Waaiya ovoz balandligini sozlaydi. Android har bir ishga tushirishda ekranni ulashishni soʻraydi. Filtrlash toʻxtaganda media ovozi qaytadi.';

  @override
  String get simpleSwitch => 'Oddiy rejimdan foydalanish';

  @override
  String simpleChannelTitle(String channel) {
    return 'Ovoz kanali: $channel';
  }

  @override
  String get simpleChannelAlarm => 'Budilnik';

  @override
  String get simpleChannelNotification => 'Bildirishnoma';

  @override
  String get simpleChannelHelp =>
      'Hech narsa eshitilmasa yoki quloqchin ulangan boʻlsa-da ovoz telefon karnayidan chiqsa, boshqa kanalni sinab koʻring. Telefon tebranish rejimida yoki “Bezovta qilinmasin” yoqilgan boʻlsa, Bildirishnoma kanali ovozsiz boʻladi.';

  @override
  String get simpleTestNote =>
      'Bu sinov. Uni sinab koʻrgach (karnay, quloqchin, Bluetooth), iltimos, Sozlamalardan diagnostika hisobotini yuboring.';

  @override
  String get simpleOnDetail =>
      'Oddiy rejim (sinov): Waaiya filtrlayotganda media ovozi oʻchiriladi.';

  @override
  String get worshipPrayerFajr => 'Bomdod';

  @override
  String get worshipPrayerSunrise => 'Quyosh chiqishi';

  @override
  String get worshipPrayerDhuhr => 'Peshin';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Shom';

  @override
  String get worshipPrayerIsha => 'Xufton';

  @override
  String get worshipEndSilent => 'Jimlikni hozir tugatish';

  @override
  String get worshipUnmute => 'Ovozni hozir yoqish';

  @override
  String get worshipSmsDefault =>
      'Hozir namoz vaqti, javob bera olmayman. Keyinroq oʻzim qoʻngʻiroq qilaman.';

  @override
  String get updateTitle => 'Ilova yangilanishlari';

  @override
  String get updateAuto => 'Kuniga bir marta yangi versiyani tekshirish';

  @override
  String get updateAutoBody =>
      'Waaiya waaiya.mssid.org saytidan yangiroq versiya bor-yoʻqligini soʻraydi va boshqa hech narsa yubormaydi. Hozir yangilash tugmasini bosmaguningizcha hech narsa yuklab olinmaydi.';

  @override
  String get updateCheck => 'Hozir tekshirish';

  @override
  String get updateChecking => 'Tekshirilmoqda…';

  @override
  String updateNone(String version) {
    return 'Sizda eng soʻnggi versiya ($version).';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'Waaiya $latest chiqdi. Sizda $current.';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'Yuklab olish: $size, faqat oʻzgarishlar (toʻliq ilova $full).';
  }

  @override
  String updateSizeFull(String size) {
    return 'Yuklab olish: $size.';
  }

  @override
  String get updateNow => 'Hozir yangilash';

  @override
  String updateDownloading(String progress) {
    return 'Yuklab olinmoqda: $progress';
  }

  @override
  String get updatePreparing => 'Yangilanish tayyorlanmoqda…';

  @override
  String get updateInstalling =>
      'Android koʻrsatgan ekranda oʻrnatishni tasdiqlang.';

  @override
  String get updateStopsFilter =>
      'Oʻrnatish filtrlashni toʻxtatadi. Yangilanishdan keyin uni qayta yoqing.';

  @override
  String get updatePermission =>
      'Waaiya’ga yangilanishlarini oʻrnatishga ruxsat bering, soʻng yana Hozir yangilash tugmasini bosing.';

  @override
  String get updateFailed =>
      'Yangilanishni yakunlab boʻlmadi. Keyinroq urinib koʻring yoki saytdan yuklab oling.';

  @override
  String get updateOpenPage => 'Yuklab olish sahifasini ochish';

  @override
  String get updateCheckFailed =>
      'Hozir tekshirib boʻlmadi. Keyinroq urinib koʻring.';

  @override
  String get moveOldTitle => 'Waaiya ko‘chdi';

  @override
  String get moveOldBody =>
      'Endi Waaiya Android’da yangi ilova sifatida chiqadi (o‘sha Waaiya, yangi nom bilan), bu ilova esa endi yangilanmaydi. Yangisini o‘rnating: sozlamalaringiz ham ko‘chadi. So‘ng uning bir martalik sozlashini bajaring va buni o‘chiring.';

  @override
  String get moveOldInstalled =>
      'Yangi Waaiya o‘rnatildi. Uni oching: u sozlamalaringizni oladi. Bir martalik sozlashni bajaring, so‘ng ikkalasi hech qachon birga filtrlamasligi uchun bu eskisini o‘chiring.';

  @override
  String get moveInstall => 'Yangi Waaiya’ni o‘rnatish';

  @override
  String get moveOpenNew => 'Yangi Waaiya’ni ochish';

  @override
  String get moveRemoveThis => 'Bu eski Waaiya’ni o‘chirish';

  @override
  String get moveNewTitle => 'Eski Waaiya hali ham o‘rnatilgan';

  @override
  String get moveNewBody =>
      'Eski Waaiya (0.2.15 versiyasidan oldingi) hali ham bu telefonda. Ikkalasi hech qachon birga filtrlamasligi uchun uni o‘chiring.';

  @override
  String get moveNewImported => 'Sozlamalaringiz undan olib kelindi.';

  @override
  String get moveRemoveOld => 'Eski Waaiya’ni o‘chirish';

  @override
  String get desktopPreview =>
      'Namoyish rejimi: filtr mexanizmi bu kompyuterda hali ulanmagan. Tugma faqat ilova qanday ishlashini koʻrsatadi.';

  @override
  String actionFailed(String details) {
    return 'Bu ishlamadi: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Ilovalaringiz ovozi filtrlanmoqda.';

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
      'Waaiya bu kompyuterda nimalarni koʻrayotgani. Uni nusxalang va sizga yordam berayotgan kishiga bering. Waaiya uni oʻzi yubormaydi: kim olishini siz tanlaysiz.';

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

  @override
  String get singingKeepTitle => 'Qoʻshiqni saqlash (sinov)';

  @override
  String get singingKeepBody =>
      'Musiqa asboblari olib tashlanadi, lekin qoʻshiq aytayotgan ovozlar saqlanadi, shuning uchun orqa fonida nashid boʻlgan maʼruzada nashid ovozi ham qoladi; bu maqbulmi yoki yoʻqmi, oʻzingiz hal qilasiz.';

  @override
  String get singingKeepNoModel =>
      'Bu versiyada qoʻshiq modeli yoʻq, shuning uchun bu yoqilganda ovoz chiqmaydi. Uni oʻchiring.';

  @override
  String get fixFilterAppsTitle => 'Filtrsiz eshitiladigan ilovalar';

  @override
  String get fixFilterAppsBody =>
      'Bu yerda tanlagan ilovalaringiz oʻz holicha ijro etiladi: filtr ham yoʻq, ovozsiz qilish ham yoʻq. Masalan, video qoʻngʻiroq ilovasi, shunda qoʻngʻiroqlarda kechikish boʻlmaydi.';

  @override
  String get fixAddApp => 'Ilova qoʻshish';

  @override
  String fixRemoveApp(Object app) {
    return '$app ilovasini olib tashlash';
  }

  @override
  String get fixNoApps => 'Hech qanday ilova tanlanmagan.';

  @override
  String get fixPickTitle => 'Ilovani tanlang';

  @override
  String get fixPickEmpty => 'Boshqa ilova topilmadi.';

  @override
  String get fixPickPlayingDesktop =>
      'Hozir ovoz chiqarayotgan ilovalar va allaqachon tanlanganlari.';

  @override
  String get fixCancel => 'Bekor qilish';

  @override
  String get fixBlurAppsTitle => 'Xiralashtirilmaydigan ilovalar';

  @override
  String get fixBlurAppsBody =>
      'Shu ilovalardan biri butun ekranni egallab turganda qoplamalar boʻlmaydi, masalan, xarita ilovasi yoki bankingiz ilovasi. Undan chiqishingiz bilan yoki Waaiya qaysi ilova koʻrsatilayotganiga ishonch hosil qila olmaganda, qoplamalar qaytadi.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Bir martalik sozlash kerak: usiz Waaiya ekranda qaysi ilova ochiqligini bila olmaydi, shuning uchun xiralashtirish hamma joyda yoqilgan qoladi.';

  @override
  String get fixBlurAppsHelperMode =>
      'Waaiya yordamchisi ishlamayapti, shuning uchun ekrandagi ilovani aniqlab boʻlmaydi. Yordamchi Sozlash sahifasidan qayta ishga tushirilmaguncha xiralashtirish hamma joyda yoqilgan qoladi.';

  @override
  String get fixHandTitle => 'Joyni qoʻlda yopish';

  @override
  String get fixHandBody =>
      'Xiralashtirish ishlayotganda ekranning bir qismini oʻzingiz yopishingiz mumkin, masalan, xiralashtirish oʻtkazib yuborgan rasmni: “Joyni yopish” tugmasini bosing va barmogʻingizni uning ustidan suring. Siz uni olib tashlamaguningizcha yoki xiralashtirish toʻxtamaguncha u yopiq qoladi.';

  @override
  String get fixHandNotRunning =>
      'Xiralashtirish ishlayotganda mavjud: filtrlash yoqilgan va xiralashtirish variantlaridan biri yoqilgan boʻlishi kerak.';

  @override
  String get fixCoverArea => 'Joyni yopish';

  @override
  String fixRemoveCovers(Object count) {
    return 'Qoʻlda qoʻyilgan qoplamalarni olib tashlash ($count)';
  }

  @override
  String get fixNoteTitle => 'Xatoni qayd etish';

  @override
  String get fixNoteBody =>
      'Waaiya biror narsada xato qilsa, nima boʻlganini bosing, masalan, “Musiqa oʻtib ketdi”. Sababni topishga yordam berish uchun qaydda vaqt, ilova va sozlamalar saqlanadi. U shu qurilmada qoladi va hech qachon yuborilmaydi.';

  @override
  String get fixMissedSound => 'Musiqa oʻtib ketdi';

  @override
  String get fixWrongSound => 'Ovoz xato bilan olib tashlandi';

  @override
  String get fixMissedScreen => 'Nimadir yopilmadi';

  @override
  String get fixWrongScreen => 'Xato bilan yopildi';

  @override
  String fixNoted(Object count) {
    return 'Qayd etildi. Bu qurilmadagi qaydlar: $count.';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Bu qurilmadagi qaydlar: $count';
  }

  @override
  String get fixNotesShow => 'Qaydlarni koʻrsatish';

  @override
  String get fixNotesDelete => 'Qaydlarni oʻchirish';

  @override
  String get fixNotesDeleteAsk =>
      'Barcha qaydlar oʻchirilsinmi? Buni ortga qaytarib boʻlmaydi.';

  @override
  String get fixNotesTitle => 'Xatolar haqida qaydlar';

  @override
  String get worshipTitle => 'Namoz vaqtlari';

  @override
  String get worshipBody =>
      'Ixtiyoriy. Siz tanlagan joy boʻyicha shu telefonda hisoblanadi. Hech narsa yuborilmaydi.';

  @override
  String worshipPlace(Object place) {
    return 'Joy: $place';
  }

  @override
  String get worshipPlaceNone => 'Joy: tanlanmagan';

  @override
  String get worshipChoose => 'Tanlash';

  @override
  String get worshipPlaceSearch => 'Shaharni qidirish';

  @override
  String get worshipPlaceNoMatch =>
      'Shahar topilmadi. Buning oʻrniga koordinatalarni kiritishingiz mumkin.';

  @override
  String get worshipPlaceCustom => 'Koordinatalarni kiritish';

  @override
  String get worshipLat => 'Kenglik (shimol +, janub −)';

  @override
  String get worshipLon => 'Uzunlik (sharq +, gʻarb −)';

  @override
  String get worshipZone => 'Vaqt mintaqasi, masalan Asia/Tashkent';

  @override
  String get worshipCustomInvalid => 'Raqamlar va vaqt mintaqasini tekshiring.';

  @override
  String get worshipPlaceInvalid =>
      'Bu joydan foydalanib boʻlmaydi. Uni qaytadan tanlang.';

  @override
  String worshipMethod(Object method) {
    return 'Hisoblash: $method';
  }

  @override
  String get worshipMethodTitle => 'Hisoblash usuli';

  @override
  String get worshipMethodNote =>
      'Shahar joylashgan davlatga qarab tanlangan. Masjidingiz amal qiladigan usulni tanlang.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Asr vaqti';

  @override
  String get worshipAsrStandard => 'Jumhur (shofeʼiy, molikiy, hanbaliy)';

  @override
  String get worshipAsrHanafi => 'Hanafiy';

  @override
  String get worshipMethodMwl => 'Islom olami ligasi';

  @override
  String get worshipMethodIsna => 'Shimoliy Amerika Islom jamiyati (ISNA)';

  @override
  String get worshipMethodEgypt => 'Misr umumiy geodeziya boshqarmasi';

  @override
  String get worshipMethodUmmAlQura => 'Ummul-Quro, Makka';

  @override
  String get worshipMethodKarachi => 'Islom fanlari universiteti, Karachi';

  @override
  String get worshipMethodTehran => 'Tehron universiteti Geofizika instituti';

  @override
  String get worshipMethodGulf => 'Koʻrfaz mintaqasi';

  @override
  String get worshipMethodKuwait => 'Quvayt';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapur (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turkiya (Diyanet)';

  @override
  String get worshipMethodFrance => 'Fransiya (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Marokash (Vaqflar vazirligi)';

  @override
  String get worshipMethodIndonesia => 'Indoneziya (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malayziya (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubay';

  @override
  String get worshipToday => 'Bugun';

  @override
  String get worshipNoTimes =>
      'Bugun bu yerda namoz vaqtlari yoʻq: quyosh chiqmaydi yoki botmaydi.';

  @override
  String get worshipSilentTitle => 'Namoz vaqtlarida ovozsiz';

  @override
  String get worshipSilentBody =>
      'Har bir namoz vaqtida telefon quyidagi daqiqalar davomida ovozsiz boʻladi (“Bezovta qilinmasin”), soʻng hammasi avvalgi holiga qaytadi. Masalan, Peshin vaqtida soat 12:00 dan 12:20 gacha.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Ovozsiz: $minutes daqiqa';
  }

  @override
  String get worshipMuteTitle => 'Azon vaqtida media ovozini oʻchirish';

  @override
  String get worshipMuteBody =>
      'Har bir namoz vaqtida media ovozi (video, musiqa, oʻyinlar) quyidagi daqiqalar davomida oʻchiriladi. Bildirishnoma orqali uni darhol yoqish mumkin.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Oʻchirilgan: $minutes daqiqa';
  }

  @override
  String get worshipMinutesTitle => 'Davomiylik';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes daqiqa';
  }

  @override
  String get worshipNeedPlace => 'Avval joyni tanlang.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Keyingisi: $prayer, $time da';
  }

  @override
  String worshipSilentNow(Object time) {
    return '$time gacha ovozsiz.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Media ovozi $time gacha oʻchirilgan.';
  }

  @override
  String get worshipDndNeeded =>
      'Waaiyaga “Bezovta qilinmasin” rejimini oʻzgartirishga ruxsat bering, aks holda telefon ovozsiz rejimga oʻta olmaydi.';

  @override
  String get worshipAllow => 'Ruxsat berish';

  @override
  String get worshipExactNeeded =>
      'Waaiya uchun “Signallar va eslatmalar” ruxsat etilmagan, shuning uchun har bir oʻzgarish 10 daqiqagacha, telefon uyqu rejimida boʻlsa esa undan ham koʻproq kechikishi mumkin.';

  @override
  String get worshipNotificationsNeeded =>
      'Bildirishnomalar oʻchirilgan: telefon qachon ovozsiz rejimga oʻtganini va ovoz qachon qaytganini koʻrmaysiz.';

  @override
  String get worshipTonesTitle =>
      'Oddiy qoʻngʻiroq ohangi va bildirishnoma ovozi';

  @override
  String get worshipTonesBody =>
      'Waaiya qoʻngʻiroq ohangi yoki bildirishnoma ovozlarini filtrlay olmaydi, faqat almashtira oladi. Musiqasiz oddiy ohangni tanlang:';

  @override
  String worshipToneRing(Object number) {
    return 'Oddiy qoʻngʻiroq ohangi $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Oddiy bildirishnoma ovozi $number';
  }

  @override
  String get worshipTonePlay => 'Eshitish';

  @override
  String get worshipToneSet => 'Oʻrnatish';

  @override
  String get worshipToneInUse => 'Ishlatilmoqda';

  @override
  String get worshipToneDone => 'Bajarildi.';

  @override
  String get worshipTonePermission =>
      'Waaiyaga tizim sozlamalarini oʻzgartirishga ruxsat bering, qaytib keling va yana bosing.';

  @override
  String get worshipToneFailed =>
      'Bu telefon Waaiyaga uni oʻzgartirishga ruxsat bermadi. Ovoz sozlamalarida “Waaiya plain” nomli ohangni tanlang.';

  @override
  String get worshipOpenSound => 'Ovoz sozlamalarini ochish';

  @override
  String get worshipSmsTitle =>
      'Namoz paytida qoʻngʻiroqlarga SMS bilan javob berish';

  @override
  String get worshipSmsBody =>
      'Har bir namoz vaqtidan keyingi ovozsiz daqiqalarda javobsiz jiringlab qolgan qoʻngʻiroqqa bitta SMS yuboriladi. Har bir raqamga har namozda bir marta; yashirin raqamlarga va qisqa raqamlarga hech qachon yuborilmaydi.';

  @override
  String worshipSmsDelay(Object seconds) {
    return '$seconds soniya jiringlagandan keyin';
  }

  @override
  String get worshipSmsDelayTitle =>
      'SMS yuborilishidan oldin necha soniya jiringlasin';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds soniya';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Xabar: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Xabaringiz';

  @override
  String get worshipSmsTextDefault => 'Standart xabarni ishlatish';

  @override
  String get worshipSmsCost =>
      'Har bir javob SIM-kartangizdan tarifingiz narxida yuboriladigan oddiy SMS. Rouming paytida hech narsa yuborilmaydi.';

  @override
  String get worshipSmsRoaming => 'Hozir rouming: SMS yuborilmaydi.';

  @override
  String get worshipSmsLogTitle =>
      'Yuborilgan javoblar (faqat shu telefonda saqlanadi)';

  @override
  String get worshipContinue => 'Davom etish';

  @override
  String get worshipWhyDnd =>
      'Namoz vaqtlarida telefonni ovozsiz qilish uchun keyingi sahifada Waaiyaga “Bezovta qilinmasin” rejimiga kirishga ruxsat bering.';

  @override
  String get worshipWhyExact =>
      'Aynan oʻz vaqtida ishlashi uchun keyingi sahifada Waaiyaga signallar va eslatmalarni oʻrnatishga ruxsat bering. Busiz oʻzgarishlar 10 daqiqagacha kechikishi mumkin.';

  @override
  String get worshipWhyNotifications =>
      'Har bir oʻzgarishni koʻrish va uni bekor qila olish uchun bildirishnomalarga ruxsat bering.';

  @override
  String get worshipWhyWrite =>
      'Qoʻngʻiroq ohangi yoki bildirishnoma ovozini oʻzgartirish uchun keyingi sahifada Waaiyaga tizim sozlamalarini oʻzgartirishga ruxsat bering.';

  @override
  String get worshipWhyPhone =>
      'Qoʻngʻiroq jiringlayotganini va uning raqamini bilish uchun Waaiyaga “Telefon” va “Chaqiruvlar jurnali” ruxsatlari kerak. Javobingizdan boshqa hech narsa telefondan chiqmaydi.';

  @override
  String get worshipWhySms =>
      'Javobingizni yuborish uchun Waaiyaga SMS yuborish ruxsati kerak. U faqat shu javobni, har bir raqamga har namozda koʻpi bilan bir marta yuboradi.';

  @override
  String get worshipMissingDnd =>
      '“Bezovta qilinmasin” rejimiga kirishga ruxsat berilmadi, shuning uchun ovozsiz rejim oʻchiq qoladi.';

  @override
  String get worshipMissingPhone =>
      '“Telefon” va “Chaqiruvlar jurnali” ruxsatlari berilmadi, shuning uchun SMS bilan javob berish oʻchiq qoladi.';

  @override
  String get worshipMissingSms =>
      'SMS yuborishga ruxsat berilmadi, shuning uchun SMS bilan javob berish oʻchiq qoladi.';

  @override
  String get worshipTryAgain => 'Qayta urinish';

  @override
  String get protectTitle => 'Zaif damlar uchun himoya';

  @override
  String get protectBody =>
      'Filtrni oʻchirgingiz kelib qolishi mumkin boʻlgan zaif lahza uchun. Hozir, xotirjam paytingizda, kutish vaqtini tanlang: shunda toʻxtatish tugmasi filtrni darhol toʻxtatmaydi va vaqt tugagach yana qaror qilasiz. Ota-ona PIN kod ham qoʻyishi mumkin.';

  @override
  String protectDelay(Object value) {
    return 'Oʻchirishdan oldin kutish: $value';
  }

  @override
  String get protectDelayTitle => 'Oʻchirishdan oldin kutish';

  @override
  String get protectDelayBody =>
      'Masalan, 30 daqiqa bilan: toʻxtatish tugmasini bosasiz, lekin filtr ishlashda davom etadi. 30 daqiqadan soʻng bu sahifa hali ham toʻxtatmoqchimisiz, deb soʻraydi. 15 daqiqa ichida “Tasdiqlash” tugmasini bossangiz, u toʻxtaydi; aks holda hech narsa oʻzgarmaydi. Qoplamani yoki boshqa himoyani oʻchirish ham shunday. Biror narsani yoqish har doim darhol ishlaydi.';

  @override
  String get protectDelayOff => 'Yoʻq';

  @override
  String get protectDelay1m => '1 daqiqa';

  @override
  String get protectDelay5m => '5 daqiqa';

  @override
  String get protectDelay15m => '15 daqiqa';

  @override
  String get protectDelay30m => '30 daqiqa';

  @override
  String get protectDelay1h => '1 soat';

  @override
  String get protectDelay4h => '4 soat';

  @override
  String get protectDelay24h => '24 soat';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes daqiqa';
  }

  @override
  String get protectPinNone => 'PIN-kod: oʻrnatilmagan';

  @override
  String get protectPinIsSet => 'PIN-kod: oʻrnatilgan';

  @override
  String get protectPinSet => 'PIN-kod oʻrnatish';

  @override
  String get protectPinRemove => 'Olib tashlash';

  @override
  String get protectPinBody =>
      'PIN-kod oʻrnatilgan boʻlsa, filtrni toʻxtatish yoki istalgan himoyani oʻchirish avval PIN-kodni soʻraydi. Masalan, ota-ona bola Waaiyada filtrni oʻchira olmasligi uchun PIN-kod oʻrnatadi (u toʻxtata olmaydigan narsalar quyida keltirilgan). Kutish muddatini yoki PIN-kodni oʻzgartirish ham uni soʻraydi.';

  @override
  String get protectPinForgot =>
      'PIN-kodni yozib, xavfsiz joyda saqlang: agar u unutilsa, uni tiklab boʻlmaydi. Yagona yoʻl — Waaiya maʼlumotlarini tozalash yoki uni qayta oʻrnatish, bu esa uning barcha sozlamalarini ham oʻchirib yuboradi.';

  @override
  String get protectPinTitle => 'PIN-kodni kiriting';

  @override
  String get protectPinNewTitle => 'PIN-kodni tanlang';

  @override
  String get protectPinChangeTitle => 'PIN-kodni oʻzgartirish';

  @override
  String get protectPinCurrent => 'Joriy PIN-kod';

  @override
  String get protectPinNew => 'Yangi PIN-kod (4 dan 8 tagacha raqam)';

  @override
  String get protectPinAgain => 'Yangi PIN-kod yana bir marta';

  @override
  String get protectPinBad => '4 dan 8 tagacha raqam kiriting.';

  @override
  String get protectPinDiffer => 'Ikkala yangi PIN-kod bir xil emas.';

  @override
  String protectPinWrong(Object count) {
    return 'PIN-kod notoʻgʻri. Pauzagacha qolgan urinishlar: $count.';
  }

  @override
  String protectLocked(Object time) {
    return 'Notoʻgʻri urinishlar juda koʻp. $time da qayta urinib koʻring.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Bekor qilish';

  @override
  String get protectCancelChange => 'Oʻzgarishni bekor qilish';

  @override
  String get protectConfirm => 'Tasdiqlash';

  @override
  String protectPending(Object time, Object what) {
    return '$what: $time gacha kutilmoqda. Soʻng “Sozlamalar” boʻlimida tasdiqlang.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: kutish tugadi. Hali ham xohlaysizmi? $time dan oldin “Tasdiqlash” tugmasini bosing; aks holda hech narsa oʻzgarmaydi.';
  }

  @override
  String get protectWaitTitle => 'Bu oʻzgarish kutadi';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what hozir boʻlmaydi. $time da, agar hali ham xohlasangiz, uni 15 daqiqa ichida “Sozlamalar” boʻlimida tasdiqlang. Hech narsa qilmasangiz, hech narsa oʻzgarmaydi.';
  }

  @override
  String get protectWaitStart => 'Kutishni boshlash';

  @override
  String protectAlreadyWaiting(Object time) {
    return '$time gacha allaqachon kutilmoqda.';
  }

  @override
  String protectStarted(Object time) {
    return '$time gacha kutilmoqda. Soʻng “Sozlamalar” boʻlimida tasdiqlang.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'ertaga $time';
  }

  @override
  String get protectHeldBack =>
      'Hozir emas: himoya sozlamalaringiz boʻyicha bu oʻzgarish kutishi kerak yoki PIN-kod soʻraladi.';

  @override
  String get protectLimits =>
      'Bu nimani toʻxtata olmaydi: telefonni qayta ishga tushirish (filtrlash oʻz-oʻzidan qayta boshlanmaydi), majburiy toʻxtatish, oʻchirib tashlash, Waaiya maʼlumotlarini tozalash va Androidning oʻz sozlamalari. Ularni bloklash uchun maxsus Android ruxsatlari kerak, Waaiya esa ulardan foydalanmaydi. Bu zaif damdan himoya qiladi, qatʼiy qaror qilgan odamdan emas.';

  @override
  String get protectLimitsDesktop =>
      'Bu nimani toʻxtata olmaydi: terminaldagi waaiya buyrugʻi, Waaiyani oʻchirib tashlash yoki uning sozlamalar jildini oʻchirish. Bu zaif damdan himoya qiladi, qatʼiy qaror qilgan odamdan emas.';

  @override
  String get protectLimitsWindows =>
      'Bu nimani toʻxtata olmaydi: terminaldagi waaiya-filter.exe buyrugʻi, Waaiyani oʻchirib tashlash yoki uning sozlamalar jildini oʻchirish. Bu zaif damdan himoya qiladi, qatʼiy qaror qilgan odamdan emas.';

  @override
  String get protectWhatStop => 'Filtrni toʻxtatish';

  @override
  String protectWhatOff(Object name) {
    return 'Oʻchirish: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Yoqish: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Ilova qoʻshish: $name';
  }

  @override
  String get protectWhatStrictness => 'Xiralashtirishni kamroq qatʼiy qilish';

  @override
  String get protectWhatGender => 'Waaiyadan kim foydalanishini oʻzgartirish';

  @override
  String protectWhatDelay(Object value) {
    return 'Oʻchirishdan oldingi kutishni oʻzgartirish: $value';
  }

  @override
  String get protectWhatPinChange => 'PIN-kodni oʻzgartirish';

  @override
  String get protectWhatPinClear => 'PIN-kodni olib tashlash';

  @override
  String get protectWhatSetting => 'Sozlamani oʻzgartirish';

  @override
  String get onboardBodyDesktop =>
      'Waaiya bu kompyuterdagi ilovalar ovozidan musiqa asboblarini olib tashlaydi. Nutq va Qurʼon tilovati saqlanadi. Qoʻshiq aytayotgan ovozlar ham olib tashlanadi.';

  @override
  String get worshipUseLocation => 'Joylashuvimdan foydalanish';

  @override
  String get worshipWhyLocation =>
      'Siz turgan joydagi namoz vaqtlarini topish uchun Waaiya bu telefonning taxminiy joylashuvini hozir bir marta o\'qiydi. U telefonda joyingiz sifatida saqlanadi va hech qayerga yuborilmaydi.';

  @override
  String get worshipLocating => 'Joylashuvingiz aniqlanmoqda…';

  @override
  String get worshipLocationDenied =>
      'Joylashuvga ruxsat berilmadi. Buning o\'rniga shahringizni qidirishingiz mumkin.';

  @override
  String get worshipLocationOff =>
      'Bu telefonda joylashuv o\'chiq. Uni yoqib, qayta urinib ko\'ring yoki shahringizni qidiring.';

  @override
  String get worshipLocationSettings => 'Joylashuv sozlamalari';

  @override
  String get worshipLocationFailed =>
      'Joylashuvingiz topilmadi. Birozdan so\'ng qayta urinib ko\'ring yoki shahringizni qidiring.';

  @override
  String worshipPlaceNear(Object city) {
    return '$city yaqinida';
  }

  @override
  String worshipHabousNote(Object city) {
    return 'Habus va islomiy ishlar vazirligining $city uchun jadvallariga moslab hisoblangan vaqtlar.';
  }

  @override
  String get trayOpen => 'Waaiyani ochish';

  @override
  String get trayQuit => 'Chiqish';

  @override
  String get engineErrorAutostartBlocked =>
      'Windows tizimga kirishda Waaiya ishga tushishiga ruxsat bermayapti. Sozlamalar › Ilovalar › Ishga tushirish bo\'limida Waaiya\'ni yoqing, so\'ng bu parametrni qayta yoqing.';

  @override
  String get engineErrorAutostartPolicy =>
      'Bu kompyuterning administrator tanlagan sozlamalari tizimga kirishda Waaiya ishga tushishiga ruxsat bermaydi.';

  @override
  String get notifTextTitle =>
      'Filtrlash paytida bildirishnoma matnini ko‘rsatish';

  @override
  String get notifTextBody =>
      'Biror ilova butun ekranni yozib olayotganda Android bildirishnomalar matnini yashiradi, filtrlash ham shunga kiradi. Yoqilgan: Waaiya bu himoyani faqat filtrlash paytida olib tashlaydi, shunda bildirishnomalarni o‘qiy olasiz. Himoya olib tashlangan paytda ayni vaqtdagi boshqa ekran ulashish ham bildirishnomalaringiz va kodlaringizni boshqalarga ko‘rsatishi mumkin.';

  @override
  String get notifTextNextStart =>
      'O‘zgarish kuchga kirishi uchun filtrlashni to‘xtatib, qayta ishga tushiring.';

  @override
  String get notifTextRefused =>
      'Bu telefon o‘zgarishni rad etdi. Dasturchilar uchun parametrlarda “Ekran ulashish himoyasini o‘chirish”ni o‘zingiz yoqing.';

  @override
  String get notifTextByHand =>
      'Ko‘rsatilmoqda: Android himoyasi dasturchilar uchun parametrlarda o‘chirilgan (“Ekran ulashish himoyasini o‘chirish”). U yerda qayta yoqmaguningizcha har qanday ekran ulashishda o‘chiq qoladi.';

  @override
  String get notifTextHowTo =>
      'Waaiya filtrlayotganda Android bildirishnomalar matnini yashiradi. Bir martalik sozlashdan keyin Waaiya ularni ko‘rsatadi: bu himoyani faqat filtrlash paytida olib tashlaydi.';

  @override
  String get notifTextOpenDev => 'Dasturchilar uchun parametrlarni ochish';

  @override
  String get notifTextLockNote =>
      'Bu telefonda ekran qulflanganda Android filtrlashni ham to‘xtatadi va siz Davom ettirish tugmasini bosmaguningizcha boshqa ilovalar jim qoladi. Sozlash bunga ham yo‘l qo‘ymaydi.';

  @override
  String get notifTextHandOptional =>
      'Ixtiyoriy, sozlashsiz: dasturchilar uchun parametrlarda “Ekran ulashish himoyasini o‘chirish”ni yoqing. Shunda u har qanday ekran ulashishda o‘chiq qoladi, ayrim telefonlarda esa bu yo‘q.';

  @override
  String get notifTextForced =>
      'Yoqilgan: bu telefonda Android har bir ishga tushirishdan oldin so‘raydi va keyin har bir ekran qulfida filtrlashni to‘xtatardi. Waaiya filtrlash paytida bu himoyani olib tashlaydi, shuning uchun bildirishnoma matni ham ko‘rinadi. Himoya olib tashlangan paytda ayni vaqtdagi boshqa ekran ulashish ham bildirishnomalaringiz va kodlaringizni boshqalarga ko‘rsatishi mumkin.';

  @override
  String get oneAppTitle =>
      'Ishga tushirishda: “Bitta ilovani ulashish”, keyin Waaiya';

  @override
  String get oneAppBody =>
      'Android nimani ulashishni so‘raganda “Bitta ilovani ulashish”ni, keyin Waaiya’ni tanlang. Boshqa ilovalar filtrlanishda davom etadi, bildirishnomalar o‘qiladigan bo‘lib qoladi va ekran qulflanganda filtrlash davom etadi. Butun ekran bilan Android bildirishnoma matnini yashiradi va har bir qulfda filtrlashni to‘xtatadi.';

  @override
  String get oneAppPair =>
      'Waaiya to‘liq ishlashi uchun Sozlash sahifasida simsiz nosozliklarni tuzatish orqali uni bir marta ulang: shunda asl musiqa ham o‘chiriladi va Android har safar so‘rashni to‘xtatadi.';

  @override
  String get notifTextOneApp =>
      'Ishga tushirishda “Bitta ilovani ulashish”, keyin Waaiya tanlansa ko‘rsatiladi. Butun ekran bilan Android uni yashiradi; bir martalik sozlashdan keyin Waaiya buni filtrlash paytida olib tashlaydi.';

  @override
  String get blurNeedsRestart =>
      'Xiralashtirishdan foydalanish uchun filtrlashni to‘xtatib, qayta ishga tushiring: unga butun ekran kerak, bu filtrlash esa “Bitta ilovani ulashish” taklifi bilan boshlangan.';

  @override
  String get micOpenSettings =>
      'Mikrofonga ruxsat berish uchun Waaiya sozlamalarini ochish';

  @override
  String get keepRunningTitle => 'Waaiya ishlab tursin';

  @override
  String get keepRunningBattery =>
      'Bu telefon batareyani tejash uchun bir muddatdan keyin Waaiyani yopishi mumkin, shunda filtrlash to‘xtaydi. Waaiya sozlamalarida, Batareya bo‘limida «Cheklanmagan»ni tanlang. Xiaomi, Redmi va POCO’da: «Cheklovlarsiz», hamda Avtoishga tushirishni ham yoqing.';

  @override
  String get keepRunningNotifications =>
      'Waaiya bildirishnomalari o‘chiq, shuning uchun filtrlash to‘xtaganda sizga xabar bera olmaydi. Ularni Waaiya sozlamalarida yoqing.';

  @override
  String get keepRunningOpen => 'Waaiya sozlamalarini ochish';

  @override
  String get lockAskTitle => 'Ekran qulflanganda filtrlash davom etsinmi?';

  @override
  String get lockTitle => 'Ekran qulflanganda filtrlashni davom ettirish';

  @override
  String get lockBody =>
      'Bu telefonda Android har bir ishga tushirishdan oldin so‘raydi, so‘ng har safar ekran qulflanganda filtrlashni to‘xtatadi. Waaiya filtrlash paytida Androidning ekran ulashish himoyasini olib qo‘yib, buning oldini olishi mumkin va filtrlash to‘xtaganda uni qaytaradi. U olib qo‘yilgan paytda bir vaqtda bo‘lgan boshqa ekran ulashish (masalan, videoqo‘ng‘iroq) ham bildirishnomalaringizni ko‘rsatishi mumkin. O‘zgarish keyingi ishga tushirishda kuchga kiradi.';

  @override
  String get lockYes => 'Filtrlashni davom ettirish';

  @override
  String get lockNo => 'Har qulflashda to‘xtatish';

  @override
  String get sendToSupport => 'Waaiyaga yuborish';

  @override
  String get stateTooSlowNoLinks =>
      'Bu telefon jonli ovozni filtrlash uchun juda sekin, shuning uchun ovoz uziladi.';

  @override
  String get startNoSetupBodyNoLinks =>
      'Bir martalik sozlash hali bajarilmagan. Usiz Waaiya asl ovozni oʻchira olmaydi: musiqa va filtrlangan ovozni birga eshitasiz.';

  @override
  String protectDelayLongAsk(String value) {
    return '$value kutishni tanlaysizmi? Endi filtr yoki istalgan himoyani o‘chirish $value kutadi, bu kutishni qisqartirish ham shunday.';
  }

  @override
  String get keepRunningKilled =>
      'Android Waaiya filtrlayotgan paytda uni yopdi, shuning uchun ovoz endi filtrlanmadi.';
}
