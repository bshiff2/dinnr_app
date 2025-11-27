import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteRestaurant {
  final String lookupKey;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? photoReference;
  final String? address;
  final double? rating;
  final String? priceLabel;
  final String? cuisine;
  final String? placeId;
  final String? source;
  final DateTime? createdAt;

  FavoriteRestaurant({
    required this.lookupKey,
    required this.name,
    this.description,
    this.imageUrl,
    this.photoReference,
    this.address,
    this.rating,
    this.priceLabel,
    this.cuisine,
    this.placeId,
    this.source,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lookupKey': lookupKey,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (photoReference != null) 'photoReference': photoReference,
      if (address != null) 'address': address,
      if (rating != null) 'rating': rating,
      if (priceLabel != null) 'priceLabel': priceLabel,
      if (cuisine != null) 'cuisine': cuisine,
      if (placeId != null) 'placeId': placeId,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory FavoriteRestaurant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];

    return FavoriteRestaurant(
      lookupKey: data['lookupKey'] as String? ?? doc.id,
      name: data['name'] as String? ?? 'Unknown',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      photoReference: data['photoReference'] as String?,
      address: data['address'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      priceLabel: data['priceLabel'] as String?,
      cuisine: data['cuisine'] as String?,
      placeId: data['placeId'] as String?,
      source: data['source'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  static String buildLookupKey({
    String? placeId,
    required String name,
    String? address,
  }) {
    if (placeId != null && placeId.isNotEmpty) {
      return placeId;
    }
    final normalizedName = name.trim().toLowerCase();
    final normalizedAddress = (address ?? '').trim().toLowerCase();
    return '$normalizedName::$normalizedAddress';
  }

  FavoriteRestaurant copyWith({String? lookupKeyOverride}) {
    return FavoriteRestaurant(
      lookupKey: lookupKeyOverride ?? lookupKey,
      name: name,
      description: description,
      imageUrl: imageUrl,
      photoReference: photoReference,
      address: address,
      rating: rating,
      priceLabel: priceLabel,
      cuisine: cuisine,
      placeId: placeId,
      source: source,
      createdAt: createdAt,
    );
  }

  String? imageUrlForDisplay(String? googleApiKey) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl;
    }
    if (photoReference != null && googleApiKey != null && googleApiKey.isNotEmpty) {
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoReference&key=$googleApiKey';
    }
    return null;
  }
}

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favoritesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  Stream<List<FavoriteRestaurant>> streamFavorites(String userId) {
    return _favoritesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => FavoriteRestaurant.fromDoc(doc)).toList(),
        );
  }

  Future<void> saveFavorite(String userId, FavoriteRestaurant favorite) async {
    final key = favorite.lookupKey;
    final ref = _favoritesRef(userId).doc(key);
    final data = favorite.copyWith(lookupKeyOverride: key).toMap();

    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();

    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> removeFavorite(String userId, String lookupKey) async {
    await _favoritesRef(userId).doc(lookupKey).delete();
  }

  Future<bool> isFavorite(String userId, String lookupKey) async {
    final doc = await _favoritesRef(userId).doc(lookupKey).get();
    return doc.exists;
  }
}
