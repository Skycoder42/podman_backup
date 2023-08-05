import 'package:freezed_annotation/freezed_annotation.dart';

part 'hook.freezed.dart';

@freezed
class Hook with _$Hook {
  static final _parseRegexp = RegExp(r'^([^=]+)=(\!)?([^@]*)(@)?\.(\w+)?$');

  const factory Hook({
    required String unit,
    required String type,
    @Default(false) bool isTemplate,
    @Default(false) bool preHook,
  }) = _Hook;

  const Hook._();

  String getUnitName(String volume) =>
      isTemplate ? '$unit@$volume.$type' : '$unit.$type';

  static MapEntry<String, Hook> parsePair(String pair) {
    final match = _parseRegexp.matchAsPrefix(pair);
    if (match == null) {
      throw Exception('TODO');
    }

    return MapEntry(
      match[1]!,
      Hook(
        preHook: match[2] != null,
        unit: match[3]!,
        isTemplate: match[4] != null,
        type: match[5]!,
      ),
    );
  }
}
