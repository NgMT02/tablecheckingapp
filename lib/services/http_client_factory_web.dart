import 'package:http/browser_client.dart' as browser_http;
import 'package:http/http.dart' as http;

http.Client createHttpClient() {
  final client = browser_http.BrowserClient();
  client.withCredentials = true;
  return client;
}

bool get usesBrowserClient => true;
