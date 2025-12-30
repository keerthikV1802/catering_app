import 'package:catering_app/screens/filters.dart';
import 'package:catering_app/screens/orders_screen.dart';
import 'package:catering_app/screens/chef_screen.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/data/meals_repository.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/screens/meals.dart';
import 'package:catering_app/screens/categories.dart';
import 'package:catering_app/widgets/main_drawer.dart';

const kInitialFilters = {
  Filter.glutenFree: false,
  Filter.lactoseFree: false,
  Filter.vegetarian: false,
  Filter.vegan: false,
};

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedPageIndex = 0;
  final List<Meal> _favoriteMeals = [];
  Map<Filter, bool> _selectedFilters = kInitialFilters;
  
  // Use Stream for real-time updates
  late Stream<List<Meal>> _mealsStream;

  @override
  void initState() {
    super.initState();
    _mealsStream = MealsRepository.instance.watchMeals();
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _toggleMealFavoriteStatus(Meal meal) {
    final isExisting = _favoriteMeals.contains(meal);

    if (isExisting) {
      setState(() {
        _favoriteMeals.remove(meal);
      });
      _showInfoMessage('Meal is no longer a favorite.');
    } else {
      setState(() {
        _favoriteMeals.add(meal);
        _showInfoMessage('Marked as a favorite!');
      });
    }
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void _setScreen(String identifier) async {
    Navigator.of(context).pop(); // close drawer first

    if (identifier == 'meals') {
      // go to Categories tab - meals auto-update via stream
      setState(() {
        _selectedPageIndex = 0;
      });
      return;
    }

    if (identifier == 'orders') {
      Navigator.of(context).pushNamed(OrdersScreen.routeName);
      return;
    }

    if (identifier == 'chef') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ChefScreen(),
        ),
      );
      return;
    }

    if (identifier == 'filters') {
      final result = await Navigator.of(context).push<Map<Filter, bool>>(
        MaterialPageRoute(
          builder: (ctx) => FiltersScreen(
            currentFilters: _selectedFilters,
          ),
        ),
      );

      setState(() {
        _selectedFilters = result ?? kInitialFilters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Meal>>(
      stream: _mealsStream,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Plates'),
            ),
            drawer: MainDrawer(
              onSelectScreen: _setScreen,
            ),
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar: BottomNavigationBar(
              onTap: _selectPage,
              currentIndex: _selectedPageIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.set_meal),
                  label: 'Plates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star),
                  label: 'Favorites',
                ),
              ],
            ),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            drawer: MainDrawer(
              onSelectScreen: _setScreen,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading meals: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _mealsStream = MealsRepository.instance.watchMeals();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              onTap: _selectPage,
              currentIndex: _selectedPageIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.set_meal),
                  label: 'Plates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star),
                  label: 'Favorites',
                ),
              ],
            ),
          );
        }

        // Get meals from snapshot
        final allMeals = snapshot.data ?? [];

        // Apply filters to loaded meals
        final availableMeals = allMeals.where((meal) {
          if (_selectedFilters[Filter.glutenFree]! && !meal.isGlutenFree) {
            return false;
          }
          if (_selectedFilters[Filter.lactoseFree]! && !meal.isLactoseFree) {
            return false;
          }
          if (_selectedFilters[Filter.vegetarian]! && !meal.isVegetarian) {
            return false;
          }
          if (_selectedFilters[Filter.vegan]! && !meal.isVegan) {
            return false;
          }
          return true;
        }).toList();

        Widget activePage;
        var activePageTitle = 'Plates';

        if (_selectedPageIndex == 0) {
          activePage = CategoriesScreen(
            onToggleFavorite: _toggleMealFavoriteStatus,
            availableMeals: availableMeals,
          );
        } else {
          activePage = MealsScreen(
            meals: _favoriteMeals,
            onToggleFavorite: _toggleMealFavoriteStatus,
          );
          activePageTitle = 'Your Favorites';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(activePageTitle),
          ),
          drawer: MainDrawer(
            onSelectScreen: _setScreen,
          ),
          body: activePage,
          bottomNavigationBar: BottomNavigationBar(
            onTap: _selectPage,
            currentIndex: _selectedPageIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.set_meal),
                label: 'Plates',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: 'Favorites',
              ),
            ],
          ),
        );
      },
    );
  }
}