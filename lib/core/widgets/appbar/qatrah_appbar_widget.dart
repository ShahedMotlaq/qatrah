import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';

class QatrahAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const QatrahAppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = true,
    this.elevation = 4.0,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return AppBar(
      bottom: bottom,
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      elevation: elevation,
      shadowColor: theme.shadowColor.withValues(alpha: .2),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
