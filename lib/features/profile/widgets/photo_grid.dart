import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bumble/features/profile/services/profile_service.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({
    super.key,
    this.userId,
    this.slotCount = 6,
  });

  final String? userId;
  final int slotCount;

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  List<String> _photos = [];
  bool _isLoading = true;
  int? _uploadingIndex;

  String get _effectiveUserId {
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return widget.userId!;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  @override
  void didUpdateWidget(covariant PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchPhotos();
    }
  }

  Future<void> _fetchPhotos() async {
    final uid = _effectiveUserId;
    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final photos = await _profileService.getUserPhotos(uid);
    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto(int index) async {
    final uid = _effectiveUserId;
    if (uid.isEmpty) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final fileName = picked.name;
    final bytes = await picked.readAsBytes();

    setState(() => _uploadingIndex = index);

    try {
      final uploadedUrl = await _profileService.uploadProfilePhoto(
        userId: uid,
        imageBytes: bytes,
        fileName: fileName,
      );

      if (mounted) {
        setState(() => _uploadingIndex = null);
        if (uploadedUrl != null) {
          setState(() {
            if (index < _photos.length) {
              _photos[index] = uploadedUrl;
            } else {
              _photos.add(uploadedUrl);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah foto.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingIndex = null);
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    final uid = _effectiveUserId;
    if (index >= _photos.length || uid.isEmpty) return;

    final photoUrl = _photos[index];

    setState(() {
      _photos.removeAt(index);
    });

    await _profileService.deleteProfilePhoto(
      userId: uid,
      photoUrl: photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.slotCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final isFilled = index < _photos.length;
        final isUploading = _uploadingIndex == index;

        if (isUploading) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffdddddd), width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return isFilled
            ? _FilledSlot(
                photoUrl: _photos[index],
                isMain: index == 0,
                onRemove: () => _removePhoto(index),
              )
            : _EmptySlot(onTap: () => _pickAndUploadPhoto(index));
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffdddddd), width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, size: 38),
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.photoUrl,
    required this.isMain,
    required this.onRemove,
  });

  final String photoUrl;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          if (isMain)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}