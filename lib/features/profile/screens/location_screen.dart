import 'package:flutter/material.dart';
import 'package:bumble/features/profile/services/profile_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.userId});

  final String userId;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _allLocations = [
    'Jakarta, Indonesia',
    'Bandung, Indonesia',
    'Surabaya, Indonesia',
    'Tangerang, Indonesia',
    'Medan, Indonesia',
    'South Tangerang, Indonesia',
    'Bogor, Indonesia',
    'Yogyakarta, Indonesia',
    'Semarang, Indonesia',
    'Makassar, Indonesia',
    'Denpasar, Indonesia',
    'Palembang, Indonesia',
    'Batam, Indonesia',
    'Malang, Indonesia',
    'New York, United States',
    'Los Angeles, United States',
    'Chicago, United States',
    'London, United Kingdom',
    'Tokyo, Japan',
    'Singapore, Singapore',
    'Sydney, Australia',
  ];

  List<String> _filteredLocations = _allLocations;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        _filteredLocations = _allLocations
            .where((location) => location.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _selectLocation(String location) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.updateLocation(
        userId: widget.userId,
        location: location,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan lokasi: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontSize: 17, color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Find your current city',
            hintStyle: TextStyle(color: Colors.black45, fontSize: 17),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _filteredLocations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF0F0F0),
              ),
              itemBuilder: (context, index) {
                final item = _filteredLocations[index];
                return InkWell(
                  onTap: () => _selectLocation(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}