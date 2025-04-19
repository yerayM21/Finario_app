import 'package:finario/screens/expenses_screen.dart';
import 'package:finario/screens/inventory_screen.dart';
import 'package:finario/screens/management_screen.dart';
import 'package:finario/screens/profit_screen.dart';
import 'package:finario/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_provider.dart';
import 'screens/login_screens.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
   url:'https://whammcussaseczrqnngg.supabase.co', 
   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoYW1tY3Vzc2FzZWN6cnFubmdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5NTk0NDgsImV4cCI6MjA1OTUzNTQ0OH0.pf6ZD6QuskWAE7ChOxZLt9nRAvJfGyXSwTIzZcTGnJU'
   );

   runApp(const Finario());
}

class Finario extends StatelessWidget {
  const Finario({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title:'Finario',
        initialRoute: '/login',
        routes: {
          '/login': (context) =>  LoginScreen(),
          '/register': (context) =>  RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/Profile':(context) =>  ProfileScreen(),
          '/inventory': (context) => InventoryScreen(),
          '/expenses': (context) => ExpensesScreen(),
          '/management': (context) => ManagementScreen(),
          '/profit': (context) => ProfitScreen(),
          '/reports': (context) => ReportsScreen(),
        },
      )
    );
  }
}