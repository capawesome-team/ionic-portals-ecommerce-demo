import UIKit
import IonicPortals
import CapacitorCamera
import CapawesomeCapacitorLiveUpdate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Fetch the latest web bundle for each portal from Capawesome Cloud.
        Task {
            await syncProviderPortals()
        }

        return true
    }

    private func syncProviderPortals() async {
        for portal in [Portal.checkout, .help, .featured] {
            do {
                _ = try await portal.syncProvider()
                print("Capawesome provider sync succeeded for portal '\(portal.name)'.")
            } catch {
                print("Capawesome provider sync failed for portal '\(portal.name)': \(error.localizedDescription)")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension Portal {
    private static let webAppId = "686bb541-04f2-426d-972b-345eaeac526b"
    private static let featuredAppId = "1234e875-f53c-411a-8f83-89ea304757c8"
    private static let activeChannel = "default"

    /// Constructs a Capawesome live update manager for a portal. Each portal gets a stable,
    /// unique `managerKey` so it persists its own active bundle.
    private static func providerManager(for target: String) -> LiveUpdateIonicManager? {
        let config: [String: Any]
        switch target {
        case "webapp":
            config = [
                "managerKey": "portal-webapp",
                "appId": webAppId,
                "channel": activeChannel
            ]
        case "help":
            config = [
                "managerKey": "portal-help",
                "appId": webAppId,
                "channel": activeChannel
            ]
        case "featured":
            config = [
                "managerKey": "portal-featured",
                "appId": featuredAppId,
                "channel": activeChannel
            ]
        default:
            return nil
        }

        return try? LiveUpdateIonicManager(configuration: config)
    }

    static let featured = Self(
        name: "featured",
        startDir: "portals/featured",
        plugins: [.type(LiveUpdatePlugin.self)],
        liveUpdateSource: providerManager(for: "featured").map { .provider(manager: $0) }
    )

    private static let commonPlugins: [Plugin] = [
        .type(LiveUpdatePlugin.self),
        .type(ShopAPIPlugin.self),
        .instance(
            WebVitalsPlugin { portalName, duration in
                print("Portal \(portalName) - First Contentful Paint: \(duration)ms")
            }
        )
    ]

    static let checkout = Self(
        name: "checkout",
        startDir: "portals/shopwebapp",
        initialContext: ["startingRoute": "/checkout"],
        plugins: commonPlugins,
        liveUpdateSource: providerManager(for: "webapp").map { .provider(manager: $0) }
    )

    static let help = Self(
        name: "help",
        startDir: "portals/shopwebapp",
        initialContext: ["startingRoute": "/help"],
        plugins: commonPlugins,
        liveUpdateSource: providerManager(for: "help").map { .provider(manager: $0) }
    )

    static let user = Self(
        name: "user",
        startDir: "portals/shopwebapp",
        initialContext: ["startingRoute": "/user"],
        plugins: commonPlugins,
        liveUpdateSource: providerManager(for: "webapp").map { .provider(manager: $0) }
    )
    .adding(CameraPlugin.self)
}
