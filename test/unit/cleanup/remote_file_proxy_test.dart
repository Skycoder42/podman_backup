// ignore_for_file: unnecessary_lambdas

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/sftp_adapter.dart';
import 'package:podman_backup/src/cleanup/remote_file_proxy.dart';
import 'package:podman_backup/src/cleanup/remote_file_transformer.dart';
import 'package:podman_backup/src/models/remote_file_info.dart';
import 'package:test/test.dart';

class MockSftpAdapter extends Mock implements SftpAdapter {}

class MockBatchBuilder extends Mock implements BatchBuilder {}

void main() {
  group('$RemoteFileProxy', () {
    const testRemoteHost = 'test-remote-host';

    final mockSftpAdapter = MockSftpAdapter();
    final mockBatchBuilder = MockBatchBuilder();

    late RemoteFileProxy sut;

    setUp(() {
      reset(mockSftpAdapter);
      reset(mockBatchBuilder);

      when(() => mockSftpAdapter.batch(any())).thenReturn(mockBatchBuilder);
      when(() => mockBatchBuilder.execute()).thenStream(const Stream.empty());

      sut = RemoteFileProxy(mockSftpAdapter, const RemoteFileTransformer());
    });

    tearDown(() {
      verifyNoMoreInteractions(mockSftpAdapter);
      verifyNoMoreInteractions(mockBatchBuilder);
    });

    test('listRemoteFiles invokes ls batch and transforms results', () async {
      const testLine =
          '-rw-r--r-- 1 vscode vscode  1203 Sep  5 2023 '
          'my-backup-file-2023_04_12_10_15_44.tar.xz';
      final listStream = Stream.value(testLine);
      when(() => mockBatchBuilder.execute()).thenStream(listStream);

      final result = sut.listRemoteFiles(testRemoteHost);

      await expectLater(
        result,
        emitsInOrder(<dynamic>[
          RemoteFileInfo(
            fileName: 'my-backup-file-2023_04_12_10_15_44.tar.xz',
            sizeInBytes: 1203,
            volume: 'my-backup-file',
            backupDate: DateTime.utc(2023, 4, 12, 10, 15, 44),
          ),
          emitsDone,
        ]),
      );

      verifyInOrder([
        () => mockSftpAdapter.batch(testRemoteHost),
        () => mockBatchBuilder.ls(withDetails: true, noEcho: true),
        () => mockBatchBuilder.execute(),
      ]);
    });

    test('deleteFiles invokes delete batch for all files', () async {
      final file1 = RemoteFileInfo(
        fileName: 'test-file-1',
        sizeInBytes: 0,
        volume: '',
        backupDate: DateTime(0),
      );
      final file2 = RemoteFileInfo(
        fileName: 'test-file-2',
        sizeInBytes: 0,
        volume: '',
        backupDate: DateTime(0),
      );
      final file3 = RemoteFileInfo(
        fileName: 'test-file-3',
        sizeInBytes: 0,
        volume: '',
        backupDate: DateTime(0),
      );

      await sut.deleteFiles(testRemoteHost, [file1, file2, file3]);

      verifyInOrder([
        () => mockSftpAdapter.batch(testRemoteHost),
        () => mockBatchBuilder.rm(file1.fileName, noEcho: true),
        () => mockBatchBuilder.rm(file2.fileName, noEcho: true),
        () => mockBatchBuilder.rm(file3.fileName, noEcho: true),
        () => mockBatchBuilder.execute(),
      ]);
    });
  });
}
