# CPCL Command Coverage & Protocol Specification Matrix

This document is the authoritative source of truth for CPCL command syntax, parameters, valid ranges, session types, and compatibility across the `flutter_cpcl_utils` library, derived directly from the Zebra CPCL Programming Manual and Link-OS documentation.

## Compatibility Classifications

* **CPCL Core / Legacy**: Supported across virtually all Zebra CPCL mobile printers (QL, QL Plus, RW, MZ, Cameo, Encore) and third-party CPCL emulators (Bixolon, Woosim, Rongta, Xprinter).
* **Link-OS CPCL**: Modern Zebra CPCL firmware (ZQ500, ZQ600, ZQ300, QLn series, iMZ) supporting enhanced commands and SGD (Set-Get-Do).
* **Model-Dependent**: Available only on printers with specific hardware features (e.g. cutter, peeler, specific DPI print heads).
* **Vendor Extension / Unknown**: Non-standard dialect variation or third-party emulator-specific behavior.

---

## Command Coverage Matrix

| Command | Supported | Syntax Verified | Validation Verified | Preview Support | Session | Classification | Notes |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :--- |
| **Session Header (`!`)** | Yes | Yes (Partial) | Partial | N/A | Label (`! 0`) / Utility (`! U1`) | CPCL Core | Syntax: `! {offset} {h-dpi} {v-dpi} {height} {qty}`. Fluent defaults to 200 DPI while declarative defaults to 203 DPI. |
| **`PAGE-WIDTH`** | Yes | Yes | Yes | Yes (via config) | Label | CPCL Core | Syntax: `PAGE-WIDTH {width}`. Sets printable page width in dots. |
| **`SPEED`** | Yes | Yes | Yes (0..5) | No | Label / Utility | CPCL Core | Syntax: `SPEED {0..5}`. Sets print speed level. |
| **`TONE`** | Yes | Yes | Yes (0..3) | No | Label / Utility | CPCL Core | Syntax: `TONE {0..3}`. Controls printhead heat/darkness. |
| **`CONTRAST`** | Yes | Yes | Yes (0..3) | No | Label / Utility | CPCL Core | Syntax: `CONTRAST {0..3}` (0=default, 1=medium, 2=dark, 3=very dark). |
| **`COUNTRY`** | Yes | Yes | Yes (enum) | No | Label / Utility | CPCL Core | Syntax: `COUNTRY {code}` (USA, FRANCE, GERMANY, UK, SPAIN, ITALY, SWEDEN, NORWAY). Modifies character table. |
| **`PREFEED`** | Yes | Yes | Yes (>=0) | No | Label / Utility | CPCL Core | Syntax: `PREFEED {dots}`. Feed distance prior to printing. |
| **`POSTFEED`** | Yes | Yes | Yes (>=0) | No | Label / Utility | CPCL Core | Syntax: `POSTFEED {dots}`. Feed distance after printing. |
| **`CENTER`** | Yes | Yes | N/A | No | Label | CPCL Core | Centers subsequent text and barcodes until next alignment command. |
| **`LEFT`** | Yes | Yes | N/A | No | Label | CPCL Core | Left-aligns subsequent text and barcodes. Default. |
| **`RIGHT`** | Yes | Yes | N/A | No | Label | CPCL Core | Right-aligns subsequent text and barcodes. |
| **`SETLP`** | Yes | Yes (Verified) | Yes | No | Line-Print / Utility (`! U1`) | CPCL Core | Resident: `SETLP <font> <size> <lineSpacing>`. TrueType: `SETLP <fontName> <xScale> <yScale> <lineSpacing>`. `setLinePrint()` emits `! U1 SETLP`. |
| **`TEXT`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `TEXT {font} {size} {x} {y} {data}`. Standard horizontal text. |
| **`TEXT90`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `TEXT90 {font} {size} {x} {y} {data}`. Rotated 90° clockwise. |
| **`TEXT180`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `TEXT180 {font} {size} {x} {y} {data}`. Rotated 180° upside down. |
| **`TEXT270`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `TEXT270 {font} {size} {x} {y} {data}`. Rotated 270° clockwise. |
| **`VTEXT`** | No | Yes | N/A | No | Label | CPCL Core | Syntax: `VTEXT {font} {size} {x} {y} {data}`. Vertical text (vertical character stacking). |
| **`SETMAG`** | Yes | Yes (Verified) | Yes (1..16) | Yes | Label | CPCL Core | Syntax: `SETMAG {w} {h}` (`1..16` direct scale factors). `SETMAG 0 0` resets to standard resident font scale. |
| **`LINE`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `LINE {x0} {y0} {x1} {y1} {thickness}`. |
| **`BOX`** | Yes | Yes | Partial | Yes | Label | CPCL Core | Syntax: `BOX {x0} {y0} {x1} {y1} {thickness}`. |
| **`INVERSE-LINE`**| Yes | Yes (Verified) | Yes | Yes | Label | CPCL Core | Syntax: `INVERSE-LINE {x0} {y0} {x1} {y1} {thickness}` (same geometry as `LINE`). `inverseLine(x, y, width, height)` emits `INVERSE-LINE x y (x+width) y height`. Inverts earlier content inside the rectangle only. |
| **`BARCODE`** | Yes | Yes (Verified) | Yes | Yes (Heuristic) | Label | CPCL Core | Syntax: `BARCODE {type} {width} {ratio} {height} {x} {y} {data}`. `ratio` represents CPCL ratio code (0, 1, 2, 3, 20..30). |
| **`VBARCODE`** | Yes | Yes (Verified) | Yes | Yes (Heuristic) | Label | CPCL Core | Vertical barcode variant of `BARCODE`. Shares same `{width}` and `{ratio}` parameters. |
| **`B QR`** | Yes | Yes | Partial | Yes | Label | CPCL Core / Link-OS | Syntax: `B QR {x} {y} M {model} U {unit}\r\n{ecc}A,{data}\r\nENDQR`. |
| **`EG`** | Yes | Yes (Verified) | Yes (0..255) | Yes | Label | CPCL Core | Syntax: `EG {widthBytes} {height} {x} {y} {hexData}`. Transmits 1-bit bitmap as uppercase ASCII hexadecimal strings. |
| **`CG`** | Yes | Yes (Verified) | Yes (0..255) | Yes | Label | CPCL Core | Syntax: `CG {widthBytes} {height} {x} {y} {binaryData}`. Transmits raw 8-bit binary bitmap data. Default for `bitmap()`. |
| **`FORM`** | Yes | Yes | N/A | N/A | Label | CPCL Core | Signals top-of-form feed. |
| **`PRINT`** | Yes | Yes | N/A | N/A | Label | CPCL Core | Terminates label definition and initiates printing. |
| **`POFF`** | No | Yes | N/A | No | Utility (`! U1`) | CPCL Core | Sets power-off timeout or powers printer down immediately. |
| **`SET-TIMEOUT`** | No | Yes | N/A | No | Utility (`! U1`) | CPCL Core | Sets communication timeout in seconds. |
| **`JOURNAL` / `PRINT`**| No| Yes | N/A | No | Line-Print | CPCL Core | Receipts with variable length. |
| **`ENCODING`** | No | Yes | N/A | No | Label / Utility | Link-OS CPCL | Configures UTF-8 encoding support for Link-OS CPCL printers. |

