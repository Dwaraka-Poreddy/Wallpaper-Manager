import 'bool_extensions.dart';

extension StringExtensions on String? {
  /// returns whether the string is null or empty
  bool isNullOrEmpty() => this == null || this!.isEmpty;

  /// returns whether the string is neither null nor empty
  bool isNotNullOrEmpty() => isNullOrEmpty().not();

  String orEmpty({String emptyValue = ""}) {
    if (isNullOrEmpty()) {
      return emptyValue;
    } else {
      return this!;
    }
  }
}
