import 'package:flutter/material.dart';

class ThemedPopupMenu extends StatelessWidget {
  final Widget child;
  final List<ThemedPopupMenuItem> items;

  const ThemedPopupMenu({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemedPopupMenuItem>(
      child: child,
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<ThemedPopupMenuItem>(
          value: item,
          child: Row(
            children: [
              Icon(
                item.icon,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (item) {
        item.onTap?.call();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Theme.of(context).cardColor,
      elevation: 8,
      offset: const Offset(0, 8),
    );
  }
}

class ThemedPopupMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const ThemedPopupMenuItem({
    required this.label,
    required this.icon,
    this.onTap,
  });
}
