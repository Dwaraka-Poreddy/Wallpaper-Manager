extension BooleanExtensions on bool? {
  /// applies not operator to any bool
  ///
  /// e.g. true.not() returns false
  bool not() {
    if (this != null) {
      return !this!;
    } else {
      return false;
    }
  }
}

extension BoolToIntExtension on bool {
  int toInt() => this ? 1 : 0;
}
