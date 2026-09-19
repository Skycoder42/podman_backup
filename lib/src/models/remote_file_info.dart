import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_file_info.freezed.dart';

@freezed
sealed class const RemoteFileInfo._() with _$RemoteFileInfo {
  const factory({
    required String fileName,
    required int sizeInBytes,
    required String volume,
    required DateTime backupDate,
  }) = _RemoteFileInfo;
}
