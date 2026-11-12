// Small WASAPI helpers shared by the Windows filter (waaiya-filter.exe) and its test tool (waaiya-wtest.exe).
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <audioclient.h>
#include <audiopolicy.h>
#include <mmdeviceapi.h>
#include <mmreg.h>
#include <objidl.h>

#include <string>

#include "com.h"

// audioclientactivationparams.h is not in every SDK (MinGW has none): the documented layout, Windows 10 2004+.
typedef enum {
    IM_ACTIVATION_TYPE_DEFAULT = 0,
    IM_ACTIVATION_TYPE_PROCESS_LOOPBACK = 1,
} im_activation_type;
typedef enum {
    IM_LOOPBACK_INCLUDE_TREE = 0,
    IM_LOOPBACK_EXCLUDE_TREE = 1,
} im_loopback_mode;
typedef struct {
    DWORD TargetProcessId;
    im_loopback_mode ProcessLoopbackMode;
} im_loopback_params;
typedef struct {
    im_activation_type ActivationType;
    im_loopback_params ProcessLoopbackParams;
} im_activation_params;
#define IM_VAD_PROCESS_LOOPBACK L"VAD\\Process_Loopback"


// 48 kHz float stereo (or mono), the engine's format; AUTOCONVERTPCM lets Windows convert to and from the device's.
WAVEFORMATEX im_float_format(int rate, int channels);

// Activates a process-loopback IAudioClient: the sound of every process except pid's tree (exclude = true), or of
// pid's tree only. Blocks until Windows answers. Returns S_OK and the client, or the failure.
HRESULT im_activate_process_loopback(DWORD pid, bool exclude, IAudioClient **out);

// "HRESULT 0x88890008 (AUDCLNT_E_UNSUPPORTED_FORMAT)" and the like.
std::string im_hr(HRESULT hr);

// UTF-8 <-> UTF-16
std::string im_utf8(const wchar_t *w);
std::wstring im_wide(const std::string &s);

// The friendly name of a device ("Speakers (Realtek(R) Audio)"), "" if unknown.
std::string im_device_name(IMMDevice *dev);
