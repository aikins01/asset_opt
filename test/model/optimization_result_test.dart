import 'package:test/test.dart';
import 'package:asset_opt/model/optimization_result.dart';
import 'package:asset_opt/model/asset_info.dart';

void main() {
  group('OptimizationResult', () {
    late AssetInfo testAsset;

    setUp(() {
      testAsset = AssetInfo(
        name: 'test.jpg',
        path: '/assets/test.jpg',
        size: 10000,
        type: 'jpeg',
        lastModified: DateTime.now(),
      );
    });

    test('creates instance with required fields', () {
      final now = DateTime.now();
      final result = OptimizationResult(
        originalAsset: testAsset,
        optimizedSize: 5000,
        savedBytes: 5000,
        optimizedAt: now,
      );

      expect(result.originalAsset, equals(testAsset));
      expect(result.optimizedSize, equals(5000));
      expect(result.savedBytes, equals(5000));
      expect(result.optimizedAt, equals(now));
    });

    group('savingsPercentage', () {
      test('calculates correct percentage', () {
        final result = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 5000,
          savedBytes: 5000,
          optimizedAt: DateTime.now(),
        );

        expect(result.savingsPercentage, equals(50.0));
      });

      test('handles 0% savings', () {
        final result = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 10000,
          savedBytes: 0,
          optimizedAt: DateTime.now(),
        );

        expect(result.savingsPercentage, equals(0.0));
      });

      test('handles high savings percentage', () {
        final result = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 1000,
          savedBytes: 9000,
          optimizedAt: DateTime.now(),
        );

        expect(result.savingsPercentage, equals(90.0));
      });
    });

    group('assetType', () {
      test('returns original asset type', () {
        final result = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 5000,
          savedBytes: 5000,
          optimizedAt: DateTime.now(),
        );

        expect(result.assetType, equals('jpeg'));
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final optimizedAt = DateTime(2024, 6, 15, 12, 0);
        final result = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 6000,
          savedBytes: 4000,
          optimizedAt: optimizedAt,
        );

        final json = result.toJson();

        expect(json['originalAsset'], isNotNull);
        expect(json['optimizedSize'], equals(6000));
        expect(json['savedBytes'], equals(4000));
        expect(json['optimizedAt'], equals(optimizedAt.toIso8601String()));
        expect(json['savingsPercentage'], equals(40.0));
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'originalAsset': {
            'name': 'photo.png',
            'path': '/images/photo.png',
            'size': 20000,
            'type': 'png',
            'lastModified': '2024-03-01T10:00:00.000',
            'imageInfo': null,
          },
          'optimizedSize': 8000,
          'savedBytes': 12000,
          'optimizedAt': '2024-03-02T14:30:00.000',
        };

        final result = OptimizationResult.fromJson(json);

        expect(result.originalAsset.name, equals('photo.png'));
        expect(result.optimizedSize, equals(8000));
        expect(result.savedBytes, equals(12000));
        expect(result.optimizedAt.year, equals(2024));
        expect(result.savingsPercentage, equals(60.0));
      });

      test('round-trips correctly through toJson/fromJson', () {
        final original = OptimizationResult(
          originalAsset: testAsset,
          optimizedSize: 7500,
          savedBytes: 2500,
          optimizedAt: DateTime(2024, 5, 10, 9, 0),
        );

        final json = original.toJson();
        final restored = OptimizationResult.fromJson(json);

        expect(restored.originalAsset.name, equals(original.originalAsset.name));
        expect(restored.optimizedSize, equals(original.optimizedSize));
        expect(restored.savedBytes, equals(original.savedBytes));
        expect(restored.savingsPercentage, equals(original.savingsPercentage));
      });
    });
  });
}
