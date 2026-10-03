import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches a one-line summary like `☀️ Sunny +18°C`, or `null` on failure.
  Future<String?> fetchSummary({
    required String server,
    required String zone,
    required bool fahrenheit,
  }) async {
    try {
      final unit = fahrenheit ? '&u' : '';
      final response =
          await _client.get(Uri.parse('$server/$zone?format=%c+%C+%t$unit'));
      if (response.statusCode == 200) return response.body;
    } catch (_) {
      // Keep existing weather on error
    }
    return null;
  }

  void dispose() => _client.close();
}
