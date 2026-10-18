# Changelog

## 0.2.6

- **Label header (Behavior Change)**: fluent `initialize()` now defaults to 203 DPI, the same 8 dot/mm resolution as `CpclConfiguration` and `CpclPrintDensity.d8`. Pass `horizontalDpi` and `verticalDpi` to keep a different resolution.
- **Rendered text (Behavior Change)**: `renderedText()`, `khmerText()`, and `CpclRenderedText` scale the Flutter picture by `pixelRatio` before rasterizing. `pixelRatio` previously only grew the bitmap and left the glyphs at 1× in the top-left corner. Preview uses that same scale and padding.

## 0.2.5

- **Inverse line (Behavior Change)**: `inverseLine()` and `CpclInverseLine` now emit the documented CPCL command `INVERSE-LINE {x0} {y0} {x1} {y1} {thickness}`. A rectangle at `(x, y)` sized `width` by `height` is written as `INVERSE-LINE x y (x+width) y height`. The previous 4-parameter form was not a valid `INVERSE-LINE` and did not invert that rectangle on the printer.
- Coordinates and size are checked against the CPCL `0..65535` range, including `x + width`.
- **Preview**: inverse-line regions now invert pixels drawn earlier, matching the printer. Content drawn after the command is left unchanged. The preview no longer paints an opaque black block over the rectangle.

## 0.2.4

- **Rendered Text Generalization**:
  - Add script-neutral `renderedText()` fluent method on `CpclGenerator`.
  - Add script-neutral `CpclRenderedText` declarative command for config-driven generation and previews.
  - Generalize Flutter-rendered bitmap rasterization to support any script (Khmer, Thai, Arabic, Devanagari, CJK, etc.) or custom font.
  - Maintain full backward compatibility for `khmerText()` and `CpclKhmerText` as aliases/wrappers.
  - Update `CpclPreview` and `CpclPreviewService` to support `CpclRenderedText` with identical rendering semantics.
  - Add architecture documentation in `doc/rendered_text_compatibility.md`.
- **Graphics (Behavior Change)**: `bitmap()`, `renderedText()`, and `khmerText()` now emit standard CPCL `CG` (COMPRESSED-GRAPHICS) with raw 1-bit binary bytes instead of invalid binary data under `EG`. Added `compressedGraphics()` alias and `expandedGraphics()` / `CpclExpandedGraphics` for 7-bit safe uppercase ASCII hexadecimal `EG` output.
- **Font Magnification (Behavior Change)**: Corrected `SETMAG` factor calculation in `text()` from zero-indexed `(multiplier - 1)` to direct 1-based documented factors (`style.xMultiplier` and `style.yMultiplier`). 2× magnification now emits `SETMAG 2 2` instead of `SETMAG 1 1` (which rendered at 1× on real printers). Magnification resets immediately with `SETMAG 0 0`. Added standalone `setMag(w, h)` for persistent printer state management.
- **Line Print Mode & Session Correctness (Behavior Change)**: Corrected `SETLP` to adhere to Zebra utility-session rules (`Valid Session Types: Utilities sessions only`).
  - Added canonical `setLinePrint()` emitting `! U1 SETLP ...`.
  - In declarative `_applyConfiguration()`, `linePrintOptions` is emitted before the label session header (`! 0 ...`), preventing bare utility commands inside page-mode label bodies.
  - Deprecated bare `setLp()`, delegating safely to `setLinePrint()`.
  - Distinguish resident font syntax (`font`, `size`, `lineSpacing`) and TrueType font syntax (`fontName`, `xScale`, `yScale`, `lineSpacing`) via `CpclResidentLinePrintOptions` and `CpclTrueTypeLinePrintOptions`. Legacy `unitWidth` and `unitHeight` parameters are deprecated and retained for source compatibility.
- **Barcode Semantics & Validation (Behavior Change)**: Corrected parameter semantics for `BARCODE` and `VBARCODE`:
  - Canonical properties on `CpclBarcodeOptions` are now `width` (narrow bar unit-width, `0..65535`) and `ratio` (wide-to-narrow bar ratio code).
  - Enforced valid discrete CPCL ratio codes (`0..4` and `20..30`) via `CpclBarcodeRatio` value class.
  - Enforced documented Zebra Link-OS command-level ranges: width `0..65535`, height `0..65535`, coordinates `0..65535` (rejecting negative coordinates), and maximum payload limit of 8191 bytes.
  - Legacy `narrow` and `wide` constructor parameters and getters are retained as deprecated source-compatible aliases, with canonical parameters taking precedence.
- **Architecture Documentation**: Added `doc/cpcl_command_coverage.md` and `doc/adr/0001-cpcl-protocol-command-model.md` documenting CPCL command syntax, session types, and architectural decisions.

## 0.2.3

- Add script-neutral `renderedText()` fluent method on `CpclGenerator`.
- Add script-neutral `CpclRenderedText` declarative command for config-driven generation and previews.
- Generalize Flutter-rendered bitmap rasterization to support any script (Khmer, Thai, Arabic, Devanagari, CJK, etc.) or custom font.
- Maintain full backward compatibility for `khmerText()` and `CpclKhmerText` as aliases/wrappers.
- Update `CpclPreview` and `CpclPreviewService` to support `CpclRenderedText` with identical rendering semantics.
- Add architecture documentation in `doc/rendered_text_compatibility.md`.

## 0.2.2

- Improve package API documentation coverage with comprehensive dartdoc comments across exported types.
- Add missing docs for declarative command classes and key methods (including `apply` overrides).
- Keep package validation clean for publishing (`dart pub publish --dry-run` with zero warnings).

## 0.2.1

- Improve `CpclPreview` layout stability inside bounded widgets and avoid rerender churn on ordinary rebuilds.
- Add preview customization options for frame padding, border radius, box shadow, zoom interaction, and preview surface styling.
- Add optional checkerboard preview background to make light labels easier to inspect on screen.
- Refresh README examples and expand widget test coverage for preview behavior.

## 0.2.0

- Add declarative `CpclConfiguration` and `commands` support for config-driven label generation.
- Add typed declarative commands such as `CpclText`, `CpclBarcode`, `CpclQrCode`, `CpclBox`, and `CpclKhmerText`.
- Add async `buildAsync()` and `previewAsync()` support for labels that include Flutter-rendered text.
- Add `CpclPreview` for live in-app label previews and `CpclPreviewService` for PNG or PDF export.
- Refresh the example app, README, and tests to cover the new generator and preview APIs.

## 0.1.0

- Replace the default package template with a usable CPCL command generator.
- Add chainable APIs for label setup, text, line, box, inverse line, barcode, vertical barcode, QR code, bitmap, and print commands.
- Add typed option objects for barcode, QR, and `SETLP` configuration.
- Add common CPCL control commands such as `contrast()`, `country()`, and `setLp()`.
- Add Flutter-rendered bitmap text support for Khmer and other Unicode text.
- Document the package with sizing guidance and richer shipping-label examples.
- Add test coverage for sanitization, richer label flows, and typed options.
