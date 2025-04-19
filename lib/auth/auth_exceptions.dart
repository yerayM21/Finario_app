class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, [this.code = 'unknown']);

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

// Excepciones específicas
class InvalidEmailException extends AuthException {
  InvalidEmailException() : super('Invalid email address', 'invalid-email');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException() : super('Password is too weak', 'weak-password');
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException() : super('Email already in use', 'email-already-in-use');
}

class UserNotFoundException extends AuthException {
  UserNotFoundException() : super('User not found', 'user-not-found');
}

class WrongPasswordException extends AuthException {
  WrongPasswordException() : super('Wrong password', 'wrong-password');
}