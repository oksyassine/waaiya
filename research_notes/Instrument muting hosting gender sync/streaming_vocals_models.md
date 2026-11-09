# Streaming (causal, low-latency) vocals-vs-accompaniment separation: usable models now, and how to train one (status 9 Nov 2026)

Scope: models that keep the **vocals stem (singing + speech)** and remove instruments, run causally at about 10–50 ms algorithmic latency, reach RTF < 0.3 on one phone or laptop CPU core, and export to ONNX with explicit recurrent state. Each claim is marked **VERIFIED** (weights downloadable and inspected on 9 Nov 2026) or **ANNOUNCED/PAPER-ONLY**. Licences are flagged throughout. This builds on the 6 Nov 2026 survey in `research_notes/System wide instrument muting app/realtime_separation_models.md` and goes further.

---

## Q1. Have the causal music-separation papers released weights (ADI 2609.12201, Band-SCNet, HS-TasNet, RT-STT, others)?

### Takeaway
No. As of 9 Nov 2026, none of the dedicated causal music-separation papers (Analog Devices, Band-SCNet, HS-TasNet, RT-STT, Deep Latent Masking, LiteCASS) has public weights. ADI promises only tooling ("profiler, feasibility script, on-device reference runtime"), not weights. RT-STT's official repo still says "code will be released soon". Band-SCNet and HS-TasNet exist only as unofficial re-implementations without trained checkpoints. The one new exception is a **community causal Open-Unmix** (see Q2). It is trained on MUSDB18, and its weights ship only as ExecuTorch `.pte` files.