---

## Detailed Protocol Analysis by Command

### 1. Label Session Header (`!`)
* **Documented Syntax**:
  `! {offset} {horizontal-dpi} {vertical-dpi} {height} {qty}`
* **Parameters**:
  * `{offset}` (int): Horizontal offset from left edge in dots (typically 0).
  * `{horizontal-dpi}` (int): Printer resolution across the printhead (203 for 8 dmm, 300 for 12 dmm).
  * `{vertical-dpi}` (int): Printer resolution along media travel (203 for 8 dmm, 300 for 12 dmm).
  * `{height}` (int): Maximum length of the label in dots.
  * `{qty}` (int): Quantity of label copies to print (1..32000).
* **Current Library Discrepancy**:
  * Fluent `initialize(...)` defaults to `horizontalDpi: 200, verticalDpi: 200`.
  * Declarative `CpclConfiguration` defaults to `printDensity: CpclPrintDensity.d8` (203 DPI).
  * Zebra standard for 8 dots/mm heads is 203 DPI. Fluent defaulting to 200 produces mismatched CPCL headers.

### 2. `EG` vs. `CG` (Graphics Commands)
* **Zebra Specification**:
  * **`EG` (EXPANDED-GRAPHICS)**: `{command} {widthInBytes} {height} {x} {y} {hexData}`
    * Transmits graphics as **ASCII hexadecimal strings** (2 ASCII characters `0-9, A-F` per byte).
    * Twice the byte payload size of raw binary, but 7-bit safe and human-readable.
  * **`CG` (COMPRESSED-GRAPHICS)**: `{command} {widthInBytes} {height} {x} {y} {binaryData}`
    * Transmits graphics as **raw 8-bit binary bytes** (1 byte per 8 pixels, MSB first).
    * Exactly 1 byte per 8 dots.
