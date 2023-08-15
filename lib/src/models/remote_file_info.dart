import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_file_info.freezed.dart';

@freezed
class RemoteFileInfo with _$RemoteFileInfo {
  const factory RemoteFileInfo({
    required String fileName,
    required int sizeInBytes,
    required String volume,
    required DateTime backupDate,
  }) = _RemoteFileInfo;

  const RemoteFileInfo._();
}
