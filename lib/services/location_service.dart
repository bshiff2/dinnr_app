import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Location Service - Get user location and search nearby places
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

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

  /// Compute distance in meters from last known position to provided coordinates
  double? distanceFrom(double lat, double lng) {
    if (_lastPosition == null) return null;
    return Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      lat,
      lng,
    );
  }

  /// Get latitude/longitude as string for AI context
  Future<String> getLocationContext() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return "User's location is unavailable.";
    }

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

        return results.take(10).map((place) {
          final photos = place['photos'] as List?;
          final photoRefs = photos == null
              ? <String>[]
              : photos
                  .map((p) => p['photo_reference'] as String?)
                  .whereType<String>()
                  .toList();

          return NearbyPlace(
            name: place['name'] ?? 'Unknown',
            address: place['vicinity'] ?? '',
            rating: (place['rating'] as num?)?.toDouble(),
            priceLevel: place['price_level'] as int?,
            isOpen: place['opening_hours']?['open_now'] as bool?,
            types: List<String>.from(place['types'] ?? []),
            photoReference: photoRefs.isNotEmpty ? photoRefs.first : null,
            photoReferences: photoRefs,
            userRatingsTotal: place['user_ratings_total'] as int?,
            lat: (place['geometry']?['location']?['lat'] as num?)?.toDouble(),
            lng: (place['geometry']?['location']?['lng'] as num?)?.toDouble(),
            placeId: place['place_id'] as String?,
          );
        }).toList();
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
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '\$';
    }
  }

  /// Public helper for UI when priceLevel may be null
  String priceLabel(int? level) {
    if (level == null) return '\$';
    return _priceString(level);
  }

  String? get lastCity => _lastCity;

  /// Fetch place details (website / maps URL) using Place Details API
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (_googleApiKey == null || _googleApiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=website,url'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return null;

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      return PlaceDetails(
        website: result['website'] as String?,
        googleMapsUrl: result['url'] as String?,
      );
    } catch (e) {
      print('Place details error: $e');
      return null;
    }
  }
}

/// Model for nearby place results
class NearbyPlace {
  final String name;
  final String address;
  final double? rating;
  final int? priceLevel;
  final bool? isOpen;
  final List<String> types;
  final List<String> photoReferences;
  final String? photoReference;
  final int? userRatingsTotal;
  final double? lat;
  final double? lng;
  final String? placeId;

  const NearbyPlace({
    required this.name,
    required this.address,
    this.rating,
    this.priceLevel,
    this.isOpen,
    this.types = const [],
    this.photoReferences = const [],
    this.photoReference,
    this.userRatingsTotal,
    this.lat,
    this.lng,
    this.placeId,
  });

  @override
  String toString() {
    return '$name (${rating ?? 'N/A'}) - $address';
  }
}

/// Details response for a place
class PlaceDetails {
  final String? website;
  final String? googleMapsUrl;

  const PlaceDetails({this.website, this.googleMapsUrl});
}
