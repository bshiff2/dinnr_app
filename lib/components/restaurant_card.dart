import 'package:flutter/material.dart';

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.address,
    this.rating,
    this.priceLevel,
    this.cuisineType,
    this.onTap,
  });

  final String name;
  final String description;
  final String imageUrl;
  final String? address;
  final double? rating;
  final String? priceLevel; // "$", "$$", "$$$", "$$$$"
  final String? cuisineType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showRestaurantDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay label
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: const Color(0xFF1E1E1E),
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 48, color: Colors.white38),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom label with restaurant name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Details section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating, Price, and Cuisine
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (priceLevel != null) ...[
                        Text(
                          priceLevel!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (cuisineType != null)
                        Flexible(
                          child: Text(
                            cuisineType!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.white38),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            address!,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestaurantDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RestaurantDetailsSheet(
        name: name,
        description: description,
        imageUrl: imageUrl,
        address: address,
        rating: rating,
        priceLevel: priceLevel,
        cuisineType: cuisineType,
      ),
    );
  }
}

// ─── Full Details Sheet ───────────────────────────────────────────────────────
class _RestaurantDetailsSheet extends StatelessWidget {
  const _RestaurantDetailsSheet({
    required this.name,
    required this.description,
    required this.imageUrl,
    this.address,
    this.rating,
    this.priceLevel,
    this.cuisineType,
  });

  final String name;
  final String description;
  final String imageUrl;
  final String? address;
  final double? rating;
  final String? priceLevel;
  final String? cuisineType;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: const Color(0xFF2C2C2C),
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 64, color: Colors.white38),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Restaurant name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating, Price, Cuisine
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${rating!.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        if (priceLevel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              priceLevel!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (cuisineType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              cuisineType!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Description
                    const Text(
                      'About',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    if (address != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement directions
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening directions...')),
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement save
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved to favorites!')),
                              );
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Save'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
      },
    );
  }
}