### Cited Findings
- **ADI, arXiv 2609.12201** ("Real-Time Music Source Separation on a Low-Power Audio DSP", Li, Liu, Malsky, Yi; submitted 10 Sep 2026; only v1 exists; "Submitted to ICASSP 2027"). The arXiv page lists no code or weights links — [arXiv abs](https://arxiv.org/abs/2609.12201)
- The paper's only release statement is "The profiler, the feasibility script and the on-device reference runtime will be released". It does not mention weights — [arXiv html](https://arxiv.org/html/2609.12201v1)
- ADI model details: causal TFC-TDF U-Net with GRUs and a deep-filter head, 44.1 kHz, n_fft 1024 / hop 512, keeps the lowest 384 bins (0–16.5 kHz); 131 K params, 21.9 M MAC per frame (≈1.89 GMAC/s); deployed per-stem cSDR vocals 5.09, drums 5.65, bass 3.87, other 4.18; the strictly causal deep filter (Q=0) adds 0.38 dB — [arXiv html](https://arxiv.org/html/2609.12201v1)
- ADI training recipe (useful for our own model): L1 waveform loss; AdamW at lr 1e-4; gradient-norm clip 3.0; mixed precision; batch 6 on **one T4 (8.8 GB)**; 500-frame (~5.8 s) segments. The deep-filter head is warm-started onto a converged backbone. "Training on _continuous_ rather than block-padded convolution context proves essential": a chunk-trained model scored 3.93 dB blockwise but "collapse[d] to silent output within about 2 s" when run frame by frame. GPU hours are not stated — [arXiv html](https://arxiv.org/html/2609.12201v1)
- A GitHub search (sorted by update, 9 Nov 2026) for "causal music source separation", "real-time music source separation", "sharc music separation" and similar found no ADI repository — gh API search (queries listed in method note below)
- **RT-STT** (Jundo26/RT-STT, "ICME 2025: Towards Practical Real-Time Low-Latency Music Source Separation"). The repo holds only a README with "The code will be released soon", has no licence, and was last pushed 2025-03-21 — [GitHub](https://github.com/Jundo26/RT-STT)
- RT-STT training setup: DTTNet pipeline, lr 1e-4, grad-norm clip 3, chunk 32,256 samples, **4× RTX 3090 at batch 8 each**, STFT 1024/512 — [arXiv 2511.13146](https://arxiv.org/html/2511.13146)
- **Band-SCNet**: only an unofficial work-in-progress PyTorch implementation exists. It has no licence and no checkpoints, and its metrics and "AMC internal test" are still unchecked to-dos — [olivepicker/band_scnet_pytorch](https://github.com/olivepicker/band_scnet_pytorch). A "Band-SCNet-RT-demo" repo holds only a static demo-page README — [w1m1x/Band-SCNet-RT-demo](https://github.com/w1m1x/Band-SCNet-RT-demo)
- Band-SCNet training (paper): 11-second segments, MSE loss on the complex spectrogram, MUSDB18-HQ without extra data — [Interspeech 2025 PDF](https://www.isca-archive.org/interspeech_2025/yang25d_interspeech.pdf)
- **HS-TasNet**: lucidrains' implementation is MIT-licensed, pip-installable (`HS-TasNet`), and includes a Trainer and a `sounddevice_stream()` live-inference helper. It ships **no pretrained checkpoint** ("after much training ... load from a specific checkpoint") — [lucidrains/HS-TasNet](https://github.com/lucidrains/HS-TasNet)
- Other HS-TasNet repos: 25ohms/HS-TasNet-NeutoneFX describes itself as containing checkpoints, but its git tree holds only code and configs and no `.pt` or `.nm` files (no licence). temismink/HS-Tasnet has no licence and no weights — [25ohms](https://github.com/25ohms/HS-TasNet-NeutoneFX), [temismink](https://github.com/temismink/HS-Tasnet)
- The Hugging Face model hub has no HS-TasNet, Band-SCNet, RT-STT or ADI checkpoints. Searches for "causal", "realtime", "real-time", "streaming", "low-latency", "online" and "hs-tasnet" returned no separation models — HF API `/api/models?search=` (9 Nov 2026)
- **LiteCASS** (arXiv 2609.23453, SWUFE/Xiaomi/Wuhan, Sep 2026) is a real-time **stereo speech / music / effects** separator. Specs: 1.06 M params, 0.72 GMAC/s (K8), STFT 42.7 ms window / 10.7 ms hop at 48 kHz, RTF 0.012 on a single Xeon 8358P core. DnR v3-stereo SI-SDR: speech 12.93, music 7.58, SFX 8.00 dB. The paper does not state whether it is causal or what its look-ahead is, and gives **no code or weights link** — [arXiv html](https://arxiv.org/html/2609.23453v1)
- **Yash-Bhake/RT-MSS** (MIT) is a causal BSRNN vocals model (n_fft 1024, hop 512, 44.1 kHz, feature_dim 128, 6 band/sequence RNN repeats, hidden 128). It includes `scripts/export_onnx.py` with **explicit flattened LSTM state inputs and outputs**, plus a `realtime_processor.py`. It ships a 33.8 MB checkpoint `checkpoints/v1_hugeerror_50epoch/best_model.pt`, trained via `prepare_musdb18_sampled.py` (i.e. on MUSDB18). Its training history shows loss only falling from 5650 to 4991 over 50 epochs, it reports no SDR, and the README is empty — [GitHub](https://github.com/Yash-Bhake/RT-MSS)

### Inferences
- The 6 Nov conclusion still holds: no causal, well-trained vocals model with permissively licensed weights exists. The RT-MSS checkpoint's own name ("hugeerror") and its barely-falling loss suggest it is not usable. Its **ONNX-with-state export script (MIT)** is still useful reference code for our pipeline.
- ADI's recipe shows a 131 K-param causal model trains on a single T4, which fits Kaggle and Colab free tiers (see Q5).

### Gaps
- No ADI GitHub organisation repo or Hugging Face model for 2609.12201 was found. Release may follow ICASSP 2027 decisions, but that is speculation.
- RT-STT, Band-SCNet and HS-TasNet code and weight licences are unknown because no official code exists.
- Method note: GitHub searches ran via `gh api search/repositories` for "causal music source separation", "real-time music source separation", "streaming vocal separation", "real-time vocal separation", "band-scnet", "hs-tasnet", "RT-STT separation", "sharc music separation", "causal vocal" and "low latency source separation onnx".

---

## Q2. Other candidates with downloadable weights: Open-Unmix, ZFTurbo MSST, UVR/MDX-Net, Demucs streaming, Spleeter, KUIELab, DTTNet, SCNet, vocal-remover, MossFormer, Sony, ByteDance, SAM-Audio, recent papers, open real-time projects

### Takeaway
There is exactly **one** downloadable causal vocals-capable music model: **`shuoyang-zheng/Open-Unmix-Unidirectional`** (July 2026). It is labelled MIT but trained on MUSDB18 (non-commercial terms), and it ships as 260 MB ExecuTorch `.pte` files with an MLX delegate, built for MaxMSP on Apple Silicon. Its window is probably ~93 ms. Everything else with weights is non-causal: Spleeter, Demucs, MDX, RoFormers, SCNet, DTTNet, Moises-Light, vocal-remover and ByteDance. The biggest new finding is the Sept 2026 paper **"Adapting offline models to a streaming context"** (MIT code). It shows that off-the-shelf HT-Demucs and SCNet can be streamed at 23 ms algorithmic latency without retraining (vocals SDR 6.90 / 7.45 dB), but this needs GPU-class compute (RTF 0.89–1.59 on an RTX 5080). SAM-Audio is out: its checkpoints are 5–15 GB and it is a gated diffusion-transformer model.

### Cited Findings

**Open-Unmix (causal) — VERIFIED weights**
- `shuoyang-zheng/Open-Unmix-Unidirectional` (created 2026-07-10, 42 downloads, HF tag `license:mit`) describes itself as "Open-Unmix source separation models ... trained on the MUSDB18 dataset ... with a causal setting". It contains `umx-live.pte`, `umx-live-mlx-1024.pte` and `umx-live-mlx-2048.pte` (about 260 MB each) plus JSON metadata. Inputs are stereo audio plus a `mask_power` attribute (0–4); outputs are 8 channels (vocals, drums, bass, other in L/R) — [HF model card](https://huggingface.co/shuoyang-zheng/Open-Unmix-Unidirectional), [HF API file list](https://huggingface.co/api/models/shuoyang-zheng/Open-Unmix-Unidirectional)
- Companion repo jasper-zheng/open-unmix-maxmsp (MIT, created 2026-07-10, 1 star; "Apple Silicon only"). `openunmix/export_stream.py` rebuilds UMX for streaming: "RealSTFT — a windowed cos/sin DFT expressed as a plain nn.Conv1d ... fed by cached_conv.CachedPadding1d"; "the three pretrained causal OpenUnmix cores, wrapped with **persistent LSTM state** so frame-by-frame streaming equals the full-sequence forward". "Other" is the residual of the mixture minus the three stems. Defaults are `n_fft=4096, n_hop=1024`. The export goes through `torch.export` to ExecuTorch with `mlx` or `xnnpack` delegates. The PyTorch cores (`models/umx-realtime`) are **not** in the repo or on HF — [GitHub](https://github.com/jasper-zheng/open-unmix-maxmsp)
- Upstream Open-Unmix: a three-layer BiLSTM, "cannot be used in an online/real-time manner. An uni-directional model can easily be trained as described [in docs/training.md]". `umxl` weights are "only licensed for non-commercial use (CC BY-NC-SA 4.0)"; code is MIT — [sigsep/open-unmix-pytorch](https://github.com/sigsep/open-unmix-pytorch). A Hugging Face mirror labels the umxhq/umxl `.pth` weights `cc-by-nc-sa-4.0` — [teamup-tech/Open-Unmix-weights](https://huggingface.co/teamup-tech/Open-Unmix-weights)
- Non-causal UMX-HQ vocals exported to ONNX (HF tag MIT, created 2026-09-28) — [MixDirective/open-unmix-umxhq-vocals-onnx](https://huggingface.co/MixDirective/open-unmix-umxhq-vocals-onnx)
- MUSDB18 and MUSDB18-HQ Zenodo records carry licence id `other-nc` — [Zenodo 1117372](https://zenodo.org/records/1117372), [Zenodo 3338373](https://zenodo.org/records/3338373)

**Streaming offline models without retraining — PAPER + MIT code (Sept 2026)**
- Sechet, Evrard, Kowalski (LISN/TAU), arXiv 2609.35397, submitted to ICASSP 2027. Method: "the input slides by one STFT hop, and one output hop is read out". Latency becomes L(k) = W + kH, with a floor of one hop (23.2 ms at 44.1 kHz, H=1024). L(0) = W = 92.9 ms for HT-Demucs and SCNet and 139.3 ms for DTTNet. "Quality drops steeply only below that threshold", and fine-tuning with a streaming-specific loss "does not reduce this dependency" — [arXiv abs](https://arxiv.org/abs/2609.35397), [PDF](https://arxiv.org/pdf/2609.35397)
- Table 1 (median SDR on MUSDB18-HQ):

  | Model | Latency | Vocals SDR | Overall SDR | RTF (RTX 5080) |
  |---|---|---|---|---|
  | HT-Demucs streamed | 23 ms | 6.90 | 6.97 | 0.89 |
  | HT-Demucs streamed | 93 ms | 8.49 | 8.47 | 0.89 |
  | HT-Demucs offline | — | 8.91 | 8.84 | 0.0053 |
  | SCNet streamed | 23 ms | 7.45 | 6.99 | 1.59 |
  | SCNet streamed | 93 ms | 8.67 | 8.51 | 1.59 |
  | SCNet offline | — | 9.35 | 9.25 | — |
  | DTTNet streamed | 23 ms | 8.10 | 6.06 | 1.57 |
  | DTTNet streamed | 93 ms | 9.69 | 7.51 | 1.57 |
  | DTTNet offline | — | 10.34 | 7.94 | 0.0123 |

  For comparison at 23 ms: HS-TasNet vocals 5.13, RT-STT 5.56, Deep Latent Masking 6.91. At 93 ms: Band-SCNet 8.74 — [PDF](https://arxiv.org/pdf/2609.35397)
- "Only HT-Demucs runs faster than real time on our GPU, with a median RTF of 0.89 ... one HT-Demucs pass takes about 20.6 ms, so each separated sample leaves the pipeline about 44 ms after it arrives. Offline pipelines reach RTFs two orders of magnitude lower" — [PDF](https://arxiv.org/pdf/2609.35397)
- Code: [dylansechet/mss_streaming](https://github.com/dylansechet/mss_streaming) (MIT, created 2026-09-21). It uses the official SCNet and DTTNet weights (Google Drive and Baidu links) and MUSDB18-HQ. "A GPU is strongly recommended" — [GitHub README](https://github.com/dylansechet/mss_streaming); listening samples from 23 ms to 3060 ms — [project page](https://dylansechet.com/papers/mss-streaming)

**ZFTurbo Music-Source-Separation-Training (MIT code) — VERIFIED weights, all non-causal**
- The pretrained list includes vocals models: MDX23C 10.17, HTDemucs4 (MVSep fine-tune) 8.78, BS-RoFormer viperx 10.87, Mel-RoFormer KJ 10.98, BS PolarFormer 11.00 and BS Mamba2 8.82 (MUSDB18-only) SDR on Multisong. Small 4-stem models: **DTTNet** (MUSDB vocals 10.31), **SCNet Small** (vocals 9.90), SCNet Tran Small 9.97, SCNet Masked Small 10.05 — [docs/pretrained_models.md](https://github.com/ZFTurbo/Music-Source-Separation-Training/blob/main/docs/pretrained_models.md)
- The repo (MIT, pushed 2026-11-08) has **no causal or streaming model configs**. The file tree contains no "causal", "realtime" or "online" configs. `scripts/stream.py` is a PyAudio wrapper around offline `demix()`. New lightweight config `config_musdb18_moises_light.yaml`: Moises-Light "paper_large preset (4.7M params, 0-14.7 kHz)", other presets 2.5–8.4 M params, n_fft 6144, 9-second chunks (non-causal) — [GitHub tree](https://github.com/ZFTurbo/Music-Source-Separation-Training), [moises-light config](https://github.com/ZFTurbo/Music-Source-Separation-Training/blob/main/configs/config_musdb18_moises_light.yaml); moises-light repo is MIT — [crlandsc/moises-light](https://github.com/crlandsc/moises-light)
- Weight licences in the ZFTurbo list are mostly unstated and models are MUSDB18-trained. KimberleyJSN Mel-RoFormer is tagged MIT on HF; becruily's vocals model has no licence tag; viperx BS-RoFormer is hosted in UVR's model_repo with no licence found — [HF KimberleyJSN](https://huggingface.co/KimberleyJSN/melbandroformer), [HF becruily](https://huggingface.co/becruily/mel-band-roformer-vocals)

**Spleeter 2-stem — VERIFIED (MIT)**
- deezer/spleeter is MIT and still maintained (pushed 2026-10-28). The 2-stem config is vocals plus accompaniment, 44.1 kHz, `frame_length 4096`, `frame_step 1024`, `T 512` frames, `F 1024` bins, U-Net — [GitHub](https://github.com/deezer/spleeter), [2stems.json](https://github.com/deezer/spleeter/blob/master/spleeter/resources/2stems.json)
- An open Mixxx 2.5 fork runs "real-time 4-stem separation (Spleeter 4stems, ONNX)" through ONNX Runtime C++ and bundles all four models — [ukirdeomkar/mixxx-spleeter-4stem](https://github.com/ukirdeomkar/mixxx-spleeter-4stem)
- On an unnamed mobile device Spleeter took 23.32 ms per 1 s of input (Open-Unmix 94.6 ms) — [GSEP arXiv 2010.12139](https://arxiv.org/pdf/2010.12139) (via earlier survey)

**Demucs / denoiser**
- Demucs is "released under the MIT license"; the repo is archived. "Hybrid Transformer models only support a maximum segment length of 7.8 seconds" — [facebookresearch/demucs](https://github.com/facebookresearch/demucs)
- HTDemucs-ft vocals ONNX on HF (tag MIT, created 2026-10-01) — [Jeremytromp/htdemucs-ft-vocals-onnx](https://huggingface.co/Jeremytromp/htdemucs-ft-vocals-onnx); a CoreML port exists — [tlfares/htdemucs-vocals-coreml](https://huggingface.co/tlfares/htdemucs-vocals-coreml)
- facebookresearch/denoiser ("Real Time Speech Enhancement in the Waveform Domain") is a **causal** waveform Demucs that "runs in real-time on a laptop CPU", ships a `denoiser.live` loopback tool, and has pretrained `dns48`, `dns64` and `master64`. Each extra frame of batching adds 16 ms latency. **Licence: CC BY-NC 4.0** (LICENSE: "Attribution-NonCommercial 4.0 International"); the repo is archived. It is speech-only — [GitHub](https://github.com/facebookresearch/denoiser)

**UVR / MDX-Net / python-audio-separator**
- UVR GUI is MIT — [Anjok07/ultimatevocalremovergui](https://github.com/Anjok07/ultimatevocalremovergui); python-audio-separator is MIT — [nomadkaraoke/python-audio-separator](https://github.com/nomadkaraoke/python-audio-separator). Individual MDX and RoFormer model licences are not stated in these repos.
- python-audio-separator-live (MIT) is a live device-to-device vocal/instrumental separator using MDX-Net ONNX and RoFormer checkpoints. It has "~1.7s latency on GPU". Its window is 16 × 0.1 s frames, "quality degrades under ~1.5s", and "CPU-only works but ~10x slower" — [nnyj/python-audio-separator-live](https://github.com/nnyj/python-audio-separator-live)
- vocalstream (MIT, Oct 2026) tested BS-RoFormer in a "rolling-window adapter [with] a fixed two-second context". Median per-emission compute was "approximately 208 ms" and "the simulated streaming implementation exceeds its 20/80 ms compute budgets" — [junxilucian-rgb/vocalstream](https://github.com/junxilucian-rgb/vocalstream)

**Other named models**
- KUIELab sdx23 (TFC-TDF-UNet v3) is MIT and non-causal — [kuielab/sdx23](https://github.com/kuielab/sdx23); SCNet official is MIT — [starrytong/SCNet](https://github.com/starrytong/SCNet)
- tsurumeso/vocal-remover is MIT, latest release v6.0.0b4 ships weights in a zip, and it is non-causal — [GitHub](https://github.com/tsurumeso/vocal-remover)
- ByteDance music_source_separation is Apache-2.0 (archived). "The separation models are trained ONLY on the Musdb18 dataset (100 songs)", with checkpoints on Zenodo 5804160. It is non-causal — [GitHub](https://github.com/bytedance/music_source_separation)
- Sony ai-research-code is Apache-2.0 (X-UMX, D3Net; non-causal) — [GitHub](https://github.com/sony/ai-research-code); Sony's `umxse` speech-enhancement model is in Open-Unmix — [sigsep/open-unmix-pytorch](https://github.com/sigsep/open-unmix-pytorch)
- ModelScope ClearerVoice-Studio (MossFormer2 SE/SS) is Apache-2.0. It is speech-only, not singing — [GitHub](https://github.com/modelscope/ClearerVoice-Studio)
- **SAM-Audio** (Meta, Dec 2025) is a "diffusion transformer" trained with flow matching, prompted by text, visuals or time spans — [arXiv 2512.18099](https://arxiv.org/abs/2512.18099). Checkpoints are **gated** ("manual" access) under the **SAM License** (royalty-free; allows use, redistribution and derivatives; must include the licence; bans reverse-engineering and military/ITAR uses). Storage is about **5.1 GB (small), 7.7 GB (base), 14.9 GB (large)**. The README recommends a CUDA GPU and says nothing about streaming — [facebookresearch/sam-audio README](https://github.com/facebookresearch/sam-audio), [LICENSE](https://github.com/facebookresearch/sam-audio/blob/main/LICENSE), HF API `usedStorage` for [sam-audio-small](https://huggingface.co/facebook/sam-audio-small)
- AudioSeal is a watermarking model, not a separator (out of scope, as the brief notes).
- **DBS-BSRNN (DnR)** (Tsinghua, Oct 2026) separates music / SFX / **speech** from a mono 44.1 kHz soundtrack. It is Apache-2.0 on HF, has 4.7 M params, SI-SDR music 6.48 / speech 15.01, and runs on 3 s / 1.5 s overlap-add chunks (non-causal) — [JusperLee/DBS-BSRNN-DnR](https://huggingface.co/JusperLee/DBS-BSRNN-DnR)
- **se2svs** (Bereuter, Plumbley, Sontacchi; arXiv 2607.11630) fine-tunes speech-enhancement models (BSRNN; SGMSE+) into singing-voice separators. Fine-tuning from an SE checkpoint beats from-scratch by "0.2–1.8 dB SDR", and "LoRA fine-tuning preserves the original speech enhancement capability". Code is MIT; checkpoints are Apache-2.0 on HF (e.g. `pablebe/se2svs_bsrnn_full`, file `epoch=378-sdr=10.03.ckpt`). The base BSRNN is the ICASSP 2026 URGENT baseline — [GitHub](https://github.com/pablebe/se2svs), [HF](https://huggingface.co/pablebe/se2svs_bsrnn_full), [arXiv](https://arxiv.org/abs/2607.11630)
- Causal speech-enhancement BSRNN checkpoints (ESPnet, `wyz/vctk_bsrnn_{xtiny,tiny,small,medium,large}_causal`) are **CC BY 4.0** and trained on VCTK+DEMAND (universal-SE recipe) — [HF wyz/vctk_bsrnn_small_causal](https://huggingface.co/wyz/vctk_bsrnn_small_causal)
- Other 2025–2026 singing-separation papers found (MambaVoice 2609.26635, audiovisual, 16.2 M params; UNMIXX 2601.12802, multi-singer; latent-diffusion SVS 2511.20470) are not causal or lightweight-streaming — arXiv API search results ([2609.26635](https://arxiv.org/abs/2609.26635), [2601.12802](https://arxiv.org/abs/2601.12802), [2511.20470](https://arxiv.org/abs/2511.20470))

### Inferences
- About the causal UMX `.pte`: its size (~260 MB) matches 3 UMX cores (~8.9 M params each) plus two 4096-point DFT matrices held as conv weights. So the window is probably **4096 samples ≈ 93 ms algorithmic latency**, above the 10–50 ms target. This is inferred from the export defaults and file size; the author does not state it.
- The UMX vocals core alone is small. A rough estimate: 3 unidirectional LSTM layers of hidden 512 plus FC layers comes to tens of MFLOP per 23 ms hop, which should easily give RTF < 0.3 on a phone core. Speed is not the blocker. The blockers are (a) the PyTorch weights are not published, only `.pte`; (b) MUSDB18 non-commercial training data despite the MIT tag; (c) ~93 ms window; (d) no reported SDR. Contacting the author (Shuoyang/Jasper Zheng) for the `.pth` cores is a cheap action.
- The streaming-adaptation result means **any** offline checkpoint can be run at 23–93 ms latency today, but it recomputes the full multi-second context every hop. HT-Demucs needed 20.6 ms per 23 ms hop on an RTX 5080, so on one phone CPU core it would be roughly 100–1000× too slow. It is a good **teacher or quality reference**, not a deployable model.
- Spleeter 2-stem is the most permissively licensed (MIT code and weights) and fastest vocals/accompaniment model with weights. Being non-causal, it would run in sliding chunks with look-ahead (see Q6).

### Gaps
- No published SDR for the causal UMX `.pte`. Its exact n_fft/hop and training epochs are unconfirmed.
- Whether the se2svs BSRNN (URGENT 2026 baseline) is causal was not verified. Neither was the licence of the URGENT base checkpoint `lichenda/icassp_2026_urgent_baseline`.
- Licences of individual UVR/MDX-Net community weights (e.g. Kim Vocal 2) are undocumented.
- No search covered Neutone FX model zoo vocals separators or commercial real-time plugins (Acon Remix, Serato Stems, djay Neural Mix). Those are proprietary anyway.

---

## Q3. Best 3–5 options: architecture, causality, look-ahead, params, CPU RTF, vocals SDR, licences, ONNX feasibility

### Takeaway
Nothing meets all the requirements off the shelf. The best options, ranked for this app: **(A) train our own ADI- or Band-SCNet-style causal model** (best fit, needs training). **(B) The causal Open-Unmix `.pte`** (exists now; ~93 ms, MUSDB-NC, needs weight extraction). **(C) Spleeter 2-stem in sliding chunks** (MIT; ~0.5–1 s latency). **(D) DeepFilterNet3** (MIT/Apache, 40 ms, but drops singing). **(E) Streamed HT-Demucs or SCNet as an offline teacher or quality reference only.**

### Cited Findings (comparison table; every cell sourced in Q1/Q2 or the cited links)

| Option | Arch | Causal? / algorithmic latency | Params | Measured speed | Vocals SDR (MUSDB) | Code licence | Weights licence / status | ONNX with explicit state |
|---|---|---|---|---|---|---|---|---|
| **ADI causal TFC-TDF U-Net + DF** (paper recipe; we train) | causal TFC-TDF U-Net, GRUs, deep filter, n_fft 1024/hop 512 | yes; 0 / 11.6 / 23.2 ms look-ahead | 131 K | 10.43 ms per 11.6 ms frame on 1 GHz SHARC-FX DSP; 1.89 GMAC/s — [arXiv](https://arxiv.org/html/2609.12201v1) | cSDR 5.09; BSSEval 6.30 | not released | **no weights** | GRU state is natural; DSP runtime "will be released" |
| **Band-SCNet** (paper recipe; we train) | causal SCNet, uni-LSTM, cLN | yes; 92 ms (4096/1024) | 2.59 M | RTF 0.478 single-thread i7-13700H — [Interspeech 2025](https://www.isca-archive.org/interspeech_2025/yang25d_interspeech.pdf) | 8.74 | unofficial WIP only | **no weights** | feasible (convs + LSTM); 92 ms is over budget unless retrained at 2048/512 |
| **Causal Open-Unmix (umx-live)** | 3-layer uni-LSTM mask on magnitude STFT; DFT-as-Conv1d; persistent LSTM state | yes; ~93 ms window (inferred) | ~8.9 M per stem (inferred) | none reported | none reported | MIT | HF-tagged MIT, **trained on MUSDB18 (NC)**; `.pte` only — [HF](https://huggingface.co/shuoyang-zheng/Open-Unmix-Unidirectional) | the repo's `export_stream.py` already manages state; re-export to ONNX needs the `.pth` |
| **Spleeter 2-stem** (chunked) | U-Net on 4096/1024 STFT | no; chunk-dependent | — | 23.32 ms per 1 s audio on a mobile device — [GSEP](https://arxiv.org/pdf/2010.12139) | (benchmark avg 4-stem 7.02 — [arXiv 2305.07489](https://arxiv.org/html/2305.07489v2)) | MIT | MIT, **VERIFIED** — [GitHub](https://github.com/deezer/spleeter) | stateless ONNX exists (Mixxx fork); latency is set by chunk |
| **DeepFilterNet3** | ERB mask + deep filter, GRUs, 48 kHz | yes; 40 ms | — | RTF 0.19 single-thread i5-8250U — [arXiv 2305.08227](https://ar5iv.labs.arxiv.org/html/2305.08227) | n/a (speech; suppresses music **and likely singing**) | MIT/Apache-2.0 | "All code and model weights ... dual-licensed" MIT/Apache, **VERIFIED** — [GitHub](https://github.com/Rikorose/DeepFilterNet) | stateful ONNX ports exist (e.g. [HF Allinsama/soniqo__DeepFilterNet3-ONNX](https://huggingface.co/Allinsama/soniqo__DeepFilterNet3-ONNX)) |
| **Streamed HT-Demucs / SCNet** (teacher only) | offline models, hop-sliding readout | 23–93 ms (algorithmic) | 42 M / 10.08 M | RTF 0.89 / 1.59 on **RTX 5080 GPU** — [arXiv 2609.35397](https://arxiv.org/pdf/2609.35397) | 6.90 / 7.45 (23 ms); 8.49 / 8.67 (93 ms) | MIT ([mss_streaming](https://github.com/dylansechet/mss_streaming)) | Demucs MIT; SCNet MIT repo | not phone-feasible |

### Inferences
- **Recommended path**: train a 100 K–1 M-param causal model with the ADI recipe (n_fft 1024 / hop 512, ~23 ms window plus 0–2 frame deep-filter look-ahead, total ≈ 23–46 ms). That lands in the 10–50 ms budget, and GRU state maps directly to ONNX "hop in + state in → hop out + state out". A 2-target (vocals vs rest) model should beat the 4-stem 5.09 dB figure, because capacity is not split across drums and bass (an expectation, not measured).
- **Quick prototype now**: obtain the causal UMX vocals `.pth` from the author, or retrain UMX unidirectional (MIT code) with n_fft 2048 / hop 512 to get ~46 ms. Use it to validate the end-to-end audio path while the custom model trains.

### Gaps
- No CPU RTF for ADI-style or RT-STT-style models on phone cores. ADI's figure is DSP-only, and RT-STT's GPU figure (1.01 ms per 1024 samples) has no CPU counterpart.
- No vocals-only (2-stem) causal results were found in any paper. All are 4-stem.

---

## Q4. Legal training data for an open-source, free app

### Takeaway
Vocals-stem data under permissive licences is scarce. **VocalSet (CC BY 4.0)** is the only verified permissive singing source. **Slakh2100 (CC BY 4.0)** gives permissive instrumental accompaniment (synthesised from MIDI). **LibriSpeech (CC BY 4.0)** and **Common Voice (CC0)** cover speech. Mixing these randomly is legally clean. Real multitracks (MUSDB18, MoisesDB, MedleyDB, OpenSinger, GTSinger) are all **non-commercial**, which may be acceptable for a free app but must be flagged. Qur'an recitation corpora have **undocumented recording licences**.

### Cited Findings
- **MUSDB18 / MUSDB18-HQ**: Zenodo licence `other-nc` (non-commercial / academic) — [Zenodo 1117372](https://zenodo.org/records/1117372), [Zenodo 3338373](https://zenodo.org/records/3338373)
- **MoisesDB** (240 songs, ~14.4 h). HF card: `license_name: cc-by-nc-sa-4.0`. Moises press release: "non-commercial research use only" under CC BY-NC-SA 4.0. The GitHub README instead names the "NC-RCL" licence, so sources conflict, but both are non-commercial — [HF wearemusicai/moisesdb](https://huggingface.co/datasets/wearemusicai/moisesdb), [music.ai blog](https://music.ai/blog/news/introducing-moisesdb-the-ultimate-multitrack-dataset-for-source-separation-beyond-4-stems), [moises-db GitHub](https://github.com/moises-ai/moises-db)
- **MedleyDB 2.0**: CC BY-NC-SA 4.0, access "restricted" (request needed). The MedleyDB Sample is CC BY-SA 4.0 — [Zenodo 1715175](https://zenodo.org/record/1715175), [Zenodo 1649325 (restricted)](https://zenodo.org/records/1649325), [Zenodo 1438309 sample](https://zenodo.org/records/1438309)
- **DSD100**: derived from the 'Mixing Secrets' library. sigsep says "Please refer to this original resource for any question regarding your rights" — [sigsep DSD100](https://sigsep.github.io/datasets/dsd100.html). The Cambridge-MT FAQ says research use "hasn't been specifically agreed with contributors ... please contact the relevant contributors" — [cambridge-mt FAQ](https://cambridge-mt.com/ms/mtk-faq). **RawStems** (HF) points to the same terms ("see-original-files", cambridge-mt) — [HF yongyizang/RawStems](https://huggingface.co/datasets/yongyizang/RawStems)
- **Slakh2100**: Zenodo licence **CC BY 4.0** (MIDI-synthesised multitracks, no vocals) — [Zenodo 4599666](https://zenodo.org/records/4599666). Some HF mirrors mislabel it CC BY-NC(-SA), e.g. [projectlosangeles/Slakh2100](https://huggingface.co/datasets/projectlosangeles/Slakh2100). Use the Zenodo original.
- **VocalSet** (10.1 h, 20 professional singers): Zenodo licence **CC BY 4.0** — [Zenodo 1193957](https://zenodo.org/records/1193957)
- **OpenSinger**: "All users of the dataset must follow the CC BY-NC-SA ... LICENSE" — [Multi-Singer page](https://github.com/Multi-Singer/Multi-Singer.github.io)
- **GTSinger**: HF tagged CC BY-NC-SA 4.0 — [HF AaronZ345/GTSinger](https://huggingface.co/datasets/AaronZ345/GTSinger)
- **DAMP-VSEP** (Smule) is restricted access — [Zenodo 3553059](https://zenodo.org/records/3553059)
- **LibriSpeech**: CC BY 4.0 — [HF openslr/librispeech_asr](https://huggingface.co/datasets/openslr/librispeech_asr); **Common Voice** 17: CC0 1.0 (mirror tag) — [HF fsicoli/common_voice_17_0](https://huggingface.co/datasets/fsicoli/common_voice_17_0)
- **EveryAyah (Tarteel)**: "Licensing of the individual recordings is not documented. Use at your own risk. The remainder of the dataset is CC BY 4.0" — [HF tarteel-ai/everyayah](https://huggingface.co/datasets/tarteel-ai/everyayah)
- **Quranic Universal Ayahs** (QUD, 3,700 h+): the project's timestamps, alignment, metadata and code are CC BY 4.0, but "Recitation recordings remain the property of their reciters and original upstream sources". Sources include QuranicAudio, EveryAyah, MP3Quran, QUL, TVQuran — [GitHub README](https://github.com/QUD-Technologies/quranic-universal-audio), [HF](https://huggingface.co/datasets/QUD-Technologies/quranic-universal-ayahs)
- Other HF Qur'an datasets carry tags such as Apache-2.0 (zaibihassan/Quranic-Recitation-Data), CC0 (ashraf-ali/quran-data) and CC BY-NC 4.0 (FaresElmenshawi/quran-recitations-asr). These are uploader-assigned tags, not reciter grants — HF API dataset search (9 Nov 2026)
- **ccMixter** (50 tracks with voice + background + mix): the dataset's licence was not found. The underlying ccMixter music is Creative Commons — [sigsep datasets list](https://sigsep.github.io/datasets), [paperswithcode ccMixter](https://astro.paperswithcode.com/dataset/ccmixter)
- **Open Multitrack Testbed**: contributions "have a Creative Commons license", per track — [Open Multitrack Testbed paper](https://joshreiss.github.io/documents/2014/DeMan%20et%20al-%20The%20Open%20Multitrack%20Testbed-%20AES-%202014.pdf)
- **DnR v3** is used by LiteCASS (speech/music/SFX mixtures) — [arXiv 2609.23453](https://arxiv.org/html/2609.23453v1); its licence was not verified.

### Inferences
- **Fully permissive core set**: vocals = VocalSet (singing) + LibriSpeech/Common Voice (speech) + optionally permissive Qur'an recitation with explicit reciter permission. Accompaniment = Slakh2100 stems (plus permissively licensed instrumental tracks from per-track-CC sources). Random-mix augmentation creates unlimited pairs. Weakness: VocalSet is solo technique exercises and Slakh is synthesised. Real-music generalisation (reverb, mastering, backing vocals) will suffer, which is why distillation (Q5) matters.
- **Non-commercial add-on** (acceptable for a free app only if NC terms are read as allowing it, and flagged): MUSDB18-HQ, MoisesDB and MedleyDB give real mixed vocals. Training on NC data and shipping weights publicly is a grey area. Many NC datasets restrict use to research, and a public app is arguably not "research". This is a legal-judgement call; no source settles it.
- **Nasheed (vocal-only Islamic songs)** are ideal positive "vocals" examples. They are already a cappella or percussion-only, so they can be used as vocals targets, ideally after percussion removal. But no licensed nasheed dataset was found.

### Gaps
- No licensed Arabic nasheed dataset was found. MTG-Jamendo, FMA and CCMixter per-track licence mixes were not verified (searches returned only mirror tags). The M4Singer licence was not verified.
- The VCTK licence (base for the causal ESPnet BSRNN) was not checked directly.

---

## Q5. Training recipe, compute, free GPUs, and distillation from offline teachers

### Takeaway
A sub-1 M-param causal model trains on **one T4** (ADI: batch 6, 8.8 GB), so Kaggle's ~30 GPU-h/week and Colab are viable. Use **44.1 kHz** (all MSS baselines, and phone capture often runs at 48 kHz, so resample or train at 48 kHz). Train on **continuous context**, not padded chunks. Use an L1 waveform loss (ADI) or MSE complex-spectrogram loss (Band-SCNet). Distillation from htdemucs (MIT) or Mel-RoFormer (KJ, HF-tagged MIT) on unlabelled music gives realistic targets. The licence status of teacher outputs is legally unsettled, and teachers were themselves trained on NC data.

### Cited Findings
- ADI recipe: 44.1 kHz; n_fft 1024 / hop 512; L1 waveform loss; AdamW 1e-4; clip 3.0; mixed precision; batch 6 on one T4; 5.8 s segments; continuous-context training required; deep-filter head warm-started after backbone convergence — [arXiv 2609.12201](https://arxiv.org/html/2609.12201v1)
- RT-STT: 4× RTX 3090, batch 8 per GPU, chunk 32,256 samples, lr 1e-4, STFT 1024/512 — [arXiv 2511.13146](https://arxiv.org/html/2511.13146)
- Band-SCNet: 11-s segments, MSE on complex spectrogram, MUSDB18-HQ only — [Interspeech 2025](https://www.isca-archive.org/interspeech_2025/yang25d_interspeech.pdf)
- A paper-faithful HS-TasNet re-implementation config uses the Demucs-style recipe: 360 epochs, batch 64, Adam 3e-4, L1. Optional MSE / SI-SNR, gradient clipping and group-norm switches "when SDR stalls or training becomes unstable" — [25ohms/HS-TasNet-NeutoneFX](https://github.com/25ohms/HS-TasNet-NeutoneFX)
- Causal BSRNN vocals recipe (RT-MSS): 3 s segments, dynamic-mix augmentation prob 0.95 (±3 dB), stem-drop 0.10, hybrid time+frequency loss — [Yash-Bhake/RT-MSS config](https://github.com/Yash-Bhake/RT-MSS)
- Starting from a pretrained speech-enhancement model and fine-tuning to singing-voice separation gives +0.2–1.8 dB over from-scratch, and LoRA keeps SE ability (good for a "speech + singing" vocals target) — [se2svs](https://github.com/pablebe/se2svs), [arXiv 2607.11630](https://arxiv.org/abs/2607.11630). Causal SE initialisations under CC BY 4.0 exist (ESPnet `wyz/vctk_bsrnn_*_causal`) — [HF](https://huggingface.co/wyz/vctk_bsrnn_small_causal)
- Fine-tuning offline models with a streaming-specific loss did not remove the sharp quality drop below one window of look-ahead — [arXiv 2609.35397](https://arxiv.org/pdf/2609.35397)
- Kaggle free GPU: roughly 30 h/week (reported as "dynamic ... 30 hours at minimum", resetting Saturday 00:00 UTC), on T4 or P100. Sessions are 12 h per Kaggle docs as cited by a Sept 2026 review. The exact quota is not in Kaggle's own docs — [gpuperhour review](https://gpuperhour.com/blog/free-cloud-gpus-and-credits), [Awesome Free Compute 2026](https://amitpandeytiktok.github.io/awesome-free-compute-2026/compute.html)
- Teacher licences: Demucs is MIT — [GitHub](https://github.com/facebookresearch/demucs). KimberleyJSN Mel-RoFormer is HF-tagged MIT — [HF](https://huggingface.co/KimberleyJSN/melbandroformer). SCNet repo is MIT — [GitHub](https://github.com/starrytong/SCNet). HTDemucs offline vocals SDR is 8.91, SCNet 9.35 (MUSDB18-HQ median) — [arXiv 2609.35397](https://arxiv.org/pdf/2609.35397)
- Teachers' own training data: the HT-Demucs checkpoint was trained on MUSDB18-HQ plus 800 extra songs, and SCNet on MUSDB18-HQ plus MoisesDB — [arXiv 2609.35397 Table 1 note](https://arxiv.org/pdf/2609.35397)

### Inferences
- **Compute estimate (inference, not sourced)**: a 0.1–1 M-param causal model at batch 6–16 on a T4 likely needs on the order of 1–3 days of GPU time (≈24–72 GPU-h) to converge, i.e. 1–3 Kaggle weeks. Distillation needs extra teacher inference time. Running htdemucs offline on a T4 at RTF ~0.01–0.05 means 1,000 h of unlabelled audio costs roughly 10–50 GPU-h, so pre-compute teacher stems once and store them.
- **Suggested recipe**:
  1. Pre-train on clean random mixes (VocalSet + LibriSpeech/Common Voice as vocals; Slakh2100 as accompaniment) with gain, EQ, reverb, pitch and SNR augmentation.
  2. Fine-tune on teacher pseudo-stems (htdemucs or Mel-RoFormer vocals) computed on permissively licensed or user-owned music, plus real nasheed or recitation with music overlays.
  3. Optionally add the MUSDB18-HQ / MoisesDB fine-tune as a flagged NC variant.
  4. Train on continuous segments, export GRU/LSTM state as explicit ONNX I/O (RT-MSS `export_onnx.py` is an MIT reference), and validate streaming-vs-offline equivalence.
- **Teacher-output licensing**: MIT/Apache teachers impose no restriction on outputs. Whether pseudo-labels inherit the NC terms of the teacher's training data (MUSDB, MoisesDB) is unsettled; no source addresses it. Treat it as low-to-moderate risk and document it.
- **48 vs 44.1 kHz**: Android and most system mixers run at 48 kHz. Training at 48 kHz (as LiteCASS and DeepFilterNet3 do) avoids a resampler in the loop. Most music teachers are 44.1 kHz, so pseudo-labels would need resampling.

### Gaps
- No paper reports GPU-hours for causal MSS training. ADI omits epochs and steps, and Band-SCNet omits hardware.
- No source covers the legal status of distilled outputs from NC-trained teachers.

---

## Q6. Interim fallback while no causal vocals model exists

### Takeaway
There are two shippable fallbacks today. **(1) DeepFilterNet3** (causal, 40 ms, RTF ~0.19 on one laptop core, MIT/Apache weights) works for speech over music (lectures, recitation with backing music), but it is trained to suppress non-speech and will likely damage singing. **(2) A non-causal vocals model in sliding chunks with look-ahead**: Spleeter 2-stem (MIT) is the only one cheap enough for a phone CPU. Evidence shows quality degrades steeply when context shrinks, and RoFormer- or Demucs-class models need ~1.5–2 s windows on a GPU. Expect 0.5–2 s of latency, which is fine for video if A/V sync is compensated but bad for calls.

### Cited Findings
- DeepFilterNet3: 40 ms latency (20 ms window, 10 ms hop, 2-frame look-ahead), RTF 0.19 single-thread i5-8250U, trained on DNS4 speech data — [arXiv 2305.08227](https://ar5iv.labs.arxiv.org/html/2305.08227); code and weights MIT/Apache-2.0 — [GitHub](https://github.com/Rikorose/DeepFilterNet)
- The DNS challenge objective is "preserve primary speaker speech while suppressing everything else". DNS 2021 added VocalSet singing to clean speech, but no singing-preservation metric is published — [Microsoft DNS](https://www.microsoft.com/en-us/research/academic-program/deep-noise-suppression-challenge-icassp-2023), [arXiv 2009.06122](https://arxiv.org/pdf/2009.06122) (via earlier survey)
- Chunked live separation with MDX-Net / RoFormer: ~1.7 s latency on GPU, "quality degrades under ~1.5s", CPU ~10× slower — [python-audio-separator-live](https://github.com/nnyj/python-audio-separator-live)
- BS-RoFormer with a 2 s rolling context: ~208 ms compute per emission on GPU, exceeding 20/80 ms budgets — [vocalstream](https://github.com/junxilucian-rgb/vocalstream)
- Streamed offline models: one window of look-ahead (93 ms) costs less than 1 dB versus offline. Quality falls steeply below that. HT-Demucs vocals reach 8.49 dB at 93 ms and 6.90 at 23 ms, but need GPU-class compute (RTF 0.89 on RTX 5080) — [arXiv 2609.35397](https://arxiv.org/pdf/2609.35397)
- Spleeter mobile cost: 23.32 ms per 1 s of input on an unnamed mobile device — [GSEP arXiv 2010.12139](https://arxiv.org/pdf/2010.12139)
- Speech-only causal separator with a music class (LiteCASS: speech 12.93 dB, music 7.58 dB SI-SDR, RTF 0.012 on one core) shows a "speech vs music" split is cheap. It has no weights — [arXiv 2609.23453](https://arxiv.org/html/2609.23453v1). A non-causal speech/music/SFX model with Apache-2.0 weights exists (DBS-BSRNN, 4.7 M params, 3 s chunks) — [HF](https://huggingface.co/JusperLee/DBS-BSRNN-DnR)

### Inferences
- **Latency vs quality for chunked Spleeter (estimate)**: with a 1 s window advanced every 250 ms and the centre region kept, latency is about 0.5–0.75 s and compute is about 4 × 23 ms per second, roughly RTF 0.1 on that mobile device. Shorter windows will cut quality, because the U-Net was trained on 512-frame (~11.9 s) patches. This should be measured, not assumed.
- **Hybrid interim** (inference): route through a music detector and pick a mode. Speech over music: DeepFilterNet3 (40 ms). Singing with instruments: chunked Spleeter vocals with ~0.5–1 s delay, plus a matching video delay if possible. Ship the causal UMX prototype or our own causal model when ready.
- A DeepFilterNet3 fine-tune whose "clean" target includes singing (VocalSet, nasheed) and whose "noise" includes instruments (Slakh) is an inexpensive way to get a causal 40 ms "keep all voice" model. It reuses MIT/Apache weights and a stateful architecture that already has ONNX ports. This is a strong low-risk training project, though its separation quality versus MSS models is unknown.

### Gaps
- No measured SDR exists for Spleeter in short sliding chunks, or for DeepFilterNet3's effect on singing voice.
- No phone-CPU RTF exists for chunked Spleeter or causal UMX on current Snapdragon or Tensor chips.
