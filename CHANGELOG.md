# Changelog

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