* **Current Library Discrepancy**:
  * `generator.bitmap()` currently emits the token `EG {widthBytes} {height} {x} {y} ` followed immediately by **raw binary bytes** (`_commands.addRawBytes(raster.bytes)`).
  * On genuine Zebra printers, sending raw binary to an `EG` command causes the printer to interpret binary values as ASCII hex tokens, resulting in corrupt printing or aborted parsing.
  * **Correction**:
    1. Support `CG` for raw binary bytes (most efficient).
    2. In `EG`, encode `raster.bytes` to ASCII hexadecimal characters (`00` through `FF`).

### 3. `SETMAG` (Font Magnification)
* **Zebra Specification**:
  * Syntax: `SETMAG {w} {h}`
  * `{w}`: Width magnification factor (`1` to `16`). `1` is normal (1×) size.
  * `{h}`: Height magnification factor (`1` to `16`). `1` is normal (1×) size.
  * Reset: `SETMAG 0 0` resets magnification back to default resident font dimensions.
  * **Persistence**: `SETMAG` is persistent in printer memory across labels until explicitly reset or power-cycled.
* **Current Library Discrepancy**:
  * Current implementation executes:
    `rawCommand('SETMAG ${style.xMultiplier - 1} ${style.yMultiplier - 1}')`
  * When a caller specifies `xMultiplier: 2, yMultiplier: 2`, the package outputs `SETMAG 1 1`, which prints text at **1× (normal size)** instead of 2×!
  * When a caller specifies `xMultiplier: 1, yMultiplier: 1`, it skips `SETMAG`, leaving whatever magnification was previously set on the printer active.

### 4. `SETLP` (Line Print Mode Font)
* **Zebra Specification**:
  * Syntax: `! U1 SETLP {font} {size} {unitHeight}` or `SETLP {font} {size} {unitHeight}`
  * Parameters:
    * `{font}`: Font ID number (0..7) or font name.
    * `{size}`: Font size number (non-negative integer).
    * `{unitHeight}`: Vertical line spacing / advance in dots when CR/LF is received.
  * **Total parameters**: 3 parameters.
* **Current Library Discrepancy**:
  * Current implementation executes:
    `'SETLP ${options.font.value} ${options.size} ${options.unitWidth} ${options.unitHeight}'`
  * Emits **4 parameters**, inventing a non-existent `unitWidth` argument. Zebra CPCL firmware treats the fourth argument as invalid syntax or assigns it to the wrong register.

