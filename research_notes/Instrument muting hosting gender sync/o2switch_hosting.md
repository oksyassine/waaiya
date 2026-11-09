# o2switch shared hosting: what it can and cannot run (instrument-removal project), as of Nov 2026

Research date: 2026-11-09. All o2switch figures come from o2switch.fr, faq.o2switch.fr and the o2switch CGV, fetched on that date unless another date is given. Where o2switch publishes no figure, that is stated explicitly.

## 1. Current o2switch plans and exact resource limits

### Takeaway
Since Feb 2025, o2switch has split its historic "Offre Unique" into three cPanel/CloudLinux tiers: Grow (8 vCPU / 16 GB / 16 MB/s IO), Cloud (12 vCPU / 48 GB / 42 MB/s), Pro (24 vCPU / 64 GB / 84 MB/s). These are per-account CloudLinux LVE caps on a shared server, not dedicated resources. o2switch does **not** publish EP, NPROC, IOPS or PHP max_execution_time values. The binding limits for compute come from the CGV: no process above 420 consecutive CPU-seconds, max 500,000 inodes, max 20,000 files per directory, max 50 GB per file.

### Cited Findings
**Plan line-up and history**
- On 18 Feb 2025, o2switch replaced the single unlimited offer it had sold since 2009 with three tiers: Grow, Cloud and Pro. All three have unlimited bandwidth and disk, 24/7 French support and a 30-day money-back guarantee — [JDN, 18 Feb 2025](https://www.journaldunet.com/cloud/1539285-o2switch-lance-de-nouvelles-offres-un-changement-qui-fait-du-bien/)
- The o2switch homepage (Nov 2026) still markets "L'Offre Unique" "à partir de 1,86€" HT/month, "paiement annuel. Renouvellement au tarif classique", with "Espace disque Illimité NVMe + RAMfs", "Nom de Domaine Inclus" and "Nombre de sites : Illimité". It also lists Grow, Cloud, Pro, "Managed Bare-Metal" (managed dedicated server), domain names and o2switch Drive — [o2switch.fr](https://www.o2switch.fr/)
- Comparison sites describe Cloud as the "ancienne offre unique" — [search summary of codeur.com / clubic comparatifs](https://www.codeur.com/comparatif/hebergement-web/o2switch). The "Offre Unique" link on the homepage goes to /hebergement-illimite/, which shows the three-tier page — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)

**Per-tier LVE quotas (official page)**
- Grow: "8 vCPU", "16 Go RAM", "I/O 16MB/s", "4 Lunes" (lunes = extra cPanel accounts). Grow lunes share resources with the main account — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)
- Cloud: "12 vCPU", "48 Go RAM", "I/O 42MB/s", "8 Lunes" — [same](https://www.o2switch.fr/hebergement-illimite/)
- Pro: "24 vCPU", "64 Go RAM", "I/O 84MB/s", "16 Lunes", "Espace disque Illimité NVMe + RAMfs" — [o2switch.fr/hebergement-entreprise](https://www.o2switch.fr/hebergement-entreprise/)
- Official wording: "Les ressources exprimées sont les quotas réels de limite LVE Cloudlinux / compte d'hébergement." and "Ressources allouées indépendantes par lune en Cloud. et/ou Pro." — [o2switch.fr/hebergement-entreprise](https://www.o2switch.fr/hebergement-entreprise/)
- Storage "Espace disque Illimité 100% NVMe" (Grow/Cloud); "Transfert Mensuel Illimité" on all tiers; unlimited sites, databases, email and FTP accounts; "Univers Web (Jusqu'à 17 comptes cPanel)"; daily backups kept 30 / 45 / 90 days (Grow / Cloud / Pro) — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)
- PHP "de 5.2 à 8.4 en Simultané"; MySQL 8.x / MariaDB 10.6.x. The page also has a second table listing older versions, so it is internally inconsistent — [same](https://www.o2switch.fr/hebergement-illimite/)
- An add-on called "Scale'UP" is listed at "36 € HT / Mois" without further detail — [o2switch.fr/hebergement-entreprise](https://www.o2switch.fr/hebergement-entreprise/)

**Prices (HT; TTC "dépend du pays et des conditions de facturation")**
- Grow: 7,00 € HT/month, "84.00€ HT pour 12 mois" — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)
- Cloud: list price 16,00 € HT/month; promo 1,86 € HT/month = "22,32€ HT pour 12 mois" (instead of 192 € HT) — [same](https://www.o2switch.fr/hebergement-illimite/)
- Pro: list price 24,00 € HT/month; promo 6,25 € HT/month = "75.00€ HT pour 12 mois" (instead of 288 € HT) — [o2switch.fr/hebergement-entreprise](https://www.o2switch.fr/hebergement-entreprise/)
- Renewal: "Renouvellement au tarif habituel" / "Hors renouvellement". The page gives no explicit renewal figure — [same](https://www.o2switch.fr/hebergement-illimite/)
- Earlier promo prices quoted in the press: Cloud at 1,76 € HT/month in Feb 2025 — [JDN](https://www.journaldunet.com/cloud/1539285-o2switch-lance-de-nouvelles-offres-un-changement-qui-fait-du-bien/)

**Hard limits in the CGV** ("Conditions Générales de Vente - Offre Unique o2switch - Version du 26 Août 2019")
- "Afin d'éviter la saturation des serveurs, vous ne devez pas : Faire fonctionner tout processus demandant plus 2.9ghz de ressources CPU, plus de 48go de mémoire vive, plus de 420 secondes consécutives d'utilisation du CPU, ou utilisant plus de 95% de toutes les ressources d'un serveur physique, n'importe quand." — [o2switch CGV](https://www.o2switch.fr/cgv/)
- "Consommer plus de 10000pps, au même moment, sur l'interface réseau du serveur hébergeant votre site." — [CGV](https://www.o2switch.fr/cgv/)
- "Stocker ou héberger un fichier dont la taille unique est supérieure à 50go." / "Créer un répertoire contenant, à lui seul, plus de 20000 fichiers" / "Utiliser plus de 500000 inodes sur un même espace d'hébergement web." — [CGV](https://www.o2switch.fr/cgv/)
- "Les archivages ne sont plus effectués à partir cent milles fichiers sur un même compte" (no backups above 100,000 files) — [CGV](https://www.o2switch.fr/cgv/)

**Resource-usage FAQ (updated 14 May 2025)**
- cPanel "Utilisation des ressources" shows CPU, Physical Memory, Input/Output, Entry Process ("Nombre de connexions actives sur le serveur web pour votre compte") and Processes ("Nombre de processus en cours d'exécution"). The FAQ gives no numeric cap for EP or Processes — [faq.o2switch.fr suivi-usage-ressources](https://faq.o2switch.fr/cpanel/mesures/suivi-usage-ressources/)
- Hitting "le plafond CPU ou I/O sur les dernières 24h" occasionally is called normal. "consommer plus de 50% du temps l'ensemble des ressources attribuées" is called abnormal. Hitting the process limit "peut causer des erreurs 503" — [same](https://faq.o2switch.fr/cpanel/mesures/suivi-usage-ressources/)
- Generic CloudLinux semantics: EP counts concurrent Apache/dynamic entries plus SSH sessions and cron jobs. NPROC caps all processes and threads in the LVE, and CloudLinux recommends NPROC > EP + 15 — [CloudLinux docs](https://docs.cloudlinux.com/cloudlinuxos/limits/). Common defaults at other hosts are NPROC 100 / EP 20, but these are **not** o2switch values — [bacloud](https://www.bacloud.com/en/blog/240/what-is-nproc-and-why-it-matters-for-website-performance.html)

### Inferences
- "vCPU" on the tier pages most likely means the LVE SPEED cap expressed in cores (e.g. Grow = 800% SPEED). The CGV per-process cap ("2.9 GHz", "420 s consécutives") is stricter in practice for batch compute than the LVE caps.
- The CGV found at /cgv/ is still titled "Offre Unique" and dated 2019. It is very likely the contract that still applies to Grow/Cloud/Pro, since no newer CGV was found, but this is unconfirmed.
- For a Python/Node API, the unpublished EP/NPROC values matter more than vCPU. They can be read from cPanel → "Utilisation des ressources" after signup, or asked from support.

### Gaps
- o2switch publishes no figures for EP, NPROC, IOPS, PMEM-vs-VMEM split, PHP max_execution_time / memory_limit defaults, or Passenger idle timeout. None of these were found in the FAQ, plan pages or CGV.
- No independent forum post (2025–2026) giving measured EP/NPROC values on the new tiers was found.
- It is unclear whether a newer CGV specific to Grow/Cloud/Pro exists. The only CGV found is dated 26 Aug 2019.
- What "Scale'UP" (36 € HT/month) provides is not described on the pages fetched.
- The specs and price of the "Managed Bare-Metal" dedicated offer were not fetched.

## 2. Long-running processes, Python/Node apps, SSH, pip/wheels, GPU

### Takeaway
SSH (web terminal and classic client), cron, Git, and cPanel "Setup Python App" / "Setup Node.js App" (Phusion Passenger) are all available, and pip/npm work. Compilers are blocked by default but can be unblocked on request. Passenger web apps are supported. Persistent daemons or workers, however, are forbidden by the CGV, even though the Node.js FAQ tolerates a manually launched, cron-restarted bot. o2switch offers no GPU on shared hosting.

### Cited Findings
- **Python:** "les versions 2.7, 3.3 … 3.10, 3.11, 3.12 de Python sont proposées" (list updated 03/10/24; page updated 24 June 2026). "En arrière-plan, cela utilise Phusion Passenger et la wsgi". You can "installer les dépendances avec pip". A virtualenv is created and a `source` command is given for SSH use. Apps "peut être lancée, stoppée, relancée" — [faq.o2switch.fr Python](https://faq.o2switch.fr/cpanel/logiciels/hebergement-python-multi-version)
- **Compilers:** "l'accès aux compilateurs est bloqués sur les hébergements", and unblocking can be requested from support — [faq Python](https://faq.o2switch.fr/cpanel/logiciels/hebergement-python-multi-version); same statement in the [Node.js FAQ](https://faq.o2switch.fr/cpanel/logiciels/hebergement-nodejs-multi-version)
- **Node.js:** versions "6, 8, 9, 10, 11, 12, 14, 16, 18, 20, 22 et 24" (updated 04/06/2026), run through Phusion Passenger, which relaunches a web app that stops responding. For a non-web process such as a bot, the FAQ says "il ne faudra pas lancer l'application à partir de l'outil car c'est uniquement prévu pour une application web", says to launch it manually, and adds "Il faudra prévoir un moyen de relancer le processus s'il est interrompu" (a cron job is recommended) — [faq Node.js, updated 4 June 2026](https://faq.o2switch.fr/cpanel/logiciels/hebergement-nodejs-multi-version)
- **Terminal limits:** The cPanel web terminal has "quelques restrictions supplémentaires sur le nombre de processus" and often produces "wasm memory", "fork failed" or "out of memory" errors. "Avec un client SSH classique, il y a moins de restrictions en place." — [faq Node.js](https://faq.o2switch.fr/cpanel/logiciels/hebergement-nodejs-multi-version); [faq Terminal, updated 26 Apr 2025](https://faq.o2switch.fr/cpanel/outils-avances/terminal-ssh-web)
- **SSH:** Shell access is "actif de base sur la majorité des nouveaux comptes d'hébergement". Older accounts may need support to enable it. The FAQ mentions "demander le passage en liste blanche" for external SSH clients such as PuTTY, i.e. IP whitelisting — [faq Terminal](https://faq.o2switch.fr/cpanel/outils-avances/terminal-ssh-web)
- **Other tools:** The cPanel docs include Setup Ruby App, cron ("Tâches Cron"), and Git Version Control — [faq.o2switch.fr/cpanel](https://faq.o2switch.fr/cpanel)
- **CGV prohibitions relevant to workers:** "Faire fonctionner des programmes en mode server-side sur le serveur. Cela inclut toutes sortes de daemons, comme IRCD." / "Faire fonctionner tout programme binaire autres que ceux mis à disposition par o2switch." — [CGV](https://www.o2switch.fr/cgv/)
- **GPU:** None of the plan pages or the homepage mention a GPU. Resources are listed only as vCPU, RAM and I/O — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/), [o2switch.fr](https://www.o2switch.fr/)

### Inferences
- **Websockets:** Neither FAQ covers them. Passenger can proxy websockets for Node apps in principle, but o2switch documents nothing on this, so treat it as unknown and test.
- **Daemons in practice vs. on paper:** The Node FAQ implicitly tolerates a long-running bot restarted by cron, while the CGV forbids "daemons". A background queue worker (Celery/RQ, `nohup`, `screen`) therefore sits in a grey zone, and any long CPU-heavy job is also caught by the 420-second CPU-time rule. Supervisor/systemd are not available on cPanel shared hosting, so cron-respawn is the only restart mechanism mentioned.
- **pip install onnxruntime / torch:** Both ship as prebuilt manylinux wheels, so blocked compilers should not matter. The "programme binaire autres que ceux mis à disposition" clause, read literally, covers native extensions and a downloaded ffmpeg/yt-dlp binary. The wheels need glibc ≥ 2.28 for recent versions, and CloudLinux 8 ships glibc 2.28 (inferred, not verified). A torch CPU install is roughly 0.7–1 GB and tens of thousands of files, which consumes a meaningful slice of the 500,000-inode cap. onnxruntime alone is far smaller.
- **Python ≤ 3.12:** The documented list stops at 3.12, so wheels must target cp312 or lower.

### Gaps
- No o2switch statement on glibc version, CloudLinux OS version, CPU model/AVX2/AVX-512 flags, or whether `/proc/cpuinfo` exposes AVX2. No forum report confirming onnxruntime or torch installs on o2switch was found.
- No o2switch documentation on websockets, Passenger idle-kill timeout, or whether `nohup`/`screen` processes are killed by policy scripts.
- Whether ffmpeg is available system-wide on o2switch was not confirmed.

## 3. Terms of use: CPU-heavy / AI-ML / video downloading, and what happens on overuse

### Takeaway
The CGV never names AI/ML, yt-dlp or audio processing. Its general clauses still effectively rule out an on-server separation service: the 420-consecutive-CPU-seconds rule, the bans on daemons and non-provided binaries, the rule that requests must be "nécessaires au bon fonctionnement d'un site internet", and the rule that the hosting must serve only websites. Overuse normally triggers a warning first, but o2switch reserves immediate suspension without notice if server stability is endangered.

### Cited Findings
- "l'hebergement web ne doit pas servir à d'autres usages que d'héberger des sites internet ou tout service lié … Tout autre usage est proscrit" and "Le Service … est destiné à un hébergement web conventionnel." — [CGV](https://www.o2switch.fr/cgv/)
- "Faire tout usage autre que les requêtes POST,GET,OPTIONS,PUT nécessaires au bon fonctionnement d'un site internet." — [CGV](https://www.o2switch.fr/cgv/)
- "Faire usage de tout ou partie des services … en complément de prestations d'hébergement assurées par un tiers." and "comme solution de sauvegarde directe, indirecte, ou d'un service tiers" are forbidden. Subletting is "strictement interdite" — [CGV](https://www.o2switch.fr/cgv/)
- There is no explicit "fair use" / "usage raisonnable" clause, the word "illimité" is not defined in the CGV, and robots, crawlers, downloading, streaming and computation are not explicitly mentioned — [CGV](https://www.o2switch.fr/cgv/)
- On overuse: "Généralement, le client est prévenu de la surconsommation sans que son site ne soit désactivé." / "o2switch se réserve un droit de suspension immédiate et sans préavis si celui-ci met gravement en danger la stabilité des installations." / o2switch "pourra résilier de plein droit le contrat" for breach — [CGV](https://www.o2switch.fr/cgv/)
- Technically, LVE caps throttle the account: CPU/I-O hit "le plafond", and process exhaustion gives 503 errors — [faq.o2switch.fr suivi-usage-ressources](https://faq.o2switch.fr/cpanel/mesures/suivi-usage-ressources/)
- Reviews note that resources remain shared and that some users report CPU limitations under heavy or intensive use — [search summary of Futura/Clubic/leptidigital reviews](https://www.leptidigital.fr/hebergement-web/performance-securite-support-o2switch-promesses-75129/)

### Inferences
- A "paste a video link → we download and separate it" endpoint is a compute and media-processing service, not "hébergement web conventionnel". It runs non-provided binaries (yt-dlp/ffmpeg, ONNX/torch native code) and would breach the 420 s CPU rule for any htdemucs job. It is high-risk for suspension even if the LVE technically allows it.
- Small, short CPU work inside a web request (e.g. a sub-minute ONNX inference on a short clip) is technically possible and arguably "service lié" to the site. It is still a grey zone and should not be the core service.
- Video downloading from YouTube also raises third-party ToS/copyright issues outside o2switch's terms (not researched here).

### Gaps
- No public o2switch statement or forum thread was found about AI/ML inference, yt-dlp, or audio processing specifically. Asking o2switch support in writing before deploying is the only way to get a definitive answer.

## 4. Does one offline separation job fit? Estimated jobs/day

### Takeaway
A 10-minute track through htdemucs on CPU needs roughly 3–15 minutes of wall time on several cores, i.e. thousands of CPU-seconds, far above the CGV's 420 consecutive CPU-seconds per process. It does not fit o2switch's terms. A light ONNX model (≈0.05–0.2× real time) could finish a 10-minute track in under ~420 CPU-s per process, but it remains contractually grey.

### Cited Findings
- Demucs CPU rule of thumb from its README: about 1.5× the track length on CPU — [HF forum/dataset note citing README](https://huggingface.co/datasets/John6666/forum2/commit/4850d9e7741ffcf87e598454ac6d639b9ab971ac); similar figure for a free-CPU HF Space — [HF Space discussion](https://huggingface.co/spaces/Thafx/Demucs_v4_2s_HT/discussions/1)
- PyTorch demucs on CPU: 3:15 track in 52.3 s, about 0.27× real time, on an Apple-silicon machine — [demucs-mlx PyPI benchmark](https://pypi.org/project/demucs-mlx/1.1.0/)
- htdemucs ONNX fp32 on an M4 Pro CPU: ~1.6 s per 7.8 s segment, RTF ≈ 0.20 (vendor model card) — [StemSplitio/htdemucs-onnx](https://huggingface.co/StemSplitio/htdemucs-onnx)
- Vendor blog: about 8 min on an Intel i7 and about 15 min on an i5 for htdemucs, track length not stated — [stemsplit.io (JA)](https://stemsplit.io/ja/blog/demucs-local-setup-guide)
- CGV per-process cap: 420 consecutive CPU-seconds, ≤ 2.9 GHz, ≤ 48 GB RAM — [CGV](https://www.o2switch.fr/cgv/)
- More than 50% of the time at the allocated ceiling is "abnormal" — [faq suivi-usage-ressources](https://faq.o2switch.fr/cpanel/mesures/suivi-usage-ressources/)

### Inferences (arithmetic, not measured on o2switch)
- **htdemucs, 10-min track:** at RTF 0.27–1.5, wall time is ≈2.7–15 min. With 4 threads that is ≈650–3,600 CPU-seconds in one process, 1.5–9× the 420 s rule. Shared-host Xeon/EPYC cores at ≤ 2.9 GHz are likely at the slow end (RTF ~1×), so the realistic figure is ~10 min wall and ~2,400 CPU-s. **Does not fit.** Chunking into ~1-minute segments, each in a fresh process, would technically dodge the per-process wording but is evasion of a clause written precisely to stop this. Not recommended.
- **Light ONNX model** (e.g. a 2-stem vocals/accompaniment model at RTF 0.05–0.2 on 1–2 threads): a 10-min track takes ≈30–120 CPU-seconds, which **fits under 420 s**. Memory is a few hundred MB, well within the 16 GB Grow cap.
- **Jobs/day ceiling if run anyway (Grow, 8 vCPU):** staying at about 25% average utilisation (to remain well under the "50% du temps" abnormal threshold) leaves ≈ 2 vCPU × 86,400 s ≈ 170,000 CPU-s/day. That is ≈ 70 htdemucs jobs (at ~2,400 CPU-s each), which are all contract-breaching, or ≈ 1,400–5,700 light-ONNX jobs (at 30–120 CPU-s), compute-wise. In practice, contractual risk, not capacity, is the limit.
- **Video fetch:** downloading a 10-min video with yt-dlp plus ffmpeg extraction adds network and CPU load, and both are "binaires non mis à disposition" on paper.

### Gaps
- No benchmark of demucs/ONNX on an actual o2switch server, and no o2switch CPU model data. All timings above are from other hardware.

## 5. Cheap alternatives for the compute job (EUR where possible)

### Takeaway
Hetzner is no longer the obvious €4 option. After three 2026 price rounds, the cheapest shared-vCPU cloud servers cost €5.49–5.99/month and were reported "not available" for new orders from Sept–Oct 2026, while dedicated-vCPU CCX13 is now €42.99. Oracle's Always Free ARM tier shrank to 2 OCPU / 12 GB in Aug 2026. Modal's $30/month free credits likely cover a modest HaramMute-style workload. Colab/Kaggle are not allowed as a web backend.

### Cited Findings
**Hetzner Cloud (DE/FI, EUR/month excl. VAT, new orders after 15 June 2026)**
- CX23 €3.99 → €5.49; CAX11 (ARM) €4.49 → €5.99; CPX22 €7.99 → €19.49; CPX52 €36.49 → €100.49; CCX13 €15.99 → €42.99; CCX63 €374.49 → €853.49 — [wz-it.com, 15 Jun 2026, upd. 1 Oct 2026](https://wz-it.com/en/blog/hetzner-price-increase-june-2026-cpx-ccx-alternatives/)
- The 15 June 2026 round applied to new orders and rescales only. A separate 1 April 2026 round (up to +37%) did hit existing customers — [search summary: tomshardware](https://www.tomshardware.com/tech-industry/hetzner-to-raise-prices-by-up-to-37-percent-from-april-1); [capitalandcompute, upd. 9 Nov 2026](https://capitalandcompute.net/md/hetzner-price-increase-2026.md)
- As of 1 Oct 2026, the Hetzner cloud page lists CX/CAX cost-optimized plans as "Currently not available" (since early Sept 2026). A Hetzner status notice has covered limited cloud provisioning for new customers since 26 June 2026 — [wz-it.com](https://wz-it.com/en/blog/hetzner-price-increase-june-2026-cpx-ccx-alternatives/)
- Dedicated servers rose "more moderately" (around one fifth for some series), and Server Auction is reportedly exempt from the adjustment. No per-model prices were given — [wz-it.com](https://wz-it.com/en/blog/hetzner-price-increase-june-2026-cpx-ccx-alternatives/)

**Oracle Cloud Always Free**
- "1,500 OCPU hours and 9,000 GB hours per month … VM.Standard.A1.Flex … For Always Free tenancies, this is equivalent to 2 OCPUs and 12 GB of memory"; 2× E2.1.Micro AMD VMs; 200 GB block storage; 10 TB/month outbound — [Oracle docs](https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm)
- Idle reclaim: an instance is idle if, over 7 days, its 95th-percentile CPU is < 20%, network is < 20%, and (A1 only) memory is < 20% — [Oracle docs](https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm)
- The cut from 4 OCPU / 24 GB took effect 18 Aug 2026, per Japanese reports. Many 2026 guides still quote 4/24, which is outdated — [labmemo.com](https://labmemo.com/?p=55273); [braindetox](https://braindetox.kr/en/posts/oracle_always_free_tier_reduced_2026.html)

**Modal (HaramMute's choice)**
- CPU $0.0000131/core/s (≈ $0.047/physical core-hour, where 1 core = 2 vCPU); memory $0.00000222/GiB/s (≈ $0.008/GiB-h); GPUs per second: T4 $0.000164 (≈ $0.59/h), L4 $0.000222 (≈ $0.80/h), A10 $0.000306 (≈ $1.10/h), A100-40GB ≈ $2.10/h. Starter plan is $0 base with "$30 per month of free credits" — [modal.com/pricing](https://modal.com/pricing)

**Colab / Kaggle**
- Colab disallows "file hosting, media serving, or other web service offerings not related to interactive compute with Colab". Free runtimes also may not run "remote control such as SSH shells", "bypassing the notebook UI to interact primarily via a web UI", or "running distributed computing workers". Free sessions last "at most 12 hours", and limits are unpublished and change — [Colab FAQ](https://research.google.com/colaboratory/faq.html)

### Inferences
- **Cost per job on Modal (USD; EUR ≈ 0.85–0.92× at late-2026 rates, unverified):**
  - htdemucs on a T4 for a 10-min track probably takes ~30–60 s of GPU time, i.e. about $0.005–0.01 per job.
  - On CPU (4 physical cores × ~5 min + 4 GiB), about $0.017 per job.
  - $30/month of credits therefore covers roughly 1,500–3,000 htdemucs jobs a month at those assumed speeds. The per-job runtimes are assumptions, not measurements.
- **Hetzner:** for an always-on CPU worker, a CAX11/CX23 (if orderable again) at ~€5.5–6/month or a Server Auction box is the cheapest self-managed option. CCX dedicated-vCPU is now poor value for this use.
- **Oracle Free:** 2 OCPU / 12 GB ARM is enough for a slow htdemucs queue (~1–2× real time, inferred) or comfortable for light ONNX. Batch jobs keep it above the idle-reclaim thresholds only while busy. Account availability and ARM capacity are known pain points.
- **Colab/Kaggle:** usable only for the maintainers' offline batch work (e.g. pre-processing, model export), not as the backend of a public "send a link" service.
- **Recommended split:** keep o2switch for the website, docs, downloads and a small API. Put any server-side separation on Modal (serverless, pay-per-use, matches HaramMute) or on an Oracle Free/Hetzner ARM box.

### Gaps
- No current Hetzner dedicated/AX or Server Auction per-model EUR prices were retrieved. Specs (vCPU/RAM) for CX23/CAX11 were not confirmed from a fetched page in this session.
- RunPod serverless pricing and Kaggle's current weekly GPU quota were not retrieved.
- Datacenter IPs being blocked by YouTube for yt-dlp (affecting any server-side link-fetch job, wherever it runs) was not researched here.

## 6. Hosting the website, docs, APK downloads, F-Droid repo, model files and small API on o2switch

### Takeaway
Serving static files is o2switch's core use case and fits well: unlimited NVMe disk and transfer, Git, cron and SSH. Constraints: ≤ 50 GB per file, ≤ 20,000 files per directory, ≤ 500,000 inodes per account, ≤ 10,000 packets/s, no backups above 100,000 files, and the space must serve the website, not be a generic file-host or backup target. Build the F-Droid repo locally or in CI and upload the static output. A small Python/Node API via Passenger fits as long as requests are short.

### Cited Findings
- File and inode limits (50 GB/file, 20,000 files/dir, 500,000 inodes) and the 10,000 pps network cap — [CGV](https://www.o2switch.fr/cgv/)
- "Transfert Mensuel Illimité", "Espace disque Illimité 100% NVMe" — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)
- Hosting must be for "sites internet ou tout service lié". Use as a direct or indirect backup solution, or in addition to hosting at a third party, is forbidden — [CGV](https://www.o2switch.fr/cgv/)
- Python/Node apps run through Passenger with pip/npm; cron and Git are available — [faq Python](https://faq.o2switch.fr/cpanel/logiciels/hebergement-python-multi-version), [faq Node.js](https://faq.o2switch.fr/cpanel/logiciels/hebergement-nodejs-multi-version), [faq cPanel index](https://faq.o2switch.fr/cpanel)
- Databases are "Bases de Données Illimitées" (MySQL 8 / MariaDB 10.6) — [o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/)
- The o2switch FAQ has an entry on allowing AI crawlers (robots) on your domain, so bot traffic is managed at host level — [faq questions list](https://faq.o2switch.fr/questions)

### Inferences
- **F-Droid repo:** A repo is just static files (index-v1/v2 JSON, signed jar, APKs, icons) that any web server can serve. Generating it with `fdroid update` needs Java, apksigner and the Android build-tools on the server, which are not offered and would hit the "binaires" clause. The safe pattern is to run `fdroidserver` in GitHub Actions or locally, then rsync/SFTP the `repo/` folder over SSH.
- **Model files:** ONNX models of tens to hundreds of MB, and even multi-GB Demucs checkpoints, are far below the 50 GB per-file cap. Serving them as project downloads is "service lié" to the site. Using o2switch as a CDN for a large third-party audience could attract attention under the 10,000 pps cap at very high traffic. Large release artefacts could also go to GitHub Releases or the F-Droid main repo to offload traffic.
- **APK/history growth:** keep old APK versions pruned. Thousands of versions × icons/screenshots can approach the 20,000 files/dir limit, and above 100,000 files o2switch stops backing up the account.
- **API (accounts, settings sync, telemetry opt-in):** a Flask/FastAPI-WSGI or Express app under Passenger with MySQL is a normal web workload and fits Grow. Telemetry ingestion should be batched and kept lightweight (short requests) to avoid tying up entry processes, whose limit is unpublished.
- **Cheapest fit:** Grow (7 € HT/month, 84 € HT/year), or Cloud at the promo price (22.32 € HT for the first year, then a list price of 16 € HT/month), is sufficient for website + repo + API.

### Gaps
- Whether o2switch's Passenger setup supports websockets (relevant only if live job-progress push is wanted) is undocumented.
- No o2switch statement on serving large binary downloads at high volume (e.g. a model file hit by thousands of users per day) beyond the "illimité" transfer and the 10,000 pps cap.
