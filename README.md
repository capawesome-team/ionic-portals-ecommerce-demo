# ionic-portals-ecommerce-demo

E-commerce demo app using [Ionic Portals](https://ionic.io/docs/portals) with [Capawesome Cloud](https://capawesome.io/cloud/) for Live Updates.

> This is an updated fork of [`ionic-team/portals-ecommerce-demo`](https://github.com/ionic-team/portals-ecommerce-demo), modified to deliver Portals live updates through Capawesome Cloud (via the [Ionic Live Update Provider SDK](https://github.com/ionic-team/live-update-provider-sdk)) instead of Appflow.

## Overview

The app is built for iOS and Android. Both use the same web resources for their Portals, and **live updates are wired on both platforms** through the Capawesome provider for the [Ionic Live Update Provider SDK](https://github.com/ionic-team/live-update-provider-sdk). This relies on Ionic Portals `0.14.0-rc.0`, which ships the provider consumer API on iOS and Android.

## Project structure

| Directory             | Description                                              |
| --------------------- | -------------------------------------------------------- |
| `ios/`                | Native iOS host app                                      |
| `android/`            | Native Android host app                                  |
| `web/`                | Shop web app — Portal content (`portals/shopwebapp`)     |
| `featured-component/` | Featured component web app — Portal content (`portals/featured`) |

`capawesome.config.json` maps each directory to a Capawesome Cloud app.

## How it works

Each Portal is configured with a live update manager backed by the Capawesome provider:

- The web content for the portals is published to Capawesome Cloud (see `capawesome.config.json`, which maps `web/` and `featured-component/` to two Capawesome Cloud apps).
- On **iOS**, `AppDelegate.swift` wraps the Capawesome provider in a `DeferredCapawesomeLiveUpdateManager` (it resolves the `capawesome` provider from `LiveUpdateProviderRegistry` lazily at sync time) and attaches one manager per Portal via `liveUpdateProvider: .provider(liveUpdateManager:)`.
- On **Android**, `EcommerceApp.java` does the same with a `DeferredCapawesomeLiveUpdateManager` attached via `PortalBuilder.setLiveUpdateProviderManager(...)`, and each Portal includes the `LiveUpdatePlugin` so the provider registers when the Portal's bridge loads.
- On launch, the app calls `syncProvider()` for each Portal to fetch the latest bundle from Capawesome Cloud, retrying until the provider has registered.

See the [plugin integration guide](https://github.com/capawesome-team/capacitor-plugins/blob/main/packages/live-update/docs/ionic-live-update-provider-sdk-integration.md) for a full explanation of the pattern.

### Web content delivery and offline support

Each Portal ships with **bundled seed content** so it renders on first launch and offline, while Live Updates refresh it at runtime. (The original Ionic reference app seeded this via a "Copy Web App" build phase running the `portals sync` CLI against Appflow; this fork removes that CLI dependency.) The two platforms source the seed differently:

- **iOS** generates it at build time. In Capawesome Cloud the iOS app's `dependencyInstallCommand` (see `capawesome.config.json`) runs `scripts/seed-portals.sh` to build both web apps, and the `Seed Portals Web Content` Xcode build phase copies their output into the app bundle at `portals/shopwebapp` and `portals/featured` (matching the Portals' `startDir`). For a local Xcode build, run the script once first so the seed exists:

  ```bash
  ./scripts/seed-portals.sh
  ```

  If you skip it the build still succeeds — the build phase logs a warning and the app launches without offline seed content (Portals stay empty until the first Live Update download completes).

- **Android** generates it with a Gradle `Copy` task. `CopyWebAssets` in `app/build.gradle` copies `web/build` into `src/main/assets/webapp` and runs before every build via `preBuild.dependsOn(CopyWebAssets)`; Android then packages `src/main/assets/` into the APK, and each Portal loads it via `setStartDir("webapp")`. Build `web/` first (step 2) so there is something to copy.

## Prerequisites

- A **Portals registration key** from [ionic.io/register-portals](https://ionic.io/register-portals).
- Two **Capawesome Cloud apps** (one for `web/`, one for `featured-component/`). Create them at [cloud.capawesome.io](https://cloud.capawesome.io/) and note their app IDs.

## Getting started

### 1. Configure your Capawesome Cloud app IDs

This repository is preconfigured with the demo's Capawesome Cloud app IDs. To point it at your own Capawesome Cloud apps, replace the app IDs in:

- `capawesome.config.json` — the `appId` for each `baseDir`.
- `ios/Portals Ecommerce/Portals Ecommerce/AppDelegate.swift` — `webAppId` and `featuredAppId`.
- `android/PortalsEcommerce/app/src/main/java/io/ionic/demo/ecommerce/EcommerceApp.java` — `WEB_APP_ID`.

The `channel` is `default` by default; change it in `AppDelegate.swift` / `EcommerceApp.java` if you publish to a different channel.

### 2. Build the web resources

Before building iOS or Android, build the web apps in `web/` and `featured-component/`:

```bash
cd ./web
npm install
npm run build

cd ../featured-component
npm install
npm run build
```

### 3. Publish the bundles to Capawesome Cloud

Use the [`@capawesome/cli`](https://capawesome.io/docs/cloud/cli/) to upload a bundle for each app/channel, e.g.:

```bash
npx @capawesome/cli apps:liveupdates:upload --app-id <WEB_APP_ID> --path ./web/build --channel default
npx @capawesome/cli apps:liveupdates:upload --app-id <FEATURED_APP_ID> --path ./featured-component/build --channel default
```

### 4. Set your Portals registration key

Get your registration key from [ionic.io/register-portals](https://ionic.io/register-portals), then set it on each platform you build:

- **iOS** — uncomment and set it in `AppDelegate.swift`:

  ```swift
  // Register Portals
  PortalsRegistrationManager.shared.register(key: "YOUR_PORTALS_KEY")
  ```

- **Android** — set it in `EcommerceApp.java`:

  ```java
  // Register Portals
  PortalManager.register("YOUR_PORTALS_KEY");
  ```

### 5. Run on iOS

The Capawesome plugin is referenced from the app's `package.json` (in `ios/Portals Ecommerce/`) so the Podfile can resolve it via `node_modules` (the native app has no co-located Capacitor web project). Install the npm dependency, then the pods:

```bash
cd "./ios/Portals Ecommerce/"
npm install
pod install
xed "Portals Ecommerce.xcworkspace"
```

It is **important** that you open the `.xcworkspace` and _not_ the `.xcodeproj` file.

### 6. Run on Android

The Capawesome plugin is referenced from a `package.json` in `android/PortalsEcommerce/` so Gradle can resolve its native module (and Capacitor) from `node_modules` — the native host has no `npx cap sync`. Install the modules first:

```bash
cd ./android/PortalsEcommerce
npm install
```

Then open `android/PortalsEcommerce` in Android Studio (or run `./gradlew :app:assembleDebug`) and run the app with your registration key set (step 4).

## iOS implementation notes

This project is configured to use the Capawesome provider integration with Ionic Portals:

- The `Podfile` includes `CapawesomeCapacitorLiveUpdate/IonicProvider`.
- `IonicPortals` is pinned to `0.14.0-rc.0` (the version that introduces `liveUpdateProvider` / `syncProvider()`).
- Portals are configured with `.provider(liveUpdateManager:)` created from `LiveUpdateProviderRegistry.shared.resolve("capawesome")`.

## Android implementation notes

This project wires the Capawesome provider integration into the native Android Portals host:

- The Capacitor and Capawesome plugin Gradle modules are consumed from the local `node_modules` (see `settings.gradle`), since the native host has no `npx cap sync`.
- `io.ionic:portals` is pinned to `0.14.0-rc.0` (the version that introduces `setLiveUpdateProviderManager` / `syncProvider()`). The transitive Maven `com.capacitorjs:core` is excluded so the single local `:capacitor-android` module provides Capacitor.
- `variables.gradle` sets `capawesomeCapacitorLiveUpdateIncludeIonicProvider = true` so the plugin compiles in and registers the `capawesome` provider.
- Portals are configured with `setLiveUpdateProviderManager(...)` backed by `LiveUpdateProviderRegistry.resolve("capawesome")`.

## License

See [LICENSE](./LICENSE).

This project is a fork of [`ionic-team/portals-ecommerce-demo`](https://github.com/ionic-team/portals-ecommerce-demo) and retains the original copyright notice.
