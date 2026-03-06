import 'package:flutter/material.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: borderRadius,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: card,
    );
  }
}
