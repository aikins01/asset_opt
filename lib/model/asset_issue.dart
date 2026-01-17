/// Severity level of an optimization issue.
enum IssueSeverity {
  /// Critical issue that should be fixed.
  error,

  /// Important issue that may impact performance.
  warning,

  /// Optional improvement suggestion.
  suggestion,
}

/// Types of optimization issues that can be detected.
class IssueType {
  final String message;
  final String recommendation;
  final IssueSeverity severity;

  const IssueType._internal(
    this.message,
    this.recommendation,
    this.severity,
  );

  static const largeFile = IssueType._internal(
    'File size exceeds recommended limit',
    'Recommended size: < {maxSize}. Current: {currentSize}\n'
        '    → Use compression tools\n'
        '    → Consider WebP format (~30% smaller)\n'
        '    → Resize if dimensions are large',
    IssueSeverity.warning,
  );

  static const largeDimensions = IssueType._internal(
    'Image dimensions are too large',
    'Current: {width}x{height}\n'
        '    → Recommended max: {maxWidth}x{maxHeight}\n'
        '    → Resize based on actual usage\n'
        '    → Use resolution-specific assets',
    IssueSeverity.warning,
  );

  static const inefficientFormat = IssueType._internal(
    'Image format could be more efficient',
    'Current format: {format}\n'
        '    → Convert to {recommendedFormat}\n'
        '    → Estimated savings: {savingsPercent}%\n'
        '    → {reason}',
    IssueSeverity.suggestion,
  );

  static const duplicateContent = IssueType._internal(
    'Potentially duplicate image content',
    'Similar to: {similarFiles}\n'
        '    → Consider using a single asset\n'
        '    → Potential savings: {potentialSavings}\n'
        '    → Check asset usage in code',
    IssueSeverity.warning,
  );

  static const highResolution = IssueType._internal(
    'Resolution higher than needed',
    'Current DPI: {dpi}\n'
        '    → Recommended: {recommendedDpi} DPI\n'
        '    → Potential size reduction: {reduction}%\n'
        '    → Check device requirements',
    IssueSeverity.suggestion,
  );

  static const metadataPresent = IssueType._internal(
    'Image contains unnecessary metadata',
    'Metadata size: {metadataSize}\n'
        '    → Strip unnecessary metadata\n'
        '    → Keep only essential EXIF data\n'
        '    → Potential savings: {savingsSize}',
    IssueSeverity.suggestion,
  );

  static const uncompressedFormat = IssueType._internal(
    'Using uncompressed format',
    'Current format: {format}\n'
        '    → Convert to {recommendedFormat}\n'
        '    → Use compression level: {compressionLevel}\n'
        '    → Expected file size: {expectedSize}',
    IssueSeverity.suggestion,
  );

  @override
  String toString() => message;

  Map<String, dynamic> toJson() => {
        'message': message,
        'recommendation': recommendation,
        'severity': severity.toString(),
      };
}

/// An optimization issue detected for a specific asset.
class AssetIssue {
  /// The type of issue detected.
  final IssueType type;

  /// Additional details about this specific occurrence.
  final String? details;

  /// Template values for the recommendation message.
  final Map<String, String> values;

  /// Creates an asset issue.
  AssetIssue({
    required this.type,
    this.details,
    Map<String, String>? values,
  }) : values = values ?? {};

  /// Human-readable issue message.
  String get message => details ?? type.message;

  /// The severity of this issue.
  IssueSeverity get severity => type.severity;

  String get formattedRecommendation {
    var recommendation = type.recommendation;
    values.forEach((key, value) {
      recommendation = recommendation.replaceAll('{$key}', value);
    });
    return recommendation;
  }

  @override
  String toString() {
    if (details == null) return '$message\n$formattedRecommendation';
    return '$message: $details\n$formattedRecommendation';
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'details': details,
        'message': message,
        'recommendation': formattedRecommendation,
        'values': values,
      };
}
