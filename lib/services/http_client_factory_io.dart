import 'package:http/http.dart' as http;

http.Client createHttpClient() => http.Client();
bool get usesBrowserClient => false;
