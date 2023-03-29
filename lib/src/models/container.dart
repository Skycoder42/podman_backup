// coverage:ignore-file
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'container.freezed.dart';
part 'container.g.dart';

@freezed
class Container with _$Container {
  const factory Container({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Exited') required bool exited,
    @JsonKey(name: 'IsInfra') required bool isInfra,
    @JsonKey(name: 'Names') required List<String> names,
    @JsonKey(name: 'Labels') required Map<String, String> labels,
    @JsonKey(name: 'Pod') required String pod,
    @JsonKey(name: 'PodName') required String podName,
  }) = _Container;

  factory Container.fromJson(Map<String, dynamic> json) =>
      _$ContainerFromJson(json);

  static List<Container> fromJsonList(List<dynamic> json) => json
      .map((dynamic e) => Container.fromJson(e as Map<String, dynamic>))
      .toList();
}
