# Publishing Workflow

Before publishing a new version of `flutter_device_info_plus` to pub.dev, follow this checklist:

1. **Update Version**: Bump the semantic version in `pubspec.yaml`.
2. **Update Changelog**: Add an entry for the new version in `CHANGELOG.md` detailing the changes.
3. **Run Formatting**: Run `dart format .` to ensure code is properly formatted.
4. **Run Analysis**: Run `flutter analyze` and ensure **zero** issues are found.
5. **Run Tests**: Run `flutter test` to ensure no regressions.
6. **Dry Run Publish**: Run `flutter pub publish --dry-run` to catch any potential pub.dev issues and verify the Pana score locally.
7. **Publish**: Run `flutter pub publish`.
