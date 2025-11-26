import 'package:flutter/material.dart';

import 'page_layout.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final LocationService _locationService = LocationService();
  final ConfigService _configService = ConfigService();

  final List<_CategoryFilter> _categories = const [
    _CategoryFilter('Nearby', null),
    _CategoryFilter('Trending', 'popular'),
    _CategoryFilter('Vegan', 'vegan'),
    _CategoryFilter('Quick bites', 'fast food'),
    _CategoryFilter('Date night', 'romantic'),
    _CategoryFilter('Family', 'family friendly'),
  ];

  int _selectedCategory = 0;
  bool _loading = true;
  String? _error;
  List<NearbyPlace> _places = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final key = _configService.googleApiKey;
    if (key == null || key.isEmpty) {
      setState(() {
        _error = 'Google Places API key is missing.';
        _loading = false;
      });
      return;
    }
    _locationService.setApiKey(key);
    await _loadPlaces(keyword: _categories[_selectedCategory].keyword);
  }

  Future<void> _loadPlaces({String? keyword}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _loading = false;
        _error = 'Location unavailable. Enable location services to get nearby picks.';
        _places = [];
      });
      return;
    }

    final results = await _locationService.searchNearbyRestaurants(keyword: keyword);
    if (!mounted) return;

    setState(() {
      _places = results;
      _loading = false;
      if (_places.isEmpty) {
        _error = 'No nearby spots found. Try another filter.';
      }
    });
  }

  void _onCategorySelected(int index) {
    if (_selectedCategory == index) return;
    setState(() => _selectedCategory = index);
    _loadPlaces(keyword: _categories[index].keyword);
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/gradient/Gradients.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchHint(),
                  const SizedBox(height: 16),
                  _buildCategories(),
                  const SizedBox(height: 20),
                  _buildResults(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Discover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Arvo',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Find your next spot',
              style: TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 14,
                fontFamily: 'SF Compact Rounded',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSearchHint() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.white70),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search cuisine, mood, or place',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontFamily: 'SF Compact Rounded',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => _onCategorySelected(index),
            child: _CategoryChip(
              label: _categories[index].label,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _MessageCard(message: _error!);
    }

    if (_places.isEmpty) {
      return const _MessageCard(message: 'No nearby spots yet.');
    }

    final apiKey = _configService.googleApiKey;
    return Column(
      children: _places
          .map(
            (place) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DiscoverCard(
                place: place,
                distanceMeters: (place.lat != null && place.lng != null)
                    ? _locationService.distanceFrom(place.lat!, place.lng!)
                    : null,
                priceLabel: _locationService.priceLabel(place.priceLevel),
                apiKey: apiKey,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF74004A) : const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF74004A) : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'SF Compact Rounded',
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.place,
    required this.priceLabel,
    required this.apiKey,
    this.distanceMeters,
  });

  final NearbyPlace place;
  final String priceLabel;
  final double? distanceMeters;
  final String? apiKey;

  String _distanceLabel() {
    if (distanceMeters == null) return '—';
    final miles = distanceMeters! / 1609.344;
    if (miles < 0.1) {
      return '${distanceMeters!.toInt()} m';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  String _cuisineLabel() {
    final filtered = place.types.where((t) => !_genericTypes.contains(t)).toList();
    if (filtered.isEmpty) return 'Restaurant';
    final primary = filtered.first.replaceAll('_', ' ');
    return '${priceLabel} • ${_titleCase(primary)}';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = (place.photoReference != null && apiKey != null)
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${place.photoReference}&key=$apiKey'
        : null;
    final imageProvider = photoUrl != null
        ? NetworkImage(photoUrl) as ImageProvider
        : const AssetImage('lib/assets/gradient/Gradients.png');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xCC1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Arvo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cuisineLabel(),
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontFamily: 'SF Compact Rounded',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          place.rating?.toStringAsFixed(1) ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'SF Compact Rounded',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'SF Compact Rounded',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.white54, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _distanceLabel(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'SF Compact Rounded',
                      ),
                    ),
                    const Spacer(),
                    if (place.userRatingsTotal != null)
                      Text(
                        '${place.userRatingsTotal} reviews',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'SF Compact Rounded',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: const Color(0x331E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: 'SF Compact Rounded',
        ),
      ),
    );
  }
}

class _CategoryFilter {
  final String label;
  final String? keyword;
  const _CategoryFilter(this.label, this.keyword);
}

const List<String> _genericTypes = [
  'restaurant',
  'food',
  'point_of_interest',
  'establishment',
];
