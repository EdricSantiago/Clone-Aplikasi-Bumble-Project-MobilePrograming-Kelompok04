import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

enum ImageQuality { standard, hd }

class ChatImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucket = 'chat-images';

  Future<String> uploadChatImage({
    required Uint8List imageBytes,
    required String matchId,
    required String senderId,
    ImageQuality quality = ImageQuality.standard,
  }) async {
    final processedBytes = _compressImage(imageBytes, quality);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';
    final path = '$matchId/$fileName';

    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          processedBytes,
          fileOptions: const FileOptions(upsert: false, contentType: 'image/jpeg'),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Uint8List _compressImage(Uint8List bytes, ImageQuality quality) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final (maxWidth, jpegQuality) = switch (quality) {
      ImageQuality.standard => (1080, 65),
      ImageQuality.hd => (2560, 90),
    };

    final resized = image.width > maxWidth
        ? img.copyResize(image, width: maxWidth)
        : image;

    return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
  }

  Future<void> deleteChatImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;

      final filePath = segments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from(_bucket).remove([filePath]);
    } catch (_) {}
  }
}