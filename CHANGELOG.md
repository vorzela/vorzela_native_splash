# Changelog

## 0.0.6

### Fixed
- **iOS asset catalog filenames** — `Contents.json` now references the real
  `splash@2x.png` / `splash@3x.png` (and branding equivalents) written by the
  densifier. Previously it listed placeholder names (`LaunchImage.png`, …)
  that Xcode could never find, so @2x/@3x splash art was missing.
- **Warning interpolation** — `${decoded.width}×${decoded.height}` so
  “image too small” messages show real dimensions instead of
  `Instance of 'Image'.width`.

### Performance
- Decode cache keyed by path (caches the `Future` so concurrent Android/iOS
  work shares one in-flight decode).
- Android + iOS generation run concurrently; density-bucket resize/encode
  writes also run concurrently.
- No-op resizes clone the cached image so concurrent PNG encodes never share
  a live buffer.
