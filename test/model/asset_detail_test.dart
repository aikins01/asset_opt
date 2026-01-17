import 'package:test/test.dart';
import 'package:asset_opt/model/asset_detail.dart';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/model/image_info.dart';

void main() {
  group('AssetDetail', () {
    late AssetInfo testAssetInfo;

    setUp(() {
      testAssetInfo = AssetInfo(
        name: 'test.png',
        path: '/assets/test.png',
        size: 5000,
        type: 'png',
        lastModified: DateTime.now(),
      );
    });

    test('creates instance with required info', () {
      final detail = AssetDetail(info: testAssetInfo);

      expect(detail.info, equals(testAssetInfo));
      expect(detail.imageInfo, isNull);
      expect(detail.issues, isEmpty);
    });

    test('creates instance with imageInfo', () {
      final imageInfo = ImageInfo(
        width: 800,
        height: 600,
        format: 'png',
        hasAlpha: true,
      );

      final detail = AssetDetail(
        info: testAssetInfo,
        imageInfo: imageInfo,
      );

      expect(detail.imageInfo, isNotNull);
      expect(detail.imageInfo!.width, equals(800));
      expect(detail.imageInfo!.height, equals(600));
    });

    test('creates instance with issues', () {
      final issues = [
        AssetIssue(type: IssueType.largeFile),
        AssetIssue(type: IssueType.inefficientFormat),
      ];

      final detail = AssetDetail(
        info: testAssetInfo,
        issues: issues,
      );

      expect(detail.issues, hasLength(2));
      expect(detail.issues[0].type, equals(IssueType.largeFile));
      expect(detail.issues[1].type, equals(IssueType.inefficientFormat));
    });

    test('creates instance with all optional parameters', () {
      final imageInfo = ImageInfo(
        width: 1920,
        height: 1080,
        format: 'png',
        hasAlpha: false,
      );
      final issues = [
        AssetIssue(
          type: IssueType.largeDimensions,
          values: {'width': '1920', 'height': '1080'},
        ),
      ];

      final detail = AssetDetail(
        info: testAssetInfo,
        imageInfo: imageInfo,
        issues: issues,
      );

      expect(detail.info.name, equals('test.png'));
      expect(detail.imageInfo!.width, equals(1920));
      expect(detail.issues, hasLength(1));
    });

    test('issues defaults to empty list when null', () {
      final detail = AssetDetail(
        info: testAssetInfo,
        issues: null,
      );

      expect(detail.issues, isNotNull);
      expect(detail.issues, isEmpty);
    });
  });
}
