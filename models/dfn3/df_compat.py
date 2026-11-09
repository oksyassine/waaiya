"""Import shims so the official `deepfilternet` 0.5.6 package works on newer torch/torchaudio.

torchaudio >= 2.5 removed `torchaudio.backend.common`, which `df.io` imports at module load.
Import this module before `df`.
"""
import sys
import types

try:
    import torchaudio.backend.common  # noqa: F401
except Exception:  # pragma: no cover - depends on the installed torchaudio
    backend = sys.modules.get("torchaudio.backend") or types.ModuleType("torchaudio.backend")
    common = types.ModuleType("torchaudio.backend.common")

    class AudioMetaData:  # only used for type hints in df.io
        pass

    common.AudioMetaData = AudioMetaData
    backend.common = common
    sys.modules["torchaudio.backend"] = backend
    sys.modules["torchaudio.backend.common"] = common
