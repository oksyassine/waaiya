# Voice model (stage 3): keep speech, Quran recitation and singing; remove instruments

Why: the DeepFilterNet3 baseline keeps speech but removes recitation (-13 dB) and singing (-25 dB)
on our test set (`eval/results/summary.md`). This fine-tunes it so all voice is kept.

## Data (licences checked Nov 2026; see research_notes/Instrument muting hosting gender sync/streaming_vocals_models.md)

| Role | Dataset | Licence |
|---|---|---|
| voice: speech EN | LibriSpeech (train-clean-100 is enough) | CC BY 4.0 |
| voice: speech AR | Common Voice Arabic | CC0 |
| voice: speech AR | Arabic Speech Corpus (Halabi) | CC BY 4.0 |
| voice: singing | VocalSet | CC BY 4.0 |
| voice: recitation | EveryAyah / quran-audio | recordings belong to the reciters: ask permission or record your own |
| voice: nasheed | none licensed found | record or commission a few hours (voice-only nasheeds) |
| instruments | Slakh2100 (rendered stems) | CC BY 4.0 |
| instruments | on-the-fly synthesis (`--synth-music`) | ours |

Do not use MUSDB18 / MoisesDB / MedleyDB / OpenSinger for a released model: they are non-commercial or academic-only.
Put files in folders, e.g. `data/voice/{speech_en,speech_ar,singing,recitation}` and `data/music/slakh`.

## Train (free GPU: Kaggle 30 h/week or Colab; a T4 is enough)

```bash
pip install deepfilternet torch torchaudio soundfile onnx onnxruntime
python models/voice/test_frontend.py          # front end == libDF (must print FRONTEND OK)
python models/voice/train.py \
  --voice data/voice/speech_en:1 --voice data/voice/speech_ar:1 \
  --voice data/voice/singing:1.5 --voice data/voice/recitation:1.5 \
  --music data/music/slakh --synth-music 0.3 \
  --steps 20000 --batch 16 --out runs/voice_v1
python models/dfn3/export_stream.py --checkpoint runs/voice_v1/last.pt \
  --out voice_v1.onnx --name "Voice v1 (speech, recitation, singing)" --keeps speech,recitation,singing
python eval/evaluate.py --candidate dfn3=models/dfn3/dfn3_stream.onnx --candidate v1=voice_v1.onnx
```

Accept a new model only if, on the test set, recitation and singing voice retention rise to about -3 dB or better
while instrument suppression stays above ~20 dB and music-only leakage stays below -30 dB.
The exported model drops into every platform unchanged (same contract, same 30 ms look-ahead).
