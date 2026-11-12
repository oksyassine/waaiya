# What observant Muslims need from their phone: findings for the Waaiya roadmap

Research date: 2026-11-11. Web search and page reads only. No code was changed.

## How to read this file

**Three kinds of statement are kept apart everywhere:**

- **ASK**: a person asks for it or complains about its absence (a fatwa-site question, a store review, a GitHub issue, a forum post). The question is the evidence of the need. No ruling is taken from the answer.
- **OFFER**: a competitor ships it. This shows somebody judged it worth building. It does not show that people ask for it.
- **IDEA**: my own suggestion. Nobody was found asking for it in these words.

**Evidence strength** counts independent ASK sources that I opened myself (different authors or sites; five comments in one thread count as one):

| Label | Meaning |
|---|---|
| Many | 5 or more independent asks |
| A few | 2 to 4 independent asks |
| One | 1 ask |
| Offers only | competitors ship it, no ask found |
| None found | searched, nothing found |

**Quotes** are short phrases copied from the page as the reading tool returned it. Where I write "paraphrase", the wording is mine. Every source carries an ID (S, G, W, C, F, T, D) that points to the list at the end of the file, with the status of each page.

**Fiqh.** This file takes no position on any ruling. Where scholars differ and the difference changes what a switch should do, the row says "user setting".

**What could not be read.** Reddit (search and page reads are both refused), the Google Play listing page that was tried (it came back empty), Telegram channels and YouTube comments (nothing found). Section 8 lists every gap. The evidence here therefore leans on fatwa-site questions, GitHub issues, Firefox add-on reviews, App Store listings and third-party store trackers.

**Two facts found during this research change the competitive picture:**

1. HaramBlur is no longer only a browser extension. It has an Android app on Google Play that blurs inside other apps through an accessibility service (about 731 thousand installs, first released 2025-11-17, in-app purchases; figures from a third-party tracker) [G13]. Its iPhone app works only inside its own browser [G12].
2. Kahf Guard on Android is large (about 3.6 million installs, about 73 thousand ratings; third-party tracker) and already ships prayer-time auto-silent including Jumu'ah, blocking of Reels, Shorts, TikTok and WhatsApp Status, and uninstall prevention [C5]. Its own FAQ says it "Cannot see images, videos, or visual content" [C4], so it does not compete with the audio filter or the screen blur.

---

## 1. Ranked table of needs

**Ranking rule:** evidence strength first, then how much of the need only an on-device, system-wide tool can meet, then effort. A need that others already serve well for free is ranked lower even when the evidence is strong.

