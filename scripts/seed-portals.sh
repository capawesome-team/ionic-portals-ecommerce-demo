#!/usr/bin/env bash
#
# Builds the Portal web apps so their output can be bundled into the native iOS
# app as offline seed content (see the "Seed Portals Web Content" Xcode build
# phase, which copies the build output into the app bundle at portals/*).
#
# Runs automatically in Capawesome Cloud via `dependencyInstallCommand`. Run it
# manually before a local Xcode build if you want the offline seed locally.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

for app in web featured-component; do
  echo "==> Building $app"
  npm --prefix "$root/$app" ci
  npm --prefix "$root/$app" run build
done

echo "==> Done. The Xcode 'Seed Portals Web Content' build phase will copy the output into the app bundle."
