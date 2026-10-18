# ADR 0001: Authoritative CPCL Protocol Command Model & Corrections

## Status
Accepted

## Context
`flutter_cpcl_utils` generates CPCL (Comtec Printer Control Language) print streams for thermal mobile printers. An independent protocol audit against authoritative Zebra CPCL documentation revealed critical discrepancies where previous implementations emitted non-standard parameters, invalid command sessions, or conflated binary/text encoding formats.

This decision record formalizes the protocol corrections made to align the library with Zebra CPCL specifications while retaining backward source compatibility for existing callers.

---

## Decisions

### 1. Binary Graphics: `CG` (COMPRESSED-GRAPHICS) vs. `EG` (EXPANDED-GRAPHICS)
* **Problem**: Previous versions emitted `EG` immediately followed by raw 8-bit binary bytes.
* **Specification**:
  * In Zebra CPCL, `EG` expects **ASCII hexadecimal** strings (`0-9`, `A-F`), requiring 2 characters per byte.
  * In Zebra CPCL, `CG` (COMPRESSED-GRAPHICS) is the designated command for **raw 8-bit binary** data, transmitting 1 byte per 8 horizontal dots (MSB first).
  * **Naming Clarification**: Zebra names this command `COMPRESSED-GRAPHICS`, but the manual explicitly notes that the bitmap data is not algorithmically compressed (no RLE, LZW, or Deflate compression is applied). It is simply twice as efficient in byte size as ASCII hexadecimal `EG`.
* **Resolution**:
  * Default binary bitmap rendering (`bitmap()`, `renderedText()`, `khmerText()`) now emits the standard `CG` command with raw binary bytes.
  * Added `compressedGraphics()` as an explicit alias for `bitmap()`. The dartdoc clarifies that the payload is raw binary bitmap data and no compression algorithm is applied.
  * Added `expandedGraphics()` and declarative `CpclExpandedGraphics` for callers requiring 7-bit safe uppercase ASCII hexadecimal `EG` output (`00`..`FF`).
  * `CpclCommandBuffer` appends raw binary bytes directly into the stream without Latin-1 string conversion or character substitution.

### 2. Font Magnification: `SETMAG` Factors & Reset
* **Problem**: The library previously emitted `SETMAG (xMultiplier - 1) (yMultiplier - 1)`. When a caller requested `2x` magnification, it generated `SETMAG 1 1`, which CPCL interprets as standard 1× scale.
* **Specification**:
  * Zebra CPCL specifies direct factors: `SETMAG {w} {h}` where `w` and `h` are integers from `1` to `16`. `1 1` is standard scale.
  * `SETMAG 0 0` is the designated command to reset magnification back to resident font defaults.
  * **Printer State Persistence**: In CPCL, `SETMAG` modifies printer state persistently across labels until explicitly reset or power-cycled.
* **Resolution**:
  * `text()` emits direct factors `SETMAG ${style.xMultiplier} ${style.yMultiplier}` when magnification is requested, and resets immediately with `SETMAG 0 0`.
  * Added standalone `setMag(w, h)` allowing callers to manage persistent magnification when needed.

### 3. Line Print Font: `SETLP` Session Correctness & Argument Hierarchy
* **Problem**: The library previously emitted 4 numeric parameters (`SETLP font size unitWidth unitHeight`) inside page-mode labels between the `! 0` header and `PRINT`.
* **Specification**:
  * **Valid Session Types**: In Zebra CPCL, `SETLP` is documented for **utility sessions only** (e.g. `! U1 SETLP ...`) and line-print receipt mode. It is invalid syntax to emit bare `SETLP` within a page-mode label session (`! 0 ...`).
  * **Resident / pre-scaled fonts**: Takes exactly 3 arguments: `SETLP <font> <size> <lineSpacing>`.
  * **TrueType fonts**: Takes 4 arguments: `SETLP <fontName> <xScale> <yScale> <lineSpacing>`.
  * **Sequential Utility Commands**: Zebra CPCL supports executing one-line utility commands (`! U1 ...`) immediately prior to starting a page-mode label session (`! 0 ...`) in the same transmission stream.
