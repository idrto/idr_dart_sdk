# idr_dart_sdk

Pure **Dart** package (no Flutter SDK dependency) for embedding the [idr.to](https://idr.to) agent via FFI to `libidr_sdk` (Rust [`idr-ffi`](https://github.com/idrto/client/tree/main/crates/idr-ffi)).

[![pub package](https://img.shields.io/pub/v/idr_dart_sdk.svg)](https://pub.dev/packages/idr_dart_sdk)

## Install

**pub.dev** (when published):

```yaml
dependencies:
  idr_dart_sdk: ^1.0.0
```

**Git** (latest from main):

```yaml
dependencies:
  idr_dart_sdk:
    git:
      url: https://github.com/idrto/idr_dart_sdk.git
      ref: main
```

**Path** (monorepo / local dev):

```yaml
dependencies:
  idr_dart_sdk:
    path: ../idr_dart_sdk
```

## Native library

This package is FFI bindings only. Build `libidr_sdk` from the [idr.to client](https://github.com/idrto/client) repo:

```bash
git clone https://github.com/idrto/client
cd client
cargo build --release -p idr-ffi
```

| Platform | Artifact |
|----------|----------|
| Linux / Android | `target/release/libidr_sdk.so` |
| macOS | `target/release/libidr_sdk.dylib` |
| Windows | `target/release/idr_sdk.dll` |
| iOS | static `libidr_sdk.a` (see client `platform/mobile/`) |

Ship the library with your app or set an explicit path:

```dart
final client = await IdrClient.open(IdrConfig(
  apiBaseUrl: 'https://idr.to',
  stateDir: stateDir,
  library: DefaultIdrNativeLibrary(
    libraryPath: '/path/to/libidr_sdk.so',
  ),
));
```

Environment variable `IDR_SDK_LIB` is supported by the [Flutter example](example/).

## Usage

```dart
import 'package:idr_dart_sdk/idr_dart_sdk.dart';

final client = await IdrClient.open(IdrConfig(
  apiBaseUrl: 'https://sig.scomm.ai',
  stateDir: stateDir,
));

await client.configureAgent(IdrAgentProfile(
  mode: IdrAgentMode.hybrid,
  entityId: 'user@example.com',
  host: 'laptop',
));

await client.loginWithPassword(
  entityId: 'user@example.com',
  password: secret,
);

// Target: accept inbound connections
await client.joinDevice(IdrJoinOptions(hostName: 'laptop'));
await client.startAgent();

// Source: outbound tunnel
final session = await client.connect(
  'idrto:example.com/server/22',
  options: IdrConnectOptions(localPort: 2222),
);

client.dispose();
```

## Flutter example

See [`example/`](example/) — a tabbed demo for setup, auth, target agent, and source connect.

```bash
# Build native lib first (see above), then:
export IDR_SDK_LIB=/path/to/libidr_sdk.so   # optional
cd example
flutter pub get
flutter run
```

## API surface

| Dart | CLI equivalent |
|------|----------------|
| `configureAgent()` | `idr-agent.toml` profile |
| `loginWithPassword()` / `loginWithToken()` | `idr auth login` |
| `joinDevice()` | `idr device join` |
| `startAgent()` / `stopAgent()` | `idr agent run` |
| `connect()` | `idr connect` |

Full matrix: [client docs/SDK.md](https://github.com/idrto/client/blob/main/docs/SDK.md).

## Development

```bash
dart pub get
dart test
dart analyze
dart pub publish --dry-run   # before releasing to pub.dev
```

See [PUBLISHING.md](PUBLISHING.md).

## License

MIT — see [LICENSE](LICENSE).
