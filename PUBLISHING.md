# Publishing to pub.dev

## Prerequisites

1. [pub.dev](https://pub.dev) account with uploader access to `idr_dart_sdk`
2. `dart pub login`
3. Clean `dart pub publish --dry-run` with no errors

## Checklist

- [ ] Bump `version` in `pubspec.yaml` (semver)
- [ ] Update `CHANGELOG.md`
- [ ] `dart test` and `dart analyze` pass
- [ ] `dart pub publish --dry-run`
- [ ] Tag release: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] `dart pub publish`

## Version policy

- **MAJOR**: breaking FFI or public Dart API changes
- **MINOR**: new `IdrClient` methods matching `idr-ffi` releases
- **PATCH**: docs, fixes, no API change

Coordinate with [idrto/client](https://github.com/idrto/client) `idr-ffi` releases — document required `libidr_sdk` version in CHANGELOG.

## Consumers

After publish, apps depend on:

```yaml
dependencies:
  idr_dart_sdk: ^1.0.0
```

Git consumers pin a tag:

```yaml
dependencies:
  idr_dart_sdk:
    git:
      url: https://github.com/idrto/idr_dart_sdk.git
      ref: v1.0.0
```