* **Resolution**:
  * Established `setLinePrint(options)` as the canonical safe method emitting the utility command prefix: `! U1 SETLP ${options.formatArguments()}`.
  * In declarative `_applyConfiguration()`, if `linePrintOptions` is specified on `CpclConfiguration`, it is emitted **before** `initialize()` (`! 0 ...`). This ensures no bare utility command is ever placed inside the page-mode label session.
  * Deprecated `setLp()` and updated it to delegate to `setLinePrint()`, preventing bare `SETLP` generation even from legacy call sites.
  * `CpclLinePrintOptions` (aliased as `CpclResidentLinePrintOptions`) models resident fonts with `font`, `size`, and `lineSpacing`. Legacy `unitWidth` is deprecated and ignored during command generation; legacy `unitHeight` delegates to `lineSpacing`.
  * Added `CpclTrueTypeLinePrintOptions` for downloadable TrueType fonts (`fontName`, `xScale`, `yScale`, `lineSpacing`).

### 4. Barcode Parameters: `width` and `ratio` Semantics
* **Problem**: Parameters were named `narrow` and `wide`, documenting `wide` as "wide bar width in dots."
* **Specification**:
  * Zebra CPCL syntax is: `{command} {type} {width} {ratio} {height} {x} {y} {data}`.
  * **Width**: Narrow bar unit-width in dots (`> 0`). The Zebra specification does not restrict width to an arbitrary `1..32` limit; large unit-widths are supported by the command format.
  * **Ratio**: Wide-to-narrow bar ratio code. Valid CPCL ratio codes are `0..4` (representing 1.5:1 to 3.5:1) and every integer from `20..30` (representing 2.0:1 to 3.0:1).
  * **Symbology Note**: Certain symbologies (e.g. Code 128) ignore ratio during rendering, but CPCL syntax still requires the parameter field and invalid ratio codes can cause printers to reject the command.
* **Resolution**:
  * Represented ratio via the `CpclBarcodeRatio` value class, which supports all documented codes (`0..4` and `20..30`) and validates inputs.
  * `CpclBarcodeOptions` uses canonical properties `width` and `ratio`.
  * Deprecated `narrow` and `wide` getters and constructor parameters as backward-compatible aliases.
  * Vertical barcodes (`VBARCODE`) share identical option semantics and validation.

### 5. Intentional Decision on DPI Defaults
* **Observation**: Fluent `initialize()` currently defaults to 200 DPI, whereas declarative `CpclConfiguration` defaults to 203 DPI (`d8`).
* **Decision**: We intentionally do NOT alter DPI defaults in this batch to keep changes strictly focused on protocol correctness and prevent unintended coordinate drift in existing client layouts. Harmonization will be scheduled in a dedicated version increment.

---

## Compatibility Classification

We distinguish three aspects of compatibility:

1. **Source Compatibility (Preserved)**:
   * Existing Dart client code calling `bitmap()`, `text()`, `setLp()`, `barcode()`, and `CpclBarcodeOptions(narrow: ..., wide: ...)` continues to compile with zero compile errors.
   * Deprecated parameters and methods are retained with clear `@Deprecated` migration annotations.

2. **Behavioral Compatibility (Changed for Correctness)**:
   * `bitmap()` now emits `CG` instead of `EG` in the generated byte stream.
   * `SETMAG` for 2× magnification now emits `SETMAG 2 2` instead of `SETMAG 1 1`, causing real printers to render the text at true 2× size.
   * `setLp()` and `CpclConfiguration.linePrintOptions` now emit `! U1 SETLP ...` (utility session) rather than bare `SETLP` inside page mode.
   * Legacy `CpclLinePrintOptions.unitWidth` is no longer emitted into the resident `SETLP` command stream.

3. **Protocol Correctness (Achieved)**:
   * Generated streams now strictly conform to Zebra CPCL syntax, session rules, and payload encoding definitions.
