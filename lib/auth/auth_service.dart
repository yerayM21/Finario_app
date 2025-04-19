import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_exceptions.dart' as app_exceptions; // Usamos un alias para tus excepciones

class AuthService {
  final SupabaseClient _client; // Definimos la variable de instancia

  // Constructor que recibe el cliente Supabase
  AuthService(SupabaseClient client) : _client = client;

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw app_exceptions.AuthException('Registration failed', 'registration-failed');
      }
    } on AuthException catch (e) { // AuthException de Supabase
      throw _convertSupabaseAuthException(e);
    } catch (e) {
      throw app_exceptions.AuthException('Unknown error occurred', 'unknown-error');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw app_exceptions.AuthException('Login failed', 'login-failed');
      }
    } on AuthException catch (e) {
      throw _convertSupabaseAuthException(e);
    } catch (e) {
      throw app_exceptions.AuthException('Unknown error occurred', 'unknown-error');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // Método privado para convertir excepciones de Supabase
  app_exceptions.AuthException _convertSupabaseAuthException(AuthException e) {
    switch (e.message) {
      case 'User already registered':
        return app_exceptions.EmailAlreadyInUseException();
      case 'Password should be at least 6 characters':
        return app_exceptions.WeakPasswordException();
      case 'Invalid email format':
        return app_exceptions.InvalidEmailException();
      case 'Invalid login credentials':
        return app_exceptions.WrongPasswordException();
      case 'User not found':
        return app_exceptions.UserNotFoundException();
      default:
        return app_exceptions.AuthException(e.message, e.statusCode?.toString() ?? 'unknown');
    }
  }
}