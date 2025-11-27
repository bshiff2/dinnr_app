import 'package:flutter/material.dart';

import 'page_layout.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final LocationService _locationService = LocationService();
  final ConfigService _configService = ConfigService();

  final TextEditingController _searchController = TextEditingController();
  final _Filters _filters = _Filters();

  final List<_CategoryFilter> _categories = const [
    _CategoryFilter('Nearby', null),
    _CategoryFilter('Trending', 'popular'),
    _CategoryFilter('Vegan', 'vegan'),
    _CategoryFilter('Quick bites', 'fast food'),
    _CategoryFilter('Family', 'family friendly'),
  ];

  int _selectedCategory = 0;
  bool _loading = true;
  String? _error;
  List<NearbyPlace> _places = [];
  List<NearbyPlace> _allPlaces = [];
  bool _hasActiveSearch = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final filtered = _filterPlaces(results);

    setState(() {
      _allPlaces = results;
      _places = filtered;
      _loading = false;
      if (_allPlaces.isEmpty) {
        _error = 'No nearby spots found. Try another filter.';
      } else if (_places.isEmpty) {
        _error = 'No matches found with current filters.';
      }
    });
  }

  void _onCategorySelected(int index) {
    final selectingSame = _selectedCategory == index;
    if (selectingSame && !_hasActiveSearch) return;

    setState(() {
      _selectedCategory = index;
      _hasActiveSearch = false;
      _searchController.clear();
    });
    _loadPlaces(keyword: _categories[index].keyword);
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    final keyword = query.isEmpty ? _categories[_selectedCategory].keyword : query;
    FocusScope.of(context).unfocus();
    setState(() => _hasActiveSearch = query.isNotEmpty);
    _loadPlaces(keyword: keyword);
  }

  void _clearSearch() {
    final hadActiveSearch = _hasActiveSearch;
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _hasActiveSearch = false);

    if (hadActiveSearch) {
      _loadPlaces(keyword: _categories[_selectedCategory].keyword);
    }
  }

  void _openFilters() {
    final initial = _filters.copy();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        double? minRating = initial.minRating;
        double? maxDistance = initial.maxDistanceMiles;
        int? minReviews = initial.minReviews;
        bool openNow = initial.openNow;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Arvo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSection(
                      title: 'Rating',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [4.5, 4.0, 3.5, 3.0].map((value) {
                          final selected = minRating == value;
                          return ChoiceChip(
                            label: Text('$value+'),
                            selected: selected,
                            onSelected: (_) => setSheetState(() => minRating = selected ? null : value),
                            selectedColor: const Color(0xFF74004A),
                            backgroundColor: const Color(0xFF2A2A2A),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Compact Rounded',
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: selected ? const Color(0xFF74004A) : Colors.white38,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Distance',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _DistanceOption(label: '0.5 mi', miles: 0.5),
                          _DistanceOption(label: '1 mi', miles: 1),
                          _DistanceOption(label: '5 mi', miles: 5),
                          _DistanceOption(label: '10 mi', miles: 10),
                        ].map((option) {
                          final selected = maxDistance == option.miles;
                          return ChoiceChip(
                            label: Text(option.label),
                            selected: selected,
                            onSelected: (_) => setSheetState(() => maxDistance = selected ? null : option.miles),
                            selectedColor: const Color(0xFF74004A),
                            backgroundColor: const Color(0xFF2A2A2A),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Compact Rounded',
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: selected ? const Color(0xFF74004A) : Colors.white38,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Minimum reviews',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [20, 50, 100, 500].map((value) {
                          final selected = minReviews == value;
                          return ChoiceChip(
                            label: Text('$value+'),
                            selected: selected,
                            onSelected: (_) => setSheetState(() => minReviews = selected ? null : value),
                            selectedColor: const Color(0xFF74004A),
                            backgroundColor: const Color(0xFF2A2A2A),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Compact Rounded',
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: selected ? const Color(0xFF74004A) : Colors.white38,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Open now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'SF Compact Rounded',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: openNow,
                          onChanged: (val) => setSheetState(() => openNow = val),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF74004A),
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor: Colors.white24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                minRating = null;
                                maxDistance = null;
                                minReviews = null;
                                openNow = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Clear all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filters
                                  ..minRating = minRating
                                  ..maxDistanceMiles = maxDistance
                                  ..minReviews = minReviews
                                  ..openNow = openNow;
                                final filtered = _filterPlaces(_allPlaces);
                                _places = filtered;
                                _error = null;
                                if (_allPlaces.isEmpty) {
                                  _error = 'No nearby spots found. Try another filter.';
                                } else if (_places.isEmpty) {
                                  _error = 'No matches found with current filters.';
                                }
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF74004A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Apply filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<NearbyPlace> _filterPlaces(List<NearbyPlace> source) {
    return source.where((place) {
      if (_filters.minRating != null && (place.rating ?? 0) < _filters.minRating!) {
        return false;
      }
      if (_filters.minReviews != null && (place.userRatingsTotal ?? 0) < _filters.minReviews!) {
        return false;
      }
      if (_filters.openNow && place.isOpen != true) {
        return false;
      }
      if (_filters.maxDistanceMeters != null) {
        if (place.lat == null || place.lng == null) return false;
        final distance = _locationService.distanceFrom(place.lat!, place.lng!);
        if (distance == null || distance > _filters.maxDistanceMeters!) return false;
      }
      return true;
    }).toList();
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
                  _buildSearchBar(),
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
            color: _filters.hasActive ? const Color(0xFF74004A) : const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _openFilters,
            padding: EdgeInsets.zero,
            tooltip: 'Filters',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'SF Compact Rounded',
              ),
              decoration: const InputDecoration(
                hintText: 'Search cuisine, mood, or place',
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontFamily: 'SF Compact Rounded',
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty || _hasActiveSearch)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close, color: Colors.white70),
            )
          else
            IconButton(
              onPressed: () => _onSearchSubmitted(_searchController.text),
              icon: const Icon(Icons.arrow_forward, color: Colors.white70),
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
    this.onTap,
  });

  final NearbyPlace place;
  final String priceLabel;
  final double? distanceMeters;
  final String? apiKey;
  final VoidCallback? onTap;

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

    return GestureDetector(
      onTap: onTap ?? () => _showDetailsSheet(context, photoUrl),
      child: Container(
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

  void _showDetailsSheet(BuildContext context, String? photoUrl) {
    final detailsFuture = place.placeId != null
        ? LocationService().getPlaceDetails(place.placeId!)
        : Future.value(null);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final detailsImage = photoUrl != null
            ? NetworkImage(photoUrl) as ImageProvider
            : const AssetImage('lib/assets/gradient/Gradients.png');

        return FutureBuilder<PlaceDetails?>(
          future: detailsFuture,
          builder: (context, snapshot) {
            final details = snapshot.data;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(
                          image: detailsImage,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: const Color(0xFF2C2C2C),
                            child: const Center(
                              child: Icon(Icons.restaurant, color: Colors.white38, size: 48),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Arvo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _infoChip(Icons.star, place.rating?.toStringAsFixed(1) ?? '�?"'),
                          _infoChip(Icons.attach_money, priceLabel.isEmpty ? '\$' : priceLabel),
                          if (place.userRatingsTotal != null)
                            _infoChip(Icons.people, '${place.userRatingsTotal} reviews'),
                          _infoChip(Icons.restaurant_menu, _cuisineLabel()),
                          _infoChip(Icons.place, _distanceLabel()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (place.address.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place.address,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontFamily: 'SF Compact Rounded',
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      if (details != null && (details.website != null || details.googleMapsUrl != null))
                        _linkSection(context, details),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'SF Compact Rounded',
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkSection(BuildContext context, PlaceDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Website & Directions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Arvo',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (details.website != null)
              _linkButton(
                context,
                icon: Icons.language,
                label: 'Open website',
                url: details.website!,
              ),
            if (details.googleMapsUrl != null)
              _linkButton(
                context,
                icon: Icons.map,
                label: 'View in Maps',
                url: details.googleMapsUrl!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _linkButton(BuildContext context, {required IconData icon, required String label, required String url}) {
    return OutlinedButton.icon(
      onPressed: () => _openLink(context, url),
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
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

class _Filters {
  double? minRating;
  int? minReviews;
  bool openNow = false;
  double? maxDistanceMiles;

  double? get maxDistanceMeters => maxDistanceMiles == null ? null : maxDistanceMiles! * 1609.344;

  bool get hasActive =>
      minRating != null || minReviews != null || openNow || maxDistanceMiles != null;

  _Filters copy() {
    return _Filters()
      ..minRating = minRating
      ..minReviews = minReviews
      ..openNow = openNow
      ..maxDistanceMiles = maxDistanceMiles;
  }

  void reset() {
    minRating = null;
    minReviews = null;
    openNow = false;
    maxDistanceMiles = null;
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'SF Compact Rounded',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _DistanceOption {
  final String label;
  final double miles;

  const _DistanceOption({required this.label, required this.miles});
}
