// coverage:ignore-file

import 'package:freezed_annotation/freezed_annotation.dart';

part 'volume.freezed.dart';
part 'volume.g.dart';

@freezed
sealed class Volume with _$Volume {
  const factory({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Labels') required Map<String, String> labels,
  }) = _Volume;

  factory fromJson(Map<String, dynamic> json) => _$VolumeFromJson(json);

  static List<Volume> fromJsonList(List<dynamic> json) => json
      .map((dynamic e) => Volume.fromJson(e as Map<String, dynamic>))
      .toList();
}
