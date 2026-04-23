// Regenerates Android adaptive + legacy mipmaps and iOS AppIcon PNGs from
// `assets/pngs/app logo.PNG`, trimming near-black margins so the logo fills
// the square canvas (fixes letterboxed black bars on adaptive icons).
//
// Run from project root: dart run tool/generate_launcher_icons.dart

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';

const _sourceAsset = 'assets/pngs/app logo.PNG';

/// Pixels with luminance below this count as "empty" margin (black letterbox).
const _luminanceCutoff = 14;

void main(List<String> args) async {
  final root = Directory.current.path;
  final srcFile = File('$root/$_sourceAsset');
  if (!srcFile.existsSync()) {
    stderr.writeln('Missing ${srcFile.path}');
    exitCode = 1;
    return;
  }

  final src = decodeImage(await srcFile.readAsBytes());
  if (src == null) {
    stderr.writeln('Could not decode source image.');
    exitCode = 1;
    return;
  }

  final square = _cropToContentSquare(src);
  stdout.writeln(
    'Source ${src.width}x${src.height} → square ${square.width}x${square.height}',
  );

  await _writeAndroid(root, square);
  await _writeIos(root, square);
  stdout.writeln('Done.');
}

bool _isBackground(Color c) {
  if (c.a < 20) return true;
  return c.luminance < _luminanceCutoff;
}

Image _cropToContentSquare(Image src) {
  var minX = src.width;
  var minY = src.height;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      if (!_isBackground(src.getPixel(x, y))) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX) {
    return copyResizeCropSquare(src, size: src.width < src.height ? src.width : src.height);
  }

  final bw = maxX - minX + 1;
  final bh = maxY - minY + 1;
  final pad = ((bw > bh ? bw : bh) * 0.02).round();
  minX = (minX - pad).clamp(0, src.width - 1);
  minY = (minY - pad).clamp(0, src.height - 1);
  maxX = (maxX + pad).clamp(0, src.width - 1);
  maxY = (maxY + pad).clamp(0, src.height - 1);

  final w = maxX - minX + 1;
  final h = maxY - minY + 1;
  var side = w > h ? w : h;
  final cx = (minX + maxX) ~/ 2;
  final cy = (minY + maxY) ~/ 2;

  final maxSide = src.width < src.height ? src.width : src.height;
  if (side > maxSide) side = maxSide;

  var x0 = cx - side ~/ 2;
  var y0 = cy - side ~/ 2;
  if (x0 < 0) x0 = 0;
  if (y0 < 0) y0 = 0;
  if (x0 + side > src.width) x0 = src.width - side;
  if (y0 + side > src.height) y0 = src.height - side;

  return copyCrop(src, x: x0, y: y0, width: side, height: side);
}

Future<void> _writePng(String path, Image img) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(encodePng(img));
}

Future<void> _writeAndroid(String root, Image square) async {
  const adaptive = <String, int>{
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
  };
  const mipmaps = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  final res = '$root/android/app/src/main/res';
  for (final e in adaptive.entries) {
    final out = copyResize(
      square,
      width: e.value,
      height: e.value,
      interpolation: Interpolation.average,
    );
    await _writePng('$res/${e.key}/ic_launcher_foreground.png', out);
    await _writePng('$res/${e.key}/ic_launcher_background.png', out);
  }
  for (final e in mipmaps.entries) {
    final out = copyResize(
      square,
      width: e.value,
      height: e.value,
      interpolation: Interpolation.average,
    );
    await _writePng('$res/${e.key}/ic_launcher.png', out);
  }
}

Future<void> _writeIos(String root, Image square) async {
  final jsonPath =
      '$root/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
  final dir = Directory('$root/ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!File(jsonPath).existsSync()) return;

  final map = jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>;
  final images = map['images'] as List<dynamic>;

  for (final raw in images) {
    final e = raw as Map<String, dynamic>;
    final name = e['filename'] as String?;
    final sizeStr = e['size'] as String?;
    final scaleStr = e['scale'] as String?;
    if (name == null || sizeStr == null || scaleStr == null) continue;

    final x = sizeStr.indexOf('x');
    if (x <= 0) continue;
    final base = double.parse(sizeStr.substring(0, x));
    final scale = int.parse(scaleStr.replaceAll('x', ''));
    final px = (base * scale).round();

    final out = copyResize(
      square,
      width: px,
      height: px,
      interpolation: px >= 256 ? Interpolation.average : Interpolation.linear,
    );
    await _writePng('${dir.path}/$name', out);
  }
}
