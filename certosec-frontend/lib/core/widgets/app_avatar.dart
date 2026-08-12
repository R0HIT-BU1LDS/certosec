import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// AppAvatar renders a circular profile image with a deterministic initials
/// fallback (first + last initial, from [name]).
///
/// When [imageUrl] is absent or fails to load, the initials chip is shown
/// instead, so every student row always has a visual anchor.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
