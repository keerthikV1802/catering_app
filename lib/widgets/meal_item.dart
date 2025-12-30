// lib/widgets/meal_item.dart
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:catering_app/models/meal.dart';

class MealItem extends StatelessWidget {
  const MealItem({
    super.key,
    required this.meal,
    required this.onSelectMeal,
  });

  final Meal meal;
  final void Function(Meal meal)? onSelectMeal;

  

  

  Widget _buildImage(BuildContext context) {
    // If imageUrl is empty/null, show a local fallback placeholder
    final imageUrl = meal.imageUrl;

    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(51),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fastfood, size: 48, color: Colors.white24),
              const SizedBox(height: 6),
              Text(
                meal.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Try to load network image but gracefully handle errors
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: imageUrl,
        fit: BoxFit.cover,
        imageErrorBuilder: (context, error, stackTrace) {
          // show fallback box when network fails
          return Container(
            height: 200,
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(51),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 40, color: Colors.white24),
                  const SizedBox(height: 6),
                  Text(
                    meal.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
        // optional: show a simple progress indicator while loading (loadingBuilder not provided by FadeInImage)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      child: InkWell(
        onTap: onSelectMeal == null ? null : () => onSelectMeal!(meal),
        child: Stack(
          children: [
            // image or fallback
            _buildImage(context),

            // top-left small price badge (optional)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rs. ${meal.pricePerPlate} / plate',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // bottom overlay with title/traits
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      meal.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        const SizedBox(width: 12),
                        
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
