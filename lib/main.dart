import 'package:finario/screens/expenses_screen.dart';
import 'package:finario/screens/inventory_screen.dart';
import 'package:finario/screens/management_screen.dart';
import 'package:finario/screens/profit_screen.dart';
import 'package:finario/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finario/models/enviroment.dart';
import 'auth/auth_provider.dart';
import 'screens/login_screens.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/maps_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: Environment.fileName );

  await Supabase.initialize(
   url: "${Environment.apiBaseUrl}", 
   anonKey: "${Environment.apiKey}"
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
          '/locals':(context) => MapsScreen(),
        },
      )
    );
  }
}