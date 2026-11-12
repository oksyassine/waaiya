package org.islamicmute.app;

// Screen-blur covers drawn by a Shizuku UserService (shell uid), see ShizukuCovers.kt.
// The shell owns one top-level layer, marked trusted (touches pass through) and left out of screen capture.
interface ICoverService {
    // Transaction id reserved by Shizuku: called when the service is removed; must exit the process.
    void destroy() = 16777114;

    // Creates the layer and draws one hidden test cover with the same calls as update(), so a device whose
    // SurfaceControl lacks one of them fails here (false) instead of later in the one-way update().
    // `app` is any binder of the app: when the app dies, the covers are removed.
    boolean start(IBinder app) = 1;

    // The covers to show now, in display pixels: count records of 8 floats
    // (x0, y0, x1, y1, kind, red, green, blue; colours 0..1). An empty update hides all.
    // Without an update for 2.5 s every cover is hidden (the app keeps sending at least twice a second).
    oneway void update(in float[] rects, int count) = 2;

    // Removes the layer and all covers.
    void stop() = 3;

    // Two-way health check (update() is one-way and cannot report): 0 = the layer exists and every update since
    // the last call was drawn; 1 = no layer; 2 = an update failed (the error is in the shell's logcat).
    int health() = 4;
}
