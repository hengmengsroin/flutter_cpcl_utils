import 'dart:convert';
import 'dart:typed_data';

/// Mutable byte buffer used internally to assemble CPCL output.
class CpclCommandBuffer {
  /// Creates a command buffer using the provided [codec] and [newLine].
  CpclCommandBuffer({required this.codec, required this.newLine});

  /// Character encoding used for text commands.
  final Encoding codec;

  /// Line separator appended after each command.
  final String newLine;
  final BytesBuilder _buffer = BytesBuilder();

  /// Removes all buffered bytes.
  void clear() => _buffer.clear();

  /// Adds a single CPCL command followed by [newLine].
  void addCommand(String command) {
    _buffer.add(codec.encode(command));
    _buffer.add(codec.encode(newLine));
  }

  /// Adds encoded text bytes without appending a newline.
  void addEncodedText(String value) {
    _buffer.add(codec.encode(value));
  }

  /// Adds bytes as-is to the underlying buffer.
  void addRawBytes(List<int> bytes) {
    _buffer.add(bytes);
  }

  /// Returns all currently buffered bytes.
  Uint8List build() => _buffer.toBytes();
}

/// Removes carriage returns and line breaks from user-provided text.
String sanitizeCpclText(String value) =>
    value.replaceAll(RegExp(r'[\r\n]+'), ' ');

/// Formats a numeric CPCL value while trimming unnecessary trailing zeros.
String formatCpclNumber(num value) {
  if (value is int) {
    return value.toString();
  }

  final normalized = value.toStringAsFixed(3);
  return normalized.contains('.')
      ? normalized.replaceFirst(RegExp(r'\.?0+$'), '')
      : normalized;
}

/// Throws a [RangeError] if [value] is outside of `[min, max]`.
void requireRange(int value, int min, int max, String name) {
  if (value < min || value > max) {
    throw RangeError('$name must be between $min and $max. Got: $value');
  }
}

/// Throws an [ArgumentError] if [value] is not strictly positive.
void requirePositive(num value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'Must be greater than 0');
  }
}

/// Throws an [ArgumentError] if [value] is negative.
void requireNonNegative(num value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'Must be 0 or greater');
  }
}
