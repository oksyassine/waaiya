package org.islamicmute.app;

// Runs inside a Shizuku UserService (shell or root uid). Deliberately narrow: no generic "exec".
interface ISetupService {
    // Transaction id reserved by Shizuku: called when the service is removed; must exit the process.
    void destroy() = 16777114;

    // Grants DUMP and allows PROJECT_MEDIA for this app. Returns a log of the commands for diagnostics.
    String grantSetup() = 1;

    // Screen blur: lets this app draw over other apps and turns on its accessibility service (which only hosts the
    // covers window), lifting Android 13+'s "restricted setting" for sideloaded apps first. Returns the command log.
    String grantBlur() = 2;
}
