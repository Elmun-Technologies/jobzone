package io.jobzone.jobzone

import android.app.Application
import com.yandex.mapkit.MapKitFactory

/**
 * Application entry point. Sets the Yandex MapKit API key before any map is
 * created (the yandex_mapkit plugin calls MapKitFactory.initialize on first use).
 *
 * Get a free "MapKit Mobile SDK" key at https://developer.tech.yandex.ru/ and
 * restrict it to this application id (io.jobzone.jobzone), then paste it below.
 * The key ships in the app (like a Google Maps key) — restriction by app id is
 * what protects it, so this is safe to commit once filled in.
 */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey(YANDEX_MAPKIT_API_KEY)
        MapKitFactory.setLocale("ru_RU")
    }

    companion object {
        private const val YANDEX_MAPKIT_API_KEY = "1d02f6b0-05d4-4eb6-ae5b-eea72724a6ff"
    }
}
