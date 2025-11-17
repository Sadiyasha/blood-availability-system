import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for the API. For portability we read this from a compile-time
  // environment variable so you can override it at run/build time with
  // --dart-define=BASE_URL=<url>. If not provided, default to localhost.
  // Examples:
  //  flutter run -d chrome --dart-define=BASE_URL=http://localhost:5000/api
  //  flutter build web --dart-define=BASE_URL=https://api.example.com
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:5000/api');

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ============ HEALTH & SYSTEM ============
  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$baseUrl/health');
    final res = await http.get(uri);
    try {
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Invalid response', 'statusCode': res.statusCode};
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final uri = Uri.parse('$baseUrl/stats');
    final res = await http.get(uri);
    try {
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch stats'};
    }
  }

  // ============ AUTHENTICATION ============
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode({'email': email, 'password': password}),
    );
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);
      await prefs.setString('user_data', json.encode(data['user']));
    }
    return data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final res = await http.post(uri, headers: await _headers(), body: json.encode(payload));
    final data = json.decode(res.body);
    if (res.statusCode == 201 && data['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);
      await prefs.setString('user_data', json.encode(data['user']));
    }
    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  // ============ DONORS ============
  Future<Map<String, dynamic>> getDonors({String? bloodGroup, String? city, bool? isAvailable}) async {
    // Backend expects: bloodType, city, available
    var queryParams = <String, String>{};
    if (bloodGroup != null) queryParams['bloodType'] = bloodGroup;
    if (city != null) queryParams['city'] = city;
    if (isAvailable != null) queryParams['available'] = isAvailable.toString();

    final uri = Uri.parse('$baseUrl/donors/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers());
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> searchDonors(Map<String, dynamic> searchParams) async {
  final uri = Uri.parse('$baseUrl/donors/search');
    final res = await http.post(
      uri,
      headers: await _headers(auth: false),
      body: json.encode(searchParams),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getDonorById(int donorId) async {
  final uri = Uri.parse('$baseUrl/donors/$donorId');
    final res = await http.get(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> updateDonorAvailability(int donorId, bool isAvailable) async {
    final uri = Uri.parse('$baseUrl/donors/$donorId/availability');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: json.encode({'is_available': isAvailable}),
    );
    return json.decode(res.body);
  }

  // ============ BLOOD REQUESTS ============
  Future<Map<String, dynamic>> getBloodRequests({String? status, String? urgency, String? bloodGroup}) async {
    var queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (urgency != null) queryParams['urgency'] = urgency;
    if (bloodGroup != null) queryParams['blood_group'] = bloodGroup;

  final uri = Uri.parse('$baseUrl/blood-requests/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> createBloodRequest(Map<String, dynamic> requestData) async {
  // Use trailing slash to avoid 308 redirect issues on web
  final uri = Uri.parse('$baseUrl/blood-requests/');
    final res = await http.post(
      uri,
      headers: await _headers(auth: false),
      body: json.encode(requestData),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getBloodRequestById(int requestId) async {
  final uri = Uri.parse('$baseUrl/blood-requests/$requestId');
    final res = await http.get(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> updateBloodRequestStatus(int requestId, String status) async {
    final uri = Uri.parse('$baseUrl/blood-requests/$requestId/status');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: json.encode({'status': status}),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> deleteBloodRequest(int requestId) async {
    final uri = Uri.parse('$baseUrl/blood-requests/$requestId');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  // ============ NOTIFICATIONS ============
  Future<Map<String, dynamic>> getNotifications({bool? isRead, String? type, int limit = 50}) async {
    var queryParams = <String, String>{'limit': limit.toString()};
    if (isRead != null) queryParams['is_read'] = isRead.toString();
    if (type != null) queryParams['type'] = type;

  final uri = Uri.parse('$baseUrl/notifications/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    final uri = Uri.parse('$baseUrl/notifications/$notificationId/read');
    final res = await http.put(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final uri = Uri.parse('$baseUrl/notifications/mark-all-read');
    final res = await http.put(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
  final uri = Uri.parse('$baseUrl/notifications/$notificationId');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    return json.decode(res.body);
  }

  // ============ BLOOD BANKS ============
  Future<Map<String, dynamic>> getBloodBanks({String? city, String? state, bool? is24x7}) async {
    var queryParams = <String, String>{};
    if (city != null) queryParams['city'] = city;
    if (state != null) queryParams['state'] = state;
    if (is24x7 != null) queryParams['is_24x7'] = is24x7.toString();

    // Use trailing slash to avoid 308 redirect that can break CORS in some browsers
    final uri = Uri.parse('$baseUrl/blood-banks/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers());
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> searchBloodBanks(Map<String, dynamic> searchParams) async {
    final uri = Uri.parse('$baseUrl/blood-banks/search');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode(searchParams),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getBloodBankById(int bankId) async {
    final uri = Uri.parse('$baseUrl/blood-banks/$bankId');
    final res = await http.get(uri, headers: await _headers());
    return json.decode(res.body);
  }

  // ============ SMART MATCH ============
  Future<Map<String, dynamic>> findMatchingDonors({
    required String bloodType,
    required Map<String, double> location,
    double maxDistance = 50,
    String urgency = 'normal',
  }) async {
    // Backend route: /api/smart-match/find-donors (expects bloodType, location, maxDistance, urgency)
    final uri = Uri.parse('$baseUrl/smart-match/find-donors');
    try {
      final res = await http.post(
        uri,
        headers: await _headers(auth: false),
        body: json.encode({
          'bloodType': bloodType,
          'location': location,
          'maxDistance': maxDistance,
          'urgency': urgency,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch matching donors',
          'statusCode': res.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
        'message': 'Failed to fetch, url=$uri'
      };
    }
  }

  Future<Map<String, dynamic>> matchBloodRequest(int requestId) async {
  final uri = Uri.parse('$baseUrl/smart-match/request/$requestId/match');
    try {
      final res = await http.get(uri, headers: await _headers(auth: false));
      return json.decode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }

  // ============ HOSPITALS ============
  Future<Map<String, dynamic>> getHospitals({String? city, String? state, bool? isEmergency}) async {
    var queryParams = <String, String>{};
    if (city != null) queryParams['city'] = city;
    if (state != null) queryParams['state'] = state;
    if (isEmergency != null) queryParams['is_emergency'] = isEmergency.toString();

    final uri = Uri.parse('$baseUrl/hospitals/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers());
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> searchHospitals(Map<String, dynamic> searchParams) async {
    final uri = Uri.parse('$baseUrl/hospitals/search');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode(searchParams),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> getHospitalById(int hospitalId) async {
    final uri = Uri.parse('$baseUrl/hospitals/$hospitalId');
    final res = await http.get(uri, headers: await _headers());
    return json.decode(res.body);
  }

  // ============ CHATBOT ============
  Future<Map<String, dynamic>> chatbotQuery(String query) async {
    final uri = Uri.parse('$baseUrl/chatbot/query');
    try {
      final user = await getCurrentUser();
      final useAuth = user != null;
      final bodyMap = {
        'message': query,
        'userId': user != null ? (user['id'] ?? user['email'] ?? 'guest') : 'guest',
        'user': user
      };

      final res = await http.post(
        uri,
        headers: await _headers(auth: useAuth),
        body: json.encode(bodyMap),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        final fallback = 'Sorry, I\'m having trouble connecting. Please try again.';
        return {
          'success': false,
          'error': 'Chatbot error',
          'message': fallback,
          'response': fallback,
        };
      }
    } catch (e) {
      final fallback = 'Sorry, I\'m currently offline. Please check your connection and try again.';
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
        'message': fallback,
        'response': fallback,
      };
    }
  }

  // ============ GOVERNMENT DATA (IBDMA) ============
  Future<Map<String, dynamic>> getNearbyBloodBanks({
    String? state,
    String? district,
    String? city,
    String? bloodGroup,
  }) async {
    var queryParams = <String, String>{};
    if (state != null) queryParams['state'] = state;
    if (district != null) queryParams['district'] = district;
    if (city != null) queryParams['city'] = city;
    if (bloodGroup != null) queryParams['blood_group'] = bloodGroup;

    final uri = Uri.parse('$baseUrl/ibdma/blood-banks/nearby').replace(queryParameters: queryParams);
    try {
      final res = await http.get(uri, headers: await _headers());
      return json.decode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> getRealtimeBloodAvailability({
    String? location,
    String? bloodGroup,
  }) async {
    var queryParams = <String, String>{};
    if (location != null) queryParams['location'] = location;
    if (bloodGroup != null) queryParams['blood_group'] = bloodGroup;

    final uri = Uri.parse('$baseUrl/ibdma/blood-availability/realtime').replace(queryParameters: queryParams);
    try {
      final res = await http.get(uri, headers: await _headers());
      return json.decode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }

  // ============ MAP / MARKERS ============
  Future<Map<String, dynamic>> getMapMarkers({
    required double latitude,
    required double longitude,
    double maxDistance = 50,
    List<String>? includeTypes,
    String? bloodType,
    int limit = 200,
  }) async {
    final uri = Uri.parse('$baseUrl/map/markers');
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'maxDistance': maxDistance,
      'includeTypes': includeTypes ?? ['donors', 'hospitals', 'bloodBanks'],
      'bloodType': bloodType,
      'limit': limit
    };

    try {
      final res = await http.post(uri, headers: await _headers(), body: json.encode(body)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return json.decode(res.body);
      return {'success': false, 'message': 'Failed to fetch markers', 'statusCode': res.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDirections({
    required Map<String, double> origin,
    required Map<String, double> destination,
  }) async {
    final uri = Uri.parse('$baseUrl/map/directions');
    final body = {'origin': origin, 'destination': destination};

    try {
      final res = await http.post(uri, headers: await _headers(), body: json.encode(body)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return json.decode(res.body);
      return {'success': false, 'message': 'Failed to fetch directions', 'statusCode': res.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNationalStats() async {
    final uri = Uri.parse('$baseUrl/ibdma/stats/national');
    try {
      final res = await http.get(uri, headers: await _headers());
      return json.decode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }
}
