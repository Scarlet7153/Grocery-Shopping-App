import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/shipper_theme.dart';
import '../../../../core/utils/app_localizations.dart';

class _PreparedImageData {
  final Uint8List bytes;
  final Size size;

  const _PreparedImageData({required this.bytes, required this.size});
}

Uint8List _cropAndEncodeInBackground(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final cropX = args['cropX'] as int;
  final cropY = args['cropY'] as int;
  final cropW = args['cropW'] as int;
  final cropH = args['cropH'] as int;
  final outputSize = args['outputSize'] as int?;
  final jpegQuality = args['jpegQuality'] as int;

  final originalImage = img.decodeImage(bytes);
  if (originalImage == null) {
    throw Exception('Cannot decode image');
  }

  final cropped = img.copyCrop(
    originalImage,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );

  final outputImage = (outputSize != null && outputSize > 0)
      ? img.copyResize(
          cropped,
          width: outputSize,
          height: outputSize,
          interpolation: img.Interpolation.linear,
        )
      : cropped;

  final encoded = img.encodeJpg(outputImage, quality: jpegQuality);

  return Uint8List.fromList(encoded);
}

class AvatarCropper extends StatefulWidget {
  final XFile image;
  final Uint8List? imageBytes;
  final ValueChanged<Uint8List> onConfirm;
  final VoidCallback onCancel;
  final int? outputSize;
  final int jpegQuality;

  const AvatarCropper({
    super.key,
    required this.image,
    this.imageBytes,
    required this.onConfirm,
    required this.onCancel,
    this.outputSize = 800,
    this.jpegQuality = 82,
  });

  @override
  State<AvatarCropper> createState() => _AvatarCropperState();
}

class _AvatarCropperState extends State<AvatarCropper> {
  static const double _cropSize = 280.0;
  static const double _maxRelativeScale = 8.0;

  double _scale = 1.0;
  double _minScale = 1.0;
  double _startScale = 1.0;
  Offset _offset = Offset.zero;
  Uint8List? _imageBytes;
  Size _baseImageSize = const Size(_cropSize, _cropSize);
  Size? _originalImageSize;
  bool _isProcessing = false;

  double get _maxScale => math.max(_minScale, _minScale * _maxRelativeScale);
  int get _zoomPercent => ((_scale / _minScale) * 100).round();
  int get _maxProcessingDimension => kIsWeb ? 1024 : 1600;

  String _tr(String vi, String en) {
    final l = AppLocalizations.of(context) ??
        AppLocalizations(Localizations.localeOf(context));
    return l.byLocale(vi: vi, en: en);
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final sourceBytes = widget.imageBytes ?? await widget.image.readAsBytes();
    final preparedImage = await _prepareImageForCropping(sourceBytes);

    if (!mounted) return;

    setState(() {
      _imageBytes = preparedImage.bytes;
      _originalImageSize = preparedImage.size;
      _baseImageSize = _calculateBaseImageSize(
        preparedImage.size.width,
        preparedImage.size.height,
      );
      _minScale = _calculateInitialScale(_baseImageSize);
      _scale = _minScale;
      _offset = Offset.zero;
    });
  }

