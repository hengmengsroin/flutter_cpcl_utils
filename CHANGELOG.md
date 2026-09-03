# Changelog

## 0.2.3

- Add script-neutral `renderedText()` fluent method on `CpclGenerator`.
- Add script-neutral `CpclRenderedText` declarative command for config-driven generation and previews.
- Generalize Flutter-rendered bitmap rasterization to support any script (Khmer, Thai, Arabic, Devanagari, CJK, etc.) or custom font.
- Maintain full backward compatibility for `khmerText()` and `CpclKhmerText` as aliases/wrappers.
- Update `CpclPreview` and `CpclPreviewService` to support `CpclRenderedText` with identical rendering semantics.
- Add architecture documentation in `docs/rendered_text_compatibility.md`.

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
