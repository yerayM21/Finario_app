import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  // Definimos las rutas de navegación para cada cuadro
  static const Map<String, Map<String, dynamic>> featureItems = {
    'inventory': {
      'title': 'Gestión de Inventario',
      'icon': Icons.inventory,
      'color': Colors.blue,
      'route': '/inventory'
    },
    'expenses': {
      'title': 'Registro de Gastos/Ingresos',
      'icon': Icons.attach_money,
      'color': Colors.green,
      'route': '/expenses'
    },
    'management': {
      'title': 'Gestión',
      'icon': Icons.settings,
      'color': Colors.orange,
      'route': '/management'
    },
    'profit': {
      'title': 'Profit',
      'icon': Icons.trending_up,
      'color': Colors.purple,
      'route': '/profit'
    },
    'reports': {
      'title': 'Reporte',
      'icon': Icons.assessment,
      'color': Colors.red,
      'route': '/reports'
    },
    'locals':{
      'title':'locals',
      'icon': Icons.map,
      'color': Colors.yellow,
      'route':'/locals'
    },
  };

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.of(context)?.auth;
    final user = auth?.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Principal'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth?.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.email ?? 'Usuario'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // Dos columnas
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: featureItems.entries.map((entry) {
                  return _FeatureCard(
                    title: entry.value['title'] as String, 
                    icon: entry.value['icon'] as IconData, 
                    color: entry.value['color'] as Color, 
                    onTap: () => Navigator.pushNamed(context, 
                    entry.value['route'] as String),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}