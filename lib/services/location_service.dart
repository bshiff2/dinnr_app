import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// Location Service - Get user location and search nearby places
/// ─────────────────────────────────────────────────────────────────────────────

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  String? _lastCity;
  String? _googleApiKey;

  /// Set Google Places API key (get from ConfigService)
  void setApiKey(String key) {
    _googleApiKey = key;
  }

  /// Get current position with permission handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Get position
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return _lastPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get the last known position (faster, no GPS lookup)
  Position? get lastPosition => _lastPosition;

  /// Get latitude/longitude as string for AI context
  Future<String> getLocationContext() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return "User's location is unavailable.";
    }

    // Try to get city name via reverse geocoding
    final city = await _getCityName(position.latitude, position.longitude);
    _lastCity = city;

    if (city != null) {
      return "User is located in $city (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}).";
    }

    return "User is at coordinates ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}.";
  }

  /// Reverse geocode to get city name
  Future<String?> _getCityName(double lat, double lng) async {
    try {
      // Using free Nominatim API for reverse geocoding
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
        ),
        headers: {'User-Agent': 'DinnrApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        return address['city'] ?? 
               address['town'] ?? 
               address['village'] ?? 
               address['suburb'] ??
               address['county'];
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return null;
  }

  /// Search for nearby restaurants using Google Places API
  Future<List<NearbyPlace>> searchNearbyRestaurants({
    String? keyword,
    int radius = 2000,
  }) async {
    if (_googleApiKey == null || _googleApiKey!.isEmpty) {
      print('Google API key not set');
      return [];
    }

    final position = _lastPosition ?? await getCurrentPosition();
    if (position == null) return [];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${position.latitude},${position.longitude}'
        '&radius=$radius'
        '&type=restaurant'
        '${keyword != null ? '&keyword=${Uri.encodeComponent(keyword)}' : ''}'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        return results.take(5).map((place) => NearbyPlace(
          name: place['name'] ?? 'Unknown',
          address: place['vicinity'] ?? '',
          rating: (place['rating'] as num?)?.toDouble(),
          priceLevel: place['price_level'] as int?,
          isOpen: place['opening_hours']?['open_now'] as bool?,
          types: List<String>.from(place['types'] ?? []),
        )).toList();
      }
    } catch (e) {
      print('Places API error: $e');
    }

    return [];
  }

  /// Format nearby places for AI context
  Future<String> getNearbyRestaurantsContext({String? cuisine}) async {
    final places = await searchNearbyRestaurants(keyword: cuisine);

    if (places.isEmpty) {
      return "No nearby restaurants found. Suggest based on general knowledge.";
    }

    final buffer = StringBuffer("Nearby restaurants:\n");
    for (final place in places) {
      buffer.writeln("- ${place.name}");
      if (place.rating != null) buffer.writeln("  Rating: ${place.rating}/5");
      if (place.priceLevel != null) buffer.writeln("  Price: ${_priceString(place.priceLevel!)}");
      if (place.isOpen != null) buffer.writeln("  ${place.isOpen! ? 'Open now' : 'Closed'}");
      buffer.writeln("  ${place.address}");
    }

    return buffer.toString();
  }

  String _priceString(int level) {
    switch (level) {
      case 1: return '\$';
      case 2: return '\$\$';
      case 3: return '\$\$\$';
      case 4: return '\$\$\$\$';
      default: return '\$';
    }
  }

  String? get lastCity => _lastCity;
}

/// Model for nearby place results
class NearbyPlace {
  final String name;
  final String address;
  final double? rating;
  final int? priceLevel;
  final bool? isOpen;
  final List<String> types;

  NearbyPlace({
    required this.name,
    required this.address,
    this.rating,
    this.priceLevel,
    this.isOpen,
    this.types = const [],
  });

  @override
  String toString() {
    return '$name (${rating ?? 'N/A'}★) - $address';
  }
}
