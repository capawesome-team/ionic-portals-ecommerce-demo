package io.ionic.demo.ecommerce;

import android.app.Application;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.capacitorjs.plugins.camera.CameraPlugin;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.capawesome.capacitorjs.plugins.liveupdate.LiveUpdatePlugin;
import io.ionic.demo.ecommerce.data.ShoppingCart;
import io.ionic.demo.ecommerce.plugins.ShopAPIPlugin;
import io.ionic.demo.ecommerce.portals.DeferredCapawesomeLiveUpdateManager;
import io.ionic.demo.ecommerce.portals.FadePortalFragment;
import io.ionic.liveupdateprovider.LiveUpdateProviderError;
import io.ionic.liveupdateprovider.LiveUpdateProviderSyncCallback;
import io.ionic.liveupdateprovider.LiveUpdateProviderSyncResult;
import io.ionic.portals.Portal;
import io.ionic.portals.PortalManager;
import io.ionic.portals.PortalsPlugin;

/**
 * The parent Application Class for the E-Commerce app.
 */
public class EcommerceApp extends Application {

    /**
     * A single instance of this class.
     */
    private static EcommerceApp instance;

    /**
     * The active shopping cart used for this shopping session.
     */
    private ShoppingCart shoppingCart;

    /**
     * Get the singleton instance of the app class.
     *
     * @return A singleton instance of the app class.
     */
    public static EcommerceApp getInstance() {
        return instance;
    }

    /**
     * Gets the application context from the singleton instance of the app class.
     *
     * @return The application context.
     */
    public static Context getContext() {
        return instance.getApplicationContext();
    }

    /**
     * Get the active shopping cart state used for this shopping session.
     *
     * @return The shopping cart for the current shopping session.
     */
    public ShoppingCart getShoppingCart() {
        return shoppingCart;
    }

    /**
     * Saves a reference to the application object on app launch and creates a fresh
     * shopping cart to be used for the shopping session.
     */
    @Override
    public void onCreate() {
        instance = this;
        super.onCreate();

        // Start app with a fresh shopping cart
        shoppingCart = new ShoppingCart();

        // Register Portals
        // PortalManager.register("YOUR_PORTALS_KEY");

        // Checkout Portal
        PortalManager.newPortal("checkout")
                .setStartDir("webapp")
                .setPlugins(Arrays.asList(ShopAPIPlugin.class, LiveUpdatePlugin.class))
                .setLiveUpdateProviderManager(liveUpdateManager("portal-checkout"))
                .create();

        // Help Portal
        HashMap<String, String> initialContext = new HashMap<>();
        initialContext.put("startingRoute", "/help");
        PortalManager.newPortal("help")
                .setStartDir("webapp")
                .setInitialContext(initialContext)
                .setPlugins(Arrays.asList(ShopAPIPlugin.class, LiveUpdatePlugin.class))
                .setPortalFragmentType(FadePortalFragment.class)
                .setLiveUpdateProviderManager(liveUpdateManager("portal-help"))
                .create();

        // Profile Portal
        HashMap<String, String> initialContextProfile = new HashMap<>();
        initialContextProfile.put("startingRoute", "/user");
        PortalManager.newPortal("profile")
                .setStartDir("webapp")
                .addPlugin(ShopAPIPlugin.class)
                .addPlugin(CameraPlugin.class)
                .addPlugin(LiveUpdatePlugin.class)
                .setInitialContext(initialContextProfile)
                .setLiveUpdateProviderManager(liveUpdateManager("portal-profile"))
                .create();

        // Fetch the latest web bundle for each portal from Capawesome Cloud.
        for (String portalName : PROVIDER_PORTALS) {
            scheduleProviderSync(portalName, 1);
        }
    }

    /**
     * The Capawesome Cloud app that hosts the web bundle for every portal, and the channel to sync.
     */
    private static final String WEB_APP_ID = "686bb541-04f2-426d-972b-345eaeac526b";
    private static final String CHANNEL = "default";

    private static final String[] PROVIDER_PORTALS = {"checkout", "help", "profile"};
    private static final int MAX_SYNC_ATTEMPTS = 20;
    private static final String TAG = "EcommerceApp";

    /**
     * Builds a deferred live update manager for a portal, backed by the Capawesome provider.
     *
     * @param managerKey A stable, unique key per portal so each persists its own active bundle.
     */
    private DeferredCapawesomeLiveUpdateManager liveUpdateManager(String managerKey) {
        Map<String, Object> config = new HashMap<>();
        config.put("managerKey", managerKey);
        config.put("appId", WEB_APP_ID);
        config.put("channel", CHANNEL);
        return new DeferredCapawesomeLiveUpdateManager(this, config);
    }

    /**
     * Triggers a provider sync for a portal, retrying until the Capawesome provider has been
     * registered (which happens once a portal's bridge loads).
     */
    private void scheduleProviderSync(String portalName, int attempt) {
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Portal portal = PortalManager.getPortal(portalName);
            if (portal == null) {
                return;
            }
            portal.syncProvider(new LiveUpdateProviderSyncCallback() {
                @Override
                public void onSuccess(LiveUpdateProviderSyncResult result) {
                    Log.d(TAG, "Capawesome provider sync succeeded for portal '" + portalName + "'.");
                }

                @Override
                public void onFailure(LiveUpdateProviderError.SyncFailed error) {
                    if (attempt < MAX_SYNC_ATTEMPTS) {
                        scheduleProviderSync(portalName, attempt + 1);
                    } else {
                        Log.w(TAG, "Capawesome provider sync did not complete for portal '" + portalName
                                + "' after " + MAX_SYNC_ATTEMPTS + " attempts.");
                    }
                }
            });
        }, 1000);
    }
}
