# ionic-portals-ecommerce-demo

E-commerce demo app using [Ionic Portals](https://ionic.io/docs/portals) with [Capawesome Cloud](https://capawesome.io/cloud/) for Live Updates.

> This is an updated fork of [`ionic-team/portals-ecommerce-demo`](https://github.com/ionic-team/portals-ecommerce-demo), modified to deliver Portals live updates through Capawesome Cloud (via the [Ionic Live Update Provider SDK](https://github.com/ionic-team/live-update-provider-sdk)) instead of Appflow.

The app is built for iOS and Android. Both use the same web resources for their Portals. Live updates are currently wired on **iOS only**. The Live Update Provider SDK defines an Android Portals manager contract (`LiveUpdateProviderManager`) that the Capawesome plugin implements, but the Ionic Portals **Android** SDK does not yet provide a documented API to hand that manager to a Portal (its current Live Updates documentation still targets Appflow), and Ionic's reference app wires the provider on iOS only.

## How Live Updates work in this demo

Each Portal is configured with a live update manager backed by the Capawesome provider:

- The web content for the portals is published to Capawesome Cloud (see `capawesome.config.json`, which maps `web/` and `featured-component/` to two Capawesome Cloud apps).
- On iOS, `AppDelegate.swift` wraps the Capawesome provider in a `DeferredCapawesomeLiveUpdateManager` (it resolves the `capawesome` provider from `LiveUpdateProviderRegistry` lazily at sync time) and attaches one manager per Portal via `liveUpdateProvider: .provider(liveUpdateManager:)`.
- On launch, the app calls `portal.syncProvider()` for each portal to fetch the latest bundle from Capawesome Cloud.

See the [plugin integration guide](https://github.com/capawesome-team/capacitor-plugins/blob/main/packages/live-update/docs/ionic-live-update-provider-sdk-integration.md) for a full explanation of the pattern.

## Prerequisites

- A **Portals registration key** from [ionic.io/register-portals](https://ionic.io/register-portals).
- Two **Capawesome Cloud apps** (one for `web/`, one for `featured-component/`). Create them at [cloud.capawesome.io](https://cloud.capawesome.io/) and note their app IDs.

## Configure your Capawesome Cloud app IDs

This repository is preconfigured with the demo's Capawesome Cloud app IDs. To point it at your own Capawesome Cloud apps, replace the app IDs in:

- `capawesome.config.json` — the `appId` for each `baseDir`.
- `ios/Portals Ecommerce/Portals Ecommerce/AppDelegate.swift` — `webAppId` and `featuredAppId`.

The `channel` is `default` by default; change it in `AppDelegate.swift` if you publish to a different channel.

## Build the web resources

Before building iOS or Android, build the web apps in `web/` and `featured-component/`:

```bash
cd ./web
npm install
npm run build

cd ../featured-component
npm install
npm run build
```

## Publish the bundles to Capawesome Cloud

Use the [`@capawesome/cli`](https://capawesome.io/docs/cloud/cli/) to upload a bundle for each app/channel, e.g.:

```bash
npx @capawesome/cli apps:liveupdates:upload --app-id <WEB_APP_ID> --path ./web/build --channel default
npx @capawesome/cli apps:liveupdates:upload --app-id <FEATURED_APP_ID> --path ./featured-component/build --channel default
```

## iOS

The Capawesome plugin is referenced from the root `package.json` so the Podfile can resolve it via `node_modules` (the native app has no co-located Capacitor web project). Install the npm dependency, then the pods:

```bash
npm install
cd "./ios/Portals Ecommerce/"
pod install
xed "Portals Ecommerce.xcworkspace"
```

It is **important** that you open the `.xcworkspace` and _not_ the `.xcodeproj` file.

This project is configured to use the Capawesome provider integration with Ionic Portals:

- The `Podfile` includes `CapawesomeCapacitorLiveUpdate/IonicProvider`.
- `IonicPortals` is pinned to `0.14.0-rc.0` (the version that introduces `liveUpdateProvider` / `syncProvider()`).
- Portals are configured with `.provider(liveUpdateManager:)` created from `LiveUpdateProviderRegistry.shared.resolve("capawesome")`.

### Portals registration key

Get your registration key from [ionic.io/register-portals](https://ionic.io/register-portals), then uncomment and set it in `AppDelegate.swift`:

```swift
// Register Portals
PortalsRegistrationManager.shared.register(key: "YOUR_PORTALS_KEY")
```

## Android

Live updates are not yet wired on Android (pending Portals Android SDK support). To run the base Portals app, set your registration key in `EcommerceApp.java`:

```java
// Register Portals
PortalManager.register("YOUR_PORTALS_KEY");
```

Then build and run the Android app.

## License

MIT — see [LICENSE](./LICENSE). This project is a fork of [`ionic-team/portals-ecommerce-demo`](https://github.com/ionic-team/portals-ecommerce-demo) and retains the original copyright notice.
