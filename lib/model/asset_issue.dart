enum IssueSeverity { error, warning, suggestion }

class IssueType {
  final String message;
  final IssueSeverity severity;

  const IssueType._internal(this.message, this.severity);

  // Pre-defined issue types
  static const largeFile = IssueType._internal(
    'File size exceeds recommended limit',
    IssueSeverity.warning,
  );

  static const largeDimensions = IssueType._internal(
    'Image dimensions are too large',
    IssueSeverity.warning,
  );

  static const inefficientFormat = IssueType._internal(
    'Image format could be more efficient',
    IssueSeverity.suggestion,
  );

  static const duplicateContent = IssueType._internal(
    'Potentially duplicate image content',
    IssueSeverity.warning,
  );

  static const highResolution = IssueType._internal(
    'Resolution higher than needed',
    IssueSeverity.suggestion,
  );

  static const metadataPresent = IssueType._internal(
    'Image contains unnecessary metadata',
    IssueSeverity.suggestion,
  );

  static const uncompressedFormat = IssueType._internal(
    'Using uncompressed format',
    IssueSeverity.suggestion,
  );

  @override
  String toString() => message;

  Map<String, dynamic> toJson() => {
        'message': message,
        'severity': severity.toString(),
      };
}

class AssetIssue {
  final IssueType type;
  final String? details;

  AssetIssue({
    required this.type,
    this.details,
  });

  String get message => details ?? type.message;
  IssueSeverity get severity => type.severity;

  @override
  String toString() => details == null ? message : '$message: $details';

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'details': details,
        'message': message,
      };
}
