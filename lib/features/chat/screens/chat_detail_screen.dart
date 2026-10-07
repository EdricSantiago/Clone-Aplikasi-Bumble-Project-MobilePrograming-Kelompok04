import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bumble/features/chat/models/message_model.dart';
import 'package:bumble/features/chat/services/chat_image_service.dart';
import 'package:bumble/features/chat/services/chat_service.dart';
import 'package:bumble/features/chat/services/presence_service.dart';
import 'package:bumble/core/services/safety_service.dart';
import 'package:bumble/core/theme/app_theme.dart';
import 'package:bumble/features/chat/screens/report_account_screen.dart';

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
  bool _isSending = false;
  bool _safetyBusy = false;
  late final _hiddenUsers = SafetyService().watchHiddenUserIds();
  late final _messages = _chatService.getMessages(widget.matchId);
  late final _otherUser = _chatService.getUserData(widget.otherUserId);
  late final _presenceStream = PresenceService().watchUserStatus(
    widget.otherUserId,
  );

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty || _isSending || _safetyBusy) return;
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(widget.matchId, text);
      if (mounted && _messageController.text == text)
        _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan gagal dikirim. Percakapan mungkin diblokir.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _report({String? messageId}) async {
    final blocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportAccountScreen(
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
          matchId: widget.matchId,
          messageId: messageId,
        ),
      ),
    );
    if (mounted && blocked == true) Navigator.pop(context);
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Block ${widget.otherUserName}?'),
        content: const Text(
          'Profil dan chat kalian akan disembunyikan. Pesan baru tidak dapat dikirim. Kamu bisa membuka block melalui Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _safetyBusy = true);
    try {
      await SafetyService().blockUser(widget.otherUserId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Block gagal. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => _safetyBusy = false);
    }
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
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    if (!mounted) return;

    final quality = await _showQualityPicker();
    if (quality == null || !mounted) return;

    setState(() => _isUploadingImage = true);

    try {
      await _chatService.ensureCanChat(widget.matchId);
      final currentUserId = _chatService.currentUserId ?? '';
      final imageBytes = await picked.readAsBytes();
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
    if (message.senderId != currentUserId) {
      await _report(messageId: message.id);
      return;
    }

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

    return StreamBuilder<Set<String>>(
      stream: _hiddenUsers,
      builder: (context, safetySnapshot) {
        final unavailable =
            !safetySnapshot.hasData ||
            safetySnapshot.hasError ||
            safetySnapshot.data!.contains(widget.otherUserId);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBumbleYellow,
            actions: [
              PopupMenuButton<String>(
                enabled: !_safetyBusy,
                tooltip: 'Report / Block akun',
                onSelected: (value) {
                  if (value == 'report') {
                    _report();
                  } else {
                    _block();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Report akun'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Block akun'),
                    ),
                  ),
                ],
              ),
            ],
            title: FutureBuilder<Map<String, dynamic>?>(
              future: _otherUser,
              builder: (context, nameSnapshot) {
                final resolvedName =
                    nameSnapshot.data?['name'] ?? widget.otherUserName;

                return StreamBuilder<Map<String, dynamic>>(
                  stream: _presenceStream,
                  builder: (context, snapshot) {
                    final isOnline =
                        !snapshot.hasError && snapshot.data?['online'] == true;
                    final statusText = snapshot.hasError
                        ? 'Status tidak tersedia'
                        : !snapshot.hasData
                        ? 'Memuat status...'
                        : isOnline
                        ? 'Online'
                        : 'Offline';
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
                              statusText,
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
                child: unavailable
                    ? const Center(
                        child: Icon(
                          Icons.lock_outline,
                          size: 56,
                          color: Colors.black38,
                        ),
                      )
                    : StreamBuilder<List<MessageModel>>(
                        stream: _messages,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError)
                            return const Center(
                              child: Text('Pesan gagal dimuat.'),
                            );

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Belum ada pesan.'),
                            );
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
                                  onLongPress: () =>
                                      _handleLongPressMessage(message),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: hasImage
                                        ? const EdgeInsets.all(4)
                                        : const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? kBumbleYellow
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: hasImage
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              message.imageUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                    if (progress == null)
                                                      return child;
                                                    return const SizedBox(
                                                      height: 150,
                                                      width: 150,
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const SizedBox(
                                                    height: 150,
                                                    width: 150,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            message.text,
                                            style: TextStyle(
                                              color: Colors.black87,
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

              if (unavailable)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    safetySnapshot.hasError
                        ? 'Status percakapan gagal dimuat. Coba kembali setelah koneksi pulih.'
                        : !safetySnapshot.hasData
                        ? 'Memeriksa percakapan...'
                        : 'Percakapan ini tidak tersedia karena akun diblokir.',
                  ),
                )
              else
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _isUploadingImage || _safetyBusy
                              ? null
                              : _pickAndSendImage,
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                          onPressed: _isSending || _safetyBusy
                              ? null
                              : _sendMessage,
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
      },
    );
  }
}
