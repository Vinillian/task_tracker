class Logger {
  static void debug(String message) {
    // В продакшне можно заменить на отправку в аналитику или отключить
    if (!const bool.fromEnvironment('dart.vm.product')) {
      print('🔍 DEBUG: $message');
    }
  }

  static void info(String message) {
    print('ℹ️ INFO: $message');
  }

  static void warning(String message) {
    print('⚠️ WARNING: $message');
  }

  static void error(String message, [Object? error]) {
    print('❌ ERROR: $message');
    if (error != null) {
      print('   Details: $error');
    }
  }

  static void success(String message) {
    print('✅ SUCCESS: $message');
  }
}