| # | Need | Who asks | Evidence | Sources | What exists today, and its gap | Waaiya covers | Feasible on Android without root | Effort | Play-policy or privacy risk |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Hear the speech, not the music, in everything: TV-style programmes, news with a music bed, lectures with a nasheed or music under them, cartoons, anime, games | People who today mute the whole sound and lose the speech | Many | [S1] [S2] [S3] [S4] [S5] [S6] | HaramMute: YouTube links only, prepared on a server, free tier "60 minutes each week on videos up to 15 minutes", no live streams [S13]. Desktop extensions cover browser tabs only. Nothing found that works over every app on the phone | Fully for sound that Android lets an app capture (media and game streams). Singing is removed too for now | With Shizuku (one-time grant) | Done; ongoing quality work | Screen-capture consent and foreground-service declaration [D3]. Apps that refuse capture stay unfiltered: say so in the app |
| 2 | Cover women and nudity in every app, with nothing visible before the cover lands, and fewer misses on thumbnails and small images | Men who use HaramBlur and find its limits | Many | [G9] [G3] [G4] [G11] [G1] [G2] | HaramBlur extension: desktop browsers. HaramBlur Android: accessibility service [G13], source not published [T2], paid extras. HaramBlur iPhone: only inside its own browser [G12]. Kahf Browser: only inside the browser, fails on full-screen video for one reviewer [G14] | Partly: covers over every app, fail-closed; a new picture can show for about 50 to 150 ms; paid streaming captures as black | With Shizuku for touch-through covers; overlay window otherwise | M (cut the first-frame gap, small images, drawn content) | Accessibility build needs in-app disclosure, consent and a declaration form [D1]. Screen capture is the most sensitive permission: keep proof that nothing leaves the phone |
| 3 | A filter that does not heat the phone, drain the battery or make video stutter, including on older phones | Users of every similar tool | Many (complaints) | [G10] [G11] [G2] [G14] [G3] | All on-device image filters draw this complaint. No user report found about a real-time audio filter on a phone | Partly: unmeasured in public. The blur and the audio filter run together | Yes | M (measure, publish numbers, add a light mode) | None. Publishing battery numbers is a trust gain |
| 4 | Protection the user cannot switch off in a weak moment: a waiting period before "off" takes effect, a password, a schedule | Men fighting a habit; parents | A few asks, plus offers | [C1] [C2] [G2] (issues #27, #31) and offers [C3] [C5] [C6] | Kahf Guard: uninstall prevention, PIN, 24-hour cooldown [C3]. HaramBlur: paid password lock that one user found does nothing offline [C2]. Nafs: tells a partner when the shield is turned off [C6] | No | Yes for a waiting period inside the app. Blocking uninstall or force-stop needs an accessibility service or device-admin | S for the waiting period; L for a hard lock | Hard locks sit close to the accessibility rule against changing settings "without their permission" [D2]. Partner alerts send data off the phone, which conflicts with a settled rule: keep the lock local |
| 5 | Be able to trust the tool: open source, on the phone only, no account, no price on the core protection | Users who watched other tools close their source or sell data | A few asks, plus one large public scandal | [T1] [T2] [C2] [T3] [W8] | HaramBlur Android and iPhone apps are closed and charge; an issue objects to "it becoming closed source, making money off of it" [T1]. Store privacy labels of HaramBlur iOS, Kahf Guard iOS, Nafs and HaramMute iOS list identifiers or tracking next to "on-device" or "zero tracking" claims [G12] [C3] [C6] [S14] | Fully (Apache-2.0, nothing sent). Not yet proven to a stranger | Yes | S (plain privacy page, no analytics, reproducible build notes, "no network" test) | None; this is the answer to the risks in the other rows |
| 6 | Quran and Islamic apps, and recitation videos, interrupted by ads with music or indecent pictures | Users of free Quran and adhan apps; YouTube listeners | A few | [S10] [S11] [S12] [W8] | Paid tiers of each app remove its own ads. Nothing removes the music from another app's ad | Partly: the filter strips instruments from an ad's sound and the blur covers women in it, when the app allows capture | With Shizuku | Done as a side effect; S to test and document | Play forbids apps that "block or interfere with another app displaying ads" [D4]. Muting music inside an ad and covering part of it may be read that way: unverified, treat as a listing risk |
| 7 | Fix mistakes on the spot: cover by hand when the model misses, report a wrong detection in one tap, turn the filter off for one app or site | HaramBlur users | A few to many (many issues, one project) | [G1] (#203, #208) [G2] (#149, #47, #162, #22, #103, #104) [G4] | These are open requests in HaramBlur's tracker; whether any has shipped since was not checked. Reporting is called "very tedious" [G4] | No (not seen in the README) | Yes | S to M | Reports must stay on the phone or leave only by the user's own action (export a file), or the "nothing is sent" rule breaks |
| 8 | Children: music-free cartoons, no indecent ads, a tablet a child cannot unlock, the family TV | Parents | A few | [S17] [S3] [S5] [F1] [F2] [G6] | Curated paid libraries: One4Kids "carefully designed to be music-free", £7.99 a month [F1]. Kahf Guard parental control (paid, remote) [C4]. Nothing filters the cartoons a child already watches | Partly: the filter works on any cartoon on an Android phone or tablet. No child lock, no Android TV build | Phone and tablet: with Shizuku. Android TV: unverified | M (child lock on settings); L (TV) | Remote parental dashboards need a server: conflicts with a settled rule. A local PIN does not |
| 9 | Phone goes silent in the mosque and at prayer times, Friday included, and comes back by itself | Worshippers; people annoyed by others' ringtones | A few asks, plus offers | [W1] [W2] [W3] and offers [W4] [W5] [C5] | Well served: Prayer Time Muter (AGPL, per-prayer and Friday offsets) [W4], Kahf Guard (free) [C5], many adhan apps | No | Yes (Do Not Disturb access) | S, but needs prayer times | Location for prayer times is the data that sank trust in Muslim Pro [T3]: compute on the phone, allow a manual city |
| 10 | Games: music under the game, indecent characters and cut-scenes | Gamers | A few | [S2] [S3] [S4] [G5] | Advice given is "mute it". HaramBlur issue asks for blur "inside video games in real time" [G5] | Sound: fully where the game allows capture. Picture: partly, the classifier was trained on photos, drawn and 3D figures are untested | With Shizuku | M (test and train on drawn and 3D figures) | None beyond rows 1 and 2 |
| 11 | The tool in my language, in good Arabic | Arabic, Persian and other speakers | A few | [G1] (#231, #218) [G2] (#163) [T4] | Kahf Guard iOS lists 12 languages including Arabic, Bengali, French, Indonesian, Malay, Turkish [C3]. Prayer Audio Controller: English, Turkish, Arabic, Indonesian, Urdu [W6] | Partly: Arabic and English | Yes | S per language | None |
| 12 | iPhone users want the same thing | iPhone owners | A few | [G2] (#129, #101) [C3] (review) [W5] | HaramBlur iPhone: "you have to use social media platforms from within the HaramBlur app", 2.0 from 3 ratings [G12]. HaramMute iPhone: pasted links [S14] | No (planned: in-app player, Safari extension) | Not an Android question. On iPhone: in-app only | L | App Store review; no system-wide route exists |
| 13 | Stop the endless short-video feed (Reels, Shorts, TikTok, statuses) | People who call it wasted time; Ramadan resolutions | A few asks, plus offers | Asks: [W9] [C7]. Praise for an offer: [G15]. Offers: [C3] [C5] [G12] | Well served: Kahf Guard blocks "Instagram Reels, Facebook Reels, YouTube Shorts", WhatsApp Status, TikTok [C5]; HaramBlur iPhone hides Shorts and Reels [G12] | No | Only with an accessibility service that reads each app's screen layout | L, and it breaks whenever those apps change | Accessibility declaration [D1]; Play Protect blocks sideloaded apps that declare one (project README, not re-checked) |
| 14 | A stronger, different cover: fully opaque, cover all but the face, cover only the offending part | HaramBlur users | A few | [G9] [G1] (#202, #212) [G2] (#144, #20) | HaramBlur blur capped at a level where "it is still visible under the blur" [G9] | Mostly: covers, not a see-through blur; body-shaped strips | Yes | S (opacity and style setting) | None |
| 15 | Phone's own sounds without music: ringtone, notification tones, built-in tunes, the tune a caller hears while waiting | Phone owners, since 2002 | A few (old) | [S7] [S8] [S9] | Every phone lets the user pick a plain tone. The caller-waiting tune belongs to the carrier | No. Per the earlier notes, Android does not let an app capture ring and notification sound | Yes for a one-screen helper that sets plain tones. No for the carrier's tune | S | Needs the "modify system settings" permission |
| 16 | Stop or mute what is playing when the adhan sounds | Not found asking | Offers only | [W6] [W11] | Prayer Audio Controller mutes Chrome tabs only, paid, "Dedicated desktop and mobile apps are in development" [W6]. Athan Auto Pause, a Chrome extension, has 59 users [W11]: a weak demand signal. Kahf Guard silences the ringer, not the media [C5] | No. Waaiya already holds the audio path, so muting it at a set time is cheap (IDEA) | With Shizuku (already granted) | S after row 9 | Same location caution as row 9. Whether one must stop: user setting |
| 17 | Women's voices: singing, or also presenters and reciters | Some men | One ask, one idea from a user | [S16] [G16] | None found | Partly: optional mute of women's singing; women's speech is kept | Yes | Done | Scholars differ on speech: keep it a user setting and keep speech as the default |
| 18 | Indecent GIF and sticker suggestions in keyboards; pictures in the gallery; music on WhatsApp statuses | Not found | None found | (searched in English and Arabic) | Kahf Guard can hide WhatsApp Status as a whole [C5] | The blur and filter already run over the keyboard, gallery and statuses like any other screen | Yes | None | None |

---

## 2. Notes by area

### 2.1 Sound

**The need in people's own words (ASK).** The recurring pattern is "I want the content, I mute it because of the music, and I lose the speech":

- A viewer of Islamic satellite channels: music plays "while advertising or in the starting or ending of the programme" and "we mute the volume when there is only music", but in news "while they give news there is music" (2009) [S1].
- A player who read that a game with music is acceptable "as long one is able to mute it" asks whether anyone allows playing unmuted (2018) [S2].
- An Arabic question (2021) asks about playing games or watching cartoons that contain music "مع كتم الصوت، وغض البصر" (with the sound muted and the gaze lowered) [S3]. The same fatwa section lists a question about anime watched "مع إغلاق الصوت" and one about muting a game when a character says something forbidden [S4].
- "cartoon movies and games should also be allowed conditional to stop or mute the music" [S5].
- Lectures: "Many times people post bayans of various Ulema on the whatsapp. There is usually a nasheed playing in the background." [S6]. Whether such a background is acceptable differs between scholars and between kinds of nasheed (voice only, voice effects, duff, instruments): **user setting**, and it is the reason "keep singing" is worth finishing.

**Ads with music in religious apps (ASK).** Reviews of a Quran app: "There's always ads that contain music which is very annoying."; "VIDEO ad comes up in the background with music that i can't stop."; "Many of the ads contain haram content" (review aggregator, no dates shown) [S10]. A 2024 question asks whether one may listen to recitation videos "that have advertisements placed by the uploader" [S11]. An Arabic-world tech blog describes "a full-screen video advertisement for a dating app, a gambling game, or a usurious loan platform" inside Quran apps (2026) [S12]. A third-party review analysis calls ads "the single most emotionally charged complaint in the category" and mentions "full-screen video ads appearing before or after the adhan" (the blog paraphrases reviews; it gives no counts) [W8].

**The phone's own sounds (ASK, old but steady).** "using mobile phones which play tunes, because these tunes are a kind of music" (2004) [S7]. A buyer whose phone has "أصوات معازف لا يمكن حذفها" (musical sounds that cannot be deleted) (2014) [S8]. The tune a caller hears while waiting: "ما حكم جعل نغمة الانتظار دعاء ؟" (2016) [S9]; scholars differ on using supplications or Quran as tones, so if a helper is ever built it offers plain tones only and decides nothing.

**Children's songs (ASK).** "I would like to know the islamic ruling on nursery rhymes for children?" (2006) [S17]. See 2.5.

**Women's voices (ASK, thin).** A question to Ibn Baz starts from the fact that many broadcast programmes, even Islamic ones, are presented by women [S16]. A HaramBlur user proposes using sound to tell gender: "sound is clearly distinguishable between male and female" [G16]. The answers found differ on speech versus singing: **user setting**. Waaiya's current choice (optional, singing only, speech kept) fits that.

**What competitors offer (OFFER) and where they stop.**

- HaramMute [S13] [S14]: YouTube only ("Other Platforms" are "Coming Soon"), link-based, prepared remotely ("Preparation time varies by video"), needs a connection, no live streams, weekly free quota then paid plans (iPhone in-app purchases QAR 19.99 to 499.99). Its iPhone privacy label lists email address, user ID and device ID as linked to the user [S14]. Its Firefox add-on has three reviews, all five stars, no complaints [S15].
- NoMusic, MusicRemover (IqraWave), Samsung Audio Eraser: see the earlier notes in `research_notes/System wide instrument muting app/existing_apps_and_platform_features.md`. Their pages were not re-read today (two returned only a title), so nothing new is claimed about them here.

**What was not found.** No user report about delay, battery or price of a music remover beyond what the earlier notes hold. No question specifically about music on WhatsApp statuses, in app interface sounds, or in ringback tones chosen by the person being called. Searches in Indonesian, Turkish and French returned only general video-editing tools and the same two or three extensions, so demand in those languages is unproven by this research, not disproven.

### 2.2 Sight

**The need in people's own words (ASK).**

- System-wide, on the phone: "We need similar service on mobile and desktop, native for overall system bluring inproper images" and "make it semi realtime protection so that bad images never gets rendered" (Firefox review, Apr 2026) [G9].
- Nothing visible first: "No blur on media load results in images/videos being exposed for 1-3 seconds before detection is completed" and "On older devices this could be even longer" (Jan 2026) [G3]. Open issues with the same aim: "Feature: Always blur until detection ends" (#111), "Use Video Buffer to Pre-process and Eliminate Blur Delay" (#168) [G2].
- Misses: "even though i have it on 100% strictness females only" a search still showed unblurred pictures; YouTube thumbnails and Shorts covers; a manga page [G4]. A one-star Arabic review: "هناك صور نساء كاسيات عاريات لا يتم طمسهم ، نريد تحسين ال ai أكثر" [G11]. Issue titles: "doesn't blur images of women wearing headphones" (#171), "Extension doesn't block facebook profile pictures" (#157), small thumbnails and "inappropriate anime pictures" (#124), black-and-white manga (#204), pictures set as page backgrounds (#159, #25), picture-in-picture (#167, #23), embedded videos (#214), PDF files (#165) [G1] [G2].
- Ads: an issue titled "Does detection work on Ads?" (2023) [G8].
- Games: blur "inside video games in real time, including character models, cutscenes, and menus", asking for "a desktop application or screen overlay" (Jul 2026) [G5].
- TV: "any plan to support andriod smart TV? This is very important to families." (Jan 2026) [G6].
- Cover strength and shape: "50% is not enough it is still visible under the blur"; "I'd like it to hide everything but the face" [G9]; "maximum blur" (#202), solid boxes (#144), "Blur only the 'Haram' part of the picture" (#20) [G1] [G2]. How much of a person to cover differs between users: **user setting** (Waaiya covers the whole body; a "face left visible" option was asked for once and is not recommended as a default).
- Other sites and apps: BBC videos (#227), msn.com (#161), Reddit video (#154), e-commerce product grids (#219) [G1] [G2].

**What competitors offer (OFFER).**

- HaramBlur browser extension: open source, 4.5 from 106 Firefox reviews [G9], 96 open issues [G1].
- HaramBlur Android app: Google Play, accessibility service "to scan on-screen content", the listing says analysis is on the device; about 731 thousand installs, 4.78 from about 15 thousand ratings (third-party tracker; a second tracker seen only in a search result gave different numbers) [G13]. Its source is not published: an issue asks "please consider open sourcing the app" [T2]. A user of the Play app notes it shows YouTube with ads, where he normally uses a patched player: "لو فتحت اليوتيوب من التطبيق بيكون فيه اعلانات" [G7]. Whether the Android app captures the screen or reads accessibility screenshots was not confirmed.
- HaramBlur iPhone app: own browser only, "does not have access to your screen", can hide Shorts and Reels, choose to blur men, women or everyone, $1.99 a month, 2.0 from 3 ratings [G12].
- Kahf Browser (Safe Gaze): blur inside its browser, says processing is on the device, 4.5 from 53 ratings on iPhone; reviewers: "Does not work on videos at all when in full screen mode.", "Phone is getting hot", "device is heat up extremely and full system become laggy" [G14]. Trustpilot: "it genuinely helps me stay safe from online fitnah"; blurring rated 8 out of 10 by one reviewer who hopes it improves [G15].
- Kahf Guard: blocks sites and whole app sections; by its own FAQ it "Cannot see images, videos, or visual content" [C4].

**Where Waaiya stands.** It already does the thing the Firefox reviewer asked for (covers over every app, on the phone). The system-wide design also sidesteps a complaint about in-app browsers: the user keeps his own player, ad blocker and extensions [G7] [G3]. Open points against the evidence: the 50 to 150 ms first-frame gap (against a competitor's 1 to 3 s), small thumbnails, drawn and 3D figures (anime, manga, games), paid streaming that captures as black, and the keyboard, gallery and sticker surfaces, for which no ask was found at all.

### 2.3 Worship and time

**Auto-silent (ASK).** A 2002 question complains that people bring phones to the mosque "ولا يغلقونها" (and do not switch them off) [W1]. A 2009 Algerian newspaper piece on tarawih: "تقطع عليك نغمات الجوال هذه الفسحة الإيمانية" (ringtones cut into this moment of faith) [W2]. Both are old; the complaint is about other people's phones, which no app on my own phone solves, and about my own forgetfulness, which an app does solve.

**A lesson from an existing auto-silent feature (ASK).** A Samsung user (2024): his phone "يصمت نفسه بنفسه بدون تدخل مني" (silences itself without me doing anything) and "تعبت منها" (I am tired of it). The cause was a prayer app's option; the fix was to turn off "جعل الهاتف صامت او هزاز وقت الصلاة" [W3]. An auto-silent that is not announced each time it acts looks like a fault.

**What competitors offer (OFFER).** Prayer Time Muter: free software (AGPL), "Per-prayer mute offsets", "Friday noon custom offsets", silent or vibrate, Android 6 and later, uses Do Not Disturb access [W4]. PrayQuiet: Android only "due to Apple limitation to access device settings" [W5]. Kahf Guard: "Your phone auto-silences during all 5 daily prayers and Jumu'ah", free tier [C5] [C4]. Many adhan apps include it. Verdict: served.

**Adhan and media (OFFER only).** Prayer Audio Controller mutes audible Chrome tabs at prayer times and restores them; "Desktop apps (Spotify, Apple Music, etc.) are not affected."; "Dedicated desktop and mobile apps are in development."; $19 a year; aimed at cafés and shops as well as individuals [W6]. Athan Auto Pause, a second Chrome extension, "Automatically pauses all audio and video across tabs at Islamic prayer times based on your location."; 59 users, 5.0 from 4 ratings, last updated January 2026 [W11]. That user count is a weak demand signal, and both tools are desktop only. No person was found asking for this on a phone. Whether one should stop what is playing during the adhan differs between scholars and between kinds of content: **user setting**, off by default.

**Adhan reliability and ads (ASK, paraphrased by a blog).** Adhan "not playing, playing late, playing silently, or being killed by battery managers" on Xiaomi, Huawei, Oppo and Samsung phones [W8, paraphrase]. This matters to Waaiya for a different reason: the same battery managers will kill a filter that must run all day.

**Prayer-time app locks (OFFER, search results only).** A dozen or more apps lock chosen apps at prayer time until the user confirms the prayer; one of their blogs describes the aim as "acting on it while another app has your attention" and says Android versions rely on accessibility, usage access or overlays [W7]. Their store pages were not opened. Verdict: crowded.

**Ramadan (ASK, press).** "I deleted Instagram from my phone and started trying to fill that void with making dua." (Hasan Gopalani); "the smartphone is a weapon of mass distraction" (Imam Shadee Elmasry) (2019) [W9]. This supports a seasonal "stricter for a month" preset more than any new feature (IDEA).

**Friday.** Only as an offset in the auto-silent tools above [W4] [C5]. No separate ask found.

### 2.4 Self-control

**The need in people's own words (ASK).**

- A waiting period: "[suggestion] Turn off protection. for example by using a 24 hour delay before turning off the extension"; "it gives people enough time to think long and hard" (Jun 2025) [C1].
- A lock that holds: a subscriber to a paid password lock found that offline "the user can change the settings or disable detection completely" (Feb 2026) [C2]. Older issue titles: "Add password lock to settings" (#27), "Scheduled Activation/Deactivation" (#31) [G2].
- Compulsion, as a scholar-run site describes it: people who "cannot keep away from their social media accounts, compulsively check them for new posts" (2021) [C7]. A question asks for advice for someone who stays up late and loses the dawn prayer (not phone-specific) [W10].
- A relieved user of a filter: "After almost a decade, now I can sense that I have the authority over what I want to see and browse on my phone." (Oct 2025) [C3].
- Praise for an existing offer, not an ask: a Trustpilot reviewer of Kahf Browser commends its shorts and reels blocker [G15].

**What competitors offer (OFFER).**

- Kahf Guard: site filter through its own DNS servers ("No VPN used"), app blocker, blocking of Reels and Shorts (premium), "Lock KahfGuard so it can't be deleted", PIN, 24-hour cooldown; free core, premium weekly $1 to yearly $48 on iPhone, plus a free pass for those who cannot pay [C3] [C4] [C5]. It admits "No software is 100% bypass-proof" [C4].
- Nafs: app shield through Apple's Screen Time, a "panic button", a 90-day programme, a partner who is told when the shield is turned off, $4.99 a month; one of two visible reviews: "the app is so buggy and crashes anytime i get in the onboarding" [C6].
- General blockers with partner reports and uninstall alerts appeared in search results only (not opened).

**What this means for Waaiya.** The one piece that fits the settled rules is a local waiting period: turning the filter or the blur off, or lowering strictness, takes effect after a delay the user chose earlier (IDEA built on [C1] and [C3]). It needs no account and sends nothing. It is a soft lock: a determined user can still uninstall the app. A hard lock needs an accessibility service or device-admin, and partner reports need a server; both are flagged in section 5 rather than recommended.

### 2.5 Family

**The need (ASK).**

- "Maruf, father of 3 kids, says that his children are growing up on YouTube"; "his worry stems from the lack of control over what his children watch and what they are exposed to via ads." (2017) [F2].
- A reviewer of a children's library: "all around us there is inappropriate advertisements or haram content" [F1].
- Questions about children's songs and cartoons with music: [S17] [S3] [S5].
- A blog for Muslim parents lists ten replacements for one popular nursery-song channel; it describes none of them as music-free (2023) [F3]. So parents who want no instruments have one named option in these sources, and it costs a subscription [F1].
- The family TV: [G6].

**What competitors offer (OFFER).** One4Kids TV: "Our content is carefully designed to be music-free", £7.99 a month or £79.99 a year, 4.6 from 247 ratings [F1]. Kahf Guard: safe-search enforcement, YouTube restricted mode, remote parental control (premium), "children cannot remove Kahf Guard", and it can be set on a home router [C3] [C5] [C8].

**What this means for Waaiya.** The filter turns any cartoon the child already watches into a no-instrument one, at no cost, which none of the offers do. Missing for a parent: a PIN on Waaiya's own settings and off-switch (same mechanism as the waiting period in 2.4), and a build for Android TV. Android TV support was not researched technically here; the setup step through Shizuku is likely to be the obstacle. Shared devices: no evidence found beyond the parental case.

### 2.6 Trust

**Open source and money (ASK).** "considering the direction that haramblur is going (it becoming closed source, making money off of it)"; "I have very strong objections to profiting off of our brothers' fear of Allah." (Mar 2026) [T1]. "please consider open sourcing the app" (Jan 2026) [T2]. A paid feature that fails offline [C2]. A blog on prayer apps says the perception of charging for sacred content "produces some of the angriest reviews" [W8, paraphrase].

**Data (press).** In 2020 a report said the US military bought location data that came from apps including "a Muslim prayer and Quran app called Muslim Pro, with more than 98 million downloads worldwide" [T3]. The 2026 review analysis says users still cite it and now examine location permissions in every prayer app [W8, paraphrase].

**Claims that do not match labels (my observation from the store pages).** HaramBlur iPhone says "100% on-device processing" and its label lists purchase history, device ID and product interaction used for advertising or marketing [G12]. Kahf Guard iPhone says "No DNS query logging" and its label lists identifiers under "Data Used to Track You" [C3]. Nafs lists tracking identifiers [C6]. HaramMute iPhone lists email, user ID and device ID [S14]. These labels are filled in by developers and cover the app shell (payments, analytics), not necessarily the filtered content; still, a tool with an empty label and public source stands out.

**Accessibility services.** Kahf Guard's FAQ spends a section on what its accessibility service can and cannot read ("Only API allowing detection of currently displayed screen content"; "Cannot see images, videos, or visual content") [C4], which shows the vendor expects the question. No user quote expressing this worry about a Muslim filter app was found. Academic work on the risk appeared in search results only.

**Cost (OFFER).** Subscriptions seen: HaramBlur iPhone $1.99 a month [G12]; Kahf Guard iPhone $5 a month, $48 a year [C3]; Nafs $4.99 a month [C6]; One4Kids £7.99 a month [F1]; Prayer Audio Controller $19 a year [W6]; HaramMute weekly quota then plans [S13]. Free and open: Prayer Time Muter [W4].

**Languages (ASK and OFFER).** Asks: "Add Persian (fa) localization" (#231), "الواجهة العربية تحتاج الى تعديل" (the Arabic interface needs fixing, #218) [G1], "كلمة غير مفهومة" (an unintelligible word, #163) [G2]. Offers: see row 11. Arabic that reads as translated is itself a complaint.

**Old and low-end phones (ASK).** "On older devices this could be even longer" [G3]; heat and lag on an "ipad 9th gen" [G14]; a Firefox-for-Android freeze [G11]. No statement was found about which Android versions people in the target countries run.

**iPhone (ASK and OFFER).** Issues asking for Safari support (#129, #101) [G2]; "Brother, iPhones don't give any access like changing dns server." (review) [C3]; an auto-silent app is Android only "due to Apple limitation" [W5]; HaramBlur's iPhone app is its own browser and rated 2.0 [G12].

### 2.7 Distribution

All policy pages below were read on 2026-11-11. Policy text changes; re-read before acting.

**Accessibility services on Google Play.**

- Only disability tools may declare themselves accessibility tools: "The tools must support people with disabilities as their primary purpose." [D1]
- Every other app that uses the API must show a disclosure "within the app itself", in normal use, with "affirmative user action for consent", and "will need to complete the Permission Declaration Form" [D1].
- The API cannot be used to "Change user settings without their permission" or to "Work around Android built-in platform security controls, privacy controls and notifications"; an exception is worded for what is "authorized by a parent or guardian through a parental control app" [D2].
- Apps that let an agent "autonomously initiate, plan, and execute actions" are prohibited; fixed rule-based behaviour is allowed [D1].
- In practice two apps of this kind are listed with accessibility services and carry a disclosure in their description: HaramBlur ("uses Android's Accessibility Service to scan on-screen content") [G13] and Kahf Guard ("Accessibility Service — required for App Blocker, Social Media Controls, Uninstall Prevention, and Website Blocker") [C5]. So an accessibility-based blur or blocker is listable. Their Play pages themselves were not read; the quotes come from a tracker's copy of the descriptions.

**Screen and audio capture (MediaProjection) on Google Play.** Apps targeting Android 14 and later declare each foreground-service type in Play Console with a description, the effect of interruption and a demo video. The media-projection type is described as: "Project media to non-primary display or external devices using the MediaProjection APIs, including streaming."; the video must "Show the user initiating an app capturing, recording, or streaming of the device screen to an external display." [D3]. Capturing in order to filter on the phone is not the case that wording describes. The earlier notes record that a rootless audio processor using the same capture route is on Play (`research_notes/System wide instrument muting app/android_rootless_interception.md`, not re-read today), so it has passed review at least once; the outcome for Waaiya is not predictable from the text.

**Other Play rules that touch current features.**

- "An app distributed via Google Play may not modify, replace, or update itself using any method other than" [D4]. The captured quote stops there; the rest of the sentence was not read. The link feature's self-updating downloader would have to be frozen in a Play build (the README already says so).
- "Apps that access or use a service or API in a manner that violates its terms of service." [D4]. Opening and saving videos from YouTube, TikTok and Instagram is the feature most likely to be refused. HaramMute keeps a link-based YouTube app on both stores [S13] [S14], but it plays a prepared audio track and how it handles the video was not examined.
- "Apps that block or interfere with another app displaying ads." [D4]. See row 6.
- VPN: "Only apps that use the VpnService and have VPN as their core functionality" may use it, with a parental-control exception [D2]. Not relevant unless a network filter is ever added.
- The one-time grant through ADB or Shizuku is not named in the policy pages read. It is a usability barrier more than a policy one.

**Outside Play: developer verification is live in part of the target market.** "Starting September 30, 2026, these new developer verification protections go live for users in Brazil, Indonesia, Singapore, and Thailand." Android "requires all apps to be registered by verified developers for users to install them on certified Android devices"; the plan is to "expand these protections globally for all apps on certified Android devices in 2027" [D5]. The same page says that in this first phase "the system verifies app installations from" seven named app stores (Google Play, HONOR App Market, OPPO App Market, Galaxy Store, Palm Store, V-Appstore, GetApps), and that the capability "will soon be expanded to all third-party Android app stores" [D5]. Routes offered to developers: full distribution (identity verification, register package names with the signing key); limited distribution without identity checks, "up to 20 devices"; or unregistered apps installed through an "advanced flow" [D5], which the press describes as "a mandatory 24-hour lock and multiple steps during installation", with ADB as the other way in [D6]. What this does today to an APK downloaded from a browser in Indonesia was not tested and is not stated plainly on the page read: treat it as unknown. The direction is clear: by 2027 a direct-download APK from an unregistered developer will need the advanced flow on certified phones everywhere. Registering needs an identity check; that decision belongs to the project owner.

**Outside Play: sideloaded accessibility services.** The project README states that Play Protect blocks installing, from a browser or file manager, an app that declares an accessibility service. That was not re-checked against a Google page today.

**How similar tools distribute (summary).**

| Tool | Where | Notes |
|---|---|---|
| HaramBlur (Android) | Google Play | Accessibility service [G13], source not published [T2], in-app purchases |
| Kahf Guard (Android) | Google Play | Accessibility service; DNS settings pointed at its own servers, "No VPN used"; free core [C5] [C4] |
| HaramMute | Google Play, App Store, Chrome and Firefox stores | A link player [S13]. Per the earlier notes it asks for none of the system-wide permissions; not re-checked today |
| Prayer Time Muter | F-Droid | Flagged there for relying on a non-free network service for prayer times [W4] |
| Kahf Browser | App Store, Google Play | A browser; filtering stays inside it [G14] |

---

## 3. Complaints about tools like Waaiya, to avoid repeating

1. **Something shows before the cover arrives.** "exposed for 1-3 seconds before detection is completed" [G3]; requests to cover first and reveal after (#111, #168) [G2]. Waaiya's fail-closed rule points the right way; the remaining 50 to 150 ms is the number users will judge.
2. **Misses at the strictest setting.** Thumbnails, small pictures, drawn figures, partly hidden people, background pictures, full-screen video [G4] [G11] [G14] [G1] [G2].
3. **Wrong covers and broken apps.** "blurring the hand of a male instructor" (#175); breakage in Notion, Jira, Slack, Udemy (#210, #191, #143) [G1] [G2]. For an overlay the equivalent is a cover that swallows taps or hides text.
4. **Heat, battery, lag.** "it's making my browser especially the videos very laggy and slow so I cant use it." [G10]; "impractical for laptop users running on battery"; "High CPU usage slows down my browser" [G11]; "Extremely High RAM Usage (Up to 2GB with Only 3 Tabs)" (#133), "بطيء" (slow, #220) [G1] [G2]; "Phone is getting hot" [G14].
5. **A see-through blur.** "50% is not enough it is still visible under the blur" [G9].
6. **Protection that is trivially undone.** The paid lock that vanishes offline [C2]; "'Unblur on hover' does not work on any site" (#222) shows the opposite failure, a reveal control that breaks [G1].
7. **It quietly stops working.** "If the plugin runs for a long time, it will become invalid." (#135), "it stoped functioning" (#184), "It's suddenly not working" (#173) [G2]; adhan apps killed by battery managers [W8, paraphrase]. A filter that dies silently is worse than none: show its state at all times and fail closed.
8. **Side effects nobody explained.** The phone that "silences itself" [W3].
9. **Closing the source and charging for the core.** [T1] [T2].
10. **Privacy claims that the store label contradicts.** [G12] [C3].
11. **Waiting, quotas and one-site coverage.** "Preparation time varies by video"; weekly minute caps; YouTube only; no live streams [S13].
12. **Ads inside a religious tool.** [S10] [W8].
13. **Reporting a mistake is a chore.** "it is very tedious for someone to go out of his way and report it." [G4].
14. **Forcing the user into the tool's own browser or player**, where he loses his ad blocker and other add-ons [G7] [G3].
15. **Arabic that needs fixing.** (#218, #163) [G1] [G2].
16. **A crash during first-run setup.** [C6]. Waaiya's setup (Shizuku or ADB) is longer than any competitor's, so this risk is higher.
17. **Sound and picture out of step, speech damaged, instruments left in.** From the earlier notes (`existing_apps_and_platform_features.md`, Key Question 4); not re-read today.

---

## 4. Not worth building

| Idea | Why not |
|---|---|
| A full prayer-times, adhan and qibla app | Crowded and free elsewhere [W4] [C5]; location data is where trust was lost [T3]. At most, a small auto-silent and "mute at adhan" switch computed on the phone (rows 9 and 16) |
| Prayer-time app locks | A dozen or more apps already do it (search results); needs accessibility or usage access [W7] |
| Website filtering through DNS or a VPN | Kahf Guard does it free at large scale [C5]; it needs servers, which conflicts with "nothing is sent anywhere"; VPN use on Play is limited to apps whose core is a VPN [D2] |
| Hiding Reels, Shorts and statuses inside other apps | Served by Kahf Guard and HaramBlur iPhone [C5] [G12]; needs an accessibility service tied to each app's layout, which breaks with their updates and blocks direct-download installs |
| Partner reports, remote parental dashboards | They send what the user does to someone else through a server: conflicts with a settled rule. A local waiting period and PIN meet most of the ask [C1] |
| Blocking uninstall | Needs accessibility or device-admin; policy-sensitive [D2]; and "No software is 100% bypass-proof" [C4] |
| Processing links on a server | Conflicts with a settled rule; it is exactly what users wait on with HaramMute [S13] |
| A library of children's shows | Others license and curate content [F1]; Waaiya's strength is filtering what the child already watches |
| Controlling the tune a caller hears while waiting | Set by the carrier; no app can change it. The ask is old [S9] |
| System-wide filtering on iPhone | Apple gives no route; competitors are confined to their own browser and rated poorly for it [G12]. Only the planned in-app player and Safari extension are realistic |
| Blocking ads | Forbidden on Play [D4]; removing instruments from an ad's sound is a different act, but keep the two clearly apart in wording |
| Scanning the keyboard, gallery or sticker suggestions as separate features | No ask found; the overlay already covers those screens |
| Any "is this allowed?" verdict, content score or built-in ruling | Conflicts with the rule that the app applies the user's choice and decides nothing |

---

## 5. Conflicts with settled rules, flagged rather than worked around

- **Partner reports** (Nafs [C6], general blockers in search results) and **remote parental control** (Kahf Guard premium [C4]) need data to leave the phone.
- **Hard locks** must still be the user's own earlier choice, with a stated way out (for example the waiting period ending), or they stop being "the user's choice".
- **Prayer times** need a place. A manual city or a one-time coarse location kept on the phone fits the rules; a location service does not.
- **Error reports** are wanted [G4], but an automatic upload breaks "nothing is sent". An export the user sends himself fits.

---

## 6. Ideas of my own (not asked for by anyone found)

- Local waiting period before any weakening of protection takes effect (built on [C1] [C3]).
- "Mute at adhan" using the audio path Waaiya already holds (built on [W6] [W11]).
- A Ramadan preset that raises strictness for the month (built on [W9]).
- A one-screen helper that sets plain ringtone and notification tones (built on [S7] [S8]).
- Announce every automatic action in a notification, because of [W3].
- A public page with measured battery and heat figures per phone model, because of section 3 item 4.

---

## 7. Sources

Status: **opened** = I read the page on 2026-11-11 through the page-reading tool. Quotes pass through that tool's summariser, so they are kept short. Anything not listed as opened is in section 8.

**Sound**

- [S1] Islamweb fatwa 118646, question (2009): https://islamweb.net/en/fatwa/118646/watching-islamic-tv-channels-which-have-music-in-their-programmes (opened)
- [S2] Islamweb fatwa 383449, question (2018): https://islamweb.net/en/fatwa/383449/playing-with-games-that-have-music (opened)
- [S3] Islamweb fatwa 445450, question (2021, Arabic): https://www.islamweb.net/ar/fatwa/445450/ (opened)
- [S4] Islamweb fatwa section listing, entries 439249 and 428914 (Arabic): https://www.islamweb.net/ar/fatawa/894?pageno=4 (opened; listing excerpts only)
- [S5] Askimam question via islamqa.org: https://islamqa.org/hanafi/askimam/81070/are-cartoon-movies-and-video-games-allowed/ (opened)
- [S6] Muftionline question via islamqa.org: https://islamqa.org/hanafi/muftionline/106759/listening-to-audio-lectures-which-have-nazams-in-the-background/ (opened)
- [S7] IslamQA 47407, question (2004): https://islamqa.info/en/answers/47407 (opened)
- [S8] IslamQA 223175, question (2014, Arabic): https://islamqa.info/ar/answers/223175 (opened)
- [S9] IslamQA 247030, question (2016, Arabic): https://islamqa.info/ar/247030 (opened)
- [S10] Quran Pro reviews on a review aggregator: https://justuseapp.com/en/app/537070378/coran-pro-quran-muslim/reviews (opened; no dates shown)
- [S11] SeekersGuidance question (2024): https://seekersguidance.org/answers/guidance-answers/can-we-listen-to-quran-recitations-with-ads-in-the-video-shaykh-anas-al-musa/ (opened)
- [S12] iPhoneIslam article (Jan 2026): https://iphoneislam.com/en/2026/01/when-the-holy-quran-becomes-a-commodity-in-app-stores/162954 (opened)
- [S13] HaramMute site: https://haram-mute.com/ (opened)
- [S14] HaramMute App Store listing: https://apps.apple.com/qa/app/harammute-watch-without-music/id6787372614 (opened)
- [S15] HaramMute Firefox reviews: https://addons.mozilla.org/en-US/firefox/addon/harammute/reviews/ (opened)
- [S16] Ibn Baz fatwa 2652, question (Arabic): https://binbaz.org.sa/fatwas/2652/%D8%AD%D9%83%D9%85-%D8%B3%D9%85%D8%A7%D8%B9-%D8%B5%D9%88%D8%AA-%D8%A7%D9%84%D9%85%D8%B1%D8%A7%D8%A9-%D9%81%D9%8A-%D9%88%D8%B3%D8%A7%D9%89%D9%84-%D8%A7%D9%84%D8%A7%D8%B9%D9%84%D8%A7%D9%85 (opened)
- [S17] Islamweb fatwa 92343, question (2006): https://www.islamweb.net/en/printfatwa.php?id=92343 (opened)

**Sight**

- [G1] HaramBlur open issues, page 1: https://github.com/alganzory/HaramBlur/issues (opened; titles)
- [G2] HaramBlur open issues, pages 2 to 4: https://github.com/alganzory/HaramBlur/issues?page=2&q=is%3Aissue+is%3Aopen , https://github.com/alganzory/HaramBlur/issues?page=3&q=is%3Aissue+is%3Aopen , https://github.com/alganzory/HaramBlur/issues?page=4&q=is%3Aissue+is%3Aopen (opened; titles)
- [G3] Issue 190: https://github.com/alganzory/HaramBlur/issues/190 (opened)
- [G4] Issue 64, false negatives: https://github.com/alganzory/HaramBlur/issues/64 (opened)
- [G5] Issue 221, games: https://github.com/alganzory/HaramBlur/issues/221 (opened)
- [G6] Issue 201, Android TV: https://github.com/alganzory/HaramBlur/issues/201 (opened)
- [G7] Issue 177, Play app and ads (Arabic): https://github.com/alganzory/HaramBlur/issues/177 (opened)
- [G8] Issue 15, ads: https://github.com/alganzory/HaramBlur/issues/15 (opened)
- [G9] HaramBlur Firefox reviews, page 1: https://addons.mozilla.org/en-US/firefox/addon/haramblur/reviews/ (opened)
- [G10] Page 2: https://addons.mozilla.org/en-US/firefox/addon/haramblur/reviews/?page=2 (opened)
- [G11] Page 3: https://addons.mozilla.org/en-US/firefox/addon/haramblur/reviews/?page=3 (opened)
- [G12] HaramBlur App Store listing: https://apps.apple.com/lb/app/haramblur/id6741595731 (opened)
- [G13] HaramBlur Android on a third-party tracker: https://appgoblin.info/apps/com.haramblur (opened; tracker figures, not Google's)
- [G14] Kahf Browser App Store listing and reviews: https://apps.apple.com/us/app/kahf-browser/id6478084743 (opened)
- [G15] Kahf Browser on Trustpilot (5 reviews): https://ca.trustpilot.com/review/kahfbrowser.com (opened)
- [G16] Issue 209, sound-based detection: https://github.com/alganzory/HaramBlur/issues/209 (opened)

**Worship and time**

- [W1] IslamQA 10193, question (2002, Arabic): https://islamqa.info/ar/answers/10193 (opened)
- [W2] Echorouk article (Sep 2009, Arabic): https://www.echoroukonline.com/%d8%b5%d9%84%d8%a7%d8%a9-%d8%a7%d9%84%d8%aa%d8%b1%d8%a7%d9%88%d9%8a%d8%ad-%d8%b9%d9%84%d9%89-%d8%a3%d9%86%d8%ba%d8%a7%d9%85-%d8%a3%d8%ae%d8%b5%d9%85%d9%83-%d8%a2%d9%87/amp (opened)
- [W3] Samsung Community thread (Feb 2024, Arabic): https://community.samsung.com/sa/conversations/%D8%AC%D8%A7%D9%84%D8%A7%D9%83%D8%B3%D9%89-A/Moh/r2_15464951 (opened)
- [W4] Prayer Time Muter on F-Droid: https://f-droid.org/en/packages/com.prayertimemuter/ (opened)
- [W5] PrayQuiet repository: https://github.com/codeswot/prayQuiet (opened)
- [W6] Prayer Audio Controller: https://prayer-audio-controller.pages.dev/ (opened)
- [W7] FivePrayer blog (Jul 2026): https://fiveprayer.app/blog/lock-phone-for-prayer (opened; vendor blog)
- [W8] Unstar blog on prayer-app reviews (Jun 2026): https://unstar.app/blog/muslim-pro-quran-majeed-athan-pillars-tarteel-quran-prayer-apps-ranked-2026 (opened; third-party, paraphrases reviews, gives no counts, carries sponsored placements)
- [W9] Religion News Service piece republished by the Salt Lake Tribune (May 2019): https://www.sltrib.com/religion/2019/05/15/smartphone-is-weapon-mass/ (opened)
- [W10] Ibn Baz fatwa 14547, question (Arabic): https://binbaz.org.sa/fatwas/14547/%D8%AA%D9%88%D8%AC%D9%8A%D9%87-%D9%84%D9%85%D9%86-%D9%8A%D8%B3%D9%87%D8%B1-%D9%88%D9%8A%D8%B6%D9%8A%D8%B9-%D8%B5%D9%84%D8%A7%D8%A9-%D8%A7%D9%84%D9%81%D8%AC%D8%B1 (opened)
- [W11] Athan Auto Pause on the Chrome Web Store: https://chromewebstore.google.com/detail/klhhofgiofihonmfkkgdfalkgnbcgdnl (opened)

**Self-control**

- [C1] Issue 139, waiting period: https://github.com/alganzory/HaramBlur/issues/139 (opened)
- [C2] Issue 207, password offline: https://github.com/alganzory/HaramBlur/issues/207 (opened)
- [C3] Kahf Guard App Store listing and reviews: https://apps.apple.com/us/app/kahf-guard-screen-time-control/id6479974796 (opened)
- [C4] Kahf Guard FAQ: https://kahfguard.com/faq/ (opened)
- [C5] Kahf Guard Android on a third-party tracker: https://appgoblin.info/apps/com.kahf.dns (opened; tracker figures, not Google's)
- [C6] Nafs App Store listing: https://apps.apple.com/us/app/id6762494633 (opened)
- [C7] Islamweb article (2021): https://www.islamweb.net/en/ramadan/article/234430/social-media-addiction (opened)
- [C8] FutureStartup profile of Kahf Guard (Mar 2024): https://futurestartup.com/2024/03/31/kahf-guard-your-ultimate-haram-blocker-on-the-internet/ (opened; promotional)

**Family**

- [F1] One4Kids TV App Store listing and reviews: https://apps.apple.com/gb/app/one4kids-tv/id1291443677 (opened)
- [F2] The Muslim Vibe (May 2017): https://themuslimvibe.com/community/this-father-of-three-is-creating-a-netflix-like-app-for-muslim-kids (opened)
- [F3] Amaliah (Aug 2023): https://www.amaliah.com/post/66833/9-alternative-channels-cocomelon (opened)

**Trust**

- [T1] Issue 211, monetisation: https://github.com/alganzory/HaramBlur/issues/211 (opened)
- [T2] Issue 189, open the app's source: https://github.com/alganzory/HaramBlur/issues/189 (opened)
- [T3] Al Jazeera (Nov 2020): https://www.aljazeera.com/news/2020/11/17/report-us-military-buying-location-data-on-popular-muslim-apps (opened)
- [T4] Issue 16, other languages: https://github.com/alganzory/HaramBlur/issues/16 (opened)

**Distribution**

- [D1] Google Play, use of the AccessibilityService API: https://support.google.com/googleplay/android-developer/answer/10964491?hl=en (opened)
- [D2] Google Play, permissions and APIs that access sensitive information: https://support.google.com/googleplay/android-developer/answer/9888170?hl=en (opened)
- [D3] Google Play, foreground service types: https://support.google.com/googleplay/android-developer/answer/13392821?hl=en (opened)
- [D4] Google Play, device and network abuse: https://support.google.com/googleplay/android-developer/answer/9888379?hl=en (opened)
- [D5] Android developer verification: https://developer.android.com/developer-verification/guides?hl=en (opened)
- [D6] Android Authority timeline (Jun 2026): https://www.androidauthority.com/android-sideloading-changes-timeline-3679204/ (opened)

---

## 8. Not verified

**Blocked or unreadable.**

- Reddit: search and page reads are both refused. No Reddit evidence is in this file. This is the largest gap, since r/islam, r/MuslimLounge and similar were named as places to look.
- Google Play: the HaramBlur listing page came back empty, so its reviews could not be read. The Play pages of Kahf Guard, HaramMute and the prayer-lock apps were not tried after that. Install and rating figures for Android apps come from a third-party tracker [G13] [C5]. For Kahf Guard a search result showed a different, smaller rating count than the tracker page I opened.
- Chrome Web Store page of the Safe Gaze extension: empty.
- Telegram channels and YouTube descriptions or comments in Arabic: searches returned nothing relevant.
- Returned errors: religionnews.com (used the Salt Lake Tribune's republication instead), marlvel.ai, apkpure.com, daruliftabirmingham.co.uk, the Eye Protector add-on page.
- nomusic.app and musicremover.org returned only their titles today; anything about them rests on the earlier notes.

**Seen only in search results, not opened** (used for orientation, not as evidence in the table): the prayer-time app locks (Awda, Deeny, Asr, Salah Lock, Khushu and others); general blockers with partner reports (BlockerX, Safe Surfer, Porn Block Plus); Egypt's Dar al-Ifta page on women's voices; AboutIslam answers; Ramadan phone-use surveys (TGM, Statista, Arab News); the academic paper on accessibility-service leaks; Ali Huda and Durioo+ listings.

**Developer verification.** The rule is live in Brazil, Indonesia, Singapore and Thailand since 2026-09-30 [D5]. Whether a browser-downloaded APK from an unregistered developer is already stopped or slowed there was not tested, and the page read names only seven app stores for the first phase. The rest of the self-update sentence in [D4] was not captured.

**Taken from the project's own files, not re-checked on the web today:** Play Protect blocking sideloaded apps that declare an accessibility service; a rootless audio processor being listed on Play; Android not letting an app capture ring and notification sound; HaramMute asking for no system-wide permission; the complaints about sync and audio quality in section 3 item 17.

**Asks I looked for and did not find.** Indecent GIF or sticker suggestions in keyboards; gallery pictures; music on WhatsApp statuses specifically; interface sounds of apps; a caller tune with music chosen by the other person; stopping media at the adhan on a phone; battery drain of a real-time audio filter on a phone; demand expressed in Urdu, Indonesian, Malay, Turkish or French (searches returned general tools only); shared family phones.

**Limits of the method.** Quotes came through the page-reading tool's summariser, which sometimes splits a sentence into pieces; they are short for that reason and should be re-checked before being reused in public text. Some App Store reviews show a day and month without a year. HaramBlur's issue tracker supplies a large share of the sight evidence: many authors, but one project's users. Whether the HaramBlur Android app captures the screen or relies on accessibility screenshots is unknown. Whether the open requests in row 7 have since shipped in HaramBlur was not checked. The age of several fatwa questions (2002 to 2016) shows the concern is long-standing, not that it is as common today.