### 5. `BARCODE` and `VBARCODE`
* **Zebra Specification**:
  * Syntax: `{command} {type} {width} {ratio} {height} {x} {y} {data}`
  * Parameters:
    * `{type}`: Symbology code (e.g. `128`, `39`, `EAN13`, `UPCA`).
    * `{width}`: Unit-width of the **narrow bar** in dots (typically 1..32).
    * `{ratio}`: Ratio of wide bar to narrow bar. Accepts specific ratio codes:
      * `0` = 1.5:1
      * `1` or `20` = 2.0:1
      * `2` or `25` = 2.5:1
      * `3` or `30` = 3.0:1
      * `4` = 3.5:1
      * (For two-width symbologies like Code 39, Codabar, Interleaved 2 of 5).
    * `{height}`: Vertical barcode height in dots.
    * `{x}`, `{y}`: Starting coordinates in dots.
    * `{data}`: Barcode data payload.
* **Current Library Discrepancy**:
  * `CpclBarcodeOptions` names the parameters `narrow` and `wide`:
    `final int narrow; final int wide;`
  * It documents `wide` as "Wide bar width in dots".
  * In reality, parameter 3 is the **ratio code**, not a dot width. Calling it `wide` is semantically incorrect and confuses callers trying to set ratio codes.

### 6. `INVERSE-LINE`
* **Zebra Specification**:
  * Syntax matches `LINE`: `INVERSE-LINE {x0} {y0} {x1} {y1} {thickness}` (alias `IL`).
  * For a horizontal bar, `(x0, y0)` is the top-left corner, `(x1, y0)` is the top-right corner, and `{thickness}` extends downward.
  * Pixels of objects created *before* the command are inverted inside that area. Objects created afterward are not affected.
  * Manual example: `INVERSE-LINE 0 45 145 45 45` covers x `0..145` and y `45..90`.
* **Library mapping**:
  * `inverseLine(x, y, width, height)` and `CpclInverseLine` keep a rectangle API and emit `INVERSE-LINE x y (x+width) y height`.
  * `inverseLine(0, 45, 145, 45)` therefore emits the manual example above.
  * `x`, `y`, `width`, `height`, and `x + width` must fall in `0..65535` (`width` and `height` at least 1).
  * Preview uses a difference blend over that rectangle so earlier marks invert and later marks stay as drawn.

---

## Architectural Session Model

Zebra CPCL distinguishes several command sessions and execution contexts:

```
┌─────────────────────────────────────────────────────────────┐
│                      CPCL Stream Engine                     │
├───────────────────────────────┬─────────────────────────────┤
│ 1. Label Session (! 0 ...)    │ Page mode formatted labels  │
│    - PAGE-WIDTH, TEXT, BOX,   │ Ended with FORM / PRINT     │
│      BARCODE, CG/EG, SETMAG   │                             │
├───────────────────────────────┼─────────────────────────────┤
│ 2. Utility Session (! U1 ...) │ Single or multi-line cmds   │
│    - SETLP, COUNTRY, SPEED,   │ Immediate execution         │
│      SET-TIMEOUT, POFF, SGD   │                             │
├───────────────────────────────┼─────────────────────────────┤
│ 3. Line Print Session         │ Continuous receipt mode     │
│    - SETLP, raw text lines    │ Form feed on paper tear     │
├───────────────────────────────┼─────────────────────────────┤
│ 4. Escape / Raw Commands      │ Direct printer pass-through │
│    - vendor escape sequences  │                             │
└───────────────────────────────┴─────────────────────────────┘
```

### Encoding & Unicode Strategy
1. **Default Encoding**:
   * CPCL native firmware is predominantly single-byte (Code Page 1252 / ASCII).
   * Default stream encoding should remain `latin1` for core CPCL commands to guarantee 1:1 byte preservation.
2. **UTF-8 in CPCL**:
   * Link-OS printers support UTF-8 when enabled via `! U1 setvar "device.languages" "zpl"` / `ENCODING UTF-8` with scalable TrueType fonts (e.g. `Swiss721`).
   * For non-Link-OS and legacy CPCL printers, native UTF-8 is unsupported.
3. **Flutter-Rendered Monochrome Bitmaps (Recommended Strategy)**:
   * The current `renderedText()` mechanism using Flutter canvas rasterization + 1-bit monochrome bitmap output (`CG` / `EG`) is the most reliable, universal mechanism across all printer models and firmware versions for complex scripts (Khmer, Thai, Arabic, CJK, etc.).
