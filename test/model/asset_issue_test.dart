import 'package:test/test.dart';
import 'package:asset_opt/model/asset_issue.dart';

void main() {
  group('IssueType', () {
    test('largeFile has correct properties', () {
      expect(IssueType.largeFile.message, contains('File size'));
      expect(IssueType.largeFile.severity, equals(IssueSeverity.warning));
      expect(IssueType.largeFile.recommendation, contains('compression'));
    });

    test('largeDimensions has correct properties', () {
      expect(IssueType.largeDimensions.message, contains('dimensions'));
      expect(IssueType.largeDimensions.severity, equals(IssueSeverity.warning));
    });

    test('inefficientFormat has correct properties', () {
      expect(IssueType.inefficientFormat.message, contains('format'));
      expect(
        IssueType.inefficientFormat.severity,
        equals(IssueSeverity.suggestion),
      );
    });

    test('toJson serializes correctly', () {
      final json = IssueType.largeFile.toJson();

      expect(json['message'], isNotEmpty);
      expect(json['recommendation'], isNotEmpty);
      expect(json['severity'], contains('warning'));
    });

    test('toString returns message', () {
      expect(IssueType.largeFile.toString(), equals(IssueType.largeFile.message));
    });
  });

  group('AssetIssue', () {
    test('creates instance with required type', () {
      final issue = AssetIssue(type: IssueType.largeFile);

      expect(issue.type, equals(IssueType.largeFile));
      expect(issue.details, isNull);
      expect(issue.values, isEmpty);
    });

    test('creates instance with optional details', () {
      final issue = AssetIssue(
        type: IssueType.largeDimensions,
        details: 'Custom message',
      );

      expect(issue.details, equals('Custom message'));
    });

    test('creates instance with values map', () {
      final issue = AssetIssue(
        type: IssueType.largeFile,
        values: {'maxSize': '1 MB', 'currentSize': '2.5 MB'},
      );

      expect(issue.values['maxSize'], equals('1 MB'));
      expect(issue.values['currentSize'], equals('2.5 MB'));
    });

    group('message', () {
      test('returns details when provided', () {
        final issue = AssetIssue(
          type: IssueType.largeFile,
          details: 'Custom details',
        );

        expect(issue.message, equals('Custom details'));
      });

      test('returns type message when no details', () {
        final issue = AssetIssue(type: IssueType.largeFile);

        expect(issue.message, equals(IssueType.largeFile.message));
      });
    });

    group('severity', () {
      test('returns type severity', () {
        final warning = AssetIssue(type: IssueType.largeFile);
        final suggestion = AssetIssue(type: IssueType.inefficientFormat);

        expect(warning.severity, equals(IssueSeverity.warning));
        expect(suggestion.severity, equals(IssueSeverity.suggestion));
      });
    });

    group('formattedRecommendation', () {
      test('replaces placeholders with values', () {
        final issue = AssetIssue(
          type: IssueType.largeFile,
          values: {'maxSize': '1 MB', 'currentSize': '3.5 MB'},
        );

        final recommendation = issue.formattedRecommendation;

        expect(recommendation, contains('1 MB'));
        expect(recommendation, contains('3.5 MB'));
        expect(recommendation, isNot(contains('{maxSize}')));
        expect(recommendation, isNot(contains('{currentSize}')));
      });

      test('handles largeDimensions placeholders', () {
        final issue = AssetIssue(
          type: IssueType.largeDimensions,
          values: {
            'width': '3000',
            'height': '2500',
            'maxWidth': '2000',
            'maxHeight': '2000',
          },
        );

        final recommendation = issue.formattedRecommendation;

        expect(recommendation, contains('3000'));
        expect(recommendation, contains('2500'));
      });

      test('handles inefficientFormat placeholders', () {
        final issue = AssetIssue(
          type: IssueType.inefficientFormat,
          values: {
            'format': 'PNG',
            'recommendedFormat': 'JPEG',
            'savingsPercent': '60',
            'reason': 'No transparency',
          },
        );

        final recommendation = issue.formattedRecommendation;

        expect(recommendation, contains('PNG'));
        expect(recommendation, contains('JPEG'));
        expect(recommendation, contains('60%'));
      });
    });

    group('toString', () {
      test('includes message and recommendation', () {
        final issue = AssetIssue(
          type: IssueType.largeFile,
          values: {'maxSize': '1 MB', 'currentSize': '2 MB'},
        );

        final str = issue.toString();

        expect(str, contains(IssueType.largeFile.message));
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final issue = AssetIssue(
          type: IssueType.largeDimensions,
          details: 'Test details',
          values: {'width': '5000'},
        );

        final json = issue.toJson();

        expect(json['type'], isNotNull);
        expect(json['details'], equals('Test details'));
        expect(json['message'], equals('Test details'));
        expect(json['values']['width'], equals('5000'));
        expect(json['recommendation'], isNotEmpty);
      });
    });
  });

  group('IssueSeverity', () {
    test('has all expected values', () {
      expect(IssueSeverity.values, contains(IssueSeverity.error));
      expect(IssueSeverity.values, contains(IssueSeverity.warning));
      expect(IssueSeverity.values, contains(IssueSeverity.suggestion));
    });
  });
}
