// File: lib/services/tongue_twister_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TongueTwisterService {
  static const String _apiUrl =
      'https://englishlearningappbackend-production.up.railway.app';

  static Future<List<String>> getTongueTwisters() async {
    try {
      final response = await http
          .get(Uri.parse('$_apiUrl/tongue-twisters'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'The connection has timed out, Please try again!',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> &&
            data.containsKey('tongue_twisters')) {
          return List<String>.from(data['tongue_twisters']);
        } else {
          throw const FormatException('Invalid JSON format from server.');
        }
      } else {
        throw HttpException(
          'Failed to load tongue twisters: ${response.statusCode}',
        );
      }
    } on HttpException catch (e) {
      print('HTTP Error in TongueTwisterService: $e');
      return _getFallbackTwisters();
    } on SocketException catch (e) {
      print('Network Error in TongueTwisterService: $e');
      return _getFallbackTwisters();
    } on FormatException catch (e) {
      print('JSON Format Error in TongueTwisterService: $e');
      return _getFallbackTwisters();
    } on TimeoutException catch (e) {
      print('Timeout Error in TongueTwisterService: $e');
      return _getFallbackTwisters();
    } catch (e) {
      print('An unexpected error occurred in TongueTwisterService: $e');
      return _getFallbackTwisters();
    }
  }

  static List<String> _getFallbackTwisters() {
    return [
      "She sells seashells by the seashore.",
      "Peter Piper picked a peck of pickled peppers.",
      "Red lorry, yellow lorry.",
      "How much wood would a woodchuck chuck if a woodchuck could chuck wood?",
    ];
  }
}
