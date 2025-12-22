// lib/widgets/meal_item.dart
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:catering_app/models/meal.dart';
import 'package:catering_app/widgets/meal_item_trait.dart';

class MealItem extends StatelessWidget {
  const MealItem({
    super.key,
    required this.meal,
    required this.onSelectMeal,
  });

  final Meal meal;
  final void Function(Meal meal) onSelectMeal;

  String get complexityText =>
      meal.complexity.name[0].toUpperCase() + meal.complexity.name.substring(1);

  String get affordabilityText =>
      meal.affordability.name[0].toUpperCase() +
      meal.affordability.name.substring(1);

  // prefer explicit pricePerPlate if model provides it; otherwise derive
  double get pricePerPlate {
    if ((meal.pricePerPlate ?? 0) > 0) {
      return meal.pricePerPlate!;
    }

    switch (meal.affordability) {
      case Affordability.affordable:
        return 120;
      case Affordability.pricey:
        return 200;
      case Affordability.luxurious:
        return 300;
    }
  }

  Widget _buildImage(BuildContext context) {
    // If imageUrl is empty/null, show a local fallback placeholder
    final imageUrl = meal.imageUrl ?? '';

    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
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
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
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
        onTap: () => onSelectMeal(meal),
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
                  '₹${pricePerPlate.toStringAsFixed(0)} / plate',
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
                        MealItemTrait(
                          icon: Icons.schedule,
                          label: '${meal.duration} min',
                        ),
                        const SizedBox(width: 12),
                        MealItemTrait(
                          icon: Icons.work,
                          label: complexityText,
                        ),
                        const SizedBox(width: 12),
                        MealItemTrait(
                          icon: Icons.attach_money,
                          label: '₹${pricePerPlate.toStringAsFixed(0)}',
                        ),
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
