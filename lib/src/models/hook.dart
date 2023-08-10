import 'package:freezed_annotation/freezed_annotation.dart';

part 'hook.freezed.dart';

@freezed
class Hook with _$Hook {
  static final _parseRegexp = RegExp(r'^(\!)?(.*[^@])(@)?\.(\w+)?$');

  const factory Hook({
    required String unit,
    required String type,
    @Default(false) bool isTemplate,
    @Default(false) bool preHook,
  }) = _Hook;

  factory Hook.parse(String value) {
    final match = _parseRegexp.matchAsPrefix(value);
    if (match == null) {
      throw FormatException(
        'Not a valid hook definition. '
        'Must be in the format: [!]<service>[@].service',
        value,
      );
    }

    return Hook(
      preHook: match[1] != null,
      unit: match[2]!,
      isTemplate: match[3] != null,
      type: match[4]!,
    );
  }

  const Hook._();

  String getUnitName(String volume) =>
      isTemplate ? '$unit@$volume.$type' : '$unit.$type';

  @override
  String toString() => preHook ? '!${getUnitName('')}' : getUnitName('');
}
