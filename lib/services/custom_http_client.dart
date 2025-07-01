import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class CustomHttpClient {
  static http.Client create() {
    final ioc = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }
}
 