# Coding Standards

## Dart Code
- Follow [Effective Dart](https://dart.dev/effective-dart).
- Maintain 100% documentation coverage on public APIs.
- Keep the `dart analyze` score at 0 issues. No exceptions.
- Prefer `final` for variables and function parameters where appropriate.

## Web Implementation
- **Strictly use `dart:js_interop`**: Do not use the legacy `dart:html` or `package:js`. The code must be WASM-compatible.
- **Conditional Imports**: Any file utilizing `dart:js_interop` MUST be hidden behind a conditional import to prevent compiler errors on desktop/mobile platforms.
  - Example: `import 'web_stub.dart' if (dart.library.js_interop) 'web_impl.dart';`

## Swift / iOS / macOS
- **Swift Package Manager**: Always structure the code using the modern SPM folder structure (e.g., `macos/flutter_device_info_plus/Sources/flutter_device_info_plus/`).
- **CocoaPods Support**: Maintain backward compatibility for CocoaPods users by updating the `.podspec` `source_files` to point to the new SPM directory.
- **Availability Checks**: Use `@available(macOS X.X, *)` for APIs introduced in newer OS versions to prevent compile errors on minimum deployment targets (e.g., macOS 10.14).
