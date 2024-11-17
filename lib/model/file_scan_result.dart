import 'asset_info.dart';

class FileScanResult {
  final List<AssetInfo> assets;
  final Map<String, String> errors;

  FileScanResult({
    required this.assets,
    required this.errors,
  });
}
