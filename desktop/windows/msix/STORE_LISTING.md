# Microsoft Store: what to fill in (Partner Center, app "Waaiya", Store ID 9NBB296FSRJP)

The package declares English, Arabic and French (`AppxManifest.xml` `<Resources>`), so Partner Center asks for these
three listings. The app itself has nine languages; more listings can be added later by adding the language to the
manifest. Screenshots: `ui/tool/store_shots_test.dart` (2732x1536, one run per language) renders them.

## Submission settings

| Page | Value |
|---|---|
| Pricing and availability | Free. Markets: all. First submission: **Private audience** or "hidden, direct link only", to install and check on a real PC before making it public. |
| Properties: category | Utilities & tools |
| Properties: privacy policy URL | the privacy policy below, published (see "Privacy policy") |
| Properties: support contact | the owner's support email or the GitHub issues page: https://github.com/oksyassine/waaiya/issues |
| Properties: product declarations | none needed (no accessibility claims, no in-app purchases) |
| System requirements | Windows 10 version 2004 (build 19041) or newer, x64. Memory: 4 GB recommended. |
| Age ratings (IARC questionnaire) | Utility app. No violence, no sexual content, no gambling, no user communication or sharing, no location sharing, no purchases, no unrestricted web access. |
| Packages | `waaiya-store-x64-<version>.msix` (a release asset, or the `waaiya-store-msix` artifact of the Windows workflow). Unsigned: the Store signs it. |
| Notes for certification | the text below |

## Notes for certification (English)

> Waaiya removes musical instruments from the sound of the user's other apps, live, and keeps speech and Quran
> recitation. It is open source (AGPL-3.0): https://github.com/oksyassine/waaiya
>
> How it works, and why it needs runFullTrust: it is a desktop app (Flutter) with two helper programs in the
> package, engine\waaiya-filter.exe (sound filter) and engine\waaiya-blur.exe (optional screen blur). When the user
> presses the power button, the filter turns the other apps' volume down in the Windows volume mixer, captures their
> sound with the process-loopback API, removes the instruments with an on-device model (ONNX Runtime) and plays the
> result. Pressing the button again gives every app its volume back. Nothing is sent over the network; there is no
> account, no analytics and no advertising.
>
> The startup task "Waaiya" runs engine\waaiya-filter.exe autostart at login: it starts filtering only if the user
> turned on "Start at login" in the app's Settings; otherwise it gives apps their volume back if the computer was
> turned off while filtering, and exits.
>
> The optional screen blur (Screen page, off by default) draws click-through covers over people or immodest images
> on screen, detected on the device.
>
> To test: open Waaiya, choose a gender on first launch, play any video with music in a browser, press the power
> button on the Filter page: the music is removed and speech remains. Press it again to stop.
>
> Note: if the app is uninstalled while filtering, Windows ends the filter and other apps keep the lowered volume
> until raised in the volume mixer; the app asks users to stop filtering first (README).

## Listing: English

**Description**

Waaiya removes musical instruments from everything your computer plays and keeps the voice: speech, lectures and
Quran recitation. It works with every app (browsers, video players, games), live, on your computer.

- One button: Waaiya filters the sound of all your other apps until you press it again.
- Fails closed: if the filter cannot run, apps stay silent instead of playing music.
- Optional: mute women's singing (women's speech and recitation are kept).
- Optional screen blur: covers women, or immodest images, over every window; clicks still reach the windows
  underneath.
- Start at login, if you want.
- Everything runs on your computer. Nothing is sent anywhere: no account, no analytics, no ads.
- Free and open source (AGPL-3.0): https://github.com/oksyassine/waaiya
- In Arabic, English, French, Urdu, Indonesian, Turkish, Bengali, Persian and Malay.

The name comes from the Quran: «وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ», "and that a heedful ear would retain it" (al-Ḥāqqah 69:12).

Windows version: a preview. It needs Windows 10 version 2004 or newer. A fast computer gives the best sound;
on a slow one Waaiya switches to mono by itself.

**Product features** (one per line)
- Removes music from every app, keeps speech and Quran recitation
- Live, on your computer: nothing is sent anywhere
- Fails closed: silence, never unfiltered music
- Optional: mute women's singing
- Optional screen blur over every window
- Start at login
- Free and open source

**Keywords**: music remover, halal, Quran, lectures, no music, vocal, filter

## Listing: العربية

**الوصف**

واعية تُزيل الآلات الموسيقية من كل ما يشغّله حاسوبك، وتُبقي الصوت البشري: الكلام والدروس وتلاوة القرآن. تعمل مع كل
التطبيقات (المتصفحات ومشغّلات الفيديو والألعاب)، مباشرةً، على حاسوبك.

