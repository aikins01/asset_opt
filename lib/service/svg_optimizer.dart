import 'dart:io';
import 'package:xml/xml.dart';

class SvgOptimizer {
  final SvgOptimizeConfig config;

  SvgOptimizer({SvgOptimizeConfig? config})
      : config = config ?? const SvgOptimizeConfig();

  Future<File?> optimize(File input, String outputPath) async {
    try {
      final content = await input.readAsString();
      final optimized = optimizeString(content);

      if (optimized == null || optimized.length >= content.length) {
        return null;
      }

      final output = File(outputPath);
      await output.writeAsString(optimized);
      return output;
    } catch (_) {
      return null;
    }
  }

  String? optimizeString(String svg) {
    try {
      final doc = XmlDocument.parse(svg);
      
      if (config.removeComments) {
        doc.children.removeWhere((n) => n is XmlComment);
      }

      final root = doc.rootElement;

      if (root.name.local.toLowerCase() != 'svg') {
        return null;
      }

      _processNode(root);

      final result = doc.toXmlString(pretty: false);
      return result.length < svg.length ? result : null;
    } catch (_) {
      return null;
    }
  }

  void _processNode(XmlElement element) {
    if (config.removeComments) {
      element.children.removeWhere((n) => n is XmlComment);
    }

    if (config.removeMetadata) {
      element.children.removeWhere((n) =>
          n is XmlElement && _metadataElements.contains(n.name.local.toLowerCase()));
    }

    if (config.removeHiddenElements) {
      element.children.removeWhere((n) =>
          n is XmlElement && _isHidden(n));
    }

    if (config.removeEmptyContainers) {
      element.children.removeWhere((n) =>
          n is XmlElement &&
          _containerElements.contains(n.name.local.toLowerCase()) &&
          n.children.whereType<XmlElement>().isEmpty);
    }

    if (config.removeEditorData) {
      _removeEditorAttributes(element);
    }

    if (config.removeEmptyAttributes) {
      element.attributes.removeWhere((a) => a.value.isEmpty);
    }

    if (config.removeDefaultValues) {
      _removeDefaultAttributes(element);
    }

    if (config.shortenNumbers) {
      _shortenNumericAttributes(element);
    }

    if (config.removeWhitespace) {
      element.children.removeWhere((n) =>
          n is XmlText && n.value.trim().isEmpty);
    }

    for (final child in element.children.whereType<XmlElement>()) {
      _processNode(child);
    }
  }

  void _removeEditorAttributes(XmlElement element) {
    element.attributes.removeWhere((attr) {
      final name = attr.name.toString();
      final prefix = attr.name.prefix;

      if (_editorPrefixes.contains(prefix)) return true;
      if (name.startsWith('data-')) return true;
      if (name.startsWith('xmlns:') && _editorPrefixes.contains(name.substring(6))) {
        return true;
      }

      if (name == 'id' && _isGeneratedId(attr.value)) return true;

      return false;
    });
  }

  void _removeDefaultAttributes(XmlElement element) {
    final tag = element.name.local.toLowerCase();
    final defaults = _defaultValues[tag] ?? {};

    element.attributes.removeWhere((attr) {
      final name = attr.name.local;
      return defaults[name] == attr.value;
    });
  }

  void _shortenNumericAttributes(XmlElement element) {
    for (final attr in element.attributes) {
      if (_numericAttributes.contains(attr.name.local)) {
        final shortened = _shortenNumber(attr.value);
        if (shortened != attr.value) {
          element.setAttribute(attr.name.toString(), shortened);
        }
      }
    }
  }

  String _shortenNumber(String value) {
    final match = RegExp(r'^(-?\d*\.?\d+)(px|pt|em|rem|%)?$').firstMatch(value.trim());
    if (match == null) return value;

    final num = double.tryParse(match.group(1)!);
    if (num == null) return value;

    final unit = match.group(2) ?? '';
    
    if (num == num.truncateToDouble()) {
      return '${num.toInt()}$unit';
    }

    var str = num.toStringAsFixed(config.precision);
    str = str.replaceFirst(RegExp(r'\.?0+$'), '');
    
    if (str.startsWith('0.')) str = str.substring(1);
    if (str.startsWith('-0.')) str = '-${str.substring(2)}';
    
    return '$str$unit';
  }

  bool _isHidden(XmlElement element) {
    final display = element.getAttribute('display');
    final visibility = element.getAttribute('visibility');
    final opacity = element.getAttribute('opacity');

    if (display == 'none') return true;
    if (visibility == 'hidden') return true;
    if (opacity == '0') return true;

    return false;
  }

  bool _isGeneratedId(String id) {
    return RegExp(r'^(Layer_|SVGID_|_x|path|rect|circle|ellipse|line|polyline|polygon|g|use|image|text|tspan)\d').hasMatch(id) ||
           RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}').hasMatch(id);
  }

  static const _metadataElements = {
    'metadata',
    'title',
    'desc',
    'sodipodi:namedview',
  };

  static const _containerElements = {
    'g',
    'defs',
    'symbol',
    'clippath',
    'mask',
    'pattern',
    'marker',
  };

  static const _editorPrefixes = {
    'inkscape',
    'sodipodi',
    'sketch',
    'illustrator',
    'serif',
    'vectornator',
  };

  static const _numericAttributes = {
    'x',
    'y',
    'x1',
    'y1',
    'x2',
    'y2',
    'cx',
    'cy',
    'r',
    'rx',
    'ry',
    'width',
    'height',
    'stroke-width',
    'font-size',
    'opacity',
    'fill-opacity',
    'stroke-opacity',
  };

  static const _defaultValues = {
    'svg': {
      'version': '1.1',
      'baseProfile': 'full',
      'preserveAspectRatio': 'xMidYMid meet',
    },
    'path': {
      'fill': 'black',
      'fill-rule': 'nonzero',
      'stroke': 'none',
    },
    'rect': {
      'rx': '0',
      'ry': '0',
    },
    'circle': {
      'fill': 'black',
      'stroke': 'none',
    },
    'line': {
      'fill': 'none',
    },
  };
}

class SvgOptimizeConfig {
  final bool removeComments;
  final bool removeMetadata;
  final bool removeEditorData;
  final bool removeEmptyAttributes;
  final bool removeDefaultValues;
  final bool removeEmptyContainers;
  final bool removeHiddenElements;
  final bool removeWhitespace;
  final bool shortenNumbers;
  final int precision;

  const SvgOptimizeConfig({
    this.removeComments = true,
    this.removeMetadata = true,
    this.removeEditorData = true,
    this.removeEmptyAttributes = true,
    this.removeDefaultValues = true,
    this.removeEmptyContainers = true,
    this.removeHiddenElements = true,
    this.removeWhitespace = true,
    this.shortenNumbers = true,
    this.precision = 3,
  });
}
