import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

enum ImageQuality { standard, hd }

class ChatImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucket = 'chat-images';

  Future<String> uploadChatImage({
    required File imageFile,
    required String matchId,
    required String senderId,
    ImageQuality quality = ImageQuality.standard,
  }) async {
    final processedFile = await _compressImage(imageFile, quality);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';
    final path = '$matchId/$fileName';

    await _supabase.storage
        .from(_bucket)
        .upload(
          path,
          processedFile,
          fileOptions: const FileOptions(upsert: false),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Future<File> _compressImage(File file, ImageQuality quality) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return file;

    final (maxWidth, jpegQuality) = switch (quality) {
      ImageQuality.standard => (1080, 65),
      ImageQuality.hd => (2560, 90),
    };

    final resized = image.width > maxWidth
        ? img.copyResize(image, width: maxWidth)
        : image;

    final compressedBytes = img.encodeJpg(resized, quality: jpegQuality);

    final outFile = File('${file.path}_compressed.jpg');
    await outFile.writeAsBytes(compressedBytes);
    return outFile;
  }
}
