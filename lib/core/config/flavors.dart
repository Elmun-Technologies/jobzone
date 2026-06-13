import 'env.dart';

enum Flavor { dev, prod }

class FlavorConfig {
  const FlavorConfig._();

  static Flavor get current => Env.flavor == 'prod' ? Flavor.prod : Flavor.dev;

  static bool get isProd => current == Flavor.prod;
  static bool get isDev => current == Flavor.dev;

  static String get appTitle => isProd ? 'Jobzone' : 'Jobzone (dev)';
}
