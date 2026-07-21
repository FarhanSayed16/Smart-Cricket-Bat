enum Environment { dev, staging, prod }

class EnvConfig {
  static Environment currentEnvironment = Environment.dev;

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.prod:
        return 'https://api.knoq.app/v1'; // TODO: Update with real prod API
      case Environment.staging:
        return 'https://api-staging.knoq.app/v1'; 
      case Environment.dev:
        return 'https://g6xrghvh-3000.inc1.devtunnels.ms'; // Physical device dev tunnel API targeting
    }
  }
}
