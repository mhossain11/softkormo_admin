import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Network image with placeholder, error fallback and optional corner radius.
/// Never loads an image when [url] is empty.
class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.icon = Icons.image_outlined,
    this.memCacheWidth,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? radius;
  final IconData icon;

  /// Limits the decoded size on web (keeps list views light).
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
    );

    Widget image;
    if (url.trim().isEmpty) {
      image = placeholder;
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: scheme.surfaceContainerHighest,
          child: const SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, _, _) => placeholder,
      );
    }

    if (radius == null) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius!), child: image);
  }
}

/// Rounded avatar built on [NetworkImageView]; falls back to initials.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = AppAvatarSize.small,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (url != null && url!.trim().isNotEmpty) {
      return NetworkImageView(
        url: url!,
        width: size,
        height: size,
        radius: AppRadius.pill,
        memCacheWidth: (size * 2).round(),
      );
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : parts.length == 1
            ? parts.first.substring(0, 1).toUpperCase()
            : (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Common avatar sizes.
class AppAvatarSize {
  static const double small = 36;
  static const double medium = 56;
}
