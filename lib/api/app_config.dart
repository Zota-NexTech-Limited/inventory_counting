// Central runtime configuration for the Inventory Counting app.
//
// The backend is the Warehouse Inventory API documented in Inventory_API.pdf.
// The live host returns a standard envelope: {status, message, code, data}.
class AppConfig {
  AppConfig._();

  /// Base URL of the REST API (confirmed live; returns the {status,message,code,data} envelope).
  /// Endpoints from the API sheet are appended to this, e.g. `$apiBaseUrl/auth/login`.
  static const String apiBaseUrl = 'https://everydaycpos.nextechltd.in/api';

  /// Master switch for live data.
  ///
  /// While the backend routes are still being deployed, leave this `false` so
  /// the app runs entirely on the bundled sample data. Flip to `true` (or pass
  /// `--dart-define=USE_LIVE_API=true`) once the documented routes are live.
  static const bool useLiveApi =
      bool.fromEnvironment('USE_LIVE_API', defaultValue: false);

  /// When a live call fails (network error, route not deployed, etc.), fall back
  /// to the bundled sample data instead of surfacing an error. Keeps the app
  /// demoable end-to-end during backend rollout.
  static const bool fallbackToSampleData = true;

  static const Duration requestTimeout = Duration(seconds: 20);
}
