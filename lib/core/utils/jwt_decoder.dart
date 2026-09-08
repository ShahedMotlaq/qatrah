import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw const FormatException('Invalid payload');
    }

    return payloadMap;
  }

  static String _decodeBase64(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');
    final rem = output.length % 4;
    if (rem == 2) {
      output += '==';
    } else if (rem == 3) {
      output += '=';
    } else if (rem != 0) {
      throw Exception('Illegal base64 string.');
    }

    return utf8.decode(base64Url.decode(output));
  }
}
