enum Complexity {
  simple,
  challenging,
  hard,
}

enum Affordability {
  affordable,
  pricey,
  luxurious,
}

class Meal {
  const Meal({
    required this.id,
    required this.categories,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.duration,
    required this.complexity,
    required this.affordability,
    required this.isGlutenFree,
    required this.isLactoseFree,
    required this.isVegan,
    required this.isVegetarian,
    required this.pricePerPlate,
  });

  final String id;
  final List<String> categories;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int duration;
  final Complexity complexity;
  final Affordability affordability;
  final bool isGlutenFree;
  final bool isLactoseFree;
  final bool isVegan;
  final bool isVegetarian;
  final double pricePerPlate;

  // 🔥 Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categories': categories,
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps,
      'duration': duration,
      'complexity': complexity.name,
      'affordability': affordability.name,
      'isGlutenFree': isGlutenFree,
      'isLactoseFree': isLactoseFree,
      'isVegan': isVegan,
      'isVegetarian': isVegetarian,
      'pricePerPlate': pricePerPlate,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      duration: map['duration'] ?? 0,
      complexity: Complexity.values.firstWhere(
        (e) => e.name == map['complexity'],
        orElse: () => Complexity.simple,
      ),
      affordability: Affordability.values.firstWhere(
        (e) => e.name == map['affordability'],
        orElse: () => Affordability.affordable,
      ),
      isGlutenFree: map['isGlutenFree'] ?? false,
      isLactoseFree: map['isLactoseFree'] ?? false,
      isVegan: map['isVegan'] ?? false,
      isVegetarian: map['isVegetarian'] ?? false,
      pricePerPlate: (map['pricePerPlate'] ?? 0).toDouble(),
    );
  }
}
