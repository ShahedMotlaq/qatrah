import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppIdentityWidget extends StatefulWidget {
  const AppIdentityWidget({
    this.color,
    super.key,
  });

  /// Text color. Defaults to [ColorScheme.onSurfaceVariant] when null.
  final Color? color;

  @override
  State<AppIdentityWidget> createState() => _AppIdentityWidgetState();
}

class _AppIdentityWidgetState extends State<AppIdentityWidget> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      height: 1.8,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'صمم وطور التطبيق بواسطة',
          style: baseStyle,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        Text(
          'محافظة درعا',
          style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        Text(
          '© 2026 محافظة درعا',
          style: baseStyle,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        if (_version.isNotEmpty)
          Text(
            'الإصدار $_version',
            style: baseStyle?.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
      ],
    );
  }
}
