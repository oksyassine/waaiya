// COM pointer that releases itself (shared by the Windows filter, blur and test tool).
#pragma once

#include <unknwn.h>

// COM pointer that releases itself.
template <class T> struct Com {
    T *p = nullptr;
    Com() = default;
    Com(const Com &) = delete;
    Com &operator=(const Com &) = delete;
    Com(Com &&o) noexcept : p(o.p) { o.p = nullptr; }
    Com &operator=(Com &&o) noexcept {
        if (this != &o) {
            reset();
            p = o.p;
            o.p = nullptr;
        }
        return *this;
    }
    ~Com() { reset(); }
    void reset() {
        if (p) p->Release();
        p = nullptr;
    }
    T **put() {
        reset();
        return &p;
    }
    T *operator->() const { return p; }
    explicit operator bool() const { return p != nullptr; }
};
