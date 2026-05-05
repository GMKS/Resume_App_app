# Android AAB Size Audit

## Current Findings

- Baseline plain release bundle measured about `59.42 MB`.
- Current optimized `arm64` release bundle measured about `22.7 MB`.
- Project assets are not the main issue. Bundled Flutter assets measured about `0.7 MB` in the optimized AAB.
- Native libraries dominate the release payload. The optimized `arm64-v8a` native payload measured about `30.59 MB` uncompressed inside the bundle.
- The release bytecode payload measured about `5.2 MB` uncompressed.
- Flutter size analysis showed `package:google_fonts` as a major Dart AOT contributor.

## Issues Found

1. Raw `flutter build appbundle --release` was bypassing the repo's optimized release path and producing a much larger bundle.
2. The size-analysis helper was broken because it passed `--analyze-size` together with `--split-debug-info`.
3. The font picker used `GoogleFonts.getFont(entry.key)` against a fixed font list, which prevented effective tree shaking of unused Google Fonts code.
4. The largest measured bundle reduction came from `arm64`-only output, but that changes device compatibility and is therefore optional rather than the default safe optimization.

## Fixes Applied

### 1. Release helper fixed

File: [build_android_release.ps1](build_android_release.ps1)

- Keeps `--tree-shake-icons` for all release builds.
- Uses `--obfuscate` and `--split-debug-info` for normal optimized releases.
- Automatically omits those flags in `-AnalyzeSize` mode so Flutter size analysis works.
- Prints the final generated AAB path and size after each build.

### 2. Google Fonts tree-shaking improvement

File: [lib/features/editor/widgets/resume_customization_sheets.dart](lib/features/editor/widgets/resume_customization_sheets.dart)

- Replaced dynamic `GoogleFonts.getFont(...)` calls with explicit helpers for the eight supported font families.
- Preserves the same visible font list and same UI behavior.
- Reduced the optimized `arm64` AAB from about `23.33 MB` to about `22.7 MB`.

## Size Breakdown

From the validated optimized `arm64` size-analysis build:

- Total compressed AAB: about `24.4 MB`
- Native libs: about `12 MB` compressed in the analysis view
- Dart/Java bytecode: about `2 MB` compressed in the analysis view
- Assets: about `381 KB` compressed in the analysis view
- Android resources: about `325 KB` compressed in the analysis view

Largest Dart AOT contributors reported by Flutter analysis:

- `package:google_fonts`: about `7 MB` decompressed
- `package:resume_builder`: about `4 MB` decompressed
- `package:flutter`: about `4 MB` decompressed
- `package:syncfusion_flutter_pdf`: about `1 MB` decompressed
- `package:image`: about `721 KB` decompressed
- `package:pdf`: about `273 KB` decompressed
- `package:archive`: about `99 KB` decompressed

## Safe Recommendations

1. Build Play releases with the helper script instead of raw `flutter build appbundle --release`.
2. Keep icon tree shaking enabled.
3. Keep R8 and resource shrinking enabled.
4. Avoid dynamic lookups that retain large registries in AOT when the app only supports a fixed set of values.

## Optional Recommendation

`-Arm64Only` gives the biggest measured reduction, but it drops 32-bit Android support. Use it only if your distribution requirements allow that tradeoff.

## Rebuild Commands

Standard optimized release:

```powershell
./build_android_release.ps1
```

Smallest bundle with `arm64` only:

```powershell
./build_android_release.ps1 -Arm64Only
```

Size analysis build:

```powershell
./build_android_release.ps1 -AnalyzeSize -Arm64Only
```

Then open Dart DevTools with the generated analysis file path shown in the build output.