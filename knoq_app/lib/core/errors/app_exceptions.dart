class AppExceptions implements Exception {
  final String message;
  final String? code;
  AppExceptions(this.message, [this.code]);

  @override
  String toString() => message;
}

class BleConnectionException extends AppExceptions {
  BleConnectionException([String msg = 'Failed to connect to KnoQ Bat']) : super(msg, 'ble_connection');
}

class BlePermissionException extends AppExceptions {
  BlePermissionException([String msg = 'Bluetooth permissions missing']) : super(msg, 'ble_permission');
}

class SessionSaveException extends AppExceptions {
  SessionSaveException([String msg = 'Failed to save session data']) : super(msg, 'session_save');
}

class AuthException extends AppExceptions {
  AuthException([String msg = 'Authentication failed', String? code]) : super(msg, code ?? 'auth_error');
}

class NetworkException extends AppExceptions {
  NetworkException([String msg = 'Network request failed']) : super(msg, 'network_error');
}
