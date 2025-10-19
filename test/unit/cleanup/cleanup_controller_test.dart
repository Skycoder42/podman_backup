import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/cleanup/cleanup_controller.dart';
import 'package:podman_backup/src/cleanup/cleanup_filter.dart';
import 'package:podman_backup/src/cleanup/remote_file_proxy.dart';
import 'package:podman_backup/src/models/remote_file_info.dart';
import 'package:test/test.dart';

class MockRemoteFileProxy extends Mock implements RemoteFileProxy {}

class MockCleanupFilter extends Mock implements CleanupFilter {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Stream<RemoteFileInfo>.empty());
  });

  group('$CleanupController', () {
    final mockRemoteFileProxy = MockRemoteFileProxy();
    final mockCleanupFilter = MockCleanupFilter();

    late CleanupController sut;

    setUp(() {
      reset(mockRemoteFileProxy);
      reset(mockCleanupFilter);

      when(
        () => mockRemoteFileProxy.deleteFiles(any(), any()),
      ).thenReturnAsync(null);

      sut = CleanupController(mockRemoteFileProxy, mockCleanupFilter);
    });

    tearDown(() {
      verifyNoMoreInteractions(mockRemoteFileProxy);
      verifyNoMoreInteractions(mockCleanupFilter);
    });

    group('cleanupOldBackups', () {
      const testRemoteHost = 'test-remote-host';

      test('collects files to be deleted and deletes them', () async {
        final remoteFileInfo = RemoteFileInfo(
          fileName: 'test-backup.tar.xz',
          sizeInBytes: 1234,
          volume: 'test-volume',
          backupDate: DateTime.utc(2023, 10, 11, 12, 13, 14, 15, 16),
        );
        final remoteFilesStream = Stream.value(remoteFileInfo);
        final filesToDelete = {remoteFileInfo};
        const minKeep = 3;
        const maxKeep = 10;
        const maxAge = Duration(days: 7);
        const maxBytesTotal = 3411223;

        when(
          () => mockRemoteFileProxy.listRemoteFiles(any()),
        ).thenStream(remoteFilesStream);
        when(
          () => mockCleanupFilter.collectDeletableFiles(
            any(),
            minKeep: any(named: 'minKeep'),
            maxKeep: any(named: 'maxKeep'),
            maxAge: any(named: 'maxAge'),
            maxBytesTotal: any(named: 'maxBytesTotal'),
          ),
        ).thenReturnAsync(filesToDelete);

        await sut.cleanupOldBackups(
          testRemoteHost,
          minKeep: minKeep,
          maxKeep: maxKeep,
          maxAge: maxAge,
          maxBytesTotal: maxBytesTotal,
        );

        verifyInOrder([
          () => mockRemoteFileProxy.listRemoteFiles(testRemoteHost),
          () => mockCleanupFilter.collectDeletableFiles(
            remoteFilesStream,
            minKeep: minKeep,
            maxKeep: maxKeep,
            maxAge: maxAge,
            maxBytesTotal: maxBytesTotal,
          ),
          () => mockRemoteFileProxy.deleteFiles(testRemoteHost, filesToDelete),
        ]);
      });

      test('does not invoke delete if no files are to be deleted', () async {
        const remoteFilesStream = Stream<RemoteFileInfo>.empty();
        const filesToDelete = <RemoteFileInfo>{};

        when(
          () => mockRemoteFileProxy.listRemoteFiles(any()),
        ).thenStream(remoteFilesStream);
        when(
          () => mockCleanupFilter.collectDeletableFiles(
            any(),
            minKeep: any(named: 'minKeep'),
            maxKeep: any(named: 'maxKeep'),
            maxAge: any(named: 'maxAge'),
            maxBytesTotal: any(named: 'maxBytesTotal'),
          ),
        ).thenReturnAsync(filesToDelete);

        await sut.cleanupOldBackups(testRemoteHost);

        verifyInOrder([
          () => mockRemoteFileProxy.listRemoteFiles(testRemoteHost),
          () => mockCleanupFilter.collectDeletableFiles(
            remoteFilesStream,
            minKeep: 1,
          ),
        ]);
      });
    });
  });
}
