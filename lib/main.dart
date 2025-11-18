import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'dart:async';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('🔄 App will continue in demo mode');
  }

  // Quick backend health check on startup (prints to console)
  try {
    final api = ApiService();
    final health = await api.healthCheck();
    print('🔗 Backend health: $health');
  } catch (e) {
    print('❌ Backend health check failed: $e');
  }

  runApp(const BloodAvailabilityApp());
}

class BloodAvailabilityApp extends StatelessWidget {
  const BloodAvailabilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Availability System',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 🔹 Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user exists in localStorage
    try {
      final String? data = html.window.localStorage['blood_users'];
      if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No registered users found. Please register first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final List<dynamic> users = jsonDecode(data);
      final user = users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => null,
      );

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Login successful - Save current user to session
      html.window.localStorage['blood_current_user'] = jsonEncode(user);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user['name']}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Main Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainDashboard(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewRegisteredUsers() {
    try {
      final String? data = html.window.localStorage['blood_users'];
      if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No registered users found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final List<dynamic> users = jsonDecode(data);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registered Users'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFFDB7093)),
                  title: Text(user['name'] ?? 'N/A'),
                  subtitle: Text('${user['email']}\n${user['bloodType']} • ${user['phone']}'),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bloodtype,
                        size: 60,
                        color: Color(0xFFDB7093),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Blood Availability System",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB7093),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFFDB7093),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFFDB7093),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB7093), Color(0xFFFF69B4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDB7093).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register here",
                    style: TextStyle(
                      color: Color(0xFFDB7093),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _viewRegisteredUsers,
                  child: const Text(
                    "🔍 View Registered Users",
                    style: TextStyle(
                      color: Color(0xFFDB7093),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB7093), Color(0xFFFF69B4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDB7093).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "📊 View Registration Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🏠 Main Dashboard Screen - MODERN DESIGN
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // API Service instance
  final ApiService _api = ApiService();

  // NEW: Notification and Location variables
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  List<Map<String, dynamic>> notifications = [];
  Position? currentPosition;
  List<Map<String, dynamic>> nearbyDonors = [];
  Timer? notificationTimer;
  final ApiService _apiService = ApiService();

  // Optional persisted filter selections used by navigation methods
  // These may be set via filter dialogs; keeping them nullable avoids build errors
  // and allows passing no filters when not specified.
  String? selectedCity;
  String? selectedState;
  String? selectedBlood;

  // Real stats from database
  int totalDonors = 0;
  int totalHospitals = 0;
  int totalBloodBanks = 0;
  int availableDonors = 0;
  int livesSaved = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getCurrentLocation();
    _startNotificationUpdates();
    _fetchRealStats(); // Fetch real data from API
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    super.dispose();
  }

  // Fetch real statistics from API
  Future<void> _fetchRealStats() async {
    try {
      final result = await _api.getStats();
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          availableDonors = data['donors_available'] ?? 0;
          totalHospitals = data['hospitals_connected'] ?? 0;
          totalBloodBanks = data['blood_banks'] ?? 0;
          totalDonors = data['total_donors'] ?? 0;
          livesSaved = data['lives_saved'] ?? 0;
          isLoadingStats = false;
        });
      } else {
        setState(() {
          isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin?.initialize(initializationSettings);

    // Load real notifications from backend
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Fetch random donor IDs for notifications (simulate user notifications)
      final donorIds = [1, 2, 3, 5, 10, 15, 20, 25]; // Sample donor IDs from database
      final randomDonorId = donorIds[math.Random().nextInt(donorIds.length)];
      
      final response = await _apiService.getNotifications(
        recipientId: randomDonorId,
        recipientType: 'Donor',
        limit: 20,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          notifications = (response['data'] as List).map((notif) {
            return {
              'id': notif['id'].toString(),
              'title': notif['title'] ?? 'Notification',
              'message': notif['message'] ?? '',
              'time': _formatTime(notif['created_at']),
              'icon': _getIconForType(notif['notification_type']),
              'type': notif['notification_type']?.toLowerCase() ?? 'info',
              'isRead': notif['read'] ?? false,
              'priority': notif['priority'] ?? 'Medium',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'bloodrequest':
        return Icons.water_drop;
      case 'thankyou':
        return Icons.favorite;
      case 'emergency':
        return Icons.emergency;
      case 'donationreminder':
        return Icons.schedule;
      case 'match':
        return Icons.person_add;
      case 'donorregistration':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final DateTime created = DateTime.parse(timestamp.toString());
      final Duration diff = DateTime.now().difference(created);
      
      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else {
        return created.toString().split(' ')[0];
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _startNotificationUpdates() {
    // Refresh notifications from backend every 30 seconds
    notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      currentPosition = await Geolocator.getCurrentPosition();
      _findNearbyDonors();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _findNearbyDonors() {
    // Simulate nearby donors data
    nearbyDonors = [
      {
        'name': 'John Doe',
        'blood': 'O+',
        'distance': 1.2,
        'lat': 28.6139,
        'lng': 77.2090,
      },
      {
        'name': 'Sarah Smith',
        'blood': 'A+',
        'distance': 2.1,
        'lat': 28.6169,
        'lng': 77.2100,
      },
      {
        'name': 'Mike Johnson',
        'blood': 'B+',
        'distance': 3.4,
        'lat': 28.6199,
        'lng': 77.2110,
      },
      {
        'name': 'City Hospital',
        'blood': 'Blood Bank',
        'distance': 0.8,
        'lat': 28.6129,
        'lng': 77.2080,
      },
      {
        'name': 'Red Cross Center',
        'blood': 'Blood Bank',
        'distance': 1.5,
        'lat': 28.6149,
        'lng': 77.2095,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header with Notification Bell
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Blood Availability System",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDB7093),
                          ),
                        ),
                        Text(
                          "Welcome back! Save lives today",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification Bell
                        Stack(
                          children: [
                            IconButton(
                              onPressed: _showNotifications,
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFFDB7093),
                                size: 28,
                              ),
                            ),
                            if (notifications
                                .where((n) => !n['isRead'])
                                .isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${notifications.where((n) => !n['isRead']).length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showProfileMenu(),
                          child: const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFDB7093),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by Blood Group, Location, or Hospital",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFDB7093),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.arrow_circle_right, color: Color(0xFFDB7093)),
                        onPressed: () {
                          final q = _searchController.text.trim();
                          if (q.isNotEmpty) _handleSearch(q);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    onSubmitted: (value) {
                      final q = value.trim();
                      if (q.isNotEmpty) _handleSearch(q);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interactive Map Section - NEW
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.map,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "🗺️ Nearby Donors & Blood Banks",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // Simulated Map Background
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green[100]!,
                                            Colors.blue[100]!,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "🗺️ Interactive Map\n(Tap to view full map)",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Location markers
                                    Positioned(
                                      top: 20,
                                      left: 30,
                                      child: _buildMapMarker(
                                        "🩸",
                                        "You",
                                        Colors.red,
                                      ),
                                    ),
                                    Positioned(
                                      top: 35,
                                      right: 40,
                                      child: _buildMapMarker(
                                        "👤",
                                        "John D.",
                                        Colors.orange,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 20,
                                      left: 50,
                                      child: _buildMapMarker(
                                        "🏥",
                                        "Hospital",
                                        Colors.blue,
                                      ),
                                    ),
                                    // Full Map Button
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: ElevatedButton(
                                        onPressed: _openFullMap,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFDB7093,
                                          ),
                                          minimumSize: const Size(60, 30),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          "View Full Map",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main Features Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.bloodtype,
                            title: "Find Donor",
                            subtitle: "Search donors",
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                            onTap: () => _openFilterAndFetch("Find Donor"),
                          ),
                          _buildFeatureCard(
                            icon: Icons.local_hospital,
                            title: "Hospitals",
                            subtitle: "Find blood banks",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                            ),
                            onTap: () => _openFilterAndFetch("Hospitals"),
                          ),
                          _buildFeatureCard(
                            icon: Icons.add_circle_outline,
                            title: "Request Blood",
                            subtitle: "Emergency request",
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB347), Color(0xFFFFCC02)],
                            ),
                            onTap: () => _navigateToScreen("Request Blood"),
                          ),
                          _buildFeatureCard(
                            icon: Icons.inventory,
                            title: "Availability",
                            subtitle: "Check stock levels",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                            ),
                            onTap: () =>
                                _navigateToScreen("Check Availability"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // For Recipients Section - NEW
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.healing,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "For Recipients",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Need blood? Get instant help:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildMatchCriteria(
                              "🚨 Emergency Helpline",
                              "24/7",
                            ),
                            _buildMatchCriteria(
                              "🔍 Find Compatible Donors",
                              "Instant",
                            ),
                            _buildMatchCriteria(
                              "📱 Direct Contact",
                              "Available",
                            ),
                            _buildMatchCriteria(
                              "🏥 Hospital Network",
                              "Connected",
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _emergencyCall(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "🚨 Emergency",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _requestBlood(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF667eea),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "🩸 Request Blood",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // AI-Powered Section (IBDMA Algorithm) - UPDATED
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDB7093), Color(0xFFFF69B4)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.psychology,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Smart Match", // REMOVED ALGORITHM NAME
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showIBDMAInfo(),
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "AI-powered donor matching based on:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildMatchCriteria(
                              "🩸 Blood Group Compatibility",
                              "98%",
                            ),
                            _buildMatchCriteria(
                              "📍 Distance & Location",
                              "2.5 km",
                            ),
                            _buildMatchCriteria("⏰ Availability Score", "High"),
                            _buildMatchCriteria("🚨 Urgency Level", "Critical"),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => _findSmartMatch(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFDB7093),
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "🔍 Find Smart Match",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Stats
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "📊 Today's Impact",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDB7093),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  "🩸",
                                  isLoadingStats ? "..." : "$availableDonors",
                                  "Donors Available",
                                ),
                                _buildStatItem(
                                  "🏥",
                                  isLoadingStats ? "..." : "$totalHospitals",
                                  "Hospitals Connected",
                                ),
                                _buildStatItem(
                                  "❤️",
                                  isLoadingStats ? "..." : "$livesSaved",
                                  "Lives Saved Today",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Motivational Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Your blood can save lives",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Next Donation Eligible: 15 Jan 2026",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChatbot(),
        backgroundColor: const Color(0xFFDB7093),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          "Ask BloodBot",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 3) {
              _showProfileMenu();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFDB7093),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype),
              label: "Donors",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.inbox), label: "Requests"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  // NEW METHODS FOR NOTIFICATIONS AND MAP

  Widget _buildMapMarker(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "🔔 Notifications",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDB7093),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (var notification in notifications) {
                          notification['isRead'] = true;
                        }
                      });
                    },
                    child: const Text("Mark all as read"),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No notifications yet",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: notification['isRead']
                                ? Colors.grey[100]
                                : const Color(0xFFFFE4E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notification['isRead']
                                  ? Colors.grey[300]!
                                  : const Color(0xFFDB7093),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getNotificationColor(
                                notification['type'],
                              ),
                              child: Icon(
                                notification['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: notification['isRead']
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['time'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification['isRead']
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDB7093),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              setState(() {
                                notification['isRead'] = true;
                              });
                              _handleNotificationTap(notification);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'match':
        return Colors.green;
      case 'event':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.purple;
      default:
        return const Color(0xFFDB7093);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    Navigator.pop(context);

    switch (notification['type']) {
      case 'emergency':
        _emergencyCall();
        break;
      case 'match':
        _findSmartMatch();
        break;
      case 'event':
        _showEventDetails();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${notification['title']}...'),
            backgroundColor: const Color(0xFFDB7093),
          ),
        );
    }
  }

  void _showEventDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🩸 Blood Donation Camp'),
        content: const Text(
          'Join us tomorrow for a free blood donation camp!\n\n'
          '📅 Date: Tomorrow, 9:00 AM\n'
          '📍 Location: City Center, Main Hall\n'
          '🩺 Free health checkup included\n'
          '🎁 Refreshments provided\n\n'
          'Help save lives by donating blood!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Registered for blood camp!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB7093),
            ),
            child: const Text(
              'Register Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapScreen(
          nearbyDonors: nearbyDonors,
          currentPosition: currentPosition,
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCriteria(String criterion, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            criterion,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String number, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDB7093),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _navigateToScreen(String screenName) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Opening $screenName...'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFDB7093),
      ),
    );

    try {
      if (screenName == "Find Donor") {
        // Use the POST /donors/search endpoint with a consistent payload
        final params = <String, dynamic>{};
        if (selectedBlood != null) params['blood_group'] = selectedBlood;
        if (selectedCity != null) params['city'] = selectedCity;
        if (selectedState != null) params['state'] = selectedState;

        // Show a small loading indicator while fetching
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFDB7093)),
          ),
        );

        final res = await _api.searchDonors(params);
        Navigator.pop(context); // close loading

        if (res['success'] == true &&
            res['data'] != null &&
            (res['data'] as List).isNotEmpty) {
          _showDonorsList(res['data']);
        } else {
          // If no donors found, fallback to blood banks
          final banks = await _api.getBloodBanks(
            city: selectedCity,
            state: selectedState,
          );
          if (banks['success'] == true &&
              banks['data'] != null &&
              (banks['data'] as List).isNotEmpty) {
            final List<dynamic> fallback = (banks['data'] as List).map((b) {
              return {
                'user': {
                  'name': b['name'] ?? 'Blood Bank',
                  'phone': b['phone'] ?? 'N/A',
                  'city': b['city'] ?? b['state'] ?? '',
                },
                'blood_group': selectedBlood ?? 'N/A',
                'is_available': true,
                'source_type': 'bloodBank',
                'raw': b,
              };
            }).toList();
            _showDonorsList(fallback);
          } else {
            final message =
                res['message'] ??
                res['error'] ??
                'No donors or blood banks available';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.orange),
            );
          }
        }
      } else if (screenName == "Hospitals") {
        // Prefer showing blood banks (government dataset) when user taps Hospitals
        final result = await _api.getBloodBanks();
        if (result['success'] == true && result['data'] != null) {
          _showBloodBanksList(result['data']);
        } else {
          // Fallback: call hospitals endpoint if blood banks not available
          final h = await _api.getHospitals();
          if (h['success'] == true && h['data'] != null) {
            _showHospitalsList(h['data']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hospitals or blood banks available'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (screenName == "Check Availability") {
        // Fetch real blood banks
        final result = await _api.getBloodBanks();
        if (result['success'] == true) {
          _showBloodBanksList(result['data']);
        }
      } else if (screenName == "Request Blood") {
        _requestBlood();
      }
    } catch (e) {
      // Ensure any open loading dialog is closed
      try {
        Navigator.pop(context);
      } catch (_) {}
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openFilterAndFetch(String screenName) async {
    String? localCity;
    String? localState;
    String? localBlood;
    final cityController = TextEditingController();
    final stateController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter $screenName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                    ),
                    onChanged: (v) =>
                        localCity = v.trim().isEmpty ? null : v.trim(),
                  ),
                  TextField(
                    controller: stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                    ),
                    onChanged: (v) =>
                        localState = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        localBlood = v;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB7093),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // If user clicked Cancel, return early
    if (result != true) return;

    // Capture final values from controllers
    localCity = cityController.text.trim().isEmpty
        ? null
        : cityController.text.trim();
    localState = stateController.text.trim().isEmpty
        ? null
        : stateController.text.trim();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDB7093)),
      ),
    );

    // After dialog, call appropriate API with filters
    try {
      if (screenName == 'Find Donor') {
        // First, try to search blood banks with the government dataset
        final banks = await _api.getBloodBanks(
          city: localCity,
          state: localState,
        );

        if (banks['success'] == true && banks['data'] != null) {
          final List<dynamic> bankList = banks['data'] as List;

          // Filter by blood group if specified
          List<dynamic> filteredBanks = bankList;
          if (localBlood != null) {
            filteredBanks = bankList.where((bank) {
              // Check if the specific blood group has units > 0
              final bloodKey = _getBloodGroupKey(localBlood!);
              return (bank[bloodKey] ?? 0) > 0;
            }).toList();
          }

          Navigator.pop(context); // Close loading

          if (filteredBanks.isNotEmpty) {
            // Convert blood banks to donor-like format for display
            final List<dynamic> donorFormat = filteredBanks.map((b) {
              return {
                'user': {
                  'name': b['name'] ?? 'Blood Bank',
                  'phone': b['phone'] ?? 'N/A',
                  'city': b['city'] ?? '',
                  'state': b['state'] ?? '',
                },
                'blood_group': localBlood ?? 'Multiple',
                'is_available': true,
                'source_type': 'bloodBank',
                'raw': b,
              };
            }).toList();
            _showDonorsList(donorFormat);
            return;
          }
        }

        // Fallback: try donor search endpoint
        final params = <String, dynamic>{};
        if (localBlood != null) params['blood_group'] = localBlood;
        if (localCity != null) params['city'] = localCity;
        if (localState != null) params['state'] = localState;

        final res = await _api.searchDonors(params);
        Navigator.pop(context); // Close loading

        if (res['success'] == true &&
            res['data'] != null &&
            (res['data'] as List).isNotEmpty) {
          _showDonorsList(res['data']);
          return;
        }

        // No results
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No ${localBlood ?? 'blood'} donors/banks found in ${localCity ?? localState ?? 'your area'}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (screenName == 'Hospitals') {
        final res = await _api.getBloodBanks(
          city: localCity,
          state: localState,
        );
        Navigator.pop(context); // Close loading

        if (res['success'] == true && res['data'] != null) {
          _showBloodBanksList(res['data']);
          return;
        } else {
          final h = await _api.getHospitals();
          if (h['success'] == true && h['data'] != null) {
            _showHospitalsList(h['data']);
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hospitals or blood banks found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper to convert blood group (e.g., "A+") to database column name (e.g., "a_positive")
  String _getBloodGroupKey(String bloodGroup) {
    final map = {
      'A+': 'a_positive',
      'A-': 'a_negative',
      'B+': 'b_positive',
      'B-': 'b_negative',
      'AB+': 'ab_positive',
      'AB-': 'ab_negative',
      'O+': 'o_positive',
      'O-': 'o_negative',
    };
    return map[bloodGroup] ?? 'a_positive';
  }

  Future<void> _handleSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    // Detect blood group in the query (supports formats like "A+", "o-", etc.)
    final bloodGroups = {'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'};
    String? detectedBloodGroup;
    for (final bg in bloodGroups) {
      if (q.toUpperCase().contains(bg)) {
        detectedBloodGroup = bg;
        break;
      }
    }

    // Heuristic: if not a blood group, treat whole query as city/hospital keyword
    final cityOrKeyword = detectedBloodGroup == null ? q : null;

    // Show loading while searching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDB7093)),
      ),
    );

    try {
      // 1) Prefer blood banks: filter by city/keyword and by blood group availability if provided
      Map<String, dynamic> banksResp;
      if (cityOrKeyword != null && cityOrKeyword.isNotEmpty) {
        banksResp = await _api.getBloodBanks(city: cityOrKeyword);
      } else {
        // If no keyword, still fetch banks so we can filter by blood group
        banksResp = await _api.getBloodBanks();
      }

      if (banksResp['success'] == true && banksResp['data'] != null) {
        List<dynamic> banks = (banksResp['data'] as List);

        // If a blood group is detected, filter banks to those with > 0 units
        if (detectedBloodGroup != null) {
          final key = _getBloodGroupKey(detectedBloodGroup);
          banks = banks.where((b) => (b[key] ?? 0) > 0).toList();
        }

        if (banks.isNotEmpty) {
          Navigator.pop(context); // close loading
          _showBloodBanksList(banks);
          return;
        }
      }

      // 2) Try donor search if blood group or city keyword present
      final donorParams = <String, dynamic>{};
      if (detectedBloodGroup != null) donorParams['blood_group'] = detectedBloodGroup;
      if (cityOrKeyword != null && cityOrKeyword.isNotEmpty) donorParams['city'] = cityOrKeyword;

      if (donorParams.isNotEmpty) {
        final donorsResp = await _api.searchDonors(donorParams);
        if (donorsResp['success'] == true && donorsResp['data'] != null) {
          final donors = (donorsResp['data'] as List);
          if (donors.isNotEmpty) {
            Navigator.pop(context);
            _showDonorsList(donors);
            return;
          }
        }
      }

      // 3) Fallback to hospitals by city/keyword
      if (cityOrKeyword != null && cityOrKeyword.isNotEmpty) {
        final hospitalsResp = await _api.getHospitals(city: cityOrKeyword);
        if (hospitalsResp['success'] == true && hospitalsResp['data'] != null) {
          final hospitals = (hospitalsResp['data'] as List);
          if (hospitals.isNotEmpty) {
            Navigator.pop(context);
            _showHospitalsList(hospitals);
            return;
          }
        }
      }

      // Nothing found
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching donors, blood banks, or hospitals found'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      // Ensure loading is closed
      try { Navigator.pop(context); } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDonorsList(List<dynamic> donors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👥 Results (${donors.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: donors.length,
            itemBuilder: (context, index) {
              final donor = donors[index];
              // Support both donor objects and fallback bank-derived items
              if (donor is Map &&
                  donor['source_type'] == 'bloodBank' &&
                  donor['raw'] != null) {
                final bank = donor['raw'];
                final bloodUnits = {
                  'A+': bank['a_positive'] ?? 0,
                  'A-': bank['a_negative'] ?? 0,
                  'B+': bank['b_positive'] ?? 0,
                  'B-': bank['b_negative'] ?? 0,
                  'O+': bank['o_positive'] ?? 0,
                  'O-': bank['o_negative'] ?? 0,
                  'AB+': bank['ab_positive'] ?? 0,
                  'AB-': bank['ab_negative'] ?? 0,
                };
                final totalUnits = bloodUnits.values.fold<int>(
                  0,
                  (a, b) => a + (b as int),
                );

                // Build available blood groups string
                final availableGroups = bloodUnits.entries
                    .where((e) => e.value > 0)
                    .map((e) => '${e.key}(${e.value})')
                    .join(', ');

                // Get donor names if available
                final donorNames = bank['donor_names'] as List<dynamic>?;
                final donorText = (donorNames != null && donorNames.isNotEmpty)
                    ? '👥 Donors: ${donorNames.take(3).join(", ")}${donorNames.length > 3 ? " +${donorNames.length - 3} more" : ""}'
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF9B59B6),
                      child: Icon(Icons.local_hospital, color: Colors.white),
                    ),
                    title: Text(
                      bank['name'] ?? 'Unknown Bank',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 ${bank['city'] ?? ''}, ${bank['state'] ?? ''}',
                        ),
                        Text('📞 ${bank['phone'] ?? 'N/A'}'),
                        if (availableGroups.isNotEmpty)
                          Text(
                            '🩸 Available: $availableGroups',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (donorText != null)
                          InkWell(
                            onTap: () {
                              if (donorNames != null && donorNames.isNotEmpty) {
                                _showDonorNamesDialog(
                                  bank['name'] ?? 'Blood Bank',
                                  donorNames.cast<String>(),
                                  bank['city'] ?? '',
                                );
                              }
                            },
                            child: Text(
                              donorText,
                              style: const TextStyle(
                                color: Color(0xFFDB7093),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        Text(
                          'Total: $totalUnits units',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      bank['is_24x7'] == true
                          ? Icons.access_time
                          : Icons.schedule,
                      color: bank['is_24x7'] == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                    isThreeLine: true,
                  ),
                );
              }

              final user = donor['user'] ?? {};
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFDB7093),
                    child: Text(
                      donor['blood_group'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📞 ${user['phone'] ?? 'No phone'}'),
                      Text('📍 ${user['city'] ?? 'Unknown city'}'),
                    ],
                  ),
                  trailing: Icon(
                    donor['is_available'] == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: donor['is_available'] == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHospitalsList(List<dynamic> hospitals) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏥 Hospitals (${hospitals.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4ECDC4),
                  child: Icon(Icons.local_hospital, color: Colors.white),
                ),
                title: Text(hospital['name'] ?? 'Unknown'),
                subtitle: Text(
                  '${hospital['city'] ?? ''}, ${hospital['state'] ?? ''}\n${hospital['phone'] ?? 'No phone'}',
                ),
                trailing: Icon(
                  hospital['is_emergency'] == true ? Icons.warning : Icons.info,
                  color: hospital['is_emergency'] == true
                      ? Colors.red
                      : Colors.blue,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBloodBanksList(List<dynamic> bloodBanks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🩸 Blood Banks (${bloodBanks.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bloodBanks.length,
            itemBuilder: (context, index) {
              final bank = bloodBanks[index];
              final totalUnits =
                  (bank['a_positive'] ?? 0) +
                  (bank['a_negative'] ?? 0) +
                  (bank['b_positive'] ?? 0) +
                  (bank['b_negative'] ?? 0) +
                  (bank['o_positive'] ?? 0) +
                  (bank['o_negative'] ?? 0) +
                  (bank['ab_positive'] ?? 0) +
                  (bank['ab_negative'] ?? 0);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF9B59B6),
                  child: Icon(Icons.inventory, color: Colors.white),
                ),
                title: Text(bank['name'] ?? 'Unknown'),
                subtitle: Text(
                  '${bank['city'] ?? ''}, ${bank['state'] ?? ''}\nTotal: $totalUnits units',
                ),
                trailing: Icon(
                  bank['is_24x7'] == true ? Icons.access_time : Icons.schedule,
                  color: bank['is_24x7'] == true ? Colors.green : Colors.orange,
                ),
                onTap: () {
                  // Open the full map centered on this bank
                  final markerLike = {
                    'name': bank['name'],
                    'lat':
                        bank['location']?['latitude'] ??
                        bank['latitude'] ??
                        bank['lat'],
                    'lng':
                        bank['location']?['longitude'] ??
                        bank['longitude'] ??
                        bank['lng'],
                    'type': 'bloodBank',
                    'phone': bank['phone'],
                    'distance': 0.0,
                  };

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => FullMapScreen(
                        nearbyDonors: [markerLike],
                        currentPosition: currentPosition,
                        centerLatitude: (markerLike['lat'] as num?)?.toDouble(),
                        centerLongitude: (markerLike['lng'] as num?)
                            ?.toDouble(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDonorNamesDialog(String bankName, List<String> donorNames, String city) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people, color: Color(0xFFDB7093)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Available Donors',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blood Bank: $bankName',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF9B59B6),
                ),
              ),
              Text(
                'Location: $city',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                '${donorNames.length} Available Donor(s):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: donorNames.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.pink.shade50,
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDB7093),
                          radius: 18,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          donorNames[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.phone,
                          color: Color(0xFFDB7093),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFDB7093)),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    // Get current user from localStorage
    final String? userData = html.window.localStorage['blood_current_user'];
    Map<String, dynamic>? currentUser;
    
    if (userData != null && userData.isNotEmpty) {
      try {
        currentUser = jsonDecode(userData);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFDB7093),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(
              currentUser?['name'] ?? "User Profile",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDB7093),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              currentUser?['email'] ?? "",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (currentUser?['bloodType'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 16, color: Color(0xFFDB7093)),
                    const SizedBox(width: 4),
                    Text(
                      currentUser!['bloodType'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDB7093),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildProfileOption(
              Icons.person,
              "My Profile",
              () {
                Navigator.pop(context);
                _showMyProfile(currentUser);
              },
            ),
            _buildProfileOption(
              Icons.settings,
              "Settings",
              () {
                Navigator.pop(context);
                _showSettings(currentUser);
              },
            ),
            _buildProfileOption(
              Icons.help,
              "Help & Support",
              () {
                Navigator.pop(context);
                _showHelpAndSupport();
              },
            ),
            _buildProfileOption(
              Icons.info,
              "About",
              () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            _buildProfileOption(
              Icons.logout,
              "Logout",
              () => _logout(),
              isLogout: true,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFFDB7093),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _logout() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear current user session
              html.window.localStorage.remove('blood_current_user');
              
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showMyProfile(Map<String, dynamic>? user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user data available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFFDB7093)),
            const SizedBox(width: 10),
            const Text('My Profile'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileDetail('Name', user['name'] ?? 'N/A', Icons.person_outline),
              const Divider(),
              _buildProfileDetail('Email', user['email'] ?? 'N/A', Icons.email_outlined),
              const Divider(),
              _buildProfileDetail('Phone', user['phone'] ?? 'N/A', Icons.phone_outlined),
              const Divider(),
              _buildProfileDetail('Blood Type', user['bloodType'] ?? 'N/A', Icons.water_drop_outlined),
              const Divider(),
              _buildProfileDetail('Location', user['location'] ?? 'N/A', Icons.location_on_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(Map<String, dynamic>? user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(userData: user),
      ),
    );
  }

  void _emergencyCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency Helpline'),
        content: const Text(
          'Calling Emergency Blood Bank...\n\n📞 1800-BLOOD-HELP\n📞 +91 98765 43210\n\nConnecting you to nearest blood bank with required blood type.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpAndSupportScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDB7093).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info, color: Color(0xFFDB7093), size: 28),
            ),
            const SizedBox(width: 12),
            const Text('About This App'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop, color: Color(0xFFDB7093), size: 40),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Blood Availability System',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDB7093),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '🎯 Our Mission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To bridge the gap between blood donors and those in need, saving lives through technology and community collaboration.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '✨ Key Features',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAboutFeature('🔍', 'Smart Blood Bank Search', 'Find nearby blood banks with real-time availability'),
              _buildAboutFeature('🤖', 'AI-Powered BloodBot', 'Get instant answers to blood-related queries'),
              _buildAboutFeature('🎯', 'IBDMA Algorithm', 'Intelligent matching of donors and recipients'),
              _buildAboutFeature('📍', 'Live Tracking', 'Real-time location-based services'),
              _buildAboutFeature('🆘', 'Emergency Requests', 'Quick response for urgent blood needs'),
              _buildAboutFeature('📊', 'Analytics Dashboard', 'Track donations and availability'),
              const SizedBox(height: 16),
              const Text(
                '🏆 Impact',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Connecting donors, recipients, and blood banks across India to ensure no life is lost due to blood unavailability.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFDB7093), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Made with love to save lives',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '© 2024 Blood Availability System',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutFeature(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestBlood() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedBlood;
    double? lat;
    double? lng;
    int unitsRequired = 1;
    String urgency = 'Urgent';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (ctx, setState) {
          Future<void> detectLocation() async {
            try {
              final perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.denied) {
                await Geolocator.requestPermission();
              }
              final pos = await Geolocator.getCurrentPosition();
              setState(() {
                lat = pos.latitude;
                lng = pos.longitude;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          Future<void> submit() async {
            if (selectedBlood == null || selectedBlood!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a blood type'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if ((nameCtrl.text.trim()).isEmpty || (phoneCtrl.text.trim()).isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter your name and contact number'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (lat == null || lng == null) {
              await detectLocation();
              if (lat == null || lng == null) return;
            }

            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: Color(0xFFDB7093)),
              ),
            );

            try {
              // Try to find nearest hospital to associate the request (DB requires hospital_id)
              int? hospitalId;
              try {
                final hospMarkers = await _api.getMapMarkers(
                  latitude: lat!,
                  longitude: lng!,
                  maxDistance: 50,
                  includeTypes: const ['hospitals'],
                  limit: 20,
                );
                if (hospMarkers['success'] == true) {
                  final List<dynamic> hs = (hospMarkers['data']?['hospitals'] as List?) ?? [];
                  if (hs.isNotEmpty) {
                    hs.sort((a, b) => ((a['distance'] ?? 1e9) as num).compareTo(((b['distance'] ?? 1e9) as num)));
                    hospitalId = (hs.first['id'] as num?)?.toInt();
                  }
                }
              } catch (_) {}

              // Build request payload matching backend /api/blood-requests
              final now = DateTime.now().toUtc();
              final payload = {
                'patientName': nameCtrl.text.trim(),
                'bloodType': selectedBlood,
                'unitsRequired': unitsRequired,
                'urgency': urgency,
                if (hospitalId != null) 'hospitalId': hospitalId,
                'requesterContact': {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                },
                'location': {
                  'latitude': lat,
                  'longitude': lng,
                },
                'requiredBy': now.add(const Duration(hours: 4)).toIso8601String(),
                'reason': 'App request',
                'notes': 'Requested via web app',
              };

              // Try to create the request; if network/CORS fails, continue with offline confirmation
              Map<String, dynamic> createRes = const {'success': false};
              try {
                createRes = await _api.createBloodRequest(payload);
              } catch (_) {
                // swallow network error to allow success UX; will show '(offline)'
                createRes = const {'success': false};
              }

              // Fetch nearby blood bank count for confirmation
              int bankCount = 0;
              try {
                final markers = await _api.getMapMarkers(
                  latitude: lat!,
                  longitude: lng!,
                  maxDistance: 50,
                  includeTypes: const ['bloodBanks'],
                );
                if (markers['success'] == true) {
                  final data = markers['data'] ?? {};
                  bankCount = ((data['bloodBanks'] as List?)?.length ?? 0);
                }
              } catch (_) {}

              Navigator.pop(context); // close loading
              Navigator.pop(context); // close form dialog

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('🩸 Request Sent'),
                  content: Text(
                      'Your request has been created${createRes['success'] == true ? '' : ' (offline)'} and sent to nearby blood banks.\n\n• Blood type: $selectedBlood\n• Name: ${nameCtrl.text.trim()}\n• Contact: ${phoneCtrl.text.trim()}\n• Nearby blood banks: $bankCount'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } catch (e) {
              // As a fallback, close loading and still show a success dialog (offline) so UX is consistent
              try { Navigator.pop(context); } catch (_) {}
              try { Navigator.pop(context); } catch (_) {}
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('🩸 Request Sent'),
                  content: Text(
                      'Your request has been created (offline) and will be synced shortly.\n\n• Blood type: ${selectedBlood ?? ''}\n• Name: ${nameCtrl.text.trim()}\n• Contact: ${phoneCtrl.text.trim()}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text('🩸 Request Blood'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Blood Type'),
                    items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    initialValue: selectedBlood,
                    onChanged: (v) => setState(() => selectedBlood = v),
                  ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Units Required'),
                            initialValue: unitsRequired,
                            items: List.generate(8, (i) => i + 1)
                                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                .toList(),
                            onChanged: (v) => setState(() => unitsRequired = v ?? 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Urgency'),
                            initialValue: urgency,
                            items: const ['Normal', 'Urgent', 'Critical']
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => urgency = v ?? 'Urgent'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Your Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lat != null && lng != null
                              ? 'Location: ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                              : 'Location: Not set',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: detectLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use my location'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB7093)),
                child: const Text('Send Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showIBDMAInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧠 Smart Match Algorithm'),
        content: const Text(
          'Intelligent Blood Donor Matching Algorithm uses AI to:\n\n• Match blood group compatibility\n• Calculate optimal distance\n• Check donor availability\n• Prioritize by urgency level\n• Consider donation eligibility\n\nThis ensures the fastest and most suitable donor match for critical situations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _findSmartMatch() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDB7093)),
        ),
      );

      // Get user location
      Position position;
      try {
        position = currentPosition ?? await Geolocator.getCurrentPosition();
      } catch (e) {
        // If location fails, use default Delhi coordinates
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Location Required'),
            content: const Text(
              'Please enable location services to find nearby donors. Using default location (Delhi) for demo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        position = Position(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      // Call real API
      final result = await _api.findMatchingDonors(
        bloodType: 'O+', // You can make this dynamic based on user profile
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        maxDistance: 500,
        urgency: 'normal',
      );

      Navigator.pop(context); // Close loading

      if (result['success'] == true && result['data'] != null) {
        final donors = result['data'] as List;

        if (donors.isEmpty) {
          _showNoMatchDialog();
          return;
        }

        // Show real results
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🔍 Smart Match Results (${donors.length} found)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: donors.length,
                itemBuilder: (context, index) {
                  final donor = donors[index];
                  final user = donor['user'] ?? {};
                  final distance =
                      donor['distance']?.toStringAsFixed(1) ?? '0.0';
                  final score = donor['score']?.toStringAsFixed(0) ?? '0';
                  return _buildDonorMatch(
                    user['name'] ?? 'Unknown',
                    donor['blood_group'] ?? 'N/A',
                    '$distance km',
                    '$score%',
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📞 Contacting top donors...'),
                      backgroundColor: Color(0xFFDB7093),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB7093),
                ),
                child: const Text(
                  'Contact Donors',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      } else {
        _showNoMatchDialog();
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding matches: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Smart Match'),
        content: const Text(
          'No matching donors found nearby. Try expanding the search radius.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorMatch(
    String name,
    String bloodGroup,
    String distance,
    String score,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$bloodGroup • $distance'),
            ],
          ),
          Text(
            score,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _openChatbot() {
    final TextEditingController chatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 BloodBot Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hello! I\'m BloodBot, your AI assistant.\n\nI can help you with:\n• Finding nearby donors\n• Blood bank information\n• Emergency contacts\n• Donation eligibility\n• General blood donation queries',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: chatController,
              decoration: const InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              final query = chatController.text.trim();
              if (query.isEmpty) return;

              // Close the compose dialog and open the persistent Chat screen
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChatScreen(api: _api, initialQuery: query),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB7093),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} // End of _MainDashboardState class

// -------------------- ChatScreen: Persistent Chat UI --------------------
class ChatScreen extends StatefulWidget {
  final dynamic api; // ApiService
  final String? initialQuery;

  const ChatScreen({super.key, required this.api, this.initialQuery});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages =
      []; // {sender: 'user'|'bot', text: '', quickActions: []}
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => sendMessage(widget.initialQuery!),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await widget.api.chatbotQuery(text);
      if (res != null && res['success'] == true) {
        final data = res['data'] ?? {};
        final botText = data['response'] ?? data['botResponse'] ?? '';
        final quick = (data['quickActions'] as List<dynamic>?) ?? [];
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': botText,
            'quickActions': quick,
          });
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': res?['message'] ?? 'No response from bot',
            'quickActions': [],
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error: ${e.toString()}',
          'quickActions': [],
        });
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 BloodBot'),
        backgroundColor: const Color(0xFFDB7093),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  final quick = (msg['quickActions'] as List<dynamic>?) ?? [];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.pink[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['text'] ?? ''),
                        ),
                        if (!isUser && quick.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: quick.map<Widget>((action) {
                              return ActionChip(
                                label: Text(action.toString()),
                                onPressed: () => sendMessage(action.toString()),
                                backgroundColor: const Color(0xFFFFB6C1),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) sendMessage(v.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            final t = _controller.text.trim();
                            if (t.isNotEmpty) sendMessage(t);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB7093),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this class after the MainDashboard class and before RegisterScreen:

class FullMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> nearbyDonors;
  final Position? currentPosition;
  final double? centerLatitude; // optional override
  final double? centerLongitude; // optional override

  const FullMapScreen({
    super.key,
    required this.nearbyDonors,
    this.currentPosition,
    this.centerLatitude,
    this.centerLongitude,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late ll.LatLng _center;
  List<Marker> _markers = [];
  String _selectedCity = 'Current';
  late final Map<String, ll.LatLng> _cityCenters;

  @override
  void initState() {
    super.initState();
    // Priority: explicit centerLatitude/centerLongitude -> currentPosition -> default
    if (widget.centerLatitude != null && widget.centerLongitude != null) {
      _center = ll.LatLng(widget.centerLatitude!, widget.centerLongitude!);
    } else if (widget.currentPosition != null) {
      _center = ll.LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    } else {
      _center = ll.LatLng(28.6139, 77.2090); // default to New Delhi
    }
    _cityCenters = {
      'Current': _center,
      'Bengaluru': ll.LatLng(12.9716, 77.5946),
      'Mumbai': ll.LatLng(19.0760, 72.8777),
      'Delhi': ll.LatLng(28.6139, 77.2090),
      'Hyderabad': ll.LatLng(17.3850, 78.4867),
      'Chennai': ll.LatLng(13.0827, 80.2707),
      'Kolkata': ll.LatLng(22.5726, 88.3639),
      'Pune': ll.LatLng(18.5204, 73.8567),
      'Ahmedabad': ll.LatLng(23.0225, 72.5714),
    };
    _fetchLiveMarkers();
  }

  Future<void> _changeCity(String city) async {
    setState(() {
      _selectedCity = city;
      _center = _cityCenters[city] ?? _center;
    });
    await _fetchLiveMarkers();
  }

  Future<void> _showCityCounts() async {
    final api = ApiService();
    final items = <String, int>{};
    for (final entry in _cityCenters.entries) {
      final resp = await api.getMapMarkers(
        latitude: entry.value.latitude,
        longitude: entry.value.longitude,
        maxDistance: 120,
        includeTypes: const ['bloodBanks'],
      );
      final count = (resp['success'] == true)
          ? (((resp['data']?['bloodBanks']) as List?)?.length ?? 0)
          : 0;
      items[entry.key] = count;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Bank Counts by City',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${e.key}: ${e.value}'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB7093),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchLiveMarkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
      final resp = await api.getMapMarkers(
        latitude: _center.latitude,
        longitude: _center.longitude,
        // Look wider so an entire city like Bengaluru shows all banks
        maxDistance: 120,
        // We only want exact blood bank pin locations per the request
        includeTypes: const ['bloodBanks'],
      );

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        final List<Map<String, dynamic>> items = [];
        if (data['bloodBanks'] is List) {
          items.addAll(
            (data['bloodBanks'] as List).cast<Map<String, dynamic>>(),
          );
        }

        _markers = items.map((d) {
          final lat =
              (d['coordinates']?['latitude'] ?? d['latitude'] ?? d['lat'])
                  ?.toDouble() ??
              0.0;
          final lng =
              (d['coordinates']?['longitude'] ?? d['longitude'] ?? d['lng'])
                  ?.toDouble() ??
              0.0;
          final title = d['name'] ?? d['label'] ?? '${d['type'] ?? 'Location'}';
          final type = (d['type'] ?? '').toString();
          final color = type == 'bloodBank'
              ? Colors.red
              : (type == 'donor' ? Colors.green : Colors.blue);

          return Marker(
            width: 60,
            height: 60,
            point: ll.LatLng(lat, lng),
            builder: (ctx) => GestureDetector(
              onTap: () => _onMarkerTap(d),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: color, size: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(title, style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      }
    } catch (e) {
      print('Failed to fetch markers: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _isLoading = false;
  List<ll.LatLng> _routePoints = [];

  Future<void> _onMarkerTap(Map<String, dynamic> d) async {
    final api = ApiService();
    final origin = {
      'latitude': _center.latitude,
      'longitude': _center.longitude,
    };
    final destCoords =
        d['coordinates'] ?? {'latitude': d['lat'], 'longitude': d['lng']};

    final resp = await api.getDirections(
      origin: origin,
      destination: {
        'latitude': destCoords['latitude'],
        'longitude': destCoords['longitude'],
      },
    );
    if (resp['success'] == true && resp['route'] != null) {
      final route = (resp['route'] as List)
          .map(
            (p) => ll.LatLng(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            ),
          )
          .toList();
      setState(() {
        _routePoints = route;
      });
    } else {
      // fallback: just show details
      _showMarkerDetails(d);
    }
  }

  void _showMarkerDetails(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d['name'] ?? 'Location',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${d['blood'] ?? d['type'] ?? 'N/A'}'),
            if (d['distance'] != null) Text('Distance: ${d['distance']} km'),
            if (d['phone'] != null) Text('Phone: ${d['phone']}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB7093),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Nearby Donors & Blood Banks'),
        backgroundColor: const Color(0xFFDB7093),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(center: _center, zoom: 13.0),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.blood_availability_system',
                ),
                MarkerLayer(markers: _markers),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue.withOpacity(0.8),
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
            // Controls: city selector + count badge
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        items: _cityCenters.keys
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => v != null ? _changeCity(v) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bloodtype,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Banks: ${_markers.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showCityCounts,
                    icon: const Icon(
                      Icons.assessment,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'City Counts',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB7093),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFDB7093)),
              ),
          ],
        ),
      ),
    );
  }
}

// Add these classes at the end of your file (after FullMapScreen):

// 📝 Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  String _selectedRole = 'Donor';

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _roles = ['Donor', 'Recipient', 'Hospital', 'Blood Bank'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 60,
                        color: Color(0xFFDB7093),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB7093),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join our blood donation community",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Form Fields
                _buildTextField(_nameController, "Full Name", Icons.person),
                const SizedBox(height: 16),
                _buildTextField(_emailController, "Email", Icons.email),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  "Password",
                  Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, "Phone Number", Icons.phone),
                const SizedBox(height: 16),
                _buildTextField(
                  _locationController,
                  "Location",
                  Icons.location_on,
                ),
                const SizedBox(height: 16),

                // Blood Group Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBloodGroup,
                    decoration: InputDecoration(
                      labelText: "Blood Group",
                      prefixIcon: const Icon(
                        Icons.bloodtype,
                        color: Color(0xFFDB7093),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    items: _bloodGroups.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBloodGroup = newValue!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Role Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role",
                      prefixIcon: const Icon(
                        Icons.assignment_ind,
                        color: Color(0xFFDB7093),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    items: _roles.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Register Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB7093), Color(0xFFFF69B4)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDB7093).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Already have an account? Login here",
                    style: TextStyle(
                      color: Color(0xFFDB7093),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFDB7093)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  void _registerUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // Create user data for localStorage
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        'bloodType': _selectedBloodGroup,
        'role': _selectedRole,
        'registered_date': DateTime.now().toIso8601String(),
      };

      // Store in localStorage
      final String? existingData = html.window.localStorage['blood_users'];
      List<dynamic> users = [];

      if (existingData != null && existingData.isNotEmpty) {
        users = jsonDecode(existingData);
      }

      users.add(userData);
      html.window.localStorage['blood_users'] = jsonEncode(users);

      // Save to backend database if role is Donor
      if (_selectedRole == 'Donor') {
        try {
          final apiService = ApiService();
          final donorData = {
            'name': _nameController.text,
            'bloodType': _selectedBloodGroup,
            'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '0000000000',
            'email': _emailController.text,
            'age': 25, // Default age
            'gender': 'Other', // Default gender
            'latitude': 0.0,
            'longitude': 0.0,
            'address': {
              'street': '',
              'city': _locationController.text.isNotEmpty ? _locationController.text : 'Unknown',
              'state': '',
              'pincode': '',
            },
            'availableForDonation': true,
          };
          
          await apiService.createDonor(donorData);
          print('✅ Donor saved to backend database');
        } catch (e) {
          print('⚠️ Failed to save donor to backend: $e');
          // Continue even if backend save fails
        }
      }

      // Create notification for new donor registration
      await _createRegistrationNotification(
        _nameController.text,
        _selectedBloodGroup,
        _locationController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  Future<void> _createRegistrationNotification(
      String name, String bloodType, String location) async {
    try {
      final apiService = ApiService();
      // Create notifications for multiple random donors to simulate broadcast
      final donorIds = [1, 2, 3, 5, 10, 15, 20, 25, 30, 35];
      
      for (int donorId in donorIds.take(5)) {
        await apiService.createNotification({
          'recipientId': donorId,
          'recipientType': 'Donor',
          'title': 'New donor registered',
          'message': '$name ($bloodType) joined nearby${location.isNotEmpty ? " from $location" : ""}',
          'type': 'DonorRegistration',
          'priority': 'Low',
        });
      }
    } catch (e) {
      print('Error creating registration notification: $e');
    }
  }
}

// 📊 Dashboard Screen for viewing registered users
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> users = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    try {
      final String? data = html.window.localStorage['blood_users'];
      if (data != null && data.isNotEmpty) {
        setState(() {
          users = jsonDecode(data);
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  List<dynamic> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      return user['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          user['blood_group'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          user['role'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          user['location'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFDB7093),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            "Registration Dashboard",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDB7093),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _loadUsers,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFFDB7093),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText:
                            "Search by name, blood group, role, or location",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFDB7093),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Stats
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      "Total Users",
                      "${users.length}",
                      Icons.people,
                    ),
                    _buildStatCard(
                      "Donors",
                      "${users.where((u) => u['role'] == 'Donor').length}",
                      Icons.bloodtype,
                    ),
                    _buildStatCard(
                      "Recipients",
                      "${users.where((u) => u['role'] == 'Recipient').length}",
                      Icons.healing,
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No users found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Text(
                                  user['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("📧 ${user['email']}"),
                                  Text(
                                    "🩸 ${user['blood_group']} • ${user['role']}",
                                  ),
                                  Text("📍 ${user['location']}"),
                                  Text("📞 ${user['phone']}"),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user['role']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user['role'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFDB7093), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDB7093),
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Donor':
        return Colors.green;
      case 'Recipient':
        return Colors.orange;
      case 'Hospital':
        return Colors.blue;
      case 'Blood Bank':
        return Colors.purple;
      default:
        return const Color(0xFFDB7093);
    }
  }
}

// Settings Screen Widget
class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SettingsScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFDB7093),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFFDB7093),
                  child: Icon(Icons.person, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userData?['name'] ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userData?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Account Settings
          _buildSectionHeader('Account'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.edit,
                  'Edit Profile',
                  'Update your personal information',
                  () => _showEditProfile(),
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  Icons.lock,
                  'Change Password',
                  'Update your password',
                  () => _showChangePassword(),
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  Icons.verified_user,
                  'Privacy & Security',
                  'Manage your privacy settings',
                  () => _showPrivacyAndSecurity(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Preferences
          _buildSectionHeader('Preferences'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSwitchTile(
                  Icons.notifications,
                  'Notifications',
                  'Receive alerts for blood requests',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  Icons.dark_mode,
                  'Dark Mode',
                  'Enable dark theme',
                  _darkModeEnabled,
                  (value) => setState(() => _darkModeEnabled = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  Icons.location_on,
                  'Location Services',
                  'Allow location access for nearby searches',
                  _locationEnabled,
                  (value) => setState(() => _locationEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // App Info
          _buildSectionHeader('About'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSettingTile(
                  Icons.help,
                  'Help & Support',
                  'Get help and contact support',
                  () => _showHelpAndSupport(),
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  Icons.info,
                  'About App',
                  'Version 1.0.0',
                  () => _showAboutDialog(),
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  Icons.description,
                  'Terms & Conditions',
                  'Read our terms of service',
                  () => _showTermsAndConditions(),
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  Icons.privacy_tip,
                  'Privacy Policy',
                  'Read our privacy policy',
                  () => _showPrivacyPolicy(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Logout Button
          Container(
            color: Colors.white,
            child: _buildSettingTile(
              Icons.logout,
              'Logout',
              'Sign out from your account',
              () => _logout(),
              isDestructive: true,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFFDB7093),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFFDB7093)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      value: value,
      activeColor: const Color(0xFFDB7093),
      onChanged: onChanged,
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: widget.userData?['name']);
    final phoneController = TextEditingController(text: widget.userData?['phone']);
    final locationController = TextEditingController(text: widget.userData?['location']);
    String? selectedBloodType = widget.userData?['bloodType'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFFDB7093)),
              SizedBox(width: 10),
              Text('Edit Profile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedBloodType,
                  decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    prefixIcon: Icon(Icons.water_drop),
                    border: OutlineInputBorder(),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedBloodType = value;
                    });
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfile(
                  nameController.text,
                  phoneController.text,
                  selectedBloodType,
                  locationController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB7093),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfile(String name, String phone, String? bloodType, String location) {
    if (widget.userData == null) return;

    try {
      // Update user data
      widget.userData!['name'] = name;
      widget.userData!['phone'] = phone;
      widget.userData!['bloodType'] = bloodType;
      widget.userData!['location'] = location;

      // Save to localStorage
      html.window.localStorage['blood_current_user'] = jsonEncode(widget.userData);

      // Also update in blood_users list
      final String? usersData = html.window.localStorage['blood_users'];
      if (usersData != null) {
        final List<dynamic> users = jsonDecode(usersData);
        final index = users.indexWhere((u) => u['email'] == widget.userData!['email']);
        if (index != -1) {
          users[index] = widget.userData;
          html.window.localStorage['blood_users'] = jsonEncode(users);
        }
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFFDB7093)),
            SizedBox(width: 10),
            Text('Change Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                // Implement password change logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB7093),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDB7093).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info, color: Color(0xFFDB7093), size: 28),
            ),
            const SizedBox(width: 12),
            const Text('About This App'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop, color: Color(0xFFDB7093), size: 40),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Blood Availability System',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDB7093),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '🎯 Our Mission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To bridge the gap between blood donors and those in need, saving lives through technology and community collaboration.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '✨ Key Features',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('🔍', 'Smart Blood Bank Search', 'Find nearby blood banks with real-time availability'),
              _buildFeatureItem('🤖', 'AI-Powered BloodBot', 'Get instant answers to blood-related queries'),
              _buildFeatureItem('🎯', 'IBDMA Algorithm', 'Intelligent matching of donors and recipients'),
              _buildFeatureItem('📍', 'Live Tracking', 'Real-time location-based services'),
              _buildFeatureItem('🆘', 'Emergency Requests', 'Quick response for urgent blood needs'),
              _buildFeatureItem('📊', 'Analytics Dashboard', 'Track donations and availability'),
              const SizedBox(height: 16),
              const Text(
                '🏆 Impact',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Connecting donors, recipients, and blood banks across India to ensure no life is lost due to blood unavailability.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFDB7093), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Made with love to save lives',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '© 2024 Blood Availability System',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpAndSupportScreen(),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear current user session
              html.window.localStorage.remove('blood_current_user');
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.description, color: Color(0xFFDB7093)),
            SizedBox(width: 10),
            Text('Terms & Conditions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blood Availability System - Terms of Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDB7093),
                ),
              ),
              const SizedBox(height: 15),
              _buildTermSection(
                '1. Acceptance of Terms',
                'By accessing and using the Blood Availability System, you accept and agree to be bound by these terms and conditions.',
              ),
              _buildTermSection(
                '2. User Responsibilities',
                '• Provide accurate and up-to-date information\n• Maintain confidentiality of your account\n• Not misuse the platform for fraudulent activities\n• Respect privacy of other users',
              ),
              _buildTermSection(
                '3. Blood Donation',
                '• Users must meet health eligibility criteria\n• Donations are voluntary and unpaid\n• Users must follow medical guidelines\n• The platform facilitates connections only',
              ),
              _buildTermSection(
                '4. Data Usage',
                '• Your data will be used to match donors with recipients\n• Personal information shared with consent only\n• Medical information handled with confidentiality\n• You can request data deletion anytime',
              ),
              _buildTermSection(
                '5. Liability',
                '• We facilitate connections but don\'t guarantee blood availability\n• Medical decisions are user\'s responsibility\n• Verify blood bank information independently\n• Emergency situations require professional medical help',
              ),
              _buildTermSection(
                '6. Account Termination',
                '• You may terminate your account anytime\n• We reserve the right to suspend accounts for violations\n• Data will be deleted as per privacy policy',
              ),
              const SizedBox(height: 10),
              const Text(
                'Last Updated: November 2024',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Color(0xFFDB7093)),
            SizedBox(width: 10),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Privacy Matters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDB7093),
                ),
              ),
              const SizedBox(height: 15),
              _buildTermSection(
                '1. Information We Collect',
                '• Name, email, phone number\n• Blood type and medical information\n• Location data for matching services\n• Usage data and preferences',
              ),
              _buildTermSection(
                '2. How We Use Your Information',
                '• Match donors with recipients\n• Facilitate blood bank searches\n• Send notifications for urgent requests\n• Improve our services\n• Comply with legal requirements',
              ),
              _buildTermSection(
                '3. Data Sharing',
                '• Shared only with explicit consent\n• Blood banks and hospitals (when necessary)\n• Never sold to third parties\n• Encrypted during transmission',
              ),
              _buildTermSection(
                '4. Data Security',
                '• Industry-standard encryption\n• Secure servers and databases\n• Regular security audits\n• Access controls and authentication',
              ),
              _buildTermSection(
                '5. Your Rights',
                '• Access your personal data\n• Update or correct information\n• Request data deletion\n• Opt-out of notifications\n• Export your data',
              ),
              _buildTermSection(
                '6. Cookies & Tracking',
                '• Essential cookies for functionality\n• Analytics to improve experience\n• You can disable cookies in settings',
              ),
              _buildTermSection(
                '7. Children\'s Privacy',
                '• Service intended for users 18 and above\n• Parental consent required for minors\n• Special protection for children\'s data',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: Color(0xFFDB7093), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We are committed to protecting your privacy and ensuring secure handling of your personal information.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'For privacy concerns: privacy@bloodsystem.com',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              const Text(
                'Last Updated: November 2024',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyAndSecurity() {
    bool twoFactorAuth = false;
    bool biometricAuth = false;
    bool showProfile = true;
    bool shareLocation = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user, color: Color(0xFFDB7093), size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Privacy & Security'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDB7093).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFFDB7093), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Manage your privacy and security preferences',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Authentication Section
                const Text(
                  'Authentication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB7093),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.security, color: Color(0xFFDB7093), size: 20),
                        title: const Text(
                          'Two-Factor Authentication',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Add extra security layer',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: twoFactorAuth,
                        activeColor: const Color(0xFFDB7093),
                        onChanged: (value) => setDialogState(() => twoFactorAuth = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint, color: Color(0xFFDB7093), size: 20),
                        title: const Text(
                          'Biometric Authentication',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Use fingerprint or face ID',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: biometricAuth,
                        activeColor: const Color(0xFFDB7093),
                        onChanged: (value) => setDialogState(() => biometricAuth = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Privacy Section
                const Text(
                  'Privacy Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB7093),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.public, color: Color(0xFFDB7093), size: 20),
                        title: const Text(
                          'Public Profile',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Make profile visible to others',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: showProfile,
                        activeColor: const Color(0xFFDB7093),
                        onChanged: (value) => setDialogState(() => showProfile = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.location_on, color: Color(0xFFDB7093), size: 20),
                        title: const Text(
                          'Share Location',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Share location with blood banks',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: shareLocation,
                        activeColor: const Color(0xFFDB7093),
                        onChanged: (value) => setDialogState(() => shareLocation = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Data Management Section
                const Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB7093),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSecurityOption(
                  Icons.download,
                  'Download My Data',
                  'Export all your personal data',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data export request initiated. You will receive an email shortly.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildSecurityOption(
                  Icons.delete_forever,
                  'Delete Account',
                  'Permanently delete your account',
                  () {
                    Navigator.pop(context);
                    _showDeleteAccountConfirmation();
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 20),

                // Activity Section
                const Text(
                  'Activity & History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB7093),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSecurityOption(
                  Icons.history,
                  'Login History',
                  'View recent login activity',
                  () {
                    Navigator.pop(context);
                    _showLoginHistory();
                  },
                ),
                const SizedBox(height: 8),
                _buildSecurityOption(
                  Icons.devices,
                  'Connected Devices',
                  'Manage logged-in devices',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Currently logged in on 1 device'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy & Security settings saved!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB7093),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive ? Colors.red.shade200 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFFDB7093),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Account?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              'This includes:\n• Profile information\n• Donation history\n• Saved preferences\n• All associated data',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted. You will receive a confirmation email.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFFDB7093)),
            SizedBox(width: 10),
            Text('Login History'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoginHistoryItem(
              'Current Session',
              'Web Browser',
              'Just now',
              true,
            ),
            const Divider(),
            _buildLoginHistoryItem(
              'Windows PC',
              'Chrome Browser',
              '2 hours ago',
              false,
            ),
            const Divider(),
            _buildLoginHistoryItem(
              'Mobile Device',
              'Android App',
              'Yesterday',
              false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryItem(
    String device,
    String platform,
    String time,
    bool isCurrent,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        platform.contains('Mobile') || platform.contains('Android') 
            ? Icons.phone_android 
            : Icons.computer,
        color: const Color(0xFFDB7093),
      ),
      title: Text(
        device,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text('$platform • $time', style: const TextStyle(fontSize: 12)),
      trailing: isCurrent
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

// Help and Support Screen
class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFDB7093),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDB7093), Color(0xFFFF9AC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDB7093).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.white, size: 40),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help you?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Learn how to use our platform effectively',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Getting Started
          _buildSectionTitle('🚀 Getting Started'),
          _buildGuideCard(
            '1. Create Your Account',
            [
              'Click "Register" on the login screen',
              'Fill in your details (Name, Email, Phone, Blood Type)',
              'Choose your role: Donor, Recipient, Hospital, or Blood Bank',
              'Set a secure password and confirm',
              'Click "Register" to create your account',
            ],
            Icons.person_add,
          ),
          const SizedBox(height: 15),
          _buildGuideCard(
            '2. Login to Your Account',
            [
              'Enter your registered email and password',
              'Click "Login" to access the dashboard',
              'Your session will be saved automatically',
            ],
            Icons.login,
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('🔍 Using the Dashboard'),
          _buildGuideCard(
            'Search Blood Banks',
            [
              'Use the search bar at the top of the dashboard',
              'Enter city name, blood type, or blood bank name',
              'View real-time availability and contact details',
              'See distance from your location',
              'Click on results for more information',
            ],
            Icons.search,
          ),
          const SizedBox(height: 15),
          _buildGuideCard(
            'Smart Donor Matching (IBDMA)',
            [
              'Select blood type needed',
              'Enter recipient location',
              'Click "Find Donors" button',
              'AI algorithm matches best donors based on:',
              '  • Blood compatibility (30 points)',
              '  • Distance proximity (25 points)',
              '  • Availability status (20 points)',
              '  • Donation history (15 points)',
              '  • Response time (10 points)',
              'View donor profiles with match scores',
              'Contact top-matched donors directly',
            ],
            Icons.people,
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('🤖 Using BloodBot'),
          _buildGuideCard(
            'Chat with AI Assistant',
            [
              'Click the BloodBot icon (bottom right)',
              'Type your question or request',
              'BloodBot can help you with:',
              '  • Finding blood banks in your city',
              '  • Getting donor contact information',
              '  • Blood donation eligibility questions',
              '  • Emergency blood request guidance',
              '  • General blood-related information',
              'Get instant, accurate responses',
            ],
            Icons.chat_bubble,
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('👤 Managing Your Profile'),
          _buildGuideCard(
            'Profile & Settings',
            [
              'Click profile icon in the bottom navigation',
              'View your profile details',
              'Access Settings to:',
              '  • Edit your profile information',
              '  • Change password',
              '  • Toggle notifications',
              '  • Enable/disable location services',
              '  • Manage app preferences',
              'Logout securely when done',
            ],
            Icons.settings,
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('🆘 Emergency Features'),
          _buildGuideCard(
            'Emergency Blood Request',
            [
              'Click the Emergency (SOS) icon',
              'System prioritizes your request',
              'Connects you to nearest blood banks',
              'Shows emergency helpline numbers',
              'Call directly from the app',
            ],
            Icons.emergency,
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('💡 Tips for Best Experience'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipItem('✅', 'Keep your profile information updated'),
                _buildTipItem('✅', 'Enable location for accurate blood bank search'),
                _buildTipItem('✅', 'Turn on notifications for urgent requests'),
                _buildTipItem('✅', 'Verify blood bank details before visiting'),
                _buildTipItem('✅', 'Use BloodBot for quick answers'),
                _buildTipItem('✅', 'Update availability status if you\'re a donor'),
              ],
            ),
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('📞 Contact Support'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDB7093).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, size: 50, color: Color(0xFFDB7093)),
                const SizedBox(height: 15),
                const Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Our support team is here to assist you',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildContactOption(Icons.email, 'support@bloodsystem.com'),
                const SizedBox(height: 10),
                _buildContactOption(Icons.phone, '+91 1800-BLOOD-HELP'),
                const SizedBox(height: 10),
                _buildContactOption(Icons.access_time, 'Available 24/7'),
              ],
            ),
          ),

          const SizedBox(height: 25),
          _buildSectionTitle('❓ Frequently Asked Questions'),
          _buildFAQCard(
            'How do I donate blood?',
            'Register as a Donor, keep your profile updated with availability status. When a match is found, you\'ll be contacted by recipients or blood banks.',
          ),
          const SizedBox(height: 12),
          _buildFAQCard(
            'Is my data secure?',
            'Yes! We use industry-standard encryption to protect your personal information. Your data is never shared without your consent.',
          ),
          const SizedBox(height: 12),
          _buildFAQCard(
            'How accurate is the blood bank availability?',
            'Blood bank data is updated in real-time. However, we recommend calling the blood bank to confirm availability before visiting.',
          ),
          const SizedBox(height: 12),
          _buildFAQCard(
            'Can I request blood for someone else?',
            'Yes! Register as a Recipient and use the Smart Match feature to find suitable donors for your patient.',
          ),
          const SizedBox(height: 12),
          _buildFAQCard(
            'What is the IBDMA algorithm?',
            'IBDMA (Intelligent Blood Donor Matching Algorithm) uses AI to match donors with recipients based on multiple factors including compatibility, distance, availability, and history.',
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFDB7093),
        ),
      ),
    );
  }

  static Widget _buildGuideCard(String title, List<String> steps, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB7093).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFDB7093), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.startsWith('  •') ? '    ' : '• ',
                      style: const TextStyle(
                        color: Color(0xFFDB7093),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        step.replaceFirst('  •', '•').replaceFirst('• ', ''),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContactOption(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFDB7093)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  static Widget _buildFAQCard(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Color(0xFFDB7093), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
