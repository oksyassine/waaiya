package org.islamicmute.app

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context

/** The daily "is there a new version?" check ([AppUpdate.check]), when a network is there; kept across restarts. */
class AppUpdateJob : JobService() {
    override fun onStartJob(params: JobParameters): Boolean {
        if (FilterService.running) return false  // never while filtering: the next day's run checks
        AppUpdate.check(this, notify = true) { jobFinished(params, false) }
        return true
    }

    override fun onStopJob(params: JobParameters) = true

    companion object {
        private const val ID = 4711
        private const val DAY = 24 * 3600 * 1000L

        /** Plans the daily check ([on]), or cancels it. An existing plan is kept, so app starts never postpone it. */
        fun schedule(c: Context, on: Boolean) {
            val js = c.getSystemService(JobScheduler::class.java) ?: return
            if (!on) { js.cancel(ID); return }
            if (js.getPendingJob(ID) != null) return
            js.schedule(JobInfo.Builder(ID, ComponentName(c, AppUpdateJob::class.java))
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPeriodic(DAY, 6 * 3600 * 1000L)
                .setPersisted(true)
                .build())
        }
    }
}
