import UIKit
import IonicPortals
import CapacitorCamera
import CapawesomeCapacitorLiveUpdate
import LiveUpdateProvider

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private static let maxSyncAttempts = 20

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Register Portals
        // PortalsRegistrationManager.shared.register(key: "YOUR_PORTALS_KEY")

        scheduleProviderSync(attempt: 1)

        return true
    }

    private func scheduleProviderSync(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await self.syncProviderPortals(attempt: attempt)
            }
        }
    }

    @MainActor
    private func syncProviderPortals(attempt: Int) async {
        let portalsToSync: [Portal] = [.checkout, .help, .featured]
        var failedPortalNames: [String] = []

        for portal in portalsToSync {
            do {
                _ = try await portal.syncProvider()
                print("Capawesome provider sync succeeded for portal '\(portal.name)'.")
            } catch {
                failedPortalNames.append(portal.name)
                print("Capawesome provider sync failed for portal '\(portal.name)': \(error.localizedDescription)")
            }
        }

        if failedPortalNames.isEmpty {
            print("Capawesome provider sync completed for all portals.")
            return
        }

        if attempt >= Self.maxSyncAttempts {
            print("Capawesome provider sync did not complete after \(Self.maxSyncAttempts) attempts. Remaining portals: \(failedPortalNames.joined(separator: ", "))")
            return
        }

        print("Retrying Capawesome provider sync (attempt \(attempt + 1)/\(Self.maxSyncAttempts)) for portals: \(failedPortalNames.joined(separator: ", "))")
        scheduleProviderSync(attempt: attempt + 1)
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

    private static func providerManager(for target: String) -> (any LiveUpdateManaging)? {
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

        return DeferredCapawesomeLiveUpdateManager(config: config)
    }

    static let featured = Self(
        name: "featured",
        startDir: "portals/featured",
        plugins: [.type(LiveUpdatePlugin.self)],
        liveUpdateProvider: providerManager(for: "featured").map { .provider(liveUpdateManager: $0) }
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
        liveUpdateProvider: providerManager(for: "webapp").map { .provider(liveUpdateManager: $0) }
    )
    
    static let help = Self(
        name: "help",
        startDir: "portals/shopwebapp",
        initialContext: ["startingRoute": "/help"],
        plugins: commonPlugins,
        liveUpdateProvider: providerManager(for: "help").map { .provider(liveUpdateManager: $0) }
    )
    
    static let user = Self(
        name: "user",
        startDir: "portals/shopwebapp",
        initialContext: ["startingRoute": "/user"],
        plugins: commonPlugins,
        liveUpdateProvider: providerManager(for: "webapp").map { .provider(liveUpdateManager: $0) }
    )
    .adding(CameraPlugin.self)
}

private final class DeferredCapawesomeLiveUpdateManager: LiveUpdateManaging {
    private static let providerId = "capawesome"

    private let config: [String: Any]
    private var currentManager: (any LiveUpdateManaging)?

    var latestAppDirectory: URL? {
        currentManager?.latestAppDirectory
    }

    init(config: [String: Any]) {
        self.config = config
    }

    func sync() async throws -> any LiveUpdateProvider.SyncResult {
        guard let provider = LiveUpdateProviderRegistry.shared.resolve(Self.providerId) else {
            throw LiveUpdateProviderError.providerNotRegistered(Self.providerId)
        }

        let manager = try provider.createManager(config: config)
        currentManager = manager
        return try await manager.sync()
    }
}

