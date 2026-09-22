# vorzela_native_splash_lint

[`custom_lint`](https://pub.dev/packages/custom_lint) rules for
[vorzela_native_splash](https://github.com/vorzela/vorzela_native_splash).

## Install

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  vorzela_native_splash_lint:
    path: packages/vorzela_native_splash_lint
```

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - prefer_preserve_before_run_app
    - prefer_splash_logo
```

```bash
dart run custom_lint
```

## Rules

| Rule | What it catches |
|------|-----------------|
| `prefer_preserve_before_run_app` | `runApp` + `VorzelaSplashGate` without `VorzelaNativeSplash.preserve` |
| `prefer_splash_logo` | Raw `Image` / `Image.asset` as `VorzelaSplashGate.logo` |

## License

MIT
