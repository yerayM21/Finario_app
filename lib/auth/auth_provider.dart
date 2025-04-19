import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends InheritedWidget {
  final AuthService auth;
  final SupabaseClient client;

  AuthProvider({Key? key, required Widget child})
      : auth = AuthService(Supabase.instance.client),
        client = Supabase.instance.client,
        super(key: key, child: child);

  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) => false;
}