import 'package:freezed_annotation/freezed_annotation.dart';

import 'container.dart';
import 'volume.dart';

part 'volume_configuration.freezed.dart';

@freezed
class VolumeConfiguration with _$VolumeConfiguration {
  const factory VolumeConfiguration({
    required Volume volume,
    required List<Container> attachedContainers,
  }) = _VolumeConfiguration;
}
