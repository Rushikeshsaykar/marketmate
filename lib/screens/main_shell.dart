import 'package:flutter/material.dart';
import 'categories_screen.dart';
import 'coming_soon_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = const [
      HomeScreen(),
      CategoriesScreen(),
      ComingSoonScreen(
        title: 'Wishlist',
        icon: Icons.favorite_outline_rounded,
      ),
      ComingSoonScreen(
        title: 'Cart',
        icon: Icons.shopping_bag_outlined,
      ),
      ComingSoonScreen(
        title: 'Account',
        icon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('3'),
              backgroundColor: Color(0xFFC2410C),
              child: Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              label: Text('3'),
              backgroundColor: Color(0xFFC2410C),
              child: Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
