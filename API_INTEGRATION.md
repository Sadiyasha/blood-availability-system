# Blood Availability System - API Integration Guide

## 🔗 Connection Status: ✅ CONNECTED

- **Backend URL**: `http://localhost:5000`
- **Frontend URL**: `http://localhost:8080`
- **API Base**: `http://localhost:5000/api`

---

## 📡 Available API Endpoints (All Connected!)

### 🏥 Authentication (`/api/auth`)

#### Login
```dart
await api.login(email, password);
```
**Backend**: `POST /api/auth/login`
**Returns**: `{ success, message, user, access_token }`

#### Register
```dart
await api.register({
  'name': 'John Doe',
  'email': 'john@example.com',
  'password': 'secure123',
  'phone': '+1234567890',
  'blood_group': 'O+',
  'role': 'Donor',
  'latitude': 40.7128,
  'longitude': -74.0060
});
```
**Backend**: `POST /api/auth/register`
**Returns**: `{ success, message, user, access_token }`

#### Logout
```dart
await api.logout();
```
**Clears local session**

---

### 🩸 Donors (`/api/donors`)

#### Get All Donors
```dart
await api.getDonors(
  bloodGroup: 'O+',
  location: 'New York',
  isAvailable: true
);
```
**Backend**: `GET /api/donors?blood_group=O+&location=New York&is_available=true`
**Returns**: `{ success, count, donors }`

#### Search Donors (Advanced)
```dart
await api.searchDonors({
  'blood_group': 'O+',
  'latitude': 40.7128,
  'longitude': -74.0060,
  'radius_km': 20
});
```
**Backend**: `POST /api/donors/search`
**Returns**: `{ success, count, donors }` (sorted by distance)

#### Get Donor by ID
```dart
await api.getDonorById(123);
```
**Backend**: `GET /api/donors/123`
**Returns**: `{ success, donor }`

#### Update Donor Availability
```dart
await api.updateDonorAvailability(123, true);
```
**Backend**: `PUT /api/donors/123/availability`
**Returns**: `{ success, message, donor }`

---

### 📋 Blood Requests (`/api/blood-requests`)

#### Get All Requests
```dart
await api.getBloodRequests(
  status: 'pending',
  urgency: 'high',
  bloodGroup: 'AB+'
);
```
**Backend**: `GET /api/blood-requests?status=pending&urgency=high`
**Returns**: `{ success, count, requests }`

#### Create Blood Request
```dart
await api.createBloodRequest({
  'blood_group': 'O+',
  'units_needed': 2,
  'hospital': 'City Hospital',
  'location': 'New York, NY',
  'latitude': 40.7128,
  'longitude': -74.0060,
  'urgency': 'high',
  'contact_number': '+1234567890',
  'description': 'Urgent need for surgery'
});
```
**Backend**: `POST /api/blood-requests`
**Returns**: `{ success, message, request }`

#### Get Request by ID
```dart
await api.getBloodRequestById(456);
```
**Backend**: `GET /api/blood-requests/456`
**Returns**: `{ success, request }`

#### Update Request Status
```dart
await api.updateBloodRequestStatus(456, 'fulfilled');
```
**Backend**: `PUT /api/blood-requests/456/status`
**Returns**: `{ success, message, request }`

#### Delete Request
```dart
await api.deleteBloodRequest(456);
```
**Backend**: `DELETE /api/blood-requests/456`
**Returns**: `{ success, message }`

---

### 🔔 Notifications (`/api/notifications`)

#### Get Notifications
```dart
await api.getNotifications(
  isRead: false,
  type: 'blood_request',
  limit: 20
);
```
**Backend**: `GET /api/notifications?is_read=false&type=blood_request&limit=20`
**Returns**: `{ success, count, unread_count, notifications }`

#### Mark as Read
```dart
await api.markNotificationAsRead(789);
```
**Backend**: `PUT /api/notifications/789/read`
**Returns**: `{ success, message, notification }`

#### Mark All as Read
```dart
await api.markAllNotificationsAsRead();
```
**Backend**: `PUT /api/notifications/mark-all-read`
**Returns**: `{ success, message }`

#### Delete Notification
```dart
await api.deleteNotification(789);
```
**Backend**: `DELETE /api/notifications/789`
**Returns**: `{ success, message }`

---

### 🏦 Blood Banks (`/api/blood-banks`)

#### Get All Blood Banks
```dart
await api.getBloodBanks(
  city: 'New York',
  state: 'NY',
  is24x7: true
);
```
**Backend**: `GET /api/blood-banks?city=New York&state=NY&is_24x7=true`
**Returns**: `{ success, count, blood_banks }`

#### Search Blood Banks
```dart
await api.searchBloodBanks({
  'latitude': 40.7128,
  'longitude': -74.0060,
  'blood_group': 'O+',
  'radius_km': 30
});
```
**Backend**: `POST /api/blood-banks/search`
**Returns**: `{ success, count, blood_banks }` (with distance and availability)

#### Get Blood Bank by ID
```dart
await api.getBloodBankById(321);
```
**Backend**: `GET /api/blood-banks/321`
**Returns**: `{ success, blood_bank }`

---

### 🎯 Smart Match (`/api/smart-match`)

#### Find Matching Donors
```dart
await api.findMatchingDonors(
  bloodType: 'O+',
  location: {'latitude': 40.7128, 'longitude': -74.0060},
  maxDistance: 50,
  urgency: 'high'
);
```
**Backend**: `POST /api/smart-match/find-donors`
**Returns**: `{ success, message, data }` (AI-matched donors)

#### Match Blood Request
```dart
await api.matchBloodRequest(456);
```
**Backend**: `GET /api/smart-match/request/456/match`
**Returns**: `{ success, message, data }` (matched donors for request)

---

## 🛠️ Usage Example in Flutter

```dart
import 'services/api_service.dart';

// Initialize API service
final api = ApiService();

// Example: User Registration
void registerUser() async {
  try {
    final result = await api.register({
      'name': 'John Doe',
      'email': 'john@example.com',
      'password': 'secure123',
      'blood_group': 'O+',
      'role': 'Donor',
      'phone': '+1234567890'
    });
    
    if (result['success']) {
      print('User registered: ${result['user']}');
      print('Token: ${result['access_token']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Example: Find Matching Donors
void findDonors() async {
  try {
    final result = await api.findMatchingDonors(
      bloodType: 'O+',
      location: {'latitude': 40.7128, 'longitude': -74.0060},
      maxDistance: 50,
      urgency: 'high'
    );
    
    if (result['success']) {
      print('Found ${result['data'].length} donors');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## ✅ Connection Verified

All backend endpoints are now connected and accessible from the Flutter frontend!

**Test the connection:**
1. Open browser: `http://localhost:8080`
2. Backend logs will show API requests in real-time
3. Try registering a user or logging in to test the connection

---

## 📝 Notes

- All authenticated endpoints require JWT token (automatically handled by ApiService)
- Tokens are stored in SharedPreferences
- Backend runs on port 5000
- Frontend runs on port 8080
- CORS is enabled for localhost connections
