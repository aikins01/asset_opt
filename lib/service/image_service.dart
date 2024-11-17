import 'dart:io';
import 'package:asset_opt/model/image_info.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:image/image.dart' as img;

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

      // Apply optimizations based on image type
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
          optimizedBytes = _optimizeWebp(originalImage, config);
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
    // Apply JPEG-specific optimizations
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
    // Apply PNG-specific optimizations
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

  List<int> _optimizeWebp(img.Image image, OptimizationConfig config) {
    // Apply WebP-specific optimizations
    if (config.resize != null) {
      image = img.copyResize(
        image,
        width: config.resize!.width,
        height: config.resize!.height,
        interpolation: img.Interpolation.linear,
      );
    }

    return img.encodeWebp(
      image,
      quality: config.webpQuality,
    );
  }
}