  Future<_PreparedImageData> _prepareImageForCropping(Uint8List sourceBytes) async {
    final imageSize = await _readImageSize(sourceBytes);
    if (imageSize == null) {
      final decoded = img.decodeImage(sourceBytes);
      if (decoded == null) {
        throw Exception('Không thể đọc ảnh');
      }
      return _PreparedImageData(
        bytes: sourceBytes,
        size: Size(decoded.width.toDouble(), decoded.height.toDouble()),
      );
    }

    final longestSide = math.max(imageSize.width, imageSize.height);
    if (longestSide <= _maxProcessingDimension) {
      return _PreparedImageData(bytes: sourceBytes, size: imageSize);
    }

    final scale = _maxProcessingDimension / longestSide;
    final targetWidth = (imageSize.width * scale).round();
    final targetHeight = (imageSize.height * scale).round();

    final codec = await ui.instantiateImageCodec(
      sourceBytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();

    final resizedBytes = byteData?.buffer.asUint8List();
    if (resizedBytes == null) {
      return _PreparedImageData(bytes: sourceBytes, size: imageSize);
    }

    return _PreparedImageData(
      bytes: resizedBytes,
      size: Size(targetWidth.toDouble(), targetHeight.toDouble()),
    );
  }

  Future<Size?> _readImageSize(Uint8List bytes) async {
    try {
      final completer = Completer<Size>();
      ui.decodeImageFromList(bytes, (ui.Image image) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(image.width.toDouble(), image.height.toDouble()),
          );
        }
        image.dispose();
      });
      return completer.future;
    } catch (_) {
      return null;
    }
  }

  double _calculateInitialScale(Size baseImageSize) {
    final widthFactor = _cropSize / baseImageSize.width;
    final heightFactor = _cropSize / baseImageSize.height;
    return math.max(widthFactor, heightFactor);
  }

  Size _calculateBaseImageSize(double imageWidth, double imageHeight) {
    final widthScale = _cropSize / imageWidth;
    final heightScale = _cropSize / imageHeight;
    final fitScale = math.min(widthScale, heightScale);

    return Size(imageWidth * fitScale, imageHeight * fitScale);
  }

  Offset _clampOffset(Offset value, double scale) {
    final displayedWidth = _baseImageSize.width * scale;
    final displayedHeight = _baseImageSize.height * scale;
    final maxDx = math.max(0.0, (displayedWidth - _cropSize) / 2);
    final maxDy = math.max(0.0, (displayedHeight - _cropSize) / 2);

    return Offset(
      value.dx.clamp(-maxDx, maxDx),
      value.dy.clamp(-maxDy, maxDy),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final nextScale =
        (_startScale * details.scale).clamp(_minScale, _maxScale);
    final scaleDelta = nextScale / _scale;
    final focalPoint = details.localFocalPoint;
    const center = Offset(_cropSize / 2, _cropSize / 2);
    final focalOffset = focalPoint - center;

    final scaledOffset = (_offset + focalOffset) * scaleDelta - focalOffset;
    final movedOffset = scaledOffset + details.focalPointDelta;

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(movedOffset, nextScale);
    });
  }

  void _onScroll(PointerScrollEvent event) {
    const divisor = 500.0;
    final scaleFactor = 1.0 - (event.scrollDelta.dy / divisor);
    final nextScale = (_scale * scaleFactor).clamp(_minScale, _maxScale);

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(_offset, nextScale);
    });
  }

  Future<void> _cropAndUpload() async {
    if (_imageBytes == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    // Let loading state render before heavy work starts.
    await Future<void>.delayed(Duration.zero);

    try {
      // Crop ảnh sử dụng package image
      final croppedBytes = await _cropImage();

      // Trả về ảnh đã crop
      widget.onConfirm(croppedBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi crop ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<Uint8List> _cropImage() async {
    if (_imageBytes == null || _originalImageSize == null) {
      throw Exception('No image loaded');
    }

    final originalWidth = _originalImageSize!.width.round();
    final originalHeight = _originalImageSize!.height.round();

    final displayedWidth = _baseImageSize.width * _scale;
    final displayedHeight = _baseImageSize.height * _scale;
    final imageLeft = (_cropSize - displayedWidth) / 2 + _offset.dx;
    final imageTop = (_cropSize - displayedHeight) / 2 + _offset.dy;

    final visibleLeft = math.max(0.0, imageLeft);
    final visibleTop = math.max(0.0, imageTop);
    final visibleRight = math.min(_cropSize, imageLeft + displayedWidth);
    final visibleBottom = math.min(_cropSize, imageTop + displayedHeight);

    if (visibleRight <= visibleLeft || visibleBottom <= visibleTop) {
      throw Exception('Ảnh nằm ngoài vùng crop, vui lòng thử lại');
    }

    final srcLeft =
        ((visibleLeft - imageLeft) / displayedWidth) * originalWidth;
    final srcTop =
        ((visibleTop - imageTop) / displayedHeight) * originalHeight;
    final srcRight =
        ((visibleRight - imageLeft) / displayedWidth) * originalWidth;
    final srcBottom =
        ((visibleBottom - imageTop) / displayedHeight) * originalHeight;

    var cropXNum = srcLeft.floor().clamp(0, originalWidth - 1);
    var cropYNum = srcTop.floor().clamp(0, originalHeight - 1);
    final cropX = cropXNum.toInt();
    final cropY = cropYNum.toInt();

    var cropWNum = (srcRight - srcLeft).ceil().clamp(1, originalWidth - cropX);
    var cropHNum =
        (srcBottom - srcTop).ceil().clamp(1, originalHeight - cropY);

    final cropW = cropWNum.toInt();
    final cropH = cropHNum.toInt();

    final side = math.min(cropW, cropH);
    var finalX = cropX + ((cropW - side) / 2).round();
    var finalY = cropY + ((cropH - side) / 2).round();
    finalX = finalX.clamp(0, originalWidth - side);
    finalY = finalY.clamp(0, originalHeight - side);

    return compute(
      _cropAndEncodeInBackground,
      {
        'bytes': _imageBytes!,
        'cropX': finalX,
        'cropY': finalY,
        'cropW': side,
        'cropH': side,
        'outputSize': widget.outputSize,
        'jpegQuality': widget.jpegQuality,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _tr('Di chuyển và phóng to/thu nhỏ', 'Move and zoom'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _tr('Kéo để di chuyển, pinch để zoom', 'Drag to move, pinch to zoom'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_tr('Zoom', 'Zoom')} $_zoomPercent%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _buildCropArea(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tr('Hủy', 'Cancel'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _imageBytes != null && !_isProcessing
                          ? _cropAndUpload
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShipperTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _tr('Xác nhận', 'Confirm'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    final sourceAspect = _baseImageSize.width / _baseImageSize.height;
    final requestedLongestSide = (_cropSize * _maxScale).round();
    final previewCacheSize = math.min(2048, math.max(1024, requestedLongestSide));

    int? cacheWidth;
    int? cacheHeight;
    if (sourceAspect >= 1) {
      cacheWidth = previewCacheSize;
      cacheHeight = math.max(1, (previewCacheSize / sourceAspect).round());
    } else {
      cacheHeight = previewCacheSize;
      cacheWidth = math.max(1, (previewCacheSize * sourceAspect).round());
    }

    return Center(
      child: Container(
        width: _cropSize,
        height: _cropSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ShipperTheme.primaryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onScroll(event);
              }
            },
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: _imageBytes != null
                  ? Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _scale,
                        child: Image.memory(
                          _imageBytes!,
                          width: _baseImageSize.width,
                          height: _baseImageSize.height,
                          fit: BoxFit.contain,
                          cacheWidth: cacheWidth,
                          cacheHeight: cacheHeight,
                          filterQuality: FilterQuality.low,
                          gaplessPlayback: true,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
