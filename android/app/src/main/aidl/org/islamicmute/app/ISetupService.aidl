package org.islamicmute.app;

// Runs inside a Shizuku UserService (shell or root uid). Deliberately narrow: no generic "exec".
interface ISetupService {
    // Transaction id reserved by Shizuku: called when the service is removed; must exit the process.
    void destroy() = 16777114;

    // Grants DUMP and allows PROJECT_MEDIA for this app. Returns a log of the commands for diagnostics.
    String grantSetup() = 1;
}
