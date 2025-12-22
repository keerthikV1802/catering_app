// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:catering_app/screens/tabs.dart';
import 'package:catering_app/screens/orders_screen.dart';
import 'package:catering_app/screens/cart_screen.dart';
import 'package:catering_app/screens/edit_meals_screen.dart';
import 'package:catering_app/screens/OrderPlacementScreen.dart';
import 'package:catering_app/screens/manager/manager_calendar_screen.dart';

import 'package:catering_app/bloc/cart/cart_bloc.dart';
import 'package:catering_app/models/meal.dart';

// 🔥 REQUIRED for Firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 131, 57, 0),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CartBloc()),
        // Add more blocs later if needed
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Catering App',
        theme: theme,
        home: const TabsScreen(),

        /// Routes WITHOUT arguments
        routes: {
          OrdersScreen.routeName: (ctx) => const ManagerCalendarScreen(),
          CartScreen.routeName: (ctx) => const CartScreen(),
        },

        /// Routes WITH arguments
        onGenerateRoute: (settings) {
          if (settings.name == EditMealsScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;

            if (args != null &&
                args['categoryTitle'] != null &&
                args['meals'] != null) {
              return MaterialPageRoute(
                builder: (ctx) => EditMealsScreen(
                  categoryTitle: args['categoryTitle'],
                  meals: args['meals'] as List<Meal>,
                ),
              );
            }

            return _errorRoute('Invalid args for EditMealsScreen');
          }

          if (settings.name == OrderPlacementScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;

            if (args != null &&
                args['categoryTitle'] != null &&
                args['meals'] != null) {
              return MaterialPageRoute(
                builder: (ctx) => OrderPlacementScreen(
                  categoryTitle: args['categoryTitle'],
                  meals: args['meals'] as List<Meal>,
                ),
              );
            }

            return _errorRoute('Invalid args for OrderPlacementScreen');
          }

          return null;
        },
      ),
    );
  }

  /// Simple reusable error route
  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}
