import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../utils/platform_utils.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import 'dashboard_screen.dart';
import 'vehicles_screen.dart';
import 'find_shops_screen.dart';
import 'profile_screen.dart';
import 'my_shop_screen.dart';
import 'appointments_screen.dart';
import 'mechanic_appointments_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMechanic = userProvider.currentUser?.userType == UserType.mechanic;

    // Different screens for mechanics vs customers
    final List<Widget> customerScreens = [
      DashboardScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const FindShopsScreen(),
      const AppointmentsScreen(),
      const VehiclesScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> mechanicScreens = [
      DashboardScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const MyShopScreen(),
      const MechanicAppointmentsScreen(),
      const ProfileScreen(),
    ];

    final screens = isMechanic ? mechanicScreens : customerScreens;

    if (PlatformUtils.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: isMechanic ? _getMechanicIOSTabItems() : _getCustomerIOSTabItems(),
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => screens[index],
          );
        },
      );
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: isMechanic ? _getMechanicAndroidDestinations() : _getCustomerAndroidDestinations(),
      ),
    );
  }

  // Customer iOS Tab Items
  List<BottomNavigationBarItem> _getCustomerIOSTabItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.home),
        activeIcon: Icon(CupertinoIcons.house_fill),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.map),
        activeIcon: Icon(CupertinoIcons.map_fill),
        label: 'Find Shops',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.calendar),
        activeIcon: Icon(CupertinoIcons.calendar_badge_plus),
        label: 'Appointments',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.car),
        activeIcon: Icon(CupertinoIcons.car_fill),
        label: 'Vehicles',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        activeIcon: Icon(CupertinoIcons.person_fill),
        label: 'Profile',
      ),
    ];
  }

  // Mechanic iOS Tab Items
  List<BottomNavigationBarItem> _getMechanicIOSTabItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.home),
        activeIcon: Icon(CupertinoIcons.house_fill),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.briefcase),
        activeIcon: Icon(CupertinoIcons.briefcase_fill),
        label: 'My Shop',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.calendar),
        activeIcon: Icon(CupertinoIcons.calendar_badge_plus),
        label: 'Appointments',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        activeIcon: Icon(CupertinoIcons.person_fill),
        label: 'Profile',
      ),
    ];
  }

  // Customer Android Destinations
  List<NavigationDestination> _getCustomerAndroidDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Find Shops',
      ),
      NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note),
        label: 'Appointments',
      ),
      NavigationDestination(
        icon: Icon(Icons.directions_car_outlined),
        selectedIcon: Icon(Icons.directions_car),
        label: 'Vehicles',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  // Mechanic Android Destinations
  List<NavigationDestination> _getMechanicAndroidDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: 'My Shop',
      ),
      NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note),
        label: 'Appointments',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }
}
