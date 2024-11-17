enum IssueSeverity { error, warning, suggestion }

class AssetIssue {
  final IssueType type;
  final String message;
  final IssueSeverity severity;

  AssetIssue({
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum IssueType {
  largeFile,
  largeDimensions,
  inefficientFormat,
  duplicateContent,
  highResolution,
}
