package io.ionic.demo.ecommerce.portals;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.util.Map;

import io.ionic.liveupdateprovider.LiveUpdateProvider;
import io.ionic.liveupdateprovider.LiveUpdateProviderError;
import io.ionic.liveupdateprovider.LiveUpdateProviderManager;
import io.ionic.liveupdateprovider.LiveUpdateProviderRegistry;
import io.ionic.liveupdateprovider.LiveUpdateProviderSyncCallback;

/**
 * Wraps the Capawesome live update provider so a {@code Portal} can be configured before the
 * provider is registered.
 *
 * <p>The Capawesome provider registers itself with the {@link LiveUpdateProviderRegistry} when the
 * {@code LiveUpdatePlugin} loads — which happens once a Portal's Capacitor bridge loads, i.e. after
 * these Portal definitions are built. This adapter therefore resolves the provider lazily, at sync
 * time, instead of holding a manager reference up front.
 */
public class DeferredCapawesomeLiveUpdateManager implements LiveUpdateProviderManager {

    private static final String PROVIDER_ID = "capawesome";

    @NonNull
    private final Context context;

    @NonNull
    private final Map<String, Object> config;

    @Nullable
    private LiveUpdateProviderManager currentManager;

    public DeferredCapawesomeLiveUpdateManager(@NonNull Context context, @NonNull Map<String, Object> config) {
        this.context = context.getApplicationContext();
        this.config = config;
    }

    @Nullable
    @Override
    public File getLatestAppDirectory() {
        return currentManager != null ? currentManager.getLatestAppDirectory() : null;
    }

    @Override
    public void sync(@Nullable LiveUpdateProviderSyncCallback callback) {
        LiveUpdateProvider provider = LiveUpdateProviderRegistry.resolve(PROVIDER_ID);
        if (provider == null) {
            notifyFailure(callback, "Live update provider '" + PROVIDER_ID + "' is not registered.", null);
            return;
        }
        try {
            if (currentManager == null) {
                currentManager = provider.createManager(context, config);
            }
            currentManager.sync(callback);
        } catch (Exception exception) {
            String message = exception.getMessage() == null ? "Sync failed" : exception.getMessage();
            notifyFailure(callback, message, exception);
        }
    }

    private void notifyFailure(@Nullable LiveUpdateProviderSyncCallback callback, @NonNull String message, @Nullable Throwable cause) {
        if (callback != null) {
            callback.onFailure(new LiveUpdateProviderError.SyncFailed(message, cause));
        }
    }
}
