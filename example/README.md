# Flutter example — idr.to agent demo

Demonstrates **source** (outbound `connect`) and **target** (inbound `join` + `startAgent`) using `idr_dart_sdk`.

## Dependencies

This example uses a **path** dependency on the parent package (`path: ../`). External apps should use pub.dev or git:

```yaml
dependencies:
  idr_dart_sdk:
    git:
      url: https://github.com/idrto/idr_dart_sdk.git
      ref: main
```

## Prerequisites

1. Flutter 3.19+
2. Built `libidr_sdk` from [idrto/agent](https://github.com/idrto/agent):

```bash
cargo build --release -p idr-ffi
```

3. Set `IDR_SDK_LIB` to the library path (or copy into the app bundle):

```bash
# Linux
export IDR_SDK_LIB=/path/to/client/target/release/libidr_sdk.so

# Windows
set IDR_SDK_LIB=D:\path\to\client\target\release\idr_sdk.dll
```

## Run

```bash
cd example
flutter pub get
flutter run -d linux    # or windows, macos, android, ios
```

## Tabs

| Tab | CLI equivalent |
|-----|----------------|
| Setup | `--api`, agent profile (`mode`, `entity_id`, `host`) |
| Auth | `idr auth login`, token login, logout |
| Target | `idr device join`, `idr agent run` |
| Source | `idr connect` |
