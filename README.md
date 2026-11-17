# basalt (Flutter)

Shared design system and in-app updater for the Basalt Flutter apps. It is the Flutter twin of
[`@basalt/core`](https://github.com/muhammadahmad545-code/basalt-core) (React Native), so every app in
the suite shares one look and one update flow whatever it is built with.

- **Theme**: `basaltTheme(brightness, accent)` gives a complete Material 3 theme: calm neutrals, one accent per app, and Inter bundled (no runtime font downloads).
- **UI kit**: `BCard`, `BListRow`, `BGroup`, `BHeader`, `BPage`, `BButton`, `BChip`, `BBadge`, `BStatTile`, `BRing`, `BBars`, `BProgressBar`, `BEmptyState`, `BSearchField`, `BTabShell`, `BOnboarding`, `BToast`, `bConfirm`.
- **Updater**: `BasaltUpdater.instance.start(owner:, repo:)` checks GitHub Releases each time the app opens (and on return after 15 minutes). It picks the APK for the phone's processor, verifies size and SHA-256, and opens Android's installer. `UpdateCard` and `UpdatesSection` are the UI.

```yaml
dependencies:
  basalt:
    git:
      url: https://github.com/muhammadahmad545-code/basalt-flutter.git
      ref: v0.1.0
```
