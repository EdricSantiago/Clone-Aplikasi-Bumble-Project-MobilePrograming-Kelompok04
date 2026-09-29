import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({super.key, this.slotCount = 6});

  final int slotCount;

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final List<File> _photos = [];
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (_photos.length < widget.slotCount) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
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
        return isFilled ? _FilledSlot(
          photo: _photos[index],
          isMain: index == 0,
          onRemove: () => _removePhoto(index),
        ) : _EmptySlot(onTap: _pickPhoto);
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
    required this.photo,
    required this.isMain,
    required this.onRemove,
  });

  final File photo;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(photo, fit: BoxFit.cover),
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
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