- زرّ واحد: تصفّي واعية صوت كل تطبيقاتك الأخرى حتى تضغطه مرة أخرى.
- عند الخلل صمت: إن تعذّر عمل التصفية، تبقى التطبيقات صامتة بدل أن تُسمِع الموسيقى.
- اختياري: كتم غناء النساء (يبقى كلامهن وتلاوتهن).
- اختياري: تمويه الشاشة فوق كل النوافذ، للنساء أو للصور غير المحتشمة، والنقرات تصل إلى النوافذ تحتها.
- التشغيل عند الدخول إلى الحساب، إن أردت.
- كل شيء يعمل على حاسوبك، ولا يُرسَل شيء إلى أي مكان: بلا حساب ولا إحصاءات ولا إعلانات.
- مجانية ومفتوحة المصدر (AGPL-3.0):‏ https://github.com/oksyassine/waaiya
- بالعربية والإنجليزية والفرنسية والأردية والإندونيسية والتركية والبنغالية والفارسية والملايوية.

الاسم من القرآن: «وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ» (الحاقة 12).

نسخة ويندوز تجريبية، وتحتاج ويندوز 10 الإصدار 2004 أو أحدث. الحاسوب السريع يعطي أفضل صوت، وعلى البطيء تنتقل واعية إلى
الصوت الأحادي من تلقاء نفسها.

**الميزات**
- تُزيل الموسيقى من كل التطبيقات، وتُبقي الكلام والتلاوة
- مباشرةً على حاسوبك، ولا يُرسَل شيء
- عند الخلل صمت، لا موسيقى دون تصفية
- اختياري: كتم غناء النساء
- اختياري: تمويه الشاشة فوق كل النوافذ
- التشغيل عند الدخول إلى الحساب
- مجانية ومفتوحة المصدر

**الكلمات المفتاحية**: إزالة الموسيقى، بدون موسيقى، حلال، قرآن، دروس، تلاوة، واعية

## Listing: Français

**Description**

Waaiya retire les instruments de musique de tout ce que joue votre ordinateur et garde la voix : paroles, cours et
récitation du Coran. Elle fonctionne avec toutes les applis (navigateurs, lecteurs vidéo, jeux), en direct, sur
votre ordinateur.

- Un seul bouton : Waaiya filtre le son de toutes vos autres applis jusqu'à ce que vous appuyiez à nouveau.
- En cas d'échec, le silence : si le filtre ne peut pas tourner, les applis restent muettes au lieu de jouer la
  musique.
- En option : couper le chant des femmes (leurs paroles et leur récitation sont gardées).
- En option : flouter l'écran au-dessus de toutes les fenêtres (les femmes, ou les images indécentes) ; les clics
  atteignent toujours les fenêtres en dessous.
- Démarrage à l'ouverture de session, si vous le souhaitez.
- Tout tourne sur votre ordinateur. Rien n'est envoyé : ni compte, ni statistiques, ni publicité.
- Gratuite et open source (AGPL-3.0) : https://github.com/oksyassine/waaiya
- En arabe, anglais, français, ourdou, indonésien, turc, bengali, persan et malais.

Le nom vient du Coran : « وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ », « et qu'une oreille attentive la retienne » (al-Hâqqa 69:12).

Version Windows en préversion. Elle demande Windows 10 version 2004 ou plus récent. Un ordinateur rapide donne le
meilleur son ; sur un ordinateur lent, Waaiya passe en mono d'elle-même.

**Fonctionnalités**
- Retire la musique de toutes les applis, garde la parole et la récitation du Coran
- En direct, sur votre ordinateur : rien n'est envoyé
- En cas d'échec, le silence, jamais la musique non filtrée
- En option : couper le chant des femmes
- En option : flou de l'écran au-dessus de toutes les fenêtres
- Démarrage à l'ouverture de session
- Gratuite et open source

**Mots-clés** : sans musique, supprimer la musique, halal, Coran, cours, voix, filtre

## Privacy policy (to publish at the URL given in Properties)

> **Waaiya: privacy policy**
>
> Waaiya does not collect, store or send any personal information. The sound filter and the screen blur run
> entirely on your device; the sound and the screen are processed in memory and never recorded or sent anywhere.
> There is no account, no analytics, no advertising and no tracking. Your settings stay in Waaiya's own folder on
> your computer and are removed when you uninstall it.
>
> The Windows app does not use the network. (On Android only, "Open a link" contacts the site of the link you
> open, and the bundled yt-dlp downloads its own updates from PyPI.)
>
> Source code: https://github.com/oksyassine/waaiya. Contact: https://github.com/oksyassine/waaiya/issues
