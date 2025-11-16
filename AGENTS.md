# Repository Guidelines

## Project Structure & Module Organization
- `CardsStash/` contains all Swift sources and resources. Key folders: `Views/`, `ViewModels/`, `Models/`, `Assets.xcassets/`, and `PreviewContent/`. Keep new Swift files grouped logically (e.g., UI components in `Views`).
- `CardsStash.xcodeproj/` stores the Xcode project configuration. Scheme and build settings live here; edit via Xcode when possible.
- `DerivedData/` is generated output; do not commit or edit.

## Build, Test, and Development Commands
- `xcodebuild -scheme CardsStash -project CardsStash.xcodeproj -destination generic/platform=iOS build` compiles the iOS app without running it.
- `xcodebuild … analyze` runs the static analyzer; use before submitting significant changes.
- Launch the app via Xcode’s “Run” button targeting an iOS simulator/device for interactive testing.

## Coding Style & Naming Conventions
- Swift files use 4-space indentation, `CamelCase` types, and `lowerCamelCase` properties/functions. Keep views small and compose them in dedicated files.
- Prefer SwiftUI idioms (e.g., `NavigationStack`, `@StateObject`). Place shared state in `ViewModels/` and data models in `Models/`.
- Run `xcodebuild … analyze` or SwiftLint (if available) to catch style issues before review.

## Testing Guidelines
- UI logic currently relies on manual testing through the simulator. Add XCTest suites under a new `Tests/` directory when implementing logic-heavy features.
- Name tests following `FeatureNameTests` and target specific view models or services; run via Xcode’s Test navigator or `xcodebuild test` once suites exist.

## Commit & Pull Request Guidelines
- Use concise commit messages (imperative mood: “Add folder grid sorting”). Group related changes together.
- Pull requests should describe the motivation, list major changes, note testing performed (`xcodebuild analyze`, simulator run), and include screenshots/GIFs for UI updates.
- Reference related issues or tickets in the PR body (e.g., “Closes #42”).
