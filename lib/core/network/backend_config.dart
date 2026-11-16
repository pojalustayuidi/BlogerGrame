/// Local backend configuration for the integration phase.
/// With `adb reverse tcp:8085 tcp:8085`, 127.0.0.1 is reachable from Android.
class BackendConfig {
  BackendConfig._();

  static const baseUrl = String.fromEnvironment(
    'BLOGERGRAME_API_URL',
    defaultValue: 'http://127.0.0.1:8085',
  );
}
