import 'package:flutter/material.dart';

class CustomerProductImage extends StatelessWidget {
  const CustomerProductImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Semantics(
        label: semanticLabel ?? '',
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _fallback();
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder();
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F3F8),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE9EDF3),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 26,
          color: Colors.black38,
        ),
      ),
    );
  }
}
