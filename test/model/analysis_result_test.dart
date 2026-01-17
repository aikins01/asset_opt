import 'package:test/test.dart';
import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_detail.dart';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/model/image_info.dart';

void main() {
  AssetDetail createAssetDetail({
    required String name,
    required int size,
    String type = 'png',
    List<AssetIssue>? issues,
    ImageInfo? imageInfo,
  }) {
    return AssetDetail(
      info: AssetInfo(
        name: name,
        path: '/assets/$name',
        size: size,
        type: type,
        lastModified: DateTime.now(),
      ),
      imageInfo: imageInfo,
      issues: issues,
    );
  }

  group('AnalysisResult', () {
    test('creates instance with required fields', () {
      final result = AnalysisResult(
        assets: [],
        scanErrors: {},
        analyzedAt: DateTime.now(),
        projectRoot: '/project',
      );

      expect(result.assets, isEmpty);
      expect(result.scanErrors, isEmpty);
      expect(result.projectRoot, equals('/project'));
    });

    group('getTotalSize', () {
      test('returns sum of all asset sizes', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'a.png', size: 1000),
            createAssetDetail(name: 'b.png', size: 2000),
            createAssetDetail(name: 'c.jpg', size: 3000),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        expect(result.getTotalSize(), equals(6000));
      });

      test('returns 0 for empty assets', () {
        final result = AnalysisResult(
          assets: [],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        expect(result.getTotalSize(), equals(0));
      });
    });

    group('getSizeByType', () {
      test('groups sizes by asset type', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'a.png', size: 1000, type: 'png'),
            createAssetDetail(name: 'b.png', size: 2000, type: 'png'),
            createAssetDetail(name: 'c.jpg', size: 5000, type: 'jpeg'),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        final sizes = result.getSizeByType();

        expect(sizes['png'], equals(3000));
        expect(sizes['jpeg'], equals(5000));
      });
    });

    group('getCountByType', () {
      test('counts assets by type', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'a.png', size: 100, type: 'png'),
            createAssetDetail(name: 'b.png', size: 100, type: 'png'),
            createAssetDetail(name: 'c.jpg', size: 100, type: 'jpeg'),
            createAssetDetail(name: 'd.webp', size: 100, type: 'webp'),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        final counts = result.getCountByType();

        expect(counts['png'], equals(2));
        expect(counts['jpeg'], equals(1));
        expect(counts['webp'], equals(1));
      });
    });

    group('getLargestAssets', () {
      test('returns assets sorted by size descending', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'small.png', size: 100),
            createAssetDetail(name: 'large.png', size: 10000),
            createAssetDetail(name: 'medium.png', size: 1000),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        final largest = result.getLargestAssets(2);

        expect(largest, hasLength(2));
        expect(largest[0].info.name, equals('large.png'));
        expect(largest[1].info.name, equals('medium.png'));
      });

      test('returns all assets when limit exceeds count', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'a.png', size: 100),
            createAssetDetail(name: 'b.png', size: 200),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        final largest = result.getLargestAssets(10);

        expect(largest, hasLength(2));
      });
    });

    group('hasIssues', () {
      test('returns true when assets have issues', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(
              name: 'test.png',
              size: 100,
              issues: [AssetIssue(type: IssueType.largeFile)],
            ),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        expect(result.hasIssues(), isTrue);
      });

      test('returns false when no assets have issues', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(name: 'test.png', size: 100),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        expect(result.hasIssues(), isFalse);
      });
    });

    group('getTotalIssues', () {
      test('counts all issues across all assets', () {
        final result = AnalysisResult(
          assets: [
            createAssetDetail(
              name: 'a.png',
              size: 100,
              issues: [
                AssetIssue(type: IssueType.largeFile),
                AssetIssue(type: IssueType.largeDimensions),
              ],
            ),
            createAssetDetail(
              name: 'b.png',
              size: 100,
              issues: [AssetIssue(type: IssueType.inefficientFormat)],
            ),
          ],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        expect(result.getTotalIssues(), equals(3));
      });
    });

    group('getIssuesByType', () {
      test('groups assets by issue type', () {
        final assetA = createAssetDetail(
          name: 'a.png',
          size: 100,
          issues: [AssetIssue(type: IssueType.largeFile)],
        );
        final assetB = createAssetDetail(
          name: 'b.png',
          size: 100,
          issues: [
            AssetIssue(type: IssueType.largeFile),
            AssetIssue(type: IssueType.inefficientFormat),
          ],
        );

        final result = AnalysisResult(
          assets: [assetA, assetB],
          scanErrors: {},
          analyzedAt: DateTime.now(),
          projectRoot: '/project',
        );

        final byType = result.getIssuesByType();

        expect(byType[IssueType.largeFile], hasLength(2));
        expect(byType[IssueType.inefficientFormat], hasLength(1));
      });
    });
  });
}
