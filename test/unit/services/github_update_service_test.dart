import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pitaka/core/services/github_update_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late GitHubUpdateService service;

  setUp(() {
    mockDio = MockDio();
    service = GitHubUpdateService(dio: mockDio);

    PackageInfo.setMockInitialValues(
      appName: 'pitaka',
      packageName: 'com.example.pitaka',
      version: '0.1.1',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  group('isNewer', () {
    test('treats 1.0.0 as newer than 0.1.1', () {
      expect(service.isNewer('0.1.1', '1.0.0'), isTrue);
    });

    test('treats 0.1.2 as newer than 0.1.1', () {
      expect(service.isNewer('0.1.1', '0.1.2'), isTrue);
    });

    test('treats 0.10.0 as newer than 0.9.0 (multi-digit jump)', () {
      expect(service.isNewer('0.9.0', '0.10.0'), isTrue);
    });

    test('treats 1.10.0 as newer than 1.9.5', () {
      expect(service.isNewer('1.9.5', '1.10.0'), isTrue);
    });

    test('treats higher build number as newer when versions are identical', () {
      expect(service.isNewer('0.1.5+5', '0.1.5+6'), isTrue);
    });

    test('treats leading v prefix correctly', () {
      expect(service.isNewer('0.1.1', 'v0.1.2'), isTrue);
    });

    test('treats identical versions as not newer', () {
      expect(service.isNewer('0.1.2', '0.1.2'), isFalse);
    });

    test('treats identical version and build number as not newer', () {
      expect(service.isNewer('0.1.5+5', '0.1.5+5'), isFalse);
    });

    test('treats an older version as not newer', () {
      expect(service.isNewer('0.1.2', '0.1.1'), isFalse);
    });
  });

  group('checkForUpdate', () {
    test(
      'returns update info when GitHub has a newer version with an APK',
      () async {
        final Map<String, dynamic> fakeResponseData = {
          'tag_name': 'v9.9.9',
          'body': 'Some release notes',
          'assets': <Map<String, dynamic>>[
            {
              'name': 'app-release.apk',
              'browser_download_url': 'https://example.com/app-release.apk',
            },
          ],
        };

        when(() => mockDio.get(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: fakeResponseData,
          ),
        );

        final result = await service.checkForUpdate();

        expect(result, isNotNull);
        expect(result!['latest_version'], '9.9.9');
        expect(result['download_url'], 'https://example.com/app-release.apk');
      },
    );

    test('returns null when the release has no APK asset', () async {
      final fakeResponseData = {
        'tag_name': 'v9.9.9',
        'body': 'Some release notes',
        'assets': <Map<String, dynamic>>[], // no assets at all
      };

      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: fakeResponseData,
        ),
      );

      final result = await service.checkForUpdate();

      expect(result, isNull);
    });

    test('returns null when the request fails', () async {
      // Simulate no internet / GitHub down.
      when(
        () => mockDio.get(any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final result = await service.checkForUpdate();

      expect(result, isNull);
    });
  });
}
