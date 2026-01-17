import 'dart:io';
import 'package:asset_opt/model/image_info.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/service/native_optimizer.dart';
import 'package:asset_opt/service/svg_optimizer.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Result of attempting to extract image metadata.
class ImageInfoResult {
  /// The extracted image info, if successful.
  final ImageInfo? info;

  /// Error message if the operation failed.
  final String? error;

  /// Creates a successful result.
  ImageInfoResult.success(this.info) : error = null;

  /// Creates a failed result with error message.
  ImageInfoResult.error(this.error) : info = null;

  /// Creates a result for unsupported file types.
  ImageInfoResult.unsupported() : info = null, error = null;

  /// True if an error occurred.
  bool get hasError => error != null;

  /// True if image info was extracted.
  bool get hasInfo => info != null;
}

/// Service for analyzing and optimizing image files.
class ImageService {
  /// Extracts metadata from an image file.
  Future<ImageInfoResult> getImageInfo(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return ImageInfoResult.unsupported();
      }

      return ImageInfoResult.success(ImageInfo(
        width: image.width,
        height: image.height,
        format: image.format.name,
        hasAlpha: image.hasAlpha,
      ));
    } on FileSystemException catch (e) {
      return ImageInfoResult.error('Cannot read file: ${e.message}');
    } on img.ImageException catch (e) {
      return ImageInfoResult.error('Invalid image: $e');
    } catch (e) {
      return ImageInfoResult.error('Failed to analyze: $e');
    }
  }

  /// Optimizes an image file using the given configuration.
  ///
  /// Returns the optimized file, or null if optimization is not supported.
  /// Throws [AssetOptException] on failure.
  Future<File?> optimizeImage(
    File image,
    OptimizationConfig config, {
    bool? hasAlpha,
  }) async {
    try {
      final optimizedPath = '${image.path}.optimized';
      final extension = p.extension(image.path).toLowerCase();

      if (extension == '.svg') {
        return SvgOptimizer().optimize(image, optimizedPath);
      }

      if (extension == '.webp') {
        if (NativeOptimizer.hasCwebp) {
          return NativeOptimizer.toWebp(image, optimizedPath, quality: config.webpQuality);
        }
        throw OptimizationSkippedException('WebP optimization skipped: cwebp not available');
      }

      File? optimizedFile;
      if (config.resize == null) {
        optimizedFile = await _tryNativeOptimization(
          image,
          optimizedPath,
          extension,
          hasAlpha ?? false,
          config,
        );

        if (optimizedFile != null) {
          return optimizedFile;
        }
      }

      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      List<int> optimizedBytes;

      switch (extension) {
        case '.jpg':
        case '.jpeg':
          optimizedBytes = _optimizeJpeg(originalImage, config);
          break;

        case '.png':
          optimizedBytes = _optimizePng(originalImage, config);
          break;

        case '.webp':
          throw OptimizationSkippedException('WebP optimization requires cwebp');

        default:
          throw AssetOptException('Unsupported image type: $extension');
      }

      optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(optimizedBytes);

      return optimizedFile;
    } catch (e) {
      throw AssetOptException('Failed to optimize image ${image.path}: $e');
    }
  }

  Future<File?> _tryNativeOptimization(
    File input,
    String outputPath,
    String extension,
    bool hasAlpha,
    OptimizationConfig config,
  ) async {
    if (extension == '.png' && NativeOptimizer.hasPngquant) {
      return NativeOptimizer.optimizePng(input, outputPath);
    }
    return null;
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
