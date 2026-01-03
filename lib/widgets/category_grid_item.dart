// lib/widgets/category_grid_item.dart
import 'package:flutter/material.dart';
import 'package:catering_app/models/plate.dart';

class CategoryGridItem extends StatelessWidget {
  const CategoryGridItem({
    super.key,
    required this.plate,
    required this.onSelectCategory,
    this.onDelete,
    this.perPlate,
  });

  final Plate plate;
  final void Function() onSelectCategory;
  final void Function()? onDelete;
  final double? perPlate; // sum of all plate-price for meals in this category

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelectCategory,
      splashColor: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                plate.color.withAlpha(140),
                plate.color.withAlpha(230),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                if (perPlate != null)
                  Text(
                    'Rs. ${perPlate!.toStringAsFixed(0)} / plate',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(230),
                        ),
                  ),
              ],
            ),
            if (onDelete != null)
              Positioned(
                top: -4,
                right: -4,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
                  onPressed: onDelete,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
