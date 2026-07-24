package com.ibusehat.app.benchmark

import androidx.benchmark.macro.MacrobenchmarkScope
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until

/**
 * Menunggu halaman Beranda siap dan menutup dialog welcome jika muncul.
 */
fun MacrobenchmarkScope.waitForBerandaReady() {
    device.wait(
        Until.hasObject(By.text("IbuSehat")),
        BenchmarkConstants.UI_WAIT_TIMEOUT_MS,
    )

    // Welcome dialog (first launch) — coba tutup dengan tombol back.
    val welcomeTitle = device.findObject(By.textContains("Selamat"))
    if (welcomeTitle != null) {
        device.pressBack()
        device.waitForIdle()
    }

    device.wait(
        Until.hasObject(By.scrollable(true)),
        BenchmarkConstants.UI_WAIT_TIMEOUT_MS,
    )
}
