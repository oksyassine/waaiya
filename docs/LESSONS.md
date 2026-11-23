# Lessons

- Kaggle silently disables internet in notebooks until the account's phone is verified, even with `enable_internet: true`. Symptom: `Failed to resolve 'pypi.org'` in the first install cell.
- Kaggle no longer offers a single T4: `NvidiaTeslaT4` means 2x T4; the single-GPU choice is `NvidiaTeslaP100`. Queues for both can be hours.
- Several queued GPU runs on one account seem to wait on each other; delete stale kernels (`kaggle kernels delete -y <user>/<slug>`) and keep one queued. Observed, not confirmed by Kaggle docs.
- The Kaggle CLI has no cancel command; a run cancelled from the web page ends with `CANCEL_REQUESTED` and saves no model.
- Kaggle logs and outputs are only available after a run ends; while it runs the API gives status only.
- Holdout gains on annotator crops did not carry over to the app pipeline (detector crops on 640-px frames). Judge gender models only with `blur_diag.py` end to end.
- Status polling in a background script slows down when the PC sleeps: count elapsed time from timestamps, not from the number of checks.
