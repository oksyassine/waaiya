#include "wasapi.h"

#include <functiondiscoverykeys_devpkey.h>

#include <cstdio>

WAVEFORMATEX im_float_format(int rate, int channels) {
    WAVEFORMATEX f = {};
    f.wFormatTag = WAVE_FORMAT_IEEE_FLOAT;
    f.nChannels = (WORD)channels;
    f.nSamplesPerSec = (DWORD)rate;
    f.wBitsPerSample = 32;
    f.nBlockAlign = (WORD)(channels * 4);
    f.nAvgBytesPerSec = (DWORD)rate * f.nBlockAlign;
    f.cbSize = 0;
    return f;
}

namespace {

// ActivateAudioInterfaceAsync calls back on another thread; the handler must be agile (IAgileObject).
class Activation final : public IActivateAudioInterfaceCompletionHandler, public IAgileObject {
  public:
    HANDLE done = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    ~Activation() { CloseHandle(done); }

    STDMETHODIMP QueryInterface(REFIID riid, void **out) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(IActivateAudioInterfaceCompletionHandler)) {
            *out = static_cast<IActivateAudioInterfaceCompletionHandler *>(this);
        } else if (riid == __uuidof(IAgileObject)) {
            *out = static_cast<IAgileObject *>(this);
        } else {
            *out = nullptr;
            return E_NOINTERFACE;
        }
        AddRef();
        return S_OK;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return (ULONG)InterlockedIncrement(&refs_); }
    STDMETHODIMP_(ULONG) Release() override {
        LONG r = InterlockedDecrement(&refs_);
        if (r == 0) delete this;
        return (ULONG)r;
    }
    STDMETHODIMP ActivateCompleted(IActivateAudioInterfaceAsyncOperation *) override {
        SetEvent(done);
        return S_OK;
    }

  private:
    LONG refs_ = 1;
};

} // namespace

HRESULT im_activate_process_loopback(DWORD pid, bool exclude, IAudioClient **out) {
    *out = nullptr;
    im_activation_params ap = {};
    ap.ActivationType = IM_ACTIVATION_TYPE_PROCESS_LOOPBACK;
    ap.ProcessLoopbackParams.TargetProcessId = pid;
    ap.ProcessLoopbackParams.ProcessLoopbackMode = exclude ? IM_LOOPBACK_EXCLUDE_TREE : IM_LOOPBACK_INCLUDE_TREE;
    PROPVARIANT pv;
    PropVariantInit(&pv);
    pv.vt = VT_BLOB;
    pv.blob.cbSize = sizeof ap;
    pv.blob.pBlobData = reinterpret_cast<BYTE *>(&ap);

    Activation *h = new Activation();
    Com<IActivateAudioInterfaceAsyncOperation> op;
    HRESULT hr = ActivateAudioInterfaceAsync(IM_VAD_PROCESS_LOOPBACK, __uuidof(IAudioClient), &pv, h, op.put());
    if (SUCCEEDED(hr)) {
        if (WaitForSingleObject(h->done, 10000) != WAIT_OBJECT_0) {
            hr = HRESULT_FROM_WIN32(ERROR_TIMEOUT);
        } else {
            HRESULT ahr = E_FAIL;
            Com<IUnknown> unk;
            hr = op->GetActivateResult(&ahr, unk.put());
            if (SUCCEEDED(hr)) hr = ahr;
            if (SUCCEEDED(hr)) hr = unk->QueryInterface(__uuidof(IAudioClient), reinterpret_cast<void **>(out));
        }
    }
    h->Release();
    return hr;
}

std::string im_hr(HRESULT hr) {
    const char *name = "";
    switch (hr) {
    case AUDCLNT_E_UNSUPPORTED_FORMAT: name = " (AUDCLNT_E_UNSUPPORTED_FORMAT)"; break;
    case AUDCLNT_E_DEVICE_INVALIDATED: name = " (AUDCLNT_E_DEVICE_INVALIDATED)"; break;
    case AUDCLNT_E_SERVICE_NOT_RUNNING: name = " (AUDCLNT_E_SERVICE_NOT_RUNNING)"; break;
    case AUDCLNT_E_DEVICE_IN_USE: name = " (AUDCLNT_E_DEVICE_IN_USE)"; break;
    case E_NOTFOUND: name = " (E_NOTFOUND: no audio output)"; break;
    case E_ACCESSDENIED: name = " (E_ACCESSDENIED)"; break;
    case E_NOTIMPL: name = " (E_NOTIMPL)"; break;
    default: break;
    }
    char buf[96];
    snprintf(buf, sizeof buf, "HRESULT 0x%08lx%s", (unsigned long)hr, name);
    return buf;
}

std::string im_utf8(const wchar_t *w) {
    if (!w) return "";
    int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return "";
    std::string s((size_t)n - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, &s[0], n, nullptr, nullptr);
    return s;
}

std::wstring im_wide(const std::string &s) {
    int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, nullptr, 0);
    if (n <= 1) return L"";
    std::wstring w((size_t)n - 1, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, &w[0], n);
    return w;
}

std::string im_device_name(IMMDevice *dev) {
    Com<IPropertyStore> props;
    if (!dev || FAILED(dev->OpenPropertyStore(STGM_READ, props.put()))) return "";
    PROPVARIANT v;
    PropVariantInit(&v);
    std::string name;
    if (SUCCEEDED(props->GetValue(PKEY_Device_FriendlyName, &v)) && v.vt == VT_LPWSTR) name = im_utf8(v.pwszVal);
    PropVariantClear(&v);
    return name;
}
