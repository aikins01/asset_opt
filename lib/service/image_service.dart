import 'dart:io';
import 'package:asset_opt/model/image_info.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class ImageService {
  Future<ImageInfo?> getImageInfo(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      return ImageInfo(
        width: image.width,
        height: image.height,
        format: image.format.name,
        hasAlpha: image.hasAlpha,
      );
    } catch (e) {
      throw AssetOptException('Failed to read image ${file.path}: $e');
    }
  }

  Future<File?> optimizeImage(
    File image,
    OptimizationConfig config,
  ) async {
    try {
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      final optimizedPath = '${image.path}.optimized';
      List<int> optimizedBytes;

      final extension = path.extension(image.path).toLowerCase();
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          optimizedBytes = _optimizeJpeg(originalImage, config);
          break;

        case '.png':
          optimizedBytes = _optimizePng(originalImage, config);
          break;

        case '.webp':
          // Use PNG encoding for WebP files since image package
          // doesn't support WebP encoding directly
          optimizedBytes = _optimizePng(originalImage, config);
          break;

        default:
          throw AssetOptException('Unsupported image type: $extension');
      }

      final optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(optimizedBytes);
      return optimizedFile;
    } catch (e) {
      throw AssetOptException('Failed to optimize image ${image.path}: $e');
    }
  }

  List<int> _optimizeJpeg(img.Image image, OptimizationConfig config) {
    if (config.resize != null) {
      image = img.copyResize(
        image,
        width: config.resize!.width,
        height: config.resize!.height,
        interpolation: img.Interpolation.linear,
      );
    }

    return img.encodeJpg(
      image,
      quality: config.jpegQuality,
    );
  }

  List<int> _optimizePng(img.Image image, OptimizationConfig config) {
    if (config.resize != null) {
      image = img.copyResize(
        image,
        width: config.resize!.width,
        height: config.resize!.height,
        interpolation: img.Interpolation.linear,
      );
    }

    return img.encodePng(
      image,
      level: 9, // Maximum compression
    );
  }
}
