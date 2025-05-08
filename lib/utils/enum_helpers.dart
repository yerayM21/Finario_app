// utils/enum_helpers.dart (o similar)
T enumFromString<T extends Enum>(String? value, List<T> enumValues, T defaultValue) {
  if (value == null) return defaultValue;
  for (var enumValue in enumValues) {
    if (enumValue.name.toLowerCase() == value.toLowerCase().trim()) {
      return enumValue;
    }
  }
  return defaultValue;
}