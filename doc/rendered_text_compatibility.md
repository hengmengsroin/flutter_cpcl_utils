# Rendered Text API Compatibility & Architecture Decision

## Overview

This document records the architectural rationale for introducing the script-neutral rendered text API (`renderedText()` and `CpclRenderedText`) and preserving existing Khmer-specific APIs (`khmerText()` and `CpclKhmerText`) for backward compatibility.

## Background

Most CPCL label printers only provide built-in bitmap or vector fonts for ASCII and a handful of Western single-byte code pages (e.g. Code Page 1252). Complex Unicode scripts—such as Khmer, Thai, Lao, Burmese, Arabic, and Devanagari—as well as East Asian CJK characters and custom brand typefaces cannot be printed using native CPCL `TEXT` commands without custom printer-resident firmware fonts.

To solve this, `flutter_cpcl_utils` introduced rasterization support: rendering text onto a Flutter canvas and serializing the resulting monochrome bitmap into standard CPCL `EG` bitmap commands.

Originally, this feature was named specifically for Khmer (`khmerText()` and `CpclKhmerText`) because that was the primary author's immediate production requirement.

## The Problem

While the rasterization engine (using Flutter's `TextPainter`, `PictureRecorder`, and `_rasterize`) has always been fully script-agnostic, the public API was Khmer-specific:

- `generator.khmerText(...)`
- `CpclKhmerText(...)`

This caused confusion for developers looking to print other scripts or custom fonts (e.g., Thai, Arabic, CJK, or custom icon fonts) who assumed the package only supported Khmer, or hesitated to use an API with a language-specific name for non-Khmer text.

## Architectural Decisions

### 1. Canonical Script-Neutral APIs

The primary, intended API for Flutter-rendered bitmap text is now script-neutral:

- **Fluent Generator**: `generator.renderedText(x, y, text, options: options)`
- **Declarative Command**: `CpclRenderedText(x: x, y: y, text: text, options: options)`
- **Options**: `CpclRenderedTextOptions(...)` (already script-neutral)

Any script, font family, or symbol that Flutter's text engine can render on the current platform can be rasterized and printed with this API.

### 2. Full Backward Compatibility for Khmer APIs

Existing codebases must not break. To ensure zero breaking changes:

- `generator.khmerText(...)` remains available as a wrapper forwarding directly to `renderedText(...)`.
- `CpclKhmerText` extends `CpclRenderedText`, maintaining the identical constructor signature, properties, and error behavior.
- In-memory type checks (e.g., `is CpclRenderedText`) match both `CpclRenderedText` and `CpclKhmerText`.
- Rasterization logic is shared; there is no code duplication.

### 3. Preview & Export Support

The local preview engine (`CpclPreview`) and export service (`CpclPreviewService`) handle `CpclRenderedText` (and by inheritance, `CpclKhmerText`) using consistent text painter semantics.

### 4. Migration & Deprecation Guidance

- **New Code**: Use `renderedText()` and `CpclRenderedText`.
- **Existing Code**: Existing calls to `khmerText()` and `CpclKhmerText` remain fully functional and supported. No immediate migration is required.
