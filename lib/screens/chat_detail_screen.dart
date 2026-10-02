import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message_model.dart';
import '../services/chat_image_service.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ChatImageService _imageService = ChatImageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isUploadingImage = false;

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _chatService.sendMessage(widget.matchId, text);
    _messageController.clear();

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    if (!mounted) return;

    final quality = await _showQualityPicker();
    if (quality == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final currentUserId = _chatService.currentUserId ?? '';
      final imageBytes = await picked
          .readAsBytes(); // ganti dari File(picked.path)
      final imageUrl = await _imageService.uploadChatImage(
        imageBytes: imageBytes,
        matchId: widget.matchId,
        senderId: currentUserId,
        quality: quality,
      );

      await _chatService.sendImageMessage(widget.matchId, imageUrl);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim gambar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageQuality?> _showQualityPicker() {
    return showModalBottomSheet<ImageQuality>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Kirim biasa'),
              subtitle: const Text('Lebih cepat, ukuran kecil'),
              onTap: () => Navigator.pop(context, ImageQuality.standard),
            ),
            ListTile(
              title: const Text('Kirim HD'),
              subtitle: const Text('Kualitas lebih tinggi, ukuran lebih besar'),
              onTap: () => Navigator.pop(context, ImageQuality.hd),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLongPressMessage(MessageModel message) async {
    final currentUserId = _chatService.currentUserId;
    if (message.senderId != currentUserId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pesan?'),
        content: const Text('Pesan ini akan dihapus untuk semua orang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      await _imageService.deleteChatImage(message.imageUrl!);
    }

    await _chatService.deleteMessage(widget.matchId, message.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _chatService.getUserData(widget.otherUserId),
          builder: (context, nameSnapshot) {
            final resolvedName =
                nameSnapshot.data?['name'] ?? widget.otherUserName;

            return StreamBuilder<Map<String, dynamic>>(
              stream: PresenceService().watchUserStatus(widget.otherUserId),
              builder: (context, snapshot) {
                final isOnline = snapshot.data?['online'] == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(resolvedName),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada pesan.'));
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final hasImage =
                        message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _handleLongPressMessage(message),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: hasImage
                              ? const EdgeInsets.all(4)
                              : const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.orange : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    message.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 150,
                                        width: 150,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(
                                              height: 150,
                                              width: 150,
                                              child: Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                            ),
                                  ),
                                )
                              : Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isUploadingImage ? null : _pickAndSendImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_outlined),
                    color: Colors.orange,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